;;<< (TEXT) STREAM MANAGEMENT
;;=========================================
;;select txt stream zero
select_txt_stream_zero:           ;{{Addr=$c1a1 Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{c1a1:af}} 
        call    swap_input_streams;{{c1a2:cdb3c1}} 
        xor     a                 ;{{c1a5:af}} 
;;=select txt stream
select_txt_stream:                ;{{Addr=$c1a6 Code Calls/jump count: 7 Data use count: 0}}
        push    hl                ;{{c1a6:e5}} 
        push    af                ;{{c1a7:f5}} 
        cp      $08               ;{{c1a8:fe08}} 
        call    c,TXT_STR_SELECT  ;{{c1aa:dcb4bb}}  firmware function: txt str select
        pop     af                ;{{c1ad:f1}} 
        ld      hl,current_output_stream_;{{c1ae:2106ac}} 
        jr      swap_stream_number_atHL;{{c1b1:1804}}  (+$04)

;;==========================================
;;swap input streams
swap_input_streams:               ;{{Addr=$c1b3 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{c1b3:e5}} 
        ld      hl,current_input_stream_;{{c1b4:2107ac}} 

;;=swap stream number atHL
swap_stream_number_atHL:          ;{{Addr=$c1b7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c1b7:d5}} 
        ld      e,a               ;{{c1b8:5f}} 
        ld      a,(hl)            ;{{c1b9:7e}} 
        ld      (hl),e            ;{{c1ba:73}} 
        pop     de                ;{{c1bb:d1}} 
        pop     hl                ;{{c1bc:e1}} 
        ret                       ;{{c1bd:c9}} 

;;-----------------------------------------------------------------
;;=get output stream
get_output_stream:                ;{{Addr=$c1be Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(current_output_stream_);{{c1be:3a06ac}} 
        cp      $08               ;{{c1c1:fe08}} 
        ret                       ;{{c1c3:c9}} 

;;-----------------------------------------------------------------
;;=get input stream
;returns Carry clear if stream is on screen, Carry set if not on screen (i.e. a file)
get_input_stream:                 ;{{Addr=$c1c4 Code Calls/jump count: 7 Data use count: 0}}
        ld      a,(current_input_stream_);{{c1c4:3a07ac}} 
        cp      $09               ;{{c1c7:fe09}} 
        ret                       ;{{c1c9:c9}} 

;;-----------------------------------------------------------------
;;=eval and select txt stream
eval_and_select_txt_stream:       ;{{Addr=$c1ca Code Calls/jump count: 1 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1ca:cdfbc1}} 
        jr      select_txt_stream ;{{c1cd:18d7}}  (-$29)

;;=exec following on evalled stream and swap back
exec_following_on_evalled_stream_and_swap_back:;{{Addr=$c1cf Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1cf:cdfbc1}} 
        jr      exec_TOS_on_stream_and_swap_back;{{c1d2:1818}}  (+$18)

;;=swap both streams, exec TOS and swap back
swap_both_streams_exec_TOS_and_swap_back:;{{Addr=$c1d4 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1d4:cdfbc1}} 
        call    swap_input_streams;{{c1d7:cdb3c1}} 
        pop     bc                ;{{c1da:c1}} 
        push    af                ;{{c1db:f5}} 
        call    get_input_stream  ;{{c1dc:cdc4c1}} 
        call    exec_BC_on_stream_and_swap_back;{{c1df:cdedc1}} 
        pop     af                ;{{c1e2:f1}} 
        jr      swap_input_streams;{{c1e3:18ce}}  (-$32)


;;===============================================
;;=exec TOS on evalled stream and swap back
exec_TOS_on_evalled_stream_and_swap_back:;{{Addr=$c1e5 Code Calls/jump count: 8 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1e5:cdfbc1}} 
        cp      $08               ;{{c1e8:fe08}} 
        jr      nc,raise_Improper_Argument_error;{{c1ea:3031}}  (+$31)
;;=exec TOS on stream and swap back
exec_TOS_on_stream_and_swap_back: ;{{Addr=$c1ec Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{c1ec:c1}} 
;;=exec BC on stream and swap back
exec_BC_on_stream_and_swap_back:  ;{{Addr=$c1ed Code Calls/jump count: 1 Data use count: 0}}
        call    select_txt_stream ;{{c1ed:cda6c1}} 
        push    af                ;{{c1f0:f5}} 
        ld      a,(hl)            ;{{c1f1:7e}} 
        cp      $2c               ;{{c1f2:fe2c}}  ','
        call    JP_BC             ;{{c1f4:cdfcff}}  JP (BC)
        pop     af                ;{{c1f7:f1}} 
        jp      select_txt_stream ;{{c1f8:c3a6c1}} 

;;======================================
;;=eval and validate stream number if present
eval_and_validate_stream_number_if_present:;{{Addr=$c1fb Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{c1fb:7e}} 
        cp      $23               ;{{c1fc:fe23}}  #
        ld      a,$00             ;{{c1fe:3e00}} 
        ret     nz                ;{{c200:c0}} 

        call    eval_and_validate_stream_number;{{c201:cd0dc2}} 
        push    af                ;{{c204:f5}} 
        call    next_token_if_prev_is_comma;{{c205:cd41de}} 
        call    nc,error_if_not_end_of_statement_or_eoln;{{c208:d437de}} 
        pop     af                ;{{c20b:f1}} 
        ret                       ;{{c20c:c9}} 

;;====================================
;;=eval and validate stream number
eval_and_validate_stream_number:  ;{{Addr=$c20d Code Calls/jump count: 3 Data use count: 0}}
        call    next_token_if_equals_inline_data_byte;{{c20d:cd25de}} 
        defb $23                  ;Inline token to test "#"

        ld      a,$0a             ;{{c211:3e0a}} 
;;=check byte value in range.
;; if not give "Improper Argument" error message
;; In: A = max value
;; Out: A = value if in range
check_byte_value_in_range:        ;{{Addr=$c213 Code Calls/jump count: 6 Data use count: 0}}
        push    bc                ;{{c213:c5}} 
        push    de                ;{{c214:d5}} 
        ld      b,a               ;{{c215:47}} 
        call    eval_expr_as_byte_or_error;{{c216:cdb8ce}}  get number and check it's less than 255 
        cp      b                 ;{{c219:b8}}  compare to value we want
        pop     de                ;{{c21a:d1}} 
        pop     bc                ;{{c21b:c1}} 
        ret     c                 ;{{c21c:d8}} ; return if less than value

;; greater than value
;;=raise Improper Argument error
raise_Improper_Argument_error:    ;{{Addr=$c21d Code Calls/jump count: 2 Data use count: 0}}
        jp      Error_Improper_Argument;{{c21d:c34dcb}}  Error: Improper Argument

;;========================================================================
;; check number is less than 2
check_number_is_less_than_2:      ;{{Addr=$c220 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,$02             ;{{c220:3e02}} 
        jr      check_byte_value_in_range;{{c222:18ef}}  check value is in range        





