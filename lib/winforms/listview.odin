
/*
	Created on: 20-Feb-2022 9:00:25 AM
		Name: ListView type
*/
/*===========================ListView Docs==============================
    ListView struct
        Constructor: new_listview() -> ^ListView
        Properties:
            All props from Control struct            
        	itemAlignment 			: enum {Left, Top}
			columnAlignment 		: ColumnAlignment
			viewStyle 				: ListViewStyle
			hideSelection 			: bool
			multiSelection 			: bool
			hasCheckBoxes 			: bool
			fullRowSelect 			: bool
			showGridLines 			: bool
			oneClickActivate 		: bool
			hotTrackSelect 			: bool
			editLabel 				: bool
			noHeader 				: bool
			headerBackColor 		: uint
			headerForeColor 		: uint
			headerHeight 			: int
			headerClickable 		: bool
			items 					: [dynamic]^ListViewItem
			columns 				: [dynamic]^ListViewColumn

        Functions:
        	new_listview_column
			new_listviewitem
			new_listviewcolumn_array
			listview_add_column
			listview_add_row
			listview_add_item
			listview_add_subitem
			listview_add_subitems
			listview_set_column_order
			listview_get_coulmn_count
			listview_set_style
			listview_begin_update
			listview_end_update
			listview_delete_item
			lv_del_item1
			lv_del_item2
			listview_delete_selected_item
			listview_clear_items
			listview_delete_column
			listview_get_item
			listview_get_row
			listview_get_selected_items
             
        Events:
            All events from Control struct
			onSelectionChanged
			onItemCheckChanged
			onItemClick
			onItemDoubleClick
			onItemActivate
             
        
===============================================================================*/
#+feature using-stmt
package winforms
import "base:runtime"
import api "core:sys/windows"
//import "core:fmt"

IccListViewClass:: 0x1
lvcount: int = 0

// Default style for list view. We can change it later with listview_set_style function.
LV_STYLE : u32 = LVS_REPORT | WS_BORDER | LVS_ALIGNLEFT | LVS_SINGLESEL 

LVIS_SELECTED :: 0x0002
LVIS_STATEIMAGEMASK :: 61440
LVN_ITEMACTIVATE :: (LVN_FIRST-14)

ListView:: struct
{			// IMPORTANT - use this -> LVS_EX_COLUMNSNAPPOINTS - as a property
	using control: Control,
	itemAlignment: LVItemAlignment,
	columnAlignment: ColumnAlignment,

	viewStyle: ListViewStyle,
	hideSelection: bool,
	multiSelection: bool,
	hasCheckBoxes: bool,
	fullRowSelect: bool,
	showGridLines: bool,
	oneClickActivate: bool,
	hotTrackSelect: bool,
	editLabel: bool,
	noHeader: bool,
	checked: b32,
	headerBackColor, headerForeColor: uint,
	headerHeight: int,
	selectedItemIndex: int,
	selectedSubItemIndex: int,

	headerClickable: bool,
	items: [dynamic]^ListViewItem,
	selectedItems: [dynamic]^ListViewItem,
	selectedItem: ^ListViewItem,
	columns: [dynamic]^ListViewColumn,

	_colIndex: i32,
	_index: i32,
	_imgList: ImageList,
	_hdrHwnd: HWND,
	_hdrIndex: i32,
	_hdrBkBrush, _hdrHotBrush: HBRUSH,
	_bgcRef, _fgcRef: COLORREF,
	_bgcDraw: bool,

	_divPen: HPEN,
	// _lvcList: [dynamic]LVCOLUMN,

	// Events
	onSelectionChanged: ListViewSelChangeEventHandler,
	onItemCheckChanged: ListViewItemCheckEventHandler,
	onItemClick: ListViewItemEventHandler,
	onItemDoubleClick: ListViewItemEventHandler,
	onItemActivate: EventHandler,
}


ListViewColumn:: struct
{
	text: string,
	width: int,
	pLvc: ^LVCOLUMN,
	index: int,
	imageIndex: int,
	hasImage, imageOnRight: bool,
	alignment: ColumnAlignment,
	headerAlign: HeaderAlignment,
	_hdrTxtFlag: UINT,// For header text alignment
	_wideText: ^u16,

}

ListViewItem:: struct
{
	index: i32,
	text: string,
	backColor: Color,
	foreColor: Color,
	font: Font,
	imageIndex: int,
	checked: b32,
	subItems: [dynamic]string,
	_bgdraw: b32,
	_fgdraw: b32,

}

ListViewSubItem:: struct
{
	text: string,
	backColor: uint,
	foreColor: uint,
	font: Font,
}

// Create a new ListView struct
new_listview:: proc{lv_constructor1, 
					lv_constructor2, 
					lv_constructor3, 
					lv_constructor4, 
					lv_constructor5, 
					lv_constructor6, 
					lv_constructor7}

new_listview_column:: proc{lv_col_constructor1, lv_col_constructor2, lv_col_constructor3}

// Create new list view item.
new_listviewitem:: proc{listview_item_constructor1, listview_item_constructor2, listview_item_constructor3}

new_listviewcolumn_array:: proc(name_and_width: ..any) -> [dynamic]^ListViewColumn
{
	colnames: [dynamic]string
	colwidths: [dynamic]int
	defer delete(colnames)
	defer delete(colwidths)
	// Extracting column names and widths
	for item in name_and_width
	{
        if value, is_str:= item.(string) ; is_str { append(&colnames, value) }
        else if value, is_int:= item.(int) ; is_int { append(&colwidths, value) }
	}
	if len(colnames) == len(colwidths) // If they are same, we can proceed
	{
		result: [dynamic]^ListViewColumn
		for col, i in colnames
		{
			pCol:= new_listview_column(col, colwidths[i], ColumnAlignment.Center )
			append(&result, pCol)
		}
		return result
	}
	return nil
}

// Add a column to list view
listview_add_column:: proc{lv_addCol1, lv_addCol2, lv_addCol3}

// Add an item and sub items(if any) to list view.
listview_add_row:: proc{lv_addrow1}

// Add an item to list view
listview_add_item:: proc{lv_additem1, lv_additem2}

listview_add_items :: proc{lv_additems1, lv_additems2}


// Add a sub item to list view
listview_add_subitem:: proc{lv_add_subitem1, lv_add_subitem2, lv_add_subitem3}

listview_add_subitems:: proc{lv_add_subitems1, lv_add_subitems2, lv_add_subitems3}


// Set the column order of list view.
// Example - listview_set_column_order(lv, 2, 1, 0)
// This will set the column indices in the same order.
listview_set_column_order:: proc(lv: ListView, col_order: ..i32)
{
	// print("set col order")
	if lv._isCreated {
		SendMessage(lv.handle,
					 LVM_SETCOLUMNORDERARRAY,
					 cast(WPARAM) len(col_order),
					 dir_cast(raw_data(col_order), LPARAM))
	}
}

// Returns the column count of this list view
listview_get_coulmn_count:: proc (lv: ^ListView) -> int
{
	x:= cast(int) SendMessage(lv_get_header(lv.handle), 0x1200, 0, 0) // I don't know what is this 0x1200 means.
	return x
}

//Get list view's selected items. Works only if multi-selection enabled.
// NOTE: The caller must free the array with 'delete'
listview_get_selected_items :: proc(this: ^ListView) -> []^ListViewItem
{
	if this._isCreated {
		return nil
	}
	return nil
}

listview_set_style:: proc (lv: ^ListView, view: ListViewStyle)
{
	lv.viewStyle = view
	if lv._isCreated {
		SendMessage(lv.handle, LVM_SETVIEW, WPARAM(lv.viewStyle), 0)
	}
}

listview_begin_update:: proc (lv: ^ListView)
{
	wp_value: bool = false
	SendMessage(lv.handle, LV_WM_SETREDRAW, WPARAM(wp_value), 0)
}

listview_end_update:: proc (lv: ^ListView)
{
	wp_value: bool = true
	SendMessage(lv.handle, LV_WM_SETREDRAW, WPARAM(wp_value), 0)
}

listview_delete_item:: proc{lv_del_item1, lv_del_item2}

lv_del_item1:: proc (lv: ^ListView, item: ^ListViewItem)
{
	if lv._isCreated {
		SendMessage(lv.handle, LVM_DELETEITEM, WPARAM(i32(item.index)), 0)
		ordered_remove(&lv.items, item.index)
		free(item)
	}
}

lv_del_item2:: proc (lv: ^ListView, item_index: i32)
{
	if lv._isCreated {
		SendMessage(lv.handle, LVM_DELETEITEM, WPARAM(item_index), 0)
		indx:= -1
		for item in lv.items {
			indx += 1
			if item.index == item_index	do break
		}
		if indx > -1 {
			item:= lv.items[indx]
			ordered_remove(&lv.items, indx)
			free(item)
		}
	}
}

listview_delete_selected_item:: proc (lv: ^ListView )
{
	print("Not Implemented")
}

listview_clear_items:: proc (lv: ^ListView)
{
	print("Not Implemented")
}

listview_delete_column:: proc (lv: ^ListView)
{
	//LVM_DELETECOLUMN
	print("Not Implemented")
}

listview_get_item:: proc (lv: ^ListView)
{
	print("Not Implemented")
}

listview_get_row:: proc (lv: ^ListView) -> []string
{
	print("Not Implemented")
	 return nil
}

//=====================================Private Functions======================



@private lv_additem1 :: proc(this: ^ListView, lvi: ^ListViewItem)
{
	append(&this.items, lvi)
	if this.handle != nil do lv_add_item_internal(this, lvi)
}

@private lv_additem2 :: proc(this: ^ListView, itemText: any)
{
	sitem := to_str(itemText)
	lvi := new_listviewitem(sitem)
	append(&this.items, lvi)
	if this.handle != nil do lv_add_item_internal(this, lvi)	
}

@private lv_additems1 :: proc(this: ^ListView, itemTexts: ..any)
{
	if len(itemTexts) > 0 {
		for sitem in itemTexts {
			lvi := new_listviewitem(to_str(sitem))
			append(&this.items, lvi)
			if this.handle != nil do lv_add_item_internal(this, lvi)
		} 
	}	
}

@private lv_additems2 :: proc(this: ^ListView, pitems: ..^ListViewItem)
{
	if len(pitems) > 0 {
		for item in pitems {
			append(&this.items, item)
			if this.handle != nil do lv_add_item_internal(this, item)	
		} 
	}	
}

@private lv_add_subitem1 :: proc(this: ^ListView, item_indx: int, subitem: any, sub_indx: i32)
{
	if item_indx < 0 || item_indx > len(this.items) do return
	pitem := this.items[item_indx]
	sitem := to_str(subitem)
	append(&pitem.subItems, sitem)
	if this.handle != nil do lv_add_subitem_internal(this, pitem, sitem, sub_indx)
}

@private lv_add_subitem2 :: proc(this: ^ListView, pitem: ^ListViewItem, subitem: any, sub_indx: i32)
{
	sitem := to_str(subitem)
	append(&pitem.subItems, sitem)
	if this.handle != nil do lv_add_subitem_internal(this, pitem, sitem, sub_indx)
}

@private lv_add_subitem3 :: proc(this: ^ListView, itemText: string, subitem: any, sub_indx: i32)
{
	if len(this.items) > 0 {
		for &item in this.items {
			if item.text == itemText {
				sitem := to_str(subitem)
				append(&item.subItems, sitem)
				if this.handle != nil do lv_add_subitem_internal(this, item, sitem, sub_indx)
				break
			}
		}
	}
}

// Add a list of sub items to an item in list view
@private lv_add_subitems1 :: proc(this: ^ListView, item_indx: int, subitems: ..any)
{
	if this.viewStyle != ListViewStyle.Report do return
	if item_indx < 0 || item_indx > len(this.items) do return
	pitem := this.items[item_indx]
	for sitem in subitems {append(&pitem.subItems, to_str(sitem))}
	if this.handle != nil {
		sub_indx: i32 = 1
		for subitem in pitem.subItems {
			lv_add_subitem_internal(this, pitem, subitem, sub_indx)
			sub_indx += 1
		}
	}	
}

@private lv_add_subitems2 :: proc(this: ^ListView, pitem: ^ListViewItem, subitems: ..any)
{
	for sitem in subitems {append(&pitem.subItems, to_str(sitem))}
	if this.handle != nil {
		sub_indx: i32 = 1
		for subitem in pitem.subItems {
			lv_add_subitem_internal(this, pitem, subitem, sub_indx)
			sub_indx += 1
		}
	}	
}

@private lv_add_subitems3 :: proc(this: ^ListView, itemText: string, subitems: ..any)
{
	pitem : ^ListViewItem 
	if len(this.items) > 0 {
		for item in this.items {
			if item.text == itemText {
				pitem = item
				break
			}
		}
	}
	if pitem != nil {
		for sitem in subitems {append(&pitem.subItems, to_str(sitem))}
		if this.handle != nil {
			sub_indx: i32 = 1
			for subitem in pitem.subItems {
				lv_add_subitem_internal(this, pitem, subitem, sub_indx)
				sub_indx += 1
			}
		}	
	}	
}

//ListViewStyle:: enum {Normal, Report, }


/*----------------------------------------------------------------------------------------------------
											↓ ListView constructor ↓
*---------------------------------------------------------------------------------------------------*/

@private lv_constructor:: proc(f: ^Control, x, y, w, h: i32) -> ^ListView
{
	if lvcount == 0 {
        app.iccx.dwIcc = IccListViewClass
        InitCommonControlsEx(&app.iccx)
    }

	this:= new(ListView)
	this.kind = .List_View
	control_base_init(this, f, x, y, w, h, &_calCounter)
	this._createHandleProc = lv_create_handle
	this.viewStyle = .Report
	this.showGridLines = true
	this._hasFont = true
	//this.multiSelection = true
	this.fullRowSelect = true	
	this.headerClickable = true
	this.headerBackColor = 0xb3cccc
	this.headerForeColor = 0x000000
	this._hdrIndex = -1
	this.headerHeight = 25
	return this
}

@private lv_constructor1:: proc(parent: ^Control) -> ^ListView
{
	this := lv_constructor(parent, 10, 10, 200, 180)
	if this._ownerForm.createChilds do create_control(this)
	return this
}

@private lv_constructor2:: proc(parent: ^Control, x, y: i32) -> ^ListView {
	this:= lv_constructor(parent, x, y, 200, 180)
	if this._ownerForm.createChilds do create_control(this)
	return this
}

@private lv_constructor3:: proc(parent: ^Control, x, y, w, h: i32) -> ^ListView
{
	this:= lv_constructor(parent, x, y, w, h)
	if this._ownerForm.createChilds do create_control(this)
	return this
}

@private lv_constructor4:: proc(parent: ^Control, x, y, w, h: i32, colnames: ..string) -> ^ListView
{
	this := lv_constructor(parent, x, y, w, h)
	if this._ownerForm.createChilds do create_control(this)
	for col in colnames {
		pCol:= new_listview_column(col, set_coloumn_autosize(this, col))
		listview_add_column(this, pCol)
	}	
	return this
}

@private lv_constructor5:: proc(parent: ^Control, x, y, w, h: i32, colnames: []string, widths: []int) -> ^ListView
{
	this:= lv_constructor(parent, x, y, w, h)
	if this._ownerForm.createChilds do create_control(this)
	if len(colnames) == len(widths)	{
		for col, width in colnames {
			pCol:= new_listview_column(col, widths[width])
			listview_add_column(this, pCol)
		}
	}
	// create_control(lv)
	return this
}

@private lv_constructor6:: proc(parent: ^Control, x, y, w, h: i32, coldata: ..any) -> ^ListView
{
	this:= lv_constructor(parent, x, y, w, h)
	if this._ownerForm.createChilds do create_control(this)
	colnames: [dynamic]string
	colwidths: [dynamic]int
	defer {
		delete(colnames)
		delete(colwidths)
	}
	// Extracting column names and widths
	for item in coldata {
        if value, is_str:= item.(string) ; is_str { append(&colnames, value) } // LEAK
        else if value, is_int:= item.(int) ; is_int { append(&colwidths, value) } // LEAK
	}
	if len(colnames) == len(colwidths) {// If they are same, we can proceed
		for col, i in colnames {
			pCol:= new_listview_column(col, colwidths[i])
			listview_add_column(this, pCol)
		}
	}
	return this
}

@private lv_constructor7:: proc(parent: ^Control, x, y, w, h: i32, cols: []^ListViewColumn) -> ^ListView
{
	this:= lv_constructor(parent, x, y, w, h)
	if this._ownerForm.createChilds do create_control(this)
	for pCol in cols { listview_add_column(this, pCol) }
	return this
}

@private lv_create_handle :: proc(ctl: ^Control)
{
	this := cast(^ListView)ctl
	lv_adjust_styles(this)
	this._hdrBkBrush = create_hbrush(this.headerBackColor)
	this._hdrHotBrush = CreateSolidBrush(change_color(this.headerBackColor, 1.12))
	this._bgcRef = get_color_ref(this.backColor)
	this._fgcRef = get_color_ref(this.foreColor)
	this._divPen = CreatePen(PS_SOLID, 1, 0x00FFFFFF)	
	create_control(ctl, this.width, this.height)

	set_subclass(this, lv_wnd_proc)
    lv_set_extended_styles(this)
	if this.viewStyle == .Tile {
		SendMessage(this.handle, LVM_SETVIEW, WPARAM(0x0004), 0)
	}
	if this._imgList.handle != nil {	// We need to set the image list to list view.
		SendMessage(this.handle,
					LVM_SETIMAGELIST,
					cast(WPARAM) this._imgList.imageType,
					dir_cast(this._imgList.handle, LPARAM))
	}

	// Let's collect the header handle and subclass it.
	this._hdrHwnd = HWND(cast(UINT_PTR) SendMessage(this.handle, LVM_GETHEADER, 0, 0))
	api.SetWindowSubclass(this._hdrHwnd, 
						  SUBCLASSPROC(hdr_wnd_proc), 
						  UINT_PTR(globalSubClassID), 
						  to_dwptr(this))
	globalSubClassID += 1	

	// Insert columns if any
	if len(this.columns) > 0 {
		for col in this.columns {lv_addcolumn_internal(this, col)}		
	}

	// Insert items if any
	if len(this.items) > 0 {
		for item in this.items {lv_add_item_internal(this, item)}		
	}
}


/*------------------------------------------------------------------------------------------------------------
										↓ ListViewColumn constructor ↓
*-------------------------------------------------------------------------------------------------------------*/

@private lv_col_constructor1:: proc(txt: string, width: int ) -> ^ListViewColumn
{
	lvc:= new(ListViewColumn)
	lvc.text = txt
	lvc.width = width
	lvc.hasImage = false
	lvc.imageOnRight =false
	lvc.imageIndex = -1
	lvc.alignment = .Center
	lvc._hdrTxtFlag = DEF_HDR_TXT_FLAG
	lvc._wideText = to_wchar_ptr(txt, context.allocator)
	//lvc.position = pos
	return lvc
}

@private lv_col_constructor2:: proc(txt: string ) -> ^ListViewColumn
{
	lvc:= new(ListViewColumn)
	lvc.text = txt
	lvc.width = 100
	lvc.hasImage = false
	lvc.imageOnRight =false
	lvc.imageIndex = -1
	lvc.alignment = .Center
	lvc._hdrTxtFlag = DEF_HDR_TXT_FLAG
	lvc._wideText = to_wchar_ptr(txt, context.allocator)
	//lvc.position = pos
	return lvc
}

@private lv_col_constructor3:: proc(txt: string, width: int, col_align: ColumnAlignment = .Left,
							hdr_align: HeaderAlignment = .Center  ) -> ^ListViewColumn
{
	lvc:= new(ListViewColumn)
	lvc.text = txt
	lvc.width = width
	lvc.hasImage = false
	lvc.imageOnRight =false
	lvc.imageIndex = -1
	lvc.alignment = col_align
	lvc.headerAlign = hdr_align
	set_hdr_text_flag(lvc)
	lvc._wideText = to_wchar_ptr(txt, context.allocator)
	//lvc.position = pos
	return lvc
}

@private lv_col_finalize:: proc(this: ^ListViewColumn) 
{
	free(this._wideText)
	free(this)
}

/*------------------------------------------------------------------------------------------------------------
										↓  ListViewItem constructor ↓
*-----------------------------------------------------------------------------------------------------------*/


@private lv_item_constructor:: proc(txt: string, bgc: uint, fgc: uint, img: int = -1) -> ^ListViewItem
{
	lvi:= new(ListViewItem)
	lvi.backColor = new_color(bgc)
	lvi.foreColor = new_color(fgc)
	lvi.text = txt
	lvi.imageIndex = img
	if bgc != 0xFFFFFF do lvi._bgdraw = true
	if fgc != 0x000000 do lvi._fgdraw = true
	return lvi
}

@private listview_item_constructor1:: proc(txt: string) -> ^ListViewItem
{
	lvi:= lv_item_constructor(txt, white, black)
	return lvi
}

@private listview_item_constructor2:: proc(txt: string, bk_clr, fr_clr: uint) -> ^ListViewItem
{
	lvi:= lv_item_constructor(txt, bk_clr, fr_clr)
	return lvi
}

@private listview_item_constructor3:: proc(txt: string, img: int) -> ^ListViewItem
{
	lvi:= lv_item_constructor(txt, white, black, img)
	return lvi
}

@private lvitem_dtor :: proc(this: ^ListViewItem) 
{
	if len(this.subItems) > 0 do delete(this.subItems)
	free(this)
}


/*-------------------------------------------------------------------------------------------------------
*									↓ ListView Add Coulmn functions ↓
*--------------------------------------------------------------------------------------------------------*/


@private lv_addCol1:: proc(this: ^ListView, txt: string, width: int,
								img: bool = false, imgOnRight: bool = false)
{
	// If hwnd is created, we add the column to lv, otherwise,...
	// We will do the deferred execution.
	lvc:= new(ListViewColumn)
	lvc.text = txt
	lvc.width = width
	lvc.hasImage = img
	lvc.imageOnRight =imgOnRight
	lvc.imageIndex = -1
	lvc.index = int(this._colIndex)
	this._colIndex += 1
	set_hdr_text_flag(lvc)
	lvc._wideText = to_wchar_ptr(txt, context.allocator)
	append(&this.columns, lvc) 
	if this.handle != nil do lv_addcolumn_internal(this, lvc)
}

@private lv_addCol2:: proc(this: ^ListView, lvc: ^ListViewColumn)
{
	lvc.index = int(this._colIndex)
	if lvc.headerAlign != .Center do set_hdr_text_flag(lvc)
	this._colIndex += 1
	append(&this.columns, lvc) // Keeping the object for deferred execution.
	if this.handle != nil do lv_addcolumn_internal(this, lvc)
}

@private lv_addCol3:: proc(this: ^ListView, txt: string, width: int, align: ColumnAlignment)
{
	lvc:= new(ListViewColumn)
	lvc.text = txt
	lvc.width = width
	lvc.hasImage = false
	lvc.imageOnRight = false
	lvc.index = int(this._colIndex)
	lvc.imageIndex = -1
	lvc.alignment = align
	this._colIndex += 1
	lvc._hdrTxtFlag = DEF_HDR_TXT_FLAG
	lvc._wideText = to_wchar_ptr(txt, context.allocator)
	append(&this.columns, lvc) // Keeping the object for deferred execution.
	if this.handle != nil do lv_addcolumn_internal(this, lvc)
}

// Here is the actual add column work happening.
@private lv_addcolumn_internal:: proc(lv: ^ListView, lvCol: ^ListViewColumn)
{
	if lv.handle == nil {
		print("Cannot add column in list view, ListView handle is nil.")
		return
	}
	lvc: LVCOLUMN
	lvc.mask = LVCF_FMT | LVCF_TEXT | LVCF_WIDTH | LVCF_SUBITEM
	lvc.fmt = cast(i32) lvCol.alignment
	lvc.cx = i32((lvCol^).width)
	lvc.pszText = lvCol._wideText

	if lvCol.hasImage {
		lvc.mask |= LVCF_IMAGE
		lvc.fmt |= LVCFMT_COL_HAS_IMAGES | LVCFMT_IMAGE
		lvc.iImage = i32(lvCol.imageIndex)
	}

	if lvCol.imageOnRight do lvc.fmt |= LVCFMT_BITMAP_ON_RIGHT
	SendMessage(lv.handle, LVM_INSERTCOLUMNW, WPARAM(lvCol.index), dir_cast(&lvc, LPARAM))	
	// append(&lv.columns, lvCol)
}

@private lv_add_item_internal :: proc(this: ^ListView, pitem: ^ListViewItem)
{
	lvitem: LVITEM	
	lvitem.mask = LVIF_TEXT | LVIF_PARAM | LVIF_STATE
	if pitem.imageIndex > -1 do lvitem.mask |= LVIF_IMAGE
	lvitem.state = 0
	lvitem.stateMask = 0
	lvitem.iItem = this._index
	lvitem.iSubItem = 0	
	lvitem.iImage = cast(i32) pitem.imageIndex
	lvitem.pszText = to_wstring(pitem.text)
	lvitem.cchTextMax = i32(len(pitem.text))
	lvitem.lParam = dir_cast(pitem, LPARAM)
	pitem.index = this._index

	SendMessage(this.handle, LVM_INSERTITEMW, 0, dir_cast(&lvitem, LPARAM))

	this._index += 1
	if len(pitem.subItems) > 0 {
		for sitem, index in pitem.subItems{
			lvi: LVITEM
			lvi.iSubItem = i32(index + 1)
			lvi.pszText = to_wstring(sitem)
			iIndx:= i32(pitem.index)
			x := SendMessage(this.handle, LVM_SETITEMTEXT, WPARAM(iIndx), dir_cast(&lvi, LPARAM))
			if x == 0 do ptf("Can't add sub item '%s', Error: %d", sitem, GetLastError())
		}
	}	
}

@private lv_addrow1:: proc(this: ^ListView, items: ..any, )
{
	if this.viewStyle != ListViewStyle.Report do return
	iLen:= len(items)
	if iLen > 0 {
		fitem := to_str(items[0])
		lvItem:= listview_item_constructor1(fitem)
		if iLen > 1 do reserve(&lvItem.subItems, iLen - 1)
		for i :=1; i < iLen; i += 1 {
			append(&lvItem.subItems, to_str(items[i]))			
		}
		append(&this.items, lvItem)
		if this.handle != nil do lv_add_item_internal(this, lvItem)		
	}
}

@private lv_add_subitem_internal :: proc(this: ^ListView, pitem: ^ListViewItem, subitem: string, sub_indx: i32)
{
	lvi: LVITEM
	lvi.iSubItem = sub_indx
	lvi.pszText = to_wstring(subitem)
	iIndx:= pitem.index
	SendMessage(this.handle, LVM_SETITEMTEXT, WPARAM(iIndx), dir_cast(&lvi, LPARAM) )
}


@private lv_get_header:: proc(lvh: HWND) -> HWND {return cast(HWND) cast(UINT_PTR) SendMessage(lvh, LVM_GETHEADER, 0, 0)}

@private lv_adjust_styles:: proc(lv: ^ListView) 
{
	#partial switch lv.viewStyle {
		case .Large_Icon:
			lv._style |= LVS_ICON
		case .Report:
			lv._style |= LVS_REPORT
		case .Small_Icon:
			lv._style |= LVS_SMALLICON
		case .List:
			lv._style |= LVS_LIST
	}

	if lv.editLabel do lv._style |= LVS_EDITLABELS
	if !lv.hideSelection do lv._style |= LVS_SHOWSELALWAYS
	if lv.noHeader do lv._style |= LVS_NOCOLUMNHEADER
}

@private lv_set_extended_styles:: proc(lv: ^ListView) 
{
	lxs: DWORD
	if lv.showGridLines do lxs |= LVS_EX_GRIDLINES
	if lv.hasCheckBoxes do lxs |= LVS_EX_CHECKBOXES
	if lv.fullRowSelect do lxs |= LVS_EX_FULLROWSELECT
	if lv.oneClickActivate do lxs |= LVS_EX_ONECLICKACTIVATE
	if lv.hotTrackSelect do lxs |= LVS_EX_TRACKSELECT

	SendMessage(lv.handle, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LPARAM(lxs) )
}

@private set_hdr_text_flag:: proc(lvc: ^ListViewColumn) 
{
	// print("worked")
	if lvc.headerAlign == .Left {
		lvc._hdrTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_LEFT | DT_NOPREFIX
	} else if lvc.headerAlign == .Right {
		lvc._hdrTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_RIGHT | DT_NOPREFIX
	} else {
		lvc._hdrTxtFlag = DEF_HDR_TXT_FLAG
	}
}

@private draw_divider:: proc(pen: HPEN, hdc: HDC, xp, yp, y2: i32) 
{
	SelectObject(hdc, HGDIOBJ(pen))
	MoveToEx(hdc, xp, yp, nil)
	LineTo(hdc, xp, y2)
}

@private draw_header:: proc(lv: ^ListView, nmcd: ^NMCUSTOMDRAW) -> LRESULT
{
	if len(lv.columns) > 0 	{
		// ptf("nmcd size %d\n", size_of(NMCUSTOMDRAW))
		hd_index:= cast(i32)nmcd.dwItemSpec
		col:= lv.columns[hd_index]
		// print("hdr drawing started ", col.width, hd_index)
		
		if col.index > 0 do nmcd.rc.left += 1
		if lv.headerClickable {

			if (nmcd.uItemState & CDIS_SELECTED) == CDIS_SELECTED {
				// Header is clicked. So we will change the back color.
				api.FillRect(nmcd.hdc, &nmcd.rc, lv._hdrBkBrush)
			} else {
				if hd_index == lv._hdrIndex {
					// Mouse pointer is on header. So we will change the back color.
					api.FillRect(nmcd.hdc, &nmcd.rc, lv._hdrHotBrush)
				} else {
					
					api.FillRect(nmcd.hdc, &nmcd.rc, lv._hdrBkBrush)
				}
			}

			if (nmcd.uItemState & CDIS_SELECTED) == CDIS_SELECTED {
				/* Here we are mimicing dot net's same technique.
					* We will change the rect's left and top a little bit when header got clicked.
					* So user will feel the header is pressed. */
				nmcd.rc.left += 2;
				nmcd.rc.top += 2;
			}
		} else {
			api.FillRect(nmcd.hdc, &nmcd.rc, lv._hdrBkBrush);
		}

		// SelectObject(nmcd.hdc, this.mHdrFont.handle);
		// SetTextColor(nmcd.hdc, get_color_ref(lv.headerForeColor))
		// coltxt:= to_wstring(col.text)
		draw_divider(lv._divPen, nmcd.hdc, nmcd.rc.right, nmcd.rc.top, nmcd.rc.bottom)
		api.SetBkMode(nmcd.hdc, api.BKMODE.TRANSPARENT) // TRANSPARENT
		nmcd.rc.left += 3 // We need some room on the left side
		DrawText(nmcd.hdc, col._wideText, -1, &nmcd.rc, col._hdrTxtFlag)
		return CDRF_SKIPDEFAULT
	}
	else {
		api.FillRect(nmcd.hdc, &nmcd.rc, lv._hdrBkBrush);
	}
	return CDRF_DODEFAULT
}

@private set_coloumn_autosize:: proc(lv: ^ListView, colname: string) -> int
{
	txtlen:= i32(len(colname))
	ss: SIZE
	hdc: HDC = GetDC(lv.handle)
    defer ReleaseDC(lv.handle, hdc)
    SelectObject(hdc, HGDIOBJ(lv.font.handle))
    GetTextExtentPoint32(hdc, to_wstring(colname), txtlen, &ss)
	//defer // free_all(context.temp_allocator)
    return int(ss.cx + 10)
}


@private listview_property_setter:: proc(this: ^ListView, prop: ListViewProps, value: $T)
{
	switch prop {
		case .Item_Alignment: break
		case .Column_Alignment: break
		case .View_Style: break
		case .Hide_Selection: break
		case .Multi_Selection: break
		case .Has_Check_Boxes: break
		case .Full_Row_Select: break
		case .Show_Grid_Lines: break
		case .One_Click_Activate: break
		case .No_Track_Select: break
		case .Edit_Label: break
		case .No_Header: break
		case .Header_Back_Color: break
		case .Header_Height: break
		case .Header_Clickable: break
	}
}

@private lv_finalize:: proc(this: ^ListView) 
{
	delete_gdi_object(this._divPen)	
	if this._imgList.handle != nil do ImageList_Destroy(this._imgList.handle)
	if this._hdrBkBrush != nil do delete_gdi_object(this._hdrBkBrush)
	if this._hdrHotBrush != nil do delete_gdi_object(this._hdrHotBrush)
    for pcol in this.columns {lv_col_finalize(pcol)}
    // for pitem in this.items	 {free(pitem)}
	if len(this.items) > 0 {
		for item in this.items {lvitem_dtor(item)}
	}
    delete(this.items)
	delete(this.columns)
	delete(this.selectedItems)
	control_base_dtor(this)
    free(this)

}

@private lv_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
												sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT 
{
	context = global_context  
	this := control_cast(ListView, ref_data)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
	
	// display_msg(msg)
	switch msg {
	case WM_NCDESTROY: 
		RemoveWindowSubclass(this.handle, lv_wnd_proc, sc_id)
		lv_finalize(this)

	case WM_SETFOCUS: 
		ctrl_setfocus_handler(this)

	case WM_KILLFOCUS: 
		ctrl_killfocus_handler(this)

	case CM_NOTIFY: // Re-routed from parent
		nmh:= dir_cast(lp, ^NMHDR)
		switch nmh.code {
			case NM_CUSTOMDRAW:
				lvcd:= dir_cast(lp, ^NMLVCUSTOMDRAW)
				switch lvcd.nmcd.dwDrawStage {
				case CDDS_PREPAINT:
					return CDRF_NOTIFYITEMDRAW
				case CDDS_ITEMPREPAINT:
					pitem := this.items[lvcd.nmcd.dwItemSpec]
					if pitem._bgdraw do lvcd.clrTextBk = pitem.backColor.ref
					if pitem._fgdraw do lvcd.clrText = pitem.foreColor.ref
					// print("iSubItem ", lvcd.nmcd.dwItemSpec)
					return CDRF_NEWFONT | CDRF_DODEFAULT
				}
				return CDRF_DODEFAULT

			case NM_CLICK:
				if this.onItemClick != nil && len(this.items) > 0 { 
                    nmia := dir_cast(lp, ^NMITEMACTIVATE)
                    sitem := this.items[nmia.iItem]
					lviea := LVItemEventArgs{item = sitem}
                    this.onItemClick(this, &lviea)
				}
			case NM_DBLCLK:
				if this.onItemDoubleClick != nil && len(this.items) > 0 { 
					nmia := dir_cast(lp, ^NMITEMACTIVATE)
					sitem := this.items[nmia.iItem]
					lviea := LVItemEventArgs{item = sitem}
					this.onItemDoubleClick(this, &lviea)
				}

			case LVN_ITEMCHANGED:
				nmlv:= dir_cast(lp, ^NMLISTVIEW)
				if (nmlv.uChanged & LVIF_STATE) != 0 {
					nowSelected : b32 = (nmlv.uNewState & LVIS_SELECTED) != 0
                    wasSelected : b32 = (nmlv.uOldState & LVIS_SELECTED) != 0
                    if (nowSelected && !wasSelected) {
						sitem := this.items[nmlv.iItem]
						if this.multiSelection {
							append(&this.selectedItems, sitem)
						} else {
							this.selectedItem = sitem
						}   
						if this.onSelectionChanged != nil {
							lsea := LVSelChangedEventArgs{item = sitem, 
														   index = nmlv.iItem, 
														   isSelected = nowSelected}
							this.onSelectionChanged(this, &lsea)
						}

                    } else if !nowSelected && wasSelected {
						sitem := this.items[nmlv.iItem]
                        if this.multiSelection {
                            ordered_remove(&this.selectedItems, sitem.index)
							if this.onSelectionChanged != nil {
								lsea := LVSelChangedEventArgs{item = sitem, 
														   index = nmlv.iItem, 
														   isSelected = nowSelected}
								this.onSelectionChanged(this, &lsea)
							}
						}
					}
					// ✅ Check for checkbox state change
					state_index := (nmlv.uNewState & LVIS_STATEIMAGEMASK) >> 12
					old_state_index := (nmlv.uOldState & LVIS_STATEIMAGEMASK) >> 12

					if state_index != old_state_index { // Item checkbox changed
						is_checked : b32 = (state_index == 2) // 2 = checked, 1 = unchecked
						if len(this.items) > 0{                             
                            sitem := this.items[nmlv.iItem]                                
							sitem.checked = is_checked  
							if this.onItemCheckChanged != nil {
								licea := LVItemCheckEventArgs{item = sitem, 
															  index = nmlv.iItem, 
															  isChecked = is_checked}
								this.onItemCheckChanged(this, &licea)
							}
						}
					}
				}
			case LVN_ITEMACTIVATE:
                if this.onItemActivate != nil do this.onItemActivate(this, &gea)
		}

	case WM_NOTIFY: // From our child
		// Message from header.
		nmh:= dir_cast(lp, ^NMHDR)
		switch nmh.code {
		case NM_CUSTOMDRAW:  // Let's draw header back & fore colors
			nmcd:= dir_cast(lp, ^NMCUSTOMDRAW)
			switch nmcd.dwDrawStage {
			case CDDS_PREPAINT:
				return CDRF_NOTIFYITEMDRAW
			case CDDS_ITEMPREPAINT:
				// print("hdr item prepaint ")
				return draw_header(this, nmcd)
				// return CDRF_SKIPDEFAULT
			}
		}
	}
	return DefSubclassProc(hw, msg, wp, lp)
}

@private hdr_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
												sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT 
{
	context = global_context //
	this := control_cast(ListView, ref_data)
	
	// display_msg(msg)
	switch msg {
		case WM_NCDESTROY:
			RemoveWindowSubclass(hw, hdr_wnd_proc, UINT_PTR(sc_id) )

		case WM_MOUSEMOVE:
			hti: HDHITTESTINFO
			hti.pt = get_mouse_points(lp)
			this._hdrIndex = i32(SendMessage(hw, HDM_HITTEST, 0, dir_cast(&hti, LPARAM)))

		case WM_MOUSELEAVE:
			this._hdrIndex = -1

		case HDM_LAYOUT:
			// ptf("hd layout %d\n", size_of(HD_LAYOUT))
			phl:= dir_cast(lp, ^HD_LAYOUT)
			res:= DefSubclassProc(hw, msg, wp, lp)
			phl.pwpos.cy = i32(this.headerHeight)
			return res

		case WM_PAINT:
			DefSubclassProc(hw, msg, wp, lp)
			hrc: RECT
			SendMessage(hw, HDM_GETITEMRECT, WPARAM(len(this.columns) - 1), dir_cast(&hrc, LPARAM))
			rc: RECT = {hrc.right + 1, hrc.top, i32(this.width), hrc.bottom}
			hdc: HDC = GetDC(hw)
			api.FillRect(hdc, &rc, this._hdrBkBrush)
			ReleaseDC(hw, hdc)
			return 0

	}
	return DefSubclassProc(hw, msg, wp, lp)
}