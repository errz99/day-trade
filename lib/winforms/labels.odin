
/*===========================Label Docs==============================
    Label struct
        Constructor: new_label() -> ^Label
        Properties:
            All props from Control struct
            autoSize       : bool
            borderStyle    : LabelBorder
            textAlignment  : TextAlignment
            multiLine      : bool
        Functions:
        Events:
            All events from Control struct
        
===============================================================================*/

package winforms
import "base:runtime"
//import "core:time"


// this is for labels
@private _lb_count:= 0
@private _lb_height_incr:: 3
@private _lb_width_incr:: 2
@private _padding :: 4


Label:: struct {
    using control: Control,
    autoSize: bool,
    borderStyle: LabelBorder,
    textAlignment: TextAlignment,
    multiLine: bool, 
    _hbrush: HBRUSH,
    _txtAlign: DWORD,
}

// Label control's constructor
new_label:: proc{new_label1, new_label2, new_label3}





//==================================Private Functions==================================
@private label_ctor:: proc(p: ^Control, txt: string, x, y: i32, w: i32 = 0, h: i32 = 0) -> ^Label 
{
    _lb_count += 1
    this:= new(Label)
    this.kind = .Label
    control_base_init(this, p, x, y, w, h, &_lb_count, txt)
    this._createHandleProc = lbl_create_handle
    this.autoSize = true
    this._autoSizable = true
    this._SizeIncr.width = 2
    this._SizeIncr.height = 3
    this.autoSize = (w != 0 || h != 0) ? false: true
    this._inherit_color = true
    return this
}

@private new_label1:: proc(parent: ^Control) -> ^Label 
{
    txt:= conc_num("Label_", _lb_count)
    this := label_ctor(parent, txt, 10, 10)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_label2:: proc(parent: ^Control, txt: string, x, y: i32) -> ^Label 
{
    this := label_ctor(parent, txt, x, y)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_label3:: proc(parent: ^Control, txt: string, x, y, w, h: i32) -> ^Label 
{
    this := label_ctor(parent, txt, x, y, w, h)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private lbl_create_handle :: proc(ctl: ^Control)
{
	this := cast(^Label)ctl
	if this.borderStyle != .No_Border do adjust_border(this)
    this._hbrush = CreateSolidBrush(get_color_ref(this.backColor))
    check_for_autosize(this)	
	create_control(ctl, this.width, this.height)
	set_subclass(this, label_wnd_proc)
    if this.autoSize do calculate_label_size(this)	
}

@private check_for_autosize:: proc(lb: ^Label) 
{
    if lb.multiLine do lb.autoSize = false
    if lb.width != 0 do lb.autoSize = false // User might change width explicitly
    if lb.height != 0 do lb.autoSize = false // User might change width explicitly
    // if lb.width == 0 || lb.height == 0 {
    //     // User did not made any changes yet.
    // }
}

@private adjust_border:: proc(lb: ^Label) 
{
    if lb.borderStyle == .Sunken_Border {
        lb._style |= SS_SUNKEN
    } else if lb.borderStyle == .Single_Line {
        lb._style |= WS_BORDER
    }
}

@private adjust_alignment:: proc(lb: ^Label) 
{
    switch lb.textAlignment {
        case .Top_Left: lb._txtAlign = DT_TOP | DT_LEFT
        case .Top_Center: lb._txtAlign = DT_TOP | DT_CENTER
        case .Top_Right: lb._txtAlign = DT_TOP | DT_RIGHT

        case .Mid_Left: lb._txtAlign = DT_VCENTER | DT_LEFT
        case .Center: lb._txtAlign = DT_VCENTER | DT_CENTER
        case .Mid_Right: lb._txtAlign = DT_VCENTER | DT_RIGHT

        case .Bottom_Left: lb._txtAlign = DT_BOTTOM | DT_LEFT
        case .Bottom_Center: lb._txtAlign = DT_BOTTOM | DT_CENTER
        case .Bottom_Right: lb._txtAlign = DT_BOTTOM | DT_RIGHT
    }

    if lb.multiLine {
        lb._txtAlign |= DT_WORDBREAK
    } else {
       lb._txtAlign |= DT_SINGLELINE
    }
}

@private set_lbl_bk_clr:: proc(lb:^Label, clr: uint) 
{
    lb.backColor = clr
    if lb._isCreated {
        lb._hbrush = nil
        InvalidateRect(lb.handle, nil, false)
    }
}

@private calculate_label_size:: proc(this: ^Label) 
{
    // Labels are creating with zero width & height.
    // We need to find appropriate size if it is an auto sized label.
    hdc:= GetDC(this.handle)
    defer ReleaseDC(this.handle, hdc)
    ss: SIZE
    select_gdi_object(hdc, this.font.handle)
    GetTextExtentPoint32(hdc, this._wtext.ptr, this._wtext.strLen, &ss )    
    this.width = ss.cx + _padding
    this.height = ss.cy + _padding
    lflag :UINT =  SWP_NOZORDER | SWP_NOACTIVATE // SWP_NOMOVE |
    control_setpos2(this.handle, this.xpos, this.ypos, this.width, this.height, SWP_NOMOVE)
    check_redraw(this, false)
}

// @private lbl_before_creation:: proc(this: ^Label) 
// {
//     if this.borderStyle != .No_Border do adjust_border(this)
//     this._hbrush = CreateSolidBrush(get_color_ref(this.backColor))
//     check_for_autosize(this)
//     //adjust_alignment(this)
// }

// @private lbl_after_creation:: proc(this: ^Label) 
// {    
//     set_subclass(this, label_wnd_proc)
//     ctl_send_msg(this.handle, WM_SETFONT, this.font.handle, 1)
//     if this.autoSize do calculate_label_size(this)
//     // ptf("this hwnd %d, %d, %d, %d", this.handle, this.width, this.height, this.autoSize)
// }

@private label_property_setter:: proc(this: ^Label, prop: LabelProps, value: $T)
{
	switch prop {
		case .Auto_Size: break
		case .Border_Style: break
		case .Text_Alignment: break
		case .Multi_Line: break
    }
}

@private lbl_finalize:: proc(this: ^Label)
{
    delete_gdi_object(this._hbrush)    
    control_base_dtor(this)        
    free(this)
}

@private label_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                                    sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context
    this := control_cast(Label, ref_data)
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

        case CM_STATIC_COLOR:
            hdc:= dir_cast(wp, HDC)
            if (this._drawFlag & 1) != 1 do SetTextColor(hdc, get_color_ref(this.foreColor))
            SetBkColor(hdc, get_color_ref(this.backColor))
            return toLRES(this._hbrush)

        case WM_NCDESTROY: 
            RemoveWindowSubclass(this.handle, label_wnd_proc, sc_id)
            lbl_finalize(this)

        case: return DefSubclassProc(hw, msg, wp, lp)

    }
    return DefSubclassProc(hw, msg, wp, lp)
}


