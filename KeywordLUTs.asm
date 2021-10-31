;;<< KEYWORD LOOK UP TABLES
;;< And associated functions
;;=======================================================================
;; get keyword table for letter
;; A = initial letter of BASIC keyword
get_keyword_table_for_letter:     ;{{Addr=$e3a8 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e3a8:e5}} 
        sub     $41               ;{{e3a9:d641}}  initial letter - 'A'
                                  ; number in range 0->27
        add     a,a               ;{{e3ab:87}}  x2 (two bytes per table entry)
                                  ; A = offset into table

        add     a,(keyword_table_per_letter) and $ff;{{e3ac:c618}} $18  table starts at $e418 Low byte of keyword table address
        ld      l,a               ;{{e3ae:6f}} 
        adc     a,(keyword_table_per_letter >> 8);{{e3af:cee4}} $e4  high byte of keyword table address
        sub     l                 ;{{e3b1:95}} 
        ld      h,a               ;{{e3b2:67}} 

        ld      e,(hl)            ;{{e3b3:5e}}  get address of keyword list from table
        inc     hl                ;{{e3b4:23}} 
        ld      d,(hl)            ;{{e3b5:56}} 
        pop     hl                ;{{e3b6:e1}} 
        ret                       ;{{e3b7:c9}} 

;;========================================================================
;;convert token to keyword text ptr
convert_token_to_keyword_text_ptr:;{{Addr=$e3b8 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e3b8:c5}} 
        ld      c,a               ;{{e3b9:4f}} 
        ld      b,$1a             ;{{e3ba:061a}}  Table count
        ld      hl,keyword_table_Z;{{e3bc:214ce4}} 

_convert_token_to_keyword_text_ptr_4:;{{Addr=$e3bf Code Calls/jump count: 1 Data use count: 0}}
        call    search_within_a_single_table;{{e3bf:cdd7e3}}  Loop through each table
        jr      c,_convert_token_to_keyword_text_ptr_12;{{e3c2:380e}}  (+$0e)
        inc     hl                ;{{e3c4:23}} 
        djnz    _convert_token_to_keyword_text_ptr_4;{{e3c5:10f8}}  (-$08)

        ld      hl,symbols_table  ;{{e3c7:2136e7}}  Also search symbols table
        call    search_within_a_single_table;{{e3ca:cdd7e3}} 
        jp      nc,Error_Syntax_Error;{{e3cd:d249cb}}  Not found: Syntax Error
        ld      b,$c0             ;{{e3d0:06c0}} "'" comment

_convert_token_to_keyword_text_ptr_12:;{{Addr=$e3d2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{e3d2:78}} 
        add     a,$40             ;{{e3d3:c640}} 
        pop     bc                ;{{e3d5:c1}} 
        ret                       ;{{e3d6:c9}} 

;;=search within a single table
search_within_a_single_table:     ;{{Addr=$e3d7 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{e3d7:7e}} 
        or      a                 ;{{e3d8:b7}} 
        ret     z                 ;{{e3d9:c8}}  Until trailing zero byte found

        push    hl                ;{{e3da:e5}} 
_search_within_a_single_table_4:  ;{{Addr=$e3db Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e3db:7e}} 
        inc     hl                ;{{e3dc:23}} 
        rla                       ;{{e3dd:17}}  Find byte with bit 7 set
        jr      nc,_search_within_a_single_table_4;{{e3de:30fb}}  (-$05)

        ld      a,(hl)            ;{{e3e0:7e}} 
        inc     hl                ;{{e3e1:23}} 
        cp      c                 ;{{e3e2:b9}}  Next byte is the token
        jr      z,_search_within_a_single_table_14;{{e3e3:2803}}  (+$03)
        pop     af                ;{{e3e5:f1}} 
        jr      search_within_a_single_table;{{e3e6:18ef}}  (-$11)

_search_within_a_single_table_14: ;{{Addr=$e3e8 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e3e8:e1}}  Entry found
        scf                       ;{{e3e9:37}} 
        ret                       ;{{e3ea:c9}} 

;;==========================================
;;keyword to token within single table
;;DE=ptr in buffer
;;HL=ptr to table
keyword_to_token_within_single_table:;{{Addr=$e3eb Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(de)            ;{{e3eb:1a}} End of buffer?
        or      a                 ;{{e3ec:b7}} 
        ret     z                 ;{{e3ed:c8}} 

        push    hl                ;{{e3ee:e5}} 
_keyword_to_token_within_single_table_4:;{{Addr=$e3ef Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{e3ef:1a}}  Get buffer char, skipping white space
        inc     de                ;{{e3f0:13}} 
        cp      $09               ;{{e3f1:fe09}} 
        jr      z,_keyword_to_token_within_single_table_10;{{e3f3:2804}}  (+$04)
        cp      $20               ;{{e3f5:fe20}} 
        jr      nz,test_letter_for_match;{{e3f7:2005}}  (+$05)
_keyword_to_token_within_single_table_10:;{{Addr=$e3f9 Code Calls/jump count: 1 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{e3f9:cd4dde}}  skip space, lf or tab
        jr      _keyword_to_token_within_single_table_4;{{e3fc:18f1}}  (-$0f)

;;-----------------------------------------------------
;;=test letter for match
test_letter_for_match:            ;{{Addr=$e3fe Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{e3fe:4f}} 
        ld      a,(hl)            ;{{e3ff:7e}} 
        inc     hl                ;{{e400:23}} 
        call    convert_character_to_upper_case;{{e401:cdabff}} ; convert character to upper case
        xor     c                 ;{{e404:a9}} ; character the same?
        jr      z,_keyword_to_token_within_single_table_4;{{e405:28e8}} match but not end of keyword - next character

;; character not the same?
        and     $7f               ;{{e407:e67f}} mask out bit 7 - end of word
        jr      z,entry_found     ;{{e409:280a}}  (+$0a) if it wasn't zero but now is the we've found word
        dec     de                ;{{e40b:1b}}  else skip to next entry
_test_letter_for_match_9:         ;{{Addr=$e40c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{e40c:1a}} 
        inc     de                ;{{e40d:13}} 
        rla                       ;{{e40e:17}} 
        jr      nc,_test_letter_for_match_9;{{e40f:30fb}}  (-$05)
        inc     de                ;{{e411:13}} 
        pop     hl                ;{{e412:e1}} 
        jr      keyword_to_token_within_single_table;{{e413:18d6}}  (-$2a)

;;=entry found
entry_found:                      ;{{Addr=$e415 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{e415:f1}} 
        scf                       ;{{e416:37}} 
        ret                       ;{{e417:c9}} 

;;===================
;; keyword table per letter
;; list of keywords sorted into alphabetical order
keyword_table_per_letter:         ;{{Addr=$e418 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defw keyword_table_A      ; AUTO, ATN, ASC, AND, AFTER, ABS
        defw keyword_table_B      ; BORDER, BIN$
        defw keyword_table_C      ; CURSOR, CREAL, COS, COPYCHR$, CONT, CLS, CLOSEOUT, CLOSEIN, CLG, CLEAR, CINT, CHR$, CHAIN, CAT, CALL
        defw keyword_table_D      ; DRAWR, DRAW, DIM, DI, DERR, DELETE, DEG, DEFSTR, DEFREAL, DEFINT, DEF, DEC$, DATA
        defw keyword_table_E      ; EXP, EVERY, ERROR, ERR, ERL, ERASE, EOF, ENV, ENT, END, ELSE, EI, EDIT
        defw keyword_table_F      ; FRE, FRAME, FOR, FN, FIX, FILL
        defw keyword_table_G      ; GRAPHICS, GOTO, GOSUB
        defw keyword_table_H      ; HIMEM, HEX$
        defw keyword_table_I      ; INT,INSTR, INPUT, INP, INKEY$, INKEY, INK, IF
        defw keyword_table_J      ; JOY
        defw keyword_table_K      ; KEY
        defw keyword_table_L      ; LOWER$, LOG10, LOG, LOCATE, LOAD, LIST, LINE, LET, LEN, LEFT$
        defw keyword_table_M      ; MOVER, MOVE, MODE, MOD, MIN, MID$, MERGE, MEMORY, MAX, MASK
        defw keyword_table_N      ; NOT, NEW, NEXT
        defw keyword_table_O      ; OUT, ORIGIN, OR, OPENOUT, OPENIN, ON SQ, ON ERROR GOTO, ON BREAK, ON
        defw keyword_table_P      ; PRINT, POS, POKE PLOTR, PLOT, PI, PEN, PEEK, PAPER
        defw keyword_table_Q      ; (no keywords defined)
        defw keyword_table_R      ; RUN, ROUND, RND, RIGHT$, RETURN, RESUME, RESTORE, RENUM, REMAIN, REM, RELEASE, READ, RANDOMIZE, RAD
        defw keyword_table_S      ; SYMBOL, SWAP, STRING$, STR$, STOP, STEP, SQR, SQ, SPEED, SPC, SPACE$, SOUND, SIN, SGN, SAVE
        defw keyword_table_T      ; TRON, TROFF, TO, TIME, THEN, TESTR, TEST, TAN, TAGOFF, TAG, TAB
        defw keyword_table_U      ; USING, UPPER$, UNT
        defw keyword_table_V      ; VPOS, VAL
        defw keyword_table_W      ; WRITE, WINDOW, WIDTH, WHILE, WEND, WAIT
        defw keyword_table_X      ; XPOS, XOR
        defw keyword_table_Y      ; YPOS
        defw keyword_table_Z      ; ZONE


;;======================================================================
;; Keyword table
;; list of keyword as text followed by keyword byte (token?)
;; end of list signalled with a 0 byte 
;;
;; - BASIC keyword stored excluding initial letter
;; e.g. "ZONE" is stored as "ONE"
;; - BASIC keyword stored with bit 7 of last letter of keyword set.
;; e.g. "ON","E"+$80 for ZONE
;; - keyword followed by keyword byte (token?)

;;=keyword table Z
keyword_table_Z:                  ;{{Addr=$e44c Data Calls/jump count: 0 Data use count: 2}}
                                  
        defb "ON","E"+$80,$da     ; ZONE
        defb 0                    

;;=keyword table Y
keyword_table_Y:                  ;{{Addr=$e451 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$48     ; YPOS
        defb 0                    

;;=keyword table X
keyword_table_X:                  ;{{Addr=$e456 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$47     ; XPOS
        defb "O","R"+$80,$fd      ; XOR
        defb 0                    

;;=keyword table W
keyword_table_W:                  ;{{Addr=$e45e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RIT","E"+$80,$d9    ; WRITE
        defb "INDO","W"+$80,$d8   ; WINDOW
        defb "IDT","H"+$80,$d7    ; WIDTH
        defb "HIL","E"+$80,$d6    ; WHILE
        defb "EN","D"+$80,$d5     ; WEND 
        defb "AI","T"+$80,$d4     ; WAIT
        defb 0                    

;;=keyword table V
keyword_table_V:                  ;{{Addr=$e47c Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$7f     ; VPOS
        defb "A","L"+$80,$1d      ; VAL
        defb 0                    

;;=keyword table U
keyword_table_U:                  ;{{Addr=$e484 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "SIN","G"+$80,$ed    ; USING
        defb "PPER","$"+$80,$1c   ; UPPER$
        defb "N","T"+$80,$1b      ; UNT
        defb 0                    

;;=keyword table T
keyword_table_T:                  ;{{Addr=$e493 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RO","N"+$80,$d3     ; TRON
        defb "ROF","F"+$80,$d2    ; TROFF
        defb "O"+$80,$ec          ; TO
        defb "IM","E"+$80,$46     ; TIME
        defb "HE","N"+$80,$eb     ; THEN
        defb "EST","R"+$80,$7d    ; TESTR
        defb "ES","T"+$80,$7c     ; TEST 
        defb "A","N"+$80,$1a      ; TAN
        defb "AGOF","F"+$80,$d1   ; TAFOFF
        defb "A","G"+$80,$d0      ; TAG
        defb "A","B"+$80,$ea      ; TAB
        defb 0                    

;;=keyword table S
keyword_table_S:                  ;{{Addr=$e4bf Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "YMBO","L"+$80,$cf   ; SYMBOL
        defb "WA","P"+$80,$e7     ; SWAP
        defb "TRING","$"+$80,$7b  ; STRING$
        defb "TR","$"+$80,$19     ; STR$
        defb "TO","P"+$80,$ce     ; STOP
        defb "TE","P"+$80,$e6     ; STEP
        defb "Q","R"+$80,$18      ; SQR
        defb "Q"+$80,$17          ; SQ
        defb "PEE","D"+$80,$cd    ; SPEED
        defb "P","C"+$80,$e5      ; SPC
        defb "PACE","$"+$80,$16   ; SPACE$
        defb "OUN","D"+$80,$cc    ; SOUND
        defb "I","N"+$80,$15      ; SIN
        defb "G","N"+$80,$14      ; SGN
        defb "AV","E"+$80,$cb     ; SAVE
        defb 0                    

;;=keyword table R
keyword_table_R:                  ;{{Addr=$e4ff Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "U","N"+$80,$ca      ; RUN
        defb "OUN","D"+$80,$7a    ; ROUND
        defb "N","D"+$80,$45      ; RND
        defb "IGHT","$"+$80,$79   ; RIGHT$
        defb "ETUR","N"+$80,$c9   ; RETURN
        defb "ESUM","E"+$80,$c8   ; RESUME
        defb "ESTOR","E"+$80,$c7  ; RESTORE
        defb "ENU","M"+$80,$c6    ; RENUM
        defb "EMAI","N"+$80,$13   ; REMAIN
        defb "E","M"+$80,$c5      ; REM
        defb "ELEAS","E"+$80,$c4  ; RELEASE
        defb "EA","D"+$80,$c3     ; READ
        defb "ANDOMIZ","E"+$80,$c2; RANDOMIZE
        defb "A","D"+$80,$c1      ; RAD
        defb 0                    

;;=keyword table Q
keyword_table_Q:                  ;{{Addr=$e549 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb 0                    

;;=keyword table P
keyword_table_P:                  ;{{Addr=$e54a Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RIN","T"+$80,$bf    ; PRINT
        defb "O","S"+$80,$78      ; POS
        defb "OK","E"+$80,$be     ; POKE
        defb "LOT","R"+$80,$bd    ; PLOTR
        defb "LO","T"+$80,$bc     ; PLOT
        defb "I"+$80,$44          ; PI
        defb "E","N"+$80,$bb      ; PEN 
        defb "EE","K"+$80,$12     ; PEEK
        defb "APE","R"+$80,$ba    ; PAPER
        defb 0                    

;;=keyword table O
keyword_table_O:                  ;{{Addr=$e56e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "U","T"+$80,$b9      ; OUT
        defb "RIGI","N"+$80,$b8   ; ORIGIN
        defb "R"+$80,$fc          ; OR
        defb "PENOU","T"+$80,$b7  ; OPENOUT
        defb "PENI","N"+$80,$b6   ; OPENIN
        defb "N S","Q"+$80,$b5    ; ON SQ
        defb "N ERROR GO",$09,"TO ","0"+$80,$b4; ON ERROR GOTO 0, ON ERROR GO TO 0 (but not ON ERROR GOTO/GO TO [n])
        defb "N BREA","K"+$80,$b3 ; ON BREAK
        defb "N"+$80,$b2          ; ON (and ON ERROR GOTO, ON ERROR GO TO)
        defb 0                    

;;=keyword table N
keyword_table_N:                  ;{{Addr=$e5a6 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "O","T"+$80,$fe      ; NOT
        defb "E","W"+$80,$b1      ; NEW
        defb "EX","T"+$80,$b0     ; NEXT
        defb 0                    

;;=keyword table M
keyword_table_M:                  ;{{Addr=$e5b1 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "OVE","R"+$80,$af    ; MOVER
        defb "OV","E"+$80,$ae     ; MOVE
        defb "OD","E"+$80,$ad     ; MODE
        defb "O","D"+$80,$fb      ; MOD
        defb "I","N"+$80,$77      ; MIN
        defb "ID","$"+$80,$ac     ; MID$
        defb "ERG","E"+$80,$ab    ; MERGE
        defb "EMOR","Y"+$80,$aa   ; MEMORY
        defb "A","X"+$80,$76      ; MAX
        defb "AS","K"+$80,$df     ; MASK
        defb 0                    

;;=keyword table L
keyword_table_L:                  ;{{Addr=$e5db Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "OWER","$"+$80,$11   ; LOWER$
        defb "OG1","0"+$80,$10    ; LOG10
        defb "O","G"+$80,$0f      ; LOG
        defb "OCAT","E"+$80,$a9   ; LOCATE
        defb "OA","D"+$80,$a8     ; LOAD
        defb "IS","T"+$80,$a7     ; LIST
        defb "IN","E"+$80,$a6     ; LINE
        defb "E","T"+$80,$a5      ; LET
        defb "E","N"+$80,$0e      ; LEN 
        defb "EFT","$"+$80,$75    ; LEFT$
        defb 0                    

;;=keyword table K
keyword_table_K:                  ;{{Addr=$e607 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "E","Y"+$80,$a4      ; KEY
        defb 0                    

;;=keyword table J
keyword_table_J:                  ;{{Addr=$e60b Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "O","Y"+$80,$0d      ; JOY
        defb 0                    

;;=keyword table I
keyword_table_I:                  ;{{Addr=$e60f Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "N","T"+$80,$0c      ; INT
        defb "NST","R"+$80,$74    ; INSTR
        defb "NPU","T"+$80,$a3    ; INPUT
        defb "N","P"+$80,$0b      ; INP
        defb "NKEY","$"+$80,$43   ; INKEY$
        defb "NKE","Y"+$80,$0a    ; INKEY
        defb "N","K"+$80,$a2      ; INK
        defb "F"+$80,$a1          ; IF
        defb 0                    

;;=keyword table H
keyword_table_H:                  ;{{Addr=$e630 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "IME","M"+$80,$42    ; HIMEM
        defb "EX","$"+$80,$73     ; HEX$
        defb 0                    

;;=keyword table G
keyword_table_G:                  ;{{Addr=$e63a Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RAPHIC","S"+$80,$de ; GRAPHICS
        defb "O",$09,"T","O"+$80,$a0;GO TO, GOTO
        defb "O",$09,"SU","B"+$80,$9f;GO SUB, GOSUB
        defb 0                    

;;=keyword table F
keyword_table_F:                  ;{{Addr=$e64e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "R","E"+$80,$09      ; FRE
        defb "RAM","E"+$80,$e0    ; FRAME
        defb "O","R"+$80,$9e      ; FOR
        defb "N"+$80,$e4          ; FN
        defb "I","X"+$80,$08      ; FIX
        defb "IL","L"+$80,$dd     ; FILL
        defb 0                    

;;=keyword table E
keyword_table_E:                  ;{{Addr=$e663 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "X","P"+$80,$07      ; EXP
        defb "VER","Y"+$80,$9d    ; EVERY
        defb "RRO","R"+$80,$9c    ; ERROR
        defb "R","R"+$80,$41      ; ERR
        defb "R","L"+$80,$e3      ; ERL
        defb "RAS","E"+$80,$9b    ; ERASE
        defb "O","F"+$80,$40      ; EOF
        defb "N","V"+$80,$9a      ; ENV
        defb "N","T"+$80,$99      ; ENT
        defb "N","D"+$80,$98      ; END
        defb "LS","E"+$80,$97     ; ELSE
        defb "I"+$80,$dc          ; EI
        defb "DI","T"+$80,$96     ; EDIT
        defb 0                    

;;=keyword table D
keyword_table_D:                  ;{{Addr=$e692 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RAW","R"+$80,$95    ; DRAWR
        defb "RA","W"+$80,$94     ; DRAW
        defb "I","M"+$80,$93      ; DIM
        defb "I"+$80,$db          ; DI
        defb "ER","R"+$80,$49     ; DERR
        defb "ELET","E"+$80,$92   ; DELETE
        defb "E","G"+$80,$91      ; DEG
        defb "EFST","R"+$80,$90   ; DEFSTR
        defb "EFREA","L"+$80,$8f  ; DEFREAL
        defb "EFIN","T"+$80,$8e   ; DEFINT
        defb "E","F"+$80,$8d      ; DEF
        defb "EC","$"+$80,$72     ; DEC$
        defb "AT","A"+$80,$8c     ; DATA
        defb 0                    

;;=keyword table C
keyword_table_C:                  ;{{Addr=$e6cc Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "URSO","R"+$80,$e1   ; CURSOR
        defb "REA","L"+$80,$06    ; CREAL
        defb "O","S"+$80,$05      ; COS
        defb "OPYCHR","$"+$80,$7e ; COPYCHR$
        defb "ON","T"+$80,$8b     ; CONT
        defb "L","S"+$80,$8a      ; CLS
        defb "LOSEOU","T"+$80,$89 ; CLOSEOUT
        defb "LOSEI","N"+$80,$88  ; CLOSEIN
        defb "L","G"+$80,$87      ; CLG
        defb "LEA","R"+$80,$86    ; CLEAR
        defb "IN","T"+$80,$04     ; CINT
        defb "HR","$"+$80,$03     ; CHR$
        defb "HAI","N"+$80,$85    ; CHAIN
        defb "A","T"+$80,$84      ; CAT
        defb "AL","L"+$80,$83     ; CALL
        defb 0                    

;;=keyword table B
keyword_table_B:                  ;{{Addr=$e715 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "ORDE","R"+$80,$82   ; BORDER
        defb "IN","$"+$80,$71     ; BIN$
        defb 0                    

;;=keyword table A
keyword_table_A:                  ;{{Addr=$e720 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "UT","O"+$80,$81     ; AUTO
        defb "T","N"+$80,$02      ; ATN
        defb "S","C"+$80,$01      ; ASC
        defb "N","D"+$80,$fa      ; AND
        defb "FTE","R"+$80,$80    ; AFTER
        defb "B","S"+$80,$00      ; ABS
        defb 0                    

;;=symbols table
symbols_table:                    ;{{Addr=$e736 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defb "^"+$80,$f8          ;
        defb $5c+$80,$f9          ; "\"
        defb ">",$09,"="+$80,$f0  ;
        defb "= ",">"+$80,$f0     ;
        defb ">"+$80,$ee          ;
        defb "<",$09,">"+$80,$f2  ;
        defb "<",$09,"="+$80,$f3  ;
        defb "= ","<"+$80,$f3     ;
        defb "="+$80,$ef          ;
        defb "<"+$80,$f1          ;
        defb "/"+$80,$f7          ;
        defb ":"+$80,$01          ;
        defb "*"+$80,$f6          ;
        defb "-"+$80,$f5          ;
        defb "+"+$80,$f4          ;
        defb "'"+$80,$c0          ;
        defb 0                    





