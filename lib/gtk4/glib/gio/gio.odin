package gio

import ".."
import g "../gobject"
import "core:c"

when ODIN_OS == .Windows {
	foreign import gio {"../../windows/gio-2.0.lib", "../../windows/gobject-2.0.lib"}
} else {
	foreign import gio {"system:gio-2.0", "system:gobject-2.0"}
}

Pointer :: distinct rawptr // GPointer
Callback :: distinct rawptr // GCallback
ClosureNotify :: distinct rawptr // GClosureNotify
Application :: distinct rawptr // GApplication
Menu :: distinct rawptr // GMenu
MenuModel :: distinct rawptr // GMenuModel
MenuItem :: distinct rawptr // GMenuItem
SimpleAction :: distinct rawptr // GSimpleAction
ActionMap :: distinct rawptr // GActionMap
Action :: distinct rawptr // GAction
AsyncResult :: distinct rawptr // GAsyncResult
Cancellable :: distinct rawptr // GCancellable
File :: distinct rawptr // GFile

AsyncReadyCallback :: #type proc "c" (source_object: ^g.Object, res: ^AsyncResult, data: Pointer)

MenuCb :: #type proc "c" (action: ^SimpleAction, variant: ^glib.Variant, data: Pointer)

ApplicationFlags :: enum {
	DefaultFlags = 0,
	IsService    = 1,
	IsLauncher   = 2,
}
ConnectFlags :: enum {
	ConnectDefault = 0,
	ConnectAfter   = 1,
	ConnectSwapped = 2,
}

@(default_calling_convention = "c")
@(link_prefix = "g_")
foreign gio {
	// GApplication
	application_run :: proc(app: ^Application, argc: c.int, argv: [^]cstring) -> c.int ---
	application_quit :: proc(app: ^Application) ---
	signal_connect_object :: proc(instance: Pointer, detailed: cstring, handler: Callback, data: Pointer, flags: ConnectFlags) -> c.ulong ---
	signal_connect_data :: proc(instance: Pointer, detailed: cstring, handler: Callback, data: Pointer, destroy_data: ClosureNotify, flags: ConnectFlags) -> c.ulong ---
	object_unref :: proc(pointer: Pointer) ---

	// GMenu
	menu_new :: proc() -> ^Menu ---
	menu_append_item :: proc(menu: ^Menu, item: ^MenuItem) ---
	menu_append_section :: proc(menu: ^Menu, label: cstring, section: ^MenuModel) ---

	// GMenuItem
	menu_item_new :: proc(label: cstring, detailed_action: cstring) -> ^MenuItem ---
	menu_item_set_submenu :: proc(item: ^MenuItem, submenu: ^MenuModel) ---

	// GSimpleAction
	simple_action_new :: proc(name: cstring, parameter_type: ^glib.VariantType) -> ^SimpleAction ---
	simple_action_new_stateful :: proc(name: cstring, parameter_type: ^glib.VariantType, state: ^glib.Variant) -> ^SimpleAction ---
	action_map_add_action :: proc(action_map: ^ActionMap, action: ^Action) ---

	// GCancellable
	cancellable_new :: proc() -> ^Cancellable ---

	// GFile
	file_new_for_path :: proc(path: cstring) -> ^File ---
}

signal_connect :: proc(instance: $T1, detailed: cstring, handler: $T2, data: Pointer = nil) {
	signal_connect_data(
		Pointer(instance),
		detailed,
		Callback(handler),
		Pointer(data),
		nil,
		.ConnectDefault,
	)
}

signal_connect_after :: proc(instance: $T1, detailed: cstring, handler: $T2, data: Pointer = nil) {
	signal_connect_data(
		Pointer(instance),
		detailed,
		Callback(handler),
		Pointer(data),
		nil,
		.ConnectAfter,
	)
}

signal_connect_swapped :: proc(
	instance: $T1,
	detailed: cstring,
	handler: $T2,
	data: Pointer = nil,
) {
	signal_connect_data(
		Pointer(instance),
		detailed,
		Callback(handler),
		Pointer(data),
		nil,
		.ConnectSwapped,
	)
}

