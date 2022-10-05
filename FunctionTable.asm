;;<< FUNCTION LOOK UP TABLE
;;======================================================
;; function table

;These functions take multiple parameters, or less straight-forward parameter(s).
;The function will have to read it's own parameters.
;Numbers after function names are the tokens
function_table:                   ;{{Addr=$d1e5 Data Calls/jump count: 0 Data use count: 4}}
                                  
        defw function_BIN         ; BIN$ $71 ##LABEL##
        defw function_DEC         ; DEC$ $72 ##LABEL##
        defw function_HEX         ; HEX$ $73 ##LABEL##
        defw function_INSTR       ; INSTR$ $74 ##LABEL##
        defw function_LEFT        ; LEFT$ $75 ##LABEL##
        defw function_MAX         ; MAX $76 ##LABEL##
        defw function_MIN         ; MIN $77 ##LABEL##
        defw function_POS         ; POS $78	  ##LABEL##
        defw function_RIGHT       ; RIGHT$ $79 ##LABEL##
        defw function_ROUND       ; ROUND $7a	  ##LABEL##
        defw function_STRING      ; STRING$ $7b	  ##LABEL##
        defw function_TEST        ; TEST	$7c	  ##LABEL##
        defw function_TESTR       ; TESTR $7d ##LABEL##
        defw function_COPYCHR     ; COPYCHR$	$7e	  ##LABEL##
        defw function_VPOS        ; VPOS $7f ##LABEL##

;;=simple function table
;These functions take a single, simple, parameter. The parameter will be read before the
;function is dispatched and passed to it.
simple_function_table:            ;{{Addr=$d203 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defw function_ABS         ; ABS $00     ##LABEL##
        defw function_ASC         ; ASC $01 ##LABEL##
        defw function_ATN         ; ATN $02 ##LABEL##
        defw function_CHR         ; CHR$  ##LABEL##
        defw function_CINT        ; CINT  ##LABEL##
        defw function_COS         ; COS  ##LABEL##
        defw function_CREAL       ; CREAL  ##LABEL##
        defw function_EXP         ; EXP  ##LABEL##
        defw function_FIX         ; FIX  ##LABEL##
        defw function_FRE         ; FRE  ##LABEL##
        defw function_INKEY       ; INKEY  ##LABEL##
        defw function_INP         ; INP  ##LABEL##
        defw function_INT         ; INT  ##LABEL##
        defw function_JOY         ; JOY  ##LABEL##
        defw function_LEN         ; LEN  ##LABEL##
        defw function_LOG         ; LOG  ##LABEL##
        defw function_LOG10       ; LOG10  ##LABEL##
        defw function_LOWER       ; LOWER$  ##LABEL##
        defw function_PEEK        ; PEEK  ##LABEL##
        defw function_REMAIN      ; REMAIN  ##LABEL##
        defw function_SGN         ; SGN  ##LABEL##
        defw function_SIN         ; SIN  ##LABEL##
        defw function_SPACE       ; SPACE$  ##LABEL##
        defw function_SQ          ; SQ  ##LABEL##
        defw function_SQR         ; SQR  ##LABEL##
        defw function_STR         ; STR$  ##LABEL##
        defw function_TAN         ; TAN  ##LABEL##
        defw function_UNT         ; UNT  ##LABEL##
        defw function_UPPER       ; UPPER$  ##LABEL##
        defw function_VAL         ; VAL $1d ##LABEL##




