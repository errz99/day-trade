package iup_ui

import iup "../../lib/iup"

run_iup :: proc() {
	iup.IupOpen(nil, nil)
	defer iup.IupClose()

	dlg := iup.IupDialog(nil)
	iup.IupSetAttribute(dlg, "TITLE", "Day Trade - IUP")
	iup.IupSetAttribute(dlg, "SIZE", "400x300")

	iup.IupShow(dlg)
	iup.IupMainLoop()
}
