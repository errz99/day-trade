package winforms

// Keyboard navigation support (added for this project).
//
// Tab and Shift+Tab are not handled by DefWindowProc: they are processed by
// IsDialogMessage, which the message loop in forms.odin now routes messages
// through. These three functions were missing from the binding, so they are
// declared here, in their own file, to keep the patch to the binding minimal and
// easy to redo when it is updated.

foreign import mag_user32 "system:user32.lib"

foreign mag_user32 {
	@(link_name="GetParent") GetParent :: proc(hWnd: HWND) -> HWND ---
	@(link_name="GetActiveWindow") GetActiveWindow :: proc() -> HWND ---
	@(link_name="IsDialogMessageW") IsDialogMessage :: proc(hDlg: HWND, lpMsg: ^MSG) -> BOOL ---
}
