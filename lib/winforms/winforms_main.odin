// Created on 05-Aug-2024 07:39
// Copyright (c) 2026 kcvinker
// SPDX-License-Identifier: MIT

package winforms

import "base:runtime"
import "core:mem"
import api "core:sys/windows"


global_context      := runtime.default_context() // Context
def_window_color    : uint  : 0xF5F5F5
def_fore_color      : uint  : 0x000000
pure_white          : uint  : 0xFFFFFF
pure_black          : uint  : 0x000000
def_font_name       :: "Tahoma"
def_font_size       :: 12
def_bgc : Color
def_fgc : Color
EMWARR : [1]WCHAR
EWCAPTR : WCPTR  
app : Application // Global variable for storing data needed by the entire library.

@private
Application :: struct
{
    mainHandle : HWND,
    hInstance : HINSTANCE,
    trayHwnd : HWND,
    screenWidth, screenHeight : i32,
    sysDPI: u32,
    formCount : int,
    clrWhite : uint,
    clrBlack : uint,
    fontHeight : LONG,
    mainLoopStarted : bool,
    nidUsed : bool,
    isFormReg : bool,
    isMowReg : bool,
    startState : FormState,
    iccx : INITCOMMONCONTROLSEX,    
    winMap : map[HWND]^Form,
    mfMap : map[HWND]^MessageForm,
    trayHwnds: [dynamic]HWND,
    font: Font,
    primaryFont : LOGFONT,
    gdip_token : ULONG_PTR,
    gdip_inited : bool,
    
}

@(init)
@private 
app_start :: proc "contextless" () 
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE)
    app.hInstance = GetModuleHandle(nil)
    gea = new_event_args()
    // global_context.user_index = 471
}

@private
initFormDefaults :: proc()
{
    app.screenWidth = api.GetSystemMetrics(0)
    app.screenHeight = api.GetSystemMetrics(1)
    app.sysDPI = GetDpiForSystem()
    app.iccx.dwSize = size_of(app.iccx)
    app.iccx.dwIcc = ICC_STANDARD_CLASSES
    InitCommonControlsEx(&app.iccx)    
    app.clrWhite = pure_white
    app.clrBlack = pure_black
    EMWARR[0] = 0
    EWCAPTR = &EMWARR[0]
    register_class() 
    app.font = new_font("Tahoma", 12)
    font_create_primary_handle()
}

@private
initMsgForm :: proc() // Called when first msg-only window starting
{
	wc : WNDCLASSEXW
	wc.cbSize = size_of(wc)
	wc.lpfnWndProc = msgfrm_wndproc	
	wc.hInstance = app.hInstance
	wc.lpszClassName = wcnMsgOnlyWin
	res := RegisterClassEx(&wc)
	if res > 0 do app.isMowReg = true
}

@private gdiplus_init :: proc()
{
    if app.gdip_inited do return
    gdipInput : GdiplusStartupInput
    gdipInput.GdiplusVersion = 1
    gdipInput.DebugEventCallback = nil
    gdipInput.SuppressBackgroundThread = false
    gdipInput.SuppressExternalCodecs = false
    res := GdiplusStartup(&app.gdip_token, &gdipInput, nil)
    if res == Status.Ok do app.gdip_inited = true
	
}

@private gdiplus_shutdown :: proc()
{
    if app.gdip_inited {
        GdiplusShutdown(app.gdip_token)
        app.gdip_inited = false
    }
}

@private register_class :: proc()
{
    win_class : WNDCLASSEXW
    win_class.cbSize = size_of(win_class)
    win_class.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC
    win_class.lpfnWndProc = window_proc
    win_class.cbClsExtra = 0
    win_class.cbWndExtra = 0
    win_class.hInstance = app.hInstance
    win_class.hIcon = LoadIcon(nil, IDI_APPLICATION)
    win_class.hCursor = LoadCursor(nil, IDC_ARROW)
    win_class.hbrBackground = CreateSolidBrush(get_color_ref(def_window_color)) 
    win_class.lpszMenuName = nil
    win_class.lpszClassName = wcnForm
    res := RegisterClassEx(&win_class)
    if res > 0 do app.isFormReg = true    
}

@private
app_finalize :: proc() // Will be executed right after main loop exit
{
    if len(app.trayHwnds) > 0 {
        for hwnd in app.trayHwnds {
            if hwnd != nil do DestroyWindow(hwnd)
        }        
    }
    font_destroy(&app.font)
    delete(app.trayHwnds)
    delete(app.winMap)
    delete(app.mfMap)
    print("Winform closed...")
}


