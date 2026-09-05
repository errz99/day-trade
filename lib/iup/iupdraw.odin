package iup

when ODIN_OS == .Windows {
	foreign import iup "iup.lib"
} else {
	foreign import iup {"system:libiup.a", "system:X11", "gdk-pixbuf-2.0", "system:pango-1.0", "system:pangocairo-1.0", "system:gobject-2.0", "system:glib-2.0", "system:cairo", "system:gtk-4"}
}

// ============================================================================
// BINDING COMPLETO PARA IUPDRAW (iupdraw.h)
// Para dibujo 2D acelerado en Canvas o BackgroundBox
// ============================================================================

@(default_calling_convention = "c")
foreign iup {
	// Control del Ciclo de Renderizado (Primitivas Obligatorias)
	IupDrawBegin :: proc(ih: Ihandle) ---
	IupDrawEnd :: proc(ih: Ihandle) ---

	// Configuración del Lienzo (Canvas)
	IupDrawSetClipRect :: proc(ih: Ihandle, x1, y1, x2, y2: i32) ---
	IupDrawResetClipRect :: proc(ih: Ihandle) ---
	IupDrawGetClipRect :: proc(ih: Ihandle, x1, y1, x2, y2: ^i32) ---

	// Primitivas de Dibujo Geométrico
	IupDrawLine :: proc(ih: Ihandle, x1, y1, x2, y2: i32) ---
	IupDrawRectangle :: proc(ih: Ihandle, x1, y1, x2, y2: i32) ---
	IupDrawFilledRectangle :: proc(ih: Ihandle, x1, y1, x2, y2: i32) ---
	IupDrawArc :: proc(ih: Ihandle, x1, y1, x2, y2: i32, a1, a2: f64) ---
	IupDrawFilledArc :: proc(ih: Ihandle, x1, y1, x2, y2: i32, a1, a2: f64) ---
	IupDrawPolygon :: proc(ih: Ihandle, points: ^i32, count: i32) ---
	IupDrawFilledPolygon :: proc(ih: Ihandle, points: ^i32, count: i32) ---
	IupDrawGetSize :: proc(ih: Ihandle, w, h: ^i32) ---

	// Renderizado de Texto e Imágenes
	IupDrawText :: proc(ih: Ihandle, str: cstring, len: i32, x, y, w, h: i32) ---
	IupDrawImage :: proc(ih: Ihandle, name: cstring, x, y, w, h: i32) ---
	IupDrawSelectDim :: proc(ih: Ihandle, w, h: ^i32) ---

	// Estilos de Dibujo (Atributos de estado del lápiz)
	// El formato de los colores "str" en IUP siempre sigue el estándar UTF-8 "R G B" (ej: "255 0 0")
	IupDrawSetAttribute :: proc(ih: Ihandle, name: cstring, value: cstring) ---
	IupDrawGetAttribute :: proc(ih: Ihandle, name: cstring) -> cstring ---
}

// Constructor adicional del elemento Canvas (requerido para usar IupDraw)
foreign iup {
	IupCanvas :: proc(action: cstring) -> Ihandle ---
}

