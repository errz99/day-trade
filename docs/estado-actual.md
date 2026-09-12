# Estado actual (documento vivo)

Última actualización: sesión del 11-12/09/2026 (diálogo Trade en WinForms +
navegación por teclado). Esto es un **handoff**: qué hay hecho, qué está
verificado, qué queda pendiente y qué decisiones están tomadas.

## Hecho y verificado

### Modelo de datos (`data/`)
- Futuros con nombre/alias/ticker/tick_size/point_value/coste por lado, CFDs y
  pares forex (arrays vacíos, sin rellenar todavía).
- **Array de brokers** en `Data` con `active_broker`; cuentas referencian su broker
  por índice. Brokers por defecto: `[0] Interactive Brokers (ibkr)`,
  `[1] iBroker (ibroker)`, sembrados con comisiones capturadas de sus webs
  (IBKR fixed, iBroker; FDXM/FDXS de iBroker quedaron con `TODO: confirm`).
- `Trade` incluye `date` numérica `YYYYMMDD` (además de campos y PnL neto).
- `record_trade(account, ticker, is_long, quantity, entry, exit, net_pnl, date)`
  con `date` obligatorio; `calculate_trade(contract, ...)`; `save_data`/`load_data`
  con migraciones; `current_date_number()`.
- `Config` (idioma, geometría de ventana, `use_adwaita`) en `config.json`.

### Interfaces
- **Compartido** (`ui/common`): textos de menú y del diálogo Trade en inglés y
  español, `begin_session_arena`, `load_session_data`.
- **GTK**: menú principal (etiqueta de cuenta + 5 botones) y diálogo Trade
  funcional; diálogo de Config (idioma + adwaita). Modales y transient.
- **WinForms**: menú principal + diálogo Trade funcional: modal (deshabilita la
  principal), centrado sobre ella, con Tab/Shift+Tab y Espacio/Enter, foco inicial
  en Cantidad, registro de trade con guardado inmediato.
- **IUP**: menú y diálogo Trade; **abandonado** (ver "decisiones").
- **TUI**: `-t`/`--terminal` en Linux/macOS.

### Verificaciones que se hicieron (y cómo)
- Registro real de un trade en las tres UIs, comprobando el `net_pnl` calculado y
  el `data.json` resultante.
- WinForms: ciclos encadenados de diálogo Trade + diálogo de sección, midiendo
  **centrado** (desviación 0-1 px), **modalidad** (`IsWindowEnabled` de la
  principal) y que la sección se destruye al cerrar.
- WinForms teclado: recorrido Tab (Cantidad → Entrada → Salida → Fecha → Añadir →
  Cerrar → Mercado → Valor → Largos → Cortos → vuelta), Shift+Tab inverso,
  escritura en el campo con foco, abrir/cerrar/reapertura solo con teclado.
- Todo ello **dentro del bucle principal**, manejando las ventanas con Win32 desde
  PowerShell (ver AGENTS.md).

## Pendiente / siguientes pasos posibles

1. **Enter en un campo de texto** → pulsar el botón por defecto (Añadir). Hoy
   Espacio/Enter funcionan con el foco en un botón, pero no desde un campo.
2. **Diálogos reales de Results / Cuenta / Config** (ahora son marcadores con
   "Aún no implementado"). Config ya existe en GTK; falta en WinForms y en IUP.
3. **Comisiones a confirmar**: iBroker FDXM/FDXS (`TODO: confirm` en el código) y
   FESX de IBKR. Mezcla de divisas: micros de CME/CBOT en USD, Eurex en EUR,
   mientras los mensajes imprimen "€".
4. **Rellenar CFDs y forex** (los arrays están vacíos): afecta al combo de mercado
   del diálogo Trade (con CFDs/Forex seleccionados no hay valores y Añadir queda
   deshabilitado, que es el comportamiento actual y deseado).
5. Añadir `date` a las líneas de `historial_trading.txt` (opcional).
6. Afinar medidas/estética del diálogo WinForms si se quiere.
7. **Decisión sobre IUP**: revertir `24f9690` y `36402af` (vuelve a abrir siempre,
   sin modal, centrado en pantalla) o retomarlo. Los útiles de depuración siguen
   en `ui/iup/debug.odin`, apagados por defecto (`-define:DT_TRACE=true` escribe
   `_dt_trace.txt`; `-define:DT_DRIVE=true` abre diálogos solo).

## Decisiones tomadas (con su motivo)

- **IUP abandonado temporalmente** por decisión del usuario tras costar mucho
  dejarlo estable: cada diálogo solo se podía abrir una vez en uso real. Lo que se
  aprendió y hay que respetar está en AGENTS.md (no destruir diálogos en sus
  propios callbacks; los popup de IUP no son reutilizables; `MODAL` es read-only
  en IUP 3; `CENTERPARENT` es `0xFFFA`).
- **Modalidad en WinForms** implementada deshabilitando la ventana principal con
  `control_enable` (y guarda `dialog_open`), no con diálogos nativos.
- **Navegación por teclado** en WinForms mediante `IsDialogMessage` en el bucle
  de mensajes (parche al binding) en vez de gestionar Tab a mano por control.
- **El diálogo Trade no se destruye al cerrarlo**: se oculta (`ea.cancel` en
  `onClosing`) y se reutiliza.
- Commits en inglés, cortos; el usuario hace push.

## Trampas del entorno (para no repetirlas)

- `data.json` / `config.json` son datos reales del usuario (gitignored): hacer
  copia antes de pruebas que registren trades y restaurarla después.
- Los `.exe` en uso bloquean la compilación (`LNK1104`): matar `day-trade*`.
- Los tests de UI por clics sintéticos son frágiles (foreground, `BM_CLICK`,
  codificación ANSI de los `.ps1`); usar el método descrito en AGENTS.md y
  preferir comprobaciones deterministas (abrir/cerrar desde dentro con un driver,
  cerrar con `WM_CLOSE` real).
