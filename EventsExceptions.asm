;;<< ERROR AND EVENT HANDLERS
;;< ON xx, DI, EI, AFTER, EVERY, REMAIN
;;========================================================================
;; command ON, ON ERROR GOTO
;(except ON ERROR GOTO 0!)

;ON <selector> GOTO <list of: <line number>>
;ON <selector> GOSUB <list of: <line number>>
;Choose on of a number of destinations based off a value.
;Value must be 0..255
;Value 1 selects the first target, 2 the second and so on.
;Value 0 or any value greater than the number of items in the list does nothing.

;ON ERROR GOTO <line number>
;Turns on error processing mode. Can be turned off with ON ERROR GOTO 0 (see elsewhere)
;The specified line will be jumped to when an error occurs. ERR and ERL can be used to 
;handle errors, or ERROR to invoke default error handling. RESUME can be used to return.

command_ON_ON_ERROR_GOTO:         ;{{Addr=$c882 Code Calls/jump count: 0 Data use count: 1}}
        cp      $9c               ;{{c882:fe9c}} token for ERROR
        jp      z,ON_ERROR_GOTO   ;{{c884:cab8cc}} 



        call    eval_expr_as_byte_or_error;{{c887:cdb8ce}}  get number and check it's less than 255 
        ld      c,a               ;{{c88a:4f}} C = index into list of item to goto/gosub
        ld      a,(hl)            ;{{c88b:7e}} 
        cp      $a0               ;{{c88c:fea0}} GOTO token
        push    af                ;{{c88e:f5}} 
        jr      z,_command_on_on_error_goto_11;{{c88f:2805}}  (+$05)

        call    next_token_if_equals_inline_data_byte;{{c891:cd25de}} 
        defb $9f                  ;Inline token to test "GOSUB"
        dec     hl                ;{{c895:2b}} 

;Loop reading line numbers and decrementing C until C gets to zero or we run out of items
_command_on_on_error_goto_11:     ;{{Addr=$c896 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c896:cd2cde}}  get next token skipping space
_command_on_on_error_goto_12:     ;{{Addr=$c899 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{c899:0d}} 
        jr      z,do_on_goto_gosub;{{c89a:280a}}  (+$0a)
        call    eval_line_number_or_error;{{c89c:cd48cf}} 
        call    next_token_if_prev_is_comma;{{c89f:cd41de}} 
        jr      c,_command_on_on_error_goto_12;{{c8a2:38f5}}  (-$0b)
        pop     af                ;{{c8a4:f1}} 
        ret                       ;{{c8a5:c9}} 

;;=do on goto gosub
do_on_goto_gosub:                 ;{{Addr=$c8a6 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_and_convert_line_number_to_line_address;{{c8a6:cd27e8}} 
        call    nz,skip_to_end_of_statement;{{c8a9:c4a3e9}} NZ means item not found - call DATA to 
                                  ;skip over list and contnue execution at the next line
        pop     af                ;{{c8ac:f1}} 
        jp      nz,GOSUB_HL       ;{{c8ad:c290c7}} Do a GOSUB
        ex      de,hl             ;{{c8b0:eb}} else do a GOTO
        ret                       ;{{c8b1:c9}} 

;;=prob process pending events
prob_process_pending_events:      ;{{Addr=$c8b2 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{c8b2:af}} 
        ld      (unknown_event_handler_data),a;{{c8b3:3216ac}} 

_prob_process_pending_events_2:   ;{{Addr=$c8b6 Code Calls/jump count: 1 Data use count: 0}}
        call    KL_NEXT_SYNC      ;{{c8b6:cdfbbc}}  firmware function: kl next sync 
        jr      nc,finished_processing_events;{{c8b9:301d}}  (+$1d)
        ld      b,a               ;{{c8bb:47}} 
        ld      a,(unknown_event_handler_data);{{c8bc:3a16ac}} 
        and     $7f               ;{{c8bf:e67f}} 
        ld      (unknown_event_handler_data),a;{{c8c1:3216ac}} 
        push    bc                ;{{c8c4:c5}} 
        push    hl                ;{{c8c5:e5}} 
        call    KL_DO_SYNC        ;{{c8c6:cdfebc}}  firmware function: kl do sync
        pop     hl                ;{{c8c9:e1}} 
        pop     bc                ;{{c8ca:c1}} 
        ld      a,(unknown_event_handler_data);{{c8cb:3a16ac}} 
        rla                       ;{{c8ce:17}} 
        push    af                ;{{c8cf:f5}} 
        ld      a,b               ;{{c8d0:78}} 
        call    nc,KL_DONE_SYNC   ;{{c8d1:d401bd}}  firmware function: kl done sync
        pop     af                ;{{c8d4:f1}} 
        rla                       ;{{c8d5:17}} 
        jr      nc,_prob_process_pending_events_2;{{c8d6:30de}}  (-$22) Loop for more

;;=finished processing events
finished_processing_events:       ;{{Addr=$c8d8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(unknown_event_handler_data);{{c8d8:3a16ac}} 
        and     $04               ;{{c8db:e604}} 
        call    nz,arm_break_handler;{{c8dd:c47fc4}} 
        ld      hl,(address_of_byte_before_current_statement);{{c8e0:2a1bae}} 
        ld      a,(unknown_event_handler_data);{{c8e3:3a16ac}} 
        and     $03               ;{{c8e6:e603}} 
        ret     z                 ;{{c8e8:c8}} 

        rra                       ;{{c8e9:1f}} 
        jp      c,unknown_execution_error;{{c8ea:da3ecc}} 
        inc     hl                ;{{c8ed:23}} 
        pop     af                ;{{c8ee:f1}} 
        jp      execute_line_atHL ;{{c8ef:c377de}} 

;;=do ON BREAK
;(Called after the break pause and then unpause)
do_ON_BREAK:                      ;{{Addr=$c8f2 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_location_holding_ROM_routine_),hl;{{c8f2:221cac}} 
        ld      a,$04             ;{{c8f5:3e04}} 
        jr      nc,poss_event_done;{{c8f7:3052}}  (+$52) ON BREAK STOP?

        ld      hl,(ON_BREAK_GOSUB_handler_line_address_);{{c8f9:2a1aac}} 
        ld      a,h               ;{{c8fc:7c}} 
        or      l                 ;{{c8fd:b5}} 
        call    nz,get_current_line_number;{{c8fe:c4b5de}} 
        ld      a,$41             ;{{c901:3e41}} 
        jr      nc,poss_event_done;{{c903:3046}}  (+$46) ON BREAK GOSUB

        push    bc                ;{{c905:c5}} ON BREAK CONTinue?
        call    SOUND_CONTINUE    ;{{c906:cdb9bc}}  firmware function: sound continue
        pop     bc                ;{{c909:c1}} 
        ld      de,unknown_ON_BREAK_GOSUB_data;{{c90a:1117ac}} 
        ld      c,$02             ;{{c90d:0e02}} 
        jr      handle_event_etc_GOSUBs;{{c90f:1822}}  (+$22)

;;=eval and setup event GOSUB handler
;Used by ON SQ, AFTER and EVERY
;evals the gosub and line number and stores in the relevant event data block
;DE=event data block address?
eval_and_setup_event_GOSUB_handler:;{{Addr=$c911 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{c911:d5}} 
        call    next_token_if_equals_inline_data_byte;{{c912:cd25de}} 
        defb $9f                  ;Inline token to test "GOSUB"
        call    eval_and_convert_line_number_to_line_address;{{c916:cd27e8}} 
        ld      b,d               ;{{c919:42}} 
        ld      c,e               ;{{c91a:4b}} 
        pop     de                ;{{c91b:d1}} 
        push    hl                ;{{c91c:e5}} 
        ld      hl,$000a          ;{{c91d:210a00}} 
        add     hl,de             ;{{c920:19}} 
        ld      (hl),c            ;{{c921:71}} 
        inc     hl                ;{{c922:23}} 
        ld      (hl),b            ;{{c923:70}} 
        pop     hl                ;{{c924:e1}} 
        ret                       ;{{c925:c9}} 

;;==============================================
;;event handler routine
;Called by the firmware for events
event_handler_routine:            ;{{Addr=$c926 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{c926:23}} 
        inc     hl                ;{{c927:23}} 
        inc     hl                ;{{c928:23}} 
        ex      de,hl             ;{{c929:eb}} 
        call    get_current_line_number;{{c92a:cdb5de}} 
        ld      a,$40             ;{{c92d:3e40}} 
        jr      nc,poss_event_done;{{c92f:301a}}  (+$1a)
        ld      c,$01             ;{{c931:0e01}} GOSUB type

;;=handle event etc GOSUBs
;C specifies gosub type
;DE=address to store data for this event type
handle_event_etc_GOSUBs:          ;{{Addr=$c933 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c933:d5}} 
        call    special_GOSUB_HL  ;{{c934:cd93c7}} 
        ld      hl,(address_of_byte_before_current_statement);{{c937:2a1bae}} 
        ex      de,hl             ;{{c93a:eb}} 
        pop     hl                ;{{c93b:e1}} 
        ld      (hl),b            ;{{c93c:70}} 
        inc     hl                ;{{c93d:23}} 
        ld      (hl),e            ;{{c93e:73}} 
        inc     hl                ;{{c93f:23}} 
        ld      (hl),d            ;{{c940:72}} 
        inc     hl                ;{{c941:23}} 
        ld      e,(hl)            ;{{c942:5e}} 
        inc     hl                ;{{c943:23}} 
        ld      d,(hl)            ;{{c944:56}} 
        ex      de,hl             ;{{c945:eb}} 
        ld      (address_of_byte_before_current_statement),hl;{{c946:221bae}} 
        ld      a,$c2             ;{{c949:3ec2}} 

;;=poss event done?
poss_event_done:                  ;{{Addr=$c94b Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,unknown_event_handler_data;{{c94b:2116ac}} 
        or      (hl)              ;{{c94e:b6}} 
        ld      (hl),a            ;{{c94f:77}} 
        ret                       ;{{c950:c9}} 

;;=prob RETURN from event handler
;RETURN statement executed in an event handler
prob_RETURN_from_event_handler:   ;{{Addr=$c951 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{c951:7e}} 
        inc     hl                ;{{c952:23}} 
        ld      e,(hl)            ;{{c953:5e}} 
        inc     hl                ;{{c954:23}} 
        ld      d,(hl)            ;{{c955:56}} 
        push    de                ;{{c956:d5}} 
        ld      bc,$fff7          ;{{c957:01f7ff}} ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{c95a:09}} 
        call    KL_DONE_SYNC      ;{{c95b:cd01bd}}  firmware function: KL DONE SYNC
        pop     hl                ;{{c95e:e1}} 
        jr      _prob_return_from_break_handler_7;{{c95f:1811}}  (+$11)

;;=prob RETURN from break handler
prob_RETURN_from_break_handler:   ;{{Addr=$c961 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{c961:7e}} 
        ld      hl,(address_of_location_holding_ROM_routine_);{{c962:2a1cac}} 
        ld      bc,$fffc          ;{{c965:01fcff}}  JP (BC) ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{c968:09}} 
        call    KL_DONE_SYNC      ;{{c969:cd01bd}}  firmware function: KL DONE SYNC
        call    arm_break_handler ;{{c96c:cd7fc4}} 
        ld      hl,(prob_cache_of_current_execution_addr_dur);{{c96f:2a18ac}} 
_prob_return_from_break_handler_7:;{{Addr=$c972 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{c972:f1}} 
        jp      execute_statement_atHL;{{c973:c360de}} 

;;========================================================================
;; command ON BREAK GOSUB, ON BREAK CONT, ON BREAK STOP
;ON BREAK GOSUB <line number>
;ON BREAK STOP
;Performs the specified action when [ESC][ESC] is pressed

command_ON_BREAK_GOSUB_ON_BREAK_CONT_ON_BREAK_STOP:;{{Addr=$c976 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_on_break_gosub_on_break_cont_on_break_stop_2;{{c976:cd7cc9}} 
        jp      get_next_token_skipping_space;{{c979:c32cde}}  get next token skipping space

_command_on_break_gosub_on_break_cont_on_break_stop_2:;{{Addr=$c97c Code Calls/jump count: 1 Data use count: 0}}
        cp      $8b               ;{{c97c:fe8b}}  token for "CONT"
        jp      z,ON_BREAK_CONT   ;{{c97e:cad0c4}}  ON BREAK CONT

        cp      $ce               ;{{c981:fece}}  token for "STOP"
        ld      de,$0000          ;{{c983:110000}} ##LIT##
        jr      z,set_ON_BREAK_handler_line_address;{{c986:2808}}  ON BREAK STOP

;; 
        call    next_token_if_equals_inline_data_byte;{{c988:cd25de}} 
        defb $9f                  ; token for "GOSUB"
        call    eval_and_convert_line_number_to_line_address;{{c98c:cd27e8}} 
        dec     hl                ;{{c98f:2b}} 

;;=set ON BREAK handler line address
set_ON_BREAK_handler_line_address:;{{Addr=$c990 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ON_BREAK_GOSUB_handler_line_address_),de;{{c990:ed531aac}} 
        jp      ON_BREAK_STOP     ;{{c994:c3d3c4}}  ON BREAK STOP


;;EVENTS
;;========================================================================
;; command DI
;DI
;Disables interrupts (BASIC interrupts, not system/machine code interrupts)
;Does not affect break interrupts (ESC key)
;If interrupts are disabled in an interrupt handler subroutine they are
;implicitly re-enabled by the terminating RETURN statement

command_DI:                       ;{{Addr=$c997 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c997:e5}} 
        call    KL_EVENT_DISABLE  ;{{c998:cd04bd}}  firmware function: KL EVENT DISABLE
        pop     hl                ;{{c99b:e1}} 
        ret                       ;{{c99c:c9}} 

;;========================================================================
;; command EI
;EI
;Enables interrupts which have been disabled by DI
;See DI

command_EI:                       ;{{Addr=$c99d Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c99d:e5}} 
        call    KL_EVENT_ENABLE   ;{{c99e:cd07bd}}  firmware function: KL EVENT ENABLE
        pop     hl                ;{{c9a1:e1}} 
        ret                       ;{{c9a2:c9}} 

;;========================================================================
;;initialise event system
initialise_event_system:          ;{{Addr=$c9a3 Code Calls/jump count: 1 Data use count: 0}}
        call    SOUND_RESET       ;{{c9a3:cda7bc}}  firmware function: SOUND RESET
        ld      hl,Ticker_and_Event_Block_for_AFTEREVERY_T;{{c9a6:2142ac}} 
        ld      b,$04             ;{{c9a9:0604}} 

;;delete sound events loop
_initialise_event_system_3:       ;{{Addr=$c9ab Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c9ab:e5}} 
        call    KL_DEL_TICKER     ;{{c9ac:cdecbc}}  firmware function: KL DEL TICKER
        pop     hl                ;{{c9af:e1}} 
        ld      de,$0012          ;{{c9b0:111200}} 
        add     hl,de             ;{{c9b3:19}} 
        djnz    _initialise_event_system_3;{{c9b4:10f5}} 

        call    KM_DISARM_BREAK   ;{{c9b6:cd48bb}}  firmware function: KL DISARM BREAK
        call    KL_SYNC_RESET     ;{{c9b9:cdf5bc}}  firmware function: KL SYNC RESET
        ld      hl,$0000          ;{{c9bc:210000}} ##LIT##
        ld      (ON_BREAK_GOSUB_handler_line_address_),hl;{{c9bf:221aac}} 
        call    arm_break_handler ;{{c9c2:cd7fc4}} 
        ld      hl,CEvent_Block_for_ON_SQ;{{c9c5:211eac}} 
        ld      de,$0305          ;{{c9c8:110503}} 
        ld      bc,$0800          ;{{c9cb:010008}} 
        call    Initialise_event_blocks;{{c9ce:cddac9}} 
        ld      hl,chain_address_to_next_ticker_block;{{c9d1:2148ac}} address of event block
        ld      de,$040b          ;{{c9d4:110b04}} 
        ld      bc,$0201          ;{{c9d7:010102}} B = event class

;;=Initialise event blocks
;D=count of event blocks to initialise
Initialise_event_blocks:          ;{{Addr=$c9da Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{c9da:c5}} 
        push    de                ;{{c9db:d5}} 
        ld      c,$fd             ;{{c9dc:0efd}} ROM select address
        ld      de,event_handler_routine;{{c9de:1126c9}} address of event routine ##LLABEL##;WARNING: Code area used as literal
        call    KL_INIT_EVENT     ;{{c9e1:cdefbc}}  firmware function: KL INIT EVENT 
        pop     de                ;{{c9e4:d1}} 
        push    de                ;{{c9e5:d5}} 
        ld      d,$00             ;{{c9e6:1600}} 
        add     hl,de             ;{{c9e8:19}} 
        pop     de                ;{{c9e9:d1}} 
        pop     bc                ;{{c9ea:c1}} 
        ld      a,c               ;{{c9eb:79}} 
        or      a                 ;{{c9ec:b7}} 
        jr      z,_initialise_event_blocks_15;{{c9ed:2802}}  (+$02)
        rlc     b                 ;{{c9ef:cb00}} 
_initialise_event_blocks_15:      ;{{Addr=$c9f1 Code Calls/jump count: 1 Data use count: 0}}
        dec     d                 ;{{c9f1:15}} 
        jr      nz,Initialise_event_blocks;{{c9f2:20e6}}  (-$1a) Loop for next block
        ret                       ;{{c9f4:c9}} 

;;========================================================================
;; command ON SQ
;ON SQ(<channel>) GOSUB <line number>
;channel number = 1,2,4 for channels A, B, or C
;Enables an interrupt for when there is a free slot in the given sound queue.
;The SOUND command and SQ function disable ON SQ interrupts

command_ON_SQ:                    ;{{Addr=$c9f5 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{c9f5:cd19de}}  check for open bracket
        call    eval_expr_as_byte_or_error;{{c9f8:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{c9fb:f5}} 
        call    get_event_block_for_channel;{{c9fc:cd10ca}} 
        or      a                 ;{{c9ff:b7}} 
        jr      nz,raise_improper_argument_error_B;{{ca00:201d}}  (+$1d)
        call    next_token_if_close_bracket;{{ca02:cd1dde}}  check for close bracket
        call    eval_and_setup_event_GOSUB_handler;{{ca05:cd11c9}} Read GOSUB and address and set up
        pop     af                ;{{ca08:f1}} 
        push    hl                ;{{ca09:e5}} 
        ex      de,hl             ;{{ca0a:eb}} 
        call    SOUND_ARM_EVENT   ;{{ca0b:cdb0bc}}  firmware function: sound arm event
        pop     hl                ;{{ca0e:e1}} 
        ret                       ;{{ca0f:c9}} 

;;=get event block for channel
get_event_block_for_channel:      ;{{Addr=$ca10 Code Calls/jump count: 1 Data use count: 0}}
        rra                       ;{{ca10:1f}} 
        ld      de,CEvent_Block_for_ON_SQ;{{ca11:111eac}} 
        ret     c                 ;{{ca14:d8}} 

        rra                       ;{{ca15:1f}} 
        ld      de,cevent_block_for_on_sq_B;{{ca16:112aac}} 
        ret     c                 ;{{ca19:d8}} 

        rra                       ;{{ca1a:1f}} 
        ld      de,cevent_block_for_on_sq_C;{{ca1b:1136ac}} 
        ret     c                 ;{{ca1e:d8}} 

;;=raise Improper argument error
raise_improper_argument_error_B:  ;{{Addr=$ca1f Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Improper_Argument;{{ca1f:c34dcb}}  Error: Improper Argument

;;==================================================================
;; command AFTER
;AFTER <time delay>[,<timer number>] GOSUB <line number>
;Call a subroutine after the specified period in 1/50ths of a second
;Timer number 0-3, default 0. Timer 3 has highest priority, 0 the lowest.

command_AFTER:                    ;{{Addr=$ca22 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_positive_int_or_error;{{ca22:cdcece}} Get delay
        ld      bc,$0000          ;{{ca25:010000}} ##LIT##
        jr      init_timer_event  ;{{ca28:1805}}  (+$05)

;;==================================================================
;; command EVERY
;EVERY <time delay>[,<timer number>] GOSUB <line number>
;Call a subroutine at regular intervals, given in 1/50ths of a second
;Timer number 0-3, default 0

command_EVERY:                    ;{{Addr=$ca2a Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_positive_int_or_error;{{ca2a:cdcece}} Get period
        ld      b,d               ;{{ca2d:42}} 
        ld      c,e               ;{{ca2e:4b}} 

;;=init timer event
init_timer_event:                 ;{{Addr=$ca2f Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ca2f:d5}} 
        push    bc                ;{{ca30:c5}} 
        call    next_token_if_prev_is_comma;{{ca31:cd41de}} 
        ld      de,$0000          ;{{ca34:110000}} ##LIT##
        call    c,eval_expr_as_int;{{ca37:dcd8ce}}  get timer number
        ex      de,hl             ;{{ca3a:eb}} 
        call    calc_AFTEREVERY_ticker_block_address;{{ca3b:cd62ca}} 

        push    hl                ;{{ca3e:e5}} 
        ld      bc,$0006          ;{{ca3f:010600}} 
        add     hl,bc             ;{{ca42:09}} 
        ex      de,hl             ;{{ca43:eb}} 
        call    eval_and_setup_event_GOSUB_handler;{{ca44:cd11c9}} 
        pop     de                ;{{ca47:d1}} 
        pop     bc                ;{{ca48:c1}} 
        ex      (sp),hl           ;{{ca49:e3}} 
        ex      de,hl             ;{{ca4a:eb}} 
        call    KL_ADD_TICKER     ;{{ca4b:cde9bc}}  firmware function: kl add ticker
        pop     hl                ;{{ca4e:e1}} 
        ret                       ;{{ca4f:c9}} 

;;========================================================
;; function REMAIN
;REMAIN(<timer number>)
;Gets the timer remaining count for a timer.
;Values 0..3
;Returns zero if the timer was not enabled

function_REMAIN:                  ;{{Addr=$ca50 Code Calls/jump count: 0 Data use count: 1}}
        call    function_CINT     ;{{ca50:cdb6fe}} 
        call    calc_AFTEREVERY_ticker_block_address;{{ca53:cd62ca}} 
        call    KL_DEL_TICKER     ;{{ca56:cdecbc}}  firmware function: kl del ticker
        jr      c,_function_remain_5;{{ca59:3803}}  (+$03)
        ld      de,$0000          ;{{ca5b:110000}} ##LIT##
_function_remain_5:               ;{{Addr=$ca5e Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ca5e:eb}} 
        jp      store_HL_in_accumulator_as_INT;{{ca5f:c335ff}} 

;;=calc AFTER/EVERY ticker block address
;HL=ticker block number (0-3)
;out: HL=address
calc_AFTEREVERY_ticker_block_address:;{{Addr=$ca62 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{ca62:7c}} 
        or      a                 ;{{ca63:b7}} 
        jr      nz,raise_improper_argument_error_B;{{ca64:20b9}}  (-$47)
        ld      a,l               ;{{ca66:7d}} 
        cp      $04               ;{{ca67:fe04}} 
        jr      nc,raise_improper_argument_error_B;{{ca69:30b4}}  (-$4c)
        add     a,a               ;{{ca6b:87}} Calc offset/address within ticker block
        add     a,a               ;{{ca6c:87}} 
        add     a,a               ;{{ca6d:87}} 
        add     a,l               ;{{ca6e:85}} 
        add     a,a               ;{{ca6f:87}} 
        ld      l,a               ;{{ca70:6f}} 
        ld      bc,Ticker_and_Event_Block_for_AFTEREVERY_T;{{ca71:0142ac}} 
        add     hl,bc             ;{{ca74:09}} 
        ret                       ;{{ca75:c9}} 




