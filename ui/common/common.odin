package common

import dt "../../data"
import "core:mem"

// ============================================================================
// Localized texts and actions shared by the graphical UIs (GTK and IUP)
// ============================================================================

// Localized texts for the main menu window
Menu_Texts :: struct {
	account: cstring, // Account / Cuenta
	trade:   cstring, // Trade / Operar
	results: cstring, // Results / Resultados
	config:  cstring, // Config
	exit:    cstring, // Exit / Salida
	pending: cstring, // placeholder hint shown in not-yet-implemented dialogs
}

// Returns the localized texts for the given language
get_menu_texts :: proc(lang: dt.Language) -> Menu_Texts {
	switch lang {
	case .English:
		return Menu_Texts {
			account = cstring("Account"),
			trade   = cstring("Trade"),
			results = cstring("Results"),
			config  = cstring("Config"),
			exit    = cstring("Exit"),
			pending = cstring("Not implemented yet"),
		}
	case .Spanish:
		return Menu_Texts {
			account = cstring("Cuenta"),
			trade   = cstring("Operar"),
			results = cstring("Resultados"),
			config  = cstring("Config"),
			exit    = cstring("Salida"),
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

// NOTE: kept as a package variable (not a constant) because some UIs index it
// with a runtime index, which is not allowed on constant arrays
MENU_ACTIONS := [?]MenuAction{.Trade, .Results, .Account, .Config, .Exit}

// Returns the localized title for the given menu action
action_title :: proc(texts: Menu_Texts, action: MenuAction) -> cstring {
	switch action {
	case .Trade:   return texts.trade
	case .Results: return texts.results
	case .Account: return texts.account
	case .Config:  return texts.config
	case .Exit:    return texts.exit
	}
	return ""
}

// ============================================================================
// Texts of the Trade dialog, shared by the graphical UIs
// ============================================================================

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

// ============================================================================
// Shared session bootstrap, used by all UIs (tui, gtk, iup)
// ============================================================================

// Loads the session data from the given JSON file. Falls back to the default
// account data when the file is missing or holds no accounts, and clamps
// active_account to a valid index. Everything is allocated through `allocator`.
load_session_data :: proc(filepath: string, allocator := context.allocator) -> dt.Data {
	trading_data: dt.Data
	if loaded, ok := dt.load_data(filepath, allocator); ok {
		trading_data = loaded
	} else {
		trading_data = dt.new_default_data(allocator)
	}
	if len(trading_data.accounts) == 0 {
		trading_data = dt.new_default_data(allocator)
	}
	if trading_data.active_account < 0 || trading_data.active_account >= len(trading_data.accounts) {
		trading_data.active_account = 0
	}
	return trading_data
}

// Initializes a dynamic arena and installs it as the context allocator, so that
// everything allocated during the session (including the loaded JSON data) is
// released wholesale at the end. Returns the arena allocator, which UIs store
// to restore the session context inside their "c" callbacks. The caller is
// responsible for destroying the arena when the session ends.
begin_session_arena :: proc(arena: ^mem.Dynamic_Arena) -> mem.Allocator {
	mem.dynamic_arena_init(arena)
	alloc := mem.dynamic_arena_allocator(arena)
	context.allocator = alloc
	return alloc
}
