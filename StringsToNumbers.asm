;;<< STRINGS TO NUMBERS
;;==============================
;;convert string to number
;Converts a string which can have a preceding + or - sign

convert_string_to_number:         ;{{Addr=$ed6f Code Calls/jump count: 3 Data use count: 0}}
        call    test_for_plus_or_minus_sign;{{ed6f:cd0fee}} 
        jr      nz,_convert_string_to_number_4;{{ed72:2005}}  (+$05) No plus or minus sign
        call    skip_space_tab_or_line_feed;{{ed74:cd4dde}}  skip space, lf or tab
        jr      convert_decimal   ;{{ed77:182f}}  (+$2f)

_convert_string_to_number_4:      ;{{Addr=$ed79 Code Calls/jump count: 1 Data use count: 0}}
        cp      $26               ;{{ed79:fe26}} '&' - Hex prefix
        jr      z,convert_hex_or_binary_to_accumulator;{{ed7b:281c}}  (+$1c)
        call    test_if_period_or_digit;{{ed7d:cda0ff}} 
        jr      c,convert_decimal ;{{ed80:3826}}  (+$26) Carry set if decimal digit or period

        call    set_accumulator_type_to_int;{{ed82:cd38ff}} 
        call    zero_accumulator  ;{{ed85:cd1bff}} 
        scf                       ;{{ed88:37}} 
        ret                       ;{{ed89:c9}} 

;;=convert string to positive number
;Converts a string which doesn't have a preceding sign. The result will always be positive
convert_string_to_positive_number:;{{Addr=$ed8a Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ed8a:e5}} 
        call    _convert_string_to_positive_number_6;{{ed8b:cd92ed}} 
        pop     de                ;{{ed8e:d1}} 
        ret     c                 ;{{ed8f:d8}} 

        ex      de,hl             ;{{ed90:eb}} 
        ret                       ;{{ed91:c9}} 

_convert_string_to_positive_number_6:;{{Addr=$ed92 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,$00             ;{{ed92:1600}} Positive number
        ld      a,(hl)            ;{{ed94:7e}} 
        cp      $26               ;{{ed95:fe26}} '&' - Hex prefix
        jr      nz,convert_decimal;{{ed97:200f}}  (+$0f)

;;=convert hex or binary to accumulator
convert_hex_or_binary_to_accumulator:;{{Addr=$ed99 Code Calls/jump count: 1 Data use count: 0}}
        call    convert_hex_or_binary_to_HL;{{ed99:cde7ee}} 
        ex      de,hl             ;{{ed9c:eb}} 
        push    af                ;{{ed9d:f5}} 
        call    store_HL_in_accumulator_as_INT;{{ed9e:cd35ff}} 
        pop     af                ;{{eda1:f1}} 
        ex      de,hl             ;{{eda2:eb}} 
        ret     c                 ;{{eda3:d8}} 

        ret     z                 ;{{eda4:c8}} 

        jp      overflow_error    ;{{eda5:c3becb}} 

;;=convert decimal
;D=&00 if positive, &ff if negative
convert_decimal:                  ;{{Addr=$eda8 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{eda8:e5}} 
        ld      a,(hl)            ;{{eda9:7e}} 
        inc     hl                ;{{edaa:23}} 
        cp      $2e               ;{{edab:fe2e}} '.' - prefix for a float
        call    z,skip_space_tab_or_line_feed;{{edad:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{edb0:cda4ff}} ; test if ASCII character represents a decimal number digit
        pop     hl                ;{{edb3:e1}} 
        jr      c,_convert_decimal_13;{{edb4:3806}}  (+$06) Carry set = digit
        ld      a,(hl)            ;{{edb6:7e}} 
        xor     $2e               ;{{edb7:ee2e}} Set zero flag if char is a period...
        ret     nz                ;{{edb9:c0}} 

        inc     hl                ;{{edba:23}} ...and if so step over it
        ret                       ;{{edbb:c9}} 

;Copy ASCII number to pre-conversion buffer. Digits are converted from ASCII to binary equivalents
_convert_decimal_13:              ;{{Addr=$edbc Code Calls/jump count: 1 Data use count: 0}}
        call    set_accumulator_type_to_int;{{edbc:cd38ff}} Convert as an integer until we know otherwise
        push    de                ;{{edbf:d5}} 
        ld      bc,$0000          ;{{edc0:010000}} Initialise counters ##LIT##
        ld      de,preconversion_buffer;{{edc3:112dae}} 
        call    copy_while_decimal_digits;{{edc6:cd1eee}} 
        cp      $2e               ;{{edc9:fe2e}} '.'
        jr      nz,_convert_decimal_25;{{edcb:200b}}  (+$0b) - no period - all digits read

;period found - number is a real
        call    skip_whitespace   ;{{edcd:cd94ee}} 
        call    set_accumulator_type_to_real;{{edd0:cd41ff}} 
        inc     c                 ;{{edd3:0c}} 
        call    copy_while_decimal_digits;{{edd4:cd1eee}} Read remaining decimal digits
        dec     c                 ;{{edd7:0d}} 

_convert_decimal_25:              ;{{Addr=$edd8 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{edd8:eb}} 
        ld      (hl),$ff          ;{{edd9:36ff}} 
        ex      de,hl             ;{{eddb:eb}} 
        call    test_for_and_eval_exponent;{{eddc:cd42ee}} Test for (and copy if found) exponent
        pop     de                ;{{eddf:d1}} 
        ld      e,a               ;{{ede0:5f}} E=exponent
        push    hl                ;{{ede1:e5}} 
        push    de                ;{{ede2:d5}} 

        ld      hl,preconversion_buffer;{{ede3:212dae}} 
        call    do_decimal_conversion;{{ede6:cd99ee}} Do the conversion?
        pop     de                ;{{ede9:d1}} 

        call    is_accumulator_a_string;{{edea:cd66ff}} Test result type?
        jr      nc,_convert_decimal_43;{{eded:3008}}  (+$08) Real?

        push    hl                ;{{edef:e5}} 
        ld      b,d               ;{{edf0:42}} B=sign?
        call    _function_int_11  ;{{edf1:cd2cfe}} Attempt to store as an int
        pop     hl                ;{{edf4:e1}} 
        jr      c,_convert_decimal_52;{{edf5:3811}}  (+$11) If succeeds then were done...
                                  ;...else store as a real
_convert_decimal_43:              ;{{Addr=$edf7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{edf7:7a}} A=sign?
        ld      c,(hl)            ;{{edf8:4e}} 
        inc     hl                ;{{edf9:23}} 
        call    REAL_5byte_to_real;{{edfa:cdb8bd}} Convert binary to real?
        ld      a,e               ;{{edfd:7b}} A=exponent
        call    REAL_10A          ;{{edfe:cd79bd}} Exponent?
        ex      de,hl             ;{{ee01:eb}} 
        call    set_accumulator_type_to_real_and_HL_to_accumulator_addr;{{ee02:cd3eff}} 
        call    c,REAL_copy_atDE_to_atHL;{{ee05:dc61bd}} Copy to accumulator?

_convert_decimal_52:              ;{{Addr=$ee08 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0a             ;{{ee08:3e0a}} We found a decimal number?
        pop     hl                ;{{ee0a:e1}} 
        ret     c                 ;{{ee0b:d8}} Return if no errors

        jp      overflow_error    ;{{ee0c:c3becb}} 

;;=test for plus or minus sign
;If next char is:
;'-': returns Zero set, D=$ff
;'+': returns Zero set, D=$00
;Otherwise returns Zero clear
test_for_plus_or_minus_sign:      ;{{Addr=$ee0f Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee0f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee12:23}} 
        ld      d,$ff             ;{{ee13:16ff}} 
        cp      $2d               ;{{ee15:fe2d}} '-'
        ret     z                 ;{{ee17:c8}} 

        inc     d                 ;{{ee18:14}} 
        cp      $2b               ;{{ee19:fe2b}} '+'
        ret     z                 ;{{ee1b:c8}} 

        dec     hl                ;{{ee1c:2b}} 
        ret                       ;{{ee1d:c9}} 

;;=copy while decimal digits
;Copies decimal digits to buffer in DE, ignoring leading zeros (B=0) and 
;ending at the first non-digit.
;Following char is returned in A
;Digits are converted from ASCII to binary equivalents
;B=count of digits copied to buffer
;C will be non-zero if more than one digit has been copied
copy_while_decimal_digits:        ;{{Addr=$ee1e Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{ee1e:e5}} 
        call    skip_space_tab_or_line_feed;{{ee1f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee22:23}} 
        call    test_if_digit     ;{{ee23:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_copy_while_decimal_digits_7;{{ee26:3804}}  (+$04) Carry set if decimal digit
        pop     hl                ;{{ee28:e1}} 
        jp      convert_character_to_upper_case;{{ee29:c3abff}} ; convert character to upper case

_copy_while_decimal_digits_7:     ;{{Addr=$ee2c Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee2c:e3}} 
        pop     hl                ;{{ee2d:e1}} 
        sub     $30               ;{{ee2e:d630}} Converts ASCII number to decimal value
        ld      (de),a            ;{{ee30:12}} Write digit to buffer
        or      b                 ;{{ee31:b0}} If digit=0 and digits copied = 0, result will be zero - i.e. leading zero
        jr      z,_copy_while_decimal_digits_18;{{ee32:2807}}  (+$07) Step over leading zeroes
        ld      a,b               ;{{ee34:78}} 
        inc     b                 ;{{ee35:04}} 
        cp      $0c               ;{{ee36:fe0c}} Max buffer length?
        jr      nc,_copy_while_decimal_digits_18;{{ee38:3001}}  (+$01) Buffer overflow - ignore digits
        inc     de                ;{{ee3a:13}} 
_copy_while_decimal_digits_18:    ;{{Addr=$ee3b Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{ee3b:79}} 
        or      a                 ;{{ee3c:b7}} 
        jr      z,copy_while_decimal_digits;{{ee3d:28df}}  (-$21)
        inc     c                 ;{{ee3f:0c}} 
        jr      copy_while_decimal_digits;{{ee40:18dc}} 

;;=test for and eval exponent
test_for_and_eval_exponent:       ;{{Addr=$ee42 Code Calls/jump count: 1 Data use count: 0}}
        cp      $45               ;{{ee42:fe45}} ; 'E' - exponent
        jr      nz,_test_for_and_eval_exponent_9;{{ee44:2010}} Not exponent
         
        push    hl                ;{{ee46:e5}} 
        call    skip_whitespace   ;{{ee47:cd94ee}} 
        call    test_for_plus_or_minus_sign;{{ee4a:cd0fee}} 
        call    z,skip_space_tab_or_line_feed;{{ee4d:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{ee50:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,eval_exponent   ;{{ee53:3804}}  (+$04)
        pop     hl                ;{{ee55:e1}} 

_test_for_and_eval_exponent_9:    ;{{Addr=$ee56 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{ee56:af}} Exponent is zero
        jr      _eval_exponent_20 ;{{ee57:181e}}  (+$1e)

;;=eval exponent
eval_exponent:                    ;{{Addr=$ee59 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee59:e3}} 
        pop     hl                ;{{ee5a:e1}} 
        call    set_accumulator_type_to_real;{{ee5b:cd41ff}} 
        push    de                ;{{ee5e:d5}} 
        push    bc                ;{{ee5f:c5}} 
        call    convert_decimal_integer;{{ee60:cd00ef}} 
        jr      nc,_eval_exponent_13;{{ee63:3009}}  (+$09)
        ld      a,e               ;{{ee65:7b}} 
        sub     $64               ;{{ee66:d664}} Maximum exponent?
        ld      a,d               ;{{ee68:7a}} 
        sbc     a,$00             ;{{ee69:de00}} 
        ld      a,e               ;{{ee6b:7b}} 
        jr      c,_eval_exponent_14;{{ee6c:3802}}  (+$02)
_eval_exponent_13:                ;{{Addr=$ee6e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$7f             ;{{ee6e:3e7f}} 
_eval_exponent_14:                ;{{Addr=$ee70 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{ee70:c1}} 
        pop     de                ;{{ee71:d1}} 
        inc     d                 ;{{ee72:14}} D=sign
        jr      nz,_eval_exponent_20;{{ee73:2002}}  (+$02)
        cpl                       ;{{ee75:2f}} 
        inc     a                 ;{{ee76:3c}} 

;A=exponent - encode?
_eval_exponent_20:                ;{{Addr=$ee77 Code Calls/jump count: 2 Data use count: 0}}
        add     a,$80             ;{{ee77:c680}} 
        ld      e,a               ;{{ee79:5f}} 
        ld      a,b               ;{{ee7a:78}} 
        sub     $0c               ;{{ee7b:d60c}} 
        jr      nc,_eval_exponent_26;{{ee7d:3001}}  (+$01)
        xor     a                 ;{{ee7f:af}} 
_eval_exponent_26:                ;{{Addr=$ee80 Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{ee80:91}} 
        jr      nc,_eval_exponent_34;{{ee81:3009}}  (+$09)
        add     a,e               ;{{ee83:83}} 
        jr      c,_eval_exponent_31;{{ee84:3801}}  (+$01)
        xor     a                 ;{{ee86:af}} 
_eval_exponent_31:                ;{{Addr=$ee87 Code Calls/jump count: 1 Data use count: 0}}
        cp      $01               ;{{ee87:fe01}} 
        adc     a,$80             ;{{ee89:ce80}} 
        ret                       ;{{ee8b:c9}} 

_eval_exponent_34:                ;{{Addr=$ee8c Code Calls/jump count: 1 Data use count: 0}}
        add     a,e               ;{{ee8c:83}} 
        jr      nc,_eval_exponent_37;{{ee8d:3002}}  (+$02)
        ld      a,$ff             ;{{ee8f:3eff}} 
_eval_exponent_37:                ;{{Addr=$ee91 Code Calls/jump count: 1 Data use count: 0}}
        sub     $80               ;{{ee91:d680}} 
        ret                       ;{{ee93:c9}} 

;;=skip whitespace
skip_whitespace:                  ;{{Addr=$ee94 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee94:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee97:23}} 
        ret                       ;{{ee98:c9}} 

;;=do decimal conversion
do_decimal_conversion:            ;{{Addr=$ee99 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ee99:eb}} 
        ld      hl,end_of_conversion_buffer + 1;{{ee9a:213fae}} Zero buffer for result
        ld      bc,$0501          ;{{ee9d:010105}} B=counter for next loop;C=count of how many bytes we need to multiply
_do_decimal_conversion_3:         ;{{Addr=$eea0 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{eea0:2b}} 
        ld      (hl),$00          ;{{eea1:3600}} 
        djnz    _do_decimal_conversion_3;{{eea3:10fb}}  (-$05)
        ld      a,(de)            ;{{eea5:1a}} 
        cp      $ff               ;{{eea6:feff}} End of ASCII digits marker
        ret     z                 ;{{eea8:c8}} 

        ld      (hl),a            ;{{eea9:77}} Write first digit

;;=decimal convert loop for digits in input buffer
decimal_convert_loop_for_digits_in_input_buffer:;{{Addr=$eeaa Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,conversion_buffer;{{eeaa:213aae}} 
        inc     de                ;{{eead:13}} 
        ld      a,(de)            ;{{eeae:1a}} Read next digit
        cp      $ff               ;{{eeaf:feff}} End of buffer marker
        ret     z                 ;{{eeb1:c8}} 

        push    de                ;{{eeb2:d5}} 
        ld      b,c               ;{{eeb3:41}} Source digit counter
        ld      d,$00             ;{{eeb4:1600}} 

;;=decimal convert multiply loop
decimal_convert_multiply_loop:    ;{{Addr=$eeb6 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{eeb6:e5}} 
        ld      e,(hl)            ;{{eeb7:5e}} 
        ld      h,d               ;{{eeb8:62}} 
        ld      l,e               ;{{eeb9:6b}} 
        add     hl,hl             ;{{eeba:29}} 
        add     hl,hl             ;{{eebb:29}} 
        add     hl,de             ;{{eebc:19}} 
        add     hl,hl             ;{{eebd:29}} 
        ld      e,a               ;{{eebe:5f}} 
        add     hl,de             ;{{eebf:19}} 
        ld      e,l               ;{{eec0:5d}} 
        ld      a,h               ;{{eec1:7c}} 
        pop     hl                ;{{eec2:e1}} 
        ld      (hl),e            ;{{eec3:73}} 
        inc     hl                ;{{eec4:23}} 
        djnz    decimal_convert_multiply_loop;{{eec5:10ef}}  (-$11)

        pop     de                ;{{eec7:d1}} 
        or      a                 ;{{eec8:b7}} 
        jr      z,decimal_convert_loop_for_digits_in_input_buffer;{{eec9:28df}}  (-$21)
        ld      (hl),a            ;{{eecb:77}} 
        inc     c                 ;{{eecc:0c}} 
        jr      decimal_convert_loop_for_digits_in_input_buffer;{{eecd:18db}}  (-$25)

;;=======================================================================
;;parse line number
parse_line_number:                ;{{Addr=$eecf Code Calls/jump count: 4 Data use count: 0}}
        push    bc                ;{{eecf:c5}} 
        push    hl                ;{{eed0:e5}} 
        call    convert_decimal_integer;{{eed1:cd00ef}} 
        ex      de,hl             ;{{eed4:eb}} 
        call    store_HL_in_accumulator_as_INT;{{eed5:cd35ff}} 
        ex      de,hl             ;{{eed8:eb}} 
        pop     bc                ;{{eed9:c1}} 
        jr      nc,_parse_line_number_12;{{eeda:3006}}  (+$06)
        ld      a,d               ;{{eedc:7a}} 
        or      e                 ;{{eedd:b3}} 
        add     a,$ff             ;{{eede:c6ff}} 
        jr      c,_parse_line_number_15;{{eee0:3803}}  (+$03)
_parse_line_number_12:            ;{{Addr=$eee2 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,b               ;{{eee2:50}} 
        ld      e,c               ;{{eee3:59}} 
        ex      de,hl             ;{{eee4:eb}} 
_parse_line_number_15:            ;{{Addr=$eee5 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{eee5:c1}} 
        ret                       ;{{eee6:c9}} 


;;=======================================================================
;;convert hex or binary to HL
convert_hex_or_binary_to_HL:      ;{{Addr=$eee7 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eee7:23}} 
        call    skip_space_tab_or_line_feed;{{eee8:cd4dde}}  skip space, lf or tab
        call    convert_character_to_upper_case;{{eeeb:cdabff}} ; convert character to upper case

        ld      b,$02             ;{{eeee:0602}} ; base 2
        cp      $58               ;{{eef0:fe58}} ; X
        jr      z,_convert_hex_or_binary_to_hl_9;{{eef2:2806}} 

        ld      b,$10             ;{{eef4:0610}} ; base 16
        cp      $48               ;{{eef6:fe48}} ; H
        jr      nz,_convert_hex_or_binary_to_hl_11;{{eef8:2004}} 

_convert_hex_or_binary_to_hl_9:   ;{{Addr=$eefa Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eefa:23}} 
        call    skip_space_tab_or_line_feed;{{eefb:cd4dde}}  skip space, lf or tab
_convert_hex_or_binary_to_hl_11:  ;{{Addr=$eefe Code Calls/jump count: 1 Data use count: 0}}
        jr      convert_number_using_base_in_B;{{eefe:1802}}  (+$02)

;;=======================================================================
;; convert decimal integer
convert_decimal_integer:          ;{{Addr=$ef00 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$0a             ;{{ef00:060a}} ; base 10

;;=convert number using base in B
; B = base: 2 for binary, 16 for hexadecimal, 10 for decimal
convert_number_using_base_in_B:   ;{{Addr=$ef02 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef02:eb}} 
        call    convert_digit_using_base_in_B;{{ef03:cd2cef}} 

        ld      h,$00             ;{{ef06:2600}} Result
        ld      l,a               ;{{ef08:6f}} 
        jr      nc,_based_conversion_loop_17;{{ef09:301e}}  (+$1e) Digit conversion failed

        ld      c,$00             ;{{ef0b:0e00}} Overflow flag?

;;=based conversion loop
based_conversion_loop:            ;{{Addr=$ef0d Code Calls/jump count: 1 Data use count: 0}}
        call    convert_digit_using_base_in_B;{{ef0d:cd2cef}} Next digit
        jr      nc,_based_conversion_loop_15;{{ef10:3014}}  (+$14) End of digits
        push    de                ;{{ef12:d5}} 

        ld      d,$00             ;{{ef13:1600}} DE=new digit
        ld      e,a               ;{{ef15:5f}} 
        push    de                ;{{ef16:d5}} 

        ld      e,b               ;{{ef17:58}} DE=base
        call    do_16x16_multiply_with_overflow;{{ef18:cd72dd}} 
        pop     de                ;{{ef1b:d1}} 
        jr      c,_based_conversion_loop_12;{{ef1c:3803}}  (+$03) Overflow
        add     hl,de             ;{{ef1e:19}} 
        jr      nc,_based_conversion_loop_13;{{ef1f:3002}}  (+$02) No overflow
_based_conversion_loop_12:        ;{{Addr=$ef21 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$ff             ;{{ef21:0eff}} Overflow flag?
_based_conversion_loop_13:        ;{{Addr=$ef23 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{ef23:d1}} 
        jr      based_conversion_loop;{{ef24:18e7}}  (-$19) Loop for next digit

_based_conversion_loop_15:        ;{{Addr=$ef26 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{ef26:79}} 
        cp      $01               ;{{ef27:fe01}} 
_based_conversion_loop_17:        ;{{Addr=$ef29 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef29:eb}} 
        ld      a,b               ;{{ef2a:78}} 
        ret                       ;{{ef2b:c9}} 

;;=convert digit using base in B
;Convert single ASCII digit to binary in selected base
convert_digit_using_base_in_B:    ;{{Addr=$ef2c Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{ef2c:1a}} 
        inc     de                ;{{ef2d:13}} 
        call    test_if_digit     ;{{ef2e:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_convert_digit_using_base_in_b_9;{{ef31:380a}}  (+$0a) Carry set if decimal digit
        call    convert_character_to_upper_case;{{ef33:cdabff}} ; convert character to upper case
        cp      $41               ;{{ef36:fe41}} 'A'
        ccf                       ;{{ef38:3f}} 
        jr      nc,_convert_digit_using_base_in_b_11;{{ef39:3005}}  (+$05)
        sub     $07               ;{{ef3b:d607}} Move ASCII letters to 'follow' ASCII numbers
_convert_digit_using_base_in_b_9: ;{{Addr=$ef3d Code Calls/jump count: 1 Data use count: 0}}
        sub     $30               ;{{ef3d:d630}} '0' - convert ASCII to binary
        cp      b                 ;{{ef3f:b8}} Validate we're within given base
_convert_digit_using_base_in_b_11:;{{Addr=$ef40 Code Calls/jump count: 1 Data use count: 0}}
        ret     c                 ;{{ef40:d8}} 

        dec     de                ;{{ef41:1b}} 
        xor     a                 ;{{ef42:af}} 
        ret                       ;{{ef43:c9}} 




