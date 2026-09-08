/*
	Major Update on 3rd week of 2023 October.
*/

/*===========================================Control Docs=========================================================
    Control struct
        Constructor: No constructor available. It's an abstract type.
        Properties:
            kind 		: ControlKind - An enum in this file.
			name 		: string
			handle 		: HWND
			controlID 	: UINT
			parent 		: ^Form
			text 		: string
			width		: int
			height 		: int
			xpos		: int
			ypos 		: int
			font 		: Font
			backColor 	: uint
			foreColor 	: uint
			enabled 	: bool
			visible 	: bool
			contextMenu : ^ContextMenu [See contextmenu.odin]
        Functions:
			control_enable	
			cright
			cbottom
			control_visibile
			control_setdisable
			control_set_forecolor
			control_set_font
			control_set_font_name
			control_set_font_size
			control_set_position
			control_set_size
			control_set_text
			control_get_text
			control_set_backcolor
			control_set_forecolor
			control_Setfocus
        Events:
			PaintEventHandler type - proc(^Control, ^PaintEventArgs) [See events.odin]
				onPaint
            EventHandler type - proc(^Control, ^EventArgs) [See events.odin]
                onGotFocus
				onLostFocus 
				onMouseEnter
				onClick
				onRightClick
				onDoubleClick
				onMouseLeave
				onSizeChanging
				onSizeChanged
				onDestroy
			MouseEventHandler type - proc(^Control, ^MouseEventArgs) [See events.odin]
				onMouseDown
				onRightMouseDown
				onMouseUp
				onRightMouseUp
				onMouseScroll
				onMouseMove
				onMouseHover
			KeyEventHandler type - proc(^Control, ^KeyEventArgs) [See events.odin]
				onKeyUp
				onKeyDown
				onKeyPress
==============================================================================================================*/


#+feature using-stmt
package winforms

import "base:runtime"
import api "core:sys/windows"
import "core:reflect"
import "core:fmt"

globalSubClassID : int = 2001
globalCtlID : UINT= 100
MOUSE_ENTER_EVENT      :: 1 << 0
MOUSE_HOVER_EVENT      :: 1 << 1
MOUSE_LEAVE_EVENT      :: 1 << 2

CreateHandleProc :: proc(this: ^Control)

// A base class for all controls & Form.
Control :: struct
{
	kind : ControlKind,
	name : string,
	handle : HWND,
	controlID : UINT,
	parent : ^Control,
	text : string,
	width, height : i32,
    xpos, ypos : i32,
    font : Font,
	backColor : uint,
	foreColor : uint,
	enabled : bool,
	visible : bool,
	contextMenu : ^ContextMenu,

    _style, _exStyle : DWORD,
	_isMouseTracking: BOOL,
	_isCreated : b64,
	_isMouseEntered : bool,
	_isPressed: bool,
	_mDownHappened, _mRDownHappened : bool,
	_SizeIncr : SizeIncrement,
	_clsName : wstring,
	_drawFlag: uint,
	_cachedWidth, _cachedHeight : i32,
	_fp_size_fix : ControlDelegate,
	_inherit_color: bool,
	_textable: bool,
	_cmenuUsed: bool,
	_hasFont: bool,
	_autoSizable: bool,
	_wtext : ^WideString,
	_fcref : COLORREF,
	_myRect : RECT,
	_mouseEvents: bit_set[SpecialMouseEvents; u8],
	_tmeFlags: DWORD,
	_ownerForm: ^Form,
	_createHandleProc: CreateHandleProc,
	clrChanged : bool,

	// Events
	onPaint : PaintEventHandler,
	onGotFocus,
	onLostFocus ,
	onMouseEnter,
	onMouseHover,
	onClick,
	onRightClick,
	onDoubleClick,
	onMouseLeave,
	onSizeChanging,
	onSizeChanged : EventHandler,

    onMouseDown,
    onRightMouseDown,
    onMouseUp,
    onRightMouseUp,
    onMouseScroll,
    onMouseMove : MouseEventHandler,

    onKeyUp,
	onKeyDown,
	onKeyPress : KeyEventHandler,
	onHandleCreated,
	onDestroy : EventHandler,
}





// Create a Control. Use this for all controls.
create_control :: proc(this : ^Control, width: i32 = 0, height: i32 = 0 )
{
	if this.handle != nil do return		
	this._tmeFlags = 0 
	ctlInfo := ControlStaticData[this.kind]
	ctrl_txt_ptr : WCPTR = nil
	if ctlInfo.isTextable && len(this.text) > 0 do ctrl_txt_ptr = this._wtext.ptr 

	if this.kind == .Tree_View {
		if this._style & TVS_EDITLABELS != 0 {
			fmt.println("TVS_EDITLABELS is present")
		} else {
			fmt.println("TVS_EDITLABELS is NOT present")
		}
	}

    this.handle = CreateWindowEx(  this._exStyle,
								ctlInfo.clsName,
								ctrl_txt_ptr,
								this._style,
								i32(this.xpos),
								i32(this.ypos),
								width,
								height,
								this.parent.handle,
								dir_cast(this.controlID, HMENU),
								app.hInstance,
								nil )

    if this.handle != nil {
        this._isCreated = true
		GetClientRect(this.handle, &this._myRect)	
		if ctlInfo.hasFont do setfont_internal(this)

	}else {
		ptf("Failed to create control, error code: %d\n", GetLastError())
    }

	if this.kind == .Tree_View {
		style := cast(DWORD) api.GetWindowLongPtrW(this.handle, GWL_STYLE)

		fmt.printfln("Actual TreeView style: 0x%X", style)

		if style & TVS_EDITLABELS != 0 {
			fmt.println("TVS_EDITLABELS is PRESENT in HWND style")
		} else {
			fmt.println("TVS_EDITLABELS is NOT present in HWND style")
		}
	}
}

control_base_init :: proc(this: ^Control, parent: ^Control, x, y, w, h: i32, ctlCounter: ^int, ctxt: string = "")
{
	info := ControlStaticData[this.kind]
	this.parent = parent
	this.xpos = x
	this.ypos = y
	this.width = w
	this.height = h
	this._style = info.style
	this._exStyle = info.exStyle
	this.name = fmt.aprintf("%s%d", info.prefix, ctlCounter^)
	this.controlID = globalCtlID

	ctlCounter^ += 1
	globalCtlID += 1	
	
	if info.isTextable {
		if ctxt != "" do this.text = ctxt
		this._wtext = new_widestring(ctxt)	
	}

	if parent != nil {
		styleSrc : ^Control = parent.kind == ControlKind.Group_Box? parent.parent : parent
		if info.hasFont do font_clone(&styleSrc.font, &this.font, true) 
		if info.bkMode == .Inherit_BGC {
			this.backColor = styleSrc.backColor
		} else if info.bkMode == .White_BGC {
			this.backColor = def_back_clr
		} 
		this._ownerForm = parent.kind == .Form ? cast(^Form)parent : cast(^Form)parent._ownerForm
		if info.blackFGC do this.foreColor = def_fore_clr
		append(&this._ownerForm._controls, this)
	}
}

control_base_dtor :: proc(this: ^Control)
{
	delete(this.name)
	cinfo := ControlStaticData[this.kind]
	if cinfo.isTextable && this._wtext != nil do widestring_destroy(this._wtext)
	if cinfo.hasFont do font_destroy(&this.font)
	if this._cmenuUsed do contextmenu_dtor(this.contextMenu)
	// ptf("ctrl name: %s, cmenu: %s", this.name, this._cmenuUsed)
}


control_place_right :: proc(this: ^Control, rightOf: ^Control, gap: i32 = 10)
{
	newxpos := rightOf.xpos + rightOf.width + gap
	control_set_position(this, newxpos, rightOf.ypos)
	// ptf("New xpos: %d, rightOf.xpos: %d", newxpos, rightOf.xpos)
}


common_mouse_leave_handler :: proc(this: ^Control)
{
	this._isMouseEntered = false
	// alert2("Common Mouse leave message from %s", this.kind)
}

control_setpos :: #force_inline proc(this: ^Control, flag: UINT) {
    SetWindowPos(this.handle, nil, this.xpos, this.ypos, this.width, this.height, flag)
}

control_setpos2 :: #force_inline proc(hw: HWND, x, y, w, h: i32, flag: UINT) {
	SetWindowPos(hw, nil, x, y, w, h, flag)
}

@private ctl_send_msg :: #force_inline proc(hw: HWND, msg: UINT, wp: $T, lp: $U) -> LRESULT
{
	return SendMessage(hw, msg, WPARAM(wp), LPARAM(lp))
}

control_clone_parent_font :: proc(this: ^Control) {
	this.font.name = this.parent.font.name
    this.font.size = this.parent.font.size
    this.font.weight = this.parent.font.weight
    this.font.italics = this.parent.font.italics
    this.font.underline = this.parent.font.underline  
    font_clone_parent_handle(&this.font, nil)
}

// Enable or disable a control or form.
control_enable :: proc(ctl : ^Control, bstate : bool)
{
	ctl.enabled = bstate
	#partial switch ctl.kind {
		case .Number_Picker :
			SendMessage(ctl.handle, WM_ENABLE, WPARAM(bstate), 0)
		case :
			api.EnableWindow(ctl.handle, auto_cast(bstate))
	}
}

// Get the right point of control
cright :: proc(this: ^Control) -> i32
{
	return map_parent_points(this).right
}

// Get the bottom point of control
cbottom :: proc(this: ^Control) -> i32
{
	return map_parent_points(this).bottom
}

// Hide or show a control.
control_visibile :: proc(ctl : ^Control, bstate : bool)
{
	ctl.enabled = bstate
	flag : i32 = SW_HIDE if !bstate else SW_SHOW
	#partial switch ctl.kind {
		case .Number_Picker :
			np := dir_cast(ctl, ^NumberPicker)
			ShowWindow(np.handle, flag)
			ShowWindow(np._buddyHandle, flag)
		case :
			ShowWindow(ctl.handle, flag)
	}
}

// Enable or disable control
control_setdisable :: proc(this: ^Control, value: b8)
{
	if this._isCreated do api.EnableWindow(this.handle, !value)
}


// To set a user defined font before or after creating the control handle
control_set_font :: proc(ctl : ^Control, fn : string, fsz : int,
							fw : FontWeight = .Normal, fi : bool = false, fu : bool = false)
{
	if ctl._hasFont == false do return
	using ctl.font
	name = fn
	size = fsz
	weight = fw
	italics = fi
	underline = fu
	_defFontChanged = true
	font_create_handle(&ctl.font)
	if ctl.handle != nil do ctl_send_msg(ctl.handle, WM_SETFONT, ctl.font.handle, 1)
	if ctl._fp_size_fix != nil do ctl._fp_size_fix(ctl)
}

// Set control's font name
control_set_font_name :: proc(ctl : ^Control, fn : string)
{
	if ctl._hasFont == false do return
	ctl.font._defFontChanged = true
	ctl.font.name = fn
	if ctl._isCreated do control_set_font(ctl, fn, ctl.font.size)
}

// Set control's font size
 control_set_font_size :: proc(ctl : ^Control, fsz : int, )
{
	if ctl._hasFont == false do return
	ctl.font._defFontChanged = true
	ctl.font.size = fsz
	if ctl._isCreated do control_set_font(ctl, ctl.font.name, fsz)
}

// To set the position of a control or form
control_set_position :: proc(ctl : ^Control, x, y : i32)
{
	mx : i32 = ctl.xpos if x == 0 else x
	my : i32 = ctl.ypos if y == 0 else y
	
	// if ctl.kind == .Number_Picker {
	// 	np := cast(^NumberPicker)ctl
	// 	nump_set_pos(np, mx, my)
		
	// } else {
	// 	SetWindowPos(ctl.handle, nil, mx, my, 0, 0, SWP_NOSIZE | SWP_NOZORDER)
	// }
	
}

// To set the size of the control or form
control_set_size :: proc(ctl : ^Control, width, height : i32)
{
	mw : i32 = ctl.width if width == 0 else width
	mh : i32 = ctl.height if height == 0 else height
	SetWindowPos(ctl.handle, nil, 0, 0, mw, mh, SWP_NOMOVE | SWP_NOZORDER)
}

// To set the text of the control or form. Note :- This is not applicable for all controls.
control_set_text :: proc(ctl : ^Control, txt : string)
{
	cinfo := ControlStaticData[ctl.kind]
	if cinfo.isTextable == false do return	
	ctl.text = txt
	widestring_update(&ctl._wtext, txt)

	if ctl._isCreated {
		x := SetWindowText(ctl.handle, to_wstring(txt))
		// ptf("SetWindowText result: %d", x)
		if ctl._autoSizable {
			if ctl.kind == .Label {
				calculate_label_size(cast(^Label)ctl)
			} else {
				calculate_ctl_size(ctl)
			}
			
		}
	}	
}


// To get the text from the control or form.
// Note :- This is not applicable for all controls.
// IMPORTANT := delete the string after use
control_get_text :: proc(ctl : Control, alloc := context.allocator) -> string
{
	tlen := GetWindowTextLength(ctl.handle)
	wsBuffer := make([]WCHAR, tlen + 1, alloc)
	GetWindowText(ctl.handle, &wsBuffer[0], i32(len(wsBuffer)))
	return utf16_to_utf8(wsBuffer, alloc)
}

// To set the back color of a control or form. Note :- This is not applicable for all controls.
control_set_backcolor :: proc{set_back_color1, set_back_color2}

// To set the fore color of a control or form. Note :- This is not applicable for all controls.
control_set_forecolor :: proc{set_fore_color1, set_fore_color2}

// To set a control's focus, but it seems not working.
control_Setfocus :: proc(ctl : ^Control)
{
	// This is not working as i intented. This will erase the text box's back color.
	// I don't know how to fix this.
	// TODO: Fix the focus issue. Maybe we can set focus to a control's child to avoid the back color issue.
	SetFocus(ctl.handle)
}

//=================================================================Private Functions==========================
@private control_cast :: proc($T : typeid, refd : DWORD_PTR) -> ^T
{
	return cast(^T) (cast(UINT_PTR) refd)
}

@private set_subclass :: proc(ctl : ^Control, fn_ptr : SUBCLASSPROC )
{
	api.SetWindowSubclass(ctl.handle, fn_ptr, UINT_PTR(globalSubClassID), to_dwptr(ctl) )
	globalSubClassID += 1
}

// This is used to set the defualt font right creating the control handle.
@private setfont_internal :: proc(ctl : ^Control)
{
	cinfo := ControlStaticData[ctl.kind]
	if cinfo.hasFont == false do return
	if ctl.font.handle == nil do font_create_handle(&ctl.font)
	SendMessage(ctl.handle, WM_SETFONT, WPARAM(ctl.font.handle), LPARAM(1))

}

@private redraw :: proc{redraw_ctl1, redraw_ctl2}
@private redraw_ctl1 :: proc(ctl : ^Control) { if ctl._isCreated do InvalidateRect(ctl.handle, nil, false) }
@private redraw_ctl2:: proc(ctl : Control) { if ctl._isCreated do InvalidateRect(ctl.handle, nil, false) }


@private map_parent_points :: proc(this: ^Control) -> RECT
{
    rc : RECT
    firstHwnd : HWND
    if this._isCreated
	{
        GetClientRect(this.handle, &rc)
        firstHwnd = this.handle
	} else {
        firstHwnd = this.parent.handle
        rc = RECT{i32(this.xpos), i32(this.ypos),
					i32(this.xpos + this.width), i32(this.ypos + this.height )}
	}
    MapWindowPoints(firstHwnd, this.parent.handle, cast(^POINT)&rc, 2)
    return rc
}


// To get the text from a control or form as a wstring.
// Note :- This is not applicable for all controls. [[[Caller must free the buffer]]]
control_get_text_wstr :: proc(ctl : Control, alloc := context.allocator) -> []u16
{
	tlen := GetWindowTextLength(ctl.handle)
	mem_chunks := make([]WCHAR, tlen + 1, alloc)
	wsBuffer : wstring = &mem_chunks[0]
	GetWindowText(ctl.handle, wsBuffer, i32(len(mem_chunks)))
	return wsBuffer[:tlen]
}

@private set_back_color1 :: proc(ctl : ^Control, clr : uint)
{
	// print("not implemented")
	#partial switch ctl.kind {
		case .Button:
			btn := cast(^Button) ctl
			btn_backcolor_control(btn, clr)

		case .Group_Box:
			gb:= cast(^GroupBox) ctl 
			gbx_set_backcolor(gb, clr)

		case .Track_Bar:
			tkb := cast(^TrackBar) ctl
			trackbar_backcolor_setter(tkb, clr)

		case .Tree_View :
			treeview_set_back_color(ctl, clr)

		case : // For all other controls
			ctl.clrChanged = true
			ctl.backColor = clr
			if (ctl._drawFlag & 2) != 2 do ctl._drawFlag += 2
			redraw(ctl)
			//if ctl._isCreated do InvalidateRect(ctl.handle, nil, true)
	}
}

@private set_back_color2 :: proc(ctl : ^Control, clr : Color)
{
	uclr := rgb_to_uint(clr)
	#partial switch ctl.kind {
		case .Button:
			btn := cast(^Button) ctl
			btn_backcolor_control(btn, uclr)
	}
}


//-------------------------------------------------------------

@private set_fore_color1 :: proc(ctl : ^Control, clr : uint)
{
	#partial switch ctl.kind
	{
		case .Button :
			btn := cast(^Button) ctl
			btn_forecolor_control(btn, clr)
		case .Tree_View :
			//tv := cast(^Tree_View) ctl
			ctl.backColor = clr
			if ctl._isCreated
			{
				cref := get_color_ref(clr)
				SendMessage(ctl.handle, TVM_SETTEXTCOLOR, 0, dir_cast(cref, LPARAM))
			}

		case : // for all other controls
			ctl.foreColor = clr
			if (ctl._drawFlag & 1) != 1 do ctl._drawFlag += 1
			if ctl._isCreated do InvalidateRect(ctl.handle, nil, false)
	}
}

@private set_fore_color2 :: proc(ctl : ^Control, clr : Color)
{
	uclr := rgb_to_uint(clr)
	#partial switch ctl.kind {
		case .Button :
			btn := cast(^Button) ctl
			btn_forecolor_control(btn, uclr)
	}
}


//--------------------------------------------------------------





// set_focus :: proc(hwnd : HWND) {SetFocus(hwnd)}

// Common control message handlers
	@private ctrl_common_msg_handler :: proc(this: ^Control, hw: HWND, msg: UINT,wp: WPARAM, lp: LPARAM) -> MsgHandlerReturn
	{
		switch msg {
		case WM_LBUTTONDOWN:
			this._isPressed = true
			if this.onMouseDown != nil {
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wp, lp)
				this.onMouseDown(this, &mea)
			}
			return .Call_Def_Proc

		case WM_RBUTTONDOWN:
			this._isPressed = true
			if this.onRightMouseDown != nil {
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wp, lp)
				this.onRightMouseDown(this, &mea)
			}
			return .Call_Def_Proc

		case WM_LBUTTONUP:				
			if this.onMouseUp != nil	{
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wp, lp)
				this.onMouseUp(this, &mea)
			}

			if this._isPressed && this.onClick != nil {
				pt := POINT{cast(i32)(cast(i16)LOWORD(lp)), cast(i32)(cast(i16)HIWORD(lp))}		
				if PtInRect(&this._myRect, pt) do this->onClick(&gea)
			}
			this._isPressed = false;		
			return .Call_Def_Proc

		case WM_RBUTTONUP:
			if this.onRightMouseUp != nil {
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wp, lp)
				this.onRightMouseUp(this, &mea)
			}
			if this._isPressed && this.onRightClick != nil {
				pt := POINT{cast(i32)(cast(i16)LOWORD(lp)), cast(i32)(cast(i16)HIWORD(lp))}		
				if PtInRect(&this._myRect, pt) do this->onRightClick(&gea)
			}
			this._isPressed = false;
			return .Call_Def_Proc

		case WM_MOUSEHWHEEL:
			if this.onMouseScroll != nil {
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wp, lp)
				this.onMouseScroll(this, &mea)
			}
			return .Call_Def_Proc

		case WM_MOUSEMOVE: // Mouse Enter & Mouse Move is firing from here.
			if this.kind == .Combo_Box {
				cmb_mouse_move_handler(cast(^ComboBox)this, hw, msg, wp, lp)
			} else if this.kind == .Number_Picker {
				nump_mouse_move_handler(cast(^NumberPicker)this, hw, msg, wp, lp)
			} else {
				ctrl_mousemove_handler(this, hw, msg, wp, lp)
			}
			return .Call_Def_Proc			

		case WM_MOUSEHOVER:
			this._isMouseTracking = false
			if this.onMouseHover != nil do this.onMouseHover(this, &gea)
			return .Call_Def_Proc

		case WM_MOUSELEAVE:
			if this.kind == .Combo_Box {
				cmb_mouse_leave_handler(cast(^ComboBox)this)
			} else if this.kind == .Number_Picker {
				nump_mouse_leave_handler(cast(^NumberPicker)this)
			} else {
				ctrl_mouseleave_handler(this)
			}
			return .Call_Def_Proc		

		case WM_CONTEXTMENU:
			if this.contextMenu != nil do contextmenu_show(this.contextMenu, lp)
			return .Call_Def_Proc
		}
		return .Continue
	}
	
// Left Mouse down, up, click

	ctrl_left_mousedown_handler :: proc(ctl: ^Control, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl.onMouseDown != nil {
			mea : MouseEventArgs
			fill_mouse_event_args(&mea, msg, wpm, lpm)
			ctl.onMouseDown(ctl, &mea)
		}
	}

	ctrl_left_mouseup_handler :: proc(ctl: ^Control, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl.onMouseUp != nil {
			mea : MouseEventArgs
			fill_mouse_event_args(&mea, msg, wpm, lpm)
			ctl.onMouseUp(ctl, &mea)
		}
		if ctl.onClick != nil {
			ea := new_event_args()
			ctl.onClick(ctl, &ea)
		}
	}
	
// End section

// Right mouse down, up, click
	ctrl_right_mousedown_handler :: proc(ctl: ^Control, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl.onRightMouseDown != nil {
			mea : MouseEventArgs
			fill_mouse_event_args(&mea, msg, wpm, lpm)
			ctl.onRightMouseDown(ctl, &mea)
		}
	}

	ctrl_right_mouseup_handler :: proc(ctl: ^Control, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl.onRightMouseUp != nil {
			mea : MouseEventArgs
			fill_mouse_event_args(&mea, msg, wpm, lpm)
			ctl.onRightMouseUp(ctl, &mea)
		}
		if ctl.onRightClick != nil {
			ea := new_event_args()
			ctl.onRightClick(ctl, &ea)
		}
	}

// End section

// Mouse wheel, enter, move, leave
	ctrl_mousewheel_handler :: proc(ctl: ^Control, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl.onMouseScroll != nil {
			mea : MouseEventArgs
			fill_mouse_event_args(&mea, msg, wpm, lpm)
			ctl.onMouseScroll(ctl, &mea)
		}
	}

	@private ctrl_mousemove_handler :: proc(ctl: ^Control, hw: HWND, msg: UINT,wpm: WPARAM, lpm: LPARAM)
	{
		if ctl._isMouseEntered {
			if ctl.onMouseMove != nil {
				mea : MouseEventArgs
				fill_mouse_event_args(&mea, msg, wpm, lpm)
				ctl.onMouseMove(ctl, &mea)
			}
		}
		if ctl._tmeFlags > 0 {
			if ctl._isMouseTracking {
				ctl._isMouseTracking = track_mouse_move(ctl.handle, ctl._tmeFlags)
				if SpecialMouseEvents.Mouse_Enter in ctl._mouseEvents && !ctl._isMouseEntered {
					ctl._isMouseEntered = true
					ea := new_event_args()
					ctl.onMouseEnter(ctl, &ea)
				}
			}			
		}		
	}

	@private ctrl_mouseleave_handler :: proc(ctl: ^Control)
	{
		ctl._isMouseEntered = false
		if ctl._isMouseTracking {
			ctl._isMouseTracking = false
			if ctl.onMouseLeave != nil {
				ea := new_event_args()
				ctl.onMouseLeave(ctl, &ea)
			}			
		}
	}

ctrl_setfocus_handler :: proc(ctl: ^Control)
{
	if ctl.onGotFocus != nil {
		ea := new_event_args()
		ctl.onGotFocus(ctl, &ea)
	}
}

ctrl_killfocus_handler :: proc(ctl: ^Control)
{
	if ctl.onLostFocus != nil {
		ea := new_event_args()
		ctl.onLostFocus(ctl, &ea)
	}
}

@private ctrl_set_font :: proc(this: ^Control, value: $T)
{
	when T == Font { this.font = value } else {print("Type error...")}
	if this.font.handle == nil do font_create_handle(&this.font)
	if this._isCreated do SendMessage(this.handle, WM_SETFONT, WPARAM(this.font.handle), LPARAM(1))
}

// End section

@private control_property_setter :: proc(this: ^Control, prop: CommonProps, value: $T)
{
	switch prop {
		case .Back_Color: set_back_color1(this, uint(value))
		case .Font: ctrl_set_font(this, value)
		case .Fore_Color: set_fore_color1(this, uint(value))
		case .Enabled: control_enable(this, bool(value))
		case .Height: control_set_size(this, this.width, i32(value))
		case .Text: control_set_text(this, tostring(value))
		case .Visible: control_visibile(this, bool(value))
		case .Width: control_set_size(this, i32(value), this.height)
		case .Xpos: control_set_position(this, i32(value), this.ypos)
		case .Ypos: control_set_position(this, this.xpos, i32(value))
	}
}



set_property :: proc(ctl: ^$T,  prop: $U, value: $V)
{
	prop_num : int = int(prop)
	switch prop_num {
		case 0..=int(max(CommonProps)):
			control_property_setter(ctl, auto_cast(prop), value)

		case int(min(CalendarProps))..=int(max(CalendarProps)):
			when T == Calendar do calendar_property_setter(ctl, prop, value)

		case int(min(CheckBoxProps))..=int(max(CheckBoxProps)):
				when T == CheckBox do checkbox_property_setter(ctl, prop, value)

		case int(min(ComboProps))..=int(max(ComboProps)):
				when T == ComboBox do combo_property_setter(ctl, prop, value)

		case int(min(DTPProps))..=int(max(DTPProps)):
				when T == DateTimePicker do dtp_property_setter(ctl, prop, value)

		case int(min(FormProps))..=int(max(FormProps)):
				when T == Form do form_property_setter(ctl, prop, value)

		case int(min(GroupBoxProps))..=int(max(GroupBoxProps)):
				when T == GroupBox do gbx_property_setter(ctl, prop, value)

		case int(min(LabelProps))..=int(max(LabelProps)):
				when T == Label do label_property_setter(ctl, LabelProps(prop), value)

		case int(min(ListBoxProps))..=int(max(ListBoxProps)):
				when T == ListBox do listbox_property_setter(ctl, prop, value)

		case int(min(ListViewProps))..=int(max(ListViewProps)):
				when T == ListView do listview_property_setter(ctl, prop, value)

		case int(min(NumberPickerProps))..=int(max(NumberPickerProps)):
				when T == ListView do numberpicker_property_setter(ctl, prop, value)

		case int(min(ProgressBarProps))..=int(max(ProgressBarProps)):
				when T == ListView do progressbar_property_setter(ctl, prop, value)

		case int(min(RadioButtonProps))..=int(max(RadioButtonProps)):
				when T == ListView do radiobutton_property_setter(ctl, prop, value)

		case int(min(TextBoxProps))..=int(max(TextBoxProps)):
				when T == ListView do textbox_property_setter(ctl, prop, value)

		case int(min(TrackBarProps))..=int(max(TrackBarProps)):
				when T == ListView do trackbar_property_setter(ctl, prop, value)

		case int(min(TreeViewProps))..=int(max(TreeViewProps)):
				when T == ListView do treeview_property_setter(ctl, prop, value)
	}
}


// User who wants to use mouse enter event must call this function to set the event handler.
ctrl_set_mouse_enter_handler :: proc(this: ^Control, evtProc: EventHandler,) 
{
	this._mouseEvents += {.Mouse_Enter}
	set_bit_flag(&this._tmeFlags, MouseTrackingFlags.TME_Leave)
	this.onMouseEnter = evtProc	
}

// User who wants to use mouse hover event must call this function to set the event handler.
ctrl_set_mouse_hover_handler :: proc(this: ^Control, evtProc: EventHandler,) 
{
	this._mouseEvents += {.Mouse_Hover}
	set_bit_flag(&this._tmeFlags, MouseTrackingFlags.TME_Hover)
	this.onMouseHover = evtProc	
	if this.kind == .Combo_Box {
		combo_set_hover_timer((^ComboBox)(this))
	} else if this.kind == .Number_Picker {
		nump_set_hover_timer((^NumberPicker)(this))
	}
}

// User who wants to use mouse leave event must call this function to set the event handler.
ctrl_set_mouse_leave_handler :: proc(this: ^Control, evtProc: EventHandler,) 
{
	this._mouseEvents += {.Mouse_Leave}
	set_bit_flag(&this._tmeFlags, MouseTrackingFlags.TME_Leave)
	this.onMouseLeave = evtProc		
}

