package main

import "ui/gtk"
import "ui/iup"

// Which graphical backend to build: gtk (default), iup or winforms
UI :: #config(UI, "gtk")

main :: proc() {
	// Terminal mode (-t / --terminal) is available on Linux and macOS only;
	// see terminal_unix.odin
	when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		if run_terminal_mode() {
			return
		}
	}

	when UI == "iup" {
		iup.run_iup()
	} else when UI == "winforms" {
		when ODIN_OS == .Windows {
			run_winforms_ui()
		} else {
			panic("the winforms UI is only available on Windows")
		}
	} else {
		gtk.run_gtk()
	}
}
