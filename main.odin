package main

import "ui/gtk"
import "ui/iup"
import "ui/tui"

UI :: #config(UI, "tui")

main :: proc() {
	when UI == "gtk" || UI == "gtk4" {
		gtk.run_gtk()
	} else when UI == "iup" {
		iup.run_iup()
	} else when UI == "winforms" {
		when ODIN_OS == .Windows {
			run_winforms_ui()
		} else {
			panic("the winforms UI is only available on Windows")
		}
	} else {
		tui.run_tui()
	}
}
