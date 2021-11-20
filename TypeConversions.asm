;;<< TYPE CONVERSIONS AND ROUNDING
;;< (from numbers to numbers)
;;========================================================
;; function ABS
function_ABS:                     ;{{Addr=$fdb0 Code Calls/jump count: 0 Data use count: 1}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{fdb0:cdc4fd}} 
        ret     p                 ;{{fdb3:f0}} 

;;=negate accumulator
negate_accumulator:               ;{{Addr=$fdb4 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fdb4:cd4fff}} 
        jp      nc,REAL_UNARY_MINUS;{{fdb7:d291bd}}  firmware REAL negate
        call    negate_HL_and_test_if_INT;{{fdba:cdeddd}} negate HL
        ld      (accumulator),hl  ;{{fdbd:22a0b0}} 
        call    nc,set_accumulator_as_REAL_from_unsigned_INT;{{fdc0:d489fe}} Not a valid INT so convert to a REAL
        ret                       ;{{fdc3:c9}} 

;;=get raw abs of accumulator with reg preserve
get_raw_abs_of_accumulator_with_reg_preserve:;{{Addr=$fdc4 Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{fdc4:c5}} 
        push    hl                ;{{fdc5:e5}} 
        call    get_raw_abs_of_accumulator;{{fdc6:cdccfd}} 
        pop     hl                ;{{fdc9:e1}} 
        pop     bc                ;{{fdca:c1}} 
        ret                       ;{{fdcb:c9}} 

;;=get raw abs of accumulator
;returns A = negative, 0 or positive
get_raw_abs_of_accumulator:       ;{{Addr=$fdcc Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fdcc:cd4fff}} 
        jp      c,unknown_test_HL ;{{fdcf:daf9dd}} 
        jp      REAL_SIGNUMSGN    ;{{fdd2:c394bd}} 

;;=round accumulator
round_accumulator:                ;{{Addr=$fdd5 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{fdd5:e5}} 
        ld      a,c               ;{{fdd6:79}} 
        call    copy_atHL_to_accumulator_type_A;{{fdd7:cd6cff}} 
        pop     de                ;{{fdda:d1}} 
        call    return_accumulator_value_if_int_or_address_if_real;{{fddb:cd4fff}} 
        ld      a,b               ;{{fdde:78}} 
        jr      nc,_round_accumulator_12;{{fddf:300b}}  (+$0b)
        or      a                 ;{{fde1:b7}} 
        ret     p                 ;{{fde2:f0}} 

        call    set_accumulator_as_positive_REAL_from_HL;{{fde3:cd93fe}} 
        call    _round_accumulator_16;{{fde6:cdf4fd}} 
        jp      function_CINT     ;{{fde9:c3b6fe}} 

_round_accumulator_12:            ;{{Addr=$fdec Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{fdec:b7}} 
        jr      nz,_round_accumulator_16;{{fded:2005}}  (+$05)
        ld      de,REAL_TO_BINARY ;{{fdef:116dbd}} firmware REAL to bin
        jr      _function_int_3   ;{{fdf2:1826}}  (+$26)

_round_accumulator_16:            ;{{Addr=$fdf4 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{fdf4:d5}} 
        push    bc                ;{{fdf5:c5}} 
        ld      a,b               ;{{fdf6:78}} 
        call    REAL_10A          ;{{fdf7:cd79bd}} 
        call    c,REAL_TO_BINARY  ;{{fdfa:dc6dbd}} firmware REAL to bin
        ld      a,b               ;{{fdfd:78}} 
        pop     bc                ;{{fdfe:c1}} 
        pop     de                ;{{fdff:d1}} 
        jr      nc,_round_accumulator_29;{{fe00:3008}}  (+$08)
        call    BINARY_TO_REAL    ;{{fe02:cd67bd}} firmware bin to REAL
        xor     a                 ;{{fe05:af}} 
        sub     b                 ;{{fe06:90}} 
        jp      REAL_10A          ;{{fe07:c379bd}}  firmware REAL exp A

_round_accumulator_29:            ;{{Addr=$fe0a Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe0a:eb}} 
        jp      copy_atHL_to_accumulator_using_accumulator_type;{{fe0b:c36fff}} 

;;========================================================
;; function FIX
function_FIX:                     ;{{Addr=$fe0e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,REAL_FIX       ;{{fe0e:1170bd}} firmware REAL fix
        jr      _function_int_1   ;{{fe11:1803}}  (+$03)

;;========================================================
;; function INT
function_INT:                     ;{{Addr=$fe13 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,REAL_INT       ;{{fe13:1173bd}} firmware REAL int
_function_int_1:                  ;{{Addr=$fe16 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fe16:cd4fff}} 
        ret     c                 ;{{fe19:d8}} 

_function_int_3:                  ;{{Addr=$fe1a Code Calls/jump count: 1 Data use count: 0}}
        call    JP_DE             ;{{fe1a:cdfeff}}  JP (DE)
        ret     nc                ;{{fe1d:d0}} 

        ld      a,(accumulator_data_type);{{fe1e:3a9fb0}} 
        call    _function_int_11  ;{{fe21:cd2cfe}} 
        ret     c                 ;{{fe24:d8}} 

        call    get_accumulator_type_in_c_and_addr_in_HL;{{fe25:cd45ff}} 
        ld      a,b               ;{{fe28:78}} 
        jp      BINARY_TO_REAL    ;{{fe29:c367bd}} firmware BIN to REAL

_function_int_11:                 ;{{Addr=$fe2c Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{fe2c:79}} 
        cp      $03               ;{{fe2d:fe03}} 
        ret     nc                ;{{fe2f:d0}} 

        ld      a,(hl)            ;{{fe30:7e}} 
        inc     hl                ;{{fe31:23}} 
        ld      h,(hl)            ;{{fe32:66}} 
        ld      l,a               ;{{fe33:6f}} 
        call    unknown_maths_fixup_B;{{fe34:cd37dd}} 
        ret     nc                ;{{fe37:d0}} 

        jp      store_HL_in_accumulator_as_INT;{{fe38:c335ff}} 

;;=========================================
;;convert accum and param to same numeric type
;(error if either is string).
;C=type of param
convert_accum_and_param_to_same_numeric_type:;{{Addr=$fe3b Code Calls/jump count: 5 Data use count: 0}}
        ld      a,c               ;{{fe3b:79}} C contains a type specifier
        cp      $03               ;{{fe3c:fe03}} 
        jr      z,raise_type_mismatch_error_B;{{fe3e:282d}}  (+$2d) if string?
        ld      a,(accumulator_data_type);{{fe40:3a9fb0}} 
        cp      $03               ;{{fe43:fe03}} 
        jr      z,raise_type_mismatch_error_B;{{fe45:2826}}  (+$26) if string
        cp      c                 ;{{fe47:b9}} 
        jr      z,_convert_accum_and_param_to_same_numeric_type_22;{{fe48:2817}}  (+$17) if same type as C
        jr      nc,_convert_accum_and_param_to_same_numeric_type_17;{{fe4a:300c}}  (+$0c) accum is real C is int
        push    hl                ;{{fe4c:e5}} else accum is int, C is real...
        ld      hl,accumulator_data_type;{{fe4d:219fb0}} ...so convert accum to real
        ld      (hl),c            ;{{fe50:71}} 
        inc     hl                ;{{fe51:23}} 
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe52:cd8cfe}} 
        pop     de                ;{{fe55:d1}} 
        or      a                 ;{{fe56:b7}} 
        ret                       ;{{fe57:c9}} 

_convert_accum_and_param_to_same_numeric_type_17:;{{Addr=$fe58 Code Calls/jump count: 1 Data use count: 0}}
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe58:cd8cfe}} 
        or      a                 ;{{fe5b:b7}} 
_convert_accum_and_param_to_same_numeric_type_19:;{{Addr=$fe5c Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe5c:eb}} 
        ld      hl,accumulator    ;{{fe5d:21a0b0}} 
        ret                       ;{{fe60:c9}} 

_convert_accum_and_param_to_same_numeric_type_22:;{{Addr=$fe61 Code Calls/jump count: 1 Data use count: 0}}
        xor     $02               ;{{fe61:ee02}} 
        jr      nz,_convert_accum_and_param_to_same_numeric_type_19;{{fe63:20f7}}  (-$09)
        ld      e,(hl)            ;{{fe65:5e}} 
        inc     hl                ;{{fe66:23}} 
        ld      d,(hl)            ;{{fe67:56}} 
        ld      hl,(accumulator)  ;{{fe68:2aa0b0}} 
        scf                       ;{{fe6b:37}} 
        ret                       ;{{fe6c:c9}} 

;;=raise Type mismatch error
raise_type_mismatch_error_B:      ;{{Addr=$fe6d Code Calls/jump count: 2 Data use count: 0}}
        jp      raise_type_mismatch_error_C;{{fe6d:c362ff}} 

;;==================================
;;convert accum and param to REAL
convert_accum_and_param_to_REAL:  ;{{Addr=$fe70 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(accumulator_data_type);{{fe70:3a9fb0}} 
        or      c                 ;{{fe73:b1}} 
        cp      $02               ;{{fe74:fe02}} 
        jr      nz,convert_accum_and_param_to_same_numeric_type;{{fe76:20c3}}  (-$3d)

;;=convert INT accum and INT param to REAL
convert_INT_accum_and_INT_param_to_REAL:;{{Addr=$fe78 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fe78:2aa0b0}} 
        call    set_accumulator_as_positive_REAL_from_HL;{{fe7b:cd93fe}} 
        ld      hl,(execution_stack_next_free_ptr);{{fe7e:2a6fb0}} 
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe81:cd8cfe}} 
        ex      de,hl             ;{{fe84:eb}} 
        ld      hl,accumulator    ;{{fe85:21a0b0}} 
        ret                       ;{{fe88:c9}} 

;;======================================
;;set accumulator as REAL from unsigned INT
set_accumulator_as_REAL_from_unsigned_INT:;{{Addr=$fe89 Code Calls/jump count: 5 Data use count: 0}}
        xor     a                 ;{{fe89:af}} 
        jr      set_accumulator_from_HL_with_possible_invert;{{fe8a:1808}}  (+$08)

;;=======================================
;;convert INT atHL to positive REAL atHL
convert_INT_atHL_to_positive_REAL_atHL:;{{Addr=$fe8c Code Calls/jump count: 3 Data use count: 0}}
        ld      e,(hl)            ;{{fe8c:5e}} 
        inc     hl                ;{{fe8d:23}} 
        ld      d,(hl)            ;{{fe8e:56}} 
        dec     hl                ;{{fe8f:2b}} 
        ld      a,d               ;{{fe90:7a}} 
        jr      set_atHL_from_DE_with_possible_invert;{{fe91:1808}}  (+$08)

;;=======================================
;;set accumulator as positive REAL from HL
;HL=int value
set_accumulator_as_positive_REAL_from_HL:;{{Addr=$fe93 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,h               ;{{fe93:7c}} 

;;=set accumulator from HL with possible invert
;invert if bit 7 of a is set
set_accumulator_from_HL_with_possible_invert:;{{Addr=$fe94 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe94:eb}} 
        ld      hl,accumulator_data_type;{{fe95:219fb0}} 
        ld      (hl),$05          ;{{fe98:3605}} 
        inc     hl                ;{{fe9a:23}} 

;;=set atHL from DE with possible invert
;invert if bit 7 of a is set
set_atHL_from_DE_with_possible_invert:;{{Addr=$fe9b Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe9b:eb}} 
        push    af                ;{{fe9c:f5}} 
        or      a                 ;{{fe9d:b7}} 
        call    m,negate_HL_and_test_if_INT;{{fe9e:fceddd}} 
        pop     af                ;{{fea1:f1}} 
        jp      INTEGER_TO_REAL   ;{{fea2:c364bd}} firmware INT to REAL

;;===================================
;;store int to accumulator
store_int_to_accumulator:         ;{{Addr=$fea5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator),hl  ;{{fea5:22a0b0}} 

;;=====================================
;;set accumulator as REAL from BINARY zero or minus one
;binary in HL only. (useful only for -1 and zero??)
        ex      de,hl             ;{{fea8:eb}} 
        ld      (accumulator_plus_2),hl;{{fea9:22a2b0}} 
        ld      hl,accumulator_data_type;{{feac:219fb0}} 
        ld      (hl),$05          ;{{feaf:3605}} 
        inc     hl                ;{{feb1:23}} 
        xor     a                 ;{{feb2:af}} 
        jp      BINARY_TO_REAL    ;{{feb3:c367bd}} firmware BIN to REAL

;;========================================================
;; function CINT
function_CINT:                    ;{{Addr=$feb6 Code Calls/jump count: 10 Data use count: 1}}
        call    _function_cint_3  ;{{feb6:cdbcfe}} 
        ret     c                 ;{{feb9:d8}} 

        jr      raise_Overflow_error;{{feba:183f}}  (+$3f)

_function_cint_3:                 ;{{Addr=$febc Code Calls/jump count: 1 Data use count: 0}}
        call    _function_cint_12 ;{{febc:cdcefe}} 
        ld      (accumulator),hl  ;{{febf:22a0b0}} 
        ret                       ;{{fec2:c9}} 

;;-=============================================
;;
_function_cint_6:                 ;{{Addr=$fec3 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,c               ;{{fec3:79}} 
        call    _function_cint_16 ;{{fec4:cdd5fe}} 
        ex      de,hl             ;{{fec7:eb}} 
        call    c,_function_cint_12;{{fec8:dccefe}} carry here means we had a pointer to an int
        ret     c                 ;{{fecb:d8}} 

        jr      raise_Overflow_error;{{fecc:182d}}  (+$2d)

_function_cint_12:                ;{{Addr=$fece Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator_data_type;{{fece:219fb0}} 
        ld      a,(hl)            ;{{fed1:7e}} 
        ld      (hl),$02          ;{{fed2:3602}} 
        inc     hl                ;{{fed4:23}} 
_function_cint_16:                ;{{Addr=$fed5 Code Calls/jump count: 1 Data use count: 0}}
        cp      $03               ;{{fed5:fe03}} 
        jr      c,_function_cint_25;{{fed7:380d}}  (+$0d) if type is int treat it as a pointer to the actual real and redo
        jp      z,raise_type_mismatch_error_C;{{fed9:ca62ff}}  error if string
        push    bc                ;{{fedc:c5}} 
        call    REAL_TO_INTEGER   ;{{fedd:cd6abd}}  firmware REAL to INT
        ld      b,a               ;{{fee0:47}} 
        call    c,unknown_maths_fixup_B;{{fee1:dc37dd}} 
        pop     bc                ;{{fee4:c1}} 
        ret                       ;{{fee5:c9}} 

_function_cint_25:                ;{{Addr=$fee6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{fee6:7e}} 
        inc     hl                ;{{fee7:23}} 
        ld      h,(hl)            ;{{fee8:66}} 
        ld      l,a               ;{{fee9:6f}} 
        ret                       ;{{feea:c9}} 

;;========================================================
;; function UNT

function_UNT:                     ;{{Addr=$feeb Code Calls/jump count: 4 Data use count: 1}}
        call    return_accumulator_value_if_int_or_address_if_real;{{feeb:cd4fff}} 
        ret     c                 ;{{feee:d8}} 

        call    REAL_TO_INTEGER   ;{{feef:cd6abd}} 
        jr      nc,raise_Overflow_error;{{fef2:3007}}  (+$07)
        ld      b,a               ;{{fef4:47}} 
        call    m,unknown_maths_fixup_B;{{fef5:fc37dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fef8:da35ff}} 

;;=raise Overflow error
raise_Overflow_error:             ;{{Addr=$fefb Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{fefb:cd45cb}} 
        defb $06                  ;Inline error code: Overflow

;;=====================================
;;convert accumulator to type in A
;int to real or real to int only
convert_accumulator_to_type_in_A: ;{{Addr=$feff Code Calls/jump count: 5 Data use count: 0}}
        push hl                   ;{{feff:e5}} 
        push    de                ;{{ff00:d5}} 
        push    bc                ;{{ff01:c5}} 
        ld      hl,accumulator_data_type;{{ff02:219fb0}} 
        cp      (hl)              ;{{ff05:be}} 
        call    nz,_convert_accumulator_to_type_in_a_10;{{ff06:c40dff}} 
        pop     bc                ;{{ff09:c1}} 
        pop     de                ;{{ff0a:d1}} 
        pop     hl                ;{{ff0b:e1}} 
        ret                       ;{{ff0c:c9}} 

_convert_accumulator_to_type_in_a_10:;{{Addr=$ff0d Code Calls/jump count: 1 Data use count: 0}}
        sub     $03               ;{{ff0d:d603}} 
        jr      c,function_CINT   ;{{ff0f:38a5}}  (-$5b)
        jp      z,error_if_accumulator_is_not_a_string;{{ff11:ca5eff}} 

;;========================================================
;; function CREAL
function_CREAL:                   ;{{Addr=$ff14 Code Calls/jump count: 4 Data use count: 1}}
        call    return_accumulator_value_if_int_or_address_if_real;{{ff14:cd4fff}} 
        jp      c,set_accumulator_as_positive_REAL_from_HL;{{ff17:da93fe}} 
        ret                       ;{{ff1a:c9}} 

;;========================================
;;zero accumulator
zero_accumulator:                 ;{{Addr=$ff1b Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ff1b:e5}} ##LIT##
        ld      hl,RESET_ENTRY    ;{{ff1c:210000}} 
        ld      (accumulator),hl  ;{{ff1f:22a0b0}} 
        ld      (accumulator_plus_2),hl;{{ff22:22a2b0}} 
        ld      (accumulator_plus_3),hl;{{ff25:22a3b0}} 
        pop     hl                ;{{ff28:e1}} 
        ret                       ;{{ff29:c9}} 

;;========================================================
;; function SGN
function_SGN:                     ;{{Addr=$ff2a Code Calls/jump count: 0 Data use count: 1}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{ff2a:cdc4fd}} 

;;=store sign extended byte in A in accumulator
store_sign_extended_byte_in_A_in_accumulator:;{{Addr=$ff2d Code Calls/jump count: 2 Data use count: 0}}
        ld      l,a               ;{{ff2d:6f}} 
        add     a,a               ;{{ff2e:87}} 
        sbc     a,a               ;{{ff2f:9f}} 
        jr      store_AL_in_accumulator_as_INT;{{ff30:1802}}  (+$02)

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
;;probably push accumulator on execution stack
probably_push_accumulator_on_execution_stack:;{{Addr=$ff74 Code Calls/jump count: 4 Data use count: 0}}
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



