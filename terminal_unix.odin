// Terminal mode is only offered on Linux and macOS. On Windows the executables
// are GUI-subsystem apps and running a text UI reliably from them has proven
// troublesome across terminals, so it is not available there.
#+build linux, darwin
package main

import "core:os"
import "ui/tui"

// Terminal mode: "-t" or "--terminal" runs the text UI instead of the GUI
has_terminal_flag :: proc(args: []string) -> bool {
	for arg in args[1:] {
		if arg == "-t" || arg == "--terminal" {
			return true
		}
	}
	return false
}

// Runs the text UI when the terminal flag is present; reports whether it ran
run_terminal_mode :: proc() -> bool {
	if has_terminal_flag(os.args) {
		tui.run_tui()
		return true
	}
	return false
}
