package winforms_ui

import dt "../../data"
import wf "../../lib/winforms"
import common "../common"
import "core:fmt"
import "core:mem"
import api "core:sys/windows"

// The WinForms handlers carry no user data (sender is the control itself), so
// the UI state lives at package level and is set up before the main loop.
App_State :: struct {
	data:        dt.Data,
	config:      dt.Config,
	texts:       common.Menu_Texts,
	main:        ^wf.Form,
	buttons:     [len(common.MENU_ACTIONS)]^wf.Button,
	dialog_open: bool, // true while a section or trade dialog is on screen
}

_app: App_State

// Saves the session (data + config). Window geometry is read from the form,
// which the binding keeps up to date on every move/resize.
save_session :: proc() {
	frm := _app.main
	_app.config.window.width = int(frm.width)
	_app.config.window.height = int(frm.height)
	_app.config.window.x = int(frm.xpos)
	_app.config.window.y = int(frm.ypos)
	_app.config.window.positioned = true

	dt.save_data("data.json", _app.data)
	dt.save_config("config.json", _app.config)
}

// Creates the handles of every control of a form. The binding does this in its
// own (private) routine when the main form is shown, so a dialog that is not the
// main form has to do it here: the generic create_controls() helper would create
// the controls with no size.
create_form_controls :: proc(frm: ^wf.Form) {
	for ctl in frm._controls {
		if ctl.handle == nil && ctl._createHandleProc != nil {
			ctl._createHandleProc(ctl)
		}
	}
}

// Fires when a placeholder dialog is closed: the dialog is destroyed, so the
// main window only has to get the control back
on_section_closing :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	_app.dialog_open = false
	wf.control_enable(&_app.main.control, true)
	api.SetForegroundWindow(cast(api.HWND)_app.main.handle)
}

// Opens a placeholder dialog window for a section, over the main window. The main
// window is disabled while it is open, so no other dialog can be opened.
open_section_dialog :: proc(title: cstring) {
	if _app.dialog_open {
		return
	}

	dlg := wf.new_form(string(title), 320, 150)
	dlg.start_pos = .Manual
	dlg.onClosing = on_section_closing
	wf.new_label(dlg, string(_app.texts.pending), 16, 24, 280, 20)

	center_over_main(dlg)

	_app.dialog_open = true
	wf.create_handle(dlg)
	create_form_controls(dlg)
	wf.control_enable(&_app.main.control, false)
	wf.form_show(dlg^)
	api.SetForegroundWindow(cast(api.HWND)dlg.handle)
}

// Main menu button dispatcher: identifies the button by its handle
on_button_clicked :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	btn := cast(^wf.Button)sender

	action := common.MenuAction.Exit
	for _, i in common.MENU_ACTIONS {
		if _app.buttons[i] == btn {
			action = common.MENU_ACTIONS[i]
			break
		}
	}

	switch action {
	case .Exit:
		// Closing the main window triggers on_main_closing, which saves the session
		api.PostMessageW(cast(api.HWND)_app.main.handle, api.WM_CLOSE, 0, 0)
	case .Trade:
		open_trade_dialog()
	case .Results, .Account, .Config:
		open_section_dialog(common.action_title(_app.texts, action))
	}
}

// Fires when the main window is closed (X or the Exit button), before it is destroyed
on_main_closing :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	save_session()
}

run_winforms :: proc() {
	// Session memory: a dynamic arena holds everything allocated this run
	// (including the JSON data loaded at start) and is freed when the app quits
	session_arena: mem.Dynamic_Arena
	common.begin_session_arena(&session_arena)
	defer mem.dynamic_arena_destroy(&session_arena)

	// Load the application data and configuration (language) at session start
	data := common.load_session_data("data.json")
	cfg := dt.load_config("config.json")

	_app = App_State {
		data   = data,
		config = cfg,
		texts  = common.get_menu_texts(cfg.language),
	}

	// Window size: the saved one when available, otherwise a sensible default
	win_w: i32 = 360
	win_h: i32 = 400
	if cfg.window.width > 0 && cfg.window.height > 0 {
		win_w = cast(i32)cfg.window.width
		win_h = cast(i32)cfg.window.height
	}

	frm := wf.new_form("Day Trade", win_w, win_h)
	if cfg.window.positioned {
		frm.start_pos = .Manual
		frm.xpos = cast(i32)cfg.window.x
		frm.ypos = cast(i32)cfg.window.y
	} else {
		frm.start_pos = .Center
	}
	_app.main = frm
	frm.onClosing = on_main_closing

	// 1. Label with the name of the active account (centered text)
	active_account := &data.accounts[data.active_account]
	account_text := fmt.tprintf("%s: %s", string(_app.texts.account), active_account.name)
	label_w: i32 = 240
	account_label := wf.new_label(frm, account_text, (win_w - label_w) / 2, 24, label_w, 32)
	account_label._style |= api.SS_CENTER

	// 2. Column of menu buttons, each launching its own dialog
	btn_w: i32 = 150
	btn_h: i32 = 30
	start_y: i32 = 60
	gap: i32 = 8
	for action, i in common.MENU_ACTIONS {
		title := string(common.action_title(_app.texts, action))
		button := wf.new_button(
			frm,
			title,
			(win_w - btn_w) / 2,
			start_y + i32(i) * (btn_h + gap),
			btn_w,
			btn_h,
		)
		button.onClick = on_button_clicked
		_app.buttons[i] = button
	}

	wf.start_mainloop(frm)
}
