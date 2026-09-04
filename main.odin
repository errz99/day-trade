package main

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strconv"
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

// Localized strings container
Messages :: struct {
	banner:             string,
	prompt_market:      string,
	unsupported_market: string,
	selected_contract:  string,
	prompt_direction:   string,
	prompt_qty:         string,
	prompt_entry:       string,
	prompt_exit:        string,
	net_result:         string,
	gross_and_costs:    string,
	file_open_error:    string,
	log_format:         string,
	log_success:        string,
}

// Returns localized messages for the specified language
get_messages :: proc(lang: Language) -> Messages {
	switch lang {
	case .English:
		return Messages{
			banner             = "--- 📈 FUTURES CALCULATOR & LOGGER (ODIN) ---",
			prompt_market      = "Enter index (nasdaq, s&p, dow jones, russell, mini dax, micro dax, eurostoxx): ",
			unsupported_market = "❌ Unsupported market. Please enter one from the list.",
			selected_contract  = "📌 Selected: %s (%s) [Point Value: %.2f€]\n",
			prompt_direction   = "Direction? Long (L) or Short (S/C): ",
			prompt_qty         = "Quantity of contracts to trade: ",
			prompt_entry       = "ENTRY price: ",
			prompt_exit        = "EXIT price: ",
			net_result         = "\n-------------------------------------------\n📊 NET RESULT: %.2f €\n",
			gross_and_costs    = "💰 Gross Profit: %.2f € | 💸 Commissions paid: %.2f €\n-------------------------------------------\n",
			file_open_error    = "⚠️ Could not open file to save trade operation.",
			log_format         = "Market: %s | Type: %s | Contracts: %d | Entry: %.2f | Exit: %.2f | Net PnL: %.2f €\n",
			log_success        = "💾 Trade successfully logged to 'historial_trading.txt'!",
		}
	case .Spanish:
		return Messages{
			banner             = "--- 📈 CALCULADORA DE FUTUROS & REGISTRO (ODIN) ---",
			prompt_market      = "Introduce el índice (nasdaq, s&p, dow jones, russell, mini dax, micro dax, eurostoxx): ",
			unsupported_market = "❌ Mercado no soportado. Introduce uno de la lista.",
			selected_contract  = "📌 Seleccionado: %s (%s) [Valor Punto: %.2f€]\n",
			prompt_direction   = "¿Dirección? Largos (L) o Cortos (C): ",
			prompt_qty         = "Cantidad de contratos a operar: ",
			prompt_entry       = "Precio de ENTRADA: ",
			prompt_exit        = "Precio de SALIDA: ",
			net_result         = "\n-------------------------------------------\n📊 RESULTADO NETO: %.2f €\n",
			gross_and_costs    = "💰 Beneficio Bruto: %.2f € | 💸 Comisiones pagadas: %.2f €\n-------------------------------------------\n",
			file_open_error    = "⚠️ No se pudo abrir el archivo para guardar la operación.",
			log_format         = "Mercado: %s | Tipo: %s | Contratos: %d | Entrada: %.2f | Salida: %.2f | PnL Neto: %.2f €\n",
			log_success        = "💾 ¡Operación registrada con éxito en 'historial_trading.txt'!",
		}
	}
	return Messages{}
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

main :: proc() {
	defer free_all(context.temp_allocator)

	// Load language settings from configuration
	lang := load_language_config("config.ini")
	msg := get_messages(lang)

	// Terminal input reader setup
	reader: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buffer[:])

	// 2. Create and populate map of market indices (Micro E-mini and Mini contracts)
	// Note: Point value is calibrated to euros or dollars depending on broker settings.
	market_database := make(map[string]FutureContract)
	defer delete(market_database) // Best practice: free map upon exit

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

	fmt.println(msg.banner)

	// 3. Prompt for and validate index selection
	fmt.print(msg.prompt_market)
	asset_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	asset_input := strings.to_lower(strings.trim_space(string(asset_bytes)))

	contract, exists := market_database[asset_input]
	if !exists {
		fmt.println(msg.unsupported_market)
		return
	}
	fmt.printf(
		msg.selected_contract,
		contract.name,
		contract.ticker,
		contract.point_value,
	)

	// 4. Prompt for order direction (Long vs Short)
	fmt.print(msg.prompt_direction)
	type_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	raw_dir := strings.to_upper(strings.trim_space(string(type_bytes)))

	is_long := (raw_dir == "L")
	is_short := (raw_dir == "C" || raw_dir == "S")
	if !is_long && !is_short {
		return
	}

	op_type := "L" if is_long else (lang == .English ? "S" : "C")

	// 5. Prompt for number of contracts
	fmt.print(msg.prompt_qty)
	num_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	contracts_qty, ok_qty := strconv.parse_int(strings.trim_space(string(num_bytes)))
	if !ok_qty || contracts_qty <= 0 {
		return
	}

	// 6. Prompt for entry and exit prices
	fmt.print(msg.prompt_entry)
	in_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_entry, ok_in := strconv.parse_f64(strings.trim_space(string(in_bytes)))

	fmt.print(msg.prompt_exit)
	out_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_exit, ok_out := strconv.parse_f64(strings.trim_space(string(out_bytes)))
	if !ok_in || !ok_out {
		return
	}

	// 7. Mathematical calculations for futures PnL
	points_pnl: f64 = 0.0
	if is_long {
		points_pnl = price_exit - price_entry
	} else {
		points_pnl = price_entry - price_exit
	}

	// Gross PnL = Points gained/lost * Full point value * Contract count
	gross_pnl := points_pnl * contract.point_value * f64(contracts_qty)

	// Total fees = Fee per side * 2 sides (open + close) * Contract count
	total_costs := (contract.cost_per_side * 2.0) * f64(contracts_qty)

	// Net PnL = Gross PnL - Total fees
	net_pnl := gross_pnl - total_costs

	// 8. Display results on screen
	fmt.printf(msg.net_result, net_pnl)
	fmt.printf(
		msg.gross_and_costs,
		gross_pnl,
		total_costs,
	)

	// 9. Persist trade record to historical file
	// Open file in append mode (create if it does not exist)
	file_handle, err := os.open(
		"historial_trading.txt",
		os.O_WRONLY | os.O_CREATE | os.O_APPEND,
	)
	if err != os.ERROR_NONE {
		fmt.println(msg.file_open_error)
		return
	}
	defer os.close(file_handle)

	// Format trade record line for persistence
	log_line := fmt.tprintf(
		msg.log_format,
		contract.ticker,
		op_type,
		contracts_qty,
		price_entry,
		price_exit,
		net_pnl,
	)

	// Write log line to file
	os.write(file_handle, transmute([]byte)log_line)
	fmt.println(msg.log_success)
}
