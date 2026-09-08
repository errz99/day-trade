package gtk_ui

import common "../common"
import dt "../../data"
import gio "../../lib/gtk4/glib/gio"
import gtk "../../lib/gtk4/gtk"
import runtime "base:runtime"

// ----------------------------------------------------------------------------
// Config dialog.
//
// GTK4 dropped the GtkDialog class, so this is a plain (modal, transient)
// GtkWindow that edits the language and the Adwaita option and commits them
// through OK/Cancel. Language options are shown in their own language.
// ----------------------------------------------------------------------------

Config_Texts :: struct {
	title:          cstring, // window title
	language_label: cstring, // "Language" / "Idioma"
	english:        cstring, // "English"
	spanish:        cstring, // "Español"
	adwaita:        cstring, // "Enable Adwaita theme (GTK)" / "Activar tema Adwaita (GTK)"
	note:           cstring, // changes apply on next start
	ok:             cstring, // "OK" / "Aceptar"
	cancel:         cstring, // "Cancel" / "Cancelar"
}

get_config_texts :: proc(lang: dt.Language) -> Config_Texts {
	switch lang {
	case .English:
		return Config_Texts {
			title          = cstring("Config"),
			language_label = cstring("Language:"),
			english        = cstring("English"),
			spanish        = cstring("Español"),
			adwaita        = cstring("Enable Adwaita theme (GTK)"),
			note           = cstring("These changes take effect the next time the application starts."),
			ok             = cstring("OK"),
			cancel         = cstring("Cancel"),
		}
	case .Spanish:
		return Config_Texts {
			title          = cstring("Configuración"),
			language_label = cstring("Idioma:"),
			english        = cstring("English"),
			spanish        = cstring("Español"),
			adwaita        = cstring("Activar tema Adwaita (GTK)"),
			note           = cstring("Estos cambios se aplicarán la próxima vez que inicies la aplicación."),
			ok             = cstring("Aceptar"),
			cancel         = cstring("Cancelar"),
		}
	}
	return {}
}

// State of the config dialog; lives as long as the dialog window
Config_Dialog_State :: struct {
	window:  ^gtk.Window,
	ctx:     ^Context,
	texts:   Config_Texts,
	english: ^gtk.Widget,
	spanish: ^gtk.Widget,
	adwaita: ^gtk.Widget,
}

on_config_ok :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	state := cast(^Config_Dialog_State)user_data

	context = runtime.default_context()
	context.allocator = state.ctx.alloc
	context.temp_allocator = state.ctx.temp_alloc

	// Commit the edits into the session config
	if gtk.check_button_get_active(cast(^gtk.CheckButton)state.english) {
		state.ctx.config.language = .English
	} else {
		state.ctx.config.language = .Spanish
	}
	state.ctx.config.use_adwaita = gtk.check_button_get_active(cast(^gtk.CheckButton)state.adwaita)

	dt.save_config("config.json", state.ctx.config)
	gtk.window_close(state.window)
}

on_config_cancel :: proc "c" (_: ^gtk.Widget, user_data: gio.Pointer) {
	state := cast(^Config_Dialog_State)user_data
	gtk.window_close(state.window)
}

open_config_dialog :: proc(ctx: ^Context) {
	texts := get_config_texts(ctx.config.language)

	state := new(Config_Dialog_State)
	state.ctx = ctx
	state.texts = texts

	dialog := cast(^gtk.Window)gtk.window_new()
	state.window = dialog
	gtk.window_set_title(dialog, texts.title)
	gtk.window_set_default_size(dialog, 400, 240)
	gtk.window_set_transient_for(dialog, ctx.window)
	gtk.window_set_modal(dialog, b32(true))

	root := gtk.box_new(.Vertical, 10)
	gtk.widget_set_margin_top(root, 20)
	gtk.widget_set_margin_bottom(root, 20)
	gtk.widget_set_margin_start(root, 20)
	gtk.widget_set_margin_end(root, 20)

	// --- Language -----------------------------------------------------------
	language_label := gtk.label_new(texts.language_label)
	gtk.widget_set_halign(language_label, .Start)
	gtk.box_append(cast(^gtk.Box)root, language_label)

	language_row := gtk.box_new(.Horizontal, 16)
	gtk.widget_set_margin_start(language_row, 12)
	gtk.box_append(cast(^gtk.Box)root, language_row)

	// Same group => the two check buttons behave like radio buttons (GTK keeps
	// exactly one of them active), so no manual exclusivity handling is needed
	english_check := gtk.check_button_new_with_label(texts.english)
	spanish_check := gtk.check_button_new_with_label(texts.spanish)
	gtk.check_button_set_group(cast(^gtk.CheckButton)spanish_check, cast(^gtk.CheckButton)english_check)
	state.english = english_check
	state.spanish = spanish_check

	gtk.check_button_set_active(cast(^gtk.CheckButton)english_check, b32(ctx.config.language == .English))
	gtk.check_button_set_active(cast(^gtk.CheckButton)spanish_check, b32(ctx.config.language == .Spanish))

	gtk.box_append(cast(^gtk.Box)language_row, english_check)
	gtk.box_append(cast(^gtk.Box)language_row, spanish_check)

	// --- Adwaita ------------------------------------------------------------
	adwaita_check := gtk.check_button_new_with_label(texts.adwaita)
	gtk.check_button_set_active(cast(^gtk.CheckButton)adwaita_check, b32(ctx.config.use_adwaita))
	state.adwaita = adwaita_check
	gtk.widget_set_margin_top(adwaita_check, 8)
	gtk.box_append(cast(^gtk.Box)root, adwaita_check)

	// --- Note ---------------------------------------------------------------
	note_label := gtk.label_new(texts.note)
	gtk.widget_set_halign(note_label, .Start)
	gtk.widget_set_margin_top(note_label, 4)
	gtk.box_append(cast(^gtk.Box)root, note_label)

	// --- Buttons ------------------------------------------------------------
	button_row := gtk.box_new(.Horizontal, 8)
	gtk.widget_set_halign(button_row, .End)
	gtk.widget_set_margin_top(button_row, 12)
	gtk.box_append(cast(^gtk.Box)root, button_row)

	cancel_button := gtk.button_new_with_label(texts.cancel)
	ok_button := gtk.button_new_with_label(texts.ok)
	gtk.box_append(cast(^gtk.Box)button_row, cancel_button)
	gtk.box_append(cast(^gtk.Box)button_row, ok_button)

	gio.signal_connect(cancel_button, "clicked", on_config_cancel, gio.Pointer(state))
	gio.signal_connect(ok_button, "clicked", on_config_ok, gio.Pointer(state))

	gtk.window_set_child(dialog, root)
	gtk.window_present(dialog)
}
