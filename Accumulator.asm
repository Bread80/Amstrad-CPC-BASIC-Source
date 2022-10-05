;;<< ACCUMULATOR UTILITIES
;;< Store values to accumulator, get values from accumulator,
;;< and accumulator type conversions
;;=========================================================
;;=store A in accumulator as INT
store_A_in_accumulator_as_INT:    ;{{Addr=$ff32 Code Calls/jump count: 10 Data use count: 0}}
        ld      l,a               ;{{ff32:6f}} 
        xor     a                 ;{{ff33:af}} 
;;=store AL in accumulator as INT
store_AL_in_accumulator_as_INT:   ;{{Addr=$ff34 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,a               ;{{ff34:67}} 

;;=store HL in accumulator as INT
store_HL_in_accumulator_as_INT:   ;{{Addr=$ff35 Code Calls/jump count: 16 Data use count: 0}}
        ld      (accumulator),hl  ;{{ff35:22a0b0}} 
;;=set accumulator type to int
set_accumulator_type_to_int:      ;{{Addr=$ff38 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$02             ;{{ff38:3e02}} int
;;=set accumulator data type
set_accumulator_data_type:        ;{{Addr=$ff3a Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator_data_type),a;{{ff3a:329fb0}} 
        ret                       ;{{ff3d:c9}} 

;;====================================
;;=set accumulator type to real and HL to accumulator addr
set_accumulator_type_to_real_and_HL_to_accumulator_addr:;{{Addr=$ff3e Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator    ;{{ff3e:21a0b0}} 
;;=set accumulator type to real
set_accumulator_type_to_real:     ;{{Addr=$ff41 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$05             ;{{ff41:3e05}} real
        jr      set_accumulator_data_type;{{ff43:18f5}}  (-$0b)

;;======================================
;;get accumulator type in c and addr in HL
get_accumulator_type_in_c_and_addr_in_HL:;{{Addr=$ff45 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator_data_type;{{ff45:219fb0}} 
        ld      c,(hl)            ;{{ff48:4e}} 
        inc     hl                ;{{ff49:23}} 
        ret                       ;{{ff4a:c9}} 

;;=====================================
;;get accumulator data type
get_accumulator_data_type:        ;{{Addr=$ff4b Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff4b:3a9fb0}} 
        ret                       ;{{ff4e:c9}} 

;;======================================
;;return accumulator value if int or address if real
return_accumulator_value_if_int_or_address_if_real:;{{Addr=$ff4f Code Calls/jump count: 7 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff4f:3a9fb0}} 
        cp      $03               ;{{ff52:fe03}} string
        jr      z,raise_type_mismatch_error_C;{{ff54:280c}}  (+$0c) error if string
        ld      hl,(accumulator)  ;{{ff56:2aa0b0}} 
        ret     c                 ;{{ff59:d8}} 

        ld      hl,accumulator    ;{{ff5a:21a0b0}} 
        ret                       ;{{ff5d:c9}} 

;;==================================
;;error if accumulator is not a string
error_if_accumulator_is_not_a_string:;{{Addr=$ff5e Code Calls/jump count: 6 Data use count: 0}}
        call    is_accumulator_a_string;{{ff5e:cd66ff}} 
        ret     z                 ;{{ff61:c8}} 

;;=raise Type Mismatch error
raise_type_mismatch_error_C:      ;{{Addr=$ff62 Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{ff62:cd45cb}} 
        defb $0d                  ;Inline error code: Type mismatch

;;=======================================================
;;is accumulator a string?
is_accumulator_a_string:          ;{{Addr=$ff66 Code Calls/jump count: 14 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff66:3a9fb0}}  accumulator type
        cp      $03               ;{{ff69:fe03}} string marker
        ret                       ;{{ff6b:c9}} 

;;================
;;copy atHL to accumulator type A
copy_atHL_to_accumulator_type_A:  ;{{Addr=$ff6c Code Calls/jump count: 7 Data use count: 0}}
        ld      (accumulator_data_type),a;{{ff6c:329fb0}} 
;;=copy atHL to accumulator using accumulator type
copy_atHL_to_accumulator_using_accumulator_type:;{{Addr=$ff6f Code Calls/jump count: 2 Data use count: 0}}
        ld      de,accumulator    ;{{ff6f:11a0b0}} 
        jr      copy_value_atHL_to_atDE_accumulator_type;{{ff72:1813}}  (+$13)

;;================
;;push numeric accumulator on execution stack
push_numeric_accumulator_on_execution_stack:;{{Addr=$ff74 Code Calls/jump count: 4 Data use count: 0}}
        push    de                ;{{ff74:d5}} 
        push    hl                ;{{ff75:e5}} 
        ld      a,(accumulator_data_type);{{ff76:3a9fb0}} 
        ld      c,a               ;{{ff79:4f}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{ff7a:cd72f6}} 
        call    copy_numeric_accumulator_to_atHL;{{ff7d:cd83ff}} 
        pop     hl                ;{{ff80:e1}} 
        pop     de                ;{{ff81:d1}} 
        ret                       ;{{ff82:c9}} 

;;========================================
;;copy numeric accumulator to atHL
copy_numeric_accumulator_to_atHL: ;{{Addr=$ff83 Code Calls/jump count: 6 Data use count: 0}}
        ex      de,hl             ;{{ff83:eb}} 
        ld      hl,accumulator    ;{{ff84:21a0b0}} 

;;=copy value atHL to atDE accumulator type
copy_value_atHL_to_atDE_accumulator_type:;{{Addr=$ff87 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{ff87:c5}} 
        ld      a,(accumulator_data_type);{{ff88:3a9fb0}} 
        ld      c,a               ;{{ff8b:4f}} 
        ld      b,$00             ;{{ff8c:0600}} 
        ldir                      ;{{ff8e:edb0}} 
        pop     bc                ;{{ff90:c1}} 
        ret                       ;{{ff91:c9}} 



