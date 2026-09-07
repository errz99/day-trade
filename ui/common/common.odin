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
