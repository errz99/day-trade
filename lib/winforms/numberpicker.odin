/*===========================NumberPicker Docs==============================
    NumberPicker struct
        Constructor : new_numberpicker() -> ^NumberPicker
        Properties:
            All properties from Control struct
            buttonOnLeft        : bool
            textAlignment       : SimpleTextAlignment - An enum in this file.
            minRange            : f32
            maxRange            : f32
            hasSeparator        : bool
            autoRotate          : bool - Value become min value after max value and vice versa.
            hideCaret           : bool
            value               : f32
            formatString        : string
            decimalPrecision    : int
            trackMouseLeave     : bool - Set true if you want to subscribe mouse leave event.
            step                : f32        

        Functions:
            numberpicker_set_range
            numberpicker_set_decimal_precision
             
        Events:
            EventHandler type events - proc(^Control, ^EventArgs)
                onValueChanged 
            PaintEventHandler type events - proc(^Control, ^PaintEventArgs)
                onButtonPaint
                onTextPaint    
===============================================================================*/

package winforms

import "base:runtime"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:math"
import api "core:sys/windows"


is_np_inited : bool = false    
_npCounter : int = 1
 
NP_STYLES : u32 = UDS_ALIGNRIGHT | UDS_ARROWKEYS | UDS_AUTOBUDDY | UDS_HOTTRACK   

//MAX_VALUE :: 16 // Increase this value if you need more than 15 digits on 

NumberPicker :: struct 
{
    using control : Control,
    textAlignment : SimpleTextAlignment,
    minRange: f32,
    maxRange : f32,
    value : f32,
    step : f32,
    buttonOnLeft: bool,
    hasSeparator : bool,
    autoRotate : bool, // use UDS_WRAP style
    hideCaret : bool,
    trackMouseLeave : bool,
    formatString : string,
    decimalPrecision : int,    

    _buddyHandle : HWND,
    _buddyStyle : DWORD,
    _buddyExStyle : DWORD,
    _buddySubclsID : int,
    _buddyWinProc : SUBCLASSPROC,
    _bkBrush : HBRUSH,
    _borderPen : HPEN,
    _tbwrc : RECT,
    _udrc : RECT,
    _myrc : RECT,
    _borderPts : [4]POINT,
    _npRect: RECT,
    _updatedTxt : string,
    _topEdgeFlag : DWORD,
    _botEdgeFlag : DWORD,
    _txtPos : SimpleTextAlignment,
    _bgcRef : COLORREF,
    _hoverTriggered: bool,
    _hoverTimer : ^Timer,
     _lastMpos: POINT,
    _disValArr: [dynamic]WCHAR,  

    // Events
    onButtonPaint,
    onTextPaint : PaintEventHandler,
    onValueChanged : EventHandler,
}

// Create new NumberPicker
new_numberpicker :: proc{np_ctor1, np_ctor2, np_ctor3}

// Set the max & min ranges for this NumberPicker
numberpicker_set_range :: proc(this : ^NumberPicker, max_val, min_val : int)
{
    this.maxRange = f32(max_val)
    this.minRange = f32(min_val)
    if this._isCreated {
        wpm := dir_cast(min_val, WPARAM)
        lpm := dir_cast(max_val, LPARAM)
        SendMessage(this.handle, UDM_SETRANGE32, wpm, lpm)
        new_arr_size := calc_value_array_size(this)
        if new_arr_size > len(this._disValArr) do resize(&this._disValArr, new_arr_size)
    }
}

// Set the decimal precision. Default is zero.
numberpicker_set_decimal_precision :: proc(this: ^NumberPicker, value: int)
{
    set_decimal_precision(this, value)
    new_arr_size := calc_value_array_size(this)
    if new_arr_size > len(this._disValArr) do resize(&this._disValArr, new_arr_size)
}




//===================================================================Private Functions======================
@private np_ctor :: proc(p : ^Control, x, y, w, h : i32) -> ^NumberPicker
{
    if !is_np_inited { // Then we need to initialize the date class control.
        is_np_inited = true
        app.iccx.dwIcc = ICC_UPDOWN_CLASS
        InitCommonControlsEx(&app.iccx)
    }
    this := new(NumberPicker)
    this.kind = .Number_Picker
    control_base_init(this, p, x, y, w, h, &_npCounter, "0")
    this._createHandleProc = nump_create_handle
    this.step = 1
    this._hasFont = true
    this.minRange = 0
    this.maxRange = 100
    this.decimalPrecision = 0
    this.formatString = "%d"
    this._buddyStyle = WS_CHILD | WS_VISIBLE | ES_NUMBER | WS_TABSTOP// | WS_BORDER
    this._buddyExStyle = WS_EX_LEFT //| WS_EX_CLIENTEDGE // WS_EX_LTRREADING | WS_EX_LEFT // | WS_EX_CLIENTEDGE
    this._topEdgeFlag = BF_TOPLEFT
    this._botEdgeFlag = BF_BOTTOM
    return this
}

@private np_ctor1 :: proc(parent : ^Control) -> ^NumberPicker
{
    this := np_ctor(parent,10, 10, 100, 25 )
    alloc_value_array(this)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private np_ctor2 :: proc(parent : ^Control, x, y : i32, 
                            deciPrec: int = 0, step: f32 = 1, btnLeft: bool = false) -> ^NumberPicker
{
    this := np_ctor(parent, x, y, 100, 25)
    this.buttonOnLeft = btnLeft
    set_decimal_precision(this, deciPrec)
    alloc_value_array(this)
    this.step = step
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private np_ctor3 :: proc(parent : ^Control, x, y, w, h : i32, 
                            deciPrec: int = 0, step: f32 = 1, btnLeft: bool = false) -> ^NumberPicker
{
    this := np_ctor(parent, x, y, w, h)
    this.buttonOnLeft = btnLeft
    set_decimal_precision(this, deciPrec)
    alloc_value_array(this)
    this.step = step
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private nump_create_handle :: proc(ctl: ^Control)
{
	this := cast(^NumberPicker)ctl
	if !is_np_inited {
        icex : INITCOMMONCONTROLSEX
        icex.dwSize = size_of(icex)
        icex.dwIcc = ICC_UPDOWN_CLASS
        InitCommonControlsEx(&icex)
        is_np_inited = true
    }
    set_np_styles(this)
    this._bgcRef = get_color_ref(this.backColor)	
	create_control(ctl, 0, 0)
	np_after_creation(this)	
}

@private set_np_styles :: proc(this : ^NumberPicker)
{
    if this.buttonOnLeft {
        this._style ~= UDS_ALIGNRIGHT
        this._style |= UDS_ALIGNLEFT
        this._topEdgeFlag = BF_TOP
        this._botEdgeFlag = BF_BOTTOMRIGHT
        if this._txtPos == SimpleTextAlignment.Left {
            this._txtPos = SimpleTextAlignment.Right
            
        }
    }
    switch this.textAlignment {
        case .Left : this._buddyStyle |= ES_LEFT
        case .Center : this._buddyStyle |= ES_CENTER
        case .Right : this._buddyStyle |= ES_RIGHT
    }
    // clr : Color = new_color(0xB4B4B4) //(0xABABAB) // Gray color for edit control border
    // this._borderPen = CreatePen(PS_SOLID, 1, get_color_ref(0xffffff))
}

@private np_set_range_internal :: proc(np : ^NumberPicker)
{
    wpm := dir_cast(i32(np.minRange), WPARAM)
    lpm := dir_cast(i32(np.maxRange), LPARAM)
    SendMessage(np.handle, UDM_SETRANGE32, wpm, lpm)
}

@private np_set_value_internal :: proc(np : ^NumberPicker, idelta : i32)
{
    new_val : f32 = np.value + (f32(idelta) * np.step)
    if np.autoRotate {
        if new_val > np.maxRange {  // 100.25 > 100.00
            np.value = np.minRange
        } else if new_val < np.minRange {
            np.value = np.maxRange
        } else {
            np.value = new_val
        }
    } else {
        np.value = clamp(new_val, np.minRange, np.maxRange)
    }
    np_display_value_internal(np)
}

@private np_display_value_internal :: proc(np : ^NumberPicker)
{
    val_str : string
    if np.decimalPrecision == 0 {
        val_str = fmt.tprintf(np.formatString, cast(int)np.value)
    } else {        
        val_str = fmt.tprintf(np.formatString, np.value)
    }    

    // We are filling our static wchar array with what va_str contains.
    utf8_to_utf16_with_array(val_str, np._disValArr[:])
    SetWindowText(np._buddyHandle, &np._disValArr[0])               
}

@private set_decimal_precision :: proc(this: ^NumberPicker, value: int)
{
    this.decimalPrecision = value
    if value == 0 {
        this.formatString = "%d"
    } else if value > 0 {        
        this.formatString = fmt.tprintf("%%.%df", value)
    } else {
        print("numberpicker_set_decimal_precision: Value must be greater than zero...!")
    }  

    if this._isCreated do np_display_value_internal(this)
}

@private calc_value_array_size :: proc(this: ^NumberPicker) -> int
{
    val_digits := int(math.log10(this.maxRange)) + 1
    return val_digits + this.decimalPrecision + 2
}

@private alloc_value_array :: proc(this: ^NumberPicker) 
{
    // Let's calculate the size of our array to hold the value string.
    val_digits := int(math.log10(this.maxRange)) + 1
    arr_len := val_digits + this.decimalPrecision + 2
    this._disValArr = make([dynamic]u16, arr_len)
    // ptf("array size %d", arr_len)
}

@private set_rects_and_size :: proc(this : ^NumberPicker)
{
    /* Mouse leave from a number picker is big problem. Since it is a combo control,
     * So here, we are trying to solve it somehow.
     * There is no magic in it. We just create a big RECT. It can comprise the edit & updown.
     * So, we will map the mouse points into parent's client rect size. Then we will
     * check if those points are inside our big rect. If yes, mouse is on us. Otherwise mouse leaved. */
    this._tbwrc = get_win_rect(this._buddyHandle) // buddy edit window rect
    OffsetRect(&this._tbwrc, -this._tbwrc.left, -this._tbwrc.top)
    this._udrc = get_rect(this.handle) // Arrow btn client rect
    
    /* We need to draw a border on 3 sides of our buddy control.
     * So we are preparing the pen and rect here. We will update
     * the rect when control get resized or moved..............*/ 
    this._borderPen = CreatePen(PS_SOLID, 2, get_color_ref(0xB4B4B4))
    if this.buttonOnLeft {  // ⊐
        this._borderPts[1].x = this._tbwrc.right
        this._borderPts[2].x = this._tbwrc.right
        this._borderPts[2].y = this._tbwrc.bottom
        this._borderPts[3].y = this._tbwrc.bottom

    } else {  // ⊏
        this._borderPts[0].x = this._tbwrc.right
        this._borderPts[2].y = this._tbwrc.bottom
        this._borderPts[3].x = this._tbwrc.right
        this._borderPts[3].y = this._tbwrc.bottom
    }
}

@private np_hide_selection :: proc(np : ^NumberPicker)
{
    wpm : i32 = -1
    SendMessage(np._buddyHandle, EM_SETSEL, WPARAM(wpm), 0)
}


@private np_after_creation :: proc(this : ^NumberPicker)
{    
    ctl_id : UINT= globalCtlID // Use global control ID & update it.
    globalCtlID += 1
    this._buddyHandle = CreateWindowEx( this._buddyExStyle,
                                        to_wstring("Edit"),
                                        nil,
                                        this._buddyStyle,
                                        this.xpos,
                                        this.ypos,
                                        this.width,
                                        this.height,
                                        this.parent.handle,
                                        dir_cast(ctl_id, HMENU),
                                        app.hInstance,
                                        nil )

    
    if this.handle != nil && this._buddyHandle != nil {
        set_np_subclass(this, np_wnd_proc, buddy_wnd_proc)
        if this.font.handle != this.parent.font.handle || this.font.handle == nil {
            font_create_handle(&this.font)
        }
        SendMessage(this._buddyHandle, WM_SETFONT, WPARAM(this.font.handle), LPARAM(1))

        usb := SendMessage(this.handle, UDM_SETBUDDY, WPARAM(this._buddyHandle), 0)
        oldBuddy : HWND = dir_cast(usb, HWND)
        SendMessage(this.handle, UDM_SETRANGE32, WPARAM(this.minRange), LPARAM(this.maxRange))

        set_rects_and_size(this)
        SetRect(&this._myrc, this.xpos, this.ypos, this.xpos + this.width, this.ypos + this.height)
        np_display_value_internal(this)
    }
}

@private nump_set_hover_timer :: proc(this: ^NumberPicker)
{
    this._hoverTimer = new_timer_internal(this.handle, 400)
}

@private numberpicker_property_setter :: proc(this: ^NumberPicker, prop: NumberPickerProps, value: $T)
{
	switch prop {
        case .Button_On_Left: break
        case .Text_Alignment: break
        case .Min_Range:
            when T == int {
                this.minRange = value
                if this._isCreated {
                    SendMessage(this.handle, 
                                UDM_SETRANGE32, 
                                WPARAM(int(this.minRange)), 
                                LPARAM(int(this.maxRange)))
                }
            }
        case .Max_Range:
            when T == int {
                this.maxRange = value
                if this._isCreated {
                    SendMessage(this.handle, 
                                UDM_SETRANGE32, 
                                WPARAM(int(this.minRange)), 
                                LPARAM(int(this.maxRange)))
                }
            }

        case .Has_Separator: break
        case .Auto_Rotate: break
        case .Hide_Caret: break
        case .Value:
            if this._isCreated {
                when T == f32 {
                    this.value = value
                } else when T == int {
                    this.value = f32(value)
                }
                np_display_value_internal(this)
            }
        case .Format_String: break
        case .Decimal_Precision:
            when T == int do numberpicker_set_decimal_precision(this, value)

        case .Track_Mouse_Leave: break
        case .Step: break
    }
}

// Special subclassing for NumberPicker control. Remove_subclass is written in dtor
@private set_np_subclass :: proc(np : ^NumberPicker, np_func, buddy_func : SUBCLASSPROC )
{
	np_dwp := cast(DWORD_PTR)(cast(UINT_PTR) np)
	api.SetWindowSubclass(np.handle, np_func, UINT_PTR(globalSubClassID), np_dwp )
	globalSubClassID += 1

	api.SetWindowSubclass(np._buddyHandle, buddy_func, UINT_PTR(globalSubClassID), np_dwp )
	globalSubClassID += 1
}

@private nump_mouse_move_handler :: proc(this: ^NumberPicker, hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM) 
{
    if this.onMouseMove != nil {
        mea : MouseEventArgs
		fill_mouse_event_args(&mea, msg, wp, lp)
        this.onMouseMove(this, &mea)
    }
    
    if SpecialMouseEvents.Mouse_Hover in this._mouseEvents {
        this._lastMpos.x = cast(i32)LOWORD(lp)
        this._lastMpos.y = cast(i32)HIWORD(lp)
        timer_restart(this._hoverTimer)
        this._hoverTriggered = true
    }

    if SpecialMouseEvents.Mouse_Enter in this._mouseEvents && !this._isMouseEntered {
        this._isMouseEntered = true
        ea := new_event_args()
        this.onMouseEnter(this, &ea)
    }       
}

@private nump_mouse_leave_handler :: proc(this: ^NumberPicker) 
{
    /*-----------------------------------------------------------------------------
        Mouse leave event in NumberPicker control is a bit tricky. It's a combination
        of a text box and button. And if we use UDS_HOTTRACK style, the
        control internally uses TrackMouseEvent function to track the mouse movement
        in the rect of the arrow button only. So we have to create an imaginary rect over 
        the bondaries of these two controls. If mouse is inside that rect, 
        there is no mouse leave. A perfect hack!
    ----------------------------------------------------------------------------------*/
    if mouse_leave_or_hover_set(this._tmeFlags) {
        if this._isMouseEntered || this._isMouseTracking || this._hoverTriggered {
            pt : POINT = {}
            GetCursorPos(&pt)
            ScreenToClient(this.parent.handle, &pt)        
            inside := PtInRect(&this._myrc, pt)
            if !inside {        
                this._isMouseEntered = false
                this._isMouseTracking = false
                if this._hoverTriggered {
                    this._hoverTriggered = false
                    timer_stop(this._hoverTimer)
                }

                if this.onMouseLeave != nil do this.onMouseLeave(this, &gea)
            }
        }
    }
}


@private np_finalize :: proc(this: ^NumberPicker)
{
    delete_gdi_object(this._bkBrush)   
    delete_gdi_object(this._borderPen) 
    if SpecialMouseEvents.Mouse_Hover in this._mouseEvents {
        timer_dtor(this._hoverTimer)      
    }
    delete(this._disValArr)  
    control_base_dtor(this)
    
    free(this)
}


@private np_wnd_proc :: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                        sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context 
    this := control_cast(NumberPicker, ref_data)
    // display_msg(msg)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }

    switch msg {
    case WM_TIMER:
        if this.onMouseHover != nil {
            timer_stop(this._hoverTimer)
            this.onMouseHover(this, &gea)
            return 0
        }
    case WM_NCDESTROY:     
        RemoveWindowSubclass(this.handle, np_wnd_proc, sc_id)        
        np_finalize(this)
        

    case WM_PAINT:
        if this.onPaint != nil {
            ps : PAINTSTRUCT
            hdc := BeginPaint(hw, &ps)
            pea := new_paint_event_args(&ps)
            this.onButtonPaint(this, &pea)
            EndPaint(hw, &ps)
            return 0
        }
        
    case CM_NOTIFY :
        nm := dir_cast(lp, ^NMUPDOWN)
        if nm.hdr.code == UDN_DELTAPOS {
            tbstr : string = get_ctrl_text_internal(this._buddyHandle)
            new_val, _ := strconv.parse_f32(tbstr)
            this.value = new_val
            defer delete(tbstr)                
            np_set_value_internal(this, nm.iDelta)                
        }

        if this.onValueChanged != nil {
            ea := new_event_args()
            this.onValueChanged(this, &ea)
        }
        return 0       

    case WM_ENABLE :
        api.EnableWindow(hw, auto_cast(wp))
        api.EnableWindow(this._buddyHandle, auto_cast(wp))
        return 0

    case : 
        return DefSubclassProc(hw, msg, wp, lp)

    }
    return DefSubclassProc(hw, msg, wp, lp)
}

@private buddy_wnd_proc :: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                            sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context
    this := control_cast(NumberPicker, ref_data)

    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }

    switch msg {
        case WM_NCCALCSIZE:
            /* By default, arrow button has a border on 3 sides.
             * But we don't use WS_BORDER style for this edit control.
             * So, we need to draw a border on the 3 sides of this edit.
             * To do that, we need to shrink the client area and make room..
             * for our border......................................... */ 
            if wp == 1 {
                pncsp := dir_cast(lp, ^NCCALCSIZE_PARAMS)
                if !this.buttonOnLeft {
                    pncsp.rgrc[0].left += 1
                    pncsp.rgrc[0].top += 1
                    pncsp.rgrc[0].right -= 2
                    pncsp.rgrc[0].bottom -= 1 
                } else {
                    pncsp.rgrc[0].left += 2
                    pncsp.rgrc[0].top += 1
                    pncsp.rgrc[0].right -= 1
                    pncsp.rgrc[0].bottom -= 1 
                }                               
                return 0
            }            

        case WM_NCPAINT:
            // Drawing border on 3 sides of the edit control.
            // Points are pre-calculated. Make sure to adjust them
            // when control resized or moved.
            hrgn := cast(HRGN)wp     
            flags := DCX_WINDOW | DCX_CACHE | DCX_INTERSECTRGN
            if wp == 1 do flags = DCX_WINDOW | DCX_CACHE    
            hdc : HDC = GetDCEx(hw, hrgn, flags)
            defer ReleaseDC(hw, hdc)    
            if hdc != nil {        
                hOldPen := SelectObject(hdc, HGDIOBJ(this._borderPen))        
                Polyline(hdc, &this._borderPts[0], 4)
                SelectObject(hdc, hOldPen)
            }
            return 0


        case WM_NCDESTROY: 
            RemoveWindowSubclass(hw, buddy_wnd_proc, sc_id)

        case CM_EDIT_COLOR:
            if this.foreColor != def_fore_clr || this.backColor != def_back_clr {
                dc_handle := dir_cast(wp, HDC)
                api.SetBkMode(dc_handle, api.BKMODE.TRANSPARENT)
                if this.foreColor != 0x000000 {
                    SetTextColor(dc_handle, get_color_ref(this.foreColor))
                }
                if this._bkBrush == nil {
                    this._bkBrush = CreateSolidBrush(get_color_ref(this.backColor))
                }
                return toLRES(this._bkBrush)
            }

        case EM_SETSEL: 
            return 1

        case WM_KEYDOWN:
            kea := new_key_event_args(wp)
            if this.onKeyDown != nil {
                this.onKeyDown(this, &kea)
            }

        case CM_CTLCOMMAND:
            ncode := HIWORD(wp)
            if ncode == EN_UPDATE {
                if this.hideCaret do HideCaret(hw)
            }

        case WM_KEYUP:
            kea := new_key_event_args(wp)
            if this.onKeyUp != nil {
                this.onKeyUp(this, &kea)
            }
            SendMessage(hw, CM_TBTXTCHANGED, 0, 0)
            return 0

        case WM_CHAR:
            if this.onKeyPress != nil {
                kea := new_key_event_args(wp)
                this.onKeyPress(this, &kea)
                return 0
            }

        case CM_TBTXTCHANGED:
             if this.onValueChanged != nil {
                ea:= new_event_args()
                this.onValueChanged(this, &ea)
            }        

        case : return DefSubclassProc(hw, msg, wp, lp)
    }
    return 0 // DefSubclassProc(hw, msg, wp, lp)
}





