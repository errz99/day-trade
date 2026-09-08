
/*===========================================CheckBox Docs=========================================================
    CheckBox struct
        Constructor: new_checkBox() -> ^CheckBox
        Properties:
            All props from Control struct
            checked        : bool
            textAlignment  : enum {Left, Right}
            autoSize       : bool
        Functions:
        Events:
            EventHandler type -proc(^Control, ^EventArgs) [See events.odin]
                onCheckChanged
        
==============================================================================================================*/




package winforms

import "base:runtime"
import api "core:sys/windows"

@private _cbcount: int = 1

CheckBox:: struct
{
    using control: Control,
    checked: bool,
    textAlign: Alignment,
    autoSize: bool,
    _bkBrush: HBRUSH,
    _txtStyle: UINT,
    // Events
    onCheckChanged: EventHandler,
}

// Constructor for Checkbox type.
new_checkbox:: proc{new_checkbox1, new_checkbox2}


//===================================================Private functions=============================================
@private cb_ctor:: proc(p: ^Control, txt: string, x, y, w, h: i32) -> ^CheckBox
{
    this:= new(CheckBox)
    this.kind = .Check_Box
    control_base_init(this, p, x, y, w, h, &_cbcount, txt)
    this._txtStyle = DT_SINGLELINE | DT_VCENTER
    this.autoSize = true
    this._autoSizable = true
    this._SizeIncr.width = 20
    this._SizeIncr.height = 3
    this._createHandleProc = cb_create_handle
    return this
}

@private new_checkbox1:: proc(parent: ^Control, txt: string = "") -> ^CheckBox
{
    cbtxt:= len(txt) == 0 ? conc_num("CheckBox_", _cbcount ): txt
    this := cb_ctor(parent, cbtxt, 10, 10, 0, 0 )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_checkbox2:: proc(parent: ^Control, txt: string, x, y: i32) -> ^CheckBox
{
    this:= cb_ctor(parent, txt, x, y, 0, 0)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_checkbox3:: proc(parent: ^Control, txt: string, x, y, w, h: i32) -> ^CheckBox
{
    this:= cb_ctor(parent, txt, x, y, w, h)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private cb_create_handle :: proc(ctl: ^Control)
{
	this := cast(^CheckBox)ctl
	adjust_style(this)	
	create_control(ctl, this.width, this.height)
	set_subclass(this, cb_wnd_proc)	
    if this.autoSize do calculate_ctl_size(ctl)
}

@private adjust_style:: proc(cb: ^CheckBox)
{
    if cb.textAlign == .Right {
        cb._style |= BS_RIGHTBUTTON
       cb._txtStyle |= DT_RIGHT
    }
}

@private checkbox_property_setter:: proc(this: ^CheckBox, prop: CheckBoxProps, value: $T)
{
	switch prop {
		case .Checked:
            when T == bool {
                this.checked = value
                if this._isCreated do SendMessage(this.handle, BM_SETCHECK, auto_cast(value), 0)
            }
		case .Text_Alignment: break

		case .Auto_Size:
            when T == bool {
                this.autoSize = value
                if this._isCreated do InvalidateRect(this.handle, nil, false)
            }
	}
}

@private cb_finalize:: proc(this: ^CheckBox)
{
    delete_gdi_object(this._bkBrush)
    control_base_dtor(this)
    free(this)
}

@private cb_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                                        sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context
    // context = runtime.default_context()
    this := control_cast(CheckBox, ref_data)
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

        case CM_CTLCOMMAND:
            this.checked = cast(bool) SendMessage(hw, BM_GETCHECK, 0, 0)
            if this.onCheckChanged != nil {
                ea:= new_event_args()
                this.onCheckChanged(this, &ea)
            }

        case CM_STATIC_COLOR:
            hd:= dir_cast(wp, HDC)
            bkref:= get_color_ref(this.backColor)
            api.SetBkMode(hd, api.BKMODE.TRANSPARENT)
            if this._bkBrush == nil do this._bkBrush = CreateSolidBrush(bkref)
            return toLRES(this._bkBrush)

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
                    DrawText(nmcd.hdc, to_wstring(this.text), -1, &rct, this._txtStyle)
                    // // free_all(context.temp_allocator)
                    return CDRF_SKIPDEFAULT
            }

        case WM_NCDESTROY: 
            RemoveWindowSubclass(this.handle, cb_wnd_proc, sc_id)
            cb_finalize(this)

        case: return DefSubclassProc(hw, msg, wp, lp)
    }
    return DefSubclassProc(hw, msg, wp, lp)
}