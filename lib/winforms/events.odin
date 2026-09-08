package winforms
//import "core:fmt"

EventHandler :: proc(sender : rawptr, ea : ^EventArgs) //distinct #type
MouseEventHandler :: proc(sender : ^Control, e : ^MouseEventArgs)
KeyEventHandler :: proc(sender : ^Control, e : ^KeyEventArgs)
DateTimeEventHandler :: proc(sender : ^Control, e : ^DateTimeEventArgs)
PaintEventHandler :: proc(sender : ^Control, e : ^PaintEventArgs)
SizeEventHandler :: proc(sender : ^Control, e : ^SizeEventArgs)
LBoxEventHandler :: proc(sender : ^Control, e : string)
ThreadMsgHandler :: proc(wpm: WPARAM, lpm: LPARAM)
TreeEventHandler :: proc(sender : ^TreeView, e : ^TreeEventArgs)
MenuEventHandler :: proc(sender: ^MenuItem, e: ^EventArgs)
ContextMenuEventHandler :: proc(sender: ^ContextMenu, e: ^EventArgs)
TrayIconEventHandler :: proc(sender: ^TrayIcon, e: ^EventArgs)
ListViewItemEventHandler :: proc(sender: ^ListView, e: ^LVItemEventArgs)
ListViewSelChangeEventHandler :: proc(sender: ^ListView, e: ^LVSelChangedEventArgs)
ListViewItemCheckEventHandler :: proc(sender: ^ListView, e: ^LVItemCheckEventArgs)

// CreateDelegate :: proc(ctl : ^Control)
ControlDelegate :: proc(ctl : ^Control)
PropSetter :: proc(c: ^Control, p: any, v : any)

MK_LBUTTON  : u32 : 0x0001
MK_RBUTTON  : u32 : 0x0002
MK_SHIFT    : u32 : 0x0004
MK_CONTROL  : u32 : 0x0008
MK_MBUTTON  : u32 : 0x0010
MK_XBUTTON1 : u32 : 0x0020
MK_XBUTTON2 : u32 : 0x0040


EventArgs :: struct {handled : b64, cancel : b64,}
MouseEventArgs :: struct
{
	using base : EventArgs,
	button : MouseButtons,
	clicks, delta : i32,
	shiftPressed, ctrlPressed : b32,
	x, y : i32,
}

KeyEventArgs :: struct
{
    using base : EventArgs,
	altPressed : bool,
    ctrlPressed : bool,
    shiftPressed : bool,
    keyCode : KeyEnum,
    keyValue : int,
    suppressKeyPress : bool,
}

DateTimeEventArgs :: struct
{
    using base : EventArgs,
    dateString : string,
    dateStruct : SYSTEMTIME,
}

PaintEventArgs ::  struct
{
    using base : EventArgs,
    paintInfo : ^PAINTSTRUCT,
}

SizeEventArgs :: struct
{
    using base : EventArgs,
    formRect : ^RECT,
    sizedOn : SizedPosition,
    clientArea : Area,
   // sized_reason : SizedReason,
}

TreeEventArgs :: struct
{
    using base : EventArgs,
    action : TreeViewAction,
    isCBChanged: bool,
    oldChecked, newChecked: bool,
    node : ^TreeNode,
    oldNode : ^TreeNode,
    nodeText: string,
}

LVItemEventArgs :: struct
{
    using base: EventArgs,
    item: ^ListViewItem,
}

LVSelChangedEventArgs :: struct
{
    using base: EventArgs,
    item: ^ListViewItem,
    index: i32,
    isSelected: b32,
}

LVItemCheckEventArgs :: struct 
{
    using base: EventArgs,
    item: ^ListViewItem,
    index: i32,
    isChecked: b32,
}

new_event_args :: proc "contextless" () -> EventArgs
{
	ea : EventArgs
	ea.handled = false
    ea.cancel = false
	return ea
}


fill_mouse_event_args :: proc(this: ^MouseEventArgs, msg : u32, wpm : WPARAM, lpm : LPARAM) 
{
	fwKeys := LOWORD(wpm) 
	//fmt.println("fwKeys - ", fwKeys)
	this.delta = cast(i32)(HIWORD(wpm))
	this.shiftPressed = (cast(u32)wpm & MK_SHIFT) != 0
	this.ctrlPressed = (cast(u32)wpm & MK_CONTROL) != 0
	this.delta = cast(i32)(HIWORD(wpm))
	this.x = cast(i32)(cast(i16)LOWORD(lpm))
	this.y = cast(i32)(cast(i16)HIWORD(lpm))

	switch msg {
	case WM_LBUTTONDOWN, WM_LBUTTONUP:
        this.button = MouseButtons.Left
    case WM_RBUTTONDOWN, WM_RBUTTONUP:
        this.button = MouseButtons.Right
    case WM_MBUTTONDOWN, WM_MBUTTONUP:
        this.button = MouseButtons.Middle
    case :
        check_value := cast(u32)wpm
        if (check_value & MK_LBUTTON) != 0 {
            this.button = MouseButtons.Left
        } else if (check_value & MK_RBUTTON) != 0 {
            this.button = MouseButtons.Right
        }else if (check_value & MK_MBUTTON) != 0 {
            this.button = MouseButtons.Middle
        }        
	}
}

new_key_event_args :: proc(wP : WPARAM) -> KeyEventArgs
{
	kea : KeyEventArgs
    kea.keyCode = KeyEnum(wP)
    kea.keyValue = cast(int) kea.keyCode
    #partial switch kea.keyCode {
	case KeyEnum.Shift : kea.shiftPressed = true
	case KeyEnum.Ctrl : kea.ctrlPressed = true
	case KeyEnum.Alt : kea.altPressed = true
    }
    return kea
}

new_paint_event_args :: proc(ps : ^PAINTSTRUCT) -> PaintEventArgs
{
    pea : PaintEventArgs
    pea.paintInfo = ps
    return pea
}

new_size_event_args :: proc(m : u32, wpm : WPARAM, lpm : LPARAM) -> SizeEventArgs
{
    sea : SizeEventArgs
    if m == WM_SIZING { // When resizing happening
        sea.sizedOn = SizedPosition(wpm)
        sea.formRect = dir_cast(lpm, ^RECT)
    }
    else { //After resizing finished
        //sea.sized_reason = SizedReason(wpm)
        sea.clientArea.width = int(LOWORD(lpm))
        sea.clientArea.height = int(HIWORD(lpm))
    }
    return sea
}

new_tree_event_args :: proc{tree_event_args1, tree_event_args2, tree_event_args3}

tree_event_args1 :: proc(ntv : ^NMTREEVIEW) -> TreeEventArgs
{
    tea : TreeEventArgs
    if ntv.hdr.code == TVN_SELCHANGEDW || ntv.hdr.code == TVN_SELCHANGINGW {
        switch ntv.action {
            case 0 : tea.action = .Unknown
            case 1 : tea.action = .By_Mouse
            case 2 : tea.action = .By_Keyboard
        }
    }
    else if ntv.hdr.code == TVN_ITEMEXPANDEDW || ntv.hdr.code == TVN_ITEMEXPANDINGW {
        switch ntv.action {
            case 0 : tea.action = .Unknown
            case 1 : tea.action = .Collapse
            case 2 : tea.action = .Expand
        }
    }

    tea.node = dir_cast(ntv.itemNew.lParam, ^TreeNode)
    tea.oldNode = dir_cast(ntv.itemOld.lParam, ^TreeNode) if ntv.itemOld.lParam > 0 else nil
    return tea
}

tree_event_args2 :: proc(tic : ^NMTVITEMCHANGE) -> TreeEventArgs
{    
    tea : TreeEventArgs
    oldCheck := (tic.uStateOld & TVIS_STATEIMAGEMASK) >> 12
    newCheck := (tic.uStateNew & TVIS_STATEIMAGEMASK) >> 12
    tea.isCBChanged = oldCheck != newCheck
    tea.node = dir_cast(tic.lParam, ^TreeNode)    
    tea.oldChecked = oldCheck == 2
    tea.newChecked = newCheck == 2
    return tea
}

/*NOTE: tea.nodeText will be freed when the event handler returns.
       copy the string if user needs it later.*/
tree_event_args3 :: proc(tic : ^NMTVDISPINFOW, alloc:= context.allocator) -> TreeEventArgs
{    
    tea : TreeEventArgs
    tea.node = cast(^TreeNode)cast(uintptr) tic.item.lParam
    tea.nodeText = utf16_to_utf8(tic.item.pszText[:tic.item.cchTextMax], alloc)
    return tea
}





