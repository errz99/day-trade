package data

import runtime "base:runtime"
import "core:encoding/json"
import "core:io"
import "core:os"
import "core:strconv"

// Supported languages for user interface
Language :: enum {
	Spanish,
	English,
}

// Structure definition for futures contracts
FutureContract :: struct {
	name:          string,
	alias:         string,
	ticker:        string,
	tick_size:     f64, // Minimum price movement (e.g., 0.25)
	point_value:   f64, // Value in base currency of 1 full point (e.g., $2 or 2€)
	cost_per_side: f64, // Commission fee per side (open or close) for 1 contract
}

// Structure definition for CFD contracts
CFD_Contract :: struct {
	name:   string,
	alias:  string,
	ticker: string,
}

// Structure definition for Forex pairs
ForexPair :: struct {
	name:   string,
	alias:  string,
	ticker: string,
}

// Result of trade calculation
TradeCalculation :: struct {
	points_pnl:  f64,
	gross_pnl:   f64,
	total_costs: f64,
	net_pnl:     f64,
}

// A finished trade registered in an account's history (mirrors what is logged
// to historial_trading.txt); direction is kept semantically as is_long
Trade :: struct {
	ticker:   string, // market ticker (e.g., "MES")
	is_long:  bool, // trade direction: long or short
	quantity: int, // number of contracts traded
	entry:    f64, // entry price
	exit:     f64, // exit price
	net_pnl:  f64, // net result after commissions
}

// Broker groups a trading venue with its tradeable markets. Each market type
// has its own database; futures are populated by default, the rest are empty
// for now (to be filled in as those markets are implemented)
Broker :: struct {
	name:             string,
	futures_database: [dynamic]FutureContract,
	cfds_database:    [dynamic]CFD_Contract,
	forex_database:   [dynamic]ForexPair,
}

// Account groups a trading account with its broker and its trade history
Account :: struct {
	name:   string,
	broker: Broker,
	trades: [dynamic]Trade,
}

// Data is the top-level application state; it will grow as more data is added.
// active_account indexes the account currently in use
Data :: struct {
	accounts:       [dynamic]Account,
	active_account: int,
}

// Creates the default broker, whose futures database holds the supported indices
new_default_broker :: proc(allocator := context.allocator) -> Broker {
	broker := Broker {
		name             = "Default",
		futures_database = make([dynamic]FutureContract, 0, 7, allocator),
		cfds_database    = make([dynamic]CFD_Contract, 0, allocator),
		forex_database   = make([dynamic]ForexPair, 0, allocator),
	}

	append(
		&broker.futures_database,
		FutureContract{"Micro E-mini Nasdaq 100", "nasdaq", "MNQ", 0.25, 2.0, 0.60},
		FutureContract{"Micro E-mini S&P 500", "s&p", "MES", 0.25, 5.0, 0.60},
		FutureContract{"Micro E-mini Dow Jones", "dow jones", "MYM", 1.00, 0.5, 0.60},
		FutureContract{"Micro E-mini Russell 2000", "russell", "M2K", 0.10, 5.0, 0.60},
		FutureContract{"Mini Dax", "mini dax", "FDXM", 1, 5, 1.25},
		FutureContract{"Micro Dax", "micro dax", "FDXS", 1, 1, 0.75},
		FutureContract{"EuroStoxx", "eurostoxx", "FESX", 1, 10, 3.50},
	)

	return broker
}

// Finds a futures contract by its alias (e.g. "nasdaq"); returns false when the
// alias is not present in the given database
find_future_by_alias :: proc(contracts: []FutureContract, alias: string) -> (FutureContract, bool) {
	for contract in contracts {
		if contract.alias == alias {
			return contract, true
		}
	}
	return {}, false
}

// Creates the default account, holding the default broker and its market database
new_default_account :: proc(allocator := context.allocator) -> Account {
	account := Account {
		name   = "Default",
		broker = new_default_broker(allocator),
	}
	return account
}

// Appends a finished trade to the account's trade history
record_trade :: proc(
	account: ^Account,
	ticker: string,
	is_long: bool,
	quantity: int,
	entry: f64,
	exit: f64,
	net_pnl: f64,
) {
	append(
		&account.trades,
		Trade {
			ticker = ticker,
			is_long = is_long,
			quantity = quantity,
			entry = entry,
			exit = exit,
			net_pnl = net_pnl,
		},
	)
}

// Creates the initial application data, holding the default account
new_default_data :: proc(allocator := context.allocator) -> Data {
	trading_data := Data {
		accounts       = make([dynamic]Account, 0, 1, allocator),
		active_account = 0,
	}
	append(&trading_data.accounts, new_default_account(allocator))
	return trading_data
}

// Custom float marshaler: writes the shortest round-trip representation
// (e.g. 2.0 -> "2", 0.60 -> "0.6") instead of the full 16-decimal form
_json_marshalers: map[typeid]json.User_Marshaler
_json_marshalers_ready := false

marshal_f64 :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
	buf: [64]byte
	s := strconv.write_float(buf[:], v.(f64), 'g', -1, 64)
	// write_float always emits a sign; JSON numbers cannot carry a leading '+'
	if len(s) > 0 && s[0] == '+' {
		s = s[1:]
	}
	io.write_string(w, s) or_return
	return nil
}

_init_json_marshalers :: proc() {
	if _json_marshalers_ready {
		return
	}
	// The user-marshaler registry is process-global and outlives the per-session
	// arena, and its backing map requires cache-line (64-byte) aligned memory.
	// Allocate it with the default heap allocator instead of context.allocator
	// (which is the session arena while saving from UI callbacks) so the map
	// allocation never depends on arena alignment behaviour.
	session_alloc := context.allocator
	context.allocator = runtime.heap_allocator()
	json.set_user_marshalers(&_json_marshalers)
	_ = json.register_user_marshaler(typeid_of(f64), marshal_f64)
	context.allocator = session_alloc

	_json_marshalers_ready = true
}

// Saves the given Data to filepath in JSON format, with map keys sorted and
// floats written in their shortest form
save_data :: proc(filepath: string, trading_data: Data, allocator := context.allocator) -> bool {
	_init_json_marshalers()

	json_bytes, err := json.marshal(trading_data, {sort_maps_by_key = true}, allocator = allocator)
	if err != nil {
		return false
	}
	defer delete(json_bytes)

	return os.write_entire_file(filepath, json_bytes) == os.ERROR_NONE
}

// Loads Data from a JSON file; returns false when the file is missing or cannot be parsed
load_data :: proc(filepath: string, allocator := context.allocator) -> (Data, bool) {
	content, err := os.read_entire_file(filepath, allocator)
	if err != os.ERROR_NONE {
		return Data{}, false
	}
	defer delete(content)

	trading_data: Data
	if json_err := json.unmarshal(content, &trading_data, allocator = allocator); json_err != nil {
		return Data{}, false
	}

	// Migration: files saved before futures were kept in a dynamic array (they
	// used a market_database map) are loaded with an empty futures database
	for &account in trading_data.accounts {
		if len(account.broker.futures_database) == 0 {
			defaults := new_default_broker(allocator)
			account.broker.futures_database = defaults.futures_database
		}
	}

	return trading_data, true
}

// Mathematical calculations for futures PnL
calculate_trade :: proc(
	contract: FutureContract,
	is_long: bool,
	contracts_qty: int,
	price_entry: f64,
	price_exit: f64,
) -> TradeCalculation {
	points_pnl: f64 = 0.0
	if is_long {
		points_pnl = price_exit - price_entry
	} else {
		points_pnl = price_entry - price_exit
	}

	gross_pnl := points_pnl * contract.point_value * f64(contracts_qty)
	total_costs := (contract.cost_per_side * 2.0) * f64(contracts_qty)
	net_pnl := gross_pnl - total_costs

	return TradeCalculation {
		points_pnl = points_pnl,
		gross_pnl = gross_pnl,
		total_costs = total_costs,
		net_pnl = net_pnl,
	}
}

// Appends a trade log line to the specified file
append_trade_log :: proc(filepath: string, log_line: string) -> bool {
	file_handle, err := os.open(filepath, os.O_WRONLY | os.O_CREATE | os.O_APPEND)
	if err != os.ERROR_NONE {
		return false
	}
	defer os.close(file_handle)

	os.write(file_handle, transmute([]byte)log_line)
	return true
}
