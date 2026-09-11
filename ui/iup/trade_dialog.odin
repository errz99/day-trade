package iup_ui

import common "../common"
import dt "../../data"
import iup "../../lib/iup"
import runtime "base:runtime"
import "core:fmt"
import "core:strconv"
import "core:strings"

// ---------------------------------------------------------------------------
// Trade dialog (IUP): registers an already-closed trade in the active account.
//
// IUP callbacks carry no user data, so the dialog state lives at package level
// and is rebuilt lazily the first time the dialog is opened.
// ---------------------------------------------------------------------------

// Index of "Futures" in the market dropdown (IUP list indexes are 1-based)
MARKET_FUTURES_IUP :: 1

Trade_State :: struct {
	dialog:         iup.Ihandle,
	account_label:  iup.Ihandle,
	broker_label:   iup.Ihandle,
	market_list:    iup.Ihandle,
	value_list:     iup.Ihandle,
	long_toggle:    iup.Ihandle,
	short_toggle:   iup.Ihandle,
	amount_text:    iup.Ihandle,
	entry_text:     iup.Ihandle,
	exit_text:      iup.Ihandle,
	date_text:      iup.Ihandle,
	status_label:   iup.Ihandle,
	add_button:     iup.Ihandle,
	value_count:    int,
	texts:          common.Trade_Texts,
}

_trade: Trade_State

// Returns an attribute value as an Odin string ("" when it is not set)
iup_attribute :: proc(ih: iup.Ihandle, name: cstring) -> string {
	value := iup.IupGetAttribute(ih, name)
	if value == nil {
		return ""
	}
	return string(value)
}

// Returns the 1-based index selected in a dropdown list (0 when none)
iup_list_index :: proc(list: iup.Ihandle) -> int {
	index, ok := strconv.parse_int(iup_attribute(list, "VALUE"))
	if !ok {
		return 0
	}
	return index
}

iup_entry_text :: proc(ih: iup.Ihandle) -> string {
	return strings.trim_space(iup_attribute(ih, "VALUE"))
}

iup_set_entry_text :: proc(ih: iup.Ihandle, text: string) {
	iup.IupStoreAttribute(ih, "VALUE", strings.clone_to_cstring(text))
}

trade_set_status :: proc(text: string) {
	iup.IupStoreAttribute(_trade.status_label, "TITLE", strings.clone_to_cstring(text))
}

// Fills the value dropdown with the tickers of the selected market, and enables
// the Add button only when there is something to choose
trade_refresh_values :: proc() {
	list := _trade.value_list

	// Remove the previously listed items
	for i in 1 ..= _trade.value_count {
		iup.IupSetAttribute(list, strings.clone_to_cstring(fmt.tprintf("%d", i)), nil)
	}
	_trade.value_count = 0

	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)
	market := iup_list_index(_trade.market_list)

	if broker != nil && market == MARKET_FUTURES_IUP {
		for contract in broker.futures_database {
			_trade.value_count += 1
			iup.IupStoreAttribute(
				list,
				strings.clone_to_cstring(fmt.tprintf("%d", _trade.value_count)),
				strings.clone_to_cstring(contract.ticker),
			)
		}
	}

	if _trade.value_count > 0 {
		iup.IupSetAttribute(list, "VALUE", "1")
	}
	iup.IupSetAttribute(_trade.add_button, "ACTIVE", _trade.value_count > 0 ? "YES" : "NO")
}

// Registers the trade described by the dialog fields in the active account
trade_add :: proc() {
	market := iup_list_index(_trade.market_list)
	value_index := iup_list_index(_trade.value_list)
	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)

	contract: dt.FutureContract
	if value_index <= 0 || broker == nil || market != MARKET_FUTURES_IUP {
		trade_set_status(string(_trade.texts.err_no_values))
		return
	}
	if value_index > len(broker.futures_database) {
		trade_set_status(string(_trade.texts.err_no_values))
		return
	}
	contract = broker.futures_database[value_index - 1]

	quantity, qty_ok := strconv.parse_int(iup_entry_text(_trade.amount_text))
	if !qty_ok || quantity <= 0 {
		trade_set_status(string(_trade.texts.err_quantity))
		return
	}

	entry, entry_ok := strconv.parse_f64(iup_entry_text(_trade.entry_text))
	exit, exit_ok := strconv.parse_f64(iup_entry_text(_trade.exit_text))
	if !entry_ok || !exit_ok {
		trade_set_status(string(_trade.texts.err_price))
		return
	}

	date := dt.current_date_number()
	if date_text := iup_entry_text(_trade.date_text); len(date_text) > 0 {
		parsed, date_ok := strconv.parse_int(date_text)
		if !date_ok || parsed < 10000101 {
			trade_set_status(string(_trade.texts.err_date))
			return
		}
		date = parsed
	}

	is_long := iup_attribute(_trade.long_toggle, "VALUE") == "ON"
	calc := dt.calculate_trade(contract, is_long, quantity, entry, exit)

	dt.record_trade(account, contract.ticker, is_long, quantity, entry, exit, calc.net_pnl, date)

	// Persist right away so a registered trade is not lost
	saved := dt.save_data("data.json", _app.data)

	status := fmt.tprintf(
		"%s %s x%d | Net: %.2f",
		string(_trade.texts.added),
		contract.ticker,
		quantity,
		calc.net_pnl,
	)
	trade_set_status(saved ? status : string(_trade.texts.err_save))

	// Clear the numeric fields, ready for the next trade
	iup_set_entry_text(_trade.amount_text, "")
	iup_set_entry_text(_trade.entry_text, "")
	iup_set_entry_text(_trade.exit_text, "")
}

// --- Callbacks --------------------------------------------------------------

on_trade_market_action :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	trade_refresh_values()
	return iup.DEFAULT
}

on_trade_add_action :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	trade_add()
	return iup.DEFAULT
}

// Closing the trade dialog re-enables the main window, which was disabled while
// the dialog was open, and hides the dialog so that it can be shown again.
// IUP_CLOSE must not be used here: returned by a child dialog it closes the main
// window instead.
on_trade_close_action :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	on_child_dialog_closed()
	iup.IupHide(_trade.dialog)
	return iup.DEFAULT
}

// Closing with the window X: hiding the dialog requires IUP_IGNORE, so that IUP
// does not close it (and with it the main window) a second time
on_trade_dialog_close :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	on_child_dialog_closed()
	iup.IupHide(_trade.dialog)
	return iup.IGNORE
}

// --- Layout helpers ---------------------------------------------------------

trade_field_label :: proc(text: cstring) -> iup.Ihandle {
	label := iup.IupLabel(text)
	iup.IupSetAttribute(label, "SIZE", "90x")
	return label
}

trade_row :: proc(label_text: cstring, widget: iup.Ihandle) -> iup.Ihandle {
	iup.IupSetAttribute(widget, "EXPAND", "HORIZONTAL")

	row := iup.Hbox(trade_field_label(label_text), widget)
	iup.IupSetAttribute(row, "GAP", "8")
	return row
}

// Builds the trade dialog; it is built once and then reused: closing it only
// hides it, so the next open just shows it again
trade_build_dialog :: proc() {
	_trade = Trade_State{}

	texts := common.get_trade_texts(_app.config.language)
	_trade.texts = texts

	account_label := iup.IupLabel(nil)
	iup.IupSetAttribute(account_label, "EXPAND", "HORIZONTAL")
	iup.IupSetAttribute(account_label, "ALIGNMENT", "ALEFT")
	_trade.account_label = account_label

	broker_label := iup.IupLabel(nil)
	iup.IupSetAttribute(broker_label, "EXPAND", "HORIZONTAL")
	iup.IupSetAttribute(broker_label, "ALIGNMENT", "ALEFT")
	_trade.broker_label = broker_label

	market_list := iup.IupList(nil)
	iup.IupSetAttribute(market_list, "DROPDOWN", "YES")
	for market_name, i in texts.markets {
		iup.IupStoreAttribute(
			market_list,
			strings.clone_to_cstring(fmt.tprintf("%d", i + 1)),
			market_name,
		)
	}
	_trade.market_list = market_list

	value_list := iup.IupList(nil)
	iup.IupSetAttribute(value_list, "DROPDOWN", "YES")
	_trade.value_list = value_list

	long_toggle := iup.IupToggle(texts.long, nil)
	short_toggle := iup.IupToggle(texts.short, nil)
	iup.IupSetAttribute(long_toggle, "RADIO", "YES")
	iup.IupSetAttribute(short_toggle, "RADIO", "YES")
	iup.IupSetAttribute(long_toggle, "VALUE", "ON")
	_trade.long_toggle = long_toggle
	_trade.short_toggle = short_toggle

	direction_row := iup.Hbox(trade_field_label(texts.direction), long_toggle, short_toggle)
	iup.IupSetAttribute(direction_row, "GAP", "8")

	amount_text := iup.IupText(nil)
	entry_text := iup.IupText(nil)
	exit_text := iup.IupText(nil)
	date_text := iup.IupText(nil)
	_trade.amount_text = amount_text
	_trade.entry_text = entry_text
	_trade.exit_text = exit_text
	_trade.date_text = date_text
	iup_set_entry_text(date_text, fmt.tprintf("%d", dt.current_date_number()))

	status_label := iup.IupLabel(nil)
	iup.IupSetAttribute(status_label, "EXPAND", "HORIZONTAL")
	iup.IupSetAttribute(status_label, "ALIGNMENT", "ACENTER")
	_trade.status_label = status_label

	add_button := iup.IupButton(texts.add, nil)
	_trade.add_button = add_button
	add_row := iup.Hbox(add_button)
	iup.IupSetAttribute(add_row, "ALIGNMENT", "ACENTER")

	close_button := iup.IupButton(texts.close, nil)
	close_row := iup.Hbox(close_button)
	iup.IupSetAttribute(close_row, "ALIGNMENT", "ARIGHT")

	vbox := iup.Vbox(
		account_label,
		broker_label,
		trade_row(texts.market, market_list),
		trade_row(texts.symbol, value_list),
		direction_row,
		trade_row(texts.amount, amount_text),
		trade_row(texts.entry, entry_text),
		trade_row(texts.exit, exit_text),
		trade_row(texts.date, date_text),
		add_row,
		status_label,
		close_row,
	)
	iup.IupSetAttribute(vbox, "MARGIN", "12x12")
	iup.IupSetAttribute(vbox, "GAP", "6")

	dialog := iup.IupDialog(vbox)
	iup.IupSetAttribute(dialog, "TITLE", texts.title)
	_trade.dialog = dialog

	iup.IupSetCallback(dialog, "CLOSE_CB", on_trade_dialog_close)
	iup.IupSetCallback(market_list, "ACTION", on_trade_market_action)
	iup.IupSetCallback(add_button, "ACTION", on_trade_add_action)
	iup.IupSetCallback(close_button, "ACTION", on_trade_close_action)
}

// Opens (or re-shows) the trade dialog, refreshing the account, broker and
// values. It is centered over the main window and the main window is disabled
// while it is open, so no other dialog can be opened.
open_trade_dialog :: proc() {
	if _app.dialog_open {
		return
	}
	if _trade.dialog == nil {
		trade_build_dialog()
	}

	texts := common.get_trade_texts(_app.config.language)
	_trade.texts = texts

	account := &_app.data.accounts[_app.data.active_account]
	broker := dt.get_account_broker(&_app.data, account)
	broker_name := broker != nil ? broker.name : "—"

	iup.IupStoreAttribute(
		_trade.account_label,
		"TITLE",
		strings.clone_to_cstring(fmt.tprintf("%s: %s", string(texts.account), account.name)),
	)
	iup.IupStoreAttribute(
		_trade.broker_label,
		"TITLE",
		strings.clone_to_cstring(fmt.tprintf("%s: %s", string(texts.broker), broker_name)),
	)

	trade_set_status("")
	iup.IupSetAttribute(_trade.market_list, "VALUE", "1") // futures
	trade_refresh_values()

	show_child_dialog(_trade.dialog)
}
