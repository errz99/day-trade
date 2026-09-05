package gdk

import "core:c"

when ODIN_OS == .Windows {
	// foreign import gdk_lib "../Windows/gdk-3.lib"
} else {
	foreign import gdk "system:gdk-3"
}

KEY_VoidSymbol :: 16777215
KEY_BackSpace :: 65288
KEY_Tab :: 65289
KEY_Linefeed :: 65290
KEY_Clear :: 65291
KEY_Return :: 65293
KEY_Pause :: 65299
KEY_Scroll_Lock :: 65300
KEY_Sys_Req :: 65301
KEY_Escape :: 65307
KEY_Delete :: 65535
KEY_Multi_key :: 65312
KEY_Codeinput :: 65335
KEY_SingleCandidate :: 65340
KEY_MultipleCandidate :: 65341
KEY_PreviousCandidate :: 65342
KEY_Kanji :: 65313
KEY_Muhenkan :: 65314
KEY_Henkan_Mode :: 65315
KEY_Henkan :: 65315
KEY_Romaji :: 65316
KEY_Hiragana :: 65317
KEY_Katakana :: 65318
KEY_Hiragana_Katakana :: 65319
KEY_Zenkaku :: 65320
KEY_Hankaku :: 65321
KEY_Zenkaku_Hankaku :: 65322
KEY_Touroku :: 65323
KEY_Massyo :: 65324
KEY_Kana_Lock :: 65325
KEY_Kana_Shift :: 65326
KEY_Eisu_Shift :: 65327
KEY_Eisu_toggle :: 65328
KEY_Kanji_Bangou :: 65335
KEY_Zen_Koho :: 65341
KEY_Mae_Koho :: 65342
KEY_Home :: 65360
KEY_Left :: 65361
KEY_Up :: 65362
KEY_Right :: 65363
KEY_Down :: 65364
KEY_Prior :: 65365
KEY_Page_Up :: 65365
KEY_Next :: 65366
KEY_Page_Down :: 65366
KEY_End :: 65367
KEY_Begin :: 65368
KEY_Select :: 65376
KEY_Print :: 65377
KEY_Execute :: 65378
KEY_Insert :: 65379
KEY_Undo :: 65381
KEY_Redo :: 65382
KEY_Menu :: 65383
KEY_Find :: 65384
KEY_Cancel :: 65385
KEY_Help :: 65386
KEY_Break :: 65387
KEY_Mode_switch :: 65406
KEY_script_switch :: 65406
KEY_Num_Lock :: 65407
KEY_KP_Space :: 65408
KEY_KP_Tab :: 65417
KEY_KP_Enter :: 65421
KEY_KP_F1 :: 65425
KEY_KP_F2 :: 65426
KEY_KP_F3 :: 65427
KEY_KP_F4 :: 65428
KEY_KP_Home :: 65429
KEY_KP_Left :: 65430
KEY_KP_Up :: 65431
KEY_KP_Right :: 65432
KEY_KP_Down :: 65433
KEY_KP_Prior :: 65434
KEY_KP_Page_Up :: 65434
KEY_KP_Next :: 65435
KEY_KP_Page_Down :: 65435
KEY_KP_End :: 65436
KEY_KP_Begin :: 65437
KEY_KP_Insert :: 65438
KEY_KP_Delete :: 65439
KEY_KP_Equal :: 65469
KEY_KP_Multiply :: 65450
KEY_KP_Add :: 65451
KEY_KP_Separator :: 65452
KEY_KP_Subtract :: 65453
KEY_KP_Decimal :: 65454
KEY_KP_Divide :: 65455
KEY_KP_0 :: 65456
KEY_KP_1 :: 65457
KEY_KP_2 :: 65458
KEY_KP_3 :: 65459
KEY_KP_4 :: 65460
KEY_KP_5 :: 65461
KEY_KP_6 :: 65462
KEY_KP_7 :: 65463
KEY_KP_8 :: 65464
KEY_KP_9 :: 65465
KEY_F1 :: 65470
KEY_F2 :: 65471
KEY_F3 :: 65472
KEY_F4 :: 65473
KEY_F5 :: 65474
KEY_F6 :: 65475
KEY_F7 :: 65476
KEY_F8 :: 65477
KEY_F9 :: 65478
KEY_F10 :: 65479
KEY_F11 :: 65480
KEY_L1 :: 65480
KEY_F12 :: 65481
KEY_L2 :: 65481
KEY_F13 :: 65482
KEY_L3 :: 65482
KEY_F14 :: 65483
KEY_L4 :: 65483
KEY_F15 :: 65484
KEY_L5 :: 65484
KEY_F16 :: 65485
KEY_L6 :: 65485
KEY_F17 :: 65486
KEY_L7 :: 65486
KEY_F18 :: 65487
KEY_L8 :: 65487
KEY_F19 :: 65488
KEY_L9 :: 65488
KEY_F20 :: 65489
KEY_L10 :: 65489
KEY_F21 :: 65490
KEY_R1 :: 65490
KEY_F22 :: 65491
KEY_R2 :: 65491
KEY_F23 :: 65492
KEY_R3 :: 65492
KEY_F24 :: 65493
KEY_R4 :: 65493
KEY_F25 :: 65494
KEY_R5 :: 65494
KEY_F26 :: 65495
KEY_R6 :: 65495
KEY_F27 :: 65496
KEY_R7 :: 65496
KEY_F28 :: 65497
KEY_R8 :: 65497
KEY_F29 :: 65498
KEY_R9 :: 65498
KEY_F30 :: 65499
KEY_R10 :: 65499
KEY_F31 :: 65500
KEY_R11 :: 65500
KEY_F32 :: 65501
KEY_R12 :: 65501
KEY_F33 :: 65502
KEY_R13 :: 65502
KEY_F34 :: 65503
KEY_R14 :: 65503
KEY_F35 :: 65504
KEY_R15 :: 65504
KEY_Shift_L :: 65505
KEY_Shift_R :: 65506
KEY_Control_L :: 65507
KEY_Control_R :: 65508
KEY_Caps_Lock :: 65509
KEY_Shift_Lock :: 65510
KEY_Meta_L :: 65511
KEY_Meta_R :: 65512
KEY_Alt_L :: 65513
KEY_Alt_R :: 65514
KEY_Super_L :: 65515
KEY_Super_R :: 65516
KEY_Hyper_L :: 65517
KEY_Hyper_R :: 65518

KEY_space :: 32
KEY_exclam :: 33
KEY_quotedbl :: 34
KEY_numbersign :: 35
KEY_dollar :: 36
KEY_percent :: 37
KEY_ampersand :: 38
KEY_apostrophe :: 39
KEY_quoteright :: 39
KEY_parenleft :: 40
KEY_parenright :: 41
KEY_asterisk :: 42
KEY_plus :: 43
KEY_comma :: 44
KEY_minus :: 45
KEY_period :: 46
KEY_slash :: 47
KEY_0 :: 48
KEY_1 :: 49
KEY_2 :: 50
KEY_3 :: 51
KEY_4 :: 52
KEY_5 :: 53
KEY_6 :: 54
KEY_7 :: 55
KEY_8 :: 56
KEY_9 :: 57
KEY_colon :: 58
KEY_semicolon :: 59
KEY_less :: 60
KEY_equal :: 61
KEY_greater :: 62
KEY_question :: 63
KEY_at :: 64
KEY_A :: 65
KEY_B :: 66
KEY_C :: 67
KEY_D :: 68
KEY_E :: 69
KEY_F :: 70
KEY_G :: 71
KEY_H :: 72
KEY_I :: 73
KEY_J :: 74
KEY_K :: 75
KEY_L :: 76
KEY_M :: 77
KEY_N :: 78
KEY_O :: 79
KEY_P :: 80
KEY_Q :: 81
KEY_R :: 82
KEY_S :: 83
KEY_T :: 84
KEY_U :: 85
KEY_V :: 86
KEY_W :: 87
KEY_X :: 88
KEY_Y :: 89
KEY_Z :: 90
KEY_bracketleft :: 91
KEY_backslash :: 92
KEY_bracketright :: 93
KEY_asciicircum :: 94
KEY_underscore :: 95
KEY_grave :: 96
KEY_quoteleft :: 96
KEY_a :: 97
KEY_b :: 98
KEY_c :: 99
KEY_d :: 100
KEY_e :: 101
KEY_f :: 102
KEY_g :: 103
KEY_h :: 104
KEY_i :: 105
KEY_j :: 106
KEY_k :: 107
KEY_l :: 108
KEY_m :: 109
KEY_n :: 110
KEY_o :: 111
KEY_p :: 112
KEY_q :: 113
KEY_r :: 114
KEY_s :: 115
KEY_t :: 116
KEY_u :: 117
KEY_v :: 118
KEY_w :: 119
KEY_x :: 120
KEY_y :: 121
KEY_z :: 122
KEY_braceleft :: 123
KEY_bar :: 124
KEY_braceright :: 125
KEY_asciitilde :: 126
KEY_nobreakspace :: 160
KEY_exclamdown :: 161
KEY_cent :: 162
KEY_sterling :: 163
KEY_currency :: 164
KEY_yen :: 165
KEY_brokenbar :: 166
KEY_section :: 167
KEY_diaeresis :: 168
KEY_copyright :: 169
KEY_ordfeminine :: 170
KEY_guillemotleft :: 171
KEY_guillemetleft :: 171
KEY_notsign :: 172
KEY_hyphen :: 173
KEY_registered :: 174
KEY_macron :: 175
KEY_degree :: 176
KEY_plusminus :: 177
KEY_twosuperior :: 178
KEY_threesuperior :: 179
KEY_acute :: 180
KEY_mu :: 181
KEY_paragraph :: 182
KEY_periodcentered :: 183
KEY_cedilla :: 184
KEY_onesuperior :: 185
KEY_masculine :: 186
KEY_ordmasculine :: 186
KEY_guillemotright :: 187
KEY_guillemetright :: 187
KEY_onequarter :: 188
KEY_onehalf :: 189
KEY_threequarters :: 190
KEY_questiondown :: 191
KEY_Agrave :: 192
KEY_Aacute :: 193
KEY_Acircumflex :: 194
KEY_Atilde :: 195
KEY_Adiaeresis :: 196
KEY_Aring :: 197
KEY_AE :: 198
KEY_Ccedilla :: 199
KEY_Egrave :: 200
KEY_Eacute :: 201
KEY_Ecircumflex :: 202
KEY_Ediaeresis :: 203
KEY_Igrave :: 204
KEY_Iacute :: 205
KEY_Icircumflex :: 206
KEY_Idiaeresis :: 207
KEY_ETH :: 208
KEY_Eth :: 208
KEY_Ntilde :: 209
KEY_Ograve :: 210
KEY_Oacute :: 211
KEY_Ocircumflex :: 212
KEY_Otilde :: 213
KEY_Odiaeresis :: 214
KEY_multiply :: 215
KEY_Oslash :: 216
KEY_Ooblique :: 216
KEY_Ugrave :: 217
KEY_Uacute :: 218
KEY_Ucircumflex :: 219
KEY_Udiaeresis :: 220
KEY_Yacute :: 221
KEY_THORN :: 222
KEY_Thorn :: 222
KEY_ssharp :: 223
KEY_agrave :: 224
KEY_aacute :: 225
KEY_acircumflex :: 226
KEY_atilde :: 227
KEY_adiaeresis :: 228
KEY_aring :: 229
KEY_ae :: 230
KEY_ccedilla :: 231
KEY_egrave :: 232
KEY_eacute :: 233
KEY_ecircumflex :: 234
KEY_ediaeresis :: 235
KEY_igrave :: 236
KEY_iacute :: 237
KEY_icircumflex :: 238
KEY_idiaeresis :: 239
KEY_eth :: 240
KEY_ntilde :: 241
KEY_ograve :: 242
KEY_oacute :: 243
KEY_ocircumflex :: 244
KEY_otilde :: 245
KEY_odiaeresis :: 246
KEY_division :: 247
KEY_oslash :: 248
KEY_ooblique :: 248
KEY_ugrave :: 249
KEY_uacute :: 250
KEY_ucircumflex :: 251
KEY_udiaeresis :: 252
KEY_yacute :: 253
KEY_thorn :: 254
KEY_ydiaeresis :: 255
KEY_Aogonek :: 417
KEY_breve :: 418
KEY_Lstroke :: 419
KEY_Lcaron :: 421
KEY_Sacute :: 422
KEY_Scaron :: 425
KEY_Scedilla :: 426
KEY_Tcaron :: 427
KEY_Zacute :: 428
KEY_Zcaron :: 430
KEY_Zabovedot :: 431
KEY_aogonek :: 433
KEY_ogonek :: 434
KEY_lstroke :: 435
KEY_lcaron :: 437
KEY_sacute :: 438
KEY_caron :: 439
KEY_scaron :: 441
KEY_scedilla :: 442
KEY_tcaron :: 443
KEY_zacute :: 444
KEY_doubleacute :: 445
KEY_zcaron :: 446
KEY_zabovedot :: 447
KEY_Racute :: 448
KEY_Abreve :: 451
KEY_Lacute :: 453
KEY_Cacute :: 454
KEY_Ccaron :: 456
KEY_Eogonek :: 458
KEY_Ecaron :: 460
KEY_Dcaron :: 463
KEY_Dstroke :: 464
KEY_Nacute :: 465
KEY_Ncaron :: 466
KEY_Odoubleacute :: 469
KEY_Rcaron :: 472
KEY_Uring :: 473
KEY_Udoubleacute :: 475
KEY_Tcedilla :: 478
KEY_racute :: 480
KEY_abreve :: 483
KEY_lacute :: 485
KEY_cacute :: 486
KEY_ccaron :: 488
KEY_eogonek :: 490
KEY_ecaron :: 492
KEY_dcaron :: 495
KEY_dstroke :: 496
KEY_nacute :: 497
KEY_ncaron :: 498
KEY_odoubleacute :: 501
KEY_rcaron :: 504
KEY_uring :: 505
KEY_udoubleacute :: 507
KEY_tcedilla :: 510
KEY_abovedot :: 511
KEY_Hstroke :: 673
KEY_Hcircumflex :: 678
KEY_Iabovedot :: 681
KEY_Gbreve :: 683
KEY_Jcircumflex :: 684
KEY_hstroke :: 689
KEY_hcircumflex :: 694
KEY_idotless :: 697
KEY_gbreve :: 699
KEY_jcircumflex :: 700
KEY_Cabovedot :: 709
KEY_Ccircumflex :: 710
KEY_Gabovedot :: 725
KEY_Gcircumflex :: 728
KEY_Ubreve :: 733
KEY_Scircumflex :: 734
KEY_cabovedot :: 741
KEY_ccircumflex :: 742
KEY_gabovedot :: 757
KEY_gcircumflex :: 760
KEY_ubreve :: 765
KEY_scircumflex :: 766
KEY_kra :: 930
KEY_kappa :: 930
KEY_Rcedilla :: 931
KEY_Itilde :: 933
KEY_Lcedilla :: 934
KEY_Emacron :: 938
KEY_Gcedilla :: 939
KEY_Tslash :: 940
KEY_rcedilla :: 947
KEY_itilde :: 949
KEY_lcedilla :: 950
KEY_emacron :: 954
KEY_gcedilla :: 955
KEY_tslash :: 956
KEY_ENG :: 957
KEY_eng :: 959
KEY_Amacron :: 960
KEY_Iogonek :: 967
KEY_Eabovedot :: 972
KEY_Imacron :: 975
KEY_Ncedilla :: 977
KEY_Omacron :: 978
KEY_Kcedilla :: 979
KEY_Uogonek :: 985
KEY_Utilde :: 989
KEY_Umacron :: 990
KEY_amacron :: 992
KEY_iogonek :: 999
KEY_eabovedot :: 1004
KEY_imacron :: 1007
KEY_ncedilla :: 1009
KEY_omacron :: 1010
KEY_kcedilla :: 1011
KEY_uogonek :: 1017
KEY_utilde :: 1021
KEY_umacron :: 1022

KEY_Numeric0 :: 268964352
KEY_Numeric1 :: 268964353
KEY_Numeric2 :: 268964354
KEY_Numeric3 :: 268964355
KEY_Numeric4 :: 268964356
KEY_Numeric5 :: 268964357
KEY_Numeric6 :: 268964358
KEY_Numeric7 :: 268964359
KEY_Numeric8 :: 268964360
KEY_Numeric9 :: 268964361
KEY_NumericStar :: 268964362
KEY_NumericPound :: 268964363
KEY_NumericA :: 268964364
KEY_NumericB :: 268964365
KEY_NumericC :: 268964366
KEY_NumericD :: 268964367

BUTTON_PRIMARY :: 1
BUTTON_MIDDLE :: 2
BUTTON_SECONDARY :: 3

EventAny :: distinct rawptr
EventExpose :: distinct rawptr
EventVisibility :: distinct rawptr
EventMotion :: distinct rawptr
EventButton :: distinct rawptr
EventTouch :: distinct rawptr
EventScroll :: distinct rawptr
EventKey :: distinct rawptr
EventCrossing :: distinct rawptr
EventFocus :: distinct rawptr
EventConfigure :: distinct rawptr
EventProperty :: distinct rawptr
EventSelection :: distinct rawptr
EventOwnerChange :: distinct rawptr
EventProximity :: distinct rawptr
EventDND :: distinct rawptr
EventWindowState :: distinct rawptr
EventSetting :: distinct rawptr
EventGrabBroken :: distinct rawptr
EventTouchpadSwipe :: distinct rawptr
EventTouchpadPinch :: distinct rawptr
EventPadButton :: distinct rawptr
EventPadAxis :: distinct rawptr
EventPadGroupMode :: distinct rawptr

Event :: struct #raw_union {
	type:           EventType,
	any:            EventAny,
	expose:         EventExpose,
	visibility:     EventVisibility,
	motion:         EventMotion,
	button:         EventButton,
	touch:          EventTouch,
	scroll:         EventScroll,
	key:            EventKey,
	crossing:       EventCrossing,
	focus_change:   EventFocus,
	configure:      EventConfigure,
	property:       EventProperty,
	selection:      EventSelection,
	owner_change:   EventOwnerChange,
	proximity:      EventProximity,
	dnd:            EventDND,
	window_state:   EventWindowState,
	setting:        EventSetting,
	grab_broken:    EventGrabBroken,
	touchpad_swipe: EventTouchpadSwipe,
	touchpad_pinch: EventTouchpadPinch,
	pad_button:     EventPadButton,
	pad_axis:       EventPadAxis,
	pad_group_mode: EventPadGroupMode,
}

// Gdk.EventType
EventType :: enum {
	Delete,
	MotionNotify,
	ButtonPress,
	ButtonRelease,
	KeyPress,
	KeyRelease,
	EnterNotify,
	LeaveNotify,
	FocusChange,
	ProximityIn,
	ProximityOut,
	DragEnter,
	DragLeave,
	DragMotion,
	DropStart,
	Scroll,
	GrabBroken,
	TouchBegin,
	TouchUpdate,
	TouchEnd,
	TouchCancel,
	TouchpadSwipe,
	TouchpadPinch,
	PadButtonPress,
	PadButtonRelease,
	PadRing,
	PadStrip,
	PadGroupMode,
	TouchpadHold,
	PadDial,
	EventLast,
}

// Gdk.ModifierType
ModifierType :: enum {
	NoModifierMask = 0,
	ShiftMask      = 1,
	LockMask       = 2,
	ControlMask    = 4,
	AltMask        = 8,
	Button1Mask    = 256,
	Button2Mask    = 512,
	Button3Mask    = 1024,
	Button4Mask    = 2048,
	Button5Mask    = 4096,
	SuperMask      = 67108864,
	HyperMask      = 134217728,
	MetaMask       = 268435456,
}

Rectangle :: struct {
	x:      c.int,
	y:      c.int,
	width:  c.int,
	height: c.int,
}

// @(default_calling_convention = "c")
// @(link_prefix = "gdk_")
// foreign gdk {
// 	event_get_modifier_type :: proc(event: ^Event) -> ModifierType ---
// 	// event_controller_get_modifier_type :: proc(controller: ^EventController) -> ModifierType ---
// 	// event_get_event_type:: proc() ---
// }

