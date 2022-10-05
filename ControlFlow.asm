;;<< CONTROL FLOW
;;< FOR, IF, GOTO, GOSUB, WHILE
;;========================================================================
;; command FOR
;FOR <simple variable>=<start> TO <end> [STEP <step size>]
;Variable and values can be integer or real.
;The matching NEXT is established when executing the FOR, and is the next matching 
;NEXT (taking account of nesting) sequentially in the program code, ignoring order 
;of execution.
;Terminates when the variable is >= the end value (positive step) or 
;<= the end value (negative step)
;The FOR loop can be terminated by avoiding the NEXT

command_FOR:                      ;{{Addr=$c5d4 Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_or_alloc_FOR_var;{{c5d4:cdecd6}} 
        push    hl                ;{{c5d7:e5}} 
        push    bc                ;{{c5d8:c5}} 
        push    de                ;{{c5d9:d5}} 
        call    find_matching_NEXT;{{c5da:cd76ca}} 
        ld      (address_of_colon_or_line_end_byte_after_),hl;{{c5dd:2212ac}} 
        push    de                ;{{c5e0:d5}} 
        push    hl                ;{{c5e1:e5}} 
        ex      de,hl             ;{{c5e2:eb}} 
        call    get_execution_stack_data;{{c5e3:cdd9c6}} 
        call    z,set_execution_stack_next_free_ptr_and_its_cache;{{c5e6:cc5df6}} 
        pop     hl                ;{{c5e9:e1}} 
        call    is_next_02        ;{{c5ea:cd3dde}} 
        ld      de,$0000          ;{{c5ed:110000}} ##LIT##
        call    nc,parse_and_find_or_create_a_var;{{c5f0:d4bfd6}} 
        ld      b,h               ;{{c5f3:44}} 
        ld      c,l               ;{{c5f4:4d}} 
        pop     hl                ;{{c5f5:e1}} 
        ex      (sp),hl           ;{{c5f6:e3}} 
        ld      a,d               ;{{c5f7:7a}} 
        or      e                 ;{{c5f8:b3}} 
        call    nz,compare_HL_DE  ;{{c5f9:c4d8ff}}  HL=DE?
        jp      nz,raise_Unexpected_NEXT;{{c5fc:c29ec6}} 

        ex      de,hl             ;{{c5ff:eb}} 
        call    get_current_line_address;{{c600:cdb1de}} 
        ex      (sp),hl           ;{{c603:e3}} 
        call    set_current_line_address;{{c604:cdadde}} 
        pop     hl                ;{{c607:e1}} 
        pop     af                ;{{c608:f1}} 
        ex      (sp),hl           ;{{c609:e3}} 
        push    de                ;{{c60a:d5}} 
        push    bc                ;{{c60b:c5}} 
        push    hl                ;{{c60c:e5}} 
        ld      bc,$1605          ;{{c60d:010516}} 
        cp      c                 ;{{c610:b9}} 
        jr      z,_command_for_40 ;{{c611:2809}}  (+$09)

        ld      bc,$1002          ;{{c613:010210}} B=bytes to allocate on execution stack. C=int variable type
        cp      c                 ;{{c616:b9}} 
        ld      a,$0d             ;{{c617:3e0d}} Type mismatch error
        jp      nz,raise_error    ;{{c619:c255cb}} 

_command_for_40:                  ;{{Addr=$c61c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{c61c:78}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c61d:cd72f6}} 
        ld      (hl),e            ;{{c620:73}} 
        inc     hl                ;{{c621:23}} 
        ld      (hl),d            ;{{c622:72}} 
        inc     hl                ;{{c623:23}} 
        ex      (sp),hl           ;{{c624:e3}} 

        call    next_token_if_equals_sign;{{c625:cd21de}} test for "=" after var name
        call    eval_expression   ;{{c628:cd62cf}} Get initial value
        ld      a,c               ;{{c62b:79}} 
        call    convert_accumulator_to_type_in_A;{{c62c:cdfffe}} 
        push    hl                ;{{c62f:e5}} 
        ld      hl,FOR_start_value_;{{c630:210dac}} 
        call    copy_numeric_accumulator_to_atHL;{{c633:cd83ff}} 
        pop     hl                ;{{c636:e1}} 

        call    next_token_if_equals_inline_data_byte;{{c637:cd25de}} 
        defb $ec                  ;Inline token to test "TO"
        call    eval_expression   ;{{c6eb:cd62cf}} Read to value
        ex      (sp),hl           ;{{c63e:e3}} 
        ld      a,c               ;{{c63f:79}} 
        call    convert_accumulator_to_type_in_A;{{c640:cdfffe}} 
        call    copy_numeric_accumulator_to_atHL;{{c643:cd83ff}} 
        ex      de,hl             ;{{c646:eb}} 
        ex      (sp),hl           ;{{c647:e3}} 
        ex      de,hl             ;{{c648:eb}} 

        ld      hl,$0001          ;{{c649:210100}} Default step to 1
        call    store_HL_in_accumulator_as_INT;{{c64c:cd35ff}} 
        ex      de,hl             ;{{c64f:eb}} 
        ld      a,(hl)            ;{{c650:7e}} 
        cp      $e6               ;{{c651:fee6}} STEP token
        jr      nz,_command_for_73;{{c653:2006}}  (+$06)

        call    get_next_token_skipping_space;{{c655:cd2cde}}  get next token skipping space
        call    eval_expression   ;{{c658:cd62cf}} Step value

_command_for_73:                  ;{{Addr=$c65b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{c65b:79}} 
        call    convert_accumulator_to_type_in_A;{{c65c:cdfffe}} 
        ex      (sp),hl           ;{{c65f:e3}} 
        call    copy_numeric_accumulator_to_atHL;{{c660:cd83ff}} 
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c663:cdc4fd}} 
        ex      de,hl             ;{{c666:eb}} 
        ld      (hl),a            ;{{c667:77}} 
        inc     hl                ;{{c668:23}} 
        ex      de,hl             ;{{c669:eb}} 
        pop     hl                ;{{c66a:e1}} 
        call    error_if_not_end_of_statement_or_eoln;{{c66b:cd37de}} Validate step is an INT
        ex      de,hl             ;{{c66e:eb}} 
        ld      (hl),e            ;{{c66f:73}} 
        inc     hl                ;{{c670:23}} 
        ld      (hl),d            ;{{c671:72}} 
        inc     hl                ;{{c672:23}} 
        ex      de,hl             ;{{c673:eb}} 

        call    get_current_line_address;{{c674:cdb1de}} Address of current line (for NEXT to jump to)
        ex      de,hl             ;{{c677:eb}} 
        ld      (hl),e            ;{{c678:73}} 
        inc     hl                ;{{c679:23}} 
        ld      (hl),d            ;{{c67a:72}} 
        inc     hl                ;{{c67b:23}} 
        pop     de                ;{{c67c:d1}} 
        ld      (hl),e            ;{{c67d:73}} 
        inc     hl                ;{{c67e:23}} 
        ld      (hl),d            ;{{c67f:72}} 
        inc     hl                ;{{c680:23}} 
        ld      de,(address_of_colon_or_line_end_byte_after_);{{c681:ed5b12ac}} 
        ld      (hl),e            ;{{c685:73}} 
        inc     hl                ;{{c686:23}} 
        ld      (hl),d            ;{{c687:72}} 
        inc     hl                ;{{c688:23}} 
        ld      (hl),b            ;{{c689:70}} 
        pop     de                ;{{c68a:d1}} 

        ld      hl,FOR_start_value_;{{c68b:210dac}} 
        call    copy_value_atHL_to_atDE_accumulator_type;{{c68e:cd87ff}} 
        xor     a                 ;{{c691:af}} 
        ld      (FORNEXT_flag_),a ;{{c692:320cac}} &00=NEXT not yet used
        pop     hl                ;{{c695:e1}} 
        call    set_current_line_address;{{c696:cdadde}} 
        ld      hl,(address_of_colon_or_line_end_byte_after_);{{c699:2a12ac}} 
        jr      _command_next_2   ;{{c69c:1809}}  (+$09)

;;=raise Unexpected NEXT
raise_Unexpected_NEXT:            ;{{Addr=$c69e Code Calls/jump count: 2 Data use count: 0}}
        call    byte_following_call_is_error_code;{{c69e:cd45cb}} 
        defb $01                  ;Inline error code: Unexpected NEXT

;;========================================================================
;; command NEXT
;NEXT [<list of: <variable>>]
;Ends a FOR loop. See FOR

command_NEXT:                     ;{{Addr=$c6a2 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$ff             ;{{c6a2:3eff}} 
        ld      (FORNEXT_flag_),a ;{{c6a4:320cac}} &ff=NEXT has been used
_command_next_2:                  ;{{Addr=$c6a7 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{c6a7:eb}} 
        call    get_execution_stack_data;{{c6a8:cdd9c6}} 
        jr      nz,raise_Unexpected_NEXT;{{c6ab:20f1}}  (-$0f)

        ex      de,hl             ;{{c6ad:eb}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c6ae:cd5df6}} 
        ex      de,hl             ;{{c6b1:eb}} 
        push    hl                ;{{c6b2:e5}} 
        call    update_and_test_FOR_loop_counter;{{c6b3:cd02c7}} 
        jr      z,for_loop_done   ;{{c6b6:280f}}  (+$0f)

;;Go to end of for statement
        pop     af                ;{{c6b8:f1}} 
        inc     hl                ;{{c6b9:23}} 
        ld      e,(hl)            ;{{c6ba:5e}} 
        inc     hl                ;{{c6bb:23}} 
        ld      d,(hl)            ;{{c6bc:56}} 
        inc     hl                ;{{c6bd:23}} 
        ld      a,(hl)            ;{{c6be:7e}} 
        inc     hl                ;{{c6bf:23}} 
        ld      h,(hl)            ;{{c6c0:66}} 
        ld      l,a               ;{{c6c1:6f}} 
        call    set_current_line_address;{{c6c2:cdadde}} 
        ex      de,hl             ;{{c6c5:eb}} 
        ret                       ;{{c6c6:c9}} 

;;=for loop done
;remove data from execution stack
for_loop_done:                    ;{{Addr=$c6c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0005          ;{{c6c7:010500}} 
        add     hl,bc             ;{{c6ca:09}} 
        ld      e,(hl)            ;{{c6cb:5e}} 
        inc     hl                ;{{c6cc:23}} 
        ld      d,(hl)            ;{{c6cd:56}} 
        pop     hl                ;{{c6ce:e1}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c6cf:cd5df6}} 
        ex      de,hl             ;{{c6d2:eb}} 
        call    next_token_if_prev_is_comma;{{c6d3:cd41de}} Test for another NEXT variable
        jr      c,_command_next_2 ;{{c6d6:38cf}}  (-$31) if so, process it
        ret                       ;{{c6d8:c9}} 

;;=get execution stack data
get_execution_stack_data:         ;{{Addr=$c6d9 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c6d9:2a6fb0}} 
_get_execution_stack_data_1:      ;{{Addr=$c6dc Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c6dc:e5}} 
        dec     hl                ;{{c6dd:2b}} 
        ld      b,(hl)            ;{{c6de:46}} 
        inc     hl                ;{{c6df:23}} 
        ld      a,l               ;{{c6e0:7d}} 
        sub     b                 ;{{c6e1:90}} 
        ld      l,a               ;{{c6e2:6f}} 
        sbc     a,a               ;{{c6e3:9f}} 
        add     a,h               ;{{c6e4:84}} 
        ld      h,a               ;{{c6e5:67}} 
        ex      (sp),hl           ;{{c6e6:e3}} 
        ld      a,b               ;{{c6e7:78}} 
        cp      $07               ;{{c6e8:fe07}} 
        jr      c,_get_execution_stack_data_26;{{c6ea:380f}}  (+$0f)
        jr      nz,_get_execution_stack_data_16;{{c6ec:2000}}  (+$00)
_get_execution_stack_data_16:     ;{{Addr=$c6ee Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c6ee:e5}} 
        dec     hl                ;{{c6ef:2b}} 
        dec     hl                ;{{c6f0:2b}} 
        ld      a,(hl)            ;{{c6f1:7e}} 
        dec     hl                ;{{c6f2:2b}} 
        ld      l,(hl)            ;{{c6f3:6e}} 
        ld      h,a               ;{{c6f4:67}} 
        call    compare_HL_DE     ;{{c6f5:cdd8ff}}  HL=DE?
        pop     hl                ;{{c6f8:e1}} 
        jr      nz,_get_execution_stack_data_30;{{c6f9:2004}}  (+$04)
_get_execution_stack_data_26:     ;{{Addr=$c6fb Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c6fb:eb}} 
        pop     hl                ;{{c6fc:e1}} 
        ld      a,b               ;{{c6fd:78}} 
        ret                       ;{{c6fe:c9}} 

_get_execution_stack_data_30:     ;{{Addr=$c6ff Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c6ff:e1}} 
        jr      _get_execution_stack_data_1;{{c700:18da}}  (-$26)

;;=update and test FOR loop counter
update_and_test_FOR_loop_counter: ;{{Addr=$c702 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{c702:5e}} 
        inc     hl                ;{{c703:23}} 
        ld      d,(hl)            ;{{c704:56}} 
        inc     hl                ;{{c705:23}} 
        push    hl                ;{{c706:e5}} 
        cp      $10               ;{{c707:fe10}} Alternative loop counter variable type??
        jr      z,update_and_test_INT_for_loop_counter;{{c709:282c}}  (+$2c)

;counter is a float
        ld      bc,$0005          ;{{c70b:010500}} 
        ld      a,c               ;{{c70e:79}} 
        ex      de,hl             ;{{c70f:eb}} 
        call    copy_atHL_to_accumulator_type_A;{{c710:cd6cff}} 
        pop     hl                ;{{c713:e1}} 
        ld      a,(FORNEXT_flag_) ;{{c714:3a0cac}} 
        or      a                 ;{{c717:b7}} 
        jr      z,_update_and_test_for_loop_counter_27;{{c718:2810}}  (+$10) &00=NEXT not yet used (we're still in the FOR!)

        push    hl                ;{{c71a:e5}} Otherwise update FOR variable (var = var + step)
        add     hl,bc             ;{{c71b:09}} 
        call    infix_plus_       ;{{c71c:cd0cfd}} 
        pop     hl                ;{{c71f:e1}} 
        push    hl                ;{{c720:e5}} 
        dec     hl                ;{{c721:2b}} 
        ld      d,(hl)            ;{{c722:56}} 
        dec     hl                ;{{c723:2b}} 
        ld      e,(hl)            ;{{c724:5e}} 
        ex      de,hl             ;{{c725:eb}} 
        call    copy_numeric_accumulator_to_atHL;{{c726:cd83ff}} 
        pop     hl                ;{{c729:e1}} 

_update_and_test_for_loop_counter_27:;{{Addr=$c72a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c72a:e5}} Compare counter to 'to' value
        ld      c,$05             ;{{c72b:0e05}} Comparison operation? greater or equals?
        call    infix_comparisons_plural;{{c72d:cd49fd}} 
        pop     hl                ;{{c730:e1}} 
        ld      bc,$000a          ;{{c731:010a00}} 
        add     hl,bc             ;{{c734:09}} 
        sub     (hl)              ;{{c735:96}} 
        ret                       ;{{c736:c9}} 

;;=update and test INT for loop counter
update_and_test_INT_for_loop_counter:;{{Addr=$c737 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c737:eb}} 
        ld      e,(hl)            ;{{c738:5e}} 
        inc     hl                ;{{c739:23}} 
        ld      d,(hl)            ;{{c73a:56}} 
        ld      a,(FORNEXT_flag_) ;{{c73b:3a0cac}} 
        or      a                 ;{{c73e:b7}} 
        jr      z,_update_and_test_int_for_loop_counter_24;{{c73f:2816}}  (+$16) &00=NEXT not yet used (still in FOR statement!)

        ex      (sp),hl           ;{{c741:e3}} 
        push    hl                ;{{c742:e5}} 
        inc     hl                ;{{c743:23}} 
        inc     hl                ;{{c744:23}} 
        ld      a,(hl)            ;{{c745:7e}} 
        inc     hl                ;{{c746:23}} 
        ld      h,(hl)            ;{{c747:66}} 
        ld      l,a               ;{{c748:6f}} 
        call    INT_addition_with_overflow_test;{{c749:cd4add}} 
        ld      a,$06             ;{{c74c:3e06}} Overflow error
        jp      nc,raise_error    ;{{c74e:d255cb}} 

        ex      de,hl             ;{{c751:eb}} 
        pop     hl                ;{{c752:e1}} 
        ex      (sp),hl           ;{{c753:e3}} 
        ld      (hl),d            ;{{c754:72}} 
        dec     hl                ;{{c755:2b}} 
        ld      (hl),e            ;{{c756:73}} 

_update_and_test_int_for_loop_counter_24:;{{Addr=$c757 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c757:e1}} Test loop counter against 'to' condition
        ld      a,(hl)            ;{{c758:7e}} 
        inc     hl                ;{{c759:23}} 
        push    hl                ;{{c75a:e5}} 
        ld      h,(hl)            ;{{c75b:66}} 
        ld      l,a               ;{{c75c:6f}} 
        ex      de,hl             ;{{c75d:eb}} 
        call    prob_compare_DE_to_HL;{{c75e:cd02de}} 
        pop     hl                ;{{c761:e1}} 
        inc     hl                ;{{c762:23}} 
        inc     hl                ;{{c763:23}} 
        inc     hl                ;{{c764:23}} 
        sub     (hl)              ;{{c765:96}} 
        ret                       ;{{c766:c9}} 

;;========================================================================
;; command IF
;IF <logical expression> THEN <option part> [ELSE <option part>]
;IF <logical expression> GOTO <line number> [ELSE <option part>]
;where <option part> is <statements> or <line number>
;Conditional execution.
;An IF statement terminates at the end of the line.
;GOTO can also be GO TO
;Line numbers must be constants
;IF statements can be nested as long as they are all on the same line.

command_IF:                       ;{{Addr=$c767 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{c767:cd62cf}} 
        cp      $a0               ;{{c76a:fea0}} GOTO token
        jr      z,_command_if_5   ;{{c76c:2804}}  (+$04) IF [cond] GOTO [n] syntax
        call    next_token_if_equals_inline_data_byte;{{c76e:cd25de}} 
        defb $eb                  ;Token to test "THEN"

_command_if_5:                    ;{{Addr=$c772 Code Calls/jump count: 1 Data use count: 0}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c772:cdc4fd}} test condition
        call    z,skip_to_ELSE_statement;{{c775:cc5be9}} condition false - skip to ELSE
        ret     z                 ;{{c778:c8}} No else?

        call    is_next_02        ;{{c779:cd3dde}} 
        ret     c                 ;{{c77c:d8}} end of statement/line

        cp      $1e               ;{{c77d:fe1e}}  16-bit integer BASIC line number
        jr      z,command_GOTO    ;{{c77f:2805}} if so it's a GOTO
        cp      $1d               ;{{c781:fe1d}}  16-bit BASIC program line memory address pointer
        jp      nz,execute_command_token;{{c783:c28fde}} if not memory address pointer then execute whatever it is
                                  ;otherwise fall through to...

;;========================================================================
;; command GOTO
;GOTO <line number>
;GO TO <line number>
;Jump to a line. Line number must be a constant

command_GOTO:                     ;{{Addr=$c786 Code Calls/jump count: 1 Data use count: 1}}
        call    eval_and_convert_line_number_to_line_address;{{c786:cd27e8}} 
        ret     nz                ;{{c789:c0}} 

        ex      de,hl             ;{{c78a:eb}} 
        ret                       ;{{c78b:c9}} 

;;========================================================================
;; command GOSUB
;GOSUB <line number>
;GO SUB <line number>
;Call a subroutine. Line number must be a constant.

command_GOSUB:                    ;{{Addr=$c78c Code Calls/jump count: 0 Data use count: 1}}
        call    eval_and_convert_line_number_to_line_address;{{c78c:cd27e8}} 
        ret     nz                ;{{c78f:c0}} 

;;=GOSUB HL
GOSUB_HL:                         ;{{Addr=$c790 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c790:eb}} 
        ld      c,$00             ;{{c791:0e00}} C=type of GOSUB. &00=regular

;;=special GOSUB HL
;C=gosub type (e.g. ON ERROR, ON BREAK, event etc).
;This code sets the next current line pointer and returns eith execution address in HL
special_GOSUB_HL:                 ;{{Addr=$c793 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c793:e5}} 
        ld      a,$06             ;{{c794:3e06}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c796:cd72f6}} 
        ld      (hl),c            ;{{c799:71}} 
        inc     hl                ;{{c79a:23}} 
        ld      (hl),e            ;{{c79b:73}} 
        inc     hl                ;{{c79c:23}} 
        ld      (hl),d            ;{{c79d:72}} 
        inc     hl                ;{{c79e:23}} 
        ex      de,hl             ;{{c79f:eb}} 
        call    get_current_line_address;{{c7a0:cdb1de}} 
        ex      de,hl             ;{{c7a3:eb}} 
        ld      (hl),e            ;{{c7a4:73}} 
        inc     hl                ;{{c7a5:23}} 
        ld      (hl),d            ;{{c7a6:72}} 
        inc     hl                ;{{c7a7:23}} 
        ld      (hl),$06          ;{{c7a8:3606}} 
        inc     hl                ;{{c7aa:23}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c7ab:cd5df6}} 
        pop     hl                ;{{c7ae:e1}} 
        ret                       ;{{c7af:c9}} 

;;========================================================================
;; command RETURN
;RETURN
;Returns from a subroutine

command_RETURN:                   ;{{Addr=$c7b0 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{c7b0:c0}} 
        call    find_last_RETURN_item_on_execution_stack;{{c7b1:cdcfc7}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c7b4:cd5df6}} 
        ld      c,(hl)            ;{{c7b7:4e}} 
        inc     hl                ;{{c7b8:23}} 
        ld      e,(hl)            ;{{c7b9:5e}} 
        inc     hl                ;{{c7ba:23}} 
        ld      d,(hl)            ;{{c7bb:56}} 
        inc     hl                ;{{c7bc:23}} 
        ld      a,(hl)            ;{{c7bd:7e}} 
        inc     hl                ;{{c7be:23}} 
        ld      h,(hl)            ;{{c7bf:66}} 
        ld      l,a               ;{{c7c0:6f}} 
        call    set_current_line_address;{{c7c1:cdadde}} 
        ex      de,hl             ;{{c7c4:eb}} 
        ld      a,c               ;{{c7c5:79}} 
        cp      $01               ;{{c7c6:fe01}} 
        ret     c                 ;{{c7c8:d8}} 

        jp      z,prob_RETURN_from_event_handler;{{c7c9:ca51c9}} 
        jp      prob_RETURN_from_break_handler;{{c7cc:c361c9}} 

;;=find last RETURN item on execution stack
find_last_RETURN_item_on_execution_stack:;{{Addr=$c7cf Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c7cf:2a6fb0}} 
_find_last_return_item_on_execution_stack_1:;{{Addr=$c7d2 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{c7d2:2b}} 
        ld      a,(hl)            ;{{c7d3:7e}} 
        push    af                ;{{c7d4:f5}} 
        ld      a,l               ;{{c7d5:7d}} 
        sub     (hl)              ;{{c7d6:96}} 
        ld      l,a               ;{{c7d7:6f}} 
        sbc     a,a               ;{{c7d8:9f}} 
        add     a,h               ;{{c7d9:84}} 
        ld      h,a               ;{{c7da:67}} 
        inc     hl                ;{{c7db:23}} 
        pop     af                ;{{c7dc:f1}} 
        cp      $06               ;{{c7dd:fe06}} 
        ret     z                 ;{{c7df:c8}} 

        or      a                 ;{{c7e0:b7}} 
        jr      nz,_find_last_return_item_on_execution_stack_1;{{c7e1:20ef}}  (-$11)
        call    byte_following_call_is_error_code;{{c7e3:cd45cb}} 
        defb $03                  ;Inline error code: Unexpected RETURN

;;========================================================================
;; command WHILE
;WHILE <logical expression>
;Begins a WHILE ... WEND loop
;The matching WEND is established when WHILE is encountered, and is searched for sequentially
;in the code, ignoring order of execution, but respecting and nested WHILE loops.
;WHILE can be terminated by avoiding the WEND

command_WHILE:                    ;{{Addr=$c7e7 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c7e7:e5}} 
        call    find_matching_WEND;{{c7e8:cdc9ca}} 
        push    hl                ;{{c7eb:e5}} 
        ex      de,hl             ;{{c7ec:eb}} 

;Find data on execution stack
        ld      (address_of_LB_of_the_line_number_contain),hl;{{c7ed:2214ac}} 
        call    find_WHILEWEND_data_on_execution_stack;{{c7f0:cd5dc8}} 
        call    z,set_execution_stack_next_free_ptr_and_its_cache;{{c7f3:cc5df6}} 

;Data not found on execution stack so add it
        ld      a,$07             ;{{c7f6:3e07}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c7f8:cd72f6}} 
        ex      de,hl             ;{{c7fb:eb}} 
        call    get_current_line_address;{{c7fc:cdb1de}} 
        ex      de,hl             ;{{c7ff:eb}} 
        ld      (hl),e            ;{{c800:73}} 
        inc     hl                ;{{c801:23}} 
        ld      (hl),d            ;{{c802:72}} 
        inc     hl                ;{{c803:23}} 
        pop     de                ;{{c804:d1}} 
        ld      (hl),e            ;{{c805:73}} 
        inc     hl                ;{{c806:23}} 
        ld      (hl),d            ;{{c807:72}} 
        inc     hl                ;{{c808:23}} 
        ex      de,hl             ;{{c809:eb}} 
        ex      (sp),hl           ;{{c80a:e3}} 
        ex      de,hl             ;{{c80b:eb}} 
        ld      (hl),e            ;{{c80c:73}} 
        inc     hl                ;{{c80d:23}} 
        ld      (hl),d            ;{{c80e:72}} 
        inc     hl                ;{{c80f:23}} 
        ld      (hl),$07          ;{{c810:3607}} 
        inc     hl                ;{{c812:23}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c813:cd5df6}} 
        ex      de,hl             ;{{c816:eb}} 
        pop     de                ;{{c817:d1}} 
        jr      eval_WHILE_condition;{{c818:182a}}  (+$2a)

;;========================================================================
;; command WEND
;WEND
;Terminates a WHILE ... WEND loop.
;See WHILE

command_WEND:                     ;{{Addr=$c81a Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{c81a:c0}} 
        ex      de,hl             ;{{c81b:eb}} 
        call    find_WHILEWEND_data_on_execution_stack;{{c81c:cd5dc8}} 
        ld      a,$1e             ;{{c81f:3e1e}}  Unexpected WEND error
        jp      nz,raise_error    ;{{c821:c255cb}} 

        push    hl                ;{{c824:e5}} 
        ld      de,$0007          ;{{c825:110700}} 
        add     hl,de             ;{{c828:19}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c829:cd5df6}} 
        call    get_current_line_address;{{c82c:cdb1de}} 
        ld      (address_of_LB_of_the_line_number_contain),hl;{{c82f:2214ac}} 
        pop     hl                ;{{c832:e1}} 
        ld      e,(hl)            ;{{c833:5e}} 
        inc     hl                ;{{c834:23}} 
        ld      d,(hl)            ;{{c835:56}} 
        inc     hl                ;{{c836:23}} 
        ex      de,hl             ;{{c837:eb}} 
        call    set_current_line_address;{{c838:cdadde}} Go to the WHILE statement?
        ex      de,hl             ;{{c83b:eb}} 
        ld      e,(hl)            ;{{c83c:5e}} 
        inc     hl                ;{{c83d:23}} 
        ld      d,(hl)            ;{{c83e:56}} 
        inc     hl                ;{{c83f:23}} 
        ld      a,(hl)            ;{{c840:7e}} 
        inc     hl                ;{{c841:23}} 
        ld      h,(hl)            ;{{c842:66}} 
        ld      l,a               ;{{c843:6f}} 

;;=eval WHILE condition
eval_WHILE_condition:             ;{{Addr=$c844 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c844:d5}} 
        call    eval_expression   ;{{c845:cd62cf}} 
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c848:cdc4fd}} 
        pop     de                ;{{c84b:d1}} 
        ret     nz                ;{{c84c:c0}} Condition true? - continue after the WHILE

        ld      hl,(address_of_LB_of_the_line_number_contain);{{c84d:2a14ac}} else remove execution stack data and continue after the WEND
        call    set_current_line_address;{{c850:cdadde}} 
        ld      a,$07             ;{{c853:3e07}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{c855:cd62f6}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c858:cd5df6}} 
        ex      de,hl             ;{{c85b:eb}} 
        ret                       ;{{c85c:c9}} 

;;=find WHILE/WEND data on execution stack
find_WHILEWEND_data_on_execution_stack:;{{Addr=$c85d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c85d:2a6fb0}} 
_find_whilewend_data_on_execution_stack_1:;{{Addr=$c860 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{c860:2b}} 
        push    hl                ;{{c861:e5}} 
        ld      a,l               ;{{c862:7d}} 
        sub     (hl)              ;{{c863:96}} 
        ld      l,a               ;{{c864:6f}} 
        sbc     a,a               ;{{c865:9f}} 
        add     a,h               ;{{c866:84}} 
        ld      h,a               ;{{c867:67}} 
        inc     hl                ;{{c868:23}} 
        ex      (sp),hl           ;{{c869:e3}} 
        ld      a,(hl)            ;{{c86a:7e}} 
        cp      $07               ;{{c86b:fe07}} 
        jr      c,_find_whilewend_data_on_execution_stack_24;{{c86d:380e}}  (+$0e)
        jr      nz,_find_whilewend_data_on_execution_stack_26;{{c86f:200e}}  (+$0e)
        dec     hl                ;{{c871:2b}} 
        dec     hl                ;{{c872:2b}} 
        dec     hl                ;{{c873:2b}} 
        ld      a,(hl)            ;{{c874:7e}} 
        dec     hl                ;{{c875:2b}} 
        ld      l,(hl)            ;{{c876:6e}} 
        ld      h,a               ;{{c877:67}} 
        call    compare_HL_DE     ;{{c878:cdd8ff}}  HL=DE?
        jr      nz,_find_whilewend_data_on_execution_stack_26;{{c87b:2002}}  (+$02)
_find_whilewend_data_on_execution_stack_24:;{{Addr=$c87d Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c87d:e1}} 
        ret                       ;{{c87e:c9}} 

_find_whilewend_data_on_execution_stack_26:;{{Addr=$c87f Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{c87f:e1}} 
        jr      _find_whilewend_data_on_execution_stack_1;{{c880:18de}}  (-$22)




