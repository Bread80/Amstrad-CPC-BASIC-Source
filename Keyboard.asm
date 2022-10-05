;;<< LOW LEVEL KEYBOARD HANDLING
;;< including BREAK key handler
;;=======================================================================================
;;jp km read char
jp_km_read_char:                  ;{{Addr=$c46f Code Calls/jump count: 1 Data use count: 0}}
        jp      KM_READ_CHAR      ;{{c46f:c309bb}}  firmware function: km read char

;;=======================================================================================
;;test for break key
test_for_break_key:               ;{{Addr=$c472 Code Calls/jump count: 2 Data use count: 0}}
        call    KM_READ_CHAR      ;{{c472:cd09bb}}  firmware function: km read char
        ret     nc                ;{{c475:d0}} 
        cp      $fc               ;{{c476:fefc}} Break?
        ret     nz                ;{{c478:c0}} 
        call    break_pause       ;{{c479:cda1c4}}  key
        jp      c,unknown_execution_error;{{c47c:da3ecc}} 

;;=arm break handler
arm_break_handler:                ;{{Addr=$c47f Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{c47f:e5}} 
;;=arm break handler
arm_break_handler_B:              ;{{Addr=$c480 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{c480:c5}} 
        push    de                ;{{c481:d5}} 
        ld      de,break_handling_routine;{{c482:1192c4}} ##LABEL##
        ld      c,$fd             ;{{c485:0efd}} ROM select address for break handling routine
        ld      a,(ON_BREAK_flag_);{{c487:3a0bac}} &00=ON BREAK CONTINUE, else ON BREAK STOP
        or      a                 ;{{c48a:b7}} 
        call    nz,KM_ARM_BREAK   ;{{c48b:c445bb}}  firmware function: km arm break
        pop     de                ;{{c48e:d1}} 
        pop     bc                ;{{c48f:c1}} 
        pop     hl                ;{{c490:e1}} 
        ret                       ;{{c491:c9}} 

;;=======================================================================================
;;break handling routine
;Called from firmware break handler

;Clear any characters in the input buffer prior to the break key being pressed
break_handling_routine:           ;{{Addr=$c492 Code Calls/jump count: 1 Data use count: 1}}
        call    KM_READ_CHAR      ;{{c492:cd09bb}}  firmware function: km read char
        jr      nc,_break_handling_routine_4;{{c495:3004}}  (+$04) No key available  
        cp      $ef               ;{{c497:feef}}  
        jr      nz,break_handling_routine;{{c499:20f7}}  (-$09) Loop until $ef. Code for break key.

_break_handling_routine_4:        ;{{Addr=$c49b Code Calls/jump count: 1 Data use count: 0}}
        call    break_pause       ;{{c49b:cda1c4}}  wait for second break, or resume
        jp      do_ON_BREAK       ;{{c49e:c3f2c8}} 

;;=======================================================================================
;;=break pause
;Wait for second break key (break)
;or any other key (continue execution)
break_pause:                      ;{{Addr=$c4a1 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{c4a1:c5}} 
        push    de                ;{{c4a2:d5}} 
        push    hl                ;{{c4a3:e5}} 
        call    SOUND_HOLD        ;{{c4a4:cdb6bc}}  firmware function: sound hold
        push    af                ;{{c4a7:f5}} 
        call    TXT_ASK_STATE     ;{{c4a8:cd40bd}}  firmware function: txt ask state
        ld      b,a               ;{{c4ab:47}} 
        call    TXT_CUR_ON        ;{{c4ac:cd81bb}}  firmware function: txt cur on
_break_pause_8:                   ;{{Addr=$c4af Code Calls/jump count: 1 Data use count: 0}}
        call    KM_WAIT_CHAR      ;{{c4af:cd06bb}}  firmware function: km wait char
        cp      $ef               ;{{c4b2:feef}} token for '='
        jr      z,_break_pause_8  ;{{c4b4:28f9}}  (-$07)
        bit     1,b               ;{{c4b6:cb48}} 
        call    nz,TXT_CUR_OFF    ;{{c4b8:c484bb}}  firmware function: txt cur off
        cp      $fc               ;{{c4bb:fefc}} 
        scf                       ;{{c4bd:37}} 
        jr      z,_break_pause_22 ;{{c4be:280b}}  (+$0b)
        cp      $20               ;{{c4c0:fe20}}  ' ' 
        call    nz,KM_CHAR_RETURN ;{{c4c2:c40cbb}}  firmware function: km char return
        pop     af                ;{{c4c5:f1}} 
        push    af                ;{{c4c6:f5}} 
        call    c,SOUND_CONTINUE  ;{{c4c7:dcb9bc}}  firmware function: sound continue
        or      a                 ;{{c4ca:b7}} 
_break_pause_22:                  ;{{Addr=$c4cb Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c4cb:e1}} 
        pop     hl                ;{{c4cc:e1}} 
        pop     de                ;{{c4cd:d1}} 
        pop     bc                ;{{c4ce:c1}} 
        ret                       ;{{c4cf:c9}} 

;;========================================================================
;; ON BREAK CONT
ON_BREAK_CONT:                    ;{{Addr=$c4d0 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{c4d0:af}} 
        jr      _on_break_stop_1  ;{{c4d1:1802}}  (+$02)

;;========================================================================
;; ON BREAK STOP
ON_BREAK_STOP:                    ;{{Addr=$c4d3 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$ff             ;{{c4d3:3eff}} 
;;------------------------------------------------------------------------
_on_break_stop_1:                 ;{{Addr=$c4d5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ON_BREAK_flag_),a;{{c4d5:320bac}} 
        push    hl                ;{{c4d8:e5}} 
        call    KM_DISARM_BREAK   ;{{c4d9:cd48bb}}  firmware function: km disarm break
        jr      arm_break_handler_B;{{c4dc:18a2}}  (-$5e)




