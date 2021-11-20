;;<< STRINGS TO NUMBERS
;;==============================
;;possibly validate input buffer is a number

possibly_validate_input_buffer_is_a_number:;{{Addr=$ed6f Code Calls/jump count: 3 Data use count: 0}}
        call    _possibly_validate_input_buffer_is_a_number_87;{{ed6f:cd0fee}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_4;{{ed72:2005}}  (+$05)
        call    skip_space_tab_or_line_feed;{{ed74:cd4dde}}  skip space, lf or tab
        jr      _possibly_validate_input_buffer_is_a_number_31;{{ed77:182f}}  (+$2f)

_possibly_validate_input_buffer_is_a_number_4:;{{Addr=$ed79 Code Calls/jump count: 1 Data use count: 0}}
        cp      $26               ;{{ed79:fe26}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_22;{{ed7b:281c}}  (+$1c)
        call    test_if_period_or_digit;{{ed7d:cda0ff}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_31;{{ed80:3826}}  (+$26)
        call    set_accumulator_type_to_int;{{ed82:cd38ff}} 
        call    zero_accumulator  ;{{ed85:cd1bff}} 
        scf                       ;{{ed88:37}} 
        ret                       ;{{ed89:c9}} 

_possibly_validate_input_buffer_is_a_number_12:;{{Addr=$ed8a Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ed8a:e5}} 
        call    _possibly_validate_input_buffer_is_a_number_18;{{ed8b:cd92ed}} 
        pop     de                ;{{ed8e:d1}} 
        ret     c                 ;{{ed8f:d8}} 

        ex      de,hl             ;{{ed90:eb}} 
        ret                       ;{{ed91:c9}} 

_possibly_validate_input_buffer_is_a_number_18:;{{Addr=$ed92 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,$00             ;{{ed92:1600}} 
        ld      a,(hl)            ;{{ed94:7e}} 
        cp      $26               ;{{ed95:fe26}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_31;{{ed97:200f}}  (+$0f)
_possibly_validate_input_buffer_is_a_number_22:;{{Addr=$ed99 Code Calls/jump count: 1 Data use count: 0}}
        call    convert_number_b  ;{{ed99:cde7ee}} 
        ex      de,hl             ;{{ed9c:eb}} 
        push    af                ;{{ed9d:f5}} 
        call    store_HL_in_accumulator_as_INT;{{ed9e:cd35ff}} 
        pop     af                ;{{eda1:f1}} 
        ex      de,hl             ;{{eda2:eb}} 
        ret     c                 ;{{eda3:d8}} 

        ret     z                 ;{{eda4:c8}} 

        jp      overflow_error    ;{{eda5:c3becb}} 

_possibly_validate_input_buffer_is_a_number_31:;{{Addr=$eda8 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{eda8:e5}} 
        ld      a,(hl)            ;{{eda9:7e}} 
        inc     hl                ;{{edaa:23}} 
        cp      $2e               ;{{edab:fe2e}} 
        call    z,skip_space_tab_or_line_feed;{{edad:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{edb0:cda4ff}} ; test if ASCII character represents a decimal number digit
        pop     hl                ;{{edb3:e1}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_44;{{edb4:3806}}  (+$06)
        ld      a,(hl)            ;{{edb6:7e}} 
        xor     $2e               ;{{edb7:ee2e}} 
        ret     nz                ;{{edb9:c0}} 

        inc     hl                ;{{edba:23}} 
        ret                       ;{{edbb:c9}} 

_possibly_validate_input_buffer_is_a_number_44:;{{Addr=$edbc Code Calls/jump count: 1 Data use count: 0}}
        call    set_accumulator_type_to_int;{{edbc:cd38ff}} 
        push    de                ;{{edbf:d5}} 
        ld      bc,RESET_ENTRY    ;{{edc0:010000}} 
        ld      de,buffer_used_to_form_binary_or_hexadecima;{{edc3:112dae}} 
        call    _possibly_validate_input_buffer_is_a_number_97;{{edc6:cd1eee}} 
        cp      $2e               ;{{edc9:fe2e}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_56;{{edcb:200b}}  (+$0b)
        call    _possibly_validate_input_buffer_is_a_number_170;{{edcd:cd94ee}} 
        call    set_accumulator_type_to_real;{{edd0:cd41ff}} 
        inc     c                 ;{{edd3:0c}} 
        call    _possibly_validate_input_buffer_is_a_number_97;{{edd4:cd1eee}} 
        dec     c                 ;{{edd7:0d}} 
_possibly_validate_input_buffer_is_a_number_56:;{{Addr=$edd8 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{edd8:eb}} 
        ld      (hl),$ff          ;{{edd9:36ff}} 
        ex      de,hl             ;{{eddb:eb}} 
        call    _possibly_validate_input_buffer_is_a_number_120;{{eddc:cd42ee}} 
        pop     de                ;{{eddf:d1}} 
        ld      e,a               ;{{ede0:5f}} 
        push    hl                ;{{ede1:e5}} 
        push    de                ;{{ede2:d5}} 
        ld      hl,buffer_used_to_form_binary_or_hexadecima;{{ede3:212dae}} 
        call    _possibly_validate_input_buffer_is_a_number_173;{{ede6:cd99ee}} 
        pop     de                ;{{ede9:d1}} 
        call    is_accumulator_a_string;{{edea:cd66ff}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_74;{{eded:3008}}  (+$08)
        push    hl                ;{{edef:e5}} 
        ld      b,d               ;{{edf0:42}} 
        call    _function_int_11  ;{{edf1:cd2cfe}} 
        pop     hl                ;{{edf4:e1}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_83;{{edf5:3811}}  (+$11)
_possibly_validate_input_buffer_is_a_number_74:;{{Addr=$edf7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{edf7:7a}} 
        ld      c,(hl)            ;{{edf8:4e}} 
        inc     hl                ;{{edf9:23}} 
        call    REAL_5byte_to_real;{{edfa:cdb8bd}} 
        ld      a,e               ;{{edfd:7b}} 
        call    REAL_10A          ;{{edfe:cd79bd}} 
        ex      de,hl             ;{{ee01:eb}} 
        call    set_accumulator_type_to_real_and_HL_to_accumulator_addr;{{ee02:cd3eff}} 
        call    c,REAL_copy_atDE_to_atHL;{{ee05:dc61bd}} 
_possibly_validate_input_buffer_is_a_number_83:;{{Addr=$ee08 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0a             ;{{ee08:3e0a}} 
        pop     hl                ;{{ee0a:e1}} 
        ret     c                 ;{{ee0b:d8}} 

        jp      overflow_error    ;{{ee0c:c3becb}} 

_possibly_validate_input_buffer_is_a_number_87:;{{Addr=$ee0f Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee0f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee12:23}} 
        ld      d,$ff             ;{{ee13:16ff}} 
        cp      $2d               ;{{ee15:fe2d}} '-'
        ret     z                 ;{{ee17:c8}} 

        inc     d                 ;{{ee18:14}} 
        cp      $2b               ;{{ee19:fe2b}} 
        ret     z                 ;{{ee1b:c8}} 

        dec     hl                ;{{ee1c:2b}} 
        ret                       ;{{ee1d:c9}} 

_possibly_validate_input_buffer_is_a_number_97:;{{Addr=$ee1e Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{ee1e:e5}} 
        call    skip_space_tab_or_line_feed;{{ee1f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee22:23}} 
        call    test_if_digit     ;{{ee23:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_possibly_validate_input_buffer_is_a_number_104;{{ee26:3804}}  (+$04)
        pop     hl                ;{{ee28:e1}} 
        jp      convert_character_to_upper_case;{{ee29:c3abff}} ; convert character to upper case

_possibly_validate_input_buffer_is_a_number_104:;{{Addr=$ee2c Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee2c:e3}} 
        pop     hl                ;{{ee2d:e1}} 
        sub     $30               ;{{ee2e:d630}} 
        ld      (de),a            ;{{ee30:12}} 
        or      b                 ;{{ee31:b0}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_115;{{ee32:2807}}  (+$07)
        ld      a,b               ;{{ee34:78}} 
        inc     b                 ;{{ee35:04}} 
        cp      $0c               ;{{ee36:fe0c}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_115;{{ee38:3001}}  (+$01)
        inc     de                ;{{ee3a:13}} 
_possibly_validate_input_buffer_is_a_number_115:;{{Addr=$ee3b Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{ee3b:79}} 
        or      a                 ;{{ee3c:b7}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_97;{{ee3d:28df}}  (-$21)
        inc     c                 ;{{ee3f:0c}} 
        jr      _possibly_validate_input_buffer_is_a_number_97;{{ee40:18dc}} 

_possibly_validate_input_buffer_is_a_number_120:;{{Addr=$ee42 Code Calls/jump count: 1 Data use count: 0}}
        cp      $45               ;{{ee42:fe45}} ; 'E'
        jr      nz,_possibly_validate_input_buffer_is_a_number_129;{{ee44:2010}} 
         
        push    hl                ;{{ee46:e5}} 
        call    _possibly_validate_input_buffer_is_a_number_170;{{ee47:cd94ee}} 
        call    _possibly_validate_input_buffer_is_a_number_87;{{ee4a:cd0fee}} 
        call    z,skip_space_tab_or_line_feed;{{ee4d:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{ee50:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_possibly_validate_input_buffer_is_a_number_131;{{ee53:3804}}  (+$04)
        pop     hl                ;{{ee55:e1}} 

_possibly_validate_input_buffer_is_a_number_129:;{{Addr=$ee56 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{ee56:af}} 
        jr      _possibly_validate_input_buffer_is_a_number_151;{{ee57:181e}}  (+$1e)

_possibly_validate_input_buffer_is_a_number_131:;{{Addr=$ee59 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee59:e3}} 
        pop     hl                ;{{ee5a:e1}} 
        call    set_accumulator_type_to_real;{{ee5b:cd41ff}} 
        push    de                ;{{ee5e:d5}} 
        push    bc                ;{{ee5f:c5}} 
        call    convert_number_in_base_defined;{{ee60:cd00ef}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_144;{{ee63:3009}}  (+$09)
        ld      a,e               ;{{ee65:7b}} 
        sub     $64               ;{{ee66:d664}} 
        ld      a,d               ;{{ee68:7a}} 
        sbc     a,$00             ;{{ee69:de00}} 
        ld      a,e               ;{{ee6b:7b}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_145;{{ee6c:3802}}  (+$02)
_possibly_validate_input_buffer_is_a_number_144:;{{Addr=$ee6e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$7f             ;{{ee6e:3e7f}} 
_possibly_validate_input_buffer_is_a_number_145:;{{Addr=$ee70 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{ee70:c1}} 
        pop     de                ;{{ee71:d1}} 
        inc     d                 ;{{ee72:14}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_151;{{ee73:2002}}  (+$02)
        cpl                       ;{{ee75:2f}} 
        inc     a                 ;{{ee76:3c}} 

_possibly_validate_input_buffer_is_a_number_151:;{{Addr=$ee77 Code Calls/jump count: 2 Data use count: 0}}
        add     a,$80             ;{{ee77:c680}} 
        ld      e,a               ;{{ee79:5f}} 
        ld      a,b               ;{{ee7a:78}} 
        sub     $0c               ;{{ee7b:d60c}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_157;{{ee7d:3001}}  (+$01)
        xor     a                 ;{{ee7f:af}} 
_possibly_validate_input_buffer_is_a_number_157:;{{Addr=$ee80 Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{ee80:91}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_165;{{ee81:3009}}  (+$09)
        add     a,e               ;{{ee83:83}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_162;{{ee84:3801}}  (+$01)
        xor     a                 ;{{ee86:af}} 
_possibly_validate_input_buffer_is_a_number_162:;{{Addr=$ee87 Code Calls/jump count: 1 Data use count: 0}}
        cp      $01               ;{{ee87:fe01}} 
        adc     a,$80             ;{{ee89:ce80}} 
        ret                       ;{{ee8b:c9}} 

_possibly_validate_input_buffer_is_a_number_165:;{{Addr=$ee8c Code Calls/jump count: 1 Data use count: 0}}
        add     a,e               ;{{ee8c:83}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_168;{{ee8d:3002}}  (+$02)
        ld      a,$ff             ;{{ee8f:3eff}} 
_possibly_validate_input_buffer_is_a_number_168:;{{Addr=$ee91 Code Calls/jump count: 1 Data use count: 0}}
        sub     $80               ;{{ee91:d680}} 
        ret                       ;{{ee93:c9}} 

_possibly_validate_input_buffer_is_a_number_170:;{{Addr=$ee94 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee94:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee97:23}} 
        ret                       ;{{ee98:c9}} 

_possibly_validate_input_buffer_is_a_number_173:;{{Addr=$ee99 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ee99:eb}} 
        ld      hl,$ae3f          ;{{ee9a:213fae}} 
        ld      bc,$0501          ;{{ee9d:010105}} 
_possibly_validate_input_buffer_is_a_number_176:;{{Addr=$eea0 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{eea0:2b}} 
        ld      (hl),$00          ;{{eea1:3600}} 
        djnz    _possibly_validate_input_buffer_is_a_number_176;{{eea3:10fb}}  (-$05)
        ld      a,(de)            ;{{eea5:1a}} 
        cp      $ff               ;{{eea6:feff}} 
        ret     z                 ;{{eea8:c8}} 

        ld      (hl),a            ;{{eea9:77}} 
_possibly_validate_input_buffer_is_a_number_183:;{{Addr=$eeaa Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,start_of_buffer_used_to_form_hexadecimal;{{eeaa:213aae}} 
        inc     de                ;{{eead:13}} 
        ld      a,(de)            ;{{eeae:1a}} 
        cp      $ff               ;{{eeaf:feff}} 
        ret     z                 ;{{eeb1:c8}} 

        push    de                ;{{eeb2:d5}} 
        ld      b,c               ;{{eeb3:41}} 
        ld      d,$00             ;{{eeb4:1600}} 
_possibly_validate_input_buffer_is_a_number_191:;{{Addr=$eeb6 Code Calls/jump count: 1 Data use count: 0}}
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
        djnz    _possibly_validate_input_buffer_is_a_number_191;{{eec5:10ef}}  (-$11)
        pop     de                ;{{eec7:d1}} 
        or      a                 ;{{eec8:b7}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_183;{{eec9:28df}}  (-$21)
        ld      (hl),a            ;{{eecb:77}} 
        inc     c                 ;{{eecc:0c}} 
        jr      _possibly_validate_input_buffer_is_a_number_183;{{eecd:18db}}  (-$25)





