;;<< DEF and DEF FN
;;========================================================================
;; command DEF

command_DEF:                      ;{{Addr=$d171 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_equals_inline_data_byte;{{d171:cd25de}} 
        defb $e4                  ; inline token to test "FN"
        ex      de,hl             ;{{d175:eb}} 
        call    get_current_line_number;{{d176:cdb5de}} 
        ex      de,hl             ;{{d179:eb}} 
        ld      a,$0c             ;{{d17a:3e0c}} Invalid direct command error
        jp      nc,raise_error    ;{{d17c:d255cb}} 
        call    parse_and_find_or_create_an_FN;{{d17f:cddbd6}} 
        ex      de,hl             ;{{d182:eb}} 
        ld      (hl),e            ;{{d183:73}} 
        inc     hl                ;{{d184:23}} 
        ld      (hl),d            ;{{d185:72}} 
        ex      de,hl             ;{{d186:eb}} 
        jp      skip_to_end_of_statement;{{d187:c3a3e9}} ; DATA

;;=======================================================================
;; prefix FN

prefix_FN:                        ;{{Addr=$d18a Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_or_create_an_FN;{{d18a:cddbd6}} find the DEF FN for this item
        push    bc                ;{{d18d:c5}} 
        push    hl                ;{{d18e:e5}} 
        ex      de,hl             ;{{d18f:eb}} 
        ld      e,(hl)            ;{{d190:5e}} read DEF FN address
        inc     hl                ;{{d191:23}} 
        ld      d,(hl)            ;{{d192:56}} 
        ex      de,hl             ;{{d193:eb}} HL=DEF FN address. We are now 'executing' the DEF FN code
        ld      a,h               ;{{d194:7c}} is address zero?
        or      l                 ;{{d195:b5}} 
        ld      a,$12             ;{{d196:3e12}} Unknown user function error
        jp      z,raise_error     ;{{d198:ca55cb}} 

;alloc space on execution stack for the FN and any parameters
        call    push_FN_header_on_execution_stack;{{d19b:cd2ada}} 
        ld      a,(hl)            ;{{d19e:7e}} Does the DEF FN have any parameters?
        cp      $28               ;{{d19f:fe28}}  '('
        jr      nz,prefix_FN_execute;{{d1a1:2028}}  (+$28) no params, skip next bit
        call    get_next_token_skipping_space;{{d1a3:cd2cde}}  get next token skipping space
        ex      (sp),hl           ;{{d1a6:e3}} 
        call    next_token_if_open_bracket;{{d1a7:cd19de}}  check for open bracket
        ex      (sp),hl           ;{{d1aa:e3}} 

;;=prefix FN read params loop
prefix_FN_read_params_loop:       ;{{Addr=$d1ab Code Calls/jump count: 1 Data use count: 0}}
        call    push_FN_parameter_on_execution_stack;{{d1ab:cd6ada}} Read both DEF FN definition parameter list...
        ex      (sp),hl           ;{{d1ae:e3}} ...and parameters passed in FN invocation
        push    de                ;{{d1af:d5}} 
        call    eval_expression   ;{{d1b0:cd62cf}} eval parameter
        ex      (sp),hl           ;{{d1b3:e3}} 
        ld      a,b               ;{{d1b4:78}} 
        call    copy_accumulator_to_atHL_as_type_B;{{d1b5:cd9fd6}} 
        pop     hl                ;{{d1b8:e1}} 
        call    next_token_if_prev_is_comma;{{d1b9:cd41de}} more parameters?
        jr      nc,prefix_FN_finished_reading_params;{{d1bc:3006}}  (+$06) nope, done
        ex      (sp),hl           ;{{d1be:e3}} 
        call    next_token_if_comma;{{d1bf:cd15de}}  check for comma
        jr      prefix_FN_read_params_loop;{{d1c2:18e7}}  (-$19)

;;=prefix FN finished reading params
prefix_FN_finished_reading_params:;{{Addr=$d1c4 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_close_bracket;{{d1c4:cd1dde}}  check for close bracket at end of FN
        ex      (sp),hl           ;{{d1c7:e3}} 
        call    next_token_if_close_bracket;{{d1c8:cd1dde}}  check for close bracket at end of DEF FN
;;=prefix FN execute
prefix_FN_execute:                ;{{Addr=$d1cb Code Calls/jump count: 1 Data use count: 0}}
        call    copy_FN_param_start_to_FN_param_end;{{d1cb:cd49da}} tidy up system variables?

        call    next_token_if_equals_sign;{{d1ce:cd21de}} HL=address of the equals sign in the DEF FN
        call    eval_expression   ;{{d1d1:cd62cf}} eval the FN (ie run it as code)
        jp      nz,Error_Syntax_Error;{{d1d4:c249cb}}  Error: Syntax Error
        call    is_accumulator_a_string;{{d1d7:cd66ff}} 
        call    z,copy_accumulator_to_strings_area;{{d1da:cc8afb}} 

        call    remove_FN_data_from_stack;{{d1dd:cd52da}} 
        pop     hl                ;{{d1e0:e1}} 
        pop     af                ;{{d1e1:f1}} 
        jp      convert_accumulator_to_type_in_A;{{d1e2:c3fffe}} 




