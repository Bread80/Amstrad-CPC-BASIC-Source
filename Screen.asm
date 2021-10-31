;;<< SCREEN HANDLING FUNCTIONS
;;========================================================================
;; command PEN

command_PEN:                      ;{{Addr=$c224 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c224:cde5c1}} 
        ld      bc,TXT_SET_PEN    ;{{c227:0190bb}}  firmware function: txt set pen
        call    nz,_command_paper_2;{{c22a:c43fc2}} 
        call    next_token_if_prev_is_comma;{{c22d:cd41de}} 
        ret     nc                ;{{c230:d0}} 
        call    check_number_is_less_than_2;{{c231:cd20c2}}  check number is less than 2
        ld      bc,TXT_SET_BACK   ;{{c234:019fbb}}  firmware function: txt set back
        jr      _command_paper_3  ;{{c237:1809}} 

;;========================================================================
;; command PAPER

command_PAPER:                    ;{{Addr=$c239 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c239:cde5c1}} 
        ld      bc,TXT_SET_PAPER  ;{{c23c:0196bb}}  firmware function: txt set paper
_command_paper_2:                 ;{{Addr=$c23f Code Calls/jump count: 1 Data use count: 0}}
        call    check_value_is_less_than_16;{{c23f:cd71c2}}  check parameter is less than 16

_command_paper_3:                 ;{{Addr=$c242 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c242:e5}} 
        call    JP_BC             ;{{c243:cdfcff}}  JP (BC)
        pop     hl                ;{{c246:e1}} 
        ret                       ;{{c247:c9}} 

;;=========================================================================
;; command BORDER

command_BORDER:                   ;{{Addr=$c248 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_one_or_two_numbers_less_than_32;{{c248:cd62c2}}  one or two numbers each less than 32
;; B,C = numbers which are the inks
        push    hl                ;{{c24b:e5}} 
        call    SCR_SET_BORDER    ;{{c24c:cd38bc}}  firmware function: scr set border
        pop     hl                ;{{c24f:e1}} 
        ret                       ;{{c250:c9}} 

;;=========================================================================
;; command INK

command_INK:                      ;{{Addr=$c251 Code Calls/jump count: 0 Data use count: 1}}
        call    check_value_is_less_than_16;{{c251:cd71c2}}  check parameter is less than 16
        push    af                ;{{c254:f5}} 
        call    next_token_if_comma;{{c255:cd15de}}  check for comma
        call    eval_one_or_two_numbers_less_than_32;{{c258:cd62c2}}  one or two numbers each less than 32

;; B,C = numbers which are the inks
        pop     af                ;{{c25b:f1}} 
        push    hl                ;{{c25c:e5}} 
        call    SCR_SET_INK       ;{{c25d:cd32bc}}  firmware function: scr set ink
        pop     hl                ;{{c260:e1}} 
        ret                       ;{{c261:c9}} 

;;=========================================================================
;; eval one or two numbers less than 32
;; used to get ink values
;;
;; first number in B, second number in C

eval_one_or_two_numbers_less_than_32:;{{Addr=$c262 Code Calls/jump count: 2 Data use count: 0}}
        call    _eval_one_or_two_numbers_less_than_32_4;{{c262:cd6ac2}} 
        ld      b,c               ;{{c265:41}} 
        call    next_token_if_prev_is_comma;{{c266:cd41de}} 
        ret     nc                ;{{c269:d0}} 

_eval_one_or_two_numbers_less_than_32_4:;{{Addr=$c26a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$20             ;{{c26a:3e20}} 
        call    check_byte_value_in_range;{{c26c:cd13c2}}  check value is in range
        ld      c,a               ;{{c26f:4f}} 
        ret                       ;{{c270:c9}} 

;;========================================================================
;; check value is less than 16
check_value_is_less_than_16:      ;{{Addr=$c271 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,$10             ;{{c271:3e10}} 
        jr      check_byte_value_in_range;{{c273:189e}}  check value is in range            

;;========================================================================
;; command MODE

command_MODE:                     ;{{Addr=$c275 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$03             ;{{c275:3e03}} 
        call    check_byte_value_in_range;{{c277:cd13c2}}  check value is in range
;; A = mode
        push    hl                ;{{c27a:e5}} 
        call    SCR_SET_MODE      ;{{c27b:cd0ebc}}  firmware function: scr set mode
        pop     hl                ;{{c27e:e1}} 
        ret                       ;{{c27f:c9}} 

;;=============================================================================
;; command CLS

command_CLS:                      ;{{Addr=$c280 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c280:cde5c1}} 
        push    hl                ;{{c283:e5}} 
        call    TXT_CLEAR_WINDOW  ;{{c284:cd6cbb}}  firmware function: txt clear window
        pop     hl                ;{{c287:e1}} 
        ret                       ;{{c288:c9}} 

;;=eval stream param, and exec TOS, and swap back
eval_stream_param_and_exec_TOS_and_swap_back:;{{Addr=$c289 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number;{{c289:cd0dc2}} 
        cp      $08               ;{{c28c:fe08}} 
        jr      nc,raise_Improper_Argument_error;{{c28e:308d}}  (-$73)
;;=exec TOS on stream and swap back
exec_tos_on_stream_and_swap_back_B:;{{Addr=$c290 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{c290:f5}} 
        call    next_token_if_close_bracket;{{c291:cd1dde}}  check for close bracket
        pop     af                ;{{c294:f1}} 
        jp      exec_TOS_on_stream_and_swap_back;{{c295:c3ecc1}} 

;;========================================================================
;; function COPYCHR$

function_COPYCHR:                 ;{{Addr=$c298 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_stream_param_and_exec_TOS_and_swap_back;{{c298:cd89c2}} 
        call    TXT_RD_CHAR       ;{{c29b:cd60bb}}  firmware function: txt rd char
        jp      _function_chr_2   ;{{c29e:c378fa}} 

;;========================================================================
;; function VPOS
function_VPOS:                    ;{{Addr=$c2a1 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_stream_param_and_exec_TOS_and_swap_back;{{c2a1:cd89c2}} 
        push    hl                ;{{c2a4:e5}} 
        call    get_Y_cursor_position;{{c2a5:cdc7c2}}  get y cursor position
        jr      _function_pos_4   ;{{c2a8:180a}}  (+$0a)

;;========================================================================
;; function POS
function_POS:                     ;{{Addr=$c2aa Code Calls/jump count: 0 Data use count: 1}}
        call    eval_and_validate_stream_number;{{c2aa:cd0dc2}} 
        call    exec_tos_on_stream_and_swap_back_B;{{c2ad:cd90c2}} 
        push    hl                ;{{c2b0:e5}} 
        call    get_xpos_of_output_stream;{{c2b1:cdb9c2}} 
_function_pos_4:                  ;{{Addr=$c2b4 Code Calls/jump count: 1 Data use count: 0}}
        call    store_A_in_accumulator_as_INT;{{c2b4:cd32ff}} 
        pop     hl                ;{{c2b7:e1}} 
        ret                       ;{{c2b8:c9}} 

;;========================================================================
;;=get xpos of output stream
;stream can be stream, file or printer
get_xpos_of_output_stream:        ;{{Addr=$c2b9 Code Calls/jump count: 4 Data use count: 0}}
        call    get_output_stream ;{{c2b9:cdbec1}} 
        ld      a,(printer_stream_current_x_position_);{{c2bc:3a08ac}} 
        ret     z                 ;{{c2bf:c8}} 

        ld      a,(file_output_stream_current_line_position);{{c2c0:3a0aac}} 
        ret     nc                ;{{c2c3:d0}} 

        jp      get_x_cursor_position;{{c2c4:c3ecc3}} 

;;========================================================================
;; get Y cursor position
get_Y_cursor_position:            ;{{Addr=$c2c7 Code Calls/jump count: 2 Data use count: 0}}
        call    TXT_GET_CURSOR    ;{{c2c7:cd78bb}}  firmware function: txt get cursor
        call    TXT_VALIDATE      ;{{c2ca:cd87bb}}  firmware function: txt validate
        ld      a,l               ;{{c2cd:7d}} 
        ret                       ;{{c2ce:c9}} 

;;========================================================================
;;=pos is xpos in D in range
pos_is_xpos_in_D_in_range:        ;{{Addr=$c2cf Code Calls/jump count: 2 Data use count: 0}}
        call    get_output_stream ;{{c2cf:cdbec1}} 
        jr      z,poss_get_screen_width;{{c2d2:280d}}  (+$0d)
        ret     nc                ;{{c2d4:d0}} 

        push    de                ;{{c2d5:d5}} 
        push    hl                ;{{c2d6:e5}} 
        call    TXT_GET_WINDOW    ;{{c2d7:cd69bb}}  firmware function: txt get window
        ld      a,d               ;{{c2da:7a}} 
        sub     h                 ;{{c2db:94}} 
        inc     a                 ;{{c2dc:3c}} 
        pop     hl                ;{{c2dd:e1}} 
        pop     de                ;{{c2de:d1}} 
        scf                       ;{{c2df:37}} 
        ret                       ;{{c2e0:c9}} 

;;=poss get screen width
poss_get_screen_width:            ;{{Addr=$c2e1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(WIDTH_)        ;{{c2e1:3a09ac}} 
        cp      $ff               ;{{c2e4:feff}} 
        ret                       ;{{c2e6:c9}} 

;;=poss validate xpos in D
poss_validate_xpos_in_D:          ;{{Addr=$c2e7 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{c2e7:e5}} 
        ld      h,a               ;{{c2e8:67}} 
        call    pos_is_xpos_in_D_in_range;{{c2e9:cdcfc2}} 
        ccf                       ;{{c2ec:3f}} 
        jr      c,_poss_validate_xpos_in_d_15;{{c2ed:380e}}  (+$0e)
        ld      l,a               ;{{c2ef:6f}} 
        call    get_xpos_of_output_stream;{{c2f0:cdb9c2}} 
        dec     a                 ;{{c2f3:3d}} 
        scf                       ;{{c2f4:37}} 
        jr      z,_poss_validate_xpos_in_d_15;{{c2f5:2806}}  (+$06)
        add     a,h               ;{{c2f7:84}} 
        ccf                       ;{{c2f8:3f}} 
        jr      nc,_poss_validate_xpos_in_d_15;{{c2f9:3002}}  (+$02)
        dec     a                 ;{{c2fb:3d}} 
        cp      l                 ;{{c2fc:bd}} 
_poss_validate_xpos_in_d_15:      ;{{Addr=$c2fd Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{c2fd:e1}} 
        ret                       ;{{c2fe:c9}} 

;;========================================================================
;; command LOCATE

command_LOCATE:                   ;{{Addr=$c2ff Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c2ff:cde5c1}} 
        call    eval_two_params_minus_1_to_D_E;{{c302:cd51c3}} 
        push    hl                ;{{c305:e5}} 
        ex      de,hl             ;{{c306:eb}} 
        inc     h                 ;{{c307:24}} 
        inc     l                 ;{{c308:2c}} 
        call    TXT_SET_CURSOR    ;{{c309:cd75bb}}  firmware function: txt set cursor
        pop     hl                ;{{c30c:e1}} 
        ret                       ;{{c30d:c9}} 

;;========================================================================
;; command WINDOW, WINDOW SWAP
command_WINDOW_WINDOW_SWAP:       ;{{Addr=$c30e Code Calls/jump count: 0 Data use count: 1}}
        cp      $e7               ;{{c30e:fee7}} 
        jr      z,window_swap     ;{{c310:2816}}  (+$16)
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c312:cde5c1}} 
        call    eval_two_params_minus_1_to_D_E;{{c315:cd51c3}} 
        push    de                ;{{c318:d5}} 
        call    next_token_if_comma;{{c319:cd15de}}  check for comma
        call    eval_two_params_minus_1_to_D_E;{{c31c:cd51c3}} 
        ex      (sp),hl           ;{{c31f:e3}} 
        ld      a,d               ;{{c320:7a}} 
        ld      d,l               ;{{c321:55}} 
        ld      l,a               ;{{c322:6f}} 
        call    TXT_WIN_ENABLE    ;{{c323:cd66bb}}  firmware function: txt win enable
        pop     hl                ;{{c326:e1}} 
        ret                       ;{{c327:c9}} 

;;========================================================================
;;=window swap
window_swap:                      ;{{Addr=$c328 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c328:cd2cde}}  get next token skipping space
        call    eval_number_less_than_8;{{c32b:cd3ec3}}  get number less than 8
        ld      c,a               ;{{c32e:4f}} 
        call    next_token_if_prev_is_comma;{{c32f:cd41de}} 
        ld      a,$00             ;{{c332:3e00}} 
        call    c,eval_number_less_than_8;{{c334:dc3ec3}}  get number less than 8
        ld      b,a               ;{{c337:47}} 
        push    hl                ;{{c338:e5}} 
        call    TXT_SWAP_STREAMS  ;{{c339:cdb7bb}}  firmware function: txt swap streams
        pop     hl                ;{{c33c:e1}} 
        ret                       ;{{c33d:c9}} 

;;=eval number less than 8
eval_number_less_than_8:          ;{{Addr=$c33e Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$08             ;{{c33e:3e08}} 
        jp      check_byte_value_in_range;{{c340:c313c2}}  check value is in range

;;========================================================================
;; command TAG
command_TAG:                      ;{{Addr=$c343 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c343:cde5c1}} 
        ld      a,$ff             ;{{c346:3eff}} 
        jr      _command_tagoff_2 ;{{c348:1804}}  (+$04)

;;========================================================================
;; command TAGOFF
command_TAGOFF:                   ;{{Addr=$c34a Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c34a:cde5c1}} 
        xor     a                 ;{{c34d:af}} 
_command_tagoff_2:                ;{{Addr=$c34e Code Calls/jump count: 1 Data use count: 0}}
        jp      TXT_SET_GRAPHIC   ;{{c34e:c363bb}}  firmware function: txt set graphic

;;-------------------------------------------------------------------------
;;=eval two params minus 1 to D E
eval_two_params_minus_1_to_D_E:   ;{{Addr=$c351 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_param_minus_1_to_E;{{c351:cd58c3}} 
        ld      d,e               ;{{c354:53}} 
        call    next_token_if_comma;{{c355:cd15de}}  check for comma

;;--------------------------------------------------------------------------
;;=eval param minus 1 to E
eval_param_minus_1_to_E:          ;{{Addr=$c358 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c358:d5}} 
        call    eval_expr_as_int_less_than_256;{{c359:cdc3ce}} 
        pop     de                ;{{c35c:d1}} 
        ld      e,a               ;{{c35d:5f}} 
        dec     e                 ;{{c35e:1d}} 
        ret                       ;{{c35f:c9}} 

;;========================================================================
;; command CURSOR

command_CURSOR:                   ;{{Addr=$c360 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c360:cde5c1}} 
        jr      z,_command_cursor_6;{{c363:280a}}  (+$0a)
        call    check_number_is_less_than_2;{{c365:cd20c2}}  check number is less than 2
        or      a                 ;{{c368:b7}} 
        call    z,TXT_CUR_OFF     ;{{c369:cc84bb}}  firmware function: txt cur off
        call    nz,TXT_CUR_ON     ;{{c36c:c481bb}}  firmware function: txt cur on
_command_cursor_6:                ;{{Addr=$c36f Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c36f:cd41de}} 
        ret     nc                ;{{c372:d0}} 

        call    check_number_is_less_than_2;{{c373:cd20c2}}  check number is less than 2
        or      a                 ;{{c376:b7}} 
        jp      z,TXT_CUR_DISABLE ;{{c377:ca7ebb}}  firmware function: txt cur disable
        jp      TXT_CUR_ENABLE    ;{{c37a:c37bbb}}  firmware function: txt cur enable





