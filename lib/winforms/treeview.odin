
/*
    Created on: 06-Feb-2022 7:36:35 PM
    Name: TreeView type
*/

/*===========================================TreeView Docs=========================================================
    TreeView struct
        Constructor: new_treeview() -> ^TreeView
        Properties:
            All props from Control struct
            noLines       : bool
            noButtons     : bool
            hasCheckBoxes : bool
            fullRowSelect : bool
            editable      : bool
            showSelection : bool
            hotTracking   : bool
            selectedNode  : ^TreeNode
            nodes         : [dynamic]^TreeNode
            imageList     : HIMAGELIST
            lineColor     : uint
        Functions:
			new_treenode
            treeview_expand_all
            treeview_collapse_all
            treeview_expand_node
            treeview_collapse_node
            treeview_add_node
            treeview_add_nodes
            treeview_insert_node
            treeview_add_child_node
            treeview_add_childnodes
            treeview_insert_child_node
            treeview_delete_node
            treeview_set_node_color
            treeview_set_line_color
            treeview_set_image_list
            treeview_create_image_list

        Events:
			All events from Control struct
            EventHandler type [proc(^Control, ^EventARgs)]
                onBeginEdit
                onEndEdit
                onNodeDeleted
            TreeEventHandler type [proc(^Control, ^TreeEventARgs)]
                onBeforeChecked
                onAfterChecked
                onBeforeSelect
                onAfterSelect
                onBeforeExpand
                onAfterExpand
                onBeforeCollapse
                onAfterCollapse
               
==============================================================================================================*/


package winforms

import "base:runtime"
//import "core:slice"
//import "core:fmt"

g_node_id: int = 100

_tvcount: int = 1
TV_STYLE : u32 = WS_BORDER | TVS_HASLINES | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_DISABLEDRAGDROP

TreeNodeArray:: distinct ^[dynamic]^TreeNode
NodeDisposeHandler:: proc(node: ^TreeNode)
NodeNotifyHandler:: proc(node: ^TreeNode)

TreeView:: struct
{
    using control: Control,
    noLines: bool,
    noButtons: bool,
    hasCheckBoxes: bool,
    fullRowSelect: bool,
    editable: bool,
    showSelection: bool,
    hotTracking: bool,
    selectedNode: ^TreeNode,
    nodes: [dynamic]^TreeNode,
    imageList: HIMAGELIST,
    lineColor: uint,

    _lastItemHwnd: HTREEITEM,
    _itemCount: int,
    _uniqItemID: int,
    _nodeChecked: bool,
    _nodeClrChange: bool,
    _suppressNotify: bool,

    
    onNodeDeleted: EventHandler,
    onBeginEdit,
    onEndEdit,  
    onEditCancelled,
    onBeforeChecked,
    onAfterChecked,
    onBeforeSelect,
    onAfterSelect,
    onBeforeExpand,
    onAfterExpand,
    onBeforeCollapse,
    onAfterCollapse: TreeEventHandler,
}

TreeNode:: struct
{
    handle: HTREEITEM,
    parentNode: ^TreeNode,
    imageIndex: int,
    selImageIndex: int,
    childCount: int,
    text: string,
    nodes: [dynamic]^TreeNode,
    checked: bool,
    foreColor: uint,
    backColor: uint,
    _dispose: NodeDisposeHandler,
    _isCreated: bool,
    _treeHwnd: HWND,
    _insAfter: HTREEITEM,
    _nodeOp: NodeOpMode,
    _index: int,
    _nodeID: int,
    _nodeCount: int,
    _insPos: int
}

// Create new treeview
new_treeview:: proc{new_tv1, new_tv2, new_tv3}

// Create new tree view node.
new_treenode:: proc{node_ctor1, node_ctor2, node_ctor3, node_ctor4}

// Expland all tree nodes
treeview_expand_all:: proc(tv: ^TreeView)
{
    for node in tv.nodes {
        SendMessage(tv.handle, CM_TVNODEEXPAND, WPARAM(TVE_EXPAND), dir_cast(node, LPARAM))
    }
}

// Collapse all tree nodes
treeview_collapse_all:: proc(tv: ^TreeView)
{
    for node in tv.nodes {
        SendMessage(tv.handle, CM_TVNODEEXPAND, WPARAM(TVE_COLLAPSE), dir_cast(node, LPARAM))
    }
}

// Expand the given node
treeview_expand_node:: proc(tv: ^TreeView, node: ^TreeNode)
{
    SendMessage(tv.handle, CM_TVNODEEXPAND, WPARAM(TVE_EXPAND), dir_cast(node, LPARAM))
}

// Collapse the given node
treeview_collapse_node:: proc(tv: ^TreeView, node: ^TreeNode)
{
    SendMessage(tv.handle, CM_TVNODEEXPAND, WPARAM(TVE_COLLAPSE), dir_cast(node, LPARAM))
}

// Add a new root node to tree view.
treeview_add_node:: proc{tv_addnode1, tv_addnode2}

// Add the given root nodes into treeview.
treeview_add_nodes:: proc{tv_add_nodes1, tv_add_nodes2}

treeview_add_node_with_children :: proc{tv_addnode_with_children1}

// Inserts given root node to given index.
treeview_insert_node:: proc{tv_insert_node1, tv_insert_node2}


// Add a child node to given parent node.
treeview_add_child_node:: proc{tv_add_childnode1, tv_add_childnode2}


// Add given child nodes to given parent node.
treeview_add_childnodes:: proc{tv_add_child_nodes1,
                                tv_add_child_nodes2,
                                tv_add_child_nodes3}

// Iserts a child node to given parent node at given index
treeview_insert_child_node:: proc{tv_insert_childnode1, tv_insert_childnode2}


// Delete a node from treeview
treeview_delete_node:: proc(tv: ^TreeView, node: ^TreeNode)
{
    //indx: int
    if node.parentNode == nil {  // it's a top level node
        SendMessage(tv.handle, TVM_DELETEITEM, 0, dir_cast(node.handle, LPARAM))
        indx, _:= find_index(tv.nodes, node.handle )
        node._dispose(node)
        ordered_remove(&tv.nodes, indx) }
    else {   // It's a child node.
        SendMessage(tv.handle, TVM_DELETEITEM, 0, dir_cast(node.handle, LPARAM))
        indx, _:= find_index(node.parentNode.nodes, node.handle )
        node._dispose(node)
        ordered_remove(&node.parentNode.nodes, indx)
    }
}

// Apply colors to TreeNode
treeview_set_node_color:: proc(tv: ^TreeView, node: ^TreeNode)
{
    tv._nodeClrChange = true
    if tv._isCreated do InvalidateRect(tv.handle, nil, true)
}

treeview_set_line_color:: proc(tv: ^TreeView, clr: uint)
{
    if tv._isCreated {
        tv.lineColor = clr
        cref:= get_color_ref(tv.lineColor)
        SendMessage(tv.handle, TVM_SETLINECOLOR, 0, dir_cast(cref, LPARAM) )
    }
}

// Set an image list for tree view
treeview_set_image_list:: proc(tv: ^TreeView, himl: HIMAGELIST)
{
    SendMessage(tv.handle, TVM_SETIMAGELIST, 0, dir_cast(himl, LPARAM))// TVSIL_NORMAL = 0
}

treeview_create_image_list:: proc(tv: ^TreeView, nImg: int, ico_size: int = 16)
{
    isize:= i32(ico_size)
    tv.imageList = ImageList_Create(isize, isize, TVIML_FLAG, i32(nImg), 0 )
    SendMessage(tv.handle, TVM_SETIMAGELIST, 0, dir_cast(tv.imageList, LPARAM))
}

// Prepare for editing the node text. TreeView's editable property must be true. 
treenode_begin_edit :: proc(this: ^TreeNode) 
{
    SendMessage(this._treeHwnd, TVM_EDITLABELW, 0, cast(LPARAM) cast(uintptr) this.handle)
}
// ======================================Private Functions=======================================

@private tv_ctor:: proc(f: ^Control, x, y, w, h: i32) -> ^TreeView
{
    if _tvcount == 1 {
        app.iccx.dwIcc = ICC_TREEVIEW_CLASSES
        InitCommonControlsEx(&app.iccx)
    }
    this:= new(TreeView)
    this.kind = .Tree_View
    control_base_init(this, f, x, y, w, h, &_tvcount)
    this._createHandleProc = tv_create_handle
    this._uniqItemID = 100
    this.lineColor = app.clrBlack
    return this
}

@private new_tv1:: proc(parent: ^Control) -> ^TreeView
{
    this := tv_ctor(parent, 10, 10, 200, 250)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tv2:: proc(parent: ^Control, x, y: i32) -> ^TreeView
{
    this := tv_ctor(parent, x, y, 200, 250)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private new_tv3:: proc(parent: ^Control, x, y, w, h: i32) -> ^TreeView
{
    this := tv_ctor(parent, x, y, w, h)
    if this._ownerForm.createChilds do create_control(this)
    return this
}

@private tv_create_handle :: proc(ctl: ^Control)
{
	this := cast(^TreeView)ctl
    ptf("editable %t", this.editable)
	tv_adjust_styles(this)	
	create_control(ctl, this.width, this.height)
	set_subclass(this, tv_wnd_proc)
    setfont_internal(this)
    if this.backColor != app.clrWhite {
        cref:= get_color_ref(this.backColor)
        SendMessage(this.handle, TVM_SETBKCOLOR, 0, dir_cast(cref, LPARAM) )
    }
    if this.foreColor != app.clrBlack {
        cref:= get_color_ref(this.foreColor)
        SendMessage(this.handle, TVM_SETTEXTCOLOR, 0, dir_cast(cref, LPARAM) )
    }
    if this.lineColor != app.clrBlack  {
        cref:= get_color_ref(this.lineColor)
        SendMessage(this.handle, TVM_SETLINECOLOR, 0, dir_cast(cref, LPARAM) )
    }	
    
    if len(this.nodes) > 0 {
        for node in this.nodes {tv_insert_items_internal(this, node)}
    }
}

@private treenode_ctor:: proc(txt: string, img: int = -1, simg: int = -1,
                                 fclr: uint = def_fore_clr, bk_clr: uint = def_back_clr) -> ^TreeNode
{
    tn:= new(TreeNode)
    tn.imageIndex = img
    tn.selImageIndex = simg
    tn.text = txt
    tn._dispose = dispose_node
    tn.foreColor = fclr
    tn.backColor = bk_clr
    tn._insPos = -1
    return tn
}

@private node_ctor1:: proc(txt: string) -> ^TreeNode { return treenode_ctor(txt)}

@private node_ctor2:: proc(txt: string, img_indx, sel_img_indx: int) -> ^TreeNode
{
    return treenode_ctor(txt, img_indx, sel_img_indx)
}

@private node_ctor3:: proc(txt: string, txt_clr: uint, back_clr: uint = def_back_clr) -> ^TreeNode
{
    return treenode_ctor(txt, -1, -1, txt_clr, back_clr)
}

@private node_ctor4:: proc(txt: string, img_indx: int, sel_img_indx: int,
                            txt_clr: uint, back_clr: uint = def_back_clr) -> ^TreeNode
{
    return treenode_ctor(txt, img_indx, sel_img_indx, txt_clr, back_clr)
}

@private tv_addnode1 :: proc(this: ^TreeView, node: ^TreeNode)
{
    node._index = this._itemCount
    node._nodeOp = .Add_Node
    node._insAfter = TVI_LAST
    append(&this.nodes, node)
    this._itemCount += 1
    if this.handle != nil do tv_addnode_internal(this, node)
}

@private tv_addnode2 :: proc(this: ^TreeView, nodeText: any)
{
    node := new_treenode(to_str(nodeText))
    node._nodeOp = .Add_Node
    node._insAfter = TVI_LAST
    node._index = this._itemCount
    append(&this.nodes, node)
    this._itemCount += 1
    if this.handle != nil do tv_addnode_internal(this, node)
}

@private tv_addnode_with_children1 :: proc(this: ^TreeView, items: ..any)
{
    if len(items) == 0 do return
    pnode := new_treenode(to_str(items[0]))
    pnode._nodeOp = .Add_Node
    pnode._insAfter = TVI_LAST
    pnode._index = this._itemCount
    this._itemCount += 1
    if this.handle != nil do tv_addnode_internal(this, pnode)
    append(&this.nodes, pnode)

    for i := 1; i < len(items); i += 1 {
        cnode := new_treenode(to_str(items[i]))
        cnode._nodeOp = .Add_Child
        cnode._index = this._itemCount
        cnode._insAfter = TVI_LAST
        append(&pnode.nodes, cnode)
        this._itemCount += 1
        pnode._nodeCount += 1
        if this.handle != nil do tv_addnode_internal(this, cnode, pnode)
    }    
}

@private tv_insert_node1 :: proc(this: ^TreeView, node: ^TreeNode, index: int)
{
    if index < 0 || index >= len(this.nodes) do return
    node._insPos = index
    node._index = this._itemCount
    node._nodeOp = .Insert_Node
    node._insAfter = TVI_FIRST if index == 0 else this.nodes[index - 1].handle
    append(&this.nodes, node)
    this._itemCount += 1
    if this.handle != nil do tv_addnode_internal(this, node)
}

@private tv_insert_node2 :: proc(this: ^TreeView, nodeText: any, index: int)
{
    if index < 0 || index >= len(this.nodes) do return
    node := new_treenode(to_str(nodeText))
    node._insPos = index
    node._index = this._itemCount
    node._nodeOp = .Insert_Node
    node._insAfter = TVI_FIRST if index == 0 else this.nodes[index - 1].handle
    append(&this.nodes, node)
    this._itemCount += 1
    if this.handle != nil do tv_addnode_internal(this, node)
}

@private tv_add_nodes1:: proc(this: ^TreeView, nodes: ..^TreeNode )
{
    for node in nodes {
        node._index = this._itemCount
        node._nodeOp = .Add_Node
        node._insAfter = TVI_LAST
        append(&this.nodes, node)
        this._itemCount += 1
        if this.handle != nil do tv_addnode_internal(this, node)
    }
}

@private tv_add_nodes2:: proc(this: ^TreeView, nodetexts: ..any )
{
    for txt in nodetexts {
        node:= new_treenode(to_str(txt))
        node._nodeOp = .Add_Node
        node._insAfter = TVI_LAST
        node._index = this._itemCount
        append(&this.nodes, node)
        this._itemCount += 1
        if this.handle != nil do tv_addnode_internal(this, node)
    }
}

@private tv_add_childnode1 :: proc(this: ^TreeView, node: ^TreeNode, parent: ^TreeNode)
{
    node._index = this._itemCount
    node._nodeOp = .Add_Node
    node._insAfter = TVI_LAST
    append(&this.nodes, node)
    this._itemCount += 1
    parent._nodeCount += 1
    if this.handle != nil do tv_addnode_internal(this, node, parent)    
}

@private tv_add_childnode2 :: proc(this: ^TreeView, nodeText: any, parent: ^TreeNode)
{
    node := new_treenode(to_str(nodeText))
    node._index = this._itemCount
    node._nodeOp = .Add_Child
    node._insAfter = TVI_LAST
    append(&this.nodes, node)
    this._itemCount += 1
    parent._nodeCount += 1
    if this.handle != nil do tv_addnode_internal(this, node, parent)    
}

@private tv_insert_childnode1 :: proc(this: ^TreeView, node: ^TreeNode, parent: ^TreeNode, index: int)
{
    if index < 0 || index >= len(parent.nodes) do return
    node._insPos = index
    node._index = this._itemCount
    node._nodeOp = .Insert_Child
    node._insAfter = TVI_FIRST if index == 0 else parent.nodes[index - 1].handle
    append(&parent.nodes, node)
    parent._nodeCount += 1
    if this.handle != nil do tv_addnode_internal(this, node, parent)
}

@private tv_insert_childnode2 :: proc(this: ^TreeView, nodeText: any, parent: ^TreeNode, index: int)
{
    if index < 0 || index >= len(parent.nodes) do return
    node := new_treenode(to_str(nodeText))
    node._insPos = index
    node._insAfter = TVI_FIRST if index == 0 else parent.nodes[index - 1].handle
    node._index = this._itemCount
    node._nodeOp = .Insert_Child
    append(&parent.nodes, node)
    parent._nodeCount += 1
    if this.handle != nil do tv_addnode_internal(this, node, parent)
}

@private tv_add_child_nodes1:: proc(this: ^TreeView, parent: ^TreeNode, nodes: ..^TreeNode)
{
    for node in nodes {
        node._nodeOp = .Add_Child
        node._index = this._itemCount
        node._insAfter = TVI_LAST
        append(&parent.nodes, node)
        this._itemCount += 1
        parent._nodeCount += 1
        if this.handle != nil do tv_addnode_internal(this, node, parent)
    }
}

@private tv_add_child_nodes2:: proc(this: ^TreeView, parent: ^TreeNode, nodetexts: ..any)
{
    for txt in nodetexts {
        node:= new_treenode(to_str(txt))
        node._nodeOp = .Add_Child
        node._index = this._itemCount
        node._insAfter = TVI_LAST
        append(&parent.nodes, node)
        this._itemCount += 1
        parent._nodeCount += 1
        if this.handle != nil do tv_addnode_internal(this, node, parent)
    }
}

@private tv_add_child_nodes3:: proc(this: ^TreeView, parentIndex: int, nodetexts: ..any)
{
    if parentIndex > len(this.nodes) || parentIndex < 0 do return
    parent:= this.nodes[parentIndex]
    for txt in nodetexts {
        node:= new_treenode(to_str(txt))
        node._nodeOp = .Add_Child
        node._index = this._itemCount
        node._insAfter = TVI_LAST
        append(&parent.nodes, node)
        this._itemCount += 1
        parent._nodeCount += 1
        if this.handle != nil do tv_addnode_internal(this, node, parent)
    }    
}

@private tv_insert_items_internal :: proc(this: ^TreeView, node: ^TreeNode, pnode: ^TreeNode = nil)
{
    tv_addnode_internal(this, node, pnode)
    if len(node.nodes) > 0 {
        for cnode in node.nodes {
            tv_insert_items_internal(this, cnode, node) 
        }
    }    
}

// This function handles add or insert nodes & child nodes.
@private tv_addnode_internal:: proc(tv: ^TreeView, node: ^TreeNode, pnode: ^TreeNode = nil)
{
    if !tv._isCreated do return
    node._isCreated = true
    node._treeHwnd = tv.handle
    node._nodeID = tv._uniqItemID // We can identify any node with this
    err_msg:= "Can't Add Node"

    tvi: TVITEMEXW
    tvi.mask = TVIF_TEXT | TVIF_PARAM
    tvi.pszText = to_wstring(node.text)
    tvi.cchTextMax = i32(len(node.text))
    tvi.iImage = i32(node.imageIndex)
    tvi.iSelectedImage = i32(node.selImageIndex)
    tvi.stateMask = TVIS_USERMASK
    // tvi.lParam = dir_cast(node, LPARAM)
    if node.imageIndex > -1 do tvi.mask |= TVIF_IMAGE
    if node.selImageIndex > -1 do tvi.mask |= TVIF_SELECTEDIMAGE
    if node.foreColor != def_fore_clr do tv._nodeClrChange = true

    tis: TVINSERTSTRUCT
    tis.itemEx = tvi
    tis.itemEx.lParam = dir_cast(rawptr(node), LPARAM)
    tis.hInsertAfter = node._insAfter

    switch node._nodeOp {
        case .Add_Node:
            tis.hParent = TVI_ROOT

        case .Insert_Node:
            tis.hParent = TVI_ROOT
            err_msg = "Can't Insert Node"
            
        case .Add_Child:
            tis.hParent = pnode.handle
            node.parentNode = pnode
            err_msg = "Can't Add Child Node"

        case .Insert_Child:
            tis.hParent = pnode.handle
            node.parentNode = pnode
            err_msg = "Can't Insert Child Node"
    }

    lres:= SendMessage(tv.handle, TVM_INSERTITEMW, 0,  dir_cast(&tis, LPARAM) )
    if lres != 0 {
        hItem:= dir_cast(lres, HTREEITEM)
        node.handle = hItem
        tv._uniqItemID += 1
    } else {
        print(err_msg)
    }
}

// Sometimes we need to remove a node from it's parent's node list, we need to find the index of that node.
@private find_index:: proc(list: [dynamic]^TreeNode, hti: HTREEITEM) ->(idx: int, ok: bool)
{
    for node, i in list { if node.handle == hti { return i, true}  }
    return -1, false
}

// Every node must dispose itself and clean the momory it posses.
// This must be get called either at program end or when user delete a node.
@private dispose_node:: proc(n: ^TreeNode)
{
    //print("Going to delete nodes of ", n.text)
    for child in n.nodes {child._dispose(child)}
    delete(n.nodes)
    free(n)
}

@private treeview_set_back_color:: proc(tv: ^Control, clr: uint)
{
    tv.backColor = clr
    cref:= get_color_ref(clr)
    SendMessage(tv.handle, TVM_SETBKCOLOR, 0, dir_cast(cref, LPARAM))
}

@private treenode_color:: proc( lpm: LPARAM) -> LRESULT
{
    //@static x: int
    pn:= dir_cast(lpm, ^NMTVCUSTOMDRAW)
    switch pn.nmcd.dwDrawStage {
        case CDDS_PREPAINT:
            return CDRF_NOTIFYITEMDRAW
        case CDDS_ITEMPREPAINT:
            nd:= dir_cast(pn.nmcd.lItemParam, ^TreeNode)
            if nd.foreColor != def_fore_clr {
                pn.clrText = get_color_ref(nd.foreColor)
            }
            if nd.backColor != def_back_clr {
                pn.clrTextBk = get_color_ref(nd.backColor)
            }
            return CDRF_DODEFAULT

    }
    return CDRF_DODEFAULT
}

@private add_style:: proc(tv: ^TreeView, stls: ..DWORD)
{
    for i in stls { if (tv._style & i) != i do tv._style |= i }
}



@private tv_adjust_styles:: proc(tv: ^TreeView)
{
    if tv.noLines do tv._style ~= TVS_HASLINES
    if tv.noButtons do tv._style ~= TVS_HASBUTTONS
    if tv.hasCheckBoxes do add_style(tv, TVS_CHECKBOXES)
    if tv.fullRowSelect do add_style(tv, TVS_FULLROWSELECT)
    if tv.editable do tv._style |= TVS_EDITLABELS //add_style(tv, TVS_EDITLABELS )
    if tv.showSelection do add_style(tv, TVS_SHOWSELALWAYS)
    if tv.hotTracking do add_style(tv, TVS_TRACKSELECT )

    if tv.noButtons && tv.noLines do tv._style ~= TVS_LINESATROOT
}


@private treeview_property_setter:: proc(this: ^TreeView, prop: TreeViewProps, value: $T)
{
	switch prop {
        case .No_Lines: break
        case .No_Buttons: break
        case .Has_Check_Boxes: break
        case .Full_Row_Select: break
        case .Editable: break
        case .Show_Selection: break
        case .Hot_Tracking: break
        case .Selected_Node: break
        case .Image_List: break
        case .Line_Color: break
	}
}

@private tv_finalize:: proc(this: ^TreeView)
{
    for n in this.nodes { n._dispose(n)} // looping thru the child nodes and delete them.
    delete(this.nodes)                  // delete all the top level nodes.
    ImageList_Destroy(this.imageList)
    control_base_dtor(this)
    free(this)
}

@private tv_wnd_proc:: proc "stdcall" (hw: HWND, msg: u32, wp: WPARAM, lp: LPARAM,
                                    sc_id: UINT_PTR, ref_data: DWORD_PTR) -> LRESULT
{
    // context = runtime.default_context()
    context = global_context
    
    //display_msg(msg)
    this := control_cast(TreeView, ref_data)
    res := ctrl_common_msg_handler(this, hw, msg, wp, lp) 
    #partial switch res {
        case .Call_Def_Proc: return DefSubclassProc(hw, msg, wp, lp)
        case .Immediate_Return: return 1
    }
    switch msg {
    case WM_DESTROY:
        if this.onDestroy != nil {
            ea:= new_event_args()
            this.onDestroy(this, &ea)
        }

    case WM_NCDESTROY:
        RemoveWindowSubclass(this.handle, tv_wnd_proc, sc_id)
        tv_finalize(this)

    case CM_TVNODEEXPAND:
        node:= dir_cast(lp, ^TreeNode)
        SendMessage(this.handle, TVM_EXPAND, wp, dir_cast(node.handle, LPARAM))
        if node.childCount > 0 {
            for n in node.nodes {
                SendMessage(this.handle, CM_TVNODEEXPAND, wp, dir_cast(n, LPARAM))
            }
        }
        // return 0

    case CM_NOTIFY:
        nm:= dir_cast(lp, ^NMHDR)
        switch nm.code {
        case TVN_DELETEITEMW:
            if this.onNodeDeleted != nil {
                nmtv:= dir_cast(lp, ^NMTREEVIEW)
                tea : TreeEventArgs
                tea.node = dir_cast(nmtv.itemOld.lParam, ^TreeNode)
                this.onNodeDeleted(this, &tea)
            }
        case TVN_SELCHANGINGW:
            if this.onBeforeSelect != nil {
                nmtv:= dir_cast(lp, ^NMTREEVIEW)
                tea:= new_tree_event_args(nmtv)
                this.onBeforeSelect(this, &tea)
            }
        case TVN_SELCHANGEDW:
            nmtv:= dir_cast(lp, ^NMTREEVIEW)
            tea:= new_tree_event_args(nmtv)
            this.selectedNode = tea.node
            if this.onAfterSelect != nil { this.onAfterSelect(this, &tea) }

        case TVN_ITEMCHANGINGW:
            if this.onBeforeChecked != nil {
                tea:= new_tree_event_args(dir_cast(lp, ^NMTVITEMCHANGE))
                if tea.isCBChanged {
                    this.onBeforeChecked(this, &tea)
                    if tea.cancel do return 1
                }
            }

        case TVN_ITEMCHANGEDW:
            if this._suppressNotify do return 0
            if this.onAfterChecked != nil {
                tea := new_tree_event_args(dir_cast(lp, ^NMTVITEMCHANGE))
                if tea.oldChecked != tea.newChecked do this.onAfterChecked(this, &tea)
            }

        case TVN_ITEMEXPANDINGW:
            nmtv:= dir_cast(lp, ^NMTREEVIEW)
            switch nmtv.action {
                case 1:
                    if this.onBeforeCollapse != nil {
                        tea:= new_tree_event_args(nmtv)
                        this.onBeforeCollapse(this, &tea)
                        if tea.cancel do return 1
                    }

                case 2:
                    if this.onBeforeExpand != nil {
                        tea:= new_tree_event_args(nmtv)
                        this.onBeforeExpand(this, &tea)
                        if tea.cancel do return 1
                    }
                }

        case TVN_ITEMEXPANDEDW:
            if this._suppressNotify do return 0
            nmtv:= dir_cast(lp, ^NMTREEVIEW)
            switch nmtv.action {
                case 1:
                    if this.onAfterCollapse != nil {
                        tea:= new_tree_event_args(nmtv)
                        this.onAfterCollapse(this, &tea)
                    }

                case 2:
                    if this.onAfterExpand != nil {
                        tea:= new_tree_event_args(nmtv)
                        this.onAfterExpand(this, &tea)
                    }
            }

        case TVN_BEGINLABELEDITW:
            if this.onBeginEdit != nil {
                nmdi := dir_cast(lp, ^NMTVDISPINFOW)
                tea := new_tree_event_args(nmdi)
                this.onBeginEdit(this, &tea)
                delete(tea.nodeText)
                if tea.cancel do return 1
            }

        case TVN_ENDLABELEDITW:
            if this.onEndEdit != nil {
                nmdi := dir_cast(lp, ^NMTVDISPINFOW)
                if nmdi.item.pszText == nil {
                    if this.onEditCancelled != nil {
                        tea: TreeEventArgs
                        // tea.hItem = nmdi.item.hItem
                        this.onEditCancelled(this, &tea)
                    }
                    return 0  // nothing was typed; native control reverts on its own regardless
                }

                tea := new_tree_event_args(nmdi)
                this.onEndEdit(this, &tea)
                delete(tea.nodeText)
                if tea.cancel do return 0  // Zero here means REJECT and revert
            }
            return 1 // Must return TRUE (nonzero) to accept and commit the new text

        // case NM_CUSTOMDRAW:
        //     if this._nodeClrChange {
        //         return treenode_color( lp)
        //     }

        // case:
            //print("else case - ", nm.code)
        // case 4294966879:
            //   print("4294966879 rcvd")
        // case: alert(fmt.tprintf("NMHDR.Code - %d", nm.code)) 4294967279
        }
    }
    return DefSubclassProc(hw, msg, wp, lp)
}


