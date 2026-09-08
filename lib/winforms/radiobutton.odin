/*
    Created on: 01-Feb-2022 08:38 AM
    Name: RadioButton type.
*/

/*===========================================RadioButton Docs=========================================================
    RadioButton struct
        Constructor: new_radiobutton() -> ^RadioButton
        Properties:
            All props from Control struct
            textAlign  : enum {left, right}
            checked        : bool
            checkOnClick   : bool
            autoSize       : bool
        Functions:
			radiobutton_set_state
            radiobutton_set_autocheck

        Events:
			All events from Control struct
        
==============================================================================================================*/


package winforms
import "base:runtime"
import api "core:sys/windows"


rb_count: int

RadioButton:: struct
{
    using control: Control,
    textAlign: Alignment,
    checked: bool,
    checkOnClick: bool,
    autoSize: bool,
    _hbrush: HBRUSH,
    _txtStyle: UINT,
    onStateChanged: EventHandler,
}

new_radiobutton:: proc{new_rb1, new_rb2, new_rb3, new_rb4}

radiobutton_set_state:: proc(rb: ^RadioButton, bstate: bool)
{
    state:= 0x0001 if bstate else 0x0000
    SendMessage(rb.handle, BM_SETCHECK, WPARAM(state), 0)
}

// Change Radio Button's behaviour. Normally radio button will change it's checked state when it clicked.
// But you can change that behaviour by passing a false to this function.
radiobutton_set_autocheck:: proc(rb: ^RadioButton, auto_check: bool )
{
    ready_to_change: bool
    if auto_check {
         if !rb.checkOnClick {
            rb._style =  WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON
            rb.checkOnClick = true
            ready_to_change = true
        }
    } else {
       if rb.checkOnClick {
            rb._style = WS_VISIBLE | WS_CHILD  | BS_RADIOBUTTON
            rb.checkOnClick = false
            ready_to_change = true
        }
    }
    if ready_to_change {
        SetWindowLongPtr(rb.handle, GWL_STYLE, LONG_PTR(rb._style))
        InvalidateRect(rb.handle, nil, true)
    }
}

//===========================================Private Functions======================================
@private rb_ctor:: proc(f: ^Control, txt: string, x, y, w, h: i32) -> ^RadioButton
{
    this:= new(RadioButton)
    this.kind = .Radio_Button
    control_base_init(this, f, x, y, w, h, &rb_count, txt)
    this._createHandleProc = rb_create_handle
    this.checkOnClick = true
    this.autoSize = true
    this._autoSizable = true
    this._txtStyle = DT_SINGLELINE | DT_VCENTER
    this._SizeIncr.width = 20
    this._SizeIncr.height = 3
    this._inherit_color = true
    return this
}

@private new_rb1:: proc(parent: ^Control) -> ^RadioButton
{
    rb_count += 1
    rtxt:= conc_num("Radio_Button_", rb_count)
    this := rb_ctor(parent, rtxt, 10, 10, 100, 25 )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_rb2:: proc(parent: ^Control, txt: string) -> ^RadioButton
{
    this := rb_ctor(parent, txt, 10, 10, 100, 25 )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_rb3:: proc(parent: ^Control, txt: string, x, y: i32) -> ^RadioButton
{
    this := rb_ctor(parent, txt, x, y, 100, 25 )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_rb4:: proc(parent: ^Control, txt: string, x, y, w, h: i32) -> ^RadioButton
{
    this := rb_ctor(parent, txt, x, y, w, h )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private rb_create_handle :: proc(ctl: ^Control)
{
	this := cast(^RadioButton)ctl
	rb_adjust_styles(this)	
	create_control(ctl, this.width, this.height)
	set_subclass(this, rb_wnd_proc)
    if this.autoSize do calculate_ctl_size(this)
    if this.checked {
        SendMessage(this.handle, BM_SETCHECK, WPARAM(0x0001), 0)
    }	
}

@private rb_adjust_styles:: proc(rb: ^RadioButton)
{
    if !rb.checkOnClick do rb._style ~= BS_AUTORADIOBUTTON
    //if rb.textAlign = .right do rb.
}

// @private rb_before_creation:: proc(rb: ^RadioButton)
// {
//     rb_adjust_styles(rb)
// }

// @private rb_after_creation:: proc(rb: ^RadioButton)
// {
//     set_subclass(rb, rb_wnd_proc)
//     if rb.autoSize do calculate_ctl_size(rb)
//     if rb.checked {
//         SendMessage(rb.handle, BM_SETCHECK, WPARAM(0x0001), 0)
//     }
// }

@private radiobutton_property_setter:: proc(this: ^RadioButton, prop: RadioButtonProps, value: $T)
{
	switch prop {
        case. Text_Alignment: break
        case .Checked: when T == bool do radiobutton_set_state(this, value)
        case .Check_On_Click: break
        case .Auto_Size: break
	}
}

@private rb_finalize:: proc(this: ^RadioButton)
{
    delete_gdi_object(this._hbrush)
    control_base_dtor(this)
    free(this, context.allocator)    
}

@private rb_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                        sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context  
    // context = runtime.default_context()  
    //display_msg(msg)
    this := control_cast(RadioButton, ref_data)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
    switch msg {
    case WM_NCDESTROY: 
        RemoveWindowSubclass(this.handle, rb_wnd_proc, sc_id)
        rb_finalize(this)

    case CM_CTLCOMMAND:
        if HIWORD(wp) == 0 {
            this.checked = bool(SendMessage(this.handle, BM_GETCHECK, 0, 0))
            if this.onStateChanged != nil {
                ea:= new_event_args()
                this.onStateChanged(this, &ea)
            }
        }

    case CM_STATIC_COLOR:
        // print("199")
        hdc:= dir_cast(wp, HDC)
        api.SetBkMode(hdc, api.BKMODE.TRANSPARENT)
        SetBkColor(hdc, get_color_ref(this.backColor))
        this._hbrush = CreateSolidBrush(get_color_ref(this.backColor))
        // print("rb bkc ", this.backColor)
        // return toLRES(this._hbrush)
        return toLRES(this._hbrush)

    case CM_NOTIFY:
        nmcd:= dir_cast(lp, ^NMCUSTOMDRAW)
        switch nmcd.dwDrawStage {
        case CDDS_PREPAINT:
            cref:= get_color_ref(this.foreColor)
            rct: RECT = nmcd.rc
            if this.textAlign == .Left{
                rct.left += 18
            } else do rct.right -= 18
            SetTextColor(nmcd.hdc, cref)
            // SetBackColor(nmcd.hdc, get_color_ref(this.backColor))
            DrawText(nmcd.hdc, this._wtext.ptr, -1, &rct, this._txtStyle)
            // free_all(context.temp_allocator)
            return CDRF_SKIPDEFAULT
        }

    }
    return DefSubclassProc(hw, msg, wp, lp)
}
