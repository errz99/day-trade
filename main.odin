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
	} else {
		tui.run_tui()
	}
}
