package iup

// foreign import iup "iup.lib"

// ============================================================================
// BINDING COMPLETO PARA IUPKEY (iupkey.h)
// Definiciones numéricas de teclas para capturar eventos del teclado
// ============================================================================


// from 32 to 126, all character sets are equal,
// the key code is the same as the ASCii character code.

K_SP :: 32
K_exclam :: 33
K_quotedbl :: 34
K_numbersign :: 35
K_dollar :: 36
K_percent :: 37
K_ampersand :: 38
K_apostrophe :: 39
K_parentleft :: 40
K_parentright :: 41
K_asterisk :: 42
K_plus :: 43
K_comma :: 44
K_minus :: 45
K_period :: 46
K_slash :: 47
K_0 :: 48
K_1 :: 49
K_2 :: 50
K_3 :: 51
K_4 :: 52
K_5 :: 53
K_6 :: 54
K_7 :: 55
K_8 :: 56
K_9 :: 57
K_colon :: 58
K_semicolon :: 59
K_less :: 60
K_equal :: 61
K_greater :: 62
K_question :: 63
K_at :: 64
K_A :: 65
K_B :: 66
K_C :: 67
K_D :: 68
K_E :: 69
K_F :: 70
K_G :: 71
K_H :: 72
K_I :: 73
K_J :: 74
K_K :: 75
K_L :: 76
K_M :: 77
K_N :: 78
K_O :: 79
K_P :: 80
K_Q :: 81
K_R :: 82
K_S :: 83
K_T :: 84
K_U :: 85
K_V :: 86
K_W :: 87
K_X :: 88
K_Y :: 89
K_Z :: 90
K_bracketleft :: 91
K_backslash :: 92
K_bracketright :: 93
K_circum :: 94
K_underscore :: 95
K_grave :: 96
K_a :: 97
K_b :: 98
K_c :: 99
K_d :: 100
K_e :: 101
K_f :: 102
K_g :: 103
K_h :: 104
K_i :: 105
K_j :: 106
K_k :: 107
K_l :: 108
K_m :: 109
K_n :: 110
K_o :: 111
K_p :: 112
K_q :: 113
K_r :: 114
K_s :: 115
K_t :: 116
K_u :: 117
K_v :: 118
K_w :: 119
K_x :: 120
K_y :: 121
K_z :: 122
K_braceleft :: 123
K_bar :: 124
K_braceright :: 125
K_tilde :: 126

// These use the same definition as X11 and GDK.
// This also means that any X11 or GDK definition can also be used.

K_PAUSE :: 0xFF13
K_ESC :: 0xFF1B
K_HOME :: 0xFF50
K_LEFT :: 0xFF51
K_UP :: 0xFF52
K_RIGHT :: 0xFF53
K_DOWN :: 0xFF54
K_PGUP :: 0xFF55
K_PGDN :: 0xFF56
K_END :: 0xFF57
K_MIDDLE :: 0xFF0B
K_Print :: 0xFF61
K_INS :: 0xFF63
K_Menu :: 0xFF67
K_DEL :: 0xFFFF
K_F1 :: 0xFFBE
K_F2 :: 0xFFBF
K_F3 :: 0xFFC0
K_F4 :: 0xFFC1
K_F5 :: 0xFFC2
K_F6 :: 0xFFC3
K_F7 :: 0xFFC4
K_F8 :: 0xFFC5
K_F9 :: 0xFFC6
K_F10 :: 0xFFC7
K_F11 :: 0xFFC8
K_F12 :: 0xFFC9
K_F13 :: 0xFFCA
K_F14 :: 0xFFCB
K_F15 :: 0xFFCC
K_F16 :: 0xFFCD
K_F17 :: 0xFFCE
K_F18 :: 0xFFCF
K_F19 :: 0xFFD0
K_F20 :: 0xFFD1

// no Shift/Ctrl/Alt
K_LSHIFT :: 0xFFE1
K_RSHIFT :: 0xFFE2
K_LCTRL :: 0xFFE3
K_RCTRL :: 0xFFE4
K_LALT :: 0xFFE9
K_RALT :: 0xFFEA

K_NUM :: 0xFF7F
K_SCROLL :: 0xFF14
K_CAPS :: 0xFFE5

// Teclas de Control Especiales
// K_SP: i32 : 32 // Espacio
K_BS: i32 : 8 // Backspace
K_TAB: i32 : 9 // Tabulador
K_CR: i32 : 13 // Enter / Carriage Return
K_LF: i32 : 10 // Line Feed
// K_ESC: i32 : 27 // Escape
// K_INS: i32 : 260 // Insertar
// K_DEL: i32 : 261 // Suprimir
// K_HOME: i32 : 262 // Inicio
// K_END: i32 : 263 // Fin
// K_PGUP: i32 : 264 // Re Pág
// K_PGDN: i32 : 265 // Av Pág

// // Flechas de Dirección
// K_UP: i32 : 266
// K_DOWN: i32 : 267
// K_LEFT: i32 : 268
// K_RIGHT: i32 : 269

// // Teclas de Función
// K_F1: i32 : 270
// K_F2: i32 : 271
// K_F3: i32 : 272
// K_F4: i32 : 273
// K_F5: i32 : 274
// K_F6: i32 : 275
// K_F7: i32 : 276
// K_F8: i32 : 277
// K_F9: i32 : 278
// K_F10: i32 : 279
// K_F11: i32 : 280
// K_F12: i32 : 281

// // Números (Fila Superior)
// K_0: i32 : 48
// K_1: i32 : 49
// K_2: i32 : 50
// K_3: i32 : 51
// K_4: i32 : 52
// K_5: i32 : 53
// K_6: i32 : 54
// K_7: i32 : 55
// K_8: i32 : 56
// K_9: i32 : 57

// // Letras Mayúsculas
// K_A: i32 : 65
// K_B: i32 : 66
// K_C: i32 : 67
// K_D: i32 : 68
// K_E: i32 : 69
// K_F: i32 : 70
// K_G: i32 : 71
// K_H: i32 : 72
// K_I: i32 : 73
// K_J: i32 : 74
// K_K: i32 : 75
// K_L: i32 : 76
// K_M: i32 : 77
// K_N: i32 : 78
// K_O: i32 : 79
// K_P: i32 : 80
// K_Q: i32 : 81
// K_R: i32 : 82
// K_S: i32 : 83
// K_T: i32 : 84
// K_U: i32 : 85
// K_V: i32 : 86
// K_W: i32 : 87
// K_X: i32 : 88
// K_Y: i32 : 89
// K_Z: i32 : 90

// // Letras Minúsculas
// K_a: i32 : 97
// K_b: i32 : 98
// K_c: i32 : 99
// K_d: i32 : 100
// K_e: i32 : 101
// K_f: i32 : 102
// K_g: i32 : 103
// K_h: i32 : 104
// K_i: i32 : 105
// K_j: i32 : 106
// K_k: i32 : 107
// K_l: i32 : 108
// K_m: i32 : 109
// K_n: i32 : 110
// K_o: i32 : 111
// K_p: i32 : 112
// K_q: i32 : 113
// K_r: i32 : 114
// K_s: i32 : 115
// K_t: i32 : 116
// K_u: i32 : 117
// K_v: i32 : 118
// K_w: i32 : 119
// K_x: i32 : 120
// K_y: i32 : 121
// K_z: i32 : 122

// Macros auxiliares de verificación de estado (Mapeo de combinaciones)
is_shift :: proc(code: i32) -> bool {return (code & 0x10000000) != 0}
is_ctrl :: proc(code: i32) -> bool {return (code & 0x20000000) != 0}
is_alt :: proc(code: i32) -> bool {return (code & 0x40000000) != 0}
is_sys :: proc(code: u32) -> bool {return (code & 0x80000000) != 0}

// iup_isShiftXkey(_c) (((_c) & 0x10000000) != 0)
// iup_isCtrlXkey(_c)  (((_c) & 0x20000000) != 0)
// iup_isAltXkey(_c)   (((_c) & 0x40000000) != 0)
// iup_isSysXkey(_c)   (((_c) & 0x80000000) != 0)

iup_isShiftXkey :: proc(c: i32) -> bool {
	return (c & 0x10000000) != 0
}
iup_isCtrlXkey :: proc(c: i32) -> bool {
	return (c & 0x20000000) != 0
}
iup_isAltXkey :: proc(c: i32) -> bool {
	return (c & 0x40000000) != 0
}
iup_isSysXkey :: proc(c: u32) -> bool {
	return (c & 0x80000000) != 0
}

// iup_isshift(status)
// iup_iscontrol(status)
// iup_isbutton1(status)
// iup_isbutton2(status)
// iup_isbutton3(status)
// iup_isbutton4(status)
// iup_isbutton5(status)
// iup_isdouble(status)
// iup_isalt(status)
// iup_issys(status)
//
iup_isshift :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[0] == 'S' do return true
	return false
}
iup_iscontrol :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[1] == 'C' do return true
	return false
}
iup_isalt :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[6] == 'A' do return true
	return false
}
iup_issys :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[7] == 'Y' do return true
	return false
}
iup_isdouble :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[5] == 'D' do return true
	return false
}
iup_button1 :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[2] == '1' do return true
	return false
}
iup_button2 :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[3] == '2' do return true
	return false
}
iup_button3 :: proc(str: cstring) -> bool {
	if (cast([^]u8)str)[4] == '3' do return true
	return false
}

iup_XkeyBase :: proc(c: i32) -> i32 {return c & 0x0FFFFFFF}
iup_XkeyShift :: proc(c: i32) -> i32 {return c | 0x10000000} /* Shift  */
iup_XkeyCtrl :: proc(c: i32) -> i32 {return c | 0x20000000} /* Ctrl   */
iup_XkeyAlt :: proc(c: i32) -> i32 {return (c) | 0x40000000} /* Alt    */
iup_XkeySys :: proc(c: u32) -> u32 {return(
		(c) |
		0x80000000 \
	)} /* Sys (Win or Apple) - notice that using "int" will display a negative value */

// K_sHOME :: iup_XkeyShift(K_HOME)

