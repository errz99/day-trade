package glib

import "core:c"

Quark :: distinct c.uint32_t
Pointer :: distinct rawptr
SourceFunc :: #type proc "c" (data: Pointer) -> bool

Error :: struct {
	domain:  Quark,
	code:    c.int,
	message: cstring,
}

when ODIN_OS == .Windows {
	foreign import glib "../windows/glib-2.0.lib"
} else {
	foreign import glib "system:glib-2.0"
}

DestroyNotify :: #type proc "c" (data: Pointer)

Variant :: distinct rawptr // GVariant
VariantType :: distinct rawptr // GVariantType

@(default_calling_convention = "c")
@(link_prefix = "g_")
foreign glib {
	// GVariant
	variant_new :: proc(format_string: cstring) -> ^Variant ---
	variant_new_boolean :: proc(variant: bool) -> ^Variant ---
	variant_new_string :: proc(string: cstring) -> ^Variant ---
	variant_type_new :: proc(type_string: cstring) -> ^VariantType ---
	idle_add :: proc(function: SourceFunc, data: Pointer) -> c.uint ---
}

