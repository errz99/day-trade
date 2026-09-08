
/*===========================DateTimePicker Docs==============================
    DateTimePicker struct
        Constructor: new_datetimepicker() -> ^DateTimePicker
        Properties:
            All props from Control struct
            format         : DtpFormat
            formatString   : string
            rightAlign     : b64
            fourDigitYear  : b64
            value          : DateTime
            showWeekNum    : b64
            noTodayCircle  : b64
            noToday        : b64
            noTrailingDates: b64
            showUpdown     : b64
            shortDayNames  : b64
        Functions:
            dtp_set_value
            dtp_set_custom_format

        Events:
            EventHandler type -proc(^Control, ^EventArgs) [See events.odin]
                onCalendarOpened
                onValueChanged
                onCalendarClosed            
            DateTimeEventHandler type -proc(^TrayIcon, ^DateTimeEventArgs) [See events.odin]
                 onTextChanged 
        
===============================================================================*/


package winforms		// Notes: write func for setting value by user.

// import "core:strings"
import "core:fmt"
import "base:runtime"


isDtpClassInit: bool = false
_dtpCounter: int = 1




DateTimePicker:: struct
{
    using control: Control,
    format: DtpFormat,
    formatString: string,
    rightAlign: b64,
    fourDigitYear: b64,
    value: DateTime,
    showWeekNum: b64,
    noTodayCircle: b64,
    noToday: b64,
    noTrailingDates: b64,
    showUpdown: b64,
    shortDayNames: b64,

   // _fmt_str: string,
    _valueChangeCount: int,
    _bkBrush: HBRUSH,
    _calStyle: DWORD,

    onCalendarOpened,
    onValueChanged,
    onCalendarClosed: EventHandler,
    onTextChanged: DateTimeEventHandler,
}

// DateTimePicker constructor.
new_datetimepicker:: proc{new_dtp1, new_dtp2, new_dtp3}

dtp_set_value:: proc(dtp: ^DateTimePicker, dt_value: DateTime)
{
    dtp.value = dt_value
    if dtp._isCreated {
        sysTm:= datetime_to_systime(dt_value)
        SendMessage(dtp.handle, DTM_SETSYSTEMTIME, 0, dir_cast(&sysTm, LPARAM))
    }
}

dtp_set_custom_format:: proc(dtp: ^DateTimePicker, fmt_string: string)
{
    dtp.formatString = fmt_string
    dtp.format = .Custom
    if dtp._isCreated {
        SendMessage(dtp.handle, DTM_SETFORMATW, 0, convert_to(LPARAM, to_wstring(dtp.formatString)))
        // free_all(context.temp_allocator)
    }
}

//==================================Private Functions========================
@private dtp_ctor:: proc(p: ^Control, x, y, w, h: i32) -> ^DateTimePicker
{
    if !isDtpClassInit { // global var of this module. Then we need to initialize the date class control.
        isDtpClassInit = true
        app.iccx.dwIcc = ICC_DATE_CLASSES
        InitCommonControlsEx(&app.iccx)
    }
    this:= new(DateTimePicker)
    this.kind = .Date_Time_Picker
    control_base_init(this, p, x, y, w, h, &_dtpCounter)
    this._createHandleProc = dtp_create_handle
    this.format = .Custom
    this._fp_size_fix = set_dtp_size
    this.formatString = " dd-MMM-yyyy"  
    // ptf("nmhdr: %d", size_of(NMHDR)) // TODO:{IMPORTANT!} Change code member of NMHDR to u32.....
    return this
}

@private new_dtp1:: proc(parent: ^Control) -> ^DateTimePicker
{
    this:= dtp_ctor(parent, 10, 10, 120, 30 )
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_dtp2:: proc(parent: ^Control, x, y: i32) -> ^DateTimePicker
{
    this:= dtp_ctor(parent, x, y, 120, 30)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_dtp3:: proc(parent: ^Control, x, y, w, h: i32) -> ^DateTimePicker
{
    this:= dtp_ctor(parent,x, y, w, h)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private dtp_create_handle :: proc(ctl: ^Control)
{
	this := cast(^DateTimePicker)ctl
	set_dtp_style_internal(this)
	create_control(ctl, this.width, this.height)
	dtp_after_creation(this)	
}

@private set_dtp_style_internal:: proc(dtp: ^DateTimePicker)
{
    switch dtp.format {
        case .Custom:
            dtp._style = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATEFORMAT | DTS_APPCANPARSE
        case .Long:
            dtp._style = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_LONGDATEFORMAT
        case .Short:
            if dtp.fourDigitYear {
                dtp._style = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATECENTURYFORMAT
            } else {
                dtp._style = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_SHORTDATEFORMAT
            }
        case .Time:
            dtp._style = WS_TABSTOP | WS_CHILD|WS_VISIBLE|DTS_TIMEFORMAT
    }

    if dtp.showWeekNum do dtp._calStyle |= MCS_WEEKNUMBERS
    if dtp.noTodayCircle do dtp._calStyle |= MCS_NOTODAYCIRCLE
    if dtp.noToday do dtp._calStyle |= MCS_NOTODAY
    if dtp.noTrailingDates do dtp._calStyle |= MCS_NOTRAILINGDATES
    if dtp.shortDayNames do dtp._calStyle |= MCS_SHORTDAYSOFWEEK

    if dtp.rightAlign do dtp._style |= DTS_RIGHTALIGN
    if dtp.showUpdown do dtp._style ~= DTS_UPDOWN
}


// Set custom date format for a DTP control.
// To see how to create a custom format, see the docs.

// @private dtp_before_creation:: proc(dtp: ^DateTimePicker) {set_dtp_style_internal(dtp)}

@private dtp_after_creation:: proc(dtp: ^DateTimePicker)
{
    // print("dtp creation ended")
    set_subclass(dtp, dtp_wnd_proc)
    if dtp.format == .Custom {
		fmt_str:= fmt.tprintf("%v\x00", dtp.formatString)	// Creating a null terminated string.
        SendMessage(dtp.handle, DTM_SETFORMATA, 0, convert_to(LPARAM, raw_data(fmt_str)))
		/*
		Here, we have a strange situation. Since, we are working with unicode string, we need...
		to use the W version functions & messages. So, here DTM_SETFORMATW is the candidate.
		But it won't work. For some unknown reason, only DTM_SETFORMATA is working here. So we need...
		to pass a null terminated c string ptr to this function. Why MS, why ?
		*/
    }
    if dtp._calStyle > 0 {
        SendMessage(dtp.handle, DTM_SETMCSTYLE, 0, dir_cast(dtp._calStyle, LPARAM))
    }

    // Let's make proper size for this dtp
    set_dtp_size(dtp)
}

@private set_dtp_size:: proc(dtp: ^Control)
{
    ss: SIZE
    SendMessage(dtp.handle, DTM_GETIDEALSIZE, 0, to_lparam(&ss))
    dtp.width = ss.cx + 3
    dtp.height = ss.cy 
    SetWindowPos(dtp.handle, nil, dtp.xpos, dtp.ypos, dtp.width, dtp.height, SWP_NOZORDER)
}


@private dtp_property_setter:: proc(this: ^DateTimePicker, prop: DTPProps, value: $T)
{
    switch prop {
        case .Format: break
        case .Format_String:
            when T == string {
                this.formatString = value
                this.format = DtpFormat.Custom
                if this._isCreated {
                    SendMessage(this.handle, DTM_SETFORMATA, 0, LPARAM(to_wstring(value)))
                    // free_all(context.temp_allocator)
                }
            }
        case .Right_Align: break
        case .Four_Digit_Year: break
        case .Value:
            when T == DateTime {
                this.value = value
                st:= datetime_to_systime(value)
                SendMessage(this.handle, DTM_SETSYSTEMTIME, 0, LPARAM(&st))
            }
        case .Show_Updown: break
    }
}


@private dtp_finalize:: proc(this: ^DateTimePicker)
{
    control_base_dtor(this)
    free(this)
}

@private
dtp_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    // context = runtime.default_context()
    context = global_context
    this:= control_cast(DateTimePicker, ref_data)
    //display_msg(msg)
     res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
    switch msg {
    case WM_NCDESTROY:  
        RemoveWindowSubclass(this.handle, dtp_wnd_proc, sc_id)           
        dtp_finalize(this)

    case WM_PAINT:
        if this.onPaint != nil {
            ps: PAINTSTRUCT
            hdc:= BeginPaint(hw, &ps)
            pea:= new_paint_event_args(&ps)
            this.onPaint(this, &pea)
            EndPaint(hw, &ps)
            return 0
        }

    case WM_CONTEXTMENU:
        if this.contextMenu != nil do contextmenu_show(this.contextMenu, lp)

    case CM_NOTIFY:
        nm:= dir_cast(lp, ^NMHDR)
        switch nm.code { 
        case DTN_USERSTRING:
            if this.onTextChanged != nil {
                dts:= dir_cast(lp, ^NMDATETIMESTRINGW)
                dtea: DateTimeEventArgs
                dtea.dateString = wstring_to_string(dts.pszUserString)
                this.onTextChanged(this, &dtea )
                // After invoking the event, send this message to set the time in dtp
                if dtea.handled do SendMessage(this.handle, DTM_SETSYSTEMTIME, 0, dir_cast(&dtea.dateStruct, LPARAM))
                // free_all(context.temp_allocator)

            }
        case DTN_DROPDOWN:
            if this.onCalendarOpened != nil {
                ea:= new_event_args()
                this.onCalendarOpened(this, &ea)
                return 0
            }

        case DTN_DATETIMECHANGE:
            // For unknown reason, this notification occures two times.
            // So we need to use an integer value to limit it once and only.
            if this._valueChangeCount == 0 {
                this._valueChangeCount = 1
                dtc:= dir_cast(lp, ^NMDATETIMECHANGE)
                this.value = systime_to_datetime(dtc.st)
                if this.onValueChanged != nil {
                    ea:= new_event_args()
                    this.onValueChanged(this, &ea)
                    return 0
                }
            } else if this._valueChangeCount == 1 {
                this._valueChangeCount = 0
                return 0
            }
            return 0

        case DTN_CLOSEUP:
            if this.onCalendarClosed != nil {
                ea:= new_event_args()
                this.onCalendarClosed(this, &ea)
            }
        }    

    case: 
        return DefSubclassProc(hw, msg, wp, lp)
    }
    return DefSubclassProc(hw, msg, wp, lp)
}


