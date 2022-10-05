;;<< INFIX OPERATORS
;;< Infix +, -, *, / etc. including boolean operators
;;=========================================
;; infix plus +
infix_plus_:                      ;{{Addr=$fd0c Code Calls/jump count: 1 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd0c:cd3bfe}} 
        jr      nc,_infix_plus__5 ;{{fd0f:3009}}  (+$09)
        call    INT_addition_with_overflow_test;{{fd11:cd4add}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd14:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd17:cd78fe}} 
_infix_plus__5:                   ;{{Addr=$fd1a Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_ADDITION     ;{{fd1a:cd7cbd}}  firmware REAL addition
        ret     c                 ;{{fd1d:d8}} 

;;=overflow error
overflow_error_B:                 ;{{Addr=$fd1e Code Calls/jump count: 2 Data use count: 0}}
        jp      overflow_error    ;{{fd1e:c3becb}} 

;;==========================================
;; infix minus -
infix_minus_:                     ;{{Addr=$fd21 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd21:cd3bfe}} 
        jr      nc,_infix_minus__5;{{fd24:3009}}  (+$09)
        call    INT_subtraction_with_overflow_test;{{fd26:cd52dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd29:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd2c:cd78fe}} 
_infix_minus__5:                  ;{{Addr=$fd2f Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_REVERSE_SUBTRACTION;{{fd2f:cd82bd}}  firmware REAL reverse subtraction
        ret     c                 ;{{fd32:d8}} 

        jr      overflow_error_B  ;{{fd33:18e9}}  (-$17)

;;==========================================
;; infix multiply *
infix_multiply_:                  ;{{Addr=$fd35 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd35:cd3bfe}} 
        jr      nc,_infix_multiply__5;{{fd38:3009}}  (+$09)
        call    INT_multiply_with_overflow_test;{{fd3a:cd5bdd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd3d:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd40:cd78fe}} 
_infix_multiply__5:               ;{{Addr=$fd43 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_MULTIPLICATION;{{fd43:cd85bd}} firmware REAL mltiplication
        ret     c                 ;{{fd46:d8}} 

        jr      overflow_error_B  ;{{fd47:18d5}}  (-$2b)

;;===============================================
;; infix comparisons (plural)
infix_comparisons_plural:         ;{{Addr=$fd49 Code Calls/jump count: 3 Data use count: 0}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd49:cd3bfe}} 
        jp      c,prob_compare_DE_to_HL;{{fd4c:da02de}} 
        jp      REAL_COMPARISON   ;{{fd4f:c38ebd}}  firmwware REAL compare

;;=============================================
;;infix divide /
infix_divide_:                    ;{{Addr=$fd52 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_REAL;{{fd52:cd70fe}} 
        ex      de,hl             ;{{fd55:eb}} 
        push    de                ;{{fd56:d5}} 
        call    REAL_DIVISION     ;{{fd57:cd88bd}}  firmware REAL division??
        pop     de                ;{{fd5a:d1}} 
        ld      bc,$0005          ;{{fd5b:010500}} 
        ldir                      ;{{fd5e:edb0}} 
        ret     c                 ;{{fd60:d8}} 

        jp      z,division_by_zero_error;{{fd61:cab5cb}} 
        jp      overflow_error    ;{{fd64:c3becb}} 

;;=================================================
;;infix integer division
infix_integer_division:           ;{{Addr=$fd67 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_atHL_with_type_C_and_accumulator_to_ints;{{fd67:cdc3fe}} 
        ex      de,hl             ;{{fd6a:eb}} 
        call    INT_division_with_overflow_test;{{fd6b:cd9cdd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd6e:da35ff}} 
        jr      z,raise_Division_by_zero_error;{{fd71:2810}}  (+$10)
        ld      hl,$8000          ;{{fd73:210080}} 
        jp      set_accumulator_as_REAL_from_unsigned_INT;{{fd76:c389fe}} 

;;=================================================
;;infix MOD
infix_MOD:                        ;{{Addr=$fd79 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_atHL_with_type_C_and_accumulator_to_ints;{{fd79:cdc3fe}} 
        ex      de,hl             ;{{fd7c:eb}} 
        call    INT_modulo        ;{{fd7d:cda3dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd80:da35ff}} 

;;=raise Division by zero error
raise_Division_by_zero_error:     ;{{Addr=$fd83 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{fd83:cd45cb}} 
        defb $0b                  ;Inline error code: Division by zero

;;============================================
;; infix AND
infix_AND:                        ;{{Addr=$fd87 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_atHL_with_type_C_and_accumulator_to_ints;{{fd87:cdc3fe}} 
        ld      a,e               ;{{fd8a:7b}} 
        and     l                 ;{{fd8b:a5}} 
        ld      l,a               ;{{fd8c:6f}} 
        ld      a,h               ;{{fd8d:7c}} 
        and     d                 ;{{fd8e:a2}} 

;;=infix logic done
infix_logic_done:                 ;{{Addr=$fd8f Code Calls/jump count: 3 Data use count: 0}}
        jp      store_AL_in_accumulator_as_INT;{{fd8f:c334ff}} 

;;=============================================
;; infix OR
infix_OR:                         ;{{Addr=$fd92 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_atHL_with_type_C_and_accumulator_to_ints;{{fd92:cdc3fe}} 
        ld      a,e               ;{{fd95:7b}} 
        or      l                 ;{{fd96:b5}} 
        ld      l,a               ;{{fd97:6f}} 
        ld      a,d               ;{{fd98:7a}} 
        or      h                 ;{{fd99:b4}} 
        jr      infix_logic_done  ;{{fd9a:18f3}}  (-$0d)

;;==============================================
;; infix XOR
infix_XOR:                        ;{{Addr=$fd9c Code Calls/jump count: 0 Data use count: 1}}
        call    convert_atHL_with_type_C_and_accumulator_to_ints;{{fd9c:cdc3fe}} 
        ld      a,e               ;{{fd9f:7b}} 
        xor     l                 ;{{fda0:ad}} 
        ld      l,a               ;{{fda1:6f}} 
        ld      a,h               ;{{fda2:7c}} 
        xor     d                 ;{{fda3:aa}} 
        jr      infix_logic_done  ;{{fda4:18e9}}  (-$17)

;;===============================================
;;bitwise complement/invert
bitwise_complementinvert:         ;{{Addr=$fda6 Code Calls/jump count: 1 Data use count: 0}}
        call    function_CINT     ;{{fda6:cdb6fe}} 
        ld      a,l               ;{{fda9:7d}} 
        cpl                       ;{{fdaa:2f}} 
        ld      l,a               ;{{fdab:6f}} 
        ld      a,h               ;{{fdac:7c}} 
        cpl                       ;{{fdad:2f}} 
        jr      infix_logic_done  ;{{fdae:18df}}  (-$21)





