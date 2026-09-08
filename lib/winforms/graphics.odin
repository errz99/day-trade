// graphics module, created on 21-Sep-2024 06:54

package winforms
import api "core:sys/windows"

DCFreeMode :: enum u8 {None, Release_DC, End_Paint}

Graphics :: struct 
{
    hdc: HDC,
    hwnd: HWND,
    ps: PAINTSTRUCT,
    dcFreeMode: DCFreeMode,
    freeThis: bool,
    dcNumber: i32,
}

new_graphics :: proc{new_graphics1, new_graphics2}

new_graphics1 :: proc(hw: HWND, freeThisPtr: bool = true) -> ^Graphics
{
    gfx := new(Graphics)
    gfx.hdc = GetDC(hw)
    gfx.hwnd = hw 
    gfx.freeThis = freeThisPtr
    gfx.dcFreeMode = .Release_DC
    return gfx
}

new_graphics2 :: proc(wp: WPARAM, freeThisPtr: bool = true) -> ^Graphics
{
    gfx := new(Graphics)
    gfx.hdc = dir_cast(wp, HDC)
    gfx.hwnd = nil 
    gfx.freeThis = freeThisPtr
    gfx.dcFreeMode = .None
    return gfx
}

paint_gfx :: proc(hw: HWND) -> Graphics
{
    gfx : Graphics   
    gfx.hdc = BeginPaint(hw, &gfx.ps)
    gfx.hwnd = hw
    gfx.dcFreeMode = .End_Paint
    gfx.dcNumber = SaveDC(gfx.hdc)
    gfx.freeThis = false

    return gfx
}

gfx_destroy :: proc(this: ^Graphics)
{
    if this.dcFreeMode == .Release_DC {
        ReleaseDC(this.hwnd, this.hdc)
    } else if this.dcFreeMode == .End_Paint {
        RestoreDC(this.hdc, this.dcNumber)
        EndPaint(this.hwnd, &this.ps)
    }
    if this.freeThis do free(this)
}

gfx_draw_hline :: proc(this: ^Graphics, mPen: HPEN, sx, y, ex: i32)
{
    select_gdi_object(this.hdc, mPen)
    MoveToEx(this.hdc, sx, y, nil)
    LineTo(this.hdc, ex, y)
}

gfx_text_size :: proc(this: ^Graphics, ctl: ^Control, sz: ^SIZE) -> bool
{
    select_gdi_object(this.hdc, ctl.font.handle)
    GetTextExtentPoint32(this.hdc, ctl._wtext.ptr, ctl._wtext.strLen, sz)
    return false                
}

gfx_draw_text :: proc(this: ^Graphics, pc: ^Control, x, y : i32)
{
    api.SetBkMode(this.hdc, api.BKMODE.TRANSPARENT)
    select_gdi_object(this.hdc, pc.font.handle)
    api.SetTextColor(this.hdc, pc._fcref)
    TextOut(this.hdc, x, y, pc._wtext.ptr, pc._wtext.strLen)
}

gfx_set_hdc_and_bmp :: #force_inline proc(this: ^Graphics, mdc: ^HDC, bmp: ^HBITMAP, w, h: i32)
{
    if bmp^ != nil do delete_gdi_object(bmp^)
    bmp^ = CreateCompatibleBitmap(this.hdc, w, h)
    select_gdi_object(mdc^, bmp^)
}