;;<< GRAPHICS FUNCTIONS
;;========================================================================
;; command ORIGIN
;ORIGIN <x>,<y>[,<left>,<right>,<top>,<bottom>]
;Sets graphics screen origin and window
;If left, right, top, bottom are omitted then current window remains unchanged.
;(0,0) is the bottom, left of the screen.

command_ORIGIN:                   ;{{Addr=$c4de Code Calls/jump count: 0 Data use count: 1}}
        call    eval_two_int_params;{{c4de:cd8cc5}} params x,y
        push    bc                ;{{c4e1:c5}} 
        push    de                ;{{c4e2:d5}} 
        call    next_token_if_prev_is_comma;{{c4e3:cd41de}} 
        jr      nc,_command_origin_18;{{c4e6:3017}}  (+$17) only two params
        call    eval_two_int_params;{{c4e8:cd8cc5}} params left, right
        push    bc                ;{{c4eb:c5}} 
        push    de                ;{{c4ec:d5}} 
        call    next_token_if_comma;{{c4ed:cd15de}}  check for comma
        call    eval_two_int_params;{{c4f0:cd8cc5}} params top,bottom
        push    bc                ;{{c4f3:c5}} 
        ex      (sp),hl           ;{{c4f4:e3}} 
        call    GRA_WIN_HEIGHT    ;{{c4f5:cdd2bb}}  firmware function: gra win height
        pop     hl                ;{{c4f8:e1}} 
        pop     de                ;{{c4f9:d1}} 
        ex      (sp),hl           ;{{c4fa:e3}} 
        call    GRA_WIN_WIDTH     ;{{c4fb:cdcfbb}}  firmware function: gra win width
        pop     hl                ;{{c4fe:e1}} 
_command_origin_18:               ;{{Addr=$c4ff Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{c4ff:d1}} 
        ex      (sp),hl           ;{{c500:e3}} 
        call    GRA_SET_ORIGIN    ;{{c501:cdc9bb}}  firmware function: gra set origin
        pop     hl                ;{{c504:e1}} 
        ret                       ;{{c505:c9}} 

;;=============================================================================
;; command CLG
;CLG [<masked ink>]
;Clear the graphics screen to the given ink. If no ink is given the value
;from the last call to CLG is used, or ink 0 if no CLG command has been executed

command_CLG:                      ;{{Addr=$c506 Code Calls/jump count: 0 Data use count: 1}}
        call    is_next_02        ;{{c506:cd3dde}} 
        call    nc,validate_and_set_graphics_paper;{{c509:d4b4c5}} 
        push    hl                ;{{c50c:e5}} 
        call    GRA_CLEAR_WINDOW  ;{{c50d:cddbbb}}  firmware function: GRA CLEAR WINDOW
        pop     hl                ;{{c510:e1}} 
        ret                       ;{{c511:c9}} 

;;========================================================================
;; command FILL
command_FILL:                     ;{{Addr=$c512 Code Calls/jump count: 0 Data use count: 1}}
        call    check_value_is_less_than_16;{{c512:cd71c2}}  check parameter is less than 16
        push    hl                ;{{c515:e5}} 
        push    af                ;{{c516:f5}} 
        call    strings_area_garbage_collection;{{c517:cd64fc}} (free up?) and calc free memory?
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{c51a:cdfcf6}} 
        ld      bc,$001d          ;{{c51d:011d00}} 
        call    compare_HL_BC     ;{{c520:cddeff}}  HL=BC?
        ld      a,$07             ;{{c523:3e07}} Memory full error
        jp      c,raise_error     ;{{c525:da55cb}} 
        ex      de,hl             ;{{c528:eb}} 
        pop     af                ;{{c529:f1}} 
        call    GRA_FILL          ;{{c52a:cd52bd}}  firmware function: GRA FILL
        pop     hl                ;{{c52d:e1}} 
        ret                       ;{{c52e:c9}} 

;;========================================================================
;; command MOVE
;MOVE <x coordinate>,<y coordinate>
;Moves the graphic cursor

command_MOVE:                     ;{{Addr=$c52f Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_MOVE_ABSOLUTE;{{c52f:01c0bb}}  firmware function: gra move absolute
        jr      plotdraw_general_function;{{c532:1817}} 

;;========================================================================
;; command MOVER
;MOVER <x coordinate>,<y coordinate>
;Moves the graphic cursor relative to it's current position

command_MOVER:                    ;{{Addr=$c534 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_MOVE_RELATIVE;{{c534:01c3bb}}  firmware function: gra move relative
        jr      plotdraw_general_function;{{c537:1812}} 

;;========================================================================
;; command DRAW
;DRAW <x coordinate>,<y coordinate>[,<masked ink>]
;Draw a line on the screen from the current position to that given.
;If no masked ink is specified that given in the last call to DRAW, DRAWR, PLOT or PLOTR 
;will be used. If no such commands have been used, ink 1 will be used.

command_DRAW:                     ;{{Addr=$c539 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_LlNE_ABSOLUTE;{{c539:01f6bb}}  firmware function: gra line absolute
        jr      plotdraw_general_function;{{c53c:180d}} 

;;========================================================================
;; command DRAWR
;DRAWR <x offset>,<y offset>[,<masked ink>]
;Draws a line from the current position to the given offset from that position
;See DRAW

command_DRAWR:                    ;{{Addr=$c53e Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_LINE_RELATIVE;{{c53e:01f9bb}}  firmware function: gra line relative
        jr      plotdraw_general_function;{{c541:1808}} 

;;========================================================================
;; command PLOT
;PLOT <x coordinate>,<y coordinate>[,<masked ink>]
;Plots a pixel at the given location
;See DRAW

command_PLOT:                     ;{{Addr=$c543 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_PLOT_ABSOLUTE;{{c543:01eabb}}  firmware function: gra plot absolute
        jr      plotdraw_general_function;{{c546:1803}} 

;;========================================================================
;; command PLOTR
;PLOTR <x offset>,<y offset>[,<masked ink>]
;Plots a pixel at the given offset from the current position
;See DRAW

command_PLOTR:                    ;{{Addr=$c548 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_PLOT_RELATIVE;{{c548:01edbb}}  firmware function: gra plot relative

;;+------------------------------------------------------------------------
;; plot/draw general function
;;reads parameters and calls the address in BC to do the actual function
plotdraw_general_function:        ;{{Addr=$c54b Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{c54b:c5}} 
        call    eval_two_int_params;{{c54c:cd8cc5}} 
        call    next_token_if_prev_is_comma;{{c54f:cd41de}} 
        jr      nc,_plotdraw_general_function_6;{{c552:3005}}  (+$05)
        cp      $2c               ;{{c554:fe2c}}  ','
        call    nz,validate_and_set_graphics_pen;{{c556:c4bac5}} 

_plotdraw_general_function_6:     ;{{Addr=$c559 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c559:cd41de}} 
        jr      nc,_plotdraw_general_function_13;{{c55c:300a}}  (+$0a)
        ld      a,$04             ;{{c55e:3e04}} 
        call    check_byte_value_in_range;{{c560:cd13c2}}  check value is in range
        push    hl                ;{{c563:e5}} 
        call    SCR_ACCESS        ;{{c564:cd59bc}}  firmware function: scr access 
        pop     hl                ;{{c567:e1}} 

_plotdraw_general_function_13:    ;{{Addr=$c568 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{c568:e3}} 
        push    bc                ;{{c569:c5}} 
        ex      (sp),hl           ;{{c56a:e3}} 
        pop     bc                ;{{c56b:c1}} 
        call    JP_BC             ;{{c56c:cdfcff}}  JP (BC)
        pop     hl                ;{{c56f:e1}} 
        ret                       ;{{c570:c9}} 

;;========================================================================
;; function TEST
;TEST(<x coordinate>,<y coordinate>)
;Returns the ink at the given pixel location. Also moves th graphics cursor.
;If the location is outside the current graphics window the value used in the last CLG
;command is returned. If no CLG command hs been used returns 0

function_TEST:                    ;{{Addr=$c571 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_TEST_ABSOLUTE;{{c571:01f0bb}}  firmware function: GRA TEST ABSOLUTE
        jr      _function_testr_1 ;{{c574:1803}}  

;;========================================================================
;; function TESTR
;TESTR(<x offset>,<y offset>)
;As TEST but the position is relative to the current graphics cursor position

function_TESTR:                   ;{{Addr=$c576 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_TEST_RELATIVE;{{c576:01f3bb}}  firmware function: GRA TEST RELATIVE
;;------------------------------------------------------------------------
_function_testr_1:                ;{{Addr=$c579 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{c579:c5}} 
        call    eval_two_int_params;{{c57a:cd8cc5}} 
        call    next_token_if_close_bracket;{{c57d:cd1dde}}  check for close bracket
        ex      (sp),hl           ;{{c580:e3}} 
        push    bc                ;{{c581:c5}} 
        ex      (sp),hl           ;{{c582:e3}} 
        pop     bc                ;{{c583:c1}} 
        call    JP_BC             ;{{c584:cdfcff}}  JP (BC)
        call    store_A_in_accumulator_as_INT;{{c587:cd32ff}} 
        pop     hl                ;{{c58a:e1}} 
        ret                       ;{{c58b:c9}} 
;;------------------------------------------------------------------------
;;=eval two int params
eval_two_int_params:              ;{{Addr=$c58c Code Calls/jump count: 5 Data use count: 0}}
        call    eval_expr_as_int  ;{{c58c:cdd8ce}}  get number
        push    de                ;{{c58f:d5}} 
        call    next_token_if_comma;{{c590:cd15de}}  check for comma
        call    eval_expr_as_int  ;{{c593:cdd8ce}}  get number
        ld      b,d               ;{{c596:42}} 
        ld      c,e               ;{{c597:4b}} 
        pop     de                ;{{c598:d1}} 
        ret                       ;{{c599:c9}} 

;;========================================================================
;; command GRAPHICS PAPER / GRAPHICS PEN and set graphics draw mode
command_GRAPHICS_PAPER__GRAPHICS_PEN_and_set_graphics_draw_mode:;{{Addr=$c59a Code Calls/jump count: 0 Data use count: 1}}
        cp      $ba               ;{{c59a:feba}}  token for "PAPER"
        jr      z,eval_and_set_graphics_paper;{{c59c:2813}}  set graphics paper
      
        call    next_token_if_equals_inline_data_byte;{{c59e:cd25de}} 
        defb $bb                  ; token for "PEN"
        cp      $2c               ;{{c5a2:fe2c}}  ','
        call    nz,validate_and_set_graphics_pen;{{c5a4:c4bac5}}  set graphics pen

        call    next_token_if_prev_is_comma;{{c5a7:cd41de}} 
        ret     nc                ;{{c5aa:d0}} 

;;=validate and set graphics background mode
        call    check_number_is_less_than_2;{{c5ab:cd20c2}}  check number is less than 2
        jp      GRA_SET_BACK      ;{{c5ae:c346bd}}  firmware function: GRA SET BACK

;;=eval and set graphics paper
eval_and_set_graphics_paper:      ;{{Addr=$c5b1 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c5b1:cd2cde}}  get next token skipping space
;;=validate and set graphics paper
validate_and_set_graphics_paper:  ;{{Addr=$c5b4 Code Calls/jump count: 1 Data use count: 0}}
        call    check_value_is_less_than_16;{{c5b4:cd71c2}}  check parameter is less than 16
        jp      GRA_SET_PAPER     ;{{c5b7:c3e4bb}}  firmware function: GRA SET PAPER	

;;=validate and set graphics pen
validate_and_set_graphics_pen:    ;{{Addr=$c5ba Code Calls/jump count: 2 Data use count: 0}}
        call    check_value_is_less_than_16;{{c5ba:cd71c2}}  check parameter is less than 16
        jp      GRA_SET_PEN       ;{{c5bd:c3debb}}  firmware function: GRA SET PEN

;;========================================================================
;; command MASK

command_MASK:                     ;{{Addr=$c5c0 Code Calls/jump count: 0 Data use count: 1}}
        cp      $2c               ;{{c5c0:fe2c}}  ','
        jr      z,_command_mask_4 ;{{c5c2:2806}}  

        call    eval_expr_as_byte_or_error;{{c5c4:cdb8ce}}  get number and check it's less than 255 
        call    GRA_SET_LINE_MASK ;{{c5c7:cd4cbd}}  firmware function: GRA SET LINE MASK	

_command_mask_4:                  ;{{Addr=$c5ca Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c5ca:cd41de}} 
        ret     nc                ;{{c5cd:d0}} 

        call    check_number_is_less_than_2;{{c5ce:cd20c2}}  check number is less than 2
        jp      GRA_SET_FIRST     ;{{c5d1:c349bd}}  firmware function: GRA SET FIRST





