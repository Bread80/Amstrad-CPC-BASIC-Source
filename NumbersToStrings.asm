;;<< NUMBERS TO STRINGS
;;============================================
;;display decimal number
;Display the value in HL to the current stream
display_decimal_number:           ;{{Addr=$ef44 Code Calls/jump count: 2 Data use count: 0}}
        call    convert_int_in_HL_to_string;{{ef44:cd4aef}} 
        jp      output_ASCIIZ_string;{{ef47:c38bc3}} ; display 0 terminated string

;;=convert int in HL to string
;Convert the value in HL to a string. Could be integer or real depending on the size of the number
convert_int_in_HL_to_string:      ;{{Addr=$ef4a Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{ef4a:d5}} 
        push    bc                ;{{ef4b:c5}} 
        call    store_HL_in_accumulator_as_INT;{{ef4c:cd35ff}} 
        call    set_regs_for_int_to_string_conv;{{ef4f:cd03fd}} HL=accumulator + 1; B=0; E=0; C=2 (size of int)
        xor     a                 ;{{ef52:af}} Conversion format?
        call    do_number_to_string;{{ef53:cd72ef}} 
        inc     hl                ;{{ef56:23}} 
        pop     bc                ;{{ef57:c1}} 
        pop     de                ;{{ef58:d1}} 
        ret                       ;{{ef59:c9}} 

;;=convert accumulator to string
;Converts accumulator to 'natural' format - ie. unspecified, could be real, integer or exponent 
;depending on the number
convert_accumulator_to_string:    ;{{Addr=$ef5a Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{ef5a:d5}} 
        push    bc                ;{{ef5b:c5}} 
        xor     a                 ;{{ef5c:af}} Conversion format?
        call    convert_number_to_string_by_format;{{ef5d:cd6aef}} 
        pop     bc                ;{{ef60:c1}} 
        pop     de                ;{{ef61:d1}} 
        ld      a,(hl)            ;{{ef62:7e}} 
        cp      $20               ;{{ef63:fe20}} ; ' '
        ret     nz                ;{{ef65:c0}} 

        inc     hl                ;{{ef66:23}} 
        ret                       ;{{ef67:c9}} 

;;==================================
;;conv number to decimal string
;Converts accumulator to decimal integer string
conv_number_to_decimal_string:    ;{{Addr=$ef68 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$40             ;{{ef68:3e40}} Integer

;;=convert number to string by format
;A=Display format
;If bit 7 of A is clear then the format is as follows:
;$00=Flexible (could be real or integer depending on the number)
;$40=Integer
;(Other values are possible but unlikely)

;If bit 7 of A is set then the value is formatted with a format string (i.e. PRINT USING or DEC$)
;using bitwise values as follows
;Bit    Hex
;7      $80 Always set - indicates we have a format 
;            (as opposed to calling the conversion routines without a format)
;6      &40 Exponent ('^^^^' at the end)
;5      $20 Asterisk prefix
;4      $10 If clear then show sign prefix, otherwise sign suffix
;3      $08 If bit 4 set, bit 3 set specifies always show sign prefix, even for positive numbers
;                         bit 3 clear specifies sign prefix only if negative
;           If bit 4 clear, bit 3 clear specifies sign suffix of '-' or space
;                           bit 3 set specifies sign suffix of '-' or '+'
;2      &04 Currency symbol prefix (actual symbol is stored at &ae54)
;1      &02 Contains comma(s)
;(Bit zero is used as a flag when doing conversions)
;
;DE=Address of format template (prob not used)
;B=length of format template (prob not used)
;H=number of chars before the decimal point
;L=number of chars after, and including, the decimal point
convert_number_to_string_by_format:;{{Addr=$ef6a Code Calls/jump count: 3 Data use count: 0}}
        ld      (Chars_before_the_decimal_point_in_format),hl;{{ef6a:2252ae}} Store char counts
        push    af                ;{{ef6d:f5}} 
        call    prepare_accum_and_regs_for_word_to_string;{{ef6e:cdf3fc}} HL=accumulator plus 1, 
        pop     af                ;{{ef71:f1}} 

;;=do number to string
;For an integer value:
;For a real value (i.e. a value which has a fractional part or which is too large for an integer):
;REAL_prepare_for_decimal (in he firmware) is called prior to this.
;I /think/ this unpacks the value into BCD and sets up registers
;
;Either way, by the time we arrive here:
;A=format string
;B bit 7=set for -ve, clear for +ve
;C=Number of bytes in the input buffer. $02=16-bit integer, $01=8-bit integer, Real=??
;E=$00 for integers, possible number of digits for real
;HL=last used byte of source buffer
do_number_to_string:              ;{{Addr=$ef72 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{ef72:c5}} 
        ld      d,a               ;{{ef73:57}} D=format
        push    de                ;{{ef74:d5}} 
        call    do_input_to_ascii ;{{ef75:cd8af1}} Converts to a raw ASCII formatted number
                                  ;Returns: C=number of chars digits in number
                                  ;HL=addr of first digit
        pop     de                ;{{ef78:d1}} D=format, E=number of digits processed(??)
        call    prob_scale_and_add_exponent_if_needed;{{ef79:cd96ef}} 
        call    insert_commas_if_required;{{ef7c:cd1af1}} 
        pop     af                ;{{ef7f:f1}} 
        ld      e,a               ;{{ef80:5f}} 
        ld      a,b               ;{{ef81:78}} 
        or      a                 ;{{ef82:b7}} 
        call    z,write_zero_if_required;{{ef83:cc2cf1}} 
        call    write_currency_prefix_if_required;{{ef86:cd45f1}} 
        call    prob_write_sign_if_needed;{{ef89:cd4ff1}} 
        call    prob_write_leading_asterisk_or_space;{{ef8c:cd6ff1}} 
        ld      a,d               ;{{ef8f:7a}} 
        rra                       ;{{ef90:1f}} 
        ret     nc                ;{{ef91:d0}} 

        dec     hl                ;{{ef92:2b}} 
        ld      (hl),$25          ;{{ef93:3625}} '%' Conversion failed(?) eg too many chars
        ret                       ;{{ef95:c9}} 

;;=prob scale and add exponent if needed
prob_scale_and_add_exponent_if_needed:;{{Addr=$ef96 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{ef96:7a}} 
        add     a,a               ;{{ef97:87}} 
        jr      nc,unformatted_scale_and_exp_if_needed;{{ef98:302d}}  (+$2d) No format string
        jp      m,do_scale_and_add_exponent;{{ef9a:faedef}} Already showing exponent

;Check length of the number, display in exponent format if too long
        ld      a,e               ;{{ef9d:7b}} C+E=number of digits
        add     a,c               ;{{ef9e:81}} 
        sub     $15               ;{{ef9f:d615}} 
        jp      m,scale_no_exp_needed;{{efa1:fa56f0}} Not too long
        ld      a,d               ;{{efa4:7a}} 
        or      $41               ;{{efa5:f641}}  Add show exponent flag to format
        ld      d,a               ;{{efa7:57}} 
        jr      do_scale_and_add_exponent;{{efa8:1843}}  (+$43)

;;=unformatted scale loop
unformatted_scale_loop:           ;{{Addr=$efaa Code Calls/jump count: 2 Data use count: 0}}
        ld      b,c               ;{{efaa:41}} 
        ld      a,c               ;{{efab:79}} 
        or      a                 ;{{efac:b7}} 
        jr      z,_unformatted_scale_loop_16;{{efad:2815}}  (+$15)
        add     a,e               ;{{efaf:83}} 
        dec     a                 ;{{efb0:3d}} 
        ld      e,a               ;{{efb1:5f}} 
        call    prob_remove_trailing_zeros;{{efb2:cddef0}} 
        ld      b,$01             ;{{efb5:0601}} 
        ld      a,c               ;{{efb7:79}} 
        cp      $07               ;{{efb8:fe07}} 
        jr      c,_unformatted_scale_loop_14;{{efba:3804}}  (+$04)
        bit     6,d               ;{{efbc:cb72}} Show exponent?
        jr      nz,_unformatted_scale_and_exp_if_needed_19;{{efbe:2026}}  (+$26)
_unformatted_scale_loop_14:       ;{{Addr=$efc0 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{efc0:b8}} 
        call    nz,poss_insert_decimal_point;{{efc1:c474f0}} 
_unformatted_scale_loop_16:       ;{{Addr=$efc4 Code Calls/jump count: 1 Data use count: 0}}
        jp      _do_scale_and_add_exponent_45;{{efc4:c332f0}} 

;;=unformatted scale and exp if needed
unformatted_scale_and_exp_if_needed:;{{Addr=$efc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{efc7:7b}} 
        or      a                 ;{{efc8:b7}} 
        jp      m,_unformatted_scale_and_exp_if_needed_6;{{efc9:fad0ef}} 
        jr      nz,unformatted_scale_loop;{{efcc:20dc}}  (-$24)
_unformatted_scale_and_exp_if_needed_4:;{{Addr=$efce Code Calls/jump count: 1 Data use count: 0}}
        ld      b,c               ;{{efce:41}} 
        ret                       ;{{efcf:c9}} 

_unformatted_scale_and_exp_if_needed_6:;{{Addr=$efd0 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,e               ;{{efd0:43}} 
        call    prob_remove_trailing_zeros;{{efd1:cddef0}} 
        ld      a,b               ;{{efd4:78}} 
        or      a                 ;{{efd5:b7}} 
        jr      z,_unformatted_scale_and_exp_if_needed_4;{{efd6:28f6}}  (-$0a)
        sub     e                 ;{{efd8:93}} 
        ld      e,b               ;{{efd9:58}} 
        ld      b,a               ;{{efda:47}} 
        add     a,c               ;{{efdb:81}} 
        add     a,e               ;{{efdc:83}} 
        jp      m,unformatted_scale_loop;{{efdd:faaaef}} 
        call    prob_write_zeros_to_buffer;{{efe0:cd87f0}} 
        jp      poss_insert_decimal_point;{{efe3:c374f0}} 

_unformatted_scale_and_exp_if_needed_19:;{{Addr=$efe6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$06             ;{{efe6:3e06}} 
        ld      (Chars_before_the_decimal_point_in_format),a;{{efe8:3252ae}} 
        jr      _do_scale_and_add_exponent_28;{{efeb:182e}}  (+$2e)

;;=do scale and add exponent
do_scale_and_add_exponent:        ;{{Addr=$efed Code Calls/jump count: 2 Data use count: 0}}
        call    prob_test_if_prefix_char_needed;{{efed:cdfbf0}} 
        jr      nc,_do_scale_and_add_exponent_4;{{eff0:3003}}  (+$03)
        set     0,d               ;{{eff2:cbc2}} 
        xor     a                 ;{{eff4:af}} 
_do_scale_and_add_exponent_4:     ;{{Addr=$eff5 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{eff5:47}} 
        call    z,get_chars_before_dp;{{eff6:cc13f1}} 
        jr      nz,_do_scale_and_add_exponent_15;{{eff9:200e}}  (+$0e)
        set     0,d               ;{{effb:cbc2}} 
        inc     b                 ;{{effd:04}} 
        ld      a,(Chars_before_the_decimal_point_in_format);{{effe:3a52ae}} 
        or      a                 ;{{f001:b7}} 
        jr      z,_do_scale_and_add_exponent_15;{{f002:2805}}  (+$05)
        dec     b                 ;{{f004:05}} 
        inc     a                 ;{{f005:3c}} 
        ld      (Chars_before_the_decimal_point_in_format),a;{{f006:3252ae}} 
_do_scale_and_add_exponent_15:    ;{{Addr=$f009 Code Calls/jump count: 2 Data use count: 0}}
        bit     1,d               ;{{f009:cb4a}} 
        jr      z,_do_scale_and_add_exponent_22;{{f00b:2807}}  (+$07)
        ld      a,b               ;{{f00d:78}} 
        inc     b                 ;{{f00e:04}} 
_do_scale_and_add_exponent_19:    ;{{Addr=$f00f Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{f00f:05}} 
        sub     $04               ;{{f010:d604}} 
        jr      nc,_do_scale_and_add_exponent_19;{{f012:30fb}}  (-$05)
_do_scale_and_add_exponent_22:    ;{{Addr=$f014 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{f014:79}} 
        or      a                 ;{{f015:b7}} 
        jr      z,_do_scale_and_add_exponent_29;{{f016:2804}}  (+$04)
        add     a,e               ;{{f018:83}} 
        sub     b                 ;{{f019:90}} 
        ld      e,a               ;{{f01a:5f}} 
_do_scale_and_add_exponent_28:    ;{{Addr=$f01b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{f01b:78}} 
_do_scale_and_add_exponent_29:    ;{{Addr=$f01c Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{f01c:f5}} 
        ld      b,a               ;{{f01d:47}} 
        call    _scale_no_exp_needed_1;{{f01e:cd59f0}} 
        pop     af                ;{{f021:f1}} 
        cp      b                 ;{{f022:b8}} 
        jr      z,_do_scale_and_add_exponent_45;{{f023:280d}}  (+$0d)
        inc     e                 ;{{f025:1c}} 
        inc     hl                ;{{f026:23}} 
        dec     b                 ;{{f027:05}} 
        push    hl                ;{{f028:e5}} 
        ld      a,(hl)            ;{{f029:7e}} 
        cp      $2e               ;{{f02a:fe2e}} '.'
        jr      nz,_do_scale_and_add_exponent_43;{{f02c:2001}}  (+$01)
        inc     hl                ;{{f02e:23}} 
_do_scale_and_add_exponent_43:    ;{{Addr=$f02f Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$31          ;{{f02f:3631}} '1'
        pop     hl                ;{{f031:e1}} 
_do_scale_and_add_exponent_45:    ;{{Addr=$f032 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$04             ;{{f032:3e04}} 
        call    prob_copy_buffer_and_right_pad_with_zeros;{{f034:cdc2f0}} 
        push    hl                ;{{f037:e5}} 

;write exponent letter and sign
        ld      hl,$2b45          ;{{f038:21452b}} '+','E'
        ld      a,e               ;{{f03b:7b}} A=exponent
        or      a                 ;{{f03c:b7}} 
        jp      p,_do_scale_and_add_exponent_55;{{f03d:f244f0}} 
        xor     a                 ;{{f040:af}} Convert exponent
        sub     e                 ;{{f041:93}} 
        ld      h,$2d             ;{{f042:262d}}  '-'
_do_scale_and_add_exponent_55:    ;{{Addr=$f044 Code Calls/jump count: 1 Data use count: 0}}
        ld      (exponent_prefix),hl;{{f044:224cae}} Write 'E+' or 'E-' before exponent

;Convert exponent into chars in HL
        ld      l,$2f             ;{{f047:2e2f}} '/' - one before '0'
_do_scale_and_add_exponent_57:    ;{{Addr=$f049 Code Calls/jump count: 1 Data use count: 0}}
        inc     l                 ;{{f049:2c}} 
        sub     $0a               ;{{f04a:d60a}} 
        jr      nc,_do_scale_and_add_exponent_57;{{f04c:30fb}}  (-$05)
        add     a,$3a             ;{{f04e:c63a}} ":" - char after '9'
        ld      h,a               ;{{f050:67}} 
        ld      (exponent_value),hl;{{f051:224eae}} Write exponent digits to buffer
        pop     hl                ;{{f054:e1}} 
        ret                       ;{{f055:c9}} 

;;=scale no exp needed
scale_no_exp_needed:              ;{{Addr=$f056 Code Calls/jump count: 1 Data use count: 0}}
        call    prob_write_zeros_to_buffer;{{f056:cd87f0}} 
_scale_no_exp_needed_1:           ;{{Addr=$f059 Code Calls/jump count: 1 Data use count: 0}}
        call    get_chars_before_dp;{{f059:cd13f1}} 
        add     a,b               ;{{f05c:80}} 
        cp      c                 ;{{f05d:b9}} 
        jr      nc,_scale_no_exp_needed_7;{{f05e:3005}}  (+$05)
        call    prob_round_last_digit;{{f060:cd9af0}} 
        jr      _scale_no_exp_needed_12;{{f063:180a}}  (+$0a)

_scale_no_exp_needed_7:           ;{{Addr=$f065 Code Calls/jump count: 1 Data use count: 0}}
        cp      $15               ;{{f065:fe15}} 
        jr      c,_scale_no_exp_needed_10;{{f067:3802}}  (+$02)
        ld      a,$14             ;{{f069:3e14}} 
_scale_no_exp_needed_10:          ;{{Addr=$f06b Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{f06b:91}} 
        call    nz,prob_copy_buffer_and_right_pad_with_zeros;{{f06c:c4c2f0}} 
_scale_no_exp_needed_12:          ;{{Addr=$f06f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(Chars_before_the_decimal_point_in_format);{{f06f:3a52ae}} 
        or      a                 ;{{f072:b7}} 
        ret     z                 ;{{f073:c8}} 

;;=poss insert decimal point
poss_insert_decimal_point:        ;{{Addr=$f074 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,$2e             ;{{f074:0e2e}} 
        ld      a,b               ;{{f076:78}} 
;;=poss insert char into buffer
poss_insert_char_into_buffer:     ;{{Addr=$f077 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f077:c5}} 
        ld      b,a               ;{{f078:47}} 
        inc     b                 ;{{f079:04}} 
        add     a,l               ;{{f07a:85}} 
        ld      l,a               ;{{f07b:6f}} 
        adc     a,h               ;{{f07c:8c}} 
        sub     l                 ;{{f07d:95}} 
        ld      h,a               ;{{f07e:67}} 
_poss_insert_char_into_buffer_8:  ;{{Addr=$f07f Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f07f:2b}} 
        ld      a,c               ;{{f080:79}} 
        ld      c,(hl)            ;{{f081:4e}} 
        ld      (hl),a            ;{{f082:77}} 
        djnz    _poss_insert_char_into_buffer_8;{{f083:10fa}}  (-$06)
        pop     bc                ;{{f085:c1}} 
        ret                       ;{{f086:c9}} 

;;=prob write zeros to buffer
prob_write_zeros_to_buffer:       ;{{Addr=$f087 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,e               ;{{f087:7b}} 
        add     a,c               ;{{f088:81}} 
        ld      b,a               ;{{f089:47}} 
        ret     p                 ;{{f08a:f0}} 

        cpl                       ;{{f08b:2f}} 
        inc     a                 ;{{f08c:3c}} 
        ld      b,$14             ;{{f08d:0614}} 
        cp      b                 ;{{f08f:b8}} 
        jr      nc,_prob_write_zeros_to_buffer_10;{{f090:3001}}  (+$01)
        ld      b,a               ;{{f092:47}} 
_prob_write_zeros_to_buffer_10:   ;{{Addr=$f093 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f093:2b}} 
        ld      (hl),$30          ;{{f094:3630}} '0'
        inc     c                 ;{{f096:0c}} 
        djnz    _prob_write_zeros_to_buffer_10;{{f097:10fa}}  (-$06)
        ret                       ;{{f099:c9}} 

;;=prob round last digit
prob_round_last_digit:            ;{{Addr=$f09a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{f09a:4f}} 
        add     a,l               ;{{f09b:85}} 
        ld      l,a               ;{{f09c:6f}} 
        adc     a,h               ;{{f09d:8c}} 
        sub     l                 ;{{f09e:95}} 
        ld      h,a               ;{{f09f:67}} 
        push    hl                ;{{f0a0:e5}} 
        push    bc                ;{{f0a1:c5}} 
        ld      a,(hl)            ;{{f0a2:7e}} 
        cp      $35               ;{{f0a3:fe35}} '5'
        call    nc,prob_right_pad_with_zeros;{{f0a5:d4b4f0}} 
        pop     bc                ;{{f0a8:c1}} 
        jr      c,_prob_round_last_digit_17;{{f0a9:3805}}  (+$05)
        dec     hl                ;{{f0ab:2b}} 
        ld      (hl),$31          ;{{f0ac:3631}} '1'
        inc     b                 ;{{f0ae:04}} 
        inc     c                 ;{{f0af:0c}} 
_prob_round_last_digit_17:        ;{{Addr=$f0b0 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f0b0:e1}} 
        dec     hl                ;{{f0b1:2b}} 
        jr      _prob_remove_trailing_zeros_9;{{f0b2:1838}}  (+$38)

;;=prob right pad with zeros
prob_right_pad_with_zeros:        ;{{Addr=$f0b4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f0b4:79}} 
        or      a                 ;{{f0b5:b7}} 
        ret     z                 ;{{f0b6:c8}} 

        dec     hl                ;{{f0b7:2b}} 
        dec     c                 ;{{f0b8:0d}} 
        ld      a,(hl)            ;{{f0b9:7e}} 
        inc     (hl)              ;{{f0ba:34}} 
        cp      $39               ;{{f0bb:fe39}} '9'
        ret     c                 ;{{f0bd:d8}} 

        ld      (hl),$30          ;{{f0be:3630}} '0'
        jr      prob_right_pad_with_zeros;{{f0c0:18f2}}  (-$0e)

;;=prob copy buffer and right pad with zeros
prob_copy_buffer_and_right_pad_with_zeros:;{{Addr=$f0c2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f0c2:d5}} 
        push    bc                ;{{f0c3:c5}} 
        ex      de,hl             ;{{f0c4:eb}} 
        ld      b,a               ;{{f0c5:47}} 
        ld      a,e               ;{{f0c6:7b}} 
        sub     b                 ;{{f0c7:90}} 
        ld      l,a               ;{{f0c8:6f}} 
        sbc     a,a               ;{{f0c9:9f}} 
        add     a,d               ;{{f0ca:82}} 
        ld      h,a               ;{{f0cb:67}} 
        push    hl                ;{{f0cc:e5}} 
;copy until null loop
_prob_copy_buffer_and_right_pad_with_zeros_11:;{{Addr=$f0cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f0cd:1a}} 
        inc     de                ;{{f0ce:13}} 
        ld      (hl),a            ;{{f0cf:77}} 
        inc     hl                ;{{f0d0:23}} 
        or      a                 ;{{f0d1:b7}} 
        jr      nz,_prob_copy_buffer_and_right_pad_with_zeros_11;{{f0d2:20f9}}  (-$07)
        dec     hl                ;{{f0d4:2b}} 
;write zeros loop
_prob_copy_buffer_and_right_pad_with_zeros_18:;{{Addr=$f0d5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$30          ;{{f0d5:3630}} '0'
        inc     hl                ;{{f0d7:23}} 
        djnz    _prob_copy_buffer_and_right_pad_with_zeros_18;{{f0d8:10fb}}  (-$05)
        pop     hl                ;{{f0da:e1}} 
        pop     bc                ;{{f0db:c1}} 
        pop     de                ;{{f0dc:d1}} 
        ret                       ;{{f0dd:c9}} 

;;=prob remove trailing zeros
prob_remove_trailing_zeros:       ;{{Addr=$f0de Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,end_of_number_in_format_buffer + 1;{{f0de:2150ae}} ##LABEL##
;Loop over zeros
_prob_remove_trailing_zeros_1:    ;{{Addr=$f0e1 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f0e1:2b}} 
        ld      a,(hl)            ;{{f0e2:7e}} 
        cp      $30               ;{{f0e3:fe30}} 
        jr      nz,_prob_remove_trailing_zeros_9;{{f0e5:2005}}  (+$05)
        dec     c                 ;{{f0e7:0d}} 
        inc     b                 ;{{f0e8:04}} 
        jr      nz,_prob_remove_trailing_zeros_1;{{f0e9:20f6}}  (-$0a)

        dec     hl                ;{{f0eb:2b}} 
_prob_remove_trailing_zeros_9:    ;{{Addr=$f0ec Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f0ec:d5}} 
        push    bc                ;{{f0ed:c5}} 
        ld      de,end_of_number_in_format_buffer;{{f0ee:114fae}} ##LABEL##
        ld      b,$00             ;{{f0f1:0600}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f0f3:cdf5ff}}  copy bytes LDDR (BC = count)
        ex      de,hl             ;{{f0f6:eb}} 
        inc     hl                ;{{f0f7:23}} 
        pop     bc                ;{{f0f8:c1}} 
        pop     de                ;{{f0f9:d1}} 
        ret                       ;{{f0fa:c9}} 

;;=prob test if prefix char needed
prob_test_if_prefix_char_needed:  ;{{Addr=$f0fb Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f0fb:c5}} 
        ld      a,d               ;{{f0fc:7a}} 
        and     $04               ;{{f0fd:e604}} Currency prefix
        rra                       ;{{f0ff:1f}} 
        rra                       ;{{f100:1f}} 
        ld      b,a               ;{{f101:47}} 
        bit     4,d               ;{{f102:cb62}} Sign prefix
        jr      nz,_prob_test_if_prefix_char_needed_13;{{f104:2007}}  (+$07)
        ld      a,d               ;{{f106:7a}} 
        add     a,a               ;{{f107:87}} 
        or      e                 ;{{f108:b3}} 
        jp      p,_prob_test_if_prefix_char_needed_13;{{f109:f20df1}} 
        inc     b                 ;{{f10c:04}} 
_prob_test_if_prefix_char_needed_13:;{{Addr=$f10d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(Chars_after_decimal_point_in_format_stri);{{f10d:3a53ae}} 
        sub     b                 ;{{f110:90}} 
        pop     bc                ;{{f111:c1}} 
        ret                       ;{{f112:c9}} 

;;=get chars before dp
get_chars_before_dp:              ;{{Addr=$f113 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(Chars_before_the_decimal_point_in_format);{{f113:3a52ae}} 
        or      a                 ;{{f116:b7}} 
        ret     z                 ;{{f117:c8}} 

        dec     a                 ;{{f118:3d}} 
        ret                       ;{{f119:c9}} 

;;=insert commas if required
;D=format flags
;B=position of decimal point
insert_commas_if_required:        ;{{Addr=$f11a Code Calls/jump count: 1 Data use count: 0}}
        bit     1,d               ;{{f11a:cb4a}} Bit 1 of flag = insert commas
        ret     z                 ;{{f11c:c8}} 

        ld      a,b               ;{{f11d:78}} Position of decimal point?
_insert_commas_if_required_3:     ;{{Addr=$f11e Code Calls/jump count: 1 Data use count: 0}}
        sub     $03               ;{{f11e:d603}} Three chars prior
        ret     c                 ;{{f120:d8}} Return when done
        ret     z                 ;{{f121:c8}} 

        push    af                ;{{f122:f5}} Do the insertion
        ld      c,$2c             ;{{f123:0e2c}}  ','
        call    poss_insert_char_into_buffer;{{f125:cd77f0}} 
        inc     b                 ;{{f128:04}} 
        pop     af                ;{{f129:f1}} 
        jr      _insert_commas_if_required_3;{{f12a:18f2}}  (-$0e) Loop

;;=write zero if required
write_zero_if_required:           ;{{Addr=$f12c Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{f12c:e5}} 
;Loop over chars < '0'
_write_zero_if_required_1:        ;{{Addr=$f12d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f12d:7e}} 
        inc     hl                ;{{f12e:23}} 
        dec     a                 ;{{f12f:3d}} 
        cp      $30               ;{{f130:fe30}} '0'
        jr      c,_write_zero_if_required_1;{{f132:38f9}}  (-$07)

        inc     a                 ;{{f134:3c}} 
        jr      nz,_write_zero_if_required_9;{{f135:2001}}  (+$01)
        ld      e,a               ;{{f137:5f}} 
_write_zero_if_required_9:        ;{{Addr=$f138 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f138:e1}} 
        ld      a,d               ;{{f139:7a}} 
        xor     $80               ;{{f13a:ee80}} 
        call    p,prob_test_if_prefix_char_needed;{{f13c:f4fbf0}} Formatted number
        ret     c                 ;{{f13f:d8}} 

        ret     z                 ;{{f140:c8}} 

        ld      a,$30             ;{{f141:3e30}}  '0'
        jr      write_prefix_char ;{{f143:1806}} 

;;=write currency prefix if required
write_currency_prefix_if_required:;{{Addr=$f145 Code Calls/jump count: 1 Data use count: 0}}
        bit     2,d               ;{{f145:cb52}} 
        ret     z                 ;{{f147:c8}} 
        ld      a,(Print_format_currency_symbol___or_);{{f148:3a54ae}} 

;;=write prefix char
write_prefix_char:                ;{{Addr=$f14b Code Calls/jump count: 2 Data use count: 0}}
        inc     b                 ;{{f14b:04}} 
        dec     hl                ;{{f14c:2b}} 
        ld      (hl),a            ;{{f14d:77}} 
        ret                       ;{{f14e:c9}} 

;;=prob write sign if needed
;Writes leading or trailing sign (or space) as necessary
;Bit 7 of E is set if number is negative
prob_write_sign_if_needed:        ;{{Addr=$f14f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{f14f:7b}} 
        add     a,a               ;{{f150:87}} 
        ld      a,$2d             ;{{f151:3e2d}}  '-'
        jr      c,_prob_write_sign_if_needed_12;{{f153:380e}}  Negative number
        ld      a,d               ;{{f155:7a}} 
        and     $98               ;{{f156:e698}} Bits 4 and 3 = sign formatting
        xor     $80               ;{{f158:ee80}} Formatted number?
        ret     z                 ;{{f15a:c8}} Exit if not    

        and     $08               ;{{f15b:e608}} 
        ld      a,$2b             ;{{f15d:3e2b}}  '+'
        jr      nz,_prob_write_sign_if_needed_12;{{f15f:2002}}  Positive prefix or any suffix
        ld      a,$20             ;{{f161:3e20}}  ' ' else space prefix
_prob_write_sign_if_needed_12:    ;{{Addr=$f163 Code Calls/jump count: 2 Data use count: 0}}
        bit     4,d               ;{{f163:cb62}} Suffix if set
        jr      z,write_prefix_char;{{f165:28e4}}  (-$1c) if prefix
        ld      (trailing_sign_in_format_buffer),a;{{f167:3250ae}} Suffix address
        xor     a                 ;{{f16a:af}} Terminate buffer
        ld      (end_of_format_buffer),a;{{f16b:3251ae}} 
        ret                       ;{{f16e:c9}} 

;;=prob write leading asterisk or space
prob_write_leading_asterisk_or_space:;{{Addr=$f16f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{f16f:7a}} 
        or      a                 ;{{f170:b7}} 
        ret     p                 ;{{f171:f0}} 

        ld      a,(Chars_after_decimal_point_in_format_stri);{{f172:3a53ae}} 
        sub     b                 ;{{f175:90}} 
        ret     z                 ;{{f176:c8}} 

        jr      c,_prob_write_leading_asterisk_or_space_16;{{f177:380e}}  (+$0e)
        ld      b,a               ;{{f179:47}} 
        bit     5,d               ;{{f17a:cb6a}} 
        ld      a,$2a             ;{{f17c:3e2a}} '*'
        jr      nz,_prob_write_leading_asterisk_or_space_12;{{f17e:2002}}  (+$02)
        ld      a,$20             ;{{f180:3e20}} ' '
_prob_write_leading_asterisk_or_space_12:;{{Addr=$f182 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f182:2b}} 
        ld      (hl),a            ;{{f183:77}} 
        djnz    _prob_write_leading_asterisk_or_space_12;{{f184:10fc}}  (-$04)
        ret                       ;{{f186:c9}} 

_prob_write_leading_asterisk_or_space_16:;{{Addr=$f187 Code Calls/jump count: 1 Data use count: 0}}
        set     0,d               ;{{f187:cbc2}} 
        ret                       ;{{f189:c9}} 

;;=do input to ascii
;Converts the input number to unformatted ASCII
;HL=last byte of input buffer
;C=number of bytes in buffer: $01 for one byte integer, $02 for 2 byte integer, various for real
;
;Returns:
;HL=addr of first digit of number
;C=Number of digits
do_input_to_ascii:                ;{{Addr=$f18a Code Calls/jump count: 1 Data use count: 0}}
        ld      de,preconversion_buffer;{{f18a:112dae}} 
        xor     a                 ;{{f18d:af}} 
        ld      b,a               ;{{f18e:47}} Count=0

;Loop backwards over buffer to find first non-null value (if any).
;Ie. skip any zero high bytes
;Buffer is C bytes long
_do_input_to_ascii_3:             ;{{Addr=$f18f Code Calls/jump count: 1 Data use count: 0}}
        or      (hl)              ;{{f18f:b6}} 
        dec     hl                ;{{f190:2b}} 
        jr      nz,binary_to_ASCII;{{f191:2005}}  (+$05) Non-null value found
        dec     c                 ;{{f193:0d}} 
        jr      nz,_do_input_to_ascii_3;{{f194:20f9}}  (-$07)

        jr      BCD_to_ASCII      ;{{f196:1828}}  (+$28) End of buffer. Number is zero

;;=binary to ASCII
;Converts the binary number to BCD then falls through to the BCD to ASCII routine
;HL=addr of second most significant byte (penultimate) of number
;C=number of bytes to convert
;B=0
;A=most significant byte
binary_to_ASCII:                  ;{{Addr=$f198 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{f198:37}} 
_binary_to_ascii_1:               ;{{Addr=$f199 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{f199:8f}} 
        jr      nc,_binary_to_ascii_1;{{f19a:30fd}}  (-$03)
        ex      de,hl             ;{{f19c:eb}} 
        push    de                ;{{f19d:d5}} 
        ld      d,a               ;{{f19e:57}} 
        jr      _binary_to_ascii_22;{{f19f:1811}}  (+$11)

;Outer loop
_binary_to_ascii_7:               ;{{Addr=$f1a1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f1a1:1a}} 
        dec     de                ;{{f1a2:1b}} 
        push    de                ;{{f1a3:d5}} 
        scf                       ;{{f1a4:37}} 
        adc     a,a               ;{{f1a5:8f}} 

;Middle loop
_binary_to_ascii_12:              ;{{Addr=$f1a6 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{f1a6:57}} 
        ld      e,b               ;{{f1a7:58}} 

;Inner loop
_binary_to_ascii_14:              ;{{Addr=$f1a8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f1a8:7e}} 
        adc     a,a               ;{{f1a9:8f}} 
        daa                       ;{{f1aa:27}} 
        ld      (hl),a            ;{{f1ab:77}} 
        inc     hl                ;{{f1ac:23}} 
        dec     e                 ;{{f1ad:1d}} 
        jr      nz,_binary_to_ascii_14;{{f1ae:20f8}}  (-$08) 
;End of inner loop

        jr      nc,_binary_to_ascii_24;{{f1b0:3003}}  (+$03)

;Entry point
_binary_to_ascii_22:              ;{{Addr=$f1b2 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{f1b2:04}} 
        ld      (hl),$01          ;{{f1b3:3601}} 
_binary_to_ascii_24:              ;{{Addr=$f1b5 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,preconversion_buffer;{{f1b5:212dae}} 
        ld      a,d               ;{{f1b8:7a}} 
        add     a,a               ;{{f1b9:87}} 
        jr      nz,_binary_to_ascii_12;{{f1ba:20ea}}  (-$16) 
;End of middle loop

        pop     de                ;{{f1bc:d1}} 
        dec     c                 ;{{f1bd:0d}} 
        jr      nz,_binary_to_ascii_7;{{f1be:20e1}}  (-$1f) 
;End of outer loop


;;=BCD to ASCII
;B=number of bytes to convert, $00 if number is zero
BCD_to_ASCII:                     ;{{Addr=$f1c0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{f1c0:eb}} 
        ld      hl,end_of_number_in_format_buffer + 1;{{f1c1:2150ae}} 
        ld      (hl),$00          ;{{f1c4:3600}} Zero terminate the buffer
        ld      a,b               ;{{f1c6:78}} 
        add     a,a               ;{{f1c7:87}} 
        ld      c,a               ;{{f1c8:4f}} C=number of digits returned, zero if number is zero
        ret     z                 ;{{f1c9:c8}} 

        ld      a,$30             ;{{f1ca:3e30}}  '0' - Puts 3 into the high nybble of A, 
                                  ;so digits get converted to ASCII numbers
        ex      de,hl             ;{{f1cc:eb}} 

;Loop
;RRD rotates: low nybble of A to high nybble of (HL) to low nybble of (HL) to low nybbe of A
;This code splits the number at (HL) into separate nybbles, writing one to each byte starting at (DE) - 1
;HL increments after each byte. DE decrements for each nybble
;So, we're unpacking a hex number (or a BCD one)
_bcd_to_ascii_9:                  ;{{Addr=$f1cd Code Calls/jump count: 1 Data use count: 0}}
        rrd                       ;{{f1cd:ed67}} Put low nybble of (HL) into A
        dec     de                ;{{f1cf:1b}} 
        ld      (de),a            ;{{f1d0:12}} And store into (DE)
        rrd                       ;{{f1d1:ed67}} Put (what was) high nybble of (HL) into A
        dec     de                ;{{f1d3:1b}} 
        ld      (de),a            ;{{f1d4:12}} And store in (DE)
        inc     hl                ;{{f1d5:23}} 
        djnz    _bcd_to_ascii_9   ;{{f1d6:10f5}}  (-$0b)
;End of loop

        ex      de,hl             ;{{f1d8:eb}} 
        cp      $30               ;{{f1d9:fe30}} '0'
        ret     nz                ;{{f1db:c0}} 

        dec     c                 ;{{f1dc:0d}} Step back if leading zero (if there is one)
                                  ;Since we already counted how many bytes to unpack there is a 
                                  ;maximum of one leading zero
        inc     hl                ;{{f1dd:23}} 
        ret                       ;{{f1de:c9}} 

;;===============================
;;convert based number to string
;HL=number to convert
;C=base (01=binary, 0f=hex)
;B=number of bits per output digit (01 for binary, 04 for hex)
;A: $01 to $80=minimum number of digits to output. I.e. pad with leading zeros. 
;   $81 to $ff or $00=no padding.

;Returns: ASCIIZ string at HL
convert_based_number_to_string:   ;{{Addr=$f1df Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f1df:d5}} 
        ex      de,hl             ;{{f1e0:eb}} 
        ld      hl,end_of_conversion_buffer;{{f1e1:213eae}} 
        ld      (hl),$00          ;{{f1e4:3600}} Returns a zero terminated string
        dec     a                 ;{{f1e6:3d}} 

;;=convert digit loop
convert_digit_loop:               ;{{Addr=$f1e7 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{f1e7:f5}} 
        ld      a,e               ;{{f1e8:7b}} A=byte
        and     c                 ;{{f1e9:a1}} C=mask for bits we're interested in

;These four lines convert nybble to hex ASCII. 
;See 'Analysis of the binary to ASCII hex conversion' below
        or      $f0               ;{{f1ea:f6f0}} 
        daa                       ;{{f1ec:27}} 
        add     a,$a0             ;{{f1ed:c6a0}} 
        adc     a,$40             ;{{f1ef:ce40}} ; 'A'-1

        dec     hl                ;{{f1f1:2b}} 
        ld      (hl),a            ;{{f1f2:77}} Write to buffer
        ld      a,b               ;{{f1f3:78}} Cache bits per digit

;;=convert shift loop
convert_shift_loop:               ;{{Addr=$f1f4 Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{f1f4:cb3a}} DE=number to convert
        rr      e                 ;{{f1f6:cb1b}} Shift for next digit
        djnz    convert_shift_loop;{{f1f8:10fa}}  (-$06) Next digit

        ld      b,a               ;{{f1fa:47}} Restore bits per digit
        pop     af                ;{{f1fb:f1}} A=minimum width
        dec     a                 ;{{f1fc:3d}} 
        jp      p,convert_digit_loop;{{f1fd:f2e7f1}} If A still > 0 then loop

        ld      a,d               ;{{f200:7a}} If A < 0 then check if number is now zero
        or      e                 ;{{f201:b3}} 
        ld      a,$00             ;{{f202:3e00}} Force no padding
        jr      nz,convert_digit_loop;{{f204:20e1}}  (-$1f) Not zero? => next digit

        pop     de                ;{{f206:d1}} 
        ret                       ;{{f207:c9}} 

;Analysis of the binary to ASCII hex conversion
;----------------------------------------------
;Lower nybble:
;To convert from binary to ASCII we only need to add 7 if value is more than 9:
;or $f0     ;Remains the same
;daa        ;Adds 6 if more than 9
;add a,$a0  ;If DAA added 6 then this will set carry (see high nybble section)
;adc a,$40  ;Adds one to lower nybble if carry set

;High nybble:
;Needs to be $3 (%0011) for number or $4 (%0100) for letter
;or $f0     ;Initialises to $f
;daa        ;If low nybble 0..9, adds 6. If low nybble A to F effectively adds 7.
;           ;Thus high nybble becomes          $5 (%0101) or          $6 ($0110)
;add $a0    ;(%1010) Becomes          No carry,$f ($1111) or 16=Carry,$0 ($0000)
;adc $40    ;(%0110) Becomes                   $3 (%0011) or          $4 ($0110)





