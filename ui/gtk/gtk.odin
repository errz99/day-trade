package gtk_ui

import gio "../../lib/gtk4/glib/gio"
import gtk "../../lib/gtk4/gtk"

on_activate :: proc "c" (app: ^gtk.Application, user_data: gio.Pointer) {
	window := gtk.application_window_new(app)
	gtk.window_set_title(cast(^gtk.Window)window, "Day Trade - GTK4")
	gtk.window_set_default_size(cast(^gtk.Window)window, 400, 300)
	gtk.window_present(cast(^gtk.Window)window)
}

run_gtk :: proc() {
	app := gtk.application_new("com.daytrade.gtk", .DefaultFlags)
	defer gio.object_unref(gio.Pointer(app))

	gio.signal_connect(app, "activate", on_activate, nil)

	_ = gio.application_run(cast(^gio.Application)app, 0, nil)
}
