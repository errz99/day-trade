package iup_ui

import dt "../../data"
import iup "../../lib/iup"
import runtime "base:runtime"
import "core:fmt"
import "core:mem"
import "core:strings"

// Localized texts for the main menu window (mirrors the GTK UI)
Menu_Texts :: struct {
	account: cstring, // Account / Cuenta
	trade:   cstring, // Trade / Operar
	results: cstring, // Results / Resultados
	config:  cstring, // Config
	exit:    cstring, // Exit / Salida
	pending: cstring, // placeholder hint shown in not-yet-implemented dialogs
}

get_menu_texts :: proc(lang: dt.Language) -> Menu_Texts {
	switch lang {
	case .English:
		return Menu_Texts {
			account = cstring("Account"),
			trade = cstring("Trade"),
			results = cstring("Results"),
			config = cstring("Config"),
			exit = cstring("Exit"),
			pending = cstring("Not implemented yet"),
		}
	case .Spanish:
		return Menu_Texts {
			account = cstring("Cuenta"),
			trade = cstring("Operar"),
			results = cstring("Resultados"),
			config = cstring("Config"),
			exit = cstring("Salida"),
			pending = cstring("Aún no implementado"),
		}
	}
	return {}
}

// Menu action carried by each of the main window buttons
MenuAction :: enum {
	Trade,
	Results,
	Account,
	Config,
	Exit,
}

MENU_ACTIONS := [?]MenuAction{.Trade, .Results, .Account, .Config, .Exit}

action_title :: proc(texts: Menu_Texts, action: MenuAction) -> cstring {
	switch action {
	case .Trade:
		return texts.trade
	case .Results:
		return texts.results
	case .Account:
		return texts.account
	case .Config:
		return texts.config
	case .Exit:
		return texts.exit
	}
	return ""
}

// IUP callbacks carry no user data, so the UI state lives at package level;
// it is set up in run_iup and stays valid for the whole main loop
App_State :: struct {
	data:       dt.Data,
	lang:       dt.Language,
	texts:      Menu_Texts,
	main_dlg:   iup.Ihandle,
	buttons:    [len(MENU_ACTIONS)]iup.Ihandle,
	alloc:      mem.Allocator, // session arena allocator, restored inside "c" callbacks
	temp_alloc: mem.Allocator,
}

_app: App_State

// "c" callbacks have no implicit context; the first thing they must do is
// restore the session one so that any Odin code invoked from them can allocate
// through the session arena

// Creates a simple centered label inside a full-width row
make_label :: proc(text: cstring) -> iup.Ihandle {
	label := iup.IupLabel(text)
	iup.IupSetAttribute(label, "EXPAND", "HORIZONTAL")
	iup.IupSetAttribute(label, "ALIGNMENT", "ACENTER")
	return label
}

// Opens a modal, transient-ish dialog window for a section (placeholder content)
open_section_dialog :: proc(title: cstring) {
	title_label := make_label(title)
	pending_label := make_label(_app.texts.pending)

	vbox := iup.Vbox(title_label, pending_label)
	iup.IupSetAttribute(vbox, "MARGIN", "16x16")
	iup.IupSetAttribute(vbox, "GAP", "8")

	dlg := iup.IupDialog(vbox)
	iup.IupSetAttribute(dlg, "TITLE", title)
	iup.IupSetAttribute(dlg, "SIZE", "320x160")

	// modal until the user closes it
	iup.IupPopup(dlg, iup.CENTER, iup.CENTER)
	iup.IupDestroy(dlg)
}

// Dispatches each button of the main menu by matching its handle
on_button_action :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	action := MenuAction.Exit
	for _, i in MENU_ACTIONS {
		if _app.buttons[i] == ih {
			action = MENU_ACTIONS[i]
			break
		}
	}

	switch action {
	case .Exit:
		// End of the GUI session: persist the data and quit
		dt.save_data("data.json", _app.data)
		iup.IupHide(_app.main_dlg)
		iup.IupExitLoop()
	case .Trade, .Results, .Account, .Config:
		open_section_dialog(action_title(_app.texts, action))
	}
	return iup.DEFAULT
}

// Closing the main window (X) also ends the session and persists the data
on_main_close :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	dt.save_data("data.json", _app.data)
	return iup.CLOSE
}

run_iup :: proc() {
	// Session memory: a dynamic arena holds everything allocated this run
	// (including the JSON data loaded at start) and is freed when the app quits
	session_arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&session_arena)
	context.allocator = mem.dynamic_arena_allocator(&session_arena)
	defer mem.dynamic_arena_destroy(&session_arena)

	// Load the application data at session start; fall back to defaults
	data: dt.Data
	if loaded, ok := dt.load_data("data.json"); ok {
		data = loaded
	} else {
		data = dt.new_default_data()
	}
	if len(data.accounts) == 0 {
		data = dt.new_default_data()
	}
	if data.active_account < 0 || data.active_account >= len(data.accounts) {
		data.active_account = 0
	}

	lang := dt.load_language_config("config.ini")
	_app = App_State {
		data       = data,
		lang       = lang,
		texts      = get_menu_texts(lang),
		alloc      = mem.dynamic_arena_allocator(&session_arena),
		temp_alloc = context.temp_allocator,
	}

	iup.IupOpen(nil, nil)
	defer iup.IupClose()

	// 1. Label with the name of the active account
	active_account := &_app.data.accounts[_app.data.active_account]
	account_title := fmt.tprintf("%s: %s", string(_app.texts.account), active_account.name)
	account_label := make_label(strings.clone_to_cstring(account_title))

	// 2. Column of menu buttons, each launching its own dialog
	buttons: [len(MENU_ACTIONS)]iup.Ihandle
	for action, i in MENU_ACTIONS {
		button := iup.IupButton(action_title(_app.texts, action), nil)
		iup.IupSetAttribute(button, "EXPAND", "HORIZONTAL")
		buttons[i] = button
	}

	vbox := iup.Vbox(account_label, buttons[0], buttons[1], buttons[2], buttons[3], buttons[4])
	iup.IupSetAttribute(vbox, "MARGIN", "12x12")
	iup.IupSetAttribute(vbox, "GAP", "6")

	dlg := iup.IupDialog(vbox)
	iup.IupSetAttribute(dlg, "TITLE", "Day Trade")
	iup.IupSetAttribute(dlg, "SIZE", "180x200")

	_app.main_dlg = dlg
	_app.buttons = buttons

	iup.IupSetCallback(dlg, "CLOSE_CB", on_main_close)
	for i in 0 ..< len(buttons) {
		iup.IupSetCallback(buttons[i], "ACTION", on_button_action)
	}

	iup.IupShow(dlg)
	iup.IupMainLoop()
}
