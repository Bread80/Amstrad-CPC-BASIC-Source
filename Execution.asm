;;<< PROGRAM EXECUTION
;;< Execute tokenised code (except expressions)
;;< Includes token handling utilities, TRON, TROFF, 
;;< and the command/statement look up table.
;;============================================
;; next token if comma
next_token_if_comma:              ;{{Addr=$de15 Code Calls/jump count: 23 Data use count: 0}}
        ld      a,$2c             ;{{de15:3e2c}}  ','
        jr      next_token_if_value_in_A;{{de17:1810}}  

;;+----------------------------------------------------------
;; next token if open bracket
next_token_if_open_bracket:       ;{{Addr=$de19 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,$28             ;{{de19:3e28}}  '('
        jr      next_token_if_value_in_A;{{de1b:180c}}  

;;+----------------------------------------------------------
;; next token if close bracket
next_token_if_close_bracket:      ;{{Addr=$de1d Code Calls/jump count: 16 Data use count: 0}}
        ld      a,$29             ;{{de1d:3e29}}  ')'
        jr      next_token_if_value_in_A;{{de1f:1808}} 

;;+----------------------------------------------------------
;; next token if equals sign
next_token_if_equals_sign:        ;{{Addr=$de21 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,$ef             ;{{de21:3eef}} token for '='
        jr      next_token_if_value_in_A;{{de23:1804}} 

;;+----------------------------------------------------------
;; next token if equals inline data byte
next_token_if_equals_inline_data_byte:;{{Addr=$de25 Code Calls/jump count: 15 Data use count: 0}}
        ex      (sp),hl           ;{{de25:e3}}  get return address from top of stack/save HL
        ld      a,(hl)            ;{{de26:7e}}  get byte
        inc     hl                ;{{de27:23}}  increment pointer
        ex      (sp),hl           ;{{de28:e3}}  put return address back to stack/restore HL

;;+----------------------------------------------------------
;; next token if value in A
;; A = char to check against
next_token_if_value_in_A:         ;{{Addr=$de29 Code Calls/jump count: 4 Data use count: 0}}
        cp      (hl)              ;{{de29:be}} 
        jr      nz,raise_syntax_error_D;{{de2a:200f}}  (+$0f)

;;=get next token skipping space
;; skip spaces
get_next_token_skipping_space:    ;{{Addr=$de2c Code Calls/jump count: 53 Data use count: 1}}
        inc     hl                ;{{de2c:23}} 
        ld      a,(hl)            ;{{de2d:7e}} 
        cp      $20               ;{{de2e:fe20}}  ' '
        jr      z,get_next_token_skipping_space;{{de30:28fa}} 
 

        cp      $01               ;{{de32:fe01}} 
        ret     nc                ;{{de34:d0}} 
        or      a                 ;{{de35:b7}} 
        ret                       ;{{de36:c9}} 

;;+----------------------------------------------------------
;;syntax error if not $02
syntax_error_if_not_02:           ;{{Addr=$de37 Code Calls/jump count: 16 Data use count: 0}}
        ld      a,(hl)            ;{{de37:7e}} 
        cp      $02               ;{{de38:fe02}} 
        ret     c                 ;{{de3a:d8}} 

;;=raise syntax error
raise_syntax_error_D:             ;{{Addr=$de3b Code Calls/jump count: 1 Data use count: 0}}
        jr      raise_syntax_error_E;{{de3b:186a}}  (+$6a)

;;=is next $02
;Carry set if EOLN or end of statement
is_next_02:                       ;{{Addr=$de3d Code Calls/jump count: 9 Data use count: 0}}
        ld      a,(hl)            ;{{de3d:7e}} 
        cp      $02               ;{{de3e:fe02}} 
        ret                       ;{{de40:c9}} 

;;=next token if prev is comma
next_token_if_prev_is_comma:      ;{{Addr=$de41 Code Calls/jump count: 44 Data use count: 0}}
        dec     hl                ;{{de41:2b}} 
        call    get_next_token_skipping_space;{{de42:cd2cde}}  get next token skipping space
        xor     $2c               ;{{de45:ee2c}}  ','
        ret     nz                ;{{de47:c0}} 

        call    get_next_token_skipping_space;{{de48:cd2cde}}  get next token skipping space
        scf                       ;{{de4b:37}} 
        ret                       ;{{de4c:c9}} 

;;=======================================================================
;; skip space, tab or line feed
skip_space_tab_or_line_feed:      ;{{Addr=$de4d Code Calls/jump count: 20 Data use count: 0}}
        ld      a,(hl)            ;{{de4d:7e}} 
        inc     hl                ;{{de4e:23}} 
        cp      $20               ;{{de4f:fe20}}  ' '
        jr      z,skip_space_tab_or_line_feed;{{de51:28fa}}  skip space, lf or tab          
        cp      $09               ;{{de53:fe09}}  TAB
        jr      z,skip_space_tab_or_line_feed;{{de55:28f6}}  skip space, lf or tab          
        cp      $0a               ;{{de57:fe0a}}  LF
        jr      z,skip_space_tab_or_line_feed;{{de59:28f2}}  skip space, lf or tab          
        dec     hl                ;{{de5b:2b}} 
        ret                       ;{{de5c:c9}} 



;**tk
;;=======================================================================
;; execute tokenised line
execute_tokenised_line:           ;{{Addr=$de5d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_of_byte_before_current_statement);{{de5d:2a1bae}} 

;;=execute line atHL
;HL points to first token, NOT line number
execute_line_atHL:                ;{{Addr=$de60 Code Calls/jump count: 7 Data use count: 0}}
        ld      (address_of_byte_before_current_statement),hl;{{de60:221bae}} HL=current execution address
        call    KL_POLL_SYNCHRONOUS;{{de63:cd21b9}} handle pending events
        call    c,prob_process_pending_events;{{de66:dcb2c8}} 
        call    get_next_token_skipping_space;{{de69:cd2cde}}  get next token skipping space
        call    nz,execute_command_token;{{de6c:c48fde}} end of buffer?
        ld      a,(hl)            ;{{de6f:7e}} 
        cp      $01               ;{{de70:fe01}} next statement on same line
        jr      z,execute_line_atHL;{{de72:28ec}}  (-$14) Loop until end of line

        jr      nc,raise_syntax_error_E;{{de74:3031}}  (+$31)
        inc     hl                ;{{de76:23}} 

;;=execute end of line
execute_end_of_line:              ;{{Addr=$de77 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{de77:7e}} Next line number?
        inc     hl                ;{{de78:23}} 
        or      (hl)              ;{{de79:b6}} 
        inc     hl                ;{{de7a:23}} 
        jr      z,end_execution   ;{{de7b:280f}}  (+$0f) line number zero = end of code marker

        ld      (address_of_line_number_LB_of_line_of_cur),hl;{{de7d:221dae}}  Start of current line
        inc     hl                ;{{de80:23}} 
        ld      a,(trace_flag)    ;{{de81:3a1fae}} trace on??
        or      a                 ;{{de84:b7}} 
        jr      z,execute_line_atHL;{{de85:28d9}}  (-$27) if not loop - execute next line
        call    do_trace          ;{{de87:cdcade}}  trace
        jr      execute_line_atHL ;{{de8a:18d4}}  (-$2c) loop - execute next line

;;====================================
;;end execution
end_execution:                    ;{{Addr=$de8c Code Calls/jump count: 1 Data use count: 0}}
        jp      prob_end_of_program;{{de8c:c349cc}} 

;;============================================
;;execute command token
;A=token
;Tokens >= &80 are tokenised words
;the only token < &80 we should have here are for bar commands or variable names (implicit LET)
execute_command_token:            ;{{Addr=$de8f Code Calls/jump count: 2 Data use count: 0}}
        add     a,a               ;{{de8f:87}} 
        jp      nc,BAR_command_or_implicit_LET;{{de90:d289d6}} token < &80: either a bar command or a variable (implicit LET)
        cp tokenise_a_BASIC_line - command_to_code_address_LUT - 1;{{de93:fec3}} version with formula;WARNING: Code area used as literal
;OLD de93 fec3      cp      $c3              ;the last valid token is &e1 which doubles to &c2, so >= &c3 is error
        jr      nc,raise_syntax_error_E;{{de95:3010}}  (+$10)
        ex      de,hl             ;{{de97:eb}} 
        add     a,command_to_code_address_LUT and $ff;{{de98:c6e0}} $e0 lookup token in table
        ld      l,a               ;{{de9a:6f}} 
        adc     a,command_to_code_address_LUT >> 8;{{de9b:cede}} $de
        sub     l                 ;{{de9d:95}} 
        ld      h,a               ;{{de9e:67}} 
        ld      c,(hl)            ;{{de9f:4e}} code address into BC
        inc     hl                ;{{dea0:23}} 
        ld      b,(hl)            ;{{dea1:46}} 
        push    bc                ;{{dea2:c5}} push so we'll return to code with next token
        ex      de,hl             ;{{dea3:eb}} 
        jp      get_next_token_skipping_space;{{dea4:c32cde}}  get next token skipping space

;;=raise syntax error
raise_syntax_error_E:             ;{{Addr=$dea7 Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Syntax_Error;{{dea7:c349cb}}  Error: Syntax Error

;;========================================================================
;; zero current line address
zero_current_line_address:        ;{{Addr=$deaa Code Calls/jump count: 7 Data use count: 0}}
        ld      hl,$0000          ;{{deaa:210000}} ##LIT##

;;=set current line address
set_current_line_address:         ;{{Addr=$dead Code Calls/jump count: 15 Data use count: 0}}
        ld      (address_of_line_number_LB_of_line_of_cur),hl;{{dead:221dae}} 
        ret                       ;{{deb0:c9}} 

;;========================================================================
;;get current line address
get_current_line_address:         ;{{Addr=$deb1 Code Calls/jump count: 12 Data use count: 0}}
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{deb1:2a1dae}} 
        ret                       ;{{deb4:c9}} 

;;========================================================================
;; get current line number
;; returns Z if current line number address is zero
;; returns C if we HL returns a current line number
get_current_line_number:          ;{{Addr=$deb5 Code Calls/jump count: 10 Data use count: 0}}
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{deb5:2a1dae}} address of current line

;;+get line number atHL
get_line_number_atHL:             ;{{Addr=$deb8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{deb8:7c}} 
        or      l                 ;{{deb9:b5}} 
        ret     z                 ;{{deba:c8}} ; no current line 

        ld      a,(hl)            ;{{debb:7e}} get line number
        inc     hl                ;{{debc:23}} 
        ld      h,(hl)            ;{{debd:66}} 
        ld      l,a               ;{{debe:6f}} 
        scf                       ;{{debf:37}} 
        ret                       ;{{dec0:c9}} 

;;========================================================================
;; command TRON
command_TRON:                     ;{{Addr=$dec1 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$ff             ;{{dec1:3eff}} 
        jr      _command_troff_1  ;{{dec3:1801}}  (+$01)

;;========================================================================
;; command TROFF
command_TROFF:                    ;{{Addr=$dec5 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{dec5:af}} 
_command_troff_1:                 ;{{Addr=$dec6 Code Calls/jump count: 1 Data use count: 0}}
        ld      (trace_flag),a    ;{{dec6:321fae}} 
        ret                       ;{{dec9:c9}} 

;;=============
;;do trace
do_trace:                         ;{{Addr=$deca Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$5b             ;{{deca:3e5b}} '['
        call    output_char       ;{{decc:cda0c3}} ; display text char
        push    hl                ;{{decf:e5}} 
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{ded0:2a1dae}} Current line address
        ld      a,(hl)            ;{{ded3:7e}} get line number
        inc     hl                ;{{ded4:23}} 
        ld      h,(hl)            ;{{ded5:66}} 
        ld      l,a               ;{{ded6:6f}} 
        call    display_decimal_number;{{ded7:cd44ef}} Display current line number
        pop     hl                ;{{deda:e1}} 
        ld      a,$5d             ;{{dedb:3e5d}} ']'
        jp      output_char       ;{{dedd:c3a0c3}} ; display text char

;;====================================================
;; command to code address LUT

;you can add extra items to the end of this list, HOWEVER, there is only one unused item before
;current last item in the table is &e1. You can add an item &e2. Items &e3 onwards are used for other keywords
command_to_code_address_LUT:      ;{{Addr=$dee0 Data Calls/jump count: 0 Data use count: 3}}
                                  
        defw command_AFTER        ; AFTER  ##LABEL##
        defw command_AUTO         ; AUTO  ##LABEL##
        defw command_BORDER       ; BORDER  ##LABEL##
        defw command_CALL         ; CALL  ##LABEL##
        defw command_CAT          ; CAT  ##LABEL##
        defw command_CHAIN        ; CHAIN  ##LABEL##
        defw command_CLEAR_CLEAR_INPUT; CLEAR  ##LABEL##
        defw command_CLG          ; CLG  ##LABEL##
        defw command_CLOSEIN      ; CLOSEIN  ##LABEL##
        defw command_CLOSEOUT     ; CLOSEOUT  ##LABEL##
        defw command_CLS          ; CLS   ##LABEL##
        defw command_CONT         ; CONT  ##LABEL##
        defw skip_to_end_of_statement; DATA  ##LABEL##
        defw command_DEF          ; DEF   ##LABEL##
        defw command_DEFINT       ; DEFINT  ##LABEL##
        defw command_DEFREAL      ; DEFREAL  ##LABEL##
        defw command_DEFSTR       ; DEFSTR  ##LABEL##
        defw command_DEG          ; DEG  ##LABEL##
        defw command_DELETE       ; DELETE  ##LABEL##
        defw command_DIM          ; DIM  ##LABEL##
        defw command_DRAW         ; DRAW  ##LABEL##
        defw command_DRAWR        ; DRAWR  ##LABEL##
        defw command_EDIT         ; EDIT  ##LABEL##
        defw skip_to_end_of_line  ; ELSE  ##LABEL##
        defw command_END          ; END  ##LABEL##
        defw command_ENT          ; ENT  ##LABEL##
        defw command_ENV          ; ENV  ##LABEL##
        defw command_ERASE        ; ERASE  ##LABEL##
        defw command_ERROR        ; ERROR  ##LABEL##
        defw command_EVERY        ; EVERY  ##LABEL##
        defw command_FOR          ; FOR  ##LABEL##
        defw command_GOSUB        ; GOSUB  ##LABEL##
        defw command_GOTO         ; GOTO  ##LABEL##
        defw command_IF           ; IF  ##LABEL##
        defw command_INK          ; INK  ##LABEL##
        defw command_INPUT        ; INPUT  ##LABEL##
        defw command_KEY          ; KEY  ##LABEL##
        defw command_LET          ; LET   ##LABEL##
        defw command_LINE_INPUT   ; LINE  ##LABEL##
        defw command_LIST         ; LIST  ##LABEL##
        defw command_LOAD         ; LOAD  ##LABEL##
        defw command_LOCATE       ; LOCATE  ##LABEL##
        defw command_MEMORY       ; MEMORY  ##LABEL##
        defw command_MERGE        ; MERGE  ##LABEL##
        defw command_MID          ; MID$  ##LABEL##
        defw command_MODE         ; MODE  ##LABEL##
        defw command_MOVE         ; MOVE  ##LABEL##
        defw command_MOVER        ; MOVER  ##LABEL##
        defw command_NEXT         ; NEXT  ##LABEL##
        defw command_NEW          ; NEW  ##LABEL##
        defw command_ON_ON_ERROR_GOTO; ON   ##LABEL## (and ON ERROR GOTO [line])
        defw command_ON_BREAK_ON_BREAK_CONT_ON_BREAK_STOP; ON BREAK  ##LABEL##
        defw command_ON_ERROR_GOTO_0; ON ERROR GOTO 0 ##LABEL##
        defw command_ON_SQ        ; ON SQ  ##LABEL##
        defw command_OPENIN       ; OPENIN  ##LABEL##
        defw command_OPENOUT      ; OPENOUT  ##LABEL##
        defw command_ORIGIN       ; ORIGIN  ##LABEL##
        defw command_OUT          ; OUT  ##LABEL##
        defw command_PAPER        ; PAPER  ##LABEL##
        defw command_PEN          ; PEN  ##LABEL##
        defw command_PLOT         ; PLOT  ##LABEL##
        defw command_PLOTR        ; PLOTR  ##LABEL##
        defw command_POKE         ; POKE  ##LABEL##
        defw command_PRINT        ; PRINT  ##LABEL##
        defw command__or_REM      ; '  ##LABEL##
        defw command_RAD          ; RAD  ##LABEL##
        defw command_RANDOMIZE    ; RANDOMIZE  ##LABEL##
        defw command_READ         ; READ  ##LABEL##
        defw command_RELEASE      ; RELEASE  ##LABEL##
        defw command__or_REM      ; REM  ##LABEL##
        defw command_RENUM        ; RENUM  ##LABEL##
        defw command_RESTORE      ; RESTORE  ##LABEL##
        defw command_RESUME       ; RESUME  ##LABEL##
        defw command_RETURN       ; RETURN  ##LABEL##
        defw command_RUN          ; RUN  ##LABEL##
        defw command_SAVE         ; SAVE  ##LABEL##
        defw command_SOUND        ; SOUND  ##LABEL##
        defw command_SPEED_WRITE_SPEED_KEY_SPEED_INK; SPEED  ##LABEL##
        defw command_STOP         ; STOP  ##LABEL##
        defw command_SYMBOL       ; SYMBOL  ##LABEL##
        defw command_TAG          ; TAG  ##LABEL##
        defw command_TAGOFF       ; TAGOFF  ##LABEL##
        defw command_TROFF        ; TROFF  ##LABEL##
        defw command_TRON         ; TRON  ##LABEL##
        defw command_WAIT         ; WAIT  ##LABEL##
        defw command_WEND         ; WEND  ##LABEL##
        defw command_WHILE        ; WHILE  ##LABEL##
        defw command_WIDTH        ; WIDTH   ##LABEL##
        defw command_WINDOW_WINDOW_SWAP; WINDOW  ##LABEL##
        defw command_WRITE        ; WRITE  ##LABEL##
        defw command_ZONE         ; ZONE  ##LABEL##
        defw command_DI           ; DI  ##LABEL##
        defw command_EI           ; EI  ##LABEL##
        defw command_FILL         ; FILL  ##LABEL##
        defw command_GRAPHICS_PAPER__GRAPHICS_PEN_and_set_graphics_draw_mode; GRAPHICS  ##LABEL##
        defw command_MASK         ; MASK  ##LABEL##
        defw MC_WAIT_FLYBACK      ; FRAME  ##LABEL##
        defw command_CURSOR       ; CURSOR  ##LABEL##





