package cairo

when ODIN_OS == .Windows {
	foreign import cairo "../windows/cairo.lib"
} else {
	foreign import cairo "system:cairo"
}

bool_t :: b32

context_t :: struct #packed {}
surface_t :: struct #packed {}

device_t :: struct #packed {}

matrix_t :: struct {
	xx: f64,
	yx: f64,
	xy: f64,
	yy: f64,
	x0: f64,
	y0: f64,
}

pattern_t :: struct #packed {}

destroy_func_t :: #type proc "c" (data: rawptr)
user_data_key_t :: struct {
	unused: i32,
}

rectangle_t :: struct {
	x:      f64,
	y:      f64,
	width:  f64,
	height: f64,
}

rectangle_list_t :: struct {
	status:         status_t,
	rectangles:     [^]rectangle_t,
	num_rectangles: i32,
}

scaled_font_t :: struct #packed {}

font_face_t :: struct #packed {}

text_cluster_t :: struct {
	num_bytes:  i32,
	num_glyphs: i32,
}
// Cairo_t :: distinct rawptr // cairo_t
// // Context :: distinct rawptr // Context

// // Gdk.ModifierType
// CairoTest :: enum {
// 	NoModifierMask = 0,
// 	ShiftMask      = 1,
// }

status_t :: enum u32 {
	SUCCESS                   = 0,
	NO_MEMORY                 = 1,
	INVALID_RESTORE           = 2,
	INVALID_POP_GROUP         = 3,
	NO_CURRENT_POINT          = 4,
	INVALID_MATRIX            = 5,
	INVALID_STATUS            = 6,
	NULL_POINTER              = 7,
	INVALID_STRING            = 8,
	INVALID_PATH_DATA         = 9,
	READ_ERROR                = 10,
	WRITE_ERROR               = 11,
	SURFACE_FINISHED          = 12,
	SURFACE_TYPE_MISMATCH     = 13,
	PATTERN_TYPE_MISMATCH     = 14,
	INVALID_CONTENT           = 15,
	INVALID_FORMAT            = 16,
	INVALID_VISUAL            = 17,
	FILE_NOT_FOUND            = 18,
	INVALID_DASH              = 19,
	INVALID_DSC_COMMENT       = 20,
	INVALID_INDEX             = 21,
	CLIP_NOT_REPRESENTABLE    = 22,
	TEMP_FILE_ERROR           = 23,
	INVALID_STRIDE            = 24,
	FONT_TYPE_MISMATCH        = 25,
	USER_FONT_IMMUTABLE       = 26,
	USER_FONT_ERROR           = 27,
	NEGATIVE_COUNT            = 28,
	INVALID_CLUSTERS          = 29,
	INVALID_SLANT             = 30,
	INVALID_WEIGHT            = 31,
	INVALID_SIZE              = 32,
	USER_FONT_NOT_IMPLEMENTED = 33,
	DEVICE_TYPE_MISMATCH      = 34,
	DEVICE_ERROR              = 35,
	INVALID_MESH_CONSTRUCTION = 36,
	DEVICE_FINISHED           = 37,
	JBIG2_GLOBAL_MISSING      = 38,
	PNG_ERROR                 = 39,
	FREETYPE_ERROR            = 40,
	WIN32_GDI_ERROR           = 41,
	TAG_ERROR                 = 42,
	DWRITE_ERROR              = 43,
	SVG_FONT_ERROR            = 44,
	LAST_STATUS               = 45,
}

font_slant_t :: enum u32 {
	NORMAL  = 0,
	ITALIC  = 1,
	OBLIQUE = 2,
}

font_weight_t :: enum u32 {
	NORMAL = 0,
	BOLD   = 1,
}

subpixel_order_t :: enum u32 {
	DEFAULT = 0,
	RGB     = 1,
	BGR     = 2,
	VRGB    = 3,
	VBGR    = 4,
}

hint_style_t :: enum u32 {
	DEFAULT = 0,
	NONE    = 1,
	SLIGHT  = 2,
	MEDIUM  = 3,
	FULL    = 4,
}

hint_metrics_t :: enum u32 {
	DEFAULT = 0,
	OFF     = 1,
	ON      = 2,
}

color_mode_t :: enum u32 {
	DEFAULT  = 0,
	NO_COLOR = 1,
	COLOR    = 2,
}

font_options_t :: struct #packed {}

font_type_t :: enum u32 {
	TOY    = 0,
	FT     = 1,
	WIN32  = 2,
	QUARTZ = 3,
	USER   = 4,
	DWRITE = 5,
}

@(default_calling_convention = "c")
@(link_prefix = "cairo_")
foreign cairo {
	set_source_rgb :: proc(cr: ^context_t, red, green, blue: f64) ---
	set_source_rgba :: proc(cr: ^context_t, red, green, blue, alpha: f64) ---
	paint :: proc(cr: ^context_t) ---
	move_to :: proc(cr: ^context_t, x, y: f64) ---
	show_text :: proc(cr: ^context_t, str: cstring) ---
	rectangle :: proc(cr: ^context_t, x, y, width, height: f64) ---
	fill :: proc(cr: ^context_t) ---

	select_font_face :: proc(cr: ^context_t, family: cstring, slant: font_slant_t, weight: font_weight_t) ---
	set_font_size :: proc(cr: ^context_t, size: f64) ---
}

