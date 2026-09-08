/*
    Created on: 18-Jan-2022 04:30 PM
    Author: kcvinu
*/
/*===========================================Calendar Docs=========================================================
    Calendar struct
        Constructor: new_calendar() -> ^Calendar
        Properties:
            All props from Control struct
            value          : DateTime
            viewMode       : ViewMode enum
            oldView        : ViewMode enum
            showWeekNum    : b64
            noTodayCircle  : b64
            noToday        : b64
            noTrailingDates: b64
            shortDayNames  : b64
        Functions:
        Events:
            EventHandler type -proc(^Control, ^EventArgs) [See events.odin]
                onValueChanged
                onViewChanged
                onSelectionChanged        
==============================================================================================================*/

package winforms
import "base:runtime"

_calCounter: int = 1

Calendar:: struct
{
    using control: Control,
    value: DateTime,
    viewMode: ViewMode,
    oldView: ViewMode,
    showWeekNum: b64,
    noTodayCircle: b64,
    noToday: b64,
    noTrailingDates: b64,
    shortDayNames: b64,
    
    // Events
    onValueChanged,
    onViewChanged,
    onSelectionChanged: EventHandler,
}

// Create a new Calendar control.
new_calendar:: proc{new_cal1, new_cal2}



//===================================================Private functions=============================================
@private calendar_ctor:: proc(p: ^Control, x, y: i32) -> ^Calendar
{
    if !isDtpClassInit { // Then we need to initialize the date class control.
        isDtpClassInit = true
        app.iccx.dwIcc = ICC_DATE_CLASSES
        InitCommonControlsEx(&app.iccx)
    }

    this:= new(Calendar)
    this.kind = .Calendar
    control_base_init(this, p, x, y, 0, 0, &_calCounter)
    this._createHandleProc = cal_create_handle
    return this
}

@private new_cal1:: proc(parent: ^Control, x, y: i32) -> ^Calendar
{
    this := calendar_ctor(parent, x, y)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_cal2:: proc(parent: ^Control) -> ^Calendar
{
    this:= calendar_ctor(parent, 10, 10)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private cal_create_handle :: proc(ctl: ^Control)
{
	this := cast(^Calendar)ctl
    set_cal_style(this)
	create_control(ctl, this.width, this.height)
	set_subclass(this, cal_wnd_proc)
    rc: RECT
    SendMessage(this.handle, MCM_GETMINREQRECT, 0, convert_to(LPARAM, &rc))
    SetWindowPos(this.handle, nil, i32(this.xpos), i32(this.ypos), rc.right, rc.bottom, SWP_NOZORDER)
}

@private set_cal_style:: proc(c: ^Calendar)
{
    if c.showWeekNum do c._style |= MCS_WEEKNUMBERS
    if c.noTodayCircle do c._style |= MCS_NOTODAYCIRCLE
    if c.noToday do c._style |= MCS_NOTODAY
    if c.noTrailingDates do c._style |= MCS_NOTRAILINGDATES
    if c.shortDayNames do c._style |= MCS_SHORTDAYSOFWEEK
}

@private calendar_property_setter:: proc(this: ^Calendar, prop: CalendarProps, value: $T)
{
	#partial switch prop {
		case .Value:
            when T == DateTime {
                this.value = value
                if this._isCreated {
                    st:= datetime_to_systime(this.value)
                    SendMessage(this.handle, MCM_SETCURSEL, 0, &st)
                }
            }
		case .View_Mode:
            when T == ViewMode {
                this.viewMode = value
                if this._isCreated do SendMessage(this.handle, MCM_SETCURRENTVIEW, 0, i32(this.viewMode))
            }

		// case .Old_View: break
		// case .Show_Week_Num: control_enable(this, bool(value))
		// case .No_Today_Circle: control_set_size(this, this.width, int(value))
		// case .No_Today: control_set_text(this, tostring(value))
		// case .No_Trailing_Dates: control_visibile(this, bool(value))
		// case .Short_Day_Names: control_set_size(this, int(value), this.height)
	}
}


@private cal_finalize:: proc(this: ^Calendar)
{
    control_base_dtor(this)
	free(this,  context.allocator)
}

@private cal_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                            sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    context = global_context    
   //display_msg(msg)
    this := control_cast(Calendar, ref_data)
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

        case CM_NOTIFY:
            nm:= dir_cast(lp, ^NMHDR)
            //print("nm.code - ", nm.code)
            switch nm.code {
                case MCN_SELECT:
                    nms:= dir_cast(lp, ^NMSELCHANGE)
                    this.value = systime_to_datetime(nms.stSelStart)
                    if this.onValueChanged != nil {
                        ea:= new_event_args()
                        this.onValueChanged(this, &ea)
                    }

                case MCN_SELCHANGE:
                    nms:= dir_cast(lp, ^NMSELCHANGE)
                    this.value = systime_to_datetime(nms.stSelStart)
                    if this.onSelectionChanged != nil {
                        ea:= new_event_args()
                        this.onSelectionChanged(this, &ea)
                    }

                case MCN_VIEWCHANGE:
                    nmv:= dir_cast(lp, ^NMVIEWCHANGE)
                    this.viewMode = ViewMode(nmv.dwNewView)
                    this.oldView = ViewMode(nmv.dwOldView)
                    if this.onViewChanged != nil {
                        ea:= new_event_args()
                        this.onViewChanged(this, &ea)
                    }
            }      
            
        case WM_NCDESTROY: 
            RemoveWindowSubclass(this.handle, cal_wnd_proc, sc_id)
            cal_finalize(this)

        case:
        return DefSubclassProc(hw, msg, wp, lp)

    }
    return DefSubclassProc(hw, msg, wp, lp)
}
