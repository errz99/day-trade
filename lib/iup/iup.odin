package iup

// Vinculación con la biblioteca de importación de Windows para IUP 3.32
when ODIN_OS == .Windows {
	foreign import iup "iup.lib"
} else {
	foreign import iup {"system:libiup.a", "system:X11", "gdk-pixbuf-2.0", "system:pango-1.0", "system:pangocairo-1.0", "system:gobject-2.0", "system:glib-2.0", "system:cairo", "system:gtk-4"}
}

// ============================================================================
// 1. TIPOS DE DATOS BASE Y CONVENCIONES DE LLAMADA
// ============================================================================

Ihandle :: rawptr
Icallback :: proc "c" (ih: Ihandle) -> i32

// Conector de funciones externas en ABI C (Windows x64)
@(default_calling_convention = "c")
foreign iup {
	// Sistema y Gestión de Ciclo de Vida
	IupOpen :: proc(argc: ^i32, argv: ^^cstring) -> i32 ---
	IupClose :: proc() ---
	IupIsOpened :: proc() -> i32 ---
	IupMainLoop :: proc() -> i32 ---
	IupMainLoopLevel :: proc() -> i32 ---
	IupLoopStep :: proc() -> i32 ---
	IupLoopStepWait :: proc() -> i32 ---
	IupExitLoop :: proc() ---
	IupFlush :: proc() ---
	IupVersion :: proc() -> cstring ---
	IupVersionDate :: proc() -> cstring ---
	IupVersionNumber :: proc() -> i32 ---

	// Atributos del Sistema
	IupSetAttribute :: proc(ih: Ihandle, name: cstring, value: cstring) ---
	IupStoreAttribute :: proc(ih: Ihandle, name: cstring, value: cstring) ---
	IupSetAttributes :: proc(ih: Ihandle, str: cstring) -> Ihandle ---
	IupGetAttribute :: proc(ih: Ihandle, name: cstring) -> cstring ---
	IupGetAttributes :: proc(ih: Ihandle) -> cstring ---
	IupGetInt :: proc(ih: Ihandle, name: cstring) -> i32 ---
	IupGetInt2 :: proc(ih: Ihandle, name: cstring) -> i32 ---
	IupGetFloat :: proc(ih: Ihandle, name: cstring) -> f32 ---
	IupSetDouble :: proc(ih: Ihandle, name: cstring, value: f64) ---
	IupGetDouble :: proc(ih: Ihandle, name: cstring) -> f64 ---
	IupSetAttributeId :: proc(ih: Ihandle, name: cstring, id: i32, value: cstring) ---
	IupStoreAttributeId :: proc(ih: Ihandle, name: cstring, id: i32, value: cstring) ---
	IupGetAttributeId :: proc(ih: Ihandle, name: cstring, id: i32) -> cstring ---
	IupGetIntId :: proc(ih: Ihandle, name: cstring, id: i32) -> i32 ---
	IupGetFloatId :: proc(ih: Ihandle, name: cstring, id: i32) -> f32 ---
	IupSetAttributeId2 :: proc(ih: Ihandle, name: cstring, id1, id2: i32, value: cstring) ---
	IupStoreAttributeId2 :: proc(ih: Ihandle, name: cstring, id1, id2: i32, value: cstring) ---
	IupGetAttributeId2 :: proc(ih: Ihandle, name: cstring, id1, id2: i32) -> cstring ---
	IupGetIntId2 :: proc(ih: Ihandle, name: cstring, id1, id2: i32) -> i32 ---
	IupGetFloatId2 :: proc(ih: Ihandle, name: cstring, id1, id2: i32) -> f32 ---
	// mag
	IupSetRGB :: proc(ih: Ihandle, name: cstring, r, g, b: u8) ---
	IupSetRGBA :: proc(ih: Ihandle, name: cstring, r, g, b, a: u8) ---

	// Atributos Globales
	IupSetGlobal :: proc(name: cstring, value: cstring) ---
	IupStoreGlobal :: proc(name: cstring, value: cstring) ---
	IupGetGlobal :: proc(name: cstring) -> cstring ---

	// Callbacks y Eventos
	IupSetCallback :: proc(ih: Ihandle, name: cstring, func: Icallback) -> Icallback ---
	IupGetCallback :: proc(ih: Ihandle, name: cstring) -> Icallback ---

	// Gestión del Árbol de Elementos (Layout)
	IupCreate :: proc(classname: cstring) -> Ihandle ---
	IupCreatev :: proc(classname: cstring, params: ^rawptr) -> Ihandle ---
	IupDestroy :: proc(ih: Ihandle) ---
	IupMap :: proc(ih: Ihandle) -> i32 ---
	IupUnmap :: proc(ih: Ihandle) ---
	IupAppend :: proc(ih, child: Ihandle) -> Ihandle ---
	IupDetach :: proc(child: Ihandle) ---
	IupInsert :: proc(ih, anchor, child: Ihandle) -> Ihandle ---
	IupGetChild :: proc(ih: Ihandle, pos: i32) -> Ihandle ---
	IupGetChildPos :: proc(ih, child: Ihandle) -> i32 ---
	IupGetChildCount :: proc(ih: Ihandle) -> i32 ---
	IupGetNextChild :: proc(ih, child: Ihandle) -> Ihandle ---
	IupGetParent :: proc(ih: Ihandle) -> Ihandle ---
	IupGetDialog :: proc(ih: Ihandle) -> Ihandle ---
	IupRefresh :: proc(ih: Ihandle) ---
	IupRefreshChildren :: proc(ih: Ihandle) ---
	// mag
	IupUpdate :: proc(ih: Ihandle) ---

	// Control de Visualización y Foco
	IupShowXY :: proc(ih: Ihandle, x, y: i32) -> i32 ---
	IupShow :: proc(ih: Ihandle) -> i32 ---
	IupHide :: proc(ih: Ihandle) -> i32 ---
	IupPopup :: proc(ih: Ihandle, x, y: i32) -> i32 ---
	IupSetFocus :: proc(ih: Ihandle) -> Ihandle ---
	IupGetFocus :: proc() -> Ihandle ---
	IupRedraw :: proc(ih: Ihandle, children: i32) ---

	// Cuadros de Diálogo Predefinidos del Sistema
	IupMessage :: proc(title, message: cstring) ---
	IupMessageAlarm :: proc(title, message, buttons: cstring) -> i32 ---
	IupAlarm :: proc(title, message, b1, b2, b3: cstring) -> i32 ---
	IupGetFile :: proc(arq: cstring) -> i32 ---

	// CONSTRUCTORES DE CONTROLES NATIVOS (Variantes de Arrays C seguras para Odin)
	IupDialog :: proc(child: Ihandle) -> Ihandle ---
	IupButton :: proc(title, action: cstring) -> Ihandle ---
	IupFlatButton :: proc(title: cstring) -> Ihandle ---
	IupLabel :: proc(title: cstring) -> Ihandle ---
	IupList :: proc(action: cstring) -> Ihandle ---
	IupText :: proc(action: cstring) -> Ihandle ---
	IupMultiLine :: proc(action: cstring) -> Ihandle ---
	IupToggle :: proc(title, action: cstring) -> Ihandle ---
	IupProgressBar :: proc() -> Ihandle ---
	IupVal :: proc(type_str: cstring) -> Ihandle --- // Scrollbar/Slider

	// CONSTRUCTORES DE CONTENEDORES (Variantes Seguras de Arrays C)
	IupVboxv :: proc(array: ^Ihandle) -> Ihandle ---
	IupHboxv :: proc(array: ^Ihandle) -> Ihandle ---
	IupZboxv :: proc(array: ^Ihandle) -> Ihandle ---
	IupNormalizerv :: proc(array: ^Ihandle) -> Ihandle ---
	IupGridBoxv :: proc(array: ^Ihandle) -> Ihandle ---
	IupFrame :: proc(child: Ihandle) -> Ihandle ---
	IupBackgroundBox :: proc(child: Ihandle) -> Ihandle ---
	IupSplit :: proc(child1, child2: Ihandle) -> Ihandle ---
	IupTabs :: proc(child: Ihandle) -> Ihandle --- // Requiere un contenedor interno o lista de hijos

	IupItem :: proc(title, action: cstring) -> Ihandle ---
	IupSubmenu :: proc(title: cstring, child: Ihandle) -> Ihandle ---
	IupSeparator :: proc() -> Ihandle ---
	IupMenu :: proc(child: Ihandle, #c_vararg var_args: ..any) -> Ihandle ---
	// IupMenuv    ::proc  (Ihandle* *children) -> Ihandle ---
	IupTimer :: proc() -> Ihandle ---
}

// ============================================================================
// 2. CONSTANTES Y MACROS DE ERROR / RESPUESTA (IUP CODES)
// ============================================================================

ERROR: i32 : 1
NOERROR: i32 : 0
OPENED: i32 : -1
INVALID: i32 : -1
INVALID_ID: i32 : -10

// Retornos de Callback estándar
DEFAULT: i32 : -1
CLOSE: i32 : -2
CONTINUE: i32 : -3
IGNORE: i32 : -4
DEFAULT_BIG: i32 : -5

// Posiciones para IupShowXY e IupPopup
CENTER: i32 : 0xFFFF
LEFT: i32 : 0xFFFE
RIGHT: i32 : 0xFFFD
MOUSEPOS: i32 : 0xFFFC
CURRENT: i32 : 0xFFFB
CENTERPARENT: i32 : 0xFAFA
TOP: i32 : 0xFFFE
BOTTOM: i32 : 0xFFFD

// Estados de Toggles y Botones
ON: i32 : 1
OFF: i32 : 0

// ============================================================================
// 3. ENVOLTURAS AUXILIARES SINTÁCTICAS (Odin Helpers)
// ============================================================================

// Alternativas de azúcar sintáctico para que no tengas que declarar arrays manuales en el código cliente.
Vbox :: proc(elements: ..Ihandle) -> Ihandle {
	// Agregamos de manera segura nil al final de la secuencia dinámica
	list := make([dynamic]Ihandle, 0, len(elements) + 1)
	defer delete(list)
	for e in elements {append(&list, e)}
	append(&list, nil)
	return IupVboxv(&list[0])
}

Hbox :: proc(elements: ..Ihandle) -> Ihandle {
	list := make([dynamic]Ihandle, 0, len(elements) + 1)
	defer delete(list)
	for e in elements {append(&list, e)}
	append(&list, nil)
	return IupHboxv(&list[0])
}

GridBox :: proc(elements: ..Ihandle) -> Ihandle {
	list := make([dynamic]Ihandle, 0, len(elements) + 1)
	defer delete(list)
	for e in elements {append(&list, e)}
	append(&list, nil)
	return IupGridBoxv(&list[0])
}

