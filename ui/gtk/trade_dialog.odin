package gtk_ui

import dt "../../data"
import gio "../../lib/gtk4/glib/gio"
import gtk "../../lib/gtk4/gtk"
import runtime "base:runtime"
import "core:fmt"
import "core:strconv"
import "core:strings"

// ---------------------------------------------------------------------------
// Trade dialog: registers an already-closed trade in the active account.
//
// Layout: labels with the active account and its broker, a market combo and a
// value (contract) combo, the trade fields, and Add / Close buttons.
// ---------------------------------------------------------------------------

Trade_Texts :: struct {
	title:         cstring,
	account:       cstring,
	broker:        cstring,
	market:        cstring,
	symbol:        cstring,
	direction:     cstring,
	long:          cstring,
	short:         cstring,
	amount:        cstring,
	entry:         cstring,
	exit:          cstring,
	date:          cstring,
	add:           cstring,
	close:         cstring,
	markets:       [3]cstring, // futures, CFDs, forex
	err_no_values: cstring,
	err_quantity:  cstring,
	err_price:     cstring,
	err_date:      cstring,
	err_save:      cstring,
	added:         cstring, // prefix of the "added" status message
}

get_trade_texts :: proc(lang: dt.Language) -> Trade_Texts {
	switch lang {
	case .English:
		return Trade_Texts {
			title = cstring("Trade"),
			account = cstring("Account"),
			broker = cstring("Broker"),
			market = cstring("Market"),
			symbol = cstring("Symbol"),
			direction = cstring("Direction"),
			long = cstring("Long"),
			short = cstring("Short"),
			amount = cstring("Amount"),
			entry = cstring("Entry price"),
			exit = cstring("Exit price"),
			date = cstring("Date (YYYYMMDD)"),
			add = cstring("Add"),
			close = cstring("Close"),
			markets = {cstring("Futures"), cstring("CFDs"), cstring("Forex")},
			err_no_values = cstring("No values available for this market"),
			err_quantity = cstring("Invalid quantity"),
			err_price = cstring("Invalid price"),
			err_date = cstring("Invalid date"),
			err_save = cstring("Trade registered, but saving failed"),
			added = cstring("Added"),
		}
	case .Spanish:
		return Trade_Texts {
			title = cstring("Operar"),
			account = cstring("Cuenta"),
			broker = cstring("Broker"),
			market = cstring("Mercado"),
			symbol = cstring("Valor"),
			direction = cstring("Dirección"),
			long = cstring("Largos"),
			short = cstring("Cortos"),
			amount = cstring("Cantidad"),
			entry = cstring("Precio entrada"),
			exit = cstring("Precio salida"),
			date = cstring("Fecha (AAAAMMDD)"),
			add = cstring("Añadir"),
			close = cstring("Cerrar"),
			markets = {cstring("Futuros"), cstring("CFDs"), cstring("Forex")},
			err_no_values = cstring("No hay valores disponibles para este mercado"),
			err_quantity = cstring("Cantidad no válida"),
			err_price = cstring("Precio no válido"),
			err_date = cstring("Fecha no válida"),
			err_save = cstring("Operación registrada, pero falló el guardado"),
			added = cstring("Añadida"),
		}
	}
	return {}
}

// Which market database the market combo refers to (only futures have data now)
MARKET_FUTURES :: 0

Trade_Dialog_State :: struct {
	window:          ^gtk.Window,
	ctx:             ^Context,
	texts:           Trade_Texts,
	market_combo:    ^gtk.Widget,
	value_combo:     ^gtk.Widget,
	long_check:      ^gtk.Widget,
	short_check:     ^gtk.Widget,
	contracts_entry: ^gtk.Widget,
	entry_entry:     ^gtk.Widget,
	exit_entry:      ^gtk.Widget,
	date_entry:      ^gtk.Widget,
	status_label:    ^gtk.Widget,
	add_button:      ^gtk.Widget,
}

trade_active_account :: proc(state: ^Trade_Dialog_State) -> ^dt.Account {
	return &state.ctx.data.accounts[state.ctx.data.active_account]
}

trade_entry_text :: proc(widget: ^gtk.Widget) -> string {
	text := gtk.editable_get_text(cast(^gtk.Editable)widget)
	if text == nil {
		return ""
	}
	return strings.trim_space(string(text))
}

trade_set_entry_text :: proc(widget: ^gtk.Widget, text: string) {
	gtk.editable_set_text(cast(^gtk.Editable)widget, strings.clone_to_cstring(text))
}

trade_set_status :: proc(state: ^Trade_Dialog_State, text: string) {
	gtk.label_set_text(cast(^gtk.Label)state.status_label, strings.clone_to_cstring(text))
}

// Fills the value combo with the values of the selected market and enables the
// Add button only when there is something to choose
trade_populate_values :: proc(state: ^Trade_Dialog_State) {
	combo := cast(^gtk.ComboBoxText)state.value_combo
	gtk.combo_box_text_remove_all(combo)

	broker := dt.get_account_broker(&state.ctx.data, trade_active_account(state))
	market := gtk.combo_box_get_active(cast(^gtk.ComboBox)state.market_combo)
	count := 0

	if broker != nil && market == MARKET_FUTURES {
		for contract in broker.futures_database {
			gtk.combo_box_text_append_text(combo, strings.clone_to_cstring(contract.ticker))
			count += 1
		}
	}

	if count > 0 {
		gtk.combo_box_set_active(cast(^gtk.ComboBox)state.value_combo, 0)
	}
	gtk.widget_set_sensitive(state.add_button, b32(count > 0))
}

on_trade_market_changed :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	state := cast(^Trade_Dialog_State)user_data

	context = runtime.default_context()
	context.allocator = state.ctx.alloc
	context.temp_allocator = state.ctx.temp_alloc

	trade_populate_values(state)
}

on_trade_add :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	state := cast(^Trade_Dialog_State)user_data

	context = runtime.default_context()
	context.allocator = state.ctx.alloc
	context.temp_allocator = state.ctx.temp_alloc

	market := gtk.combo_box_get_active(cast(^gtk.ComboBox)state.market_combo)
	value_index := gtk.combo_box_get_active(cast(^gtk.ComboBox)state.value_combo)
	broker := dt.get_account_broker(&state.ctx.data, trade_active_account(state))

	contract: dt.FutureContract
	if value_index < 0 || broker == nil || market != MARKET_FUTURES {
		trade_set_status(state, string(state.texts.err_no_values))
		return
	}
	if int(value_index) >= len(broker.futures_database) {
		trade_set_status(state, string(state.texts.err_no_values))
		return
	}
	contract = broker.futures_database[value_index]

	quantity, qty_ok := strconv.parse_int(trade_entry_text(state.contracts_entry))
	if !qty_ok || quantity <= 0 {
		trade_set_status(state, string(state.texts.err_quantity))
		return
	}

	entry, entry_ok := strconv.parse_f64(trade_entry_text(state.entry_entry))
	exit, exit_ok := strconv.parse_f64(trade_entry_text(state.exit_entry))
	if !entry_ok || !exit_ok {
		trade_set_status(state, string(state.texts.err_price))
		return
	}

	date := dt.current_date_number()
	if date_text := trade_entry_text(state.date_entry); len(date_text) > 0 {
		parsed, date_ok := strconv.parse_int(date_text)
		if !date_ok || parsed < 10000101 {
			trade_set_status(state, string(state.texts.err_date))
			return
		}
		date = parsed
	}

	is_long := gtk.check_button_get_active(cast(^gtk.CheckButton)state.long_check)
	calc := dt.calculate_trade(contract, is_long, quantity, entry, exit)

	dt.record_trade(
		trade_active_account(state),
		contract.ticker,
		is_long,
		quantity,
		entry,
		exit,
		calc.net_pnl,
		date,
	)

	// Persist right away so a registered trade is not lost
	saved := dt.save_data("data.json", state.ctx.data)

	status := fmt.tprintf(
		"%s %s x%d | Net: %.2f",
		string(state.texts.added),
		contract.ticker,
		quantity,
		calc.net_pnl,
	)
	trade_set_status(state, saved ? status : string(state.texts.err_save))

	// Clear the numeric fields, ready for the next trade
	trade_set_entry_text(state.contracts_entry, "")
	trade_set_entry_text(state.entry_entry, "")
	trade_set_entry_text(state.exit_entry, "")
}

on_trade_close :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	state := cast(^Trade_Dialog_State)user_data
	gtk.window_close(state.window)
}

// Creates a label + widget row inside the given box
trade_add_row :: proc(root: ^gtk.Widget, label_text: cstring, widget: ^gtk.Widget) {
	row := gtk.box_new(.Horizontal, 8)

	label := gtk.label_new(label_text)
	gtk.widget_set_size_request(label, 130, -1)
	gtk.widget_set_halign(label, .Start)
	gtk.box_append(cast(^gtk.Box)row, label)

	gtk.widget_set_hexpand(widget, b32(true))
	gtk.box_append(cast(^gtk.Box)row, widget)

	gtk.box_append(cast(^gtk.Box)root, row)
}

open_trade_dialog :: proc(ctx: ^Context) {
	texts := get_trade_texts(ctx.config.language)

	state := new(Trade_Dialog_State)
	state.ctx = ctx
	state.texts = texts

	account := &ctx.data.accounts[ctx.data.active_account]
	broker := dt.get_account_broker(&ctx.data, account)

	dialog := cast(^gtk.Window)gtk.window_new()
	state.window = dialog
	gtk.window_set_title(dialog, texts.title)
	gtk.window_set_default_size(dialog, 460, 560)
	gtk.window_set_transient_for(dialog, ctx.window)
	gtk.window_set_modal(dialog, b32(true))

	root := gtk.box_new(.Vertical, 8)
	gtk.widget_set_margin_top(root, 20)
	gtk.widget_set_margin_bottom(root, 20)
	gtk.widget_set_margin_start(root, 20)
	gtk.widget_set_margin_end(root, 20)

	// --- Active account and its broker --------------------------------------
	account_text := fmt.tprintf("%s: %s", string(texts.account), account.name)
	account_label := gtk.label_new(strings.clone_to_cstring(account_text))
	gtk.widget_set_halign(account_label, .Start)
	gtk.box_append(cast(^gtk.Box)root, account_label)

	broker_text := fmt.tprintf("%s: %s", string(texts.broker), broker != nil ? broker.name : "—")
	broker_label := gtk.label_new(strings.clone_to_cstring(broker_text))
	gtk.widget_set_halign(broker_label, .Start)
	gtk.widget_set_margin_bottom(broker_label, 8)
	gtk.box_append(cast(^gtk.Box)root, broker_label)

	// --- Market and value combos --------------------------------------------
	market_combo := gtk.combo_box_text_new()
	state.market_combo = market_combo
	for market_name in texts.markets {
		gtk.combo_box_text_append_text(cast(^gtk.ComboBoxText)market_combo, market_name)
	}
	trade_add_row(root, texts.market, market_combo)

	value_combo := gtk.combo_box_text_new()
	state.value_combo = value_combo
	trade_add_row(root, texts.symbol, value_combo)

	// --- Direction (grouped check buttons behave like radio buttons) --------
	direction_row := gtk.box_new(.Horizontal, 8)
	direction_label := gtk.label_new(texts.direction)
	gtk.widget_set_size_request(direction_label, 130, -1)
	gtk.widget_set_halign(direction_label, .Start)
	gtk.box_append(cast(^gtk.Box)direction_row, direction_label)

	long_check := gtk.check_button_new_with_label(texts.long)
	short_check := gtk.check_button_new_with_label(texts.short)
	gtk.check_button_set_group(cast(^gtk.CheckButton)short_check, cast(^gtk.CheckButton)long_check)
	state.long_check = long_check
	state.short_check = short_check
	gtk.box_append(cast(^gtk.Box)direction_row, long_check)
	gtk.box_append(cast(^gtk.Box)direction_row, short_check)
	gtk.box_append(cast(^gtk.Box)root, direction_row)

	// --- Trade fields -------------------------------------------------------
	contracts_entry := gtk.entry_new()
	state.contracts_entry = contracts_entry
	trade_add_row(root, texts.amount, contracts_entry)

	entry_entry := gtk.entry_new()
	state.entry_entry = entry_entry
	trade_add_row(root, texts.entry, entry_entry)

	exit_entry := gtk.entry_new()
	state.exit_entry = exit_entry
	trade_add_row(root, texts.exit, exit_entry)

	date_entry := gtk.entry_new()
	state.date_entry = date_entry
	trade_add_row(root, texts.date, date_entry)
	gtk.editable_set_text(
		cast(^gtk.Editable)date_entry,
		strings.clone_to_cstring(fmt.tprintf("%d", dt.current_date_number())),
	)

	// --- Add button, centered below the last field --------------------------
	add_button := gtk.button_new_with_label(texts.add)
	state.add_button = add_button
	gtk.widget_set_size_request(add_button, 140, -1)
	gtk.widget_set_halign(add_button, .Center)
	gtk.widget_set_margin_top(add_button, 16)
	gtk.box_append(cast(^gtk.Box)root, add_button)

	// --- Status message, below the Add button -------------------------------
	status_label := gtk.label_new(cstring(""))
	state.status_label = status_label
	gtk.widget_set_halign(status_label, .Center)
	gtk.widget_set_margin_top(status_label, 8)
	gtk.box_append(cast(^gtk.Box)root, status_label)

	// --- Close button, bottom right -----------------------------------------
	close_row := gtk.box_new(.Horizontal, 0)
	gtk.widget_set_halign(close_row, .End)
	gtk.widget_set_margin_top(close_row, 16)
	gtk.box_append(cast(^gtk.Box)root, close_row)

	close_button := gtk.button_new_with_label(texts.close)
	gtk.box_append(cast(^gtk.Box)close_row, close_button)

	gio.signal_connect(close_button, "clicked", on_trade_close, gio.Pointer(state))
	gio.signal_connect(add_button, "clicked", on_trade_add, gio.Pointer(state))
	gio.signal_connect(market_combo, "changed", on_trade_market_changed, gio.Pointer(state))

	// Initial selection: futures, long, today, and its values
	gtk.check_button_set_active(cast(^gtk.CheckButton)long_check, b32(true))
	gtk.combo_box_set_active(cast(^gtk.ComboBox)market_combo, MARKET_FUTURES)
	trade_populate_values(state)

	gtk.window_set_child(dialog, root)
	gtk.window_present(dialog)
}
