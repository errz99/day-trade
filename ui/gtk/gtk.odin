package gtk_ui

import dt "../../data"
import gio "../../lib/gtk4/glib/gio"
import gtk "../../lib/gtk4/gtk"
import common "../common"
import runtime "base:runtime"
import "core:c"
import "core:dynlib"
import "core:fmt"
import "core:mem"
import "core:strings"

// ============================================================================
// Optional Adwaita (libadwaita) support
//
// libadwaita is loaded on demand through core:dynlib so that the executable has
// NO static dependency on it: Adwaita is only used when the config says so AND
// the library is actually present on the system. If either condition fails the
// app falls back to a plain GtkApplication.
// ============================================================================

// Keeps the loaded library alive for the whole run
_adwaita_lib: dynlib.Library

Adw_Application_New :: #type proc "c" (app_id: cstring, flags: gio.ApplicationFlags) -> gio.Pointer

// DLL names to try (they vary depending on how the GTK4 runtime was built)
ADWAITA_DLL_NAMES :: [?]string{"adwaita-1-0.dll", "libadwaita-1-0.dll", "libadwaita-1.dll"}

// Attempts to load libadwaita and resolve adw_application_new
load_adwaita :: proc() -> (Adw_Application_New, bool) {
	for name in ADWAITA_DLL_NAMES {
		lib, ok := dynlib.load_library(name)
		if !ok do continue

		proc_ptr, found := dynlib.symbol_address(lib, "adw_application_new")
		if !found do continue

		_adwaita_lib = lib
		return cast(Adw_Application_New)proc_ptr, true
	}
	return nil, false
}


// Per-button payload: which action to run and the shared context it belongs to
Button_Info :: struct {
	action: common.MenuAction,
	ctx:    ^Context,
}

// Shared UI session context (lives for the whole run, valid during the main loop)
Context :: struct {
	app:        ^gtk.Application,
	window:     ^gtk.Window,
	data:       dt.Data,
	config:     dt.Config,
	texts:      common.Menu_Texts,
	alloc:      mem.Allocator, // session arena allocator, restored inside "c" callbacks
	temp_alloc: mem.Allocator,
	buttons:    [len(common.MENU_ACTIONS)]Button_Info,
}

// "c" callbacks have no implicit context; the first thing they must do is
// restore the session one so that any Odin code invoked from them can allocate
// through the session arena

// Escapes a runtime string so it can be safely embedded in Pango markup
escape_markup :: proc(s: string, allocator := context.allocator) -> string {
	out := s
	out, _ = strings.replace_all(out, "&", "&amp;", allocator)
	out, _ = strings.replace_all(out, "<", "&lt;", allocator)
	out, _ = strings.replace_all(out, ">", "&gt;", allocator)
	return out
}

// Opens a modal, transient dialog window for a section (placeholder content)
open_section_dialog :: proc(ctx: ^Context, title: cstring) {
	dialog := cast(^gtk.Window)gtk.window_new()
	gtk.window_set_title(dialog, title)
	gtk.window_set_default_size(dialog, 320, 180)
	gtk.window_set_transient_for(dialog, ctx.window)
	gtk.window_set_modal(dialog, true)

	vbox := gtk.box_new(.Vertical, 8)
	gtk.widget_set_margin_top(vbox, 24)
	gtk.widget_set_margin_bottom(vbox, 24)
	gtk.widget_set_margin_start(vbox, 24)
	gtk.widget_set_margin_end(vbox, 24)

	title_label := gtk.label_new(title)
	gtk.widget_set_halign(title_label, .Center)
	gtk.box_append(cast(^gtk.Box)vbox, title_label)

	pending_label := gtk.label_new(ctx.texts.pending)
	gtk.widget_set_halign(pending_label, .Center)
	gtk.box_append(cast(^gtk.Box)vbox, pending_label)

	gtk.window_set_child(dialog, vbox)
	gtk.window_present(dialog)
}

on_button_clicked :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	info := cast(^Button_Info)user_data
	ctx := info.ctx

	context = runtime.default_context()
	context.allocator = ctx.alloc
	context.temp_allocator = ctx.temp_alloc

	switch info.action {
	case .Exit:
		// End of the GUI session: persist data, window size and config, then quit.
		// Position is not manageable from GTK4, so it stays untouched.
		ctx.config.window.width = int(gtk.widget_get_width(cast(^gtk.Widget)ctx.window))
		ctx.config.window.height = int(gtk.widget_get_height(cast(^gtk.Widget)ctx.window))
		dt.save_data("data.json", ctx.data)
		dt.save_config("config.json", ctx.config)
		gio.application_quit(cast(^gio.Application)ctx.app)
	case .Trade, .Results, .Account, .Config:
		open_section_dialog(ctx, common.action_title(ctx.texts, info.action))
	}
}

on_activate :: proc "c" (_: ^gtk.Application, user_data: gio.Pointer) {
	ctx := cast(^Context)user_data

	context = runtime.default_context()
	context.allocator = ctx.alloc
	context.temp_allocator = ctx.temp_alloc

	window := cast(^gtk.Window)gtk.application_window_new(ctx.app)
	ctx.window = window
	gtk.window_set_title(window, "Day Trade")

	// Restore the saved window size (GTK4 cannot manage window position)
	if ctx.config.window.width > 0 && ctx.config.window.height > 0 {
		gtk.window_set_default_size(
			window,
			cast(c.int)ctx.config.window.width,
			cast(c.int)ctx.config.window.height,
		)
	} else {
		gtk.window_set_default_size(window, 320, 400)
	}

	root := gtk.box_new(.Vertical, 8)
	gtk.widget_set_margin_top(root, 24)
	gtk.widget_set_margin_bottom(root, 24)
	gtk.widget_set_margin_start(root, 24)
	gtk.widget_set_margin_end(root, 24)

	// 1. Label with the name of the active account
	active_account := &ctx.data.accounts[ctx.data.active_account]
	escaped := escape_markup(active_account.name)
	markup := fmt.tprintf("<b>%s: %s</b>", string(ctx.texts.account), escaped)

	account_label := gtk.label_new(cstring(""))
	gtk.label_set_markup(cast(^gtk.Label)account_label, strings.clone_to_cstring(markup))
	gtk.widget_set_halign(account_label, .Center)
	gtk.widget_set_margin_bottom(account_label, 16)
	gtk.box_append(cast(^gtk.Box)root, account_label)

	// 2. Column of menu buttons, each launching its own dialog
	for action, i in common.MENU_ACTIONS {
		ctx.buttons[i].action = action
		ctx.buttons[i].ctx = ctx

		button := gtk.button_new_with_label(common.action_title(ctx.texts, action))
		gtk.widget_set_hexpand(button, true)
		gtk.box_append(cast(^gtk.Box)root, button)
		gio.signal_connect(button, "clicked", on_button_clicked, gio.Pointer(&ctx.buttons[i]))
	}

	gtk.window_set_child(window, root)
	gtk.window_present(window)
}

run_gtk :: proc() {
	// Session memory: a dynamic arena holds everything allocated this run
	// (including the JSON data loaded at start) and is freed when the app quits
	session_arena: mem.Dynamic_Arena
	alloc := common.begin_session_arena(&session_arena)
	defer mem.dynamic_arena_destroy(&session_arena)

	// Load the application data and configuration (language) at session start;
	// config is persisted again when the session ends
	data := common.load_session_data("data.json")
	cfg := dt.load_config("config.json")

	ctx := Context {
		data       = data,
		config     = cfg,
		texts      = common.get_menu_texts(cfg.language),
		alloc      = alloc,
		temp_alloc = context.temp_allocator,
	}
	for &b in ctx.buttons {
		b.ctx = &ctx
	}

	app: ^gtk.Application
	if cfg.use_adwaita {
		// Adwaita requested: use libadwaita's AdwApplication when the library is
		// available on the system; otherwise fall back to a plain GtkApplication
		if adw_new, ok := load_adwaita(); ok {
			app = cast(^gtk.Application)adw_new("com.daytrade.gtk", .DefaultFlags)
		} else {
			app = gtk.application_new("com.daytrade.gtk", .DefaultFlags)
		}
	} else {
		app = gtk.application_new("com.daytrade.gtk", .DefaultFlags)
	}
	ctx.app = app
	defer gio.object_unref(gio.Pointer(app))

	gio.signal_connect(app, "activate", on_activate, gio.Pointer(&ctx))

	_ = gio.application_run(cast(^gio.Application)app, 0, nil)
}
