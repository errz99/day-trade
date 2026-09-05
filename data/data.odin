package data

import "core:os"
import "core:strings"

// 1. Structure definition for futures contracts
FutureContract :: struct {
	name:          string,
	ticker:        string,
	tick_size:     f64, // Minimum price movement (e.g., 0.25)
	point_value:   f64, // Value in base currency of 1 full point (e.g., $2 or 2€)
	cost_per_side: f64, // Commission fee per side (open or close) for 1 contract
}

// Supported languages for user interface
Language :: enum {
	Spanish,
	English,
}

// Result of trade calculation
TradeCalculation :: struct {
	points_pnl:  f64,
	gross_pnl:   f64,
	total_costs: f64,
	net_pnl:     f64,
}

// Creates and populates the map of supported market indices
get_market_database :: proc(allocator := context.allocator) -> map[string]FutureContract {
	market_database := make(map[string]FutureContract, allocator)

	market_database["nasdaq"] = FutureContract{"Micro E-mini Nasdaq 100", "MNQ", 0.25, 2.0, 0.60}
	market_database["s&p"] = FutureContract{"Micro E-mini S&P 500", "MES", 0.25, 5.0, 0.60}
	market_database["dow jones"] = FutureContract{"Micro E-mini Dow Jones", "MYM", 1.00, 0.5, 0.60}
	market_database["russell"] = FutureContract{
		"Micro E-mini Russell 2000",
		"M2K",
		0.10,
		5.0,
		0.60,
	}
	market_database["mini dax"] = FutureContract{"Mini Dax", "FDXM", 1, 5, 1.25}
	market_database["micro dax"] = FutureContract{"Micro Dax", "FDXS", 1, 1, 0.75}
	market_database["eurostoxx"] = FutureContract{"EuroStoxx", "FESX", 1, 10, 3.50}

	return market_database
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

	return TradeCalculation{
		points_pnl  = points_pnl,
		gross_pnl   = gross_pnl,
		total_costs = total_costs,
		net_pnl     = net_pnl,
	}
}

// Reads configuration file to determine language; defaults to Spanish and writes config.ini if missing
load_language_config :: proc(filepath: string) -> Language {
	data, err := os.read_entire_file(filepath, context.temp_allocator)
	if err != os.ERROR_NONE {
		default_config := "# Language configuration: \"en\" for English, \"es\" for Spanish\nlanguage = es\n"
		_ = os.write_entire_file(filepath, transmute([]byte)default_config)
		return .Spanish
	}

	content := string(data)
	lines := strings.split_lines(content, context.temp_allocator)
	for line in lines {
		trimmed := strings.trim_space(line)
		if len(trimmed) == 0 || strings.has_prefix(trimmed, "#") || strings.has_prefix(trimmed, ";") {
			continue
		}

		parts := strings.split(trimmed, "=", context.temp_allocator)
		if len(parts) == 2 {
			key := strings.to_lower(strings.trim_space(parts[0]))
			val := strings.to_lower(strings.trim_space(parts[1]))
			if key == "language" || key == "lang" {
				if strings.has_prefix(val, "en") {
					return .English
				} else if strings.has_prefix(val, "es") {
					return .Spanish
				}
			}
		}
	}

	return .Spanish
}

// Appends a trade log line to the specified file
append_trade_log :: proc(filepath: string, log_line: string) -> bool {
	file_handle, err := os.open(
		filepath,
		os.O_WRONLY | os.O_CREATE | os.O_APPEND,
	)
	if err != os.ERROR_NONE {
		return false
	}
	defer os.close(file_handle)

	os.write(file_handle, transmute([]byte)log_line)
	return true
}
