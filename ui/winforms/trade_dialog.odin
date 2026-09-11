package winforms_ui

import common "../common"
import dt "../../data"
import wf "../../lib/winforms"
import "core:fmt"
import "core:strconv"
import "core:strings"
import api "core:sys/windows"

// ---------------------------------------------------------------------------
// Trade dialog (WinForms): registers an already-closed trade in the active
// account.
//
// The WinForms handlers carry no user data, so the dialog state lives at package
// level, like the one of the main menu. The dialog is built once and then shown
// and hidden: while it is open the main window is disabled, which is the modal
// behaviour (its buttons can not be clicked, so no other dialog can be opened),
// and it is never destroyed from inside its own close handling.
// ---------------------------------------------------------------------------

// Indexes of the markets listed in the market combo
MARKET_FUTURES :: 0
MARKET_CFDS :: 1
MARKET_FOREX :: 2

DIALOG_WIDTH :: 440
DIALOG_HEIGHT :: 470

// Layout of the label/field rows
LABEL_X :: 16
LABEL_W :: 104
FIELD_X :: 124
FIELD_W :: 280
ROW_H :: 26
ROW_STEP :: 34

Trade_State :: struct {
	form:    ^wf.Form,
	account: ^wf.Label,
	broker:  ^wf.Label,
	market:  ^wf.ComboBox,
	value:   ^wf.ComboBox,
	long:    ^wf.RadioButton,
	short:   ^wf.RadioButton,
	amount:  ^wf.TextBox,
	entry:   ^wf.TextBox,
	exit:    ^wf.TextBox,
	date:    ^wf.TextBox,
	status:  ^wf.Label,
	add:     ^wf.Button,
	close:   ^wf.Button,
	texts:   common.Trade_Texts,
}

_trade: Trade_State

set_status :: proc(text: string) {
	wf.control_set_text(&_trade.status.control, text)
}

// Reads an entry and parses it, freeing the string the binding allocates
parse_entry_int :: proc(tb: ^wf.TextBox) -> (int, bool) {
	text := wf.control_get_text(tb.control)
	defer delete(text)
	return strconv.parse_int(strings.trim_space(text))
}

parse_entry_f64 :: proc(tb: ^wf.TextBox) -> (f64, bool) {
	text := wf.control_get_text(tb.control)
	defer delete(text)
	return strconv.parse_f64(strings.trim_space(text))
}

// Places a dialog over the main window. Before the form handle exists it only
// sets the form position, and once it exists it moves the window too, since the
// trade dialog is reused and the main window may have been moved in between.
center_over_main :: proc(frm: ^wf.Form) {
	main_rect: api.RECT
	if !bool(api.GetWindowRect(cast(api.HWND)_app.main.handle, &main_rect)) {
		return
	}

	x := main_rect.left + (main_rect.right - main_rect.left - frm.width) / 2
	y := main_rect.top + (main_rect.bottom - main_rect.top - frm.height) / 2

	frm.start_pos = .Manual
	frm.xpos = x
	frm.ypos = y
	if frm.handle != nil {
		api.MoveWindow(cast(api.HWND)frm.handle, x, y, frm.width, frm.height, true)
	}
}

// Fills the value combo with the tickers of the selected market, and only
// enables Add when there is something to choose
trade_refresh_values :: proc() {
	combo := _trade.value

	// There is no helper to empty a combo: it must be reset through the control
	api.SendMessageW(cast(api.HWND)combo.handle, wf.CB_RESETCONTENT, 0, 0)
	clear(&combo.items)

	market := wf.combo_get_selected_index(_trade.market)
	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)

	count := 0
	if broker != nil && market == MARKET_FUTURES {
		for contract in broker.futures_database {
			wf.combo_add_item(combo, contract.ticker)
			count += 1
		}
	}

	if count > 0 {
		wf.combo_set_selected_index(combo, 0)
	}
	wf.control_enable(&_trade.add.control, count > 0)
}

// Registers the trade described by the dialog fields in the active account
trade_add :: proc() {
	market := wf.combo_get_selected_index(_trade.market)
	value_index := wf.combo_get_selected_index(_trade.value)
	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)

	if broker == nil || market != MARKET_FUTURES {
		set_status(string(_trade.texts.err_no_values))
		return
	}
	if value_index < 0 || value_index >= len(broker.futures_database) {
		set_status(string(_trade.texts.err_no_values))
		return
	}
	contract := broker.futures_database[value_index]

	quantity, quantity_ok := parse_entry_int(_trade.amount)
	if !quantity_ok || quantity <= 0 {
		set_status(string(_trade.texts.err_quantity))
		return
	}

	entry, entry_ok := parse_entry_f64(_trade.entry)
	exit, exit_ok := parse_entry_f64(_trade.exit)
	if !entry_ok || !exit_ok {
		set_status(string(_trade.texts.err_price))
		return
	}

	date_text := wf.control_get_text(_trade.date.control)
	defer delete(date_text)

	date := dt.current_date_number()
	if trimmed := strings.trim_space(date_text); len(trimmed) > 0 {
		parsed, date_ok := strconv.parse_int(trimmed)
		if !date_ok || parsed < 10000101 {
			set_status(string(_trade.texts.err_date))
			return
		}
		date = parsed
	}

	is_long := _trade.long.checked
	calc := dt.calculate_trade(contract, is_long, quantity, entry, exit)

	dt.record_trade(account, contract.ticker, is_long, quantity, entry, exit, calc.net_pnl, date)

	// Persist right away so a registered trade is not lost
	saved := dt.save_data("data.json", _app.data)

	status_buffer: [160]u8
	status := fmt.bprintf(
		status_buffer[:],
		"%s %s x%d | Net: %.2f",
		string(_trade.texts.added),
		contract.ticker,
		quantity,
		calc.net_pnl,
	)
	set_status(saved ? status : string(_trade.texts.err_save))

	// Clear the numeric fields, ready for the next trade
	wf.control_set_text(&_trade.amount.control, "")
	wf.control_set_text(&_trade.entry.control, "")
	wf.control_set_text(&_trade.exit.control, "")
}

// --- Handlers ---------------------------------------------------------------

on_trade_market_changed :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	trade_refresh_values()
}

on_trade_add_clicked :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	trade_add()
}

on_trade_close_clicked :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	close_trade_dialog()
}

// The dialog is reused, so closing it (X) only hides it: the close is cancelled
// and the control goes back to the main window
on_trade_closing :: proc(sender: rawptr, ea: ^wf.EventArgs) {
	ea.cancel = true
	close_trade_dialog()
}

// --- Dialog -----------------------------------------------------------------

// Builds the dialog; it is built once and then shown and hidden
build_trade_dialog :: proc() {
	texts := common.get_trade_texts(_app.config.language)
	_trade.texts = texts

	label_h: i32 = 20
	row_y :: proc(row: i32) -> i32 { return 68 + row * ROW_STEP }

	form := wf.new_form(string(texts.title), DIALOG_WIDTH, DIALOG_HEIGHT)
	form.start_pos = .Manual
	form.onClosing = on_trade_closing
	_trade.form = form

	_trade.account = wf.new_label(form, "", LABEL_X, 14, 388, label_h)
	_trade.broker = wf.new_label(form, "", LABEL_X, 36, 388, label_h)

	market_label := wf.new_label(form, string(texts.market), LABEL_X, row_y(0) + 4, LABEL_W, label_h)
	_trade.market = wf.new_combobox(form, FIELD_X, row_y(0), FIELD_W, ROW_H)
	_trade.market.onTextChanged = on_trade_market_changed
	for market_name in texts.markets {
		wf.combo_add_item(_trade.market, string(market_name))
	}

	value_label := wf.new_label(form, string(texts.symbol), LABEL_X, row_y(1) + 4, LABEL_W, label_h)
	_trade.value = wf.new_combobox(form, FIELD_X, row_y(1), FIELD_W, ROW_H)

	direction_label := wf.new_label(
		form,
		string(texts.direction),
		LABEL_X,
		row_y(2) + 4,
		LABEL_W,
		label_h,
	)
	_trade.long = wf.new_radiobutton(form, string(texts.long), FIELD_X, row_y(2), 94, ROW_H)
	_trade.short = wf.new_radiobutton(form, string(texts.short), FIELD_X + 100, row_y(2), 94, ROW_H)

	amount_label := wf.new_label(form, string(texts.amount), LABEL_X, row_y(3) + 4, LABEL_W, label_h)
	_trade.amount = wf.new_textbox(form, "", FIELD_X, row_y(3), FIELD_W, ROW_H)

	entry_label := wf.new_label(form, string(texts.entry), LABEL_X, row_y(4) + 4, LABEL_W, label_h)
	_trade.entry = wf.new_textbox(form, "", FIELD_X, row_y(4), FIELD_W, ROW_H)

	exit_label := wf.new_label(form, string(texts.exit), LABEL_X, row_y(5) + 4, LABEL_W, label_h)
	_trade.exit = wf.new_textbox(form, "", FIELD_X, row_y(5), FIELD_W, ROW_H)

	date_label := wf.new_label(form, string(texts.date), LABEL_X, row_y(6) + 4, LABEL_W, label_h)
	_trade.date = wf.new_textbox(form, "", FIELD_X, row_y(6), FIELD_W, ROW_H)

	_trade.add = wf.new_button(form, string(texts.add), (DIALOG_WIDTH - 120) / 2, 320, 120, 30)
	_trade.add.onClick = on_trade_add_clicked

	_trade.status = wf.new_label(form, "", LABEL_X, 360, 388, label_h)
	_trade.status._style |= api.SS_CENTER

	_trade.close = wf.new_button(form, string(texts.close), 306, 390, 98, 28)
	_trade.close.onClick = on_trade_close_clicked

	wf.create_handle(form)
	create_form_controls(form)
}

// Shows the dialog with the current account, broker and values, over the main
// window, and disables the main window while it is open
open_trade_dialog :: proc() {
	if _app.dialog_open {
		return
	}
	if _trade.form == nil {
		build_trade_dialog()
	}

	texts := common.get_trade_texts(_app.config.language)
	_trade.texts = texts

	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)
	broker_name := broker != nil ? broker.name : "—"

	wf.control_set_text(
		&_trade.account.control,
		fmt.tprintf("%s: %s", string(texts.account), account.name),
	)
	wf.control_set_text(
		&_trade.broker.control,
		fmt.tprintf("%s: %s", string(texts.broker), broker_name),
	)

	set_status("")
	wf.combo_set_selected_index(_trade.market, MARKET_FUTURES)
	trade_refresh_values()
	_trade.long.checked = true
	wf.radiobutton_set_state(_trade.long, true)

	date_buffer: [16]u8
	wf.control_set_text(
		&_trade.date.control,
		fmt.bprintf(date_buffer[:], "%d", dt.current_date_number()),
	)

	center_over_main(_trade.form)

	_app.dialog_open = true
	wf.control_enable(&_app.main.control, false)
	wf.form_show(_trade.form^)
	api.SetForegroundWindow(cast(api.HWND)_trade.form.handle)
}

// Hides the dialog and gives the control back to the main window
close_trade_dialog :: proc() {
	wf.form_hide(_trade.form^)
	_app.dialog_open = false
	wf.control_enable(&_app.main.control, true)
	api.SetForegroundWindow(cast(api.HWND)_app.main.handle)
}
