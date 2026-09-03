package main

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// 1. Definimos la estructura para los contratos de futuros
FutureContract :: struct {
	name:          string,
	ticker:        string,
	tick_size:     f64, // Movimiento mínimo (ej: 0.25)
	point_value:   f64, // Valor en euros de 1 punto entero (ej: $2 o 2€)
	cost_per_side: f64, // Comisión por abrir o cerrar 1 contrato
}

main :: proc() {
	defer free_all(context.temp_allocator)

	// Configuración del lector de terminal
	reader: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&reader, os.to_stream(os.stdin), buffer[:])

	// 2. Creamos y cargamos el MAP con la colección de índices (Versiones Micro E-mini)
	// Nota: El valor por punto está ajustado en Euros (aprox) o dólares base según tu broker.
	market_database := make(map[string]FutureContract)
	defer delete(market_database) // Buenas prácticas: liberar el mapa al terminar

	market_database["nasdaq"] = FutureContract{"Micro E-mini Nasdaq 100", "MNQ", 0.25, 2.0, 0.60}
	market_database["s&p"] = FutureContract{"Micro E-mini S&P 500", "MES", 0.25, 5.0, 0.60}
	market_database["dow jones"] = FutureContract{"Micro E-mini Dow Jones", "MYM", 1.00, 0.5, 0.60}
	market_database["russell"] = FutureContract {
		"Micro E-mini Russell 2000",
		"M2K",
		0.10,
		5.0,
		0.60,
	}
	market_database["mini dax"] = FutureContract{"Mini Dax", "FDXM", 1, 5, 1.25}
	market_database["micro dax"] = FutureContract{"Micro Dax", "FDXS", 1, 1, 0.75}
	market_database["eurostoxx"] = FutureContract{"EuroStoxx", "FESX", 1, 10, 3.50}

	fmt.println("--- 📈 CALCULADORA DE FUTUROS & REGISTRO (ODIN) ---")

	// 3. Solicitar y validar el índice
	fmt.print(
		"Introduce el índice (nasdaq, s&p, dow jones, russell, mini dax, micro dax, eurostoxx): ",
	)
	asset_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	asset_input := strings.to_lower(strings.trim_space(string(asset_bytes)))

	contract, exists := market_database[asset_input]
	if !exists {
		fmt.println("❌ Mercado no soportado. Introduce uno de la lista.")
		return
	}
	fmt.printf(
		"📌 Seleccionado: %s (%s) [Valor Punto: %.2f€]\n",
		contract.name,
		contract.ticker,
		contract.point_value,
	)

	// 4. Solicitar tipo de operación
	fmt.print("¿Dirección? Largos (L) o Cortos (C): ")
	type_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	op_type := strings.to_upper(strings.trim_space(string(type_bytes)))
	if op_type != "L" && op_type != "C" {return}

	// 5. Solicitar número de contratos
	fmt.print("Cantidad de contratos a operar: ")
	num_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	contracts_qty, ok_qty := strconv.parse_int(strings.trim_space(string(num_bytes)))
	if !ok_qty || contracts_qty <= 0 {return}

	// 6. Solicitar precios de entrada y salida
	fmt.print("Precio de ENTRADA: ")
	in_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_entry, ok_in := strconv.parse_f64(strings.trim_space(string(in_bytes)))

	fmt.print("Precio de SALIDA: ")
	out_bytes, _ := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
	price_exit, ok_out := strconv.parse_f64(strings.trim_space(string(out_bytes)))
	if !ok_in || !ok_out {return}

	// 7. CÁLCULOS MATEMÁTICOS DE FUTUROS
	points_pnl: f64 = 0.0
	if op_type == "L" {
		points_pnl = price_exit - price_entry
	} else {
		points_pnl = price_entry - price_exit
	}

	// PnL Bruto = Puntos ganados/perdidos * Valor del punto entero * Número de contratos
	gross_pnl := points_pnl * contract.point_value * f64(contracts_qty)

	// Costes totales = Coste por lado (abrir + cerrar = 2) * contratos
	total_costs := (contract.cost_per_side * 2.0) * f64(contracts_qty)

	// PnL Neto = Bruto - Costes
	net_pnl := gross_pnl - total_costs

	// 8. Mostrar en pantalla
	fmt.println("\n-------------------------------------------")
	fmt.printf("📊 RESULTADO NETO: %.2f €\n", net_pnl)
	fmt.printf(
		"💰 Beneficio Bruto: %.2f € | 💸 Comisiones pagadas: %.2f €\n",
		gross_pnl,
		total_costs,
	)
	fmt.println("-------------------------------------------")

	// 9. ALMACENAR Y GUARDAR EN FICHERO
	// Abrimos el archivo en modo Append (Añadir al final) u O_CREAT (crear si no existe)
	file_handle, err := os.open(
		"historial_trading.txt",
		os.O_WRONLY | os.O_CREATE | os.O_APPEND,
		// 0o666,
	)
	if err != os.ERROR_NONE {
		fmt.println("⚠️ No se pudo abrir el archivo para guardar la operación.")
		return
	}
	defer os.close(file_handle)

	// Formateamos la línea de texto que irá al fichero corporativo
	log_line := fmt.tprintf(
		"Mercado: %s | Tipo: %s | Contratos: %d | Entrada: %.2f | Salida: %.2f | PnL Neto: %.2f €\n",
		contract.ticker,
		op_type,
		contracts_qty,
		price_entry,
		price_exit,
		net_pnl,
	)

	// Escribimos en el archivo convirtiendo el string a un array de bytes
	os.write(file_handle, transmute([]byte)log_line)
	fmt.println("💾 ¡Operación registrada con éxito en 'historial_trading.txt'!")
}
