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
	alias:            string,
	futures_database: [dynamic]FutureContract,
	cfds_database:    [dynamic]CFD_Contract,
	forex_database:   [dynamic]ForexPair,
}

// Account groups a trading account with the index of the broker it trades with
// (an index into Data.brokers) and its trade history
Account :: struct {
	name:         string,
	broker_index: int,
	trades:       [dynamic]Trade,
}

// Data is the top-level application state; it will grow as more data is added.
// active_account / active_broker index the account and broker currently in use
Data :: struct {
	accounts:       [dynamic]Account,
	active_account: int,
	brokers:        [dynamic]Broker,
	active_broker:  int,
}

// Creates a new broker with empty market databases; name and alias identify it.
// Market data is meant to be filled in later (eventually from the UI)
new_broker :: proc(name, alias: string, allocator := context.allocator) -> Broker {
	broker := Broker {
		name             = name,
		alias            = alias,
		futures_database = make([dynamic]FutureContract, 0, allocator),
		cfds_database    = make([dynamic]CFD_Contract, 0, allocator),
		forex_database   = make([dynamic]ForexPair, 0, allocator),
	}
	return broker
}

// Per-side commissions for the built-in futures, one field per contract
Builtin_Commissions :: struct {
	nasdaq, sp, dow, russell, mini_dax, micro_dax, eurostoxx: f64,
}

// Fills a broker's futures database with the built-in contracts, using the given
// per-side commissions.
// NOTE: temporary seed data, just a starting point; it will be removed once
// market data can be entered from the UI
@(private = "file")
seed_builtin_futures :: proc(broker: ^Broker, c: Builtin_Commissions) {
	append(
		&broker.futures_database,
		FutureContract{"Micro E-mini Nasdaq 100", "nasdaq", "MNQ", 0.25, 2.0, c.nasdaq},
		FutureContract{"Micro E-mini S&P 500", "s&p", "MES", 0.25, 5.0, c.sp},
		FutureContract{"Micro E-mini Dow Jones", "dow jones", "MYM", 1.00, 0.5, c.dow},
		FutureContract{"Micro E-mini Russell 2000", "russell", "M2K", 0.10, 5.0, c.russell},
		FutureContract{"Mini Dax", "mini dax", "FDXM", 1, 5, c.mini_dax},
		FutureContract{"Micro Dax", "micro dax", "FDXS", 1, 1, c.micro_dax},
		FutureContract{"EuroStoxx", "eurostoxx", "FESX", 1, 10, c.eurostoxx},
	)
}

// Finds a futures contract by its alias (e.g. "nasdaq"); returns false when the
// alias is not present in the given database
find_future_by_alias :: proc(
	contracts: []FutureContract,
	alias: string,
) -> (
	FutureContract,
	bool,
) {
	for contract in contracts {
		if contract.alias == alias {
			return contract, true
		}
	}
	return {}, false
}

// Builds the initial broker set: the Interactive Broker one and iBroker, both
// seeded with the built-in futures and their respective per-side commissions
// (temporary, to be completed from the UI later). The first element is the
// default broker (index 0).
//
// Commissions captured from each broker's public schedule. Currency follows the
// contract: USD for the CME/CBOT micros, EUR for the Eurex products.
new_default_brokers :: proc(allocator := context.allocator) -> [dynamic]Broker {
	brokers := make([dynamic]Broker, 0, 2, allocator)

	// IBKR (fixed): execution 0.25 USD + exchange/regulatory recovery for the
	// micros; Eurex flat fees (Mini/Micro-DAX, "everything else" for EuroStoxx)
	ibkr := new_broker("Interactive Broker", "ibkr", allocator)
	seed_builtin_futures(
		&ibkr,
		{
			nasdaq = 0.62,
			sp = 0.62,
			dow = 0.61,
			russell = 0.62,
			mini_dax = 0.80,
			micro_dax = 0.40,
			eurostoxx = 2.00, // IBKR "everything else" row; to confirm
		},
	)
	append(&brokers, ibkr)

	// iBroker: total commission per contract (Micro E-mini 1.25 USD, EuroStoxx
	// 3.50 EUR). Mini/Micro-DAX pending: 0.0 until confirmed by hand
	ibroker := new_broker("iBroker", "ibroker", allocator)
	seed_builtin_futures(
		&ibroker,
		{
			nasdaq = 1.25,
			sp = 1.25,
			dow = 1.25,
			russell = 1.25,
			mini_dax = 0.0, // TODO: confirm iBroker Mini-DAX commission
			micro_dax = 0.0, // TODO: confirm iBroker Micro-DAX commission
			eurostoxx = 3.50,
		},
	)
	append(&brokers, ibroker)

	return brokers
}

// Returns the broker an account trades with; nil when the index is out of range
get_account_broker :: proc(trading_data: ^Data, account: ^Account) -> ^Broker {
	if account.broker_index < 0 || account.broker_index >= len(trading_data.brokers) {
		return nil
	}
	return &trading_data.brokers[account.broker_index]
}

// Creates the default account, trading with the broker at broker_index
new_default_account :: proc(broker_index := 0, allocator := context.allocator) -> Account {
	account := Account {
		name         = "Default",
		broker_index = broker_index,
		trades       = make([dynamic]Trade, 0, allocator),
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

// Creates the initial application data, holding the default brokers and account
new_default_data :: proc(allocator := context.allocator) -> Data {
	trading_data := Data {
		accounts       = make([dynamic]Account, 0, 1, allocator),
		active_account = 0,
		brokers        = new_default_brokers(allocator),
		active_broker  = 0, // the first broker is the default one
	}
	append(&trading_data.accounts, new_default_account(0, allocator))
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

	// Migration: files saved before brokers lived in Data.brokers (they embedded
	// a broker in each account) are loaded without brokers, so the default set
	// is created and the accounts are pointed at the default broker
	if len(trading_data.brokers) == 0 {
		trading_data.brokers = new_default_brokers(allocator)
		trading_data.active_broker = 0
	}
	for &account in trading_data.accounts {
		if account.broker_index < 0 || account.broker_index >= len(trading_data.brokers) {
			account.broker_index = 0
		}
	}
	if trading_data.active_broker < 0 || trading_data.active_broker >= len(trading_data.brokers) {
		trading_data.active_broker = 0
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
