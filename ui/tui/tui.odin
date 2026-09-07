package tui

import common "../common"
import dt "../../data"
import "core:bufio"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

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
get_messages :: proc(lang: dt.Language) -> Messages {
	switch lang {
	case .English:
		return Messages {
			banner = "--- 📈 FUTURES CALCULATOR & LOGGER (ODIN) ---",
			prompt_market = "Enter index (nasdaq, s&p, dow jones, russell, mini dax, micro dax, eurostoxx): ",
			unsupported_market = "❌ Unsupported market. Please enter one from the list.",
			selected_contract = "📌 Selected: %s (%s) [Point Value: %.2f€]\n",
			prompt_direction = "Direction? Long (L) or Short (S/C): ",
			prompt_qty = "Quantity of contracts to trade: ",
			prompt_entry = "ENTRY price: ",
			prompt_exit = "EXIT price: ",
			net_result = "\n-------------------------------------------\n📊 NET RESULT: %.2f €\n",
			gross_and_costs = "💰 Gross Profit: %.2f € | 💸 Commissions paid: %.2f €\n-------------------------------------------\n",
			file_open_error = "⚠️ Could not open file to save trade operation.",
			log_format = "Market: %s | Type: %s | Contracts: %d | Entry: %.2f | Exit: %.2f | Net PnL: %.2f €\n",
			log_success = "💾 Trade successfully logged to 'historial_trading.txt'!",
		}
	case .Spanish:
		return Messages {
			banner = "--- 📈 CALCULADORA DE FUTUROS & REGISTRO (ODIN) ---",
			prompt_market = "Introduce el índice (nasdaq, s&p, dow jones, russell, mini dax, micro dax, eurostoxx): ",
			unsupported_market = "❌ Mercado no soportado. Introduce uno de la lista.",
			selected_contract = "📌 Seleccionado: %s (%s) [Valor Punto: %.2f€]\n",
			prompt_direction = "¿Dirección? Largos (L) o Cortos (C): ",
			prompt_qty = "Cantidad de contratos a operar: ",
			prompt_entry = "Precio de ENTRADA: ",
			prompt_exit = "Precio de SALIDA: ",
			net_result = "\n-------------------------------------------\n📊 RESULTADO NETO: %.2f €\n",
			gross_and_costs = "💰 Beneficio Bruto: %.2f € | 💸 Comisiones pagadas: %.2f €\n-------------------------------------------\n",
			file_open_error = "⚠️ No se pudo abrir el archivo para guardar la operación.",
			log_format = "Mercado: %s | Tipo: %s | Contratos: %d | Entrada: %.2f | Salida: %.2f | PnL Neto: %.2f €\n",
			log_success = "💾 ¡Operación registrada con éxito en 'historial_trading.txt'!",
		}
	}
	return Messages{}
}

// Runs the terminal user interface flow
run_tui :: proc() {
	// Session memory: a dynamic arena holds everything allocated this run (including the
	// JSON data loaded at start) and is released wholesale when the session ends
	session_arena: mem.Dynamic_Arena
	common.begin_session_arena(&session_arena)
	defer mem.dynamic_arena_destroy(&session_arena)
	defer free_all(context.temp_allocator)

	// Load configuration (language) at session start; saved back at the end
	cfg := dt.load_config("config.json")
	defer dt.save_config("config.json", cfg)

	lang := cfg.language
	msg := get_messages(lang)

	// Terminal input reader setup
	reader: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buffer[:])

	// Load the application data at session start (defaults when there is no saved file)
	data := common.load_session_data("data.json")

	// The session always ends by persisting the current data back to the JSON file
	defer dt.save_data("data.json", data)

	// Pointer to the active account, so it can be modified directly in place
	account := &data.accounts[data.active_account]

	fmt.println(msg.banner)

	// 1. Prompt for and validate index selection
	fmt.print(msg.prompt_market)
	asset_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	asset_input := strings.to_lower(strings.trim_space(string(asset_bytes)))

	contract, exists := account.broker.market_database[asset_input]
	if !exists {
		fmt.println(msg.unsupported_market)
		return
	}
	fmt.printf(msg.selected_contract, contract.name, contract.ticker, contract.point_value)

	// 2. Prompt for order direction (Long vs Short)
	fmt.print(msg.prompt_direction)
	type_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	raw_dir := strings.to_upper(strings.trim_space(string(type_bytes)))

	is_long := (raw_dir == "L")
	is_short := (raw_dir == "C" || raw_dir == "S")
	if !is_long && !is_short {
		return
	}

	op_type := "L" if is_long else (lang == .English ? "S" : "C")

	// 3. Prompt for number of contracts
	fmt.print(msg.prompt_qty)
	num_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	contracts_qty, ok_qty := strconv.parse_int(strings.trim_space(string(num_bytes)))
	if !ok_qty || contracts_qty <= 0 {
		return
	}

	// 4. Prompt for entry and exit prices
	fmt.print(msg.prompt_entry)
	in_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_entry, ok_in := strconv.parse_f64(strings.trim_space(string(in_bytes)))

	fmt.print(msg.prompt_exit)
	out_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_exit, ok_out := strconv.parse_f64(strings.trim_space(string(out_bytes)))
	if !ok_in || !ok_out {
		return
	}

	// 5. Mathematical calculations for futures PnL via data package
	calc := dt.calculate_trade(contract, is_long, contracts_qty, price_entry, price_exit)

	// 6. Display results on screen
	fmt.printf(msg.net_result, calc.net_pnl)
	fmt.printf(msg.gross_and_costs, calc.gross_pnl, calc.total_costs)

	// 7. Record the trade in the active account's history (persisted via data.json)
	dt.record_trade(account, contract.ticker, is_long, contracts_qty, price_entry, price_exit, calc.net_pnl)

	// 8. Persist trade record to historical file
	log_line := fmt.tprintf(
		msg.log_format,
		contract.ticker,
		op_type,
		contracts_qty,
		price_entry,
		price_exit,
		calc.net_pnl,
	)

	if dt.append_trade_log("historial_trading.txt", log_line) {
		fmt.println(msg.log_success)
	} else {
		fmt.println(msg.file_open_error)
	}
}
