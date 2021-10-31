;;<< UTILITY ROUTINES
;;< Assorted memory copies, table lookups etc.
;;=========================================================
;; test if letter

test_if_letter:                   ;{{Addr=$ff92 Code Calls/jump count: 4 Data use count: 0}}
        call    convert_character_to_upper_case;{{ff92:cdabff}} ; convert character to upper case

        cp      $41               ;{{ff95:fe41}} ; 'A'
        ccf                       ;{{ff97:3f}} 
        ret     nc                ;{{ff98:d0}} 
        cp      $5b               ;{{ff99:fe5b}} ; 'Z'+1
        ret                       ;{{ff9b:c9}} 

;;=========================================
;; test if letter period or digit
test_if_letter_period_or_digit:   ;{{Addr=$ff9c Code Calls/jump count: 7 Data use count: 0}}
        call    test_if_letter    ;{{ff9c:cd92ff}} 
        ret     c                 ;{{ff9f:d8}} 

;;+----------------------------------------
;; test if period or digit
test_if_period_or_digit:          ;{{Addr=$ffa0 Code Calls/jump count: 2 Data use count: 0}}
        cp      $2e               ;{{ffa0:fe2e}}  '.'
        scf                       ;{{ffa2:37}} 
        ret     z                 ;{{ffa3:c8}} 

;;+----------------------------------------
;; test if digit
;;
;; entry:
;; A = character
;; exit:
;; carry clear = not a digit
;; carry set = is a digit

test_if_digit:                    ;{{Addr=$ffa4 Code Calls/jump count: 4 Data use count: 0}}
        cp      $30               ;{{ffa4:fe30}}  '0'
        ccf                       ;{{ffa6:3f}} 
        ret     nc                ;{{ffa7:d0}} 
        cp      $3a               ;{{ffa8:fe3a}}  '9'+1
        ret                       ;{{ffaa:c9}} 

;;========================================================
;; convert character to upper case

convert_character_to_upper_case:  ;{{Addr=$ffab Code Calls/jump count: 6 Data use count: 1}}
        cp      $61               ;{{ffab:fe61}} 
        ret     c                 ;{{ffad:d8}} 

        cp      $7b               ;{{ffae:fe7b}} 
        ret     nc                ;{{ffb0:d0}} 

        sub     $20               ;{{ffb1:d620}} 
        ret                       ;{{ffb3:c9}} 

;;=========================================================
;; get address from table
;; HL = address of table
;; A = code to find in table
;;
;; table header:
;; 0: count
;; 1,2: address to return to if not found

;; each entry in table:
;; offset 0: code
;; offset 1,2: address

get_address_from_table:           ;{{Addr=$ffb4 Code Calls/jump count: 3 Data use count: 0}}
        push    af                ;{{ffb4:f5}} 
        push    bc                ;{{ffb5:c5}} 
        ld      b,(hl)            ;{{ffb6:46}}  count in table
        inc     hl                ;{{ffb7:23}} 
        push    hl                ;{{ffb8:e5}}  save ptr to 'not found' routine

_get_address_from_table_5:        ;{{Addr=$ffb9 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ffb9:23}} 
        inc     hl                ;{{ffba:23}} 
        cp      (hl)              ;{{ffbb:be}}  code = comparison
        inc     hl                ;{{ffbc:23}} 
        jr      z,_get_address_from_table_12;{{ffbd:2803}}  code found?
        djnz    _get_address_from_table_5;{{ffbf:10f8}}  

;;-----------------------------------------------
;; code not found
;;
;; get address from start of table; putting address of end of table onto stack
        ex      (sp),hl           ;{{ffc1:e3}} retrieve ptr to 'not found' routine
;;-----------------------------------------------
;; code found or not found

_get_address_from_table_12:       ;{{Addr=$ffc2 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{ffc2:f1}} remove unwanted from stack - either 'not found' routine or junk from prev. instr

;; get address from table
        ld      a,(hl)            ;{{ffc3:7e}} 
        inc     hl                ;{{ffc4:23}} 
        ld      h,(hl)            ;{{ffc5:66}} 
        ld      l,a               ;{{ffc6:6f}} 
;;-----------------------------------------------
        pop     bc                ;{{ffc7:c1}} 
        pop     af                ;{{ffc8:f1}} 
        ret                       ;{{ffc9:c9}} 

;;=========================================================
;; check if byte exists in table
;;
;; HL = base address of table (table terminated with 0)
;; A = value
;;
;; carry set = byte exists in table
;; carry clear = byte doesn't exist
;; All other registers preserved

check_if_byte_exists_in_table:    ;{{Addr=$ffca Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{ffca:c5}} 
        ld      c,a               ;{{ffcb:4f}} ; C = byte to compare against

_check_if_byte_exists_in_table_2: ;{{Addr=$ffcc Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{ffcc:7e}} ; get byte from table
;; table terminator?
        or      a                 ;{{ffcd:b7}} 
        jr      z,_check_if_byte_exists_in_table_9;{{ffce:2805}} 
        inc     hl                ;{{ffd0:23}} 
;; same as byte we want
        cp      c                 ;{{ffd1:b9}} 
        jr      nz,_check_if_byte_exists_in_table_2;{{ffd2:20f8}}  (-$08)
;; byte found in table
        scf                       ;{{ffd4:37}} 
;; byte found or not found 
_check_if_byte_exists_in_table_9: ;{{Addr=$ffd5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{ffd5:79}} 
        pop     bc                ;{{ffd6:c1}} 
        ret                       ;{{ffd7:c9}} 

;;=========================================================
;; compare HL DE
compare_HL_DE:                    ;{{Addr=$ffd8 Code Calls/jump count: 30 Data use count: 0}}
        ld      a,h               ;{{ffd8:7c}} 
        sub     d                 ;{{ffd9:92}} 
        ret     nz                ;{{ffda:c0}} 
        ld      a,l               ;{{ffdb:7d}} 
        sub     e                 ;{{ffdc:93}} 
        ret                       ;{{ffdd:c9}} 

;;=========================================================
;; compare HL BC
compare_HL_BC:                    ;{{Addr=$ffde Code Calls/jump count: 10 Data use count: 0}}
        ld      a,h               ;{{ffde:7c}} 
        sub     b                 ;{{ffdf:90}} 
        ret     nz                ;{{ffe0:c0}} 
        ld      a,l               ;{{ffe1:7d}} 
        sub     c                 ;{{ffe2:91}} 
        ret                       ;{{ffe3:c9}} 
    
;;=========================================================
;; BC equal HL minus DE
;;
;; HL,DE preserved
;; flags corrupt

BC_equal_HL_minus_DE:             ;{{Addr=$ffe4 Code Calls/jump count: 8 Data use count: 0}}
        push    hl                ;{{ffe4:e5}} ; store HL
        or      a                 ;{{ffe5:b7}} 
        sbc     hl,de             ;{{ffe6:ed52}} ; HL = HL - DE
        ld      b,h               ;{{ffe8:44}} ; BC = HL - DE
        ld      c,l               ;{{ffe9:4d}} 
        pop     hl                ;{{ffea:e1}} ; restore HL
        ret                       ;{{ffeb:c9}} 

;;=========================================================
;; copy bytes LDIR  (A=count, HL=source, DE=dest)
;;
;; HL = source
;; DE = destination
;; A = count

copy_bytes_LDIR__Acount_HLsource_DEdest:;{{Addr=$ffec Code Calls/jump count: 6 Data use count: 0}}
        ld      c,a               ;{{ffec:4f}} 
        ld      b,$00             ;{{ffed:0600}} 
;; BC = count

;;+--------------------------------------------------------------
;; copy bytes LDIR (BC=count, HL=source, DE=dest)
;; BC=0?
copy_bytes_LDIR_BCcount_HLsource_DEdest:;{{Addr=$ffef Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{ffef:78}} 
        or      c                 ;{{fff0:b1}} 
        ret     z                 ;{{fff1:c8}} 

;; copy if BC<>0
        ldir                      ;{{fff2:edb0}} 
        ret                       ;{{fff4:c9}} 

;;=========================================================
;; copy bytes LDDR (BC=count, HL=source, DE=dest)
;; BC=0?
copy_bytes_LDDR_BCcount_HLsource_DEdest:;{{Addr=$fff5 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{fff5:78}} 
        or      c                 ;{{fff6:b1}} 
        ret     z                 ;{{fff7:c8}} 
;; copy if BC<>0
        lddr                      ;{{fff8:edb8}} 
        ret                       ;{{fffa:c9}} 

;;=========================================================
;; JP (HL)
JP_HL:                            ;{{Addr=$fffb Code Calls/jump count: 2 Data use count: 0}}
        jp      (hl)              ;{{fffb:e9}} 

;;=========================================================
;; JP (BC)
JP_BC:                            ;{{Addr=$fffc Code Calls/jump count: 7 Data use count: 0}}
        push    bc                ;{{fffc:c5}} 
        ret                       ;{{fffd:c9}} 

;;=========================================================
;; JP (DE)
JP_DE:                            ;{{Addr=$fffe Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{fffe:d5}} 
        ret                       ;{{ffff:c9}} 
;;--------------------------------------------------------------
