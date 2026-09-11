package iup_ui

// Debug aids for this UI, compiled out unless they are asked for:
//
//   odin build . -define:UI=iup -define:DT_TRACE=true   # writes _dt_trace.txt
//   odin build . -define:UI=iup -define:DT_DRIVE=true   # opens dialogs on its own
//
// The trace follows the dialog life cycle (who opens and closes what, and the
// state left behind), which is what is needed when the app misbehaves without a
// debugger. The driver opens a dialog every tick, cycling through the menu, so
// the dialog cycle can be exercised inside the main loop without clicking.

import common "../common"
import iup "../../lib/iup"
import runtime "base:runtime"
import "core:fmt"
import "core:os"

TRACE_ENABLED :: #config(DT_TRACE, false)
DRIVE_ENABLED :: #config(DT_DRIVE, false)

trace :: proc(format: string, args: ..any) {
	when TRACE_ENABLED {
		if f, err := os.open("_dt_trace.txt", {.Append, .Create, .Write}); err == nil {
			defer os.close(f)
			os.write_string(f, fmt.tprintf(format, ..args))
			os.write_string(f, "\n")
		}
	}
}

_drive_step := 0

drive_open_next :: proc() {
	order := [?]common.MenuAction{.Trade, .Results, .Account, .Config}
	action := order[_drive_step % len(order)]

	trace("drive %d: opening %v", _drive_step + 1, action)
	switch action {
	case .Trade:
		open_trade_dialog()
	case .Results, .Account, .Config:
		open_section_dialog(common.action_title(_app.texts, action))
	case .Exit:
	}
	_drive_step += 1
}

drive_timer_cb :: proc "c" (ih: iup.Ihandle) -> i32 {
	context = runtime.default_context()
	context.allocator = _app.alloc
	context.temp_allocator = _app.temp_alloc

	if _app.dialog_open {
		return iup.DEFAULT
	}
	if _drive_step >= 10 {
		trace("drive finished")
		iup.IupExitLoop()
		return iup.DEFAULT
	}

	drive_open_next()
	return iup.DEFAULT
}
