package main

// Small Windows-only helper that embeds a manifest file into an .exe as the
// RT_MANIFEST (id 1) resource, without requiring the Windows SDK's mt.exe.

import "core:fmt"
import "core:os"
import "core:unicode/utf16"
import "core:unicode/utf8"

foreign import kernel32 "system:Kernel32.lib"

// RT_MANIFEST resource id; the application manifest is always resource #1
RT_MANIFEST :: uintptr(24)
RES_NAME    :: uintptr(1)

@(default_calling_convention = "system")
foreign kernel32 {
	BeginUpdateResourceW :: proc(file_name: [^]u16, delete_existing: i32) -> rawptr ---
	UpdateResourceW      :: proc(update: rawptr, resource_type: rawptr, name: rawptr, language: u16, data: rawptr, size: u32) -> i32 ---
	EndUpdateResourceW   :: proc(update: rawptr, discard: i32) -> i32 ---
}

// Converts an UTF-8 path to a NUL-terminated UTF-16 buffer
to_wide :: proc(s: string, allocator := context.allocator) -> []u16 {
	runes := utf8.string_to_runes(s, allocator)
	defer delete(runes)

	buf := make([]u16, len(runes) + 1, allocator)
	utf16.encode(buf[:len(runes)], runes)
	buf[len(runes)] = 0
	return buf
}

main :: proc() {
	if len(os.args) != 3 {
		fmt.eprintln("usage: embed_manifest <exe-file> <manifest-file>")
		os.exit(2)
	}
	exe_path := os.args[1]
	manifest_path := os.args[2]

	manifest, err := os.read_entire_file(manifest_path, context.allocator)
	if err != os.ERROR_NONE {
		fmt.eprintln("cannot read manifest file:", manifest_path)
		os.exit(1)
	}
	defer delete(manifest)
	if len(manifest) == 0 {
		fmt.eprintln("manifest file is empty:", manifest_path)
		os.exit(1)
	}

	exe_wide := to_wide(exe_path)
	defer delete(exe_wide)

	update := BeginUpdateResourceW(&exe_wide[0], 0)
	if update == nil {
		fmt.eprintln("BeginUpdateResourceW failed for:", exe_path)
		os.exit(1)
	}

	if UpdateResourceW(update, cast(rawptr)RT_MANIFEST, cast(rawptr)RES_NAME, 0, &manifest[0], u32(len(manifest))) == 0 {
		fmt.eprintln("UpdateResourceW failed for:", exe_path)
		EndUpdateResourceW(update, 1)
		os.exit(1)
	}

	if EndUpdateResourceW(update, 0) == 0 {
		fmt.eprintln("EndUpdateResourceW failed for:", exe_path)
		os.exit(1)
	}

	fmt.printfln("manifest embedded into %s", exe_path)
}
