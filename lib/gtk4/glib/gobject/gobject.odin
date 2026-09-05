package gobject

// import "../../../lib/glib"
import "core:c"

when ODIN_OS == .Windows {
	foreign import gobject "../../windows/gobject-2.0.lib"
} else {
	foreign import gobject "system:gobject-2.0"
}

Object :: distinct rawptr // GObject
Type :: distinct c.int // GType (gsize)

@(default_calling_convention = "c")
@(link_prefix = "g_")
foreign gobject {
	// GObject
	object_new :: proc(object_type: Type, first_property_name: cstring, #c_vararg var_args: ..any) -> ^Object ---
}

