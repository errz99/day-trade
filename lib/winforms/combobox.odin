
/*===========================================ComboBox Docs=========================================================
    ComboBox struct
        Constructor: new_comboBox() -> ^ComboBox
        Properties:
            All props from Control struct
            comboStyle         : DropDownStyle enum
            items              : [dynamic]string
            visibleItemCount   : int
            selectedIndex      : int
            selectedItem       : string
        Functions:
            combo_set_style()
            combo_add_item()
            combo_open_list()
            combo_close_list()
            combo_add_items()
            combo_add_array()
            combo_get_selected_index()
            combo_set_selected_index()
            combo_set_selected_item()
            combo_get_selected_item()
            combo_delete_selected_item()
            combo_delete_item()
            combo_clear_items()
        Events:
            EventHandler type -proc(^Control, ^EventArgs) [See events.odin]
                onSelectionChanged
                onSelectionCommitted
                onSelectionCancelled
                onTextChanged
                onTextUpdated
                onListOpened
                onListClosed
                onTBClick
                onTBMouseLeave
                onTBMouseEnter
        
==============================================================================================================*/

package winforms

import "core:fmt"
import "base:runtime"
import api "core:sys/windows"
import "core:time"


_cmbCounter: int = 1

ComboBox:: struct
{
    using control: Control,
    comboStyle: DropDownStyle,
    items: [dynamic]string, // Don't forget to delete it when combo box deing destroyed.
    visibleItemCount: int,
    selectedIndex: int,
    selectedItem: string,
    _recreateEnabled: bool, // Used when we need to recreate existing combo
    _dropped: bool, // Used for tracking whether combo's list is dropped or not.
    _meFired: bool, // Used for avoiding firing mouse leave event when combo's dropdown list is opening.
    _hoverTriggered: bool,
    _bkBrush: HBRUSH,
    _oldCtlID: UINT,
    _editSubclsID: UINT_PTR,
    // _mouseFlag : i32, // General mouse message processing flag
    // _mst : MouseTrackData,
    _cmbRect: RECT, // Used for mouse tracking
    _lastMpos: POINT,
    _hoverTimer : ^Timer,


    // Events
    onSelectionChanged,
    onSelectionCommitted,
    onSelectionCancelled,
    onTextChanged,
    onTextUpdated,
    onListOpened,
    onListClosed,
    onTBClick,
    onTBMouseLeave,
    onTBMouseEnter: EventHandler,
}

MouseTrackData:: struct
{
    cmbEnter: bool,
    editEnter: bool,
    editLeave: bool,
    cmbLeave: bool,
}

// Create new ComboBox
new_combobox:: proc{new_combo1, new_combo2, new_combo3}

// Show combo's dropdown list
combo_open_list:: proc(cmb: ^ComboBox) { SendMessage(cmb.handle, CB_SHOWDROPDOWN, WPARAM(1), 0) }

// Close combo's dropdown list
combo_close_list:: proc(cmb: ^ComboBox) { SendMessage(cmb.handle, CB_SHOWDROPDOWN, WPARAM(0), 0) }

// Add an item to combo.
combo_add_item:: proc(cmb: ^ComboBox, item: $T )
{
    sitem: string
    when T == string {
        sitem = item
    } else {
        sitem:= fmt.tprint(an_item)
    }
    append(&cmb.items, sitem)
    if cmb._isCreated {
        SendMessage(cmb.handle, CB_ADDSTRING, 0, dir_cast(to_wstring(sitem), LPARAM))
        // free_all(context.temp_allocator)
    }
}

// Add items to combo in bulk
combo_add_items:: proc{add_items2}

// Add an array to combo box
combo_add_array:: proc(cmb: ^ComboBox, items: []$T )
{
    //print("called once")
    when T == string {
        for i in items {
            append(&cmb.items, i)
        }
    } else {
        for i in items {
            a_string:= fmt.tprint(i)
            append(&cmb.items, a_string)
        }
    }
    // IMPORTANT - add code for update combo items
}

// Get the selected index number
combo_get_selected_index:: proc(cmb: ^ComboBox) -> int
{
    cmb.selectedIndex = int(SendMessage(cmb.handle, CB_GETCURSEL, 0, 0))
    return cmb.selectedIndex
}

// Set the item in given index as selected item
combo_set_selected_index:: proc(cmb: ^ComboBox, indx: int)
{
    SendMessage(cmb.handle, CB_SETCURSEL, WPARAM(i32(indx)), 0)
    cmb.selectedIndex = indx
}

// Set the given item as selected item
combo_set_selected_item:: proc(cmb: ^ComboBox, item: $T)
{
    sitem:= fmt.tprint(item)
    wp: i32 = -1
    indx:= cast(i32) SendMessage(cmb.handle, CB_FINDSTRINGEXACT, WPARAM(wp), dir_cast(to_wstring(sitem), LPARAM))
    if indx == LB_ERR do return
    SendMessage(cmb.handle, CB_SETCURSEL, WPARAM(indx), 0)
    cmb.selectedIndex = int(indx)
    cmb.selectedItem = sitem
    // free_all(context.temp_allocator)
}

// Get the selected item
combo_get_selected_item:: proc(cmb: ^ComboBox) -> any
{
    indx:= int(SendMessage(cmb.handle, CB_GETCURSEL, 0, 0))
    if indx > -1 {
        return cmb.items[indx]
    } else do return ""
}

// Delete the selected item
combo_delete_selected_item:: proc(cmb: ^ComboBox)
{
    indx:= i32(SendMessage(cmb.handle, CB_GETCURSEL, 0, 0))
    if indx > -1 {
        SendMessage(cmb.handle, CB_DELETESTRING, WPARAM(indx), 0)
        ordered_remove(&cmb.items, int(indx))
    }
}

// Delete the item in given index
combo_delete_item:: proc(cmb: ^ComboBox, indx: int)
{
    SendMessage(cmb.handle, CB_DELETESTRING, dir_cast(i32(indx), WPARAM), 0)
    ordered_remove(&cmb.items, indx)
}

// Clear all items from combo
combo_clear_items:: proc(cmb: ^ComboBox)
{
    SendMessage(cmb.handle, CB_DELETESTRING, 0, 0)
    // TODO - clear dynamic array of combo.
}

// Set combo box's drop down style
combo_set_style:: proc(cmb: ^ComboBox, style: DropDownStyle)
{
    /* There is no other way to change the dropdown style of an existing combo box.
     * We need to destroy the old combo and create a new one with same size and pos.
     * Then fill the old combo items. */
    if cmb._isCreated {
        if cmb.comboStyle == style do return
        cmb.comboStyle = style
        cmb._recreateEnabled = true
        DestroyWindow(cmb.handle)
        cmb.handle = nil
        create_control(cmb)
    } else {
        // Not now baby
        cmb.comboStyle = style
    }
}


//============================================Private functions==========================================
@private ComboData:: struct
{
    listBoxHwnd: HWND,
    comboHwnd: HWND,
    editHwnd: HWND,
    comboID: u32,
}

@private new_combo_data:: proc(cbi: COMBOBOXINFO, id: u32) -> ComboData
{
    cd: ComboData
    cd.comboHwnd = cbi.hwndCombo
    cd.comboID = id
    cd.editHwnd = cbi.hwndItem
    cd.listBoxHwnd = cbi.hwndList
    return cd
}

@private get_combo_info:: proc(cmb: ^ComboBox) -> ComboData
{
    // Collect the data from Combobox control.
    cmInfo: COMBOBOXINFO
    cmInfo.cbSize = size_of(cmInfo)
    SendMessage(cmb.handle, CB_GETCOMBOBOXINFO, 0, dir_cast(&cmInfo, LPARAM))
    cd:= new_combo_data(cmInfo, cmb.controlID)
    return cd
}

@private cmb_ctor:: proc(p: ^Control, w: i32 = 130, h: i32 = 30, x: i32 = 10, y: i32 = 10) -> ^ComboBox
{
    this:= new(ComboBox)
    this.kind = .Combo_Box
    control_base_init(this, p, x, y, w, h, &_cmbCounter)
    this._createHandleProc = cmb_create_handle
    this.selectedIndex = -1
    this.comboStyle = DropDownStyle.Lb_Combo
    return this
}

@private new_combo1:: proc(parent: ^Control) -> ^ComboBox
{
    this:= cmb_ctor(parent)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_combo2:: proc(parent: ^Control, x, y: i32, 
                            cmbStyle: DropDownStyle = DropDownStyle.Lb_Combo ) -> ^ComboBox
{
    this:= cmb_ctor(parent, x = x, y= y)
    this.comboStyle = cmbStyle
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_combo3:: proc(parent: ^Control, x, y, w, h: i32,
                            cmbStyle: DropDownStyle = DropDownStyle.Lb_Combo ) -> ^ComboBox
{
    this:= cmb_ctor(parent, w, h, x, y)
    this.comboStyle = cmbStyle
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private add_items2:: proc(cmb: ^ComboBox, items: ..any )
{
    for i in items {
        if value, is_str:= i.(string) ; is_str { // Magic -- type assert
            append(&cmb.items, value)
            if cmb._isCreated {
                SendMessage(cmb.handle, CB_ADDSTRING, 0, dir_cast(to_wstring(value), LPARAM))
                // // free_all(context.temp_allocator)
            }
        } else {
            a_string:= fmt.tprint(i)
            append(&cmb.items, a_string)
            if cmb._isCreated {
                SendMessage(cmb.handle, CB_ADDSTRING, 0, dir_cast(to_wstring(a_string), LPARAM))
                // // free_all(context.temp_allocator)
            }
        }
    }
}

@private additem_internal:: proc(cmb: ^ComboBox)
{
    for i in cmb.items {
        SendMessage(cmb.handle, CB_ADDSTRING, 0, dir_cast(to_wstring(i), LPARAM))
        // free_all(context.temp_allocator)
    }
}

@private combo_set_hover_timer :: proc(this: ^ComboBox)
{
    this._hoverTimer = new_timer_internal(this.handle, 400)
}

@private cmb_create_handle :: proc(ctl: ^Control)
{
	this := cast(^ComboBox)ctl
	if this.comboStyle == .Lb_Combo {
        this._style |= CBS_DROPDOWNLIST
    } else {
        this._style |= CBS_DROPDOWN
    }
    if this._recreateEnabled {
        this.selectedIndex = int(SendMessage(this.handle, CB_GETCURSEL, 0, 0))
    }
    this._bkBrush = get_solid_brush(this.backColor)
	create_control(ctl, this.width, this.height)
	cmb_after_creation(this)	
}



@private cmb_after_creation:: proc(cmb: ^ComboBox)
{    
	set_subclass(cmb, cmb_wnd_proc)
    cmb._oldCtlID = cmb.controlID
    cd: ComboData = get_combo_info(cmb)

    // Collecting child controls info
    if cmb._recreateEnabled {
        cmb._recreateEnabled = false
        update_combo_data(cmb._ownerForm, cd)

        // If selected index was a valid number, set the selection again.
        if cmb.selectedIndex != -1 {
            SendMessage(cmb.handle, CB_SETCURSEL, WPARAM(i32(cmb.selectedIndex)), 0)
        }
    } else {
        collect_combo_data(cmb._ownerForm, cd)
    }

    // Now, subclass the edit control.
    api.SetWindowSubclass(cd.editHwnd, edit_wnd_proc, cmb._editSubclsID, to_dwptr(cmb))
    cmb._editSubclsID += 1 // We don't want to use the same id again and again.

    if len(cmb.items) > 0 do additem_internal(cmb)

    if cmb.selectedIndex > -1 { // User wants to set the selected index.
        combo_set_selected_index(cmb, cmb.selectedIndex)
    }

    // Lastly, we need to collect the control rect for managing mouse enter & leave events
    GetClientRect(cmb.handle, &cmb._cmbRect)      
}

@private cmb_mouse_move_handler :: proc(this: ^ComboBox, hw: HWND, msg: UINT, wpm: WPARAM, lpm: LPARAM)
{
    if this.onMouseMove != nil {
        mea : MouseEventArgs
		fill_mouse_event_args(&mea, msg, wpm, lpm)
        this.onMouseMove(this, &mea)
    }

    if SpecialMouseEvents.Mouse_Hover in this._mouseEvents && !this._hoverTriggered {
        this._lastMpos.x = cast(i32)LOWORD(lpm)
        this._lastMpos.y = cast(i32)HIWORD(lpm)
        timer_restart(this._hoverTimer)
        this._hoverTriggered = true
    }

    if SpecialMouseEvents.Mouse_Enter in this._mouseEvents && !this._isMouseEntered {
        this._isMouseEntered = true
        ea := new_event_args()
        this.onMouseEnter(this, &ea)
    }        
}

@private cmb_mouse_leave_handler :: proc(this: ^ComboBox) 
{
    if mouse_leave_or_hover_set(this._tmeFlags) {
        if this._isMouseEntered || this._isMouseTracking || this._hoverTriggered {

            // SInce ComboBox is a comnination of edit and button, we need special
            // care to implement mouse leave event. Edit is sitting inside combo's
            // rect. So we get mouse leave message even when mouse is inside combo.
            // So, we need to check if mouse is really inside our perimeter. 
            pt : POINT = {}
            GetCursorPos(&pt)
            ScreenToClient(this.handle, &pt)        
            inside := PtInRect(&this._cmbRect, pt)
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

@private combo_property_setter:: proc(this: ^ComboBox, prop: ComboProps, value: $T)
{
    switch prop {
        case .Combo_Style: when T == DropDownStyle do combo_set_style(this, value)
        case .Visible_Item_Count: break
        case .Selected_Index: when T == int do combo_set_selected_index(this, value)
        case .Selected_Item: combo_set_selected_item(this, value)
    }
}

@private cmb_finalize:: proc(this: ^ComboBox)
{
    if !this._recreateEnabled {
        delete_gdi_object(this._bkBrush)        
        if SpecialMouseEvents.Mouse_Hover in this._mouseEvents do timer_dtor(this._hoverTimer)
        control_base_dtor(this)
        delete(this.items)
        free(this)
    }
}

@private cmb_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context
    this := control_cast(ComboBox, ref_data)
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
        case WM_NCDESTROY: 
            RemoveWindowSubclass(this.handle, cmb_wnd_proc, sc_id)
            cmb_finalize(this)

        case CM_CTLCOMMAND:
            ncode:= HIWORD(wp)
           // ptf("WM_COMMAND notification code - %d\n", ncode)
            switch ncode {
                case CBN_SELCHANGE:
                    if this.onSelectionChanged != nil do this.onSelectionChanged(this, &gea)

                case CBN_DBLCLK:

                case CBN_SETFOCUS:
                    if this.onGotFocus != nil do this.onGotFocus(this, &gea)
                    
                case CBN_KILLFOCUS:
                    if this.onLostFocus != nil do this.onLostFocus(this, &gea)
    
                case CBN_EDITCHANGE:
                    if this.onTextChanged != nil do this.onTextChanged(this, &gea)
                
                case CBN_EDITUPDATE:
                     if this.onTextUpdated != nil do  this.onTextUpdated(this, &gea)
                    
                case CBN_DROPDOWN:
                    this._dropped = true
                    if this.onListOpened != nil do this.onListOpened(this, &gea)
                
                case CBN_CLOSEUP:
                    /* When user selects an item from the dropdown list, Windows 
                        will capture the mouse and proceeding with the list that
                        contains the combo box items. So we don't get the mouse leave
                        event from the combo box. So we need to track when the list is
                        opening. This bool flag is used to indicate the dropdown state. */
				    this._dropped = false
                    if this.onListClosed != nil do this.onListClosed(this, &gea)

                case CBN_SELENDOK:
                    this._isMouseTracking = false
                    if this.onSelectionCommitted != nil do this.onSelectionCommitted(this, &gea)

                case CBN_SELENDCANCEL:
                    if this.onSelectionCancelled != nil do this.onSelectionCancelled(this, &gea)

            }

        case CM_COMBOLBCOLOR:
            //print("color combo list box")
            if this.foreColor != def_fore_clr || this.backColor != def_back_clr {
                //print("combo color rcvd")
                dc_handle:= dir_cast(wp, HDC)
                api.SetBkMode(dc_handle, api.BKMODE.TRANSPARENT)
                if this.foreColor != def_fore_clr do SetTextColor(dc_handle, get_color_ref(this.foreColor))
                if this._bkBrush == nil do this._bkBrush = CreateSolidBrush(get_color_ref(this.backColor))
                return toLRES(this._bkBrush)
            } else {
                if this._bkBrush == nil do this._bkBrush = CreateSolidBrush(get_color_ref(this.backColor))
                return toLRES(this._bkBrush)
            }

        case WM_PARENTNOTIFY:
            wp_lw:= LOWORD(wp)
            switch wp_lw {
            case 512:  // WM_MOUSEFIRST
                if this.onTBMouseEnter != nil {
                    ea:= new_event_args()
                    this.onTBMouseEnter(this, &ea)
                }
            case 513: // WM_LBUTTONDOWN
                if this.onTBClick != nil {
                    ea:= new_event_args()
                    this.onTBClick(this, &ea)
                }
            case 675: // WM_MOUSELEAVE
                if this.onTBMouseLeave != nil {
                    ea:= new_event_args()
                    this.onTBMouseLeave(this, &ea)
                }
            }
    }
    return DefSubclassProc(hw, msg, wp, lp)
}


@private edit_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = runtime.default_context()
    this := control_cast(ComboBox, ref_data)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }

    switch msg {
        case WM_NCDESTROY: 
            RemoveWindowSubclass(hw, edit_wnd_proc, sc_id)

        case CM_EDIT_COLOR:
            if this.foreColor != def_fore_clr || this.backColor != def_back_clr {
                dc_handle:= dir_cast(wp, HDC)
                // SetBkMode(dc_handle, Transparent)
                if this.foreColor != def_fore_clr do SetTextColor(dc_handle, get_color_ref(this.foreColor))
                if this.backColor != def_back_clr do SetBkColor(dc_handle, get_color_ref(this.backColor))
                return toLRES(this._bkBrush)
            }

        case WM_KEYDOWN: // only works in Tb_combo style
            if this.onKeyDown != nil {
                kea:= new_key_event_args(wp)
                this.onKeyDown(this, &kea)
            }

        case WM_KEYUP: // only works in Tb_combo style
            if this.onKeyUp != nil {
                kea:= new_key_event_args(wp)
                this.onKeyUp(this, &kea)
            }        
    }
    return DefSubclassProc(hw, msg, wp, lp)
}
