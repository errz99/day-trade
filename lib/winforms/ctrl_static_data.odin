
// Created on 202-Apr-17 by kcvin

package winforms

wcnForm := L("Winforms_Window_Class")
wcnMsgOnlyWin := L("Winforms_MsgForm_Class")
wcnButton := L("Button")
wcnCalendar:= L("SysMonthCal32")
wcnCombo:= L("ComboBox")
wcnDTP := L("SysDateTimePick32")
wcnStatic := L("Static")
wcnListBox := L("ListBox")
wcnListView := L("SysListView32")
wcnNumPick := L("msctls_updown32")
wcnPictureBox := L("Winforms_PictureBox")
wcnProgressBar := L("msctls_progress32")
wcnEdit := L("Edit")
wcnTrackBar := L("msctls_trackbar32")
wcnTreeView := L("SysTreeView32")

COMM_CTRL_STYLES : UINT : WS_CHILD | WS_VISIBLE | WS_TABSTOP
wstyleButton : DWORD : COMM_CTRL_STYLES | BS_NOTIFY
wstyleCalendar : DWORD : COMM_CTRL_STYLES
wstyleCheckBox : DWORD :  COMM_CTRL_STYLES | BS_AUTOCHECKBOX
wxstyleCheckBox : DWORD : WS_EX_LTRREADING | WS_EX_LEFT
wstyleComboBox : DWORD : COMM_CTRL_STYLES | CBS_DROPDOWN
wxstyleComboBox : DWORD : WS_EX_CLIENTEDGE
wstyleDtp : DWORD : 0x52000004
wxstyleDtp : DWORD : WS_EX_LEFT
wstyleLabel : DWORD : COMM_CTRL_STYLES | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | SS_NOTIFY
wstyleListBox : DWORD : COMM_CTRL_STYLES | LBS_HASSTRINGS | WS_VSCROLL | WS_BORDER | LBS_NOTIFY
wstyleListView : DWORD : COMM_CTRL_STYLES | LVS_REPORT | WS_BORDER | LVS_ALIGNLEFT | LVS_SINGLESEL
wstyleNumPick : DWORD : COMM_CTRL_STYLES | UDS_ALIGNRIGHT | UDS_ARROWKEYS  | UDS_HOTTRACK | WS_CLIPSIBLINGS
wstylePgb : DWORD : COMM_CTRL_STYLES | PBS_SMOOTH
wxstylePgb : DWORD : WS_EX_STATICEDGE
wstyleRadio : DWORD : COMM_CTRL_STYLES | BS_AUTORADIOBUTTON | WS_CLIPCHILDREN
wstyleTB : DWORD : COMM_CTRL_STYLES | TBSTYLE
wxstyleTB : DWORD : WS_EX_LEFT | WS_EX_LTRREADING  | WS_EX_CLIENTEDGE
wstyleTkbar : DWORD : COMM_CTRL_STYLES | TBS_AUTOTICKS
wstyleTV : DWORD : COMM_CTRL_STYLES | WS_BORDER | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_DISABLEDRAGDROP

BLK_FGC : bool : true
NO_FGC : bool : false
TXTABLE : bool : true
NO_TXT : bool : false
FONTABLE : bool : true
NO_FONT : bool : false

ControlInfo :: struct
{
	prefix : string,	
	clsName : [^]u16,	
	style : DWORD,
	exStyle : DWORD,
	bkMode : BackColorMode,
	blackFGC : bool,
	isTextable : bool,
	hasFont : bool,
	
}

ControlStaticData := [ControlKind]ControlInfo {
	.Form = {"Form_", wcnForm, 0, 0, .None, NO_FGC, NO_TXT, NO_FONT},

	.Button = {"Button_", wcnButton, wstyleButton, 0,.None, NO_FGC, TXTABLE, FONTABLE},

	.Calendar = {"Calendar_", wcnCalendar, wstyleCalendar, 0, .None, NO_FGC, NO_TXT, NO_FONT},

	.Check_Box = {"Check_Box_", wcnButton, wstyleCheckBox, wxstyleCheckBox, .Inherit_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.Combo_Box = {"Combo_Box_", wcnCombo, wstyleComboBox, wxstyleComboBox, .White_BGC, BLK_FGC, NO_TXT, FONTABLE},

	.Date_Time_Picker = {"Date_Time_Picker_", wcnDTP, wstyleDtp, wxstyleDtp, .White_BGC, BLK_FGC, NO_TXT, FONTABLE},

	.Group_Box = {"Group_Box_", wcnButton, gbstyleFlag, gbexstyle, .Inherit_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.Label = {"Label_", wcnStatic, wstyleLabel, 0, .Inherit_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.List_Box = {"List_Box_", wcnListBox, wstyleListBox, 0, .White_BGC, BLK_FGC, NO_TXT, FONTABLE},

	.List_View = {"List_View_", wcnListView, wstyleListView, 0, .White_BGC, BLK_FGC, NO_TXT, FONTABLE},

	.Number_Picker = {"Number_Picker_", wcnNumPick, wstyleNumPick, 0, .White_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.Panel = {"Panel_", wcnButton, 0, 0, .None, NO_FGC, NO_TXT, NO_FONT},

    .Picture_Box = {"Picture_Box_", wcnPictureBox, COMM_CTRL_STYLES, 0, .None, NO_FGC, NO_TXT, NO_FONT},

	.Progress_Bar = {"Progress_Bar_", wcnProgressBar, wstylePgb, wxstylePgb, .None, BLK_FGC, TXTABLE, FONTABLE},

	.Radio_Button = {"Radio_Button_", wcnButton, wstyleRadio, 0, .Inherit_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.Text_Box = {"Text_Box_", wcnEdit, wstyleTB, wxstyleTB, .White_BGC, BLK_FGC, TXTABLE, FONTABLE},

	.Track_Bar = {"Track_Bar_", wcnTrackBar, wstyleTkbar, 0, .Inherit_BGC, NO_FGC, NO_TXT, NO_FONT},

	.Tree_View = {"Tree_View_", wcnTreeView, wstyleTV, 0, .White_BGC, BLK_FGC, NO_TXT, FONTABLE},
}



