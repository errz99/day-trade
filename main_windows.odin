package main

// Only compiled on Windows (file name suffix), where the WinForms binding exists.
import "ui/winforms"

run_winforms_ui :: proc() {
	winforms.run_winforms()
}
