;;<< INTEGER MATHS
;;< (used both internally and by functions)
;;=====================================
;;prep regs for int to string
prep_regs_for_int_to_string:      ;{{Addr=$dd2a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,h               ;{{dd2a:44}} 
        call    negate_HL_if_negative_and_test_if_INT;{{dd2b:cdeadd}} 
        jr      set_E_zero_C_to_2_int_type;{{dd2e:1802}}  (+$02)

;;=set B zero E zero C to 2 int type
set_B_zero_E_zero_C_to_2_int_type:;{{Addr=$dd30 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{dd30:0600}} 
;;=set E zero C to 2 int type
set_E_zero_C_to_2_int_type:       ;{{Addr=$dd32 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,$00             ;{{dd32:1e00}} 
        ld      c,$02             ;{{dd34:0e02}} 
        ret                       ;{{dd36:c9}} 

;;=unknown maths fixup
;Bit 7 of B = invert value in HL
unknown_maths_fixup:              ;{{Addr=$dd37 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,h               ;{{dd37:7c}} 
        or      a                 ;{{dd38:b7}} 
        jp      m,unknown_maths_fixup_B;{{dd39:fa42dd}} 
        or      b                 ;{{dd3c:b0}} 
        jp      m,negate_HL_and_test_if_INT;{{dd3d:faeddd}} 
        scf                       ;{{dd40:37}} 
        ret                       ;{{dd41:c9}} 

;;--------------------------------------------------------------
;;=unknown maths fixup
unknown_maths_fixup_B:            ;{{Addr=$dd42 Code Calls/jump count: 1 Data use count: 0}}
        xor     $80               ;{{dd42:ee80}} Toggle bit 7
        or      l                 ;{{dd44:b5}} 
        ret     nz                ;{{dd45:c0}} 

        ld      a,b               ;{{dd46:78}} 
        scf                       ;{{dd47:37}} 
        adc     a,a               ;{{dd48:8f}} A = 2 * B + 1
        ret                       ;{{dd49:c9}} 

;;================================================================
;;INT addition with overflow test
INT_addition_with_overflow_test:  ;{{Addr=$dd4a Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{dd4a:b7}} 
        adc     hl,de             ;{{dd4b:ed5a}} 
        scf                       ;{{dd4d:37}} 
        ret     po                ;{{dd4e:e0}} 

        or      $ff               ;{{dd4f:f6ff}} 
        ret                       ;{{dd51:c9}} 

;;==============================================
;;INT subtraction with overflow test
INT_subtraction_with_overflow_test:;{{Addr=$dd52 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{dd52:eb}} 
        or      a                 ;{{dd53:b7}} 
        sbc     hl,de             ;{{dd54:ed52}} 
        scf                       ;{{dd56:37}} 
        ret     po                ;{{dd57:e0}} 

        or      $ff               ;{{dd58:f6ff}} 
        ret                       ;{{dd5a:c9}} 

;;=============================================
;;INT multiply with overflow test
INT_multiply_with_overflow_test:  ;{{Addr=$dd5b Code Calls/jump count: 1 Data use count: 0}}
        call    make_both_operands_positive;{{dd5b:cd67dd}} 
        call    do_16x16_multiply_with_overflow;{{dd5e:cd72dd}} 
        jp      nc,unknown_maths_fixup;{{dd61:d237dd}} negate result if operands where different signs (B bit 7 set) and ??
        or      $ff               ;{{dd64:f6ff}} 
        ret                       ;{{dd66:c9}} 

;;=make both operands positive
make_both_operands_positive:      ;{{Addr=$dd67 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{dd67:7c}} 
        xor     d                 ;{{dd68:aa}} 
        ld      b,a               ;{{dd69:47}} Bit 7 of B = are both operands the same sign?
        ex      de,hl             ;{{dd6a:eb}} 
        call    negate_HL_if_negative_and_test_if_INT;{{dd6b:cdeadd}} 
        ex      de,hl             ;{{dd6e:eb}} 
        jp      negate_HL_if_negative_and_test_if_INT;{{dd6f:c3eadd}} 

;;=do 16x16 multiply with overflow
do_16x16_multiply_with_overflow:  ;{{Addr=$dd72 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,h               ;{{dd72:7c}} 
        or      a                 ;{{dd73:b7}} 
        jr      z,_do_16x16_multiply_with_overflow_8;{{dd74:2805}}  (+$05)
        ld      a,d               ;{{dd76:7a}} 
        or      a                 ;{{dd77:b7}} 
        scf                       ;{{dd78:37}} 
        ret     nz                ;{{dd79:c0}} 

        ex      de,hl             ;{{dd7a:eb}} 
_do_16x16_multiply_with_overflow_8:;{{Addr=$dd7b Code Calls/jump count: 1 Data use count: 0}}
        or      l                 ;{{dd7b:b5}} 
        ret     z                 ;{{dd7c:c8}} 

        ld      a,d               ;{{dd7d:7a}} 
        or      e                 ;{{dd7e:b3}} 
        ld      a,l               ;{{dd7f:7d}} 
        ld      l,e               ;{{dd80:6b}} 
        ld      h,d               ;{{dd81:62}} 
        ret     z                 ;{{dd82:c8}} 

        cp      $03               ;{{dd83:fe03}} 
        jr      c,_do_16x16_multiply_with_overflow_30;{{dd85:3810}}  (+$10)
        scf                       ;{{dd87:37}} 
_do_16x16_multiply_with_overflow_19:;{{Addr=$dd88 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{dd88:8f}} 
        jr      nc,_do_16x16_multiply_with_overflow_19;{{dd89:30fd}}  (-$03)
_do_16x16_multiply_with_overflow_21:;{{Addr=$dd8b Code Calls/jump count: 1 Data use count: 0}}
        add     hl,hl             ;{{dd8b:29}} 
        ret     c                 ;{{dd8c:d8}} 

        add     a,a               ;{{dd8d:87}} 
        jr      nc,_do_16x16_multiply_with_overflow_27;{{dd8e:3002}}  (+$02)
        add     hl,de             ;{{dd90:19}} 
        ret     c                 ;{{dd91:d8}} 

_do_16x16_multiply_with_overflow_27:;{{Addr=$dd92 Code Calls/jump count: 1 Data use count: 0}}
        cp      $80               ;{{dd92:fe80}} 
        jr      nz,_do_16x16_multiply_with_overflow_21;{{dd94:20f5}}  (-$0b)
        ret                       ;{{dd96:c9}} 

_do_16x16_multiply_with_overflow_30:;{{Addr=$dd97 Code Calls/jump count: 1 Data use count: 0}}
        cp      $01               ;{{dd97:fe01}} 
        ret     z                 ;{{dd99:c8}} 

        add     hl,hl             ;{{dd9a:29}} 
        ret                       ;{{dd9b:c9}} 

;;===================
;;INT division with overflow test
INT_division_with_overflow_test:  ;{{Addr=$dd9c Code Calls/jump count: 1 Data use count: 0}}
        call    _int_modulo_5     ;{{dd9c:cdabdd}} 
_int_division_with_overflow_test_1:;{{Addr=$dd9f Code Calls/jump count: 1 Data use count: 0}}
        jp      c,unknown_maths_fixup;{{dd9f:da37dd}} 
        ret                       ;{{dda2:c9}} 

;;=INT modulo
INT_modulo:                       ;{{Addr=$dda3 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,h               ;{{dda3:4c}} 
        call    _int_modulo_5     ;{{dda4:cdabdd}} 
        ex      de,hl             ;{{dda7:eb}} 
        ld      b,c               ;{{dda8:41}} 
        jr      _int_division_with_overflow_test_1;{{dda9:18f4}}  (-$0c)

_int_modulo_5:                    ;{{Addr=$ddab Code Calls/jump count: 2 Data use count: 0}}
        call    make_both_operands_positive;{{ddab:cd67dd}} 
_int_modulo_6:                    ;{{Addr=$ddae Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{ddae:7a}} 
        or      e                 ;{{ddaf:b3}} 
        ret     z                 ;{{ddb0:c8}} 

        push    bc                ;{{ddb1:c5}} 
        ex      de,hl             ;{{ddb2:eb}} 
        ld      b,$01             ;{{ddb3:0601}} 
        ld      a,h               ;{{ddb5:7c}} 
        or      a                 ;{{ddb6:b7}} 
        jr      nz,_int_modulo_21 ;{{ddb7:2009}}  (+$09)
        ld      a,d               ;{{ddb9:7a}} 
        cp      l                 ;{{ddba:bd}} 
        jr      c,_int_modulo_21  ;{{ddbb:3805}}  (+$05)
        ld      h,l               ;{{ddbd:65}} 
        ld      l,$00             ;{{ddbe:2e00}} 
        ld      b,$09             ;{{ddc0:0609}} 
_int_modulo_21:                   ;{{Addr=$ddc2 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{ddc2:7b}} 
        sub     l                 ;{{ddc3:95}} 
        ld      a,d               ;{{ddc4:7a}} 
        sbc     a,h               ;{{ddc5:9c}} 
        jr      c,_int_modulo_30  ;{{ddc6:3805}}  (+$05)
        inc     b                 ;{{ddc8:04}} 
        add     hl,hl             ;{{ddc9:29}} 
        jr      nc,_int_modulo_21 ;{{ddca:30f6}}  (-$0a)
        ccf                       ;{{ddcc:3f}} 
_int_modulo_30:                   ;{{Addr=$ddcd Code Calls/jump count: 1 Data use count: 0}}
        ccf                       ;{{ddcd:3f}} 
        ld      a,b               ;{{ddce:78}} 
        ld      b,h               ;{{ddcf:44}} 
        ld      c,l               ;{{ddd0:4d}} 
        ld      hl,RESET_ENTRY    ;{{ddd1:210000}} 
        jr      _int_modulo_45    ;{{ddd4:180e}}  (+$0e)

_int_modulo_36:                   ;{{Addr=$ddd6 Code Calls/jump count: 1 Data use count: 0}}
        rr      b                 ;{{ddd6:cb18}} 
        rr      c                 ;{{ddd8:cb19}} 
        ex      de,hl             ;{{ddda:eb}} 
        sbc     hl,bc             ;{{dddb:ed42}} 
        jr      nc,_int_modulo_42 ;{{dddd:3001}}  (+$01)
        add     hl,bc             ;{{dddf:09}} 
_int_modulo_42:                   ;{{Addr=$dde0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{dde0:eb}} 
        ccf                       ;{{dde1:3f}} 
        adc     hl,hl             ;{{dde2:ed6a}} 
_int_modulo_45:                   ;{{Addr=$dde4 Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{dde4:3d}} 
        jr      nz,_int_modulo_36 ;{{dde5:20ef}}  (-$11)
        scf                       ;{{dde7:37}} 
        pop     bc                ;{{dde8:c1}} 
        ret                       ;{{dde9:c9}} 

;;--------------------------------------------------------------
;;=negate HL if negative and test if INT
negate_HL_if_negative_and_test_if_INT:;{{Addr=$ddea Code Calls/jump count: 3 Data use count: 0}}
        ld      a,h               ;{{ddea:7c}} 
        or      a                 ;{{ddeb:b7}} 
        ret     p                 ;{{ddec:f0}} if HL is >= 0

;;=negate HL and test if INT
;HL = -HL, then test if it's a valid INT value
;Returns NC if the result is not a valid INT
negate_HL_and_test_if_INT:        ;{{Addr=$dded Code Calls/jump count: 3 Data use count: 0}}
        xor     a                 ;{{dded:af}} 
        sub     l                 ;{{ddee:95}} 
        ld      l,a               ;{{ddef:6f}} L = -L
        sbc     a,h               ;{{ddf0:9c}} H = -L - H
        sub     l                 ;{{ddf1:95}} H = -L - H - L
        cp      h                 ;{{ddf2:bc}} 
        ld      h,a               ;{{ddf3:67}} 
        scf                       ;{{ddf4:37}} 
        ret     nz                ;{{ddf5:c0}} 

        cp      $01               ;{{ddf6:fe01}} 
        ret                       ;{{ddf8:c9}} 

;;--------------------------------------------------------------
;;=unknown test HL
;; HL = value

;; HL = 0?
unknown_test_HL:                  ;{{Addr=$ddf9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{ddf9:7c}} 
        or      l                 ;{{ddfa:b5}} 
        ret     z                 ;{{ddfb:c8}} return if HL = 0

        ld      a,h               ;{{ddfc:7c}} 
        add     a,a               ;{{ddfd:87}} A = H + H
        sbc     a,a               ;{{ddfe:9f}} A = H + H - H
        ret     c                 ;{{ddff:d8}} 

        inc     a                 ;{{de00:3c}} 
        ret                       ;{{de01:c9}} 

;;==================================================
;;prob compare DE to HL?
;if HL >= 0 and DE=HL then A := 0
prob_compare_DE_to_HL:            ;{{Addr=$de02 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{de02:7c}} 
        xor     d                 ;{{de03:aa}} 
        ld      a,h               ;{{de04:7c}} 
        jp      p,_prob_compare_de_to_hl_9;{{de05:f20dde}} if H >= 0 then if DE=HL then return with A=A+1
        add     a,a               ;{{de08:87}} If A > &7f then set A to &ff, otherwise 0

_prob_compare_de_to_hl_5:         ;{{Addr=$de09 Code Calls/jump count: 2 Data use count: 0}}
        sbc     a,a               ;{{de09:9f}} if carry, A will be &ff, otherwise 0
        ret     c                 ;{{de0a:d8}} A=&ff

        inc     a                 ;{{de0b:3c}} A=1
        ret                       ;{{de0c:c9}} 

_prob_compare_de_to_hl_9:         ;{{Addr=$de0d Code Calls/jump count: 1 Data use count: 0}}
        cp      d                 ;{{de0d:ba}} 
        jr      nz,_prob_compare_de_to_hl_5;{{de0e:20f9}}  (-$07) if A <> D
        ld      a,l               ;{{de10:7d}} 
        sub     e                 ;{{de11:93}} 
        jr      nz,_prob_compare_de_to_hl_5;{{de12:20f5}}  (-$0b) if A,L <> DE
        ret                       ;{{de14:c9}} A=0




