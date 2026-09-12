# AGENTS.md — day-trade

Instrucciones para trabajar en este repositorio. Se cargan automáticamente al
inicio de cada sesión (primera petición) y al reanudar una sesión. El detalle
vivo del proyecto está en [`docs/estado-actual.md`](docs/estado-actual.md).

## Qué es

Aplicación de escritorio en **Odin** para **registrar trades de futuros ya
cerrados** (por ahora solo eso: registrar y almacenar; los cálculos de resultados
y estadísticas vendrán después). Multi-UI: la misma aplicación se compila contra
distintos backends de interfaz con `-define:UI=<backend>`.

- `gtk` (por defecto) — GTK4, `lib/gtk4`, multiplataforma.
- `winforms` — binding Win32 propio, `lib/winforms`, solo Windows.
- `iup` — IUP (`lib/iup`), **abandonado temporalmente** (ver estado).
- TUI: no es un target aparte; se entra con `-t` / `--terminal` en los binarios
  de Linux y macOS (en Windows no hay TUI).

## Compilar y verificar

```powershell
.\build.ps1 -Target winforms   # targets: iup | gtk | gtk4(=gtk) | winforms | all
.\build.ps1 -Target gtk
```

- `build.ps1` añade `-subsystem:windows` y embebe el manifiesto de `tools/` en el
  `.exe` (con `tools/embed_manifest`).
- Comprobación rápida sin enlazar, para todos los backends:
  `odin check . -define:UI=winforms` (y `gtk`, `iup`); también con
  `-target:linux_amd64` / `-target:darwin_arm64` para no romper el código
  multiplataforma (el código de Win32 debe quedar detrás de `when ODIN_OS == .Windows`
  o en ficheros con `#+build`).
- Los `.exe` se quedan bloqueados por procesos vivos: mata `day-trade*` antes de
  recompilar (`LNK1104`).

## Estructura

- `data/` — modelo y persistencia: `data.odin` (contratos de futuros, CFDs, forex,
  brokers, cuentas, trades, cálculos, `save_data`/`load_data`), `config.odin`
  (idioma, geometría de ventana, adwaita, `save_config`/`load_config`).
- `ui/common/` — **textos y ayudas compartidos por todas las UIs** (`Menu_Texts`,
  `Trade_Texts`, `get_menu_texts`, `get_trade_texts`, `begin_session_arena`,
  `load_session_data`). Cualquier texto nuevo va aquí, en inglés y español.
- `ui/gtk/`, `ui/winforms/`, `ui/iup/` — una implementación por backend.
- `lib/` — bindings (hand-written para GTK4/IUP, `lib/winforms` es una copia
  vendorizada de github.com/kcvinker/Winforms).
- `main.odin` (`UI :: #config(UI, "gtk")` + dispatch), `main_windows.odin`,
  `terminal_unix.odin`.

## Estado de las interfaces

- **GTK**: menú principal, diálogo **Trade** (funcional) y diálogo de Config
  (idioma + adwaita). Diálogos modales (`set_modal`) y transient sobre la ventana
  principal.
- **WinForms**: menú principal y diálogo **Trade** funcional, modal, centrado
  sobre la principal y **navegable por teclado** (Tab/Shift+Tab, Espacio/Enter en
  botones). Diálogos de Results/Cuenta/Config son marcadores.
- **IUP**: menú principal y diálogo Trade funcionan, pero el ciclo de diálogos se
  rompe al cabo de 2-3 aperturas. **Abandonado por decisión del usuario**; no
  invertir en él salvo petición expresa. Sus dos últimos commits se pueden
  revertir (`24f9690`, `36402af`) para volver al comportamiento anterior.

## Convenciones de código

- Un `package` por backend (`gtk_ui`, `winforms_ui`, `iup_ui`) y **estado a nivel
  de paquete**, porque los callbacks de GTK/IUP/Win32 no llevan `user_data`.
- Los callbacks `proc "c"` de IUP/GTK **no tienen contexto implícito**: lo primero
  que hacen es `context = runtime.default_context()` y asignar
  `allocator`/`temp_allocator` de la sesión. En WinForms el binding ya restaura
  `global_context`, así que los handlers normales pueden asignar memoria.
- Memoria de sesión: `common.begin_session_arena(&arena)` al arrancar y
  `mem.dynamic_arena_destroy` al salir; los datos cargados del JSON viven ahí.
- Textos: nunca literales sueltos en una UI; van en `ui/common` en los dos idiomas.
- Idiomas: `Language` es un enum serializado por nombre (`use_enum_names`).

## Reglas aprendidas a base de golpes (respetarlas)

1. **No destruir una ventana/diálogo desde dentro de sus propios callbacks**
   (cierre, destrucción). Oculta y destruye después, o reutiliza el diálogo. Esto
   fue lo que rompió IUP (dejaba de procesar eventos tras 2-3 diálogos) y lo que
   obliga a que el diálogo WinForms se oculte en su `onClosing` con `ea.cancel`.
2. **Probar dentro del bucle principal.** Verificaciones hechas antes de
   `IupMainLoop`/`start_mainloop` dan falsos positivos: el fallo de IUP pasó mis
   primeros tests precisamente por eso.
3. `data.json` y `config.json` están en `.gitignore` y **contienen datos reales
   del usuario**: nunca commitearlos ni pisarlos; antes de una prueba que registre
   trades, copia y restaura el fichero.

## Cómo probar una UI en Windows (lo que funciona y lo que no)

Método usado y fiable: compilar solo para pruebas
(`odin build . -define:UI=<x> -out:_x.exe -subsystem:windows`), arrancar, localizar
las ventanas por título/clase y manejarlas con Win32 desde PowerShell:

- Clics y cierres: **`PostMessage`**. `SendMessage` (BM_CLICK/WM_CLOSE) **bloquea**
  si el callback entra en un bucle modal; además `BM_CLICK` solo funciona si esa
  ventana es la activa.
- Leer el foco: `AttachThreadInput(GetCurrentThreadId(), threadDeLaApp)` + `GetFocus()`.
- `GetWindowText` **no puede leer controles de otra ventana/proceso** (devuelve "");
  para edit/combo usa `WM_GETTEXT` (sí marshaliza) o `WM_SETTEXT` para escribir.
- PowerShell 5.1 lee los `.ps1` como ANSI: **evita literales con acentos**
  ("Añadir" no coincide); identifica esos controles por índice/clase.
- Para el orden de tabulación y estado de ventanas, `EnumChildWindows` + nombre de
  clase (`Edit`, `ComboBox`, `Button`, `Static`).

## Parches a los bindings

- `lib/iup/iup.odin`: `CENTERPARENT` corregido a `0xFFFA` (estaba `0xFAFA`, valor
  inválido que dejaba la ventana en (32767,32767)) y añadidas
  `IupSetHandle`/`IupGetHandle`/`IupGetName` (necesarias para `PARENTDIALOG`).
- `lib/winforms`: `forms.odin` enruta el bucle de mensajes por `IsDialogMessage`
  (Tab/Shift+Tab), `buttons.odin` activa botones con Espacio/Enter y
  `mag_keyboard.odin` declara lo que faltaba del API. Al actualizar la librería
  hay que volver a aplicar esos tres cambios.

## Preferencias de trabajo del usuario

- Conversación en **español**; **commits en inglés y cortos**.
- El agente **prepara el commit; el usuario hace push**. No afirmar cuántos
  commits hay pendientes sin comprobarlo (`git status -sb` / `git log @{u}..HEAD`).
- Investigación con fuentes cuando se decide algo de una librería (documentación
  del proyecto), y **no afirmar nada sin verificarlo**.
- Estilo: explicaciones directas, sin relleno; los cambios de comportamiento se
  verifican ejecutando, no solo compilando.
