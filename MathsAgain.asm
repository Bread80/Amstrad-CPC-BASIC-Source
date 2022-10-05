;;<< MATHS FUNCTIONS MIN, MAX and ROUND
;;========================================================================
;; function MIN
;MIN(<list of: <numeric expression>>)
;Returns the smallest of the numeric expressions

function_MIN:                     ;{{Addr=$d23f Code Calls/jump count: 0 Data use count: 2}}
        ld      b,$ff             ;{{d23f:06ff}} 
        jr      _function_max_1   ;{{d241:1802}}  (+$02)

;;========================================================================
;; function MAX
;MAX(<list of: <numeric expression>>)
;Returns the largest of the numeric expressions

function_MAX:                     ;{{Addr=$d243 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$01             ;{{d243:0601}} 
;;------------------------------------------------------------------------
_function_max_1:                  ;{{Addr=$d245 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{d245:cd62cf}} 
_function_max_2:                  ;{{Addr=$d248 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{d248:cd41de}} 
        jp      nc,next_token_if_close_bracket;{{d24b:d21dde}}  check for close bracket
        call    push_numeric_accumulator_on_execution_stack;{{d24e:cd74ff}} 
        call    eval_expression   ;{{d251:cd62cf}} 
        push    hl                ;{{d254:e5}} 
        ld      a,c               ;{{d255:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d256:cd62f6}} 
        push    bc                ;{{d259:c5}} 
        push    hl                ;{{d25a:e5}} 
        call    infix_comparisons_plural;{{d25b:cd49fd}} 
        pop     hl                ;{{d25e:e1}} 
        pop     bc                ;{{d25f:c1}} 
        or      a                 ;{{d260:b7}} 
        jr      z,_function_max_18;{{d261:2804}}  (+$04)
        cp      b                 ;{{d263:b8}} 
        call    nz,copy_atHL_to_accumulator_using_accumulator_type;{{d264:c46fff}} 
_function_max_18:                 ;{{Addr=$d267 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d267:e1}} 
        jr      _function_max_2   ;{{d268:18de}}  (-$22)

;;========================================================================
;; function ROUND
;ROUND(<numeric expression>[,decimals])
;Rounds a number to the given number of decimal places.

function_ROUND:                   ;{{Addr=$d26a Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{d26a:cd62cf}} 
        call    push_numeric_accumulator_on_execution_stack;{{d26d:cd74ff}} 
        call    next_token_if_prev_is_comma;{{d270:cd41de}} 
        ld      de,$0000          ;{{d273:110000}} ##LIT##
        call    c,eval_expr_as_int;{{d276:dcd8ce}}  get number
        call    next_token_if_close_bracket;{{d279:cd1dde}}  check for close bracket
        push    hl                ;{{d27c:e5}} 
        push    de                ;{{d27d:d5}} 
        ld      hl,$0027          ;{{d27e:212700}} 
        add     hl,de             ;{{d281:19}} 
        ld      de,$004f          ;{{d282:114f00}} 
        call    compare_HL_DE     ;{{d285:cdd8ff}}  HL=DE?
        jp      nc,Error_Improper_Argument;{{d288:d24dcb}}  Error: Improper Argument
        pop     de                ;{{d28b:d1}} 
        ld      a,c               ;{{d28c:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d28d:cd62f6}} 
        ld      b,e               ;{{d290:43}} 
        call    round_accumulator ;{{d291:cdd5fd}} 
        pop     hl                ;{{d294:e1}} 
        ret                       ;{{d295:c9}} 


