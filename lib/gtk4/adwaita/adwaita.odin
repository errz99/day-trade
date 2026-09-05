package adwaita

import g "../glib/gio"

when ODIN_OS == .Windows {
	foreign import adwaita "../windows/adwaita-1.lib"
} else {
	foreign import adwaita "system:adwaita-1"
}

Application :: distinct rawptr // AdwApplication
StyleManager :: distinct rawptr // AdwStyleManager

// Adw.ColorScheme
ColorScheme :: enum {
	Default     = 0,
	ForceLight  = 1,
	PreferLight = 2,
	PreferDark  = 3,
	ForceDark   = 4,
}

@(default_calling_convention = "c")
@(link_prefix = "adw_")
foreign adwaita {
	application_new :: proc(app_id: cstring, flags: g.ApplicationFlags) -> ^Application ---
	style_manager_get_default :: proc() -> ^StyleManager ---
	style_manager_get_for_display :: proc() -> ^StyleManager ---
	// style_manager_get_color_scheme :: proc(asm: ^StyleManager) -> ColorScheme ---
	// style_manager_set_color_scheme :: proc(asm: ^StyleManager, scheme: ColorScheme) ---
}

