
/*===========================GroupBox Docs==============================
    GroupBox struct
        Constructor: new_groupbox() -> ^GroupBox
        Properties:
            All props from Control struct
            lineColor : uint
            style : GroupBoxStyle enum
        Functions:
            gbx
            gby
        Events:
            All events from Control struct
        
===============================================================================*/
//TODO - Use double buffering bkg fill when user changes the size of groubox.

package winforms

// import "core:fmt"
import "base:runtime"
import api "core:sys/windows"

PENWIDTH :i32: 1
HTTRANSPARENT :: -1
HTCLIENT :: 1
GB_MEASURE_TXT      :: u8(1 << 0) // 1
GB_FETCH_BORDER     :: u8(1 << 1) // 2
GB_RECREATE_BMP     :: u8(1 << 2) // 4
GB_FILL_BKG         :: u8(1 << 3) // 8
GB_DRAW_BORDER      :: u8(1 << 4) // 16
GB_DRAW_TEXT        :: u8(1 << 5) // 32
// GB_CREATE_MDC       :: u8(1 << 6) // 64
GB_DIRTY_ALL        :: GB_MEASURE_TXT | GB_FETCH_BORDER | GB_RECREATE_BMP |
                       GB_FILL_BKG | GB_DRAW_BORDER | GB_DRAW_TEXT 
GB_BKG_CHANGE_FLAG  :: GB_FILL_BKG | GB_DRAW_BORDER | GB_DRAW_TEXT
GB_SIZE_CHANGE_FLAG :: GB_DIRTY_ALL & ~GB_MEASURE_TXT
GB_TXT_CHANGE_FLAG  :: GB_MEASURE_TXT | GB_FETCH_BORDER | GB_DRAW_BORDER | GB_DRAW_TEXT


GroupBox :: struct
{
    using control : Control,
    lineColor: uint,
    style: GroupBoxStyle,
    _bkBrush : HBRUSH,
    _hbmp: HBITMAP,
    _pen : HPEN,
    _memDC : HDC,
    // _rct : RECT,
    _txtWidth : i32,
    _bcRef: COLORREF,
    _fcRef: COLORREF,
    _textSize: SIZE,
    _themeOff: bool,
    _createMDC: bool,
    _dirtyFlag: u8,
    _borderPts: [6]POINT,
    _controls : [dynamic]^Control,
    
}

// Groupbox control's constructor
new_groupbox :: proc{gb_ctor1, gb_ctor2}

gbx :: #force_inline proc(this: ^GroupBox, offset: i32) -> i32
{
    return this.xpos + offset
}

gby :: #force_inline proc(this: ^GroupBox, offset: i32) -> i32
{
    return this.ypos + offset
}

//==============================Private Functions==================================
@private gb_count : int = 1

@private gb_ctor :: proc(p : ^Control, txt : string, x, y, w, h : i32, gStyle: GroupBoxStyle) -> ^GroupBox
{
    // if WcGroupBoxW == nil do WcGroupBoxW = to_wstring()
    this := new(GroupBox) 
    this.kind = .Group_Box   
    control_base_init(this, p, x, y, w, h, &gb_count, txt)
    this._createHandleProc = gb_create_handle
    this.lineColor = 0xACACAC

    return this
}

@private gb_ctor1 :: proc(parent : ^Control) -> ^GroupBox
{
    gb_txt : string = conc_num("GroupBox_", gb_count)
    this := gb_ctor(parent, gb_txt, 10, 10, 250, 250, .System)
    gb_count += 1
    // if this._ownerForm.createChilds do create_control(this)
    return this
}

@private gb_ctor2 :: proc(parent : ^Control,
                            txt : string,
                            x, y : i32, w: i32 = 200, h: i32 = 200, 
                            style: GroupBoxStyle = .System) -> ^GroupBox
{
    this := gb_ctor(parent, txt, x, y, w, h, style)
    gb_count += 1
    // if this._ownerForm.createChilds do create_control(this)
    return this
}

@private gb_create_handle :: proc(ctl: ^Control)
{
	this := cast(^GroupBox)ctl
	this._bkBrush = get_solid_brush(this.backColor)
    this._bcRef = get_color_ref(this.backColor)
    this._fcRef = get_color_ref(this.foreColor)
    if this.foreColor != def_fgc.value {
        if this.style != .Classic do this.style = .Overriden
    }
    if this.style == .Overriden {
        this._createMDC = true
        this._dirtyFlag = GB_DIRTY_ALL
        this._pen = CreatePen(PS_SOLID, PENWIDTH, get_color_ref(this.lineColor))
    }
	create_control(ctl, this.width, this.height)
	if this.style == .Classic {
        SetWindowTheme(this.handle, EWCAPTR, EWCAPTR)
        this._themeOff = true
    }
	set_subclass(this, gb_wnd_proc)	
    if this._ownerForm._enablePrintPoint do this.onMouseUp = print_point_func
}


gbx_add_controls :: proc(this: ^GroupBox, items: ..^Control) {
    if this._isCreated {
        for item in items {
           append(&this._controls, item)
           if item.kind == .Label do item.backColor = this.backColor
        }
    }
}

gbx_set_backcolor :: proc(this: ^GroupBox, clr: uint)
{
    this.backColor = clr
    if this._bkBrush != nil do delete_gdi_object(this._bkBrush)
    this._bkBrush = get_solid_brush(this.backColor)   
    this._bcRef = get_color_ref(this.backColor)
    gb_set_draw_flags(this, GB_BKG_CHANGE_FLAG)
}

gbx_set_forecolor :: proc(this: ^GroupBox)
{
    this._fcRef = get_color_ref(this.foreColor)
    gb_set_draw_flags(this, GB_DRAW_TEXT)
}

gbx_set_linecolor :: proc (this: ^GroupBox, clr: uint)
{    
    this.lineColor = clr
    if this._pen != nil do delete_gdi_object(this._pen)
    this._pen = CreatePen(PS_SOLID, PENWIDTH, get_color_ref(this.lineColor))
    if this.style != .Overriden {
        this.style = .Overriden
        this._dirtyFlag = GB_DIRTY_ALL
        if this._memDC == nil do this._createMDC = true        
    } else {
        gb_set_draw_flags(this, GB_DRAW_BORDER)
    }    
}

gbx_set_height :: proc(this: ^GroupBox, value: i32)
{
    this.height = value
    gb_set_draw_flags(this, GB_SIZE_CHANGE_FLAG)
}

gbx_set_width :: proc(this: ^GroupBox, value: i32)
{
    this.width = value
    gb_set_draw_flags(this, GB_SIZE_CHANGE_FLAG)
}

gbx_set_text :: proc(this: ^GroupBox, value: string)
{
    this.text = value
    widestring_update(&this._wtext, value)
    if this._isCreated do SetWindowText(this.handle, this._wtext.ptr)
    gb_set_draw_flags(this, GB_TXT_CHANGE_FLAG)
}

gbx_set_font :: proc(this: ^GroupBox, fname: string, fsize: int, fweight: FontWeight = .Normal)
{
    font_change_font(&this.font, fname, fsize, fweight)
    // this._getWidth = true
    ctl_send_msg(this.handle, WM_SETFONT, this.font.handle, 1)
    gb_set_draw_flags(this, GB_TXT_CHANGE_FLAG)
}

gbx_set_font1 :: proc(this: ^GroupBox, value: ^Font) {
    font_clone(&this.font, value)
    // this._getWidth = true
    ctl_send_msg(this.handle, WM_SETFONT, this.font.handle, 1)
    gb_set_draw_flags(this, GB_TXT_CHANGE_FLAG)
}

gbx_set_style :: proc(this: ^GroupBox, value: GroupBoxStyle) {
    this.style = value
    if value == .Classic {
        if !this._themeOff {
            SetWindowTheme(this.handle, EWCAPTR, EWCAPTR)
            this._themeOff = true
        }
    } else if value == .Overriden {
        // this._getWidth = true
        this._dirtyFlag = GB_DIRTY_ALL
        if this._memDC != nil do this._createMDC = true
        if this._pen == nil {
            this._pen = CreatePen(PS_SOLID, PENWIDTH, get_color_ref(this.lineColor))
        }
    }
    check_redraw(this)
}

@private gb_set_draw_flags :: #force_inline proc(this: ^GroupBox, flag: u8)
{
    if this.style == .Overriden {
        this._dirtyFlag |= flag
    } else {
        this.style = .Overriden
        this._dirtyFlag = GB_DIRTY_ALL
    }
    if this._isCreated do InvalidateRect(this.handle, nil, false)
}


@private gbx_property_setter:: proc(this: ^GroupBox, prop: GroupBoxProps, value: $T)
{
	switch prop {
		case .Back_Color:
            when T == uint do gbx_set_backcolor(this, value)
        case .Font:
            when T == Font do gbx_set_font1(this, value)
		case .Height:
            when T == int do gbx_set_height(this, value)            
		case .Text:
            when T == string do gbx_set_text(this, value)
		case .Width:
            when T == int do gbx_set_width(this, value)
	}
}

@private gb_fetch_border_pts :: proc(this: ^GroupBox) 
{
    startX := this._myRect.left + 10
    startY := this._textSize.cy / 2
    this._borderPts[0] = {startX + this._textSize.cx, startY}
    this._borderPts[1] = {this._myRect.right - 1, startY}
    this._borderPts[2] = {this._myRect.right - 1, this._myRect.bottom - 1}
    this._borderPts[3] = {this._myRect.left, this._myRect.bottom - 1}
    this._borderPts[4] = {this._myRect.left, startY}
    this._borderPts[5] = {startX - 1, startY}
}

@private _draw_text_memDC :: proc(this: ^Control, x, y : i32, fcref: COLORREF, memDC: HDC)
{
    api.SetBkMode(memDC, api.BKMODE.TRANSPARENT)
    select_gdi_object(memDC, this.font.handle)
    api.SetTextColor(memDC, fcref)
    TextOut(memDC, x, y, this._wtext.ptr, this._wtext.strLen)
}

@private gb_finalize :: proc(this: ^GroupBox)
{
    delete_gdi_object(this._bkBrush)
    delete_gdi_object(this._pen)
    delete_gdi_object(this._hbmp)
    DeleteDC(this._memDC)
    control_base_dtor(this) 
    delete(this._controls)  
    free(this)
}

@private gb_wnd_proc :: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                    sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    // context = runtime.default_context()
    context = global_context
    this := control_cast(GroupBox, ref_data)
     res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
    //display_msg(msg)
    
    switch msg {
    case WM_NCDESTROY : 
        RemoveWindowSubclass(hw, gb_wnd_proc, sc_id)
        gb_finalize(this)

    case WM_NCHITTEST:
        hit := DefSubclassProc(hw, msg, wp, lp)
        if hit == HTTRANSPARENT do return HTCLIENT
        return hit

    case WM_PAINT :            
        if this.style == .Overriden {
            gfx := paint_gfx(hw)
            defer gfx_destroy(&gfx) 

            if this._createMDC {
                this._memDC = CreateCompatibleDC(gfx.hdc)
                this._createMDC = false
            }

            if this._dirtyFlag & GB_MEASURE_TXT != 0 {
                gfx_text_size(&gfx, this, &this._textSize)
                this._dirtyFlag &= ~GB_MEASURE_TXT
            }
            if this._dirtyFlag & GB_FETCH_BORDER != 0 {
                gb_fetch_border_pts(this)                
                this._dirtyFlag &= ~GB_FETCH_BORDER
            }
            
            if this._dirtyFlag & GB_RECREATE_BMP != 0 {                              
                gfx_set_hdc_and_bmp(&gfx, &this._memDC, &this._hbmp, this.width, this.height)
                this._dirtyFlag &= ~GB_RECREATE_BMP
            }
            
            if this._dirtyFlag & GB_FILL_BKG != 0 {
                api.FillRect(this._memDC, &this._myRect, this._bkBrush)
                this._dirtyFlag &= ~GB_FILL_BKG
            } 
            if this._dirtyFlag & GB_DRAW_BORDER != 0 {
                select_gdi_object(this._memDC, this._pen)
                Polyline(this._memDC, &this._borderPts[0], 6)
                this._dirtyFlag &= ~GB_DRAW_BORDER
            }
            if this._dirtyFlag & GB_DRAW_TEXT != 0 {
                SetTextColor(this._memDC, this._fcRef)
                _draw_text_memDC(this, 10, 0, this._fcRef, this._memDC)
                this._dirtyFlag &= ~GB_DRAW_TEXT
            }
                
            BitBlt(gfx.hdc, 0, 0, this.width, this.height, this._memDC, 0, 0, SRCCOPY) 
            return 1            
        }

    case CM_STATIC_COLOR:
        if this.style == .Classic {
            hdc := dir_cast(wp, HDC)
            api.SetBkMode(hdc, api.BKMODE.TRANSPARENT)                
            SetTextColor(hdc, get_color_ref(this.foreColor))
        }
        return dir_cast(this._bkBrush, LRESULT)

    case WM_GETTEXTLENGTH:
        if this.style == .Overriden do return 0

    case WM_NOTIFY :
        nm := dir_cast(lp, ^NMHDR)
        return SendMessage(nm.hwndFrom, CM_NOTIFY, wp, lp )
    
    case WM_CTLCOLOREDIT :
        ctl_hwnd := dir_cast(lp, HWND)
        return SendMessage(ctl_hwnd, CM_EDIT_COLOR, wp, lp)

    case WM_CTLCOLORSTATIC :
        ctl_hwnd := dir_cast(lp, HWND)
        return SendMessage(ctl_hwnd, CM_STATIC_COLOR, wp, lp)

    case WM_CTLCOLORLISTBOX :
            /* ================================================================================
            If user uses a ComboBox, it contains a ListBox in it.
            So, 'ctlHwnd' might be a handle of that ListBox. Or it might be a normal ListBox too.
            So, we need to check it before disptch this message to that listbox.
            Because, if it is from Combo's listbox, there is no Wndproc function for that ListBox. 
            =======================================================================================*/
            ctl_hwnd := dir_cast(lp, HWND)
            cmb_hwnd, okay := find_combo_data(this._ownerForm, ctl_hwnd)
            if okay  {
                // This message is from a combo's listbox. Divert it to that combo box.
                return SendMessage(cmb_hwnd, CM_COMBOLBCOLOR, wp, lp)
            } else {
                // This message is from a normal listbox. send it to it's wndproc.
                return SendMessage(ctl_hwnd, CM_LIST_COLOR, wp, lp)
            }

    case WM_ERASEBKGND:
        if this.style == .Overriden do return 1     

    case :
        return DefSubclassProc(hw, msg, wp, lp)
    }
    return DefSubclassProc(hw, msg, wp, lp)
}