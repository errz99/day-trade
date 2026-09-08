
/*===========================================TextBox Docs=========================================================
    TextBox struct
        Constructor: new_textbox() -> ^TextBox
        Properties:
            All props from Control struct
            textAlignment  : TbTextAlign - An enum in this file
            multiLine      : bool
            textType       : TextType - An enum in this file
            textCase       : TextCase - An enum in this file
            hideSelection  : bool
            readOnly       : bool
            cueBanner      : string
            focusRectColor : uint
        Functions:
			textbox_set_selection
            textbox_set_readonly
            textbox_clear_all

        Events:
			All events from Control struct
            onTextChanged - EventHandler type [proc(^Control, ^EventARgs)]
==============================================================================================================*/


package winforms
import "base:runtime"
import "core:fmt"
import api "core:sys/windows"

_tbCount : int = 1


TextBox:: struct
{
    using control: Control,
    textAlignment: TbTextAlign,
    multiLine: bool,
    textType: TextType,
    textCase: TextCase,
    hideSelection: bool,
    readOnly: bool,
    cueBanner: string,
    focusRectColor: uint,

    onTextChanged: EventHandler,
    _bkBrush: HBRUSH,
    _drawFocusRect: bool,
    _frcRef: COLORREF,
}

// TextBox control constructor.
new_textbox:: proc{new_tb1, new_tb2, new_tb3, new_tb4, new_tb5}

// Select or de-select all the text in TextBox control.
textbox_set_selection:: proc(tb: ^TextBox, value: bool)
{
    wpm, lpm: i32
    if value {
        wpm = 0
        lpm = -1
    } else {
        wpm = -1
        lpm = 0
    }
    SendMessage(tb.handle, EM_SETSEL, WPARAM(wpm), LPARAM(lpm))
}

// Set a TextBox's read only state.
textbox_set_readonly:: proc(tb: ^TextBox, bstate: bool)
{
    SendMessage(tb.handle, EM_SETREADONLY, WPARAM(bstate), 0)
    tb.readOnly = bstate
}

textbox_clear_all:: proc(tb: ^TextBox)
{
    if tb._isCreated {
        SetWindowText(tb.handle, EWCAPTR)
        // free_all(context.temp_allocator)
    }
}

//==========================================Private Functions==================================
@private tb_ctor:: proc(p: ^Control, x, y, w, h: i32, txt: string = "") -> ^TextBox
{
    this:= new(TextBox)
    this.kind = .Text_Box
    control_base_init(this, p, x, y, w, h, &_tbCount, txt)
    this._createHandleProc = tb_create_handle
    this.hideSelection = true
    this.focusRectColor = 0x007FFF
    this._frcRef = get_color_ref(this.focusRectColor)
    return this
}

@private new_tb1:: proc(parent: ^Control) -> ^TextBox
{
    this := tb_ctor(parent, 10, 10, 180, 27)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tb2:: proc(parent: ^Control, x, y: i32) -> ^TextBox
{
    this := tb_ctor(parent, x, y, 180, 27)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tb3:: proc(parent: ^Control, x, y, w, h: i32) -> ^TextBox
{
    this := tb_ctor(parent, x, y, w, h)
    // ptf("tb wid: %d", w)
    // if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tb4:: proc(parent: ^Control, txt: string, x, y: i32) -> ^TextBox
{
    this := tb_ctor(parent, x, y, 180, 27, txt)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tb5:: proc(parent: ^Control, txt: string, x, y, w, h: i32) -> ^TextBox
{
    this := tb_ctor(parent, x, y, w, h, txt)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private tb_create_handle :: proc(ctl: ^Control)
{
	this := cast(^TextBox)ctl
	adjust_styles(this)	
	create_control(ctl, this.width, this.height)
	set_subclass(this, tb_wnd_proc)
    if len(this.cueBanner) > 0 {
        up:= cast(UINT_PTR) to_wstring(this.cueBanner)
        SendMessage(this.handle, EM_SETCUEBANNER, 1, LPARAM(up) )
    }
    api.EnableWindow(this.handle, true)	
}

@private adjust_styles:: proc(this: ^TextBox)
{
    if this.multiLine do this._style |= ES_MULTILINE | ES_WANTRETURN
    if !this.hideSelection do this._style |= ES_NOHIDESEL
    if this.readOnly do this._style |= ES_READONLY

    if this.textCase == .Lower_Case { this._style |= ES_LOWERCASE }
    else if this.textCase == .Upper_Case { this._style |= ES_UPPERCASE }

    if this.textType == .Number_Only { this._style |= ES_NUMBER }
    else if this.textType == .Password_Char { this._style |= ES_PASSWORD }

    if this.textAlignment == .Center { this._style |= ES_CENTER }
    else if this.textAlignment == .Right { this._style |= ES_RIGHT }
    this._bkBrush = get_solid_brush(this.backColor)
}

@private set_tb_bk_clr:: proc(this: ^TextBox, clr: uint)
{
    this.backColor = clr
    if this._isCreated do InvalidateRect(this.handle, nil, false)
}

@private textbox_property_setter:: proc(this: ^TextBox, prop: TextBoxProps, value: $T)
{
	switch prop {
        case .Text_Alignment: break
        case .Multi_Line: break
        case .Text_Type: break
        case .Text_Case: break
        case .Hide_Selection: break
        case .Read_Only: break
        case .Cue_Banner:
            when T == string {
                this.cueBanner = value
                if this._isCreated {
                    SendMessage(this.handle, EM_SETCUEBANNER, 1, dir_cast(to_wstring(value), LPARAM))
                    // free_all(context.temp_allocator)
                }
            }
	}
}

@private tb_finalize:: proc(this: ^TextBox)
{
    delete_gdi_object(this._bkBrush)
    control_base_dtor(this)
    free(this)
}

@private tb_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM, sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT {

    context = global_context //
    // display_msg(msg)
    this := control_cast(TextBox, ref_data)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
    switch msg {
    case WM_PAINT:
        if this.onPaint != nil {
            ps: PAINTSTRUCT
            hdc:= BeginPaint(hw, &ps)
            pea:= new_paint_event_args(&ps)
            this.onPaint(this, &pea)
            EndPaint(hw, &ps)
            return 0
        }

    case CM_EDIT_COLOR:
        // print("ctl clr rcvd")
        if this.foreColor != def_fore_clr || this.backColor != def_back_clr {
            dc_handle:= dir_cast(wp, HDC)
            // SetBkMode(dc_handle, Transparent)
            if this.foreColor != def_fore_clr do SetTextColor(dc_handle, get_color_ref(this.foreColor))
            SetBkColor(dc_handle, get_color_ref(this.backColor))
            // this._bkBrush = CreateSolidBrush(get_color_ref(this.backColor))

        } //else do return 0

        return toLRES(this._bkBrush)

    case WM_SETFOCUS:
        if this.onGotFocus != nil {
            ea:= new_event_args()
            this.onGotFocus(this, &ea)
        }

    case WM_KILLFOCUS:
    //    this._drawFocusRect = false
        if this.onLostFocus != nil {
            ea:= new_event_args()
            this.onLostFocus(this, &ea)
        }

    case WM_KEYDOWN:
        // this._drawFocusRect = true
        if this.onKeyDown != nil {
            kea:= new_key_event_args(wp)
            this.onKeyDown(this, &kea)
            return 0
        }

    case WM_KEYUP:
        if this.onKeyUp != nil {
            kea:= new_key_event_args(wp)
            this.onKeyUp(this, &kea)
            return 0
        }

    case WM_CHAR:
        if this.onKeyPress != nil {
            kea:= new_key_event_args(wp)
            this.onKeyPress(this, &kea)
        }
        SendMessage(this.handle, CM_TBTXTCHANGED, 0, 0)

    case CM_TBTXTCHANGED:
        if this.onTextChanged != nil {
            ea:= new_event_args()
            this.onTextChanged(this, &ea)
        }

    case WM_NCDESTROY: 
        RemoveWindowSubclass(this.handle, tb_wnd_proc, sc_id)
        tb_finalize(this)

    // case: return DefSubclassProc(hw, msg, wp, lp)
    }
    return DefSubclassProc(hw, msg, wp, lp)
}
