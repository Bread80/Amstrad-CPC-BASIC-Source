;;<< NUMBERS TO STRINGS
;;=======================================================================
;;convert number a
convert_number_a:                 ;{{Addr=$eecf Code Calls/jump count: 4 Data use count: 0}}
        push    bc                ;{{eecf:c5}} 
        push    hl                ;{{eed0:e5}} 
        call    convert_number_in_base_defined;{{eed1:cd00ef}} 
        ex      de,hl             ;{{eed4:eb}} 
        call    store_HL_in_accumulator_as_INT;{{eed5:cd35ff}} 
        ex      de,hl             ;{{eed8:eb}} 
        pop     bc                ;{{eed9:c1}} 
        jr      nc,_convert_number_a_12;{{eeda:3006}}  (+$06)
        ld      a,d               ;{{eedc:7a}} 
        or      e                 ;{{eedd:b3}} 
        add     a,$ff             ;{{eede:c6ff}} 
        jr      c,_convert_number_a_15;{{eee0:3803}}  (+$03)
_convert_number_a_12:             ;{{Addr=$eee2 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,b               ;{{eee2:50}} 
        ld      e,c               ;{{eee3:59}} 
        ex      de,hl             ;{{eee4:eb}} 
_convert_number_a_15:             ;{{Addr=$eee5 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{eee5:c1}} 
        ret                       ;{{eee6:c9}} 


;;=======================================================================
;; convert number b
convert_number_b:                 ;{{Addr=$eee7 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eee7:23}} 
        call    skip_space_tab_or_line_feed;{{eee8:cd4dde}}  skip space, lf or tab
        call    convert_character_to_upper_case;{{eeeb:cdabff}} ; convert character to upper case

        ld      b,$02             ;{{eeee:0602}} ; base 2
        cp      $58               ;{{eef0:fe58}} ; X
        jr      z,_convert_number_b_9;{{eef2:2806}} 

        ld      b,$10             ;{{eef4:0610}} ; base 16
        cp      $48               ;{{eef6:fe48}} ; H
        jr      nz,_convert_number_b_11;{{eef8:2004}} 

_convert_number_b_9:              ;{{Addr=$eefa Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eefa:23}} 
        call    skip_space_tab_or_line_feed;{{eefb:cd4dde}}  skip space, lf or tab
_convert_number_b_11:             ;{{Addr=$eefe Code Calls/jump count: 1 Data use count: 0}}
        jr      _convert_number_in_base_defined_1;{{eefe:1802}}  (+$02)

;;=======================================================================
;; convert number in base defined
convert_number_in_base_defined:   ;{{Addr=$ef00 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$0a             ;{{ef00:060a}} ; base 10

;; A = base: 2 for binary, 16 for hexadecimal, 10 for decimal

_convert_number_in_base_defined_1:;{{Addr=$ef02 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef02:eb}} 
        call    _convert_number_in_base_defined_27;{{ef03:cd2cef}} 
        ld      h,$00             ;{{ef06:2600}} 
        ld      l,a               ;{{ef08:6f}} 
        jr      nc,_convert_number_in_base_defined_24;{{ef09:301e}}  (+$1e)
        ld      c,$00             ;{{ef0b:0e00}} 
_convert_number_in_base_defined_7:;{{Addr=$ef0d Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_in_base_defined_27;{{ef0d:cd2cef}} 
        jr      nc,_convert_number_in_base_defined_22;{{ef10:3014}}  (+$14)
        push    de                ;{{ef12:d5}} 
        ld      d,$00             ;{{ef13:1600}} 
        ld      e,a               ;{{ef15:5f}} 
        push    de                ;{{ef16:d5}} 
        ld      e,b               ;{{ef17:58}} 
        call    do_16x16_multiply_with_overflow;{{ef18:cd72dd}} 
        pop     de                ;{{ef1b:d1}} 
        jr      c,_convert_number_in_base_defined_19;{{ef1c:3803}}  (+$03)
        add     hl,de             ;{{ef1e:19}} 
        jr      nc,_convert_number_in_base_defined_20;{{ef1f:3002}}  (+$02)
_convert_number_in_base_defined_19:;{{Addr=$ef21 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$ff             ;{{ef21:0eff}} 
_convert_number_in_base_defined_20:;{{Addr=$ef23 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{ef23:d1}} 
        jr      _convert_number_in_base_defined_7;{{ef24:18e7}}  (-$19)

_convert_number_in_base_defined_22:;{{Addr=$ef26 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{ef26:79}} 
        cp      $01               ;{{ef27:fe01}} 
_convert_number_in_base_defined_24:;{{Addr=$ef29 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef29:eb}} 
        ld      a,b               ;{{ef2a:78}} 
        ret                       ;{{ef2b:c9}} 

_convert_number_in_base_defined_27:;{{Addr=$ef2c Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{ef2c:1a}} 
        inc     de                ;{{ef2d:13}} 
        call    test_if_digit     ;{{ef2e:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_convert_number_in_base_defined_36;{{ef31:380a}}  (+$0a)
        call    convert_character_to_upper_case;{{ef33:cdabff}} ; convert character to upper case
        cp      $41               ;{{ef36:fe41}} 
        ccf                       ;{{ef38:3f}} 
        jr      nc,_convert_number_in_base_defined_38;{{ef39:3005}}  (+$05)
        sub     $07               ;{{ef3b:d607}} 
_convert_number_in_base_defined_36:;{{Addr=$ef3d Code Calls/jump count: 1 Data use count: 0}}
        sub     $30               ;{{ef3d:d630}} 
        cp      b                 ;{{ef3f:b8}} 
_convert_number_in_base_defined_38:;{{Addr=$ef40 Code Calls/jump count: 1 Data use count: 0}}
        ret     c                 ;{{ef40:d8}} 

        dec     de                ;{{ef41:1b}} 
        xor     a                 ;{{ef42:af}} 
        ret                       ;{{ef43:c9}} 

;;============================================
;;display decimal number
display_decimal_number:           ;{{Addr=$ef44 Code Calls/jump count: 2 Data use count: 0}}
        call    convert_int_to_string;{{ef44:cd4aef}} 
        jp      output_ASCIIZ_string;{{ef47:c38bc3}} ; display 0 terminated string

;;=convert int to string
convert_int_to_string:            ;{{Addr=$ef4a Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{ef4a:d5}} 
        push    bc                ;{{ef4b:c5}} 
        call    store_HL_in_accumulator_as_INT;{{ef4c:cd35ff}} 
        call    _poss_free_string_at_bc_length_a_18;{{ef4f:cd03fd}} 
        xor     a                 ;{{ef52:af}} 
        call    _convert_number_to_string_by_format_4;{{ef53:cd72ef}} 
        inc     hl                ;{{ef56:23}} 
        pop     bc                ;{{ef57:c1}} 
        pop     de                ;{{ef58:d1}} 
        ret                       ;{{ef59:c9}} 

;;=convert float atHL to string
convert_float_atHL_to_string:     ;{{Addr=$ef5a Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{ef5a:d5}} 
        push    bc                ;{{ef5b:c5}} 
        xor     a                 ;{{ef5c:af}} 
        call    convert_number_to_string_by_format;{{ef5d:cd6aef}} 
        pop     bc                ;{{ef60:c1}} 
        pop     de                ;{{ef61:d1}} 
        ld      a,(hl)            ;{{ef62:7e}} 
        cp      $20               ;{{ef63:fe20}} ; ' '
        ret     nz                ;{{ef65:c0}} 

        inc     hl                ;{{ef66:23}} 
        ret                       ;{{ef67:c9}} 

;;==================================
;;prob eval number to decimal string
prob_eval_number_to_decimal_string:;{{Addr=$ef68 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$40             ;{{ef68:3e40}} '@' - Decimal specifier
;;=convert number to string by format
;Format is one of + - $ £ * # , . ^
convert_number_to_string_by_format:;{{Addr=$ef6a Code Calls/jump count: 3 Data use count: 0}}
        ld      (RAM_ae52),hl     ;{{ef6a:2252ae}} 
        push    af                ;{{ef6d:f5}} 
        call    _poss_free_string_at_bc_length_a_12;{{ef6e:cdf3fc}} 
        pop     af                ;{{ef71:f1}} 
_convert_number_to_string_by_format_4:;{{Addr=$ef72 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{ef72:c5}} 
        ld      d,a               ;{{ef73:57}} 
        push    de                ;{{ef74:d5}} 
        call    _convert_number_to_string_by_format_357;{{ef75:cd8af1}} 
        pop     de                ;{{ef78:d1}} 
        call    _convert_number_to_string_by_format_25;{{ef79:cd96ef}} 
        call    _convert_number_to_string_by_format_285;{{ef7c:cd1af1}} 
        pop     af                ;{{ef7f:f1}} 
        ld      e,a               ;{{ef80:5f}} 
        ld      a,b               ;{{ef81:78}} 
        or      a                 ;{{ef82:b7}} 
        call    z,_convert_number_to_string_by_format_297;{{ef83:cc2cf1}} 
        call    _convert_number_to_string_by_format_314;{{ef86:cd45f1}} 
        call    _convert_number_to_string_by_format_321;{{ef89:cd4ff1}} 
        call    _convert_number_to_string_by_format_339;{{ef8c:cd6ff1}} 
        ld      a,d               ;{{ef8f:7a}} 
        rra                       ;{{ef90:1f}} 
        ret     nc                ;{{ef91:d0}} 

        dec     hl                ;{{ef92:2b}} 
        ld      (hl),$25          ;{{ef93:3625}} '%'
        ret                       ;{{ef95:c9}} 

_convert_number_to_string_by_format_25:;{{Addr=$ef96 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{ef96:7a}} 
        add     a,a               ;{{ef97:87}} 
        jr      nc,_convert_number_to_string_by_format_54;{{ef98:302d}}  (+$2d)
        jp      m,_convert_number_to_string_by_format_76;{{ef9a:faedef}} 
        ld      a,e               ;{{ef9d:7b}} 
        add     a,c               ;{{ef9e:81}} 
        sub     $15               ;{{ef9f:d615}} 
        jp      m,_convert_number_to_string_by_format_141;{{efa1:fa56f0}} 
        ld      a,d               ;{{efa4:7a}} 
        or      $41               ;{{efa5:f641}}  'A'
        ld      d,a               ;{{efa7:57}} 
        jr      _convert_number_to_string_by_format_76;{{efa8:1843}}  (+$43)

_convert_number_to_string_by_format_37:;{{Addr=$efaa Code Calls/jump count: 2 Data use count: 0}}
        ld      b,c               ;{{efaa:41}} 
        ld      a,c               ;{{efab:79}} 
        or      a                 ;{{efac:b7}} 
        jr      z,_convert_number_to_string_by_format_53;{{efad:2815}}  (+$15)
        add     a,e               ;{{efaf:83}} 
        dec     a                 ;{{efb0:3d}} 
        ld      e,a               ;{{efb1:5f}} 
        call    _convert_number_to_string_by_format_244;{{efb2:cddef0}} 
        ld      b,$01             ;{{efb5:0601}} 
        ld      a,c               ;{{efb7:79}} 
        cp      $07               ;{{efb8:fe07}} 
        jr      c,_convert_number_to_string_by_format_51;{{efba:3804}}  (+$04)
        bit     6,d               ;{{efbc:cb72}} 
        jr      nz,_convert_number_to_string_by_format_73;{{efbe:2026}}  (+$26)
_convert_number_to_string_by_format_51:;{{Addr=$efc0 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{efc0:b8}} 
        call    nz,_convert_number_to_string_by_format_156;{{efc1:c474f0}} 
_convert_number_to_string_by_format_53:;{{Addr=$efc4 Code Calls/jump count: 1 Data use count: 0}}
        jp      _convert_number_to_string_by_format_121;{{efc4:c332f0}} 

_convert_number_to_string_by_format_54:;{{Addr=$efc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{efc7:7b}} 
        or      a                 ;{{efc8:b7}} 
        jp      m,_convert_number_to_string_by_format_60;{{efc9:fad0ef}} 
        jr      nz,_convert_number_to_string_by_format_37;{{efcc:20dc}}  (-$24)
_convert_number_to_string_by_format_58:;{{Addr=$efce Code Calls/jump count: 1 Data use count: 0}}
        ld      b,c               ;{{efce:41}} 
        ret                       ;{{efcf:c9}} 

_convert_number_to_string_by_format_60:;{{Addr=$efd0 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,e               ;{{efd0:43}} 
        call    _convert_number_to_string_by_format_244;{{efd1:cddef0}} 
        ld      a,b               ;{{efd4:78}} 
        or      a                 ;{{efd5:b7}} 
        jr      z,_convert_number_to_string_by_format_58;{{efd6:28f6}}  (-$0a)
        sub     e                 ;{{efd8:93}} 
        ld      e,b               ;{{efd9:58}} 
        ld      b,a               ;{{efda:47}} 
        add     a,c               ;{{efdb:81}} 
        add     a,e               ;{{efdc:83}} 
        jp      m,_convert_number_to_string_by_format_37;{{efdd:faaaef}} 
        call    _convert_number_to_string_by_format_173;{{efe0:cd87f0}} 
        jp      _convert_number_to_string_by_format_156;{{efe3:c374f0}} 

_convert_number_to_string_by_format_73:;{{Addr=$efe6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$06             ;{{efe6:3e06}} 
        ld      (RAM_ae52),a      ;{{efe8:3252ae}} 
        jr      _convert_number_to_string_by_format_104;{{efeb:182e}}  (+$2e)

_convert_number_to_string_by_format_76:;{{Addr=$efed Code Calls/jump count: 2 Data use count: 0}}
        call    _convert_number_to_string_by_format_263;{{efed:cdfbf0}} 
        jr      nc,_convert_number_to_string_by_format_80;{{eff0:3003}}  (+$03)
        set     0,d               ;{{eff2:cbc2}} 
        xor     a                 ;{{eff4:af}} 
_convert_number_to_string_by_format_80:;{{Addr=$eff5 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{eff5:47}} 
        call    z,_convert_number_to_string_by_format_280;{{eff6:cc13f1}} 
        jr      nz,_convert_number_to_string_by_format_91;{{eff9:200e}}  (+$0e)
        set     0,d               ;{{effb:cbc2}} 
        inc     b                 ;{{effd:04}} 
        ld      a,(RAM_ae52)      ;{{effe:3a52ae}} 
        or      a                 ;{{f001:b7}} 
        jr      z,_convert_number_to_string_by_format_91;{{f002:2805}}  (+$05)
        dec     b                 ;{{f004:05}} 
        inc     a                 ;{{f005:3c}} 
        ld      (RAM_ae52),a      ;{{f006:3252ae}} 
_convert_number_to_string_by_format_91:;{{Addr=$f009 Code Calls/jump count: 2 Data use count: 0}}
        bit     1,d               ;{{f009:cb4a}} 
        jr      z,_convert_number_to_string_by_format_98;{{f00b:2807}}  (+$07)
        ld      a,b               ;{{f00d:78}} 
        inc     b                 ;{{f00e:04}} 
_convert_number_to_string_by_format_95:;{{Addr=$f00f Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{f00f:05}} 
        sub     $04               ;{{f010:d604}} 
        jr      nc,_convert_number_to_string_by_format_95;{{f012:30fb}}  (-$05)
_convert_number_to_string_by_format_98:;{{Addr=$f014 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{f014:79}} 
        or      a                 ;{{f015:b7}} 
        jr      z,_convert_number_to_string_by_format_105;{{f016:2804}}  (+$04)
        add     a,e               ;{{f018:83}} 
        sub     b                 ;{{f019:90}} 
        ld      e,a               ;{{f01a:5f}} 
_convert_number_to_string_by_format_104:;{{Addr=$f01b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{f01b:78}} 
_convert_number_to_string_by_format_105:;{{Addr=$f01c Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{f01c:f5}} 
        ld      b,a               ;{{f01d:47}} 
        call    _convert_number_to_string_by_format_142;{{f01e:cd59f0}} 
        pop     af                ;{{f021:f1}} 
        cp      b                 ;{{f022:b8}} 
        jr      z,_convert_number_to_string_by_format_121;{{f023:280d}}  (+$0d)
        inc     e                 ;{{f025:1c}} 
        inc     hl                ;{{f026:23}} 
        dec     b                 ;{{f027:05}} 
        push    hl                ;{{f028:e5}} 
        ld      a,(hl)            ;{{f029:7e}} 
        cp      $2e               ;{{f02a:fe2e}} 
        jr      nz,_convert_number_to_string_by_format_119;{{f02c:2001}}  (+$01)
        inc     hl                ;{{f02e:23}} 
_convert_number_to_string_by_format_119:;{{Addr=$f02f Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$31          ;{{f02f:3631}} 
        pop     hl                ;{{f031:e1}} 
_convert_number_to_string_by_format_121:;{{Addr=$f032 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$04             ;{{f032:3e04}} 
        call    _convert_number_to_string_by_format_219;{{f034:cdc2f0}} 
        push    hl                ;{{f037:e5}} 
        ld      hl,$2b45          ;{{f038:21452b}} 
        ld      a,e               ;{{f03b:7b}} 
        or      a                 ;{{f03c:b7}} 
        jp      p,_convert_number_to_string_by_format_131;{{f03d:f244f0}} 
        xor     a                 ;{{f040:af}} 
        sub     e                 ;{{f041:93}} 
        ld      h,$2d             ;{{f042:262d}}  '-'
_convert_number_to_string_by_format_131:;{{Addr=$f044 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_ae4c),hl     ;{{f044:224cae}} 
        ld      l,$2f             ;{{f047:2e2f}} 
_convert_number_to_string_by_format_133:;{{Addr=$f049 Code Calls/jump count: 1 Data use count: 0}}
        inc     l                 ;{{f049:2c}} 
        sub     $0a               ;{{f04a:d60a}} 
        jr      nc,_convert_number_to_string_by_format_133;{{f04c:30fb}}  (-$05)
        add     a,$3a             ;{{f04e:c63a}} ":"
        ld      h,a               ;{{f050:67}} 
        ld      (last_byte__B),hl ;{{f051:224eae}} 
        pop     hl                ;{{f054:e1}} 
        ret                       ;{{f055:c9}} 

_convert_number_to_string_by_format_141:;{{Addr=$f056 Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_to_string_by_format_173;{{f056:cd87f0}} 
_convert_number_to_string_by_format_142:;{{Addr=$f059 Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_to_string_by_format_280;{{f059:cd13f1}} 
        add     a,b               ;{{f05c:80}} 
        cp      c                 ;{{f05d:b9}} 
        jr      nc,_convert_number_to_string_by_format_148;{{f05e:3005}}  (+$05)
        call    _convert_number_to_string_by_format_188;{{f060:cd9af0}} 
        jr      _convert_number_to_string_by_format_153;{{f063:180a}}  (+$0a)

_convert_number_to_string_by_format_148:;{{Addr=$f065 Code Calls/jump count: 1 Data use count: 0}}
        cp      $15               ;{{f065:fe15}} 
        jr      c,_convert_number_to_string_by_format_151;{{f067:3802}}  (+$02)
        ld      a,$14             ;{{f069:3e14}} 
_convert_number_to_string_by_format_151:;{{Addr=$f06b Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{f06b:91}} 
        call    nz,_convert_number_to_string_by_format_219;{{f06c:c4c2f0}} 
_convert_number_to_string_by_format_153:;{{Addr=$f06f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(RAM_ae52)      ;{{f06f:3a52ae}} 
        or      a                 ;{{f072:b7}} 
        ret     z                 ;{{f073:c8}} 

_convert_number_to_string_by_format_156:;{{Addr=$f074 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,$2e             ;{{f074:0e2e}} 
        ld      a,b               ;{{f076:78}} 
_convert_number_to_string_by_format_158:;{{Addr=$f077 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f077:c5}} 
        ld      b,a               ;{{f078:47}} 
        inc     b                 ;{{f079:04}} 
        add     a,l               ;{{f07a:85}} 
        ld      l,a               ;{{f07b:6f}} 
        adc     a,h               ;{{f07c:8c}} 
        sub     l                 ;{{f07d:95}} 
        ld      h,a               ;{{f07e:67}} 
_convert_number_to_string_by_format_166:;{{Addr=$f07f Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f07f:2b}} 
        ld      a,c               ;{{f080:79}} 
        ld      c,(hl)            ;{{f081:4e}} 
        ld      (hl),a            ;{{f082:77}} 
        djnz    _convert_number_to_string_by_format_166;{{f083:10fa}}  (-$06)
        pop     bc                ;{{f085:c1}} 
        ret                       ;{{f086:c9}} 

_convert_number_to_string_by_format_173:;{{Addr=$f087 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,e               ;{{f087:7b}} 
        add     a,c               ;{{f088:81}} 
        ld      b,a               ;{{f089:47}} 
        ret     p                 ;{{f08a:f0}} 

        cpl                       ;{{f08b:2f}} 
        inc     a                 ;{{f08c:3c}} 
        ld      b,$14             ;{{f08d:0614}} 
        cp      b                 ;{{f08f:b8}} 
        jr      nc,_convert_number_to_string_by_format_183;{{f090:3001}}  (+$01)
        ld      b,a               ;{{f092:47}} 
_convert_number_to_string_by_format_183:;{{Addr=$f093 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f093:2b}} 
        ld      (hl),$30          ;{{f094:3630}} 
        inc     c                 ;{{f096:0c}} 
        djnz    _convert_number_to_string_by_format_183;{{f097:10fa}}  (-$06)
        ret                       ;{{f099:c9}} 

_convert_number_to_string_by_format_188:;{{Addr=$f09a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{f09a:4f}} 
        add     a,l               ;{{f09b:85}} 
        ld      l,a               ;{{f09c:6f}} 
        adc     a,h               ;{{f09d:8c}} 
        sub     l                 ;{{f09e:95}} 
        ld      h,a               ;{{f09f:67}} 
        push    hl                ;{{f0a0:e5}} 
        push    bc                ;{{f0a1:c5}} 
        ld      a,(hl)            ;{{f0a2:7e}} 
        cp      $35               ;{{f0a3:fe35}} 
        call    nc,_convert_number_to_string_by_format_208;{{f0a5:d4b4f0}} 
        pop     bc                ;{{f0a8:c1}} 
        jr      c,_convert_number_to_string_by_format_205;{{f0a9:3805}}  (+$05)
        dec     hl                ;{{f0ab:2b}} 
        ld      (hl),$31          ;{{f0ac:3631}} 
        inc     b                 ;{{f0ae:04}} 
        inc     c                 ;{{f0af:0c}} 
_convert_number_to_string_by_format_205:;{{Addr=$f0b0 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f0b0:e1}} 
        dec     hl                ;{{f0b1:2b}} 
        jr      _convert_number_to_string_by_format_253;{{f0b2:1838}}  (+$38)

_convert_number_to_string_by_format_208:;{{Addr=$f0b4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f0b4:79}} 
        or      a                 ;{{f0b5:b7}} 
        ret     z                 ;{{f0b6:c8}} 

        dec     hl                ;{{f0b7:2b}} 
        dec     c                 ;{{f0b8:0d}} 
        ld      a,(hl)            ;{{f0b9:7e}} 
        inc     (hl)              ;{{f0ba:34}} 
        cp      $39               ;{{f0bb:fe39}} 
        ret     c                 ;{{f0bd:d8}} 

        ld      (hl),$30          ;{{f0be:3630}} 
        jr      _convert_number_to_string_by_format_208;{{f0c0:18f2}}  (-$0e)

_convert_number_to_string_by_format_219:;{{Addr=$f0c2 Code Calls/jump count: 2 Data use count: 0}}
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
_convert_number_to_string_by_format_230:;{{Addr=$f0cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f0cd:1a}} 
        inc     de                ;{{f0ce:13}} 
        ld      (hl),a            ;{{f0cf:77}} 
        inc     hl                ;{{f0d0:23}} 
        or      a                 ;{{f0d1:b7}} 
        jr      nz,_convert_number_to_string_by_format_230;{{f0d2:20f9}}  (-$07)
        dec     hl                ;{{f0d4:2b}} 
_convert_number_to_string_by_format_237:;{{Addr=$f0d5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$30          ;{{f0d5:3630}} 
        inc     hl                ;{{f0d7:23}} 
        djnz    _convert_number_to_string_by_format_237;{{f0d8:10fb}}  (-$05)
        pop     hl                ;{{f0da:e1}} 
        pop     bc                ;{{f0db:c1}} 
        pop     de                ;{{f0dc:d1}} 
        ret                       ;{{f0dd:c9}} 

_convert_number_to_string_by_format_244:;{{Addr=$f0de Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RAM_ae50       ;{{f0de:2150ae}} ##LABEL##
_convert_number_to_string_by_format_245:;{{Addr=$f0e1 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f0e1:2b}} 
        ld      a,(hl)            ;{{f0e2:7e}} 
        cp      $30               ;{{f0e3:fe30}} 
        jr      nz,_convert_number_to_string_by_format_253;{{f0e5:2005}}  (+$05)
        dec     c                 ;{{f0e7:0d}} 
        inc     b                 ;{{f0e8:04}} 
        jr      nz,_convert_number_to_string_by_format_245;{{f0e9:20f6}}  (-$0a)
        dec     hl                ;{{f0eb:2b}} 
_convert_number_to_string_by_format_253:;{{Addr=$f0ec Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f0ec:d5}} 
        push    bc                ;{{f0ed:c5}} 
        ld      de,$ae4f          ;{{f0ee:114fae}} ##LABEL##
        ld      b,$00             ;{{f0f1:0600}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f0f3:cdf5ff}}  copy bytes LDDR (BC = count)
        ex      de,hl             ;{{f0f6:eb}} 
        inc     hl                ;{{f0f7:23}} 
        pop     bc                ;{{f0f8:c1}} 
        pop     de                ;{{f0f9:d1}} 
        ret                       ;{{f0fa:c9}} 

_convert_number_to_string_by_format_263:;{{Addr=$f0fb Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f0fb:c5}} 
        ld      a,d               ;{{f0fc:7a}} 
        and     $04               ;{{f0fd:e604}} 
        rra                       ;{{f0ff:1f}} 
        rra                       ;{{f100:1f}} 
        ld      b,a               ;{{f101:47}} 
        bit     4,d               ;{{f102:cb62}} 
        jr      nz,_convert_number_to_string_by_format_276;{{f104:2007}}  (+$07)
        ld      a,d               ;{{f106:7a}} 
        add     a,a               ;{{f107:87}} 
        or      e                 ;{{f108:b3}} 
        jp      p,_convert_number_to_string_by_format_276;{{f109:f20df1}} 
        inc     b                 ;{{f10c:04}} 
_convert_number_to_string_by_format_276:;{{Addr=$f10d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_ae53)      ;{{f10d:3a53ae}} 
        sub     b                 ;{{f110:90}} 
        pop     bc                ;{{f111:c1}} 
        ret                       ;{{f112:c9}} 

_convert_number_to_string_by_format_280:;{{Addr=$f113 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_ae52)      ;{{f113:3a52ae}} 
        or      a                 ;{{f116:b7}} 
        ret     z                 ;{{f117:c8}} 

        dec     a                 ;{{f118:3d}} 
        ret                       ;{{f119:c9}} 

_convert_number_to_string_by_format_285:;{{Addr=$f11a Code Calls/jump count: 1 Data use count: 0}}
        bit     1,d               ;{{f11a:cb4a}} 
        ret     z                 ;{{f11c:c8}} 

        ld      a,b               ;{{f11d:78}} 
_convert_number_to_string_by_format_288:;{{Addr=$f11e Code Calls/jump count: 1 Data use count: 0}}
        sub     $03               ;{{f11e:d603}} 
        ret     c                 ;{{f120:d8}} 

        ret     z                 ;{{f121:c8}} 

        push    af                ;{{f122:f5}} 
        ld      c,$2c             ;{{f123:0e2c}}  ','
        call    _convert_number_to_string_by_format_158;{{f125:cd77f0}} 
        inc     b                 ;{{f128:04}} 
        pop     af                ;{{f129:f1}} 
        jr      _convert_number_to_string_by_format_288;{{f12a:18f2}}  (-$0e)

_convert_number_to_string_by_format_297:;{{Addr=$f12c Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{f12c:e5}} 
_convert_number_to_string_by_format_298:;{{Addr=$f12d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f12d:7e}} 
        inc     hl                ;{{f12e:23}} 
        dec     a                 ;{{f12f:3d}} 
        cp      $30               ;{{f130:fe30}} 
        jr      c,_convert_number_to_string_by_format_298;{{f132:38f9}}  (-$07)
        inc     a                 ;{{f134:3c}} 
        jr      nz,_convert_number_to_string_by_format_306;{{f135:2001}}  (+$01)
        ld      e,a               ;{{f137:5f}} 
_convert_number_to_string_by_format_306:;{{Addr=$f138 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f138:e1}} 
        ld      a,d               ;{{f139:7a}} 
        xor     $80               ;{{f13a:ee80}} 
        call    p,_convert_number_to_string_by_format_263;{{f13c:f4fbf0}} 
        ret     c                 ;{{f13f:d8}} 

        ret     z                 ;{{f140:c8}} 

        ld      a,$30             ;{{f141:3e30}}  '0'
        jr      _convert_number_to_string_by_format_317;{{f143:1806}} 

_convert_number_to_string_by_format_314:;{{Addr=$f145 Code Calls/jump count: 1 Data use count: 0}}
        bit     2,d               ;{{f145:cb52}} 
        ret     z                 ;{{f147:c8}} 

        ld      a,(RAM_ae54)      ;{{f148:3a54ae}} 
_convert_number_to_string_by_format_317:;{{Addr=$f14b Code Calls/jump count: 2 Data use count: 0}}
        inc     b                 ;{{f14b:04}} 
        dec     hl                ;{{f14c:2b}} 
        ld      (hl),a            ;{{f14d:77}} 
        ret                       ;{{f14e:c9}} 

_convert_number_to_string_by_format_321:;{{Addr=$f14f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{f14f:7b}} 
        add     a,a               ;{{f150:87}} 
        ld      a,$2d             ;{{f151:3e2d}}  '-'
        jr      c,_convert_number_to_string_by_format_333;{{f153:380e}}  
        ld      a,d               ;{{f155:7a}} 
        and     $98               ;{{f156:e698}} 
        xor     $80               ;{{f158:ee80}} 
        ret     z                 ;{{f15a:c8}} 

        and     $08               ;{{f15b:e608}} 
        ld      a,$2b             ;{{f15d:3e2b}}  '+'
        jr      nz,_convert_number_to_string_by_format_333;{{f15f:2002}}  
        ld      a,$20             ;{{f161:3e20}}  ' '
_convert_number_to_string_by_format_333:;{{Addr=$f163 Code Calls/jump count: 2 Data use count: 0}}
        bit     4,d               ;{{f163:cb62}} 
        jr      z,_convert_number_to_string_by_format_317;{{f165:28e4}}  (-$1c)
        ld      (RAM_ae50),a      ;{{f167:3250ae}} 
        xor     a                 ;{{f16a:af}} 
        ld      (RAM_ae51),a      ;{{f16b:3251ae}} 
        ret                       ;{{f16e:c9}} 

_convert_number_to_string_by_format_339:;{{Addr=$f16f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{f16f:7a}} 
        or      a                 ;{{f170:b7}} 
        ret     p                 ;{{f171:f0}} 

        ld      a,(RAM_ae53)      ;{{f172:3a53ae}} 
        sub     b                 ;{{f175:90}} 
        ret     z                 ;{{f176:c8}} 

        jr      c,_convert_number_to_string_by_format_355;{{f177:380e}}  (+$0e)
        ld      b,a               ;{{f179:47}} 
        bit     5,d               ;{{f17a:cb6a}} 
        ld      a,$2a             ;{{f17c:3e2a}} 
        jr      nz,_convert_number_to_string_by_format_351;{{f17e:2002}}  (+$02)
        ld      a,$20             ;{{f180:3e20}} 
_convert_number_to_string_by_format_351:;{{Addr=$f182 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f182:2b}} 
        ld      (hl),a            ;{{f183:77}} 
        djnz    _convert_number_to_string_by_format_351;{{f184:10fc}}  (-$04)
        ret                       ;{{f186:c9}} 

_convert_number_to_string_by_format_355:;{{Addr=$f187 Code Calls/jump count: 1 Data use count: 0}}
        set     0,d               ;{{f187:cbc2}} 
        ret                       ;{{f189:c9}} 

_convert_number_to_string_by_format_357:;{{Addr=$f18a Code Calls/jump count: 1 Data use count: 0}}
        ld      de,buffer_used_to_form_binary_or_hexadecima;{{f18a:112dae}} 
        xor     a                 ;{{f18d:af}} 
        ld      b,a               ;{{f18e:47}} 
_convert_number_to_string_by_format_360:;{{Addr=$f18f Code Calls/jump count: 1 Data use count: 0}}
        or      (hl)              ;{{f18f:b6}} 
        dec     hl                ;{{f190:2b}} 
        jr      nz,_convert_number_to_string_by_format_366;{{f191:2005}}  (+$05)
        dec     c                 ;{{f193:0d}} 
        jr      nz,_convert_number_to_string_by_format_360;{{f194:20f9}}  (-$07)
        jr      _convert_number_to_string_by_format_397;{{f196:1828}}  (+$28)

_convert_number_to_string_by_format_366:;{{Addr=$f198 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{f198:37}} 
_convert_number_to_string_by_format_367:;{{Addr=$f199 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{f199:8f}} 
        jr      nc,_convert_number_to_string_by_format_367;{{f19a:30fd}}  (-$03)
        ex      de,hl             ;{{f19c:eb}} 
        push    de                ;{{f19d:d5}} 
        ld      d,a               ;{{f19e:57}} 
        jr      _convert_number_to_string_by_format_388;{{f19f:1811}}  (+$11)

_convert_number_to_string_by_format_373:;{{Addr=$f1a1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f1a1:1a}} 
        dec     de                ;{{f1a2:1b}} 
        push    de                ;{{f1a3:d5}} 
        scf                       ;{{f1a4:37}} 
        adc     a,a               ;{{f1a5:8f}} 
_convert_number_to_string_by_format_378:;{{Addr=$f1a6 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{f1a6:57}} 
        ld      e,b               ;{{f1a7:58}} 
_convert_number_to_string_by_format_380:;{{Addr=$f1a8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f1a8:7e}} 
        adc     a,a               ;{{f1a9:8f}} 
        daa                       ;{{f1aa:27}} 
        ld      (hl),a            ;{{f1ab:77}} 
        inc     hl                ;{{f1ac:23}} 
        dec     e                 ;{{f1ad:1d}} 
        jr      nz,_convert_number_to_string_by_format_380;{{f1ae:20f8}}  (-$08)
        jr      nc,_convert_number_to_string_by_format_390;{{f1b0:3003}}  (+$03)
_convert_number_to_string_by_format_388:;{{Addr=$f1b2 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{f1b2:04}} 
        ld      (hl),$01          ;{{f1b3:3601}} 
_convert_number_to_string_by_format_390:;{{Addr=$f1b5 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,buffer_used_to_form_binary_or_hexadecima;{{f1b5:212dae}} 
        ld      a,d               ;{{f1b8:7a}} 
        add     a,a               ;{{f1b9:87}} 
        jr      nz,_convert_number_to_string_by_format_378;{{f1ba:20ea}}  (-$16)
        pop     de                ;{{f1bc:d1}} 
        dec     c                 ;{{f1bd:0d}} 
        jr      nz,_convert_number_to_string_by_format_373;{{f1be:20e1}}  (-$1f)
_convert_number_to_string_by_format_397:;{{Addr=$f1c0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{f1c0:eb}} 
        ld      hl,RAM_ae50       ;{{f1c1:2150ae}} 
        ld      (hl),$00          ;{{f1c4:3600}} 
        ld      a,b               ;{{f1c6:78}} 
        add     a,a               ;{{f1c7:87}} 
        ld      c,a               ;{{f1c8:4f}} 
        ret     z                 ;{{f1c9:c8}} 

        ld      a,$30             ;{{f1ca:3e30}} ; '0'
        ex      de,hl             ;{{f1cc:eb}} 
_convert_number_to_string_by_format_406:;{{Addr=$f1cd Code Calls/jump count: 1 Data use count: 0}}
        rrd                       ;{{f1cd:ed67}} 
        dec     de                ;{{f1cf:1b}} 
        ld      (de),a            ;{{f1d0:12}} 
        rrd                       ;{{f1d1:ed67}} 
        dec     de                ;{{f1d3:1b}} 
        ld      (de),a            ;{{f1d4:12}} 
        inc     hl                ;{{f1d5:23}} 
        djnz    _convert_number_to_string_by_format_406;{{f1d6:10f5}}  (-$0b)
        ex      de,hl             ;{{f1d8:eb}} 
        cp      $30               ;{{f1d9:fe30}} 
        ret     nz                ;{{f1db:c0}} 

        dec     c                 ;{{f1dc:0d}} 
        inc     hl                ;{{f1dd:23}} 
        ret                       ;{{f1de:c9}} 

;;===============================
;;convert based number to string
;C=base (01=binary, 0f=hex)
;B=number of bits per output digit (01 for binary, 04 for hex)
convert_based_number_to_string:   ;{{Addr=$f1df Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f1df:d5}} 
        ex      de,hl             ;{{f1e0:eb}} 
        ld      hl,last_byte_     ;{{f1e1:213eae}} 
        ld      (hl),$00          ;{{f1e4:3600}} 
        dec     a                 ;{{f1e6:3d}} 
_convert_based_number_to_string_5:;{{Addr=$f1e7 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{f1e7:f5}} 
        ld      a,e               ;{{f1e8:7b}} 
        and     c                 ;{{f1e9:a1}} 
        or      $f0               ;{{f1ea:f6f0}} 
        daa                       ;{{f1ec:27}} 
        add     a,$a0             ;{{f1ed:c6a0}} 
        adc     a,$40             ;{{f1ef:ce40}} ; 'A'-1
        dec     hl                ;{{f1f1:2b}} 
        ld      (hl),a            ;{{f1f2:77}} 
        ld      a,b               ;{{f1f3:78}} 
_convert_based_number_to_string_15:;{{Addr=$f1f4 Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{f1f4:cb3a}} 
        rr      e                 ;{{f1f6:cb1b}} 
        djnz    _convert_based_number_to_string_15;{{f1f8:10fa}}  (-$06)
        ld      b,a               ;{{f1fa:47}} 
        pop     af                ;{{f1fb:f1}} 
        dec     a                 ;{{f1fc:3d}} 
        jp      p,_convert_based_number_to_string_5;{{f1fd:f2e7f1}} 
        ld      a,d               ;{{f200:7a}} 
        or      e                 ;{{f201:b3}} 
        ld      a,$00             ;{{f202:3e00}} 
        jr      nz,_convert_based_number_to_string_5;{{f204:20e1}}  (-$1f)
        pop     de                ;{{f206:d1}} 
        ret                       ;{{f207:c9}} 





