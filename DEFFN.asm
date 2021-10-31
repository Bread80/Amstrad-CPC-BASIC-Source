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
        call    prob_parse_and_find_an_FN;{{d17f:cddbd6}} 
        ex      de,hl             ;{{d182:eb}} 
        ld      (hl),e            ;{{d183:73}} 
        inc     hl                ;{{d184:23}} 
        ld      (hl),d            ;{{d185:72}} 
        ex      de,hl             ;{{d186:eb}} 
        jp      command_DATA      ;{{d187:c3a3e9}} ; DATA

;;=======================================================================
;; prefix FN

prefix_FN:                        ;{{Addr=$d18a Code Calls/jump count: 0 Data use count: 1}}
        call    prob_parse_and_find_an_FN;{{d18a:cddbd6}} 
        push    bc                ;{{d18d:c5}} 
        push    hl                ;{{d18e:e5}} 
        ex      de,hl             ;{{d18f:eb}} 
        ld      e,(hl)            ;{{d190:5e}} 
        inc     hl                ;{{d191:23}} 
        ld      d,(hl)            ;{{d192:56}} 
        ex      de,hl             ;{{d193:eb}} 
        ld      a,h               ;{{d194:7c}} 
        or      l                 ;{{d195:b5}} 
        ld      a,$12             ;{{d196:3e12}} Unknown user function error
        jp      z,raise_error     ;{{d198:ca55cb}} 

;alloc space on execution stack for the FN and any parameters
        call    prob_push_FN_data_on_execution_stack;{{d19b:cd2ada}} 
        ld      a,(hl)            ;{{d19e:7e}} 
        cp      $28               ;{{d19f:fe28}} 
        jr      nz,prefix_FN_no_params;{{d1a1:2028}}  (+$28)
        call    get_next_token_skipping_space;{{d1a3:cd2cde}}  get next token skipping space
        ex      (sp),hl           ;{{d1a6:e3}} 
        call    next_token_if_open_bracket;{{d1a7:cd19de}}  check for open bracket
        ex      (sp),hl           ;{{d1aa:e3}} 

;;=prefix FN read params loop
prefix_FN_read_params_loop:       ;{{Addr=$d1ab Code Calls/jump count: 1 Data use count: 0}}
        call    prob_alloc_an_FN_parameter_on_execution_stack;{{d1ab:cd6ada}} 
        ex      (sp),hl           ;{{d1ae:e3}} 
        push    de                ;{{d1af:d5}} 
        call    eval_expression   ;{{d1b0:cd62cf}} 
        ex      (sp),hl           ;{{d1b3:e3}} 
        ld      a,b               ;{{d1b4:78}} 
        call    copy_accumulator_to_atHL_as_type_B;{{d1b5:cd9fd6}} 
        pop     hl                ;{{d1b8:e1}} 
        call    next_token_if_prev_is_comma;{{d1b9:cd41de}} 
        jr      nc,prefix_FN_finished_reading_params;{{d1bc:3006}}  (+$06)
        ex      (sp),hl           ;{{d1be:e3}} 
        call    next_token_if_comma;{{d1bf:cd15de}}  check for comma
        jr      prefix_FN_read_params_loop;{{d1c2:18e7}}  (-$19)

;;=prefix FN finished reading params
prefix_FN_finished_reading_params:;{{Addr=$d1c4 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_close_bracket;{{d1c4:cd1dde}}  check for close bracket
        ex      (sp),hl           ;{{d1c7:e3}} 
        call    next_token_if_close_bracket;{{d1c8:cd1dde}}  check for close bracket
;;=prefix FN no params
prefix_FN_no_params:              ;{{Addr=$d1cb Code Calls/jump count: 1 Data use count: 0}}
        call    copy_ae10_word_to_ae12;{{d1cb:cd49da}} 
        call    next_token_if_ef_token_for_equals_sign;{{d1ce:cd21de}} 
        call    eval_expression   ;{{d1d1:cd62cf}} eval the FN (ie run it as code)
        jp      nz,Error_Syntax_Error;{{d1d4:c249cb}}  Error: Syntax Error

        call    is_accumulator_a_string;{{d1d7:cd66ff}} 
        call    z,copy_accumulator_to_strings_area;{{d1da:cc8afb}} 
        call    prob_remove_FN_data_from_stack;{{d1dd:cd52da}} 
        pop     hl                ;{{d1e0:e1}} 
        pop     af                ;{{d1e1:f1}} 
        jp      convert_accumulator_to_type_in_A;{{d1e2:c3fffe}} 




