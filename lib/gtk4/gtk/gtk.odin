package gtk

import "../cairo"
import "../gdk"
import "../glib"
import g "../glib/gio"
import "core:c"

when ODIN_OS == .Windows {
	foreign import gtk "../windows/gtk-4.lib"
} else {
	foreign import gtk "system:gtk-4"
}

// gtk4
Application :: distinct rawptr // GtkApplication
ApplicationWindow :: distinct rawptr // GtkApplicationWindow
AlertDialog :: distinct rawptr // GtkAlertDialog
FileDialog :: distinct rawptr // GtkFileDialog
Box :: distinct rawptr // GtkBox
Button :: distinct rawptr // GtkButton
CheckButton :: distinct rawptr // GtkCheckButton
DrawingArea :: distinct rawptr // GtkDrawingArea

DrawingAreaDrawFunc :: #type proc "c" (
	area: ^DrawingArea,
	cr: ^cairo.context_t,
	width: i32,
	height: i32,
	user_data: g.Pointer,
)

EventController :: distinct rawptr // GtkEventController
EventControllerKey :: distinct rawptr // GtkEventControllerKey
EventControllerFocus :: distinct rawptr // GtkEventControllerFocus
Gesture :: distinct rawptr // GtkGesture
GestureClick :: distinct rawptr // GtkGestureClick
GestureSingle :: distinct rawptr // GtkGestureSingle
Grid :: distinct rawptr // GtkGrid
Label :: distinct rawptr // GtkLabel
LayoutManager :: distinct rawptr // GtkLayoutManager
PopoverMenu :: distinct rawptr // GtkPopoverMenu
Popover :: distinct rawptr // GtkPopover
Widget :: distinct rawptr // GtkWidget
Window :: distinct rawptr // GtkWindow
Settings :: distinct rawptr // GtkSettings
EntryBuffer :: distinct rawptr // GtkEntryBuffer

// Gtk.Align
Align :: enum {
	Fill     = 0,
	Start    = 1,
	End      = 2,
	Center   = 3,
	Baseline = 4,
}
// Gtk.BaselinePosition
BaselinePosition :: enum {
	Top    = 0,
	Center = 1,
	Bottom = 2,
}
// Gtk.Orientation
Orientation :: enum {
	Horizontal = 0,
	Vertical   = 1,
}
// Gtk.WindowType
WindowType :: enum {
	TopLevel = 0,
	Popup    = 1,
}
// Gtk.EventControllerScrollFlags
EventControllerScrollFlags :: enum {
	None              = 0,
	Vertical          = 1,
	Horizontal        = 2,
	BothAxes          = 3,
	Dicrete           = 4,
	Kinetic           = 8,
	PhysicalDirection = 16,
}

// Gtk.PopoverMenuFlags
PopoverMenuFlags :: enum {
	Sliding = 0,
	Nested  = 1,
}

// Gtk.PositionType
PositionType :: enum {
	PosLeft   = 0,
	PosRight  = 1,
	PosTop    = 2,
	PosBottom = 3,
}

@(default_calling_convention = "c")
@(link_prefix = "gtk_")
foreign gtk {
	// GtkApplication
	application_new :: proc(app_id: cstring, flags: g.ApplicationFlags) -> ^Application ---
	application_set_menubar :: proc(app: ^Application, menubar: ^g.MenuModel) ---
	application_set_accels_for_action :: proc(app: ^Application, detailed_action_name: cstring, accels: [^]cstring) ---

	// GtkAlertDialog
	alert_dialog_new :: proc(format: cstring, #c_vararg var_args: ..any) -> ^AlertDialog ---
	alert_dialog_set_buttons :: proc(self: ^AlertDialog, buttons: [^]cstring) ---
	alert_dialog_set_cancel_button :: proc(self: ^AlertDialog, button: c.int) ---
	alert_dialog_set_default_button :: proc(self: ^AlertDialog, button: c.int) ---
	alert_dialog_set_detail :: proc(self: ^AlertDialog, detail: cstring) ---
	alert_dialog_set_message :: proc(self: ^AlertDialog, message: cstring) ---
	alert_dialog_set_modal :: proc(self: ^AlertDialog, modal: bool) ---
	alert_dialog_show :: proc(self: ^AlertDialog, parent: ^Window) ---
	alert_dialog_choose :: proc(self: ^AlertDialog, parent: ^Window, cancellable: ^g.Cancellable, callback: g.AsyncReadyCallback, data: g.Pointer) ---
	alert_dialog_choose_finish :: proc(self: ^AlertDialog, result: ^g.AsyncResult, error: ^glib.Error) ---

	// GtkFileDialog
	file_dialog_new :: proc() -> ^FileDialog ---
	file_dialog_set_initial_folder :: proc(self: ^FileDialog, folder: ^g.File) ---

	// GtkEventController
	event_controller_focus_new :: proc() -> ^EventController ---
	event_controller_key_new :: proc() -> ^EventController ---
	event_controller_legacy_new :: proc() -> ^EventController ---
	event_controller_motion_new :: proc() -> ^EventController ---
	event_controller_scroll_new :: proc(flags: EventControllerScrollFlags) -> ^EventController ---
	event_controller_get_modifier_type :: proc(controller: ^EventController) -> gdk.ModifierType ---
	event_controller_get_current_event_state :: proc(controller: ^EventController) -> gdk.ModifierType ---

	accelerator_get_default_mod_mask :: proc() -> gdk.ModifierType ---

	// GtkGesture
	gesture_click_new :: proc() -> ^Gesture ---
	gesture_single_set_button :: proc(gesture: ^GestureSingle, button: c.uint) -> ^Gesture ---

	// GtkWidget
	widget_add_controller :: proc(widget: ^Widget, controller: ^EventController) ---
	widget_contains :: proc(widget: ^Widget, x, y: c.double) -> bool ---
	widget_grab_focus :: proc(widget: ^Widget) -> bool ---
	widget_has_focus :: proc(widget: ^Widget) -> bool ---
	widget_hide :: proc(widget: ^Widget) ---
	widget_is_sensitive :: proc(widget: ^Widget) -> bool ---
	widget_is_visible :: proc(widget: ^Widget) -> bool ---
	widget_queue_draw :: proc(widget: ^Widget) ---

	widget_get_name :: proc(widget: ^Widget) -> cstring ---
	widget_get_can_focus :: proc(widget: ^Widget) -> bool ---
	widget_get_focusable :: proc(widget: ^Widget) -> bool ---
	widget_get_height :: proc(widget: ^Widget) -> c.int ---
	widget_get_width :: proc(widget: ^Widget) -> c.int ---
	widget_get_settings :: proc(widget: ^Widget) -> Settings ---
	widget_get_size :: proc(widget: ^Widget, orientation: Orientation) -> c.int ---
	widget_get_size_request :: proc(widget: ^Widget, width, height: ^c.int) ---
	widget_get_visible :: proc(widget: ^Widget) -> bool ---

	widget_set_can_focus :: proc(widget: ^Widget, focus: bool) ---
	// widget_set_cursor :: proc(widget: ^Widget, cursor: gdk.Cursor) ---
	widget_set_cursor_from_name :: proc(widget: ^Widget, name: cstring) ---
	widget_set_focusable :: proc(widget: ^Widget, focusable: bool) ---
	widget_set_name :: proc(widget: ^Widget, name: cstring) ---
	widget_set_margin_top :: proc(widget: ^Widget, margin: c.int) ---
	widget_set_margin_bottom :: proc(widget: ^Widget, margin: c.int) ---
	widget_set_margin_start :: proc(widget: ^Widget, margin: c.int) ---
	widget_set_margin_end :: proc(widget: ^Widget, margin: c.int) ---
	widget_set_halign :: proc(widget: ^Widget, align: Align) ---
	widget_set_valign :: proc(widget: ^Widget, align: Align) ---
	widget_set_hexpand :: proc(widget: ^Widget, expand: bool) ---
	widget_set_vexpand :: proc(widget: ^Widget, expand: bool) ---
	widget_set_size_request :: proc(widget: ^Widget, width, height: c.int) ---
	widget_set_sensitive :: proc(widget: ^Widget, sensitive: bool) ---
	widget_set_visible :: proc(widget: ^Widget, visible: bool) ---
	widget_set_parent :: proc(widget: ^Widget, parent: ^Widget) ---

	// GtkApplicationWindow
	application_window_new :: proc(application: ^Application) -> ^Widget ---
	application_window_get_show_menubar :: proc(app_window: ^ApplicationWindow) -> bool ---
	application_window_set_show_menubar :: proc(app_window: ^ApplicationWindow, show: bool) ---

	// GtkPopoverMenu
	popover_menu_new_from_model :: proc(model: ^g.MenuModel) -> ^Widget ---
	popover_menu_new_from_model_full :: proc(model: ^g.MenuModel, flags: PopoverMenuFlags) -> ^Widget ---

	// GtkPopover
	popover_present :: proc(popover: ^Popover) ---
	popover_popup :: proc(popover: ^Popover) ---
	popover_popdown :: proc(popover: ^Popover) ---
	popover_set_autohide :: proc(popover: ^Popover, autohide: bool) ---
	popover_set_cascade_popdown :: proc(popover: ^Popover, cascade: bool) ---
	popover_set_child :: proc(popover: ^Popover, child: ^Widget) ---
	popover_set_default_widget :: proc(popover: ^Popover, widget: ^Widget) ---
	popover_set_mnemonics_visible :: proc(popover: ^Popover, visible: bool) ---
	popover_set_has_arrow :: proc(popover: ^Popover, has_arrow: bool) ---
	popover_set_offset :: proc(popover: ^Popover, x_offset, y_offset: c.int) ---
	popover_set_position :: proc(popover: ^Popover, position: PositionType) ---
	popover_set_pointing_to :: proc(popover: ^Popover, rect: ^gdk.Rectangle) ---

	// GtkBox
	box_new :: proc(orientation: Orientation, spacing: c.int) -> ^Widget ---
	box_append :: proc(box: ^Box, child: ^Widget) ---
	box_prepend :: proc(box: ^Box, child: ^Widget) ---
	box_remove :: proc(box: ^Box, child: ^Widget) ---
	box_reorder_child_after :: proc(box: ^Box, child, sibling: ^Widget) ---
	box_get_homogeneous :: proc(box: ^Box) -> bool ---
	box_set_homogeneous :: proc(box: ^Box, homogeneous: bool) ---
	box_set_spacing :: proc(box: ^Box, amount: c.int) ---
	box_set_baseline_position :: proc(box: ^Box, position: BaselinePosition) ---

	// GtkButton
	button_new :: proc() -> ^Widget ---
	button_new_with_label :: proc(str: cstring) -> ^Widget ---
	button_new_with_mnemonic :: proc(str: cstring) -> ^Widget ---
	button_get_label :: proc(button: ^Button) -> cstring ---
	button_set_label :: proc(button: ^Button, label: cstring) ---

	// GtkCheckButton
	check_button_new :: proc() -> ^Widget ---
	check_button_new_with_label :: proc(str: cstring) -> ^Widget ---
	check_button_new_with_mnemonic :: proc(str: cstring) -> ^Widget ---
	check_button_get_active :: proc(check_button: ^CheckButton) -> bool ---
	check_button_set_active :: proc(check_button: ^CheckButton, active: bool) ---
	check_button_set_label :: proc(check_button: ^CheckButton, label: cstring) ---

	// GtkEntryBuffer
	entry_buffer_new :: proc(initial_chars: cstring, n_initial_chars: c.int) -> ^EntryBuffer ---
	entry_buffer_set_text :: proc(buffer: ^EntryBuffer, chars: cstring, n_chars: c.int) ---

	// GtkEntry
	entry_new :: proc() -> ^Widget ---
	entry_new_with_buffer :: proc(buffer: ^EntryBuffer) -> ^Widget ---

	// GtkDrawinArea
	drawing_area_new :: proc() -> ^Widget ---
	drawing_area_set_draw_func :: proc(area: ^DrawingArea, draw_func: DrawingAreaDrawFunc, user_data: g.Pointer, destroy: glib.DestroyNotify) ---

	// GtkGrid
	grid_new :: proc() -> ^Widget ---
	grid_attach :: proc(grid: ^Grid, child: ^Widget, lef, top, width, height: c.int) ---
	grid_remove :: proc(grid: ^Grid, child: ^Widget) ---
	grid_insert_column :: proc(grid: ^Grid, position: c.int) ---
	grid_insert_row :: proc(grid: ^Grid, position: c.int) ---
	grid_set_row_spacing :: proc(grid: ^Grid, spacing: c.uint) ---
	grid_set_column_spacing :: proc(grid: ^Grid, spacing: c.uint) ---
	grid_set_column_homogeneous :: proc(grid: ^Grid, homogeneous: bool) ---
	grid_set_row_homogeneous :: proc(grid: ^Grid, homogeneous: bool) ---

	// GtkLabel
	label_new :: proc(str: cstring) -> ^Widget ---
	label_set_markup :: proc(label: ^Label, str: cstring) ---
	label_set_text :: proc(label: ^Label, str: cstring) ---

	// GtkWindow
	window_new :: proc(type: WindowType = .TopLevel) -> ^Widget ---
	window_close :: proc(window: ^Window) ---
	window_destroy :: proc(window: ^Window) ---
	window_fullscreen :: proc(window: ^Window) ---
	window_maximize :: proc(window: ^Window) ---
	window_minimize :: proc(window: ^Window) ---
	window_unmaximize :: proc(window: ^Window) ---
	window_unminimize :: proc(window: ^Window) ---
	window_present :: proc(window: ^Window) ---

	window_get_position :: proc(window: ^Window, x, y: ^c.int) ---
	window_get_child :: proc(window: ^Window) -> ^Widget ---
	window_get_decorated :: proc(window: ^Window) -> bool ---
	window_get_default_widget :: proc(window: ^Window) -> ^Widget ---
	window_get_default_size :: proc(window: ^Window, width, height: ^c.int) ---
	window_is_fullscreen :: proc(window: ^Window) -> bool ---

	window_get_title :: proc(window: ^Window) -> cstring ---
	window_set_application :: proc(window: ^Window, application: ^Application) -> ^Window ---
	window_set_child :: proc(window: ^Window, child: ^Widget) ---
	window_set_default_size :: proc(window: ^Window, width, height: c.int) ---
	window_set_focus :: proc(window: ^Window, focus: ^Widget) ---
	window_set_position :: proc(window: ^Window, x, y: c.int) ---
	window_set_resizable :: proc(window: ^Window, resizable: bool) ---
	window_set_modal :: proc(window: ^Window, modal: bool) ---
	window_set_size :: proc(window: ^Window, width, height: c.int) ---
	window_set_title :: proc(window: ^Window, title: cstring) ---
	window_set_transient_for :: proc(window: ^Window, parent: ^Window) ---
}

