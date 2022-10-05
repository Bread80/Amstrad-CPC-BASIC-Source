;;<< EXPRESSION EVALUATION
;;< Includes prefix operators and various lookup tables (operators, system vars etc.)
;;=====================================
;;EVAL EXPRESSIONS
;;====================================================
;;eval expr as byte or error
;; returns value in A
eval_expr_as_byte_or_error:       ;{{Addr=$ceb8 Code Calls/jump count: 15 Data use count: 0}}
        call    eval_expr_as_int  ;{{ceb8:cdd8ce}}  get number
        push    af                ;{{cebb:f5}} 

;;=error if D non zero
error_if_D_non_zero:              ;{{Addr=$cebc Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{cebc:7a}} 
        or      a                 ;{{cebd:b7}} 
        jr      nz,raise_improper_argument_error_C;{{cebe:200b}}  Error: Improper argument      

;; it's lower than 256 return number
        pop     af                ;{{cec0:f1}} 
        ld      a,e               ;{{cec1:7b}} 
        ret                       ;{{cec2:c9}} 

;;=============================================
;;eval expr as int less than 256
eval_expr_as_int_less_than_256:   ;{{Addr=$cec3 Code Calls/jump count: 7 Data use count: 0}}
        call    eval_expr_as_int  ;{{cec3:cdd8ce}}  get number
        push    af                ;{{cec6:f5}} 
        ld      a,d               ;{{cec7:7a}} 
        or      e                 ;{{cec8:b3}} 
        jr      nz,error_if_D_non_zero;{{cec9:20f1}}  (-$0f)

;;+raise improper argument error
raise_improper_argument_error_C:  ;{{Addr=$cecb Code Calls/jump count: 2 Data use count: 0}}
        jp      Error_Improper_Argument;{{cecb:c34dcb}}  Error: Improper Argument

;;=======================================
;;eval expr as positive int or error
;(0-32676)
eval_expr_as_positive_int_or_error:;{{Addr=$cece Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expr_as_int  ;{{cece:cdd8ce}}  get number
        push    af                ;{{ced1:f5}} 
        ld      a,d               ;{{ced2:7a}} 
        rla                       ;{{ced3:17}} 
        jr      c,raise_improper_argument_error_C;{{ced4:38f5}}  (-$0b)
        pop     af                ;{{ced6:f1}} 
        ret                       ;{{ced7:c9}} 

;;========================================
;;eval expr as int
eval_expr_as_int:                 ;{{Addr=$ced8 Code Calls/jump count: 12 Data use count: 0}}
        call    eval_expression   ;{{ced8:cd62cf}} 
        push    af                ;{{cedb:f5}} 
        ex      de,hl             ;{{cedc:eb}} 
        call    function_CINT     ;{{cedd:cdb6fe}} 
        ex      de,hl             ;{{cee0:eb}} 
        pop     af                ;{{cee1:f1}} 
        ret                       ;{{cee2:c9}} 

;;========================================
;;eval expr as string
eval_expr_as_string:              ;{{Addr=$cee3 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{cee3:cd62cf}} 
        call    is_accumulator_a_string;{{cee6:cd66ff}} 
        jr      nz,_eval_expr_as_uint_1;{{cee9:200d}}  (+$0d)
        push    hl                ;{{ceeb:e5}} 
        ld      hl,(accumulator)  ;{{ceec:2aa0b0}} 
        call    copy_string_to_strings_area_if_not_in_strings_area;{{ceef:cd58fb}} 
        ex      de,hl             ;{{cef2:eb}} 
        pop     hl                ;{{cef3:e1}} 
        ret                       ;{{cef4:c9}} 

;;========================================
;;eval expr as uint
eval_expr_as_uint:                ;{{Addr=$cef5 Code Calls/jump count: 10 Data use count: 0}}
        call    eval_expression   ;{{cef5:cd62cf}} 
_eval_expr_as_uint_1:             ;{{Addr=$cef8 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{cef8:f5}} 
        push    bc                ;{{cef9:c5}} 
        push    hl                ;{{cefa:e5}} 
        call    function_UNT      ;{{cefb:cdebfe}} 
        ex      de,hl             ;{{cefe:eb}} 
        pop     hl                ;{{ceff:e1}} 
        pop     bc                ;{{cf00:c1}} 
        pop     af                ;{{cf01:f1}} 
        ret                       ;{{cf02:c9}} 

;;===========================================
;;eval expr as string and get length
eval_expr_as_string_and_get_length:;{{Addr=$cf03 Code Calls/jump count: 5 Data use count: 0}}
        call    eval_expression   ;{{cf03:cd62cf}} 
        jp      get_accumulator_string_length;{{cf06:c3f5fb}} 

;;===========================================
;;eval expr and error if not string
eval_expr_and_error_if_not_string:;{{Addr=$cf09 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expression   ;{{cf09:cd62cf}} 
        jp      error_if_accumulator_is_not_a_string;{{cf0c:c35eff}} 

;;===========================================
;;eval line number range params
;Params for LIST and DELETE: [first][,|-][last]
eval_line_number_range_params:    ;{{Addr=$cf0f Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$0001          ;{{cf0f:010100}} Default values
        ld      de,$ffff          ;{{cf12:11ffff}} ##LIT##;WARNING: Code area used as literal
        call    next_token_if_prev_is_comma;{{cf15:cd41de}} 
        call    nc,is_next_02     ;{{cf18:d43dde}} 
        ret     c                 ;{{cf1b:d8}} 

        cp      $23               ;{{cf1c:fe23}}  "#"
        ret     z                 ;{{cf1e:c8}} 

        cp      $f5               ;{{cf1f:fef5}} "-"
        jr      z,get_range_end   ;{{cf21:280a}}  (+$0a)

        call    eval_line_number_or_error;{{cf23:cd48cf}} 
        ld      b,d               ;{{cf26:42}} 
        ld      c,e               ;{{cf27:4b}} 
        ret     z                 ;{{cf28:c8}} 

        call    next_token_if_prev_is_comma;{{cf29:cd41de}} 
        ret     c                 ;{{cf2c:d8}} 

;;=get range end
get_range_end:                    ;{{Addr=$cf2d Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_equals_inline_data_byte;{{cf2d:cd25de}} 
        defb $f5                  ;Inline token to test "-"
        ld      de,$ffff          ;{{cf31:11ffff}} ##LIT##;WARNING: Code area used as literal
        ret     z                 ;{{cf34:c8}} 

        call    next_token_if_prev_is_comma;{{cf35:cd41de}} 
        ret     c                 ;{{cf38:d8}} 

        call    eval_line_number_or_error;{{cf39:cd48cf}} 
        call    nz,next_token_if_prev_is_comma;{{cf3c:c441de}} 
        ex      de,hl             ;{{cf3f:eb}} 
        call    compare_HL_BC     ;{{cf40:cddeff}}  HL=BC?
        jp      c,Error_Improper_Argument;{{cf43:da4dcb}}  Error: Improper Argument
        ex      de,hl             ;{{cf46:eb}} 
        ret                       ;{{cf47:c9}} 

;;===============================================
;;eval line number or error
;If data is a line pointer returns the line number of the line it points to.
eval_line_number_or_error:        ;{{Addr=$cf48 Code Calls/jump count: 10 Data use count: 0}}
        ld      a,(hl)            ;{{cf48:7e}} 
        inc     hl                ;{{cf49:23}} 
        ld      e,(hl)            ;{{cf4a:5e}} 
        inc     hl                ;{{cf4b:23}} 
        ld      d,(hl)            ;{{cf4c:56}} 
        cp      $1e               ;{{cf4d:fe1e}}  16-bit line number
        jr      z,_eval_line_number_or_error_18;{{cf4f:280e}}  (+$0e)

        cp      $1d               ;{{cf51:fe1d}}  16-bit line address pointer
        jp      nz,Error_Syntax_Error;{{cf53:c249cb}}  Error: Syntax Error
        push    hl                ;{{cf56:e5}} 
        ex      de,hl             ;{{cf57:eb}} fetch line number from line address pointer
        inc     hl                ;{{cf58:23}} 
        inc     hl                ;{{cf59:23}} 
        inc     hl                ;{{cf5a:23}} 
        ld      e,(hl)            ;{{cf5b:5e}} 
        inc     hl                ;{{cf5c:23}} 
        ld      d,(hl)            ;{{cf5d:56}} 
        pop     hl                ;{{cf5e:e1}} 

_eval_line_number_or_error_18:    ;{{Addr=$cf5f Code Calls/jump count: 1 Data use count: 0}}
        jp      get_next_token_skipping_space;{{cf5f:c32cde}}  get next token skipping space

;; EXPRESSION EVALUATOR
;;==================================
;; eval expression
;; This gets called to evaluate an expression after a statement or function
;; but will also be called recursively for sub-expressions, 
;; eg. after an open bracket or by a function call within the expression
;; HL = ptr to first token

eval_expression:                  ;{{Addr=$cf62 Code Calls/jump count: 27 Data use count: 0}}
        push    bc                ;{{cf62:c5}} 
        ld      b,$00             ;{{cf63:0600}} B=operator precedence
        call    do_eval_expression;{{cf65:cd6dcf}} 
        pop     bc                ;{{cf68:c1}} 
        dec     hl                ;{{cf69:2b}} 
        jp      get_next_token_skipping_space;{{cf6a:c32cde}}  return with the next token after the expression
                                  ; or sub expression

;;=do eval expression
do_eval_expression:               ;{{Addr=$cf6d Code Calls/jump count: 3 Data use count: 0}}
        dec     hl                ;{{cf6d:2b}} 
_do_eval_expression_1:            ;{{Addr=$cf6e Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{cf6e:c5}} 
        call    eval_sub_expression;{{cf6f:cd33d0}}  process tokenised line
        push    hl                ;{{cf72:e5}} 

;;=infix operator or done
;If next token is an infix operator then expression continues, 
;otherwise end of expression so return
infix_operator_or_done:           ;{{Addr=$cf73 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{cf73:e1}}  look for possible infix operator
        pop     bc                ;{{cf74:c1}} 
        ld      a,(hl)            ;{{cf75:7e}} 
        cp      $ee               ;{{cf76:feee}} 
        ret     c                 ;{{cf78:d8}} 

        cp      $fe               ;{{cf79:fefe}} 
        ret     nc                ;{{cf7b:d0}} continue if token >= $ee and < $fe (infix operators)

; infix operators

;comparison
; ee: >
; ef: =
; f0: >= =>
; f1: <
; f2: <>
; f3: <= =<

;maths and logic
; f4: +
; f5: -
; f6: *
; f7: /
; f8: ^
; f9: \ integer division
; fa: AND
; fb: MOD
; fc: OR
; fd: XOR

;;infix operators
        cp      $f4               ;{{cf7c:fef4}} "+" token
        jr      c,comparison_infix_operator;{{cf7e:3845}}  (+$45) tokens $ee to $f3
        call    z,is_accumulator_a_string;{{cf80:cc66ff}} If "+" then is operand a string?
        jr      nz,maths_and_logic_infix_operators;{{cf83:2012}}  (+$12) 

;accumulator is a string and operator is addition.
        push    bc                ;{{cf85:c5}} 
        push    hl                ;{{cf86:e5}} 
        ld      hl,(accumulator)  ;{{cf87:2aa0b0}} 
        ex      (sp),hl           ;{{cf8a:e3}} 
        call    eval_sub_expression;{{cf8b:cd33d0}}  process tokenised line
        call    error_if_accumulator_is_not_a_string;{{cf8e:cd5eff}} 
        ex      (sp),hl           ;{{cf91:e3}} 
        call    concat_two_strings;{{cf92:cd1df9}} 
        jr      infix_operator_or_done;{{cf95:18dc}}  (-$24)

;;=maths and logic infix operators
;; handle tokens f4 to fd
maths_and_logic_infix_operators:  ;{{Addr=$cf97 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{cf97:7e}} 
        sub     $f4               ;{{cf98:d6f4}} Table address = table start + ((token - $f4) * 3)
        ld      e,a               ;{{cf9a:5f}}  E = A * 3
        add     a,a               ;{{cf9b:87}} 
        add     a,e               ;{{cf9c:83}}  use A as index into table at $cfed
        add     a,infix_maths_table and $ff;{{cf9d:c6ed}}    $ed
        ld      e,a               ;{{cf9f:5f}} 
        adc     a,infix_maths_table >> 8;{{cfa0:cecf}}  $cf
        sub     e                 ;{{cfa2:93}} 
        ld      d,a               ;{{cfa3:57}} 
        ex      de,hl             ;{{cfa4:eb}} HL=table item addr
        ld      a,b               ;{{cfa5:78}} Precedence of previous operator
        cp      (hl)              ;{{cfa6:be}} Compare with value in table
        ex      de,hl             ;{{cfa7:eb}} 
        ret     nc                ;{{cfa8:d0}} Return if new operator is lower precedence

        push    bc                ;{{cfa9:c5}} 
;;=dispatch infix operator
;;DE = ptr to address of table entry
dispatch_infix_operator:          ;{{Addr=$cfaa Code Calls/jump count: 1 Data use count: 0}}
        call    push_numeric_accumulator_on_execution_stack;{{cfaa:cd74ff}} 
        push    de                ;{{cfad:d5}} 
        push    bc                ;{{cfae:c5}} 
        ld      a,(de)            ;{{cfaf:1a}} Read or restore previous operator precedence value?
        ld      b,a               ;{{cfb0:47}} 
        call    _do_eval_expression_1;{{cfb1:cd6ecf}} eval expression after operator
        pop     bc                ;{{cfb4:c1}} 
        ex      (sp),hl           ;{{cfb5:e3}} 
        inc     hl                ;{{cfb6:23}} 
        ld      a,(hl)            ;{{cfb7:7e}} Read code address from table...
        inc     hl                ;{{cfb8:23}} 
        ld      h,(hl)            ;{{cfb9:66}} 
        ld      l,a               ;{{cfba:6f}} 
        ex      de,hl             ;{{cfbb:eb}} ...into DE
        ld      a,c               ;{{cfbc:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{cfbd:cd62f6}} 
        call    JP_DE             ;{{cfc0:cdfeff}}  JP (DE) call infix eval routine
        jr      infix_operator_or_done;{{cfc3:18ae}}  (-$52)

;;=comparison infix operator
; tokens ee to f3
comparison_infix_operator:        ;{{Addr=$cfc5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{cfc5:78}} Precedence
        cp      $0a               ;{{cfc6:fe0a}} 
        ret     nc                ;{{cfc8:d0}} Return if previous operator is higher

        push    bc                ;{{cfc9:c5}} 
        ld      a,(hl)            ;{{cfca:7e}} Operator
        sub     $ed               ;{{cfcb:d6ed}} Calc precedence?
        ld      b,a               ;{{cfcd:47}} Predence
        call    is_accumulator_a_string;{{cfce:cd66ff}}  check operand type
        ld      de,infix_comparison_table;{{cfd1:110bd0}}  
        jr      nz,dispatch_infix_operator;{{cfd4:20d4}}  (-$2c) do comparison for non strings

        push    hl                ;{{cfd6:e5}}  otherwise it's a string comparison
        ld      hl,(accumulator)  ;{{cfd7:2aa0b0}} 
        ex      (sp),hl           ;{{cfda:e3}} 
        push    bc                ;{{cfdb:c5}} 
        ld      b,$0a             ;{{cfdc:060a}} Precedence
        call    _do_eval_expression_1;{{cfde:cd6ecf}} eval expression after operator
        pop     bc                ;{{cfe1:c1}} 
        ex      (sp),hl           ;{{cfe2:e3}} 
        push    bc                ;{{cfe3:c5}} 
        call    string_comparison ;{{cfe4:cd3ff9}} string compare???
        pop     bc                ;{{cfe7:c1}} 
        call    process_comparison_result;{{cfe8:cd13d0}} 
        jr      infix_operator_or_done;{{cfeb:1886}}  (-$7a)

;;=======================================
;Maths infix operator table format:
;byte=operator precedence? (higher values take higher priority)
;word=code address or evaluation routine


;;infix maths table
infix_maths_table:                ;{{Addr=$cfed Data Calls/jump count: 0 Data use count: 2}}
        defb $0c                  
        defw infix_plus_          ; + ##LABEL##
        defb $0c                  
        defw infix_minus_         ; - ##LABEL##
        defb $12                  
        defw infix_multiply_      ; * ##LABEL##
        defb $12                  
        defw infix_divide_        ; / ##LABEL##
        defb $16                  
        defw infix_power_         ; ^ ##LABEL##
        defb $10                  
        defw infix_integer_division; \ integer division ##LABEL##
        defb $06                  
        defw infix_AND            ; AND ##LABEL##
        defb $0e                  
        defw infix_MOD            ; MOD ##LABEL##
        defb $04                  
        defw infix_OR             ;OR ##LABEL##
        defb $02                  
        defw infix_XOR            ;XOR ##LABEL##

;;=infix comparison table
infix_comparison_table:           ;{{Addr=$d00b Data Calls/jump count: 0 Data use count: 1}}
        defb $0a                  
        defw eval_comparison_infix; ##LABEL##

;;=eval comparison infix
; ee: >
; ef: =
; f0: >= =>
; f1: <
; f2: <>
; f3: <= =<
eval_comparison_infix:            ;{{Addr=$d00e Code Calls/jump count: 0 Data use count: 1}}
        push bc                   ;{{d00e:c5}} 
        call infix_comparisons_plural;{{d00f:cd49fd}} 
        pop bc                    ;{{d012:c1}} 

;;= process comparison result
;called after we've done a comparison operator. Presumably converts the result
;into a boolean value?
process_comparison_result:        ;{{Addr=$d013 Code Calls/jump count: 1 Data use count: 0}}
        add     a,$01             ;{{d013:c601}} 
        adc     a,a               ;{{d015:8f}} 
        and     b                 ;{{d016:a0}} 
        add     a,$ff             ;{{d017:c6ff}} 
        sbc     a,a               ;{{d019:9f}} 
        jp      store_sign_extended_byte_in_A_in_accumulator;{{d01a:c32dff}} 




;;=======================================
;; PREFIX OPERATORS
;;=======================================================================
;; prefix minus -
prefix_minus_:                    ;{{Addr=$d01d Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$14             ;{{d01d:0614}} Operator precedence
        call    do_eval_expression;{{d01f:cd6dcf}} 
        push    hl                ;{{d022:e5}} 
        call    negate_accumulator;{{d023:cdb4fd}} 
        pop     hl                ;{{d026:e1}} 
        ret                       ;{{d027:c9}} 

;;=======================================================================
;; prefix NOT

prefix_NOT:                       ;{{Addr=$d028 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$08             ;{{d028:0608}} Operator precedence
        call    do_eval_expression;{{d02a:cd6dcf}} 
        push    hl                ;{{d02d:e5}} 
        call    bitwise_complementinvert;{{d02e:cda6fd}} 
        pop     hl                ;{{d031:e1}} 
        ret                       ;{{d032:c9}} 

;;=========================================
;; EVAL A TOKENISED EXPRESSION
;;==========================================================================
;; eval sub expression
;; evaluate a sub-expression. Doesn't evaluate infix operators

eval_sub_expression:              ;{{Addr=$d033 Code Calls/jump count: 2 Data use count: 0}}
        call    get_next_token_skipping_space;{{d033:cd2cde}}  get next token skipping space
;;+-----------
;;prefix plus
;if we have + as a prefix operator we don't need to do anything!

prefix_plus:                      ;{{Addr=$d036 Code Calls/jump count: 0 Data use count: 1}}
        jr      z,raise_missing_operand;{{d036:281d}}  (+$1d)
        cp      $0e               ;{{d038:fe0e}} 
        jr      c,eval_variable_references;{{d03a:3838}}  
        cp      $20               ;{{d03c:fe20}}  (space)
        jr      c,eval_constants  ;{{d03e:3852}}  
        cp      $22               ;{{d040:fe22}}  (double quote)
        jp      z,get_quoted_string;{{d042:ca79f8}} 

        cp      $ff               ;{{d045:feff}}  keyword with $ff prefix?
        jp      z,eval_functions_with_ff_prefix;{{d047:cadad0}} 

        push    hl                ;{{d04a:e5}} 
        ld      hl,prefix_token_table;{{d04b:2159d0}} 
        call    get_address_from_table;{{d04e:cdb4ff}} 
        ex      (sp),hl           ;{{d051:e3}} 
        jp      get_next_token_skipping_space;{{d052:c32cde}}  get next token skipping space
                                  ; (Function will be returned to with a token in A)

;;+---------------------------------------------------------------------------
;;raise missing operand
raise_missing_operand:            ;{{Addr=$d055 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d055:cd45cb}} 
        defb $16                  ; Error: Operand Missing

;;===========================================================================
;; prefix token table
prefix_token_table:               ;{{Addr=$d059 Data Calls/jump count: 0 Data use count: 1}}
                                  

;(call this entry if token not found)
        defb $08                  
        defw raise_syntax_error   ; Error: Syntax Error ##LABEL##

        defb $f5                  ; -
        defw prefix_minus_        ;##LABEL##
        defb $f4                  ; +
        defw prefix_plus          ;##LABEL##
        defb $28                  ; (
        defw prefix_open_bracket_ ;##LABEL##
        defb $fe                  ; NOT
        defw prefix_NOT           ;##LABEL##
        defb $e3                  ; ERL
        defw prefix_ERL           ;##LABEL##
        defb $e4                  ; FN
        defw prefix_FN            ;##LABEL##
        defb $ac                  ; MID$
        defw prefix_MID           ;##LABEL##
        defb $40                  ; @
        defw prefix_at_operator_  ;##LABEL##

;;===========================================================================
;; eval variable references
;eval tokens $00 to $0d
;These tokens are for variables. Tokens $00 (end of line) and $01 (end of statement)
;have already been preocessed.
;Tokens:
;&02: integer variable definition with % suffix
;&03: string variable definition with $ suffix
;&04: real variable definition with % suffix
;&05: ??
;&06: ??
;&07: ??
;&08: ??
;&09: ??
;&0a: ??
;&0b: integer variable definition (no suffix)
;&0c: string variable definition (no suffix)
;&0d: real variable definition (no suffix)
;Unknown stuff probably includes DEF FNs and DIMs

eval_variable_references:         ;{{Addr=$d074 Code Calls/jump count: 1 Data use count: 0}}
        call    parse_and_find_var;{{d074:cdc9d6}} 
        jr      nc,undeclared_variable;{{d077:300b}}  (+$0b) Variable not declared/no value set yet
        cp      $03               ;{{d079:fe03}} String
        jr      z,eval_string_variable_reference;{{d07b:280f}}  (+$0f)
        push    hl                ;{{d07d:e5}} 
        ex      de,hl             ;{{d07e:eb}} 
        call    copy_atHL_to_accumulator_type_A;{{d07f:cd6cff}} 
        pop     hl                ;{{d082:e1}} 
        ret                       ;{{d083:c9}} 

;;=undeclared variable
;undeclared/no value set so return zero or empty string
undeclared_variable:              ;{{Addr=$d084 Code Calls/jump count: 1 Data use count: 0}}
        cp      $03               ;{{d084:fe03}} 
        jp      nz,zero_accumulator;{{d086:c21bff}} 
        ld      de,empty_string   ;{{d089:1191d0}} Pointer to an empty string

;;=eval string variable reference
eval_string_variable_reference:   ;{{Addr=$d08c Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator),de  ;{{d08c:ed53a0b0}} 
        ret                       ;{{d090:c9}} 

;;=empty string
empty_string:                     ;{{Addr=$d091 Data Calls/jump count: 0 Data use count: 1}}
        defb $00                  

;;===========================================================================
;;eval constants
;; eval tokens $0e to $1f
;; Raw token|After sub $0e|Meaning
;; $0e..$17? $00-$0a       Constants 0-10
;; $18       $0b:          Byte constant following token
;; $19       $0c:          Word constant following token = decimal constant
;; $1a       $0d:          Word constant following token = binary constant (&X prefix)
;; $1b       $0e:          Word constant following token = hex constant (&H or & prefix)
;; $1c       $0f:          UINT at (token + 3)?? = BASIC program line pointer
;; $1d       $10:          UINT constant following token = BASIC line number
;; $1e       $11:          REAL cinstant following token

eval_constants:                   ;{{Addr=$d092 Code Calls/jump count: 1 Data use count: 0}}
        sub     $0e               ;{{d092:d60e}} 
        ld      e,a               ;{{d094:5f}} 
        ld      d,$00             ;{{d095:1600}} 
        cp      $0a               ;{{d097:fe0a}} Constant 0-10
        jr      c,eval_DE_as_number_constant;{{d099:381b}} 

        inc     hl                ;{{d09b:23}} 
        ld      e,(hl)            ;{{d09c:5e}} 
        cp      $0b               ;{{d09d:fe0b}} Token $18: Byte following token
        jr      z,eval_DE_as_number_constant;{{d09f:2815}} 

        inc     hl                ;{{d0a1:23}} 
        ld      d,(hl)            ;{{d0a2:56}} 
        cp      $0f               ;{{d0a3:fe0f}} Tokens $19, $1a, $1b. Word following token. Values 0c, 0d, 0e
        jr      c,eval_DE_as_number_constant;{{d0a5:380f}}  (+$0f)
        cp      $11               ;{{d0a7:fe11}} Tokens $1c, $1d. Extended. Values 0f, 10h
        jr      c,eval_number_constant_extended;{{d0a9:3812}}  (+$12)
        jr      nz,raise_syntax_error;{{d0ab:202a}} ; Error: Syntax Error. Values <> 11h (shouldn't be here!)
        dec     hl                ;{{d0ad:2b}} Token $1e, Value 11h
        ld      a,$05             ;{{d0ae:3e05}} REAL
        call    copy_atHL_to_accumulator_type_A;{{d0b0:cd6cff}} 
        dec     hl                ;{{d0b3:2b}} 
        jr      eval_number_done  ;{{d0b4:1818}}  (+$18)

;;===========================================================================
;; eval DE as number constant
;; DE=value

eval_DE_as_number_constant:       ;{{Addr=$d0b6 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{d0b6:eb}} 
        call    store_HL_in_accumulator_as_INT;{{d0b7:cd35ff}} 
        ex      de,hl             ;{{d0ba:eb}} 
        jr      eval_number_done  ;{{d0bb:1811}}  (+$11)

;;+---------------------------------------------------------------------------
;;eval number constant extended
;DE=value stored after token
eval_number_constant_extended:    ;{{Addr=$d0bd Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d0bd:e5}} 
        cp      $0f               ;{{d0be:fe0f}} 
        jr      nz,eval_DE_as_UINT;{{d0c0:2007}}  (+$07)

        inc     de                ;{{d0c2:13}} Token $1c value $0f
        ex      de,hl             ;{{d0c3:eb}} 
        inc     hl                ;{{d0c4:23}} 
        inc     hl                ;{{d0c5:23}} 
        ld      e,(hl)            ;{{d0c6:5e}} Read word at (token + 3)??
        inc     hl                ;{{d0c7:23}} 
        ld      d,(hl)            ;{{d0c8:56}} 

;;=eval DE as UINT
eval_DE_as_UINT:                  ;{{Addr=$d0c9 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{d0c9:eb}} 
        call    set_accumulator_as_REAL_from_unsigned_INT;{{d0ca:cd89fe}} 
        pop     hl                ;{{d0cd:e1}} 

;;=eval number done
eval_number_done:                 ;{{Addr=$d0ce Code Calls/jump count: 2 Data use count: 0}}
        jp      get_next_token_skipping_space;{{d0ce:c32cde}}  get next token skipping space

;;=======================================================================
;; prefix open bracket (
prefix_open_bracket_:             ;{{Addr=$d0d1 Code Calls/jump count: 1 Data use count: 1}}
        call    eval_expression   ;{{d0d1:cd62cf}} 
        jp      next_token_if_close_bracket;{{d0d4:c31dde}}  check for close bracket

;;======================================================================
;; raise syntax error
raise_syntax_error:               ;{{Addr=$d0d7 Code Calls/jump count: 2 Data use count: 1}}
        jp      Error_Syntax_Error;{{d0d7:c349cb}}  Error: Syntax Error

;;======================================================================
;; eval functions with $ff prefix

eval_functions_with_ff_prefix:    ;{{Addr=$d0da Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{d0da:23}} 
        ld      c,(hl)            ;{{d0db:4e}} ; get function token
        call    get_next_token_skipping_space;{{d0dc:cd2cde}}  get next token skipping space

;; A = keyword id
        ld      a,c               ;{{d0df:79}} 
        cp      $40               ;{{d0e0:fe40}} 
        jr      c,eval_function_which_arent_system_variables;{{d0e2:3805}}  (+$05)
        cp      $4a               ;{{d0e4:fe4a}} ****Change this value if extending the table.
        jp      c,eval_system_variables;{{d0e6:da10d1}} 

;;-------------------------------------------------------------------------
;;=eval function which arent system variables
;;Followed by: token < $40 or => $4a
eval_function_which_arent_system_variables:;{{Addr=$d0e9 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_open_bracket;{{d0e9:cd19de}}  function so we need opening bracket

;Convert token to index into table.
;Function tokens are:
;$71 - $7f (complex parameter functions) and 
;$00 - $1d (single simple parameter functions)
;This code converts them to a zero based index into the function look up table.
        ld      a,c               ;{{d0ec:79}} 
        add     a,a               ;{{d0ed:87}} Doubling A gives us values <initial> - $fe and $00 - <final>
        add     a,simple_function_table - function_table;{{d0ee:c61e}} <function_table>
;d0ee c61e      add     a,$1e    ;(Original) This value is twice the number of entries in the 
                                  ;complex parameter function part of the table (tokens $71 - $7f)
                                  ;Adding it to A gives us our zero based index.
        ld      c,a               ;{{d0f0:4f}} 

;; $00-$1d -> $1e->$58
;; $71-$7f -> $00->$1c
;; $40-$49 -> $9e->$b0

        cp    function_MIN - function_table - 1;{{d0f1:fe59}} ;WARNING: Code area used as literal
;d0f1 fe59      cp      $59             ;(Original) Number of bytes in total function table plus 1
        jr      nc,raise_syntax_error;{{d0f3:30e2}}  Error: Syntax Error
        cp      simple_function_table - function_table - 1;{{d0f5:fe1d}} 
;d0f5 fe1d      cp      $1d              ;(Original) Number of bytes in complex parameter function table + 1
;For these functions we'll make them process their own parameters.
;Presumably for functions which don't take a single, simple, parameter.
;(Contrast with next code section). Tokens $71 - $7f
        jr      c,jp_to_routine_in_function_table;{{d0f7:3809}}  (+$09)

;; $ff prefix followed by $00-$1d
;For these functions we'll eval the parameter beforehand and save it some work.
;These are, presumably, functions which take a single, simple, parameter.
;(Contrast with JR immediately above). Tokens $00 - $1d
        call    prefix_open_bracket_;{{d0f9:cdd1d0}} 
        push    hl                ;{{d0fc:e5}} 
        call    jp_to_routine_in_function_table;{{d0fd:cd02d1}} 
        pop     hl                ;{{d100:e1}} 
        ret                       ;{{d101:c9}} 

;;==========================================================================
;;jp to routine in function table
;; $ff prefix followed by $71 to $7f

jp_to_routine_in_function_table:  ;{{Addr=$d102 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,function_table ;{{d102:11e5d1}}  functions
;;= jp to routine in table
;; DE=table
;; C=offset
jp_to_routine_in_table:           ;{{Addr=$d105 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d105:e5}} 
        ex      de,hl             ;{{d106:eb}} 
        ld      b,$00             ;{{d107:0600}} 
        add     hl,bc             ;{{d109:09}} 
        ld      a,(hl)            ;{{d10a:7e}} 
        inc     hl                ;{{d10b:23}} 
        ld      h,(hl)            ;{{d10c:66}} 
        ld      l,a               ;{{d10d:6f}} 
        ex      (sp),hl           ;{{d10e:e3}}  Routine address on stack
        ret                       ;{{d10f:c9}} 

;;==========================================================================
;;eval system variables
;; keywords: $ff followed by $40 to $49
;; 
;; A = keyword index ($40-$49)

eval_system_variables:            ;{{Addr=$d110 Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{d110:87}} ; $40->$80, $41->$82...
        ld      c,a               ;{{d111:4f}} 

;; A = keyword index
;; C = offset in table
        ld      de,system_variables_table - $80;{{d112:1197d0}}  d117-$80
        jr      jp_to_routine_in_table;{{d115:18ee}} 

;;+------------------------------------------------------------
;; system variables table
system_variables_table:           ;{{Addr=$d117 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defw variable_EOF         ; EOF  ##LABEL##
        defw variable_ERR         ; ERR  ##LABEL##
        defw variable_HIMEM       ; HIMEM  ##LABEL##
        defw variable_INKEY       ; INKEY$  ##LABEL##
        defw variable_PI          ; PI  ##LABEL##
        defw variable_RND         ; RND  ##LABEL##
        defw variable_TIME        ; TIME  ##LABEL##
        defw variable_XPOS        ; XPOS  ##LABEL##
        defw variable_YPOS        ; YPOS  ##LABEL##
        defw variable_DERR        ; DERR  ##LABEL##




