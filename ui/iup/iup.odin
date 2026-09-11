package iup_ui

import dt "../../data"
import iup "../../lib/iup"
import common "../common"
import runtime "base:runtime"
import "core:fmt"
import "core:mem"
import "core:strings"

// IUP callbacks carry no user data, so the UI state lives at package level;
// it is set up in run_iup and stays valid for the whole main loop
App_State :: struct {
	data:        dt.Data,
	config:      dt.Config,
	texts:       common.Menu_Texts,
	main_dlg:    iup.Ihandle,
	buttons:     [len(common.MENU_ACTIONS)]iup.Ihandle,
	dialog_open: bool, // true while a section or trade dialog is on screen
	alloc:       mem.Allocator, // session arena allocator, restored inside "c" callbacks
	temp_alloc:  mem.Allocator,
}

_app: App_State

// "c" callbacks have no implicit context; the first thing they must do is
// restore the session one so that any Odin code invoked from them can allocate
// through the session arena

// Name under which the main dialog is registered so the child dialogs can refer
// to it through the PARENTDIALOG attribute (which expects a dialog name)
MAIN_DIALOG_NAME :: "main_dialog"

// Creates a simple centered label inside a full-width row
make_label :: proc(text: cstring) -> iup.Ihandle {
	label := iup.IupLabel(text)
	iup.IupSetAttribute(label, "EXPAND", "HORIZONTAL")
	iup.IupSetAttribute(label, "ALIGNMENT", "ACENTER")
	return label
}

// Shows a dialog owned by the main window and centered over it, so that only one
// dialog is on screen at a time.
//
// The main window is disabled while the dialog is open, which is the modal
// behaviour: its buttons can not be clicked, so a second dialog can never be
// opened. The dialog is a plain window shown with IupShowXY rather than a modal
// popup (IupPopup): in IUP 3 the MODAL attribute is read-only, and a popup
// leaves the dialog unusable once it ends, so it can not be shown again.
//
// The main window is re-enabled by on_child_dialog_closed, called from the close
// callbacks of the dialog.
//
// IUP_CENTERPARENT centers the dialog over its parent dialog (the main window)
// instead of over the whole screen; it needs PARENTDIALOG to be defined.
show_child_dialog :: proc(dlg: iup.Ihandle) {
	iup.IupSetAttribute(dlg, "PARENTDIALOG", MAIN_DIALOG_NAME)
	_app.dialog_open = true
	iup.IupSetAttribute(_app.main_dlg, "ACTIVE", "NO")
	iup.IupShowXY(dlg, iup.CENTERPARENT, iup.CENTERPARENT)
}

// Undoes show_child_dialog; must be called from the callbacks that close a dialog
on_child_dialog_closed :: proc() {
	_app.dialog_open = false
	iup.IupSetAttribute(_app.main_dlg, "ACTIVE", "YES")
}

// Closing the section dialog with the window X. The dialog is destroyed here,
// which the docs allow as long as IUP_IGNORE is returned so that IUP does not
// close it a second time. Note that IUP_CLOSE must not be used: returned by a
// child dialog it closes the main window instead.
on_section_close :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	on_child_dialog_closed()
	iup.IupDestroy(ih)
	return iup.IGNORE
}

// Opens a dialog for a section (placeholder content), centered over the main
// window. It is destroyed as soon as it is closed.
open_section_dialog :: proc(title: cstring) {
	if _app.dialog_open {
		return
	}

	title_label := make_label(title)
	pending_label := make_label(_app.texts.pending)

	vbox := iup.Vbox(title_label, pending_label)
	iup.IupSetAttribute(vbox, "MARGIN", "16x16")
	iup.IupSetAttribute(vbox, "GAP", "8")

	dlg := iup.IupDialog(vbox)
	iup.IupSetAttribute(dlg, "TITLE", title)
	iup.IupSetAttribute(dlg, "SIZE", "320x160")
	iup.IupSetCallback(dlg, "CLOSE_CB", on_section_close)

	show_child_dialog(dlg)
}

// IUP reports every move of the main window here, so the saved position is
// always up to date and only needs persisting when the session ends
on_main_move :: proc "c" (ih: iup.Ihandle, x: i32, y: i32) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	_app.config.window.x = int(x)
	_app.config.window.y = int(y)
	_app.config.window.positioned = true
	return iup.DEFAULT
}

// IUP reports every resize of the main window here, keeping the saved size up to date
on_main_resize :: proc "c" (ih: iup.Ihandle, width: i32, height: i32) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	_app.config.window.width = int(width)
	_app.config.window.height = int(height)
	return iup.DEFAULT
}

// Dispatches each button of the main menu by matching its handle
on_button_action :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	action := common.MenuAction.Exit
	for _, i in common.MENU_ACTIONS {
		if _app.buttons[i] == ih {
			action = common.MENU_ACTIONS[i]
			break
		}
	}

	switch action {
	case .Exit:
		// End of the GUI session: persist data and config (window geometry is
		// already kept up to date by MOVE_CB / RESIZE_CB)
		dt.save_data("data.json", _app.data)
		dt.save_config("config.json", _app.config)
		iup.IupHide(_app.main_dlg)
		iup.IupExitLoop()
	case .Trade:
		open_trade_dialog()
	case .Results, .Account, .Config:
		open_section_dialog(common.action_title(_app.texts, action))
	}
	return iup.DEFAULT
}

// Closing the main window (X) also ends the session and persists data and config
on_main_close :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	dt.save_data("data.json", _app.data)
	dt.save_config("config.json", _app.config)
	return iup.CLOSE
}

run_iup :: proc() {
	// Session memory: a dynamic arena holds everything allocated this run
	// (including the JSON data loaded at start) and is freed when the app quits
	session_arena: mem.Dynamic_Arena
	alloc := common.begin_session_arena(&session_arena)
	defer mem.dynamic_arena_destroy(&session_arena)

	// Load the application data and configuration (language) at session start;
	// config is persisted again when the session ends
	data := common.load_session_data("data.json")
	cfg := dt.load_config("config.json")

	_app = App_State {
		data       = data,
		config     = cfg,
		texts      = common.get_menu_texts(cfg.language),
		alloc      = alloc,
		temp_alloc = context.temp_allocator,
	}

	iup.IupOpen(nil, nil)
	defer iup.IupClose()

	// Force IUP to interpret all strings as UTF-8 on Windows
	iup.IupSetGlobal("UTF8MODE", "YES")

	// 1. Label with the name of the active account
	active_account := &_app.data.accounts[_app.data.active_account]
	account_title := fmt.tprintf("%s: %s", string(_app.texts.account), active_account.name)
	account_label := make_label(strings.clone_to_cstring(account_title))

	// 2. Column of menu buttons, each launching its own dialog
	buttons: [len(common.MENU_ACTIONS)]iup.Ihandle
	for action, i in common.MENU_ACTIONS {
		button := iup.IupButton(common.action_title(_app.texts, action), nil)
		iup.IupSetAttribute(button, "EXPAND", "HORIZONTAL")
		buttons[i] = button
	}

	vbox := iup.Vbox(account_label, buttons[0], buttons[1], buttons[2], buttons[3], buttons[4])
	iup.IupSetAttribute(vbox, "MARGIN", "12x12")
	iup.IupSetAttribute(vbox, "GAP", "6")

	dlg := iup.IupDialog(vbox)
	iup.IupSetAttribute(dlg, "TITLE", "Day Trade")
	// Child dialogs are parented to this one, which keeps them centered over it
	// and inhibits it while they are open. PARENTDIALOG refers to the dialog by
	// name, and the name must be registered with IupSetHandle for IUP to resolve
	// it (setting NAME alone does not do it here).
	iup.IupSetAttribute(dlg, "NAME", MAIN_DIALOG_NAME)
	iup.IupSetHandle(MAIN_DIALOG_NAME, dlg)

	// Restore the saved window size (position is applied via IupShowXY below)
	if _app.config.window.width > 0 && _app.config.window.height > 0 {
		iup.IupStoreAttribute(
			dlg,
			"CLIENTSIZE",
			strings.clone_to_cstring(
				fmt.tprintf("%dx%d", _app.config.window.width, _app.config.window.height),
			),
		)
	} else {
		iup.IupSetAttribute(dlg, "CLIENTSIZE", "180x200")
	}

	_app.main_dlg = dlg
	_app.buttons = buttons

	iup.IupSetCallback(dlg, "CLOSE_CB", on_main_close)
	iup.IupSetCallback(dlg, "MOVE_CB", cast(iup.Icallback)on_main_move)
	iup.IupSetCallback(dlg, "RESIZE_CB", cast(iup.Icallback)on_main_resize)
	for i in 0 ..< len(buttons) {
		iup.IupSetCallback(buttons[i], "ACTION", on_button_action)
	}

	// Show the window at its saved position, or centered when none is stored
	geometry := _app.config.window
	if geometry.positioned {
		iup.IupShowXY(dlg, cast(i32)geometry.x, cast(i32)geometry.y)
	} else {
		iup.IupShowXY(dlg, iup.CENTER, iup.CENTER)
	}
	iup.IupMainLoop()
}
