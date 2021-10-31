;;<< VARIABLE ALLOCATION AND ASSIGNMENT
;;< DEFINT/REAL/STR, LET, DIM, ERASE
;;< (Lots more work to do here)
;;===================================

;;=prob delete program
prob_delete_program:              ;{{Addr=$d5ea Code Calls/jump count: 2 Data use count: 0}}
        call    zero_36_bytes_at_adb7;{{d5ea:cdfad5}} 
        ld      hl,(address_after_end_of_program);{{d5ed:2a66ae}} 
        ld      (address_of_start_of_Variables_and_DEF_FN),hl;{{d5f0:2268ae}} 
        ld      (address_of_start_of_Arrays_area_),hl;{{d5f3:226aae}} 
        ld      (address_of_start_of_free_space_),hl;{{d5f6:226cae}} 
        ret                       ;{{d5f9:c9}} 

;;=zero &36 bytes at adb7
zero_36_bytes_at_adb7:            ;{{Addr=$d5fa Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_adb7       ;{{d5fa:21b7ad}} 
        ld      a,$36             ;{{d5fd:3e36}} 
        call    _zero_6_bytes_at_aded_2;{{d5ff:cd07d6}} 

;;=zero 6 bytes at aded
zero_6_bytes_at_aded:             ;{{Addr=$d602 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,RAM_aded       ;{{d602:21edad}} 
        ld      a,$06             ;{{d605:3e06}} 
_zero_6_bytes_at_aded_2:          ;{{Addr=$d607 Code Calls/jump count: 2 Data use count: 0}}
        ld      (hl),$00          ;{{d607:3600}} 
        inc     hl                ;{{d609:23}} 
        dec     a                 ;{{d60a:3d}} 
        jr      nz,_zero_6_bytes_at_aded_2;{{d60b:20fa}}  (-$06)
        ret                       ;{{d60d:c9}} 

_zero_6_bytes_at_aded_7:          ;{{Addr=$d60e Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,RESET_ENTRY    ;{{d60e:210000}} 
        ld      (RAM_adeb),hl     ;{{d611:22ebad}} 
        jp      prob_reset_links_to_variables_data;{{d614:c34dea}} 

_zero_6_bytes_at_aded_10:         ;{{Addr=$d617 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$5b             ;{{d617:3e5b}} 
_zero_6_bytes_at_aded_11:         ;{{Addr=$d619 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,(address_of_start_of_Variables_and_DEF_FN);{{d619:ed4b68ae}} 
        dec     bc                ;{{d61d:0b}} 
        add     a,a               ;{{d61e:87}} 
        add     a,$35             ;{{d61f:c635}} 
        ld      l,a               ;{{d621:6f}} 
        adc     a,$ad             ;{{d622:cead}} 
        sub     l                 ;{{d624:95}} 
        ld      h,a               ;{{d625:67}} 
        ret                       ;{{d626:c9}} 

_zero_6_bytes_at_aded_20:         ;{{Addr=$d627 Code Calls/jump count: 6 Data use count: 0}}
        ld      bc,(address_of_start_of_Arrays_area_);{{d627:ed4b6aae}} 
        dec     bc                ;{{d62b:0b}} 
        and     $03               ;{{d62c:e603}} 
        dec     a                 ;{{d62e:3d}} 
        add     a,a               ;{{d62f:87}} 
        add     a,$ed             ;{{d630:c6ed}} 
        ld      l,a               ;{{d632:6f}} 
        adc     a,$ad             ;{{d633:cead}} 
        sub     l                 ;{{d635:95}} 
        ld      h,a               ;{{d636:67}} 
        ret                       ;{{d637:c9}} 

_zero_6_bytes_at_aded_31:         ;{{Addr=$d638 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$415a          ;{{d638:015a41}} 
        ld      e,$05             ;{{d63b:1e05}} 
_zero_6_bytes_at_aded_33:         ;{{Addr=$d63d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{d63d:79}} 
        sub     b                 ;{{d63e:90}} 
        jr      c,_command_defreal_18;{{d63f:383d}}  (+$3d)
        push    hl                ;{{d641:e5}} 
        inc     a                 ;{{d642:3c}} 
        ld      hl,RAM_adb2       ;{{d643:21b2ad}} 
        ld      b,$00             ;{{d646:0600}} 
        add     hl,bc             ;{{d648:09}} 
_zero_6_bytes_at_aded_41:         ;{{Addr=$d649 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),e            ;{{d649:73}} 
        dec     hl                ;{{d64a:2b}} 
        dec     a                 ;{{d64b:3d}} 
        jr      nz,_zero_6_bytes_at_aded_41;{{d64c:20fb}}  (-$05)
        pop     hl                ;{{d64e:e1}} 
        ret                       ;{{d64f:c9}} 


;;======================================================
;; command DEFSTR

command_DEFSTR:                   ;{{Addr=$d650 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$03             ;{{d650:1e03}} 
        jr      _command_defreal_1;{{d652:1806}}  (+$06)

;;=============================================================================
;; command DEFINT

command_DEFINT:                   ;{{Addr=$d654 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$02             ;{{d654:1e02}} 
        jr      _command_defreal_1;{{d656:1802}}  (+$02)

;;=============================================================================
;; command DEFREAL
command_DEFREAL:                  ;{{Addr=$d658 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$05             ;{{d658:1e05}} 
;;-----------------------------------------------------------------------------

_command_defreal_1:               ;{{Addr=$d65a Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{d65a:7e}} 
        call    test_if_letter    ;{{d65b:cd92ff}}  is a alphabetical letter?
        jr      nc,_command_defreal_18;{{d65e:301e}}  (+$1e)
        ld      c,a               ;{{d660:4f}} 
        ld      b,a               ;{{d661:47}} 
        call    get_next_token_skipping_space;{{d662:cd2cde}}  get next token skipping space
        cp      $2d               ;{{d665:fe2d}}  '-'
        jr      nz,_command_defreal_14;{{d667:200c}}  (+$0c)
        call    get_next_token_skipping_space;{{d669:cd2cde}}  get next token skipping space
        call    test_if_letter    ;{{d66c:cd92ff}}  is a alphabetical letter?
        jr      nc,_command_defreal_18;{{d66f:300d}}  (+$0d)
        ld      c,a               ;{{d671:4f}} 
        call    get_next_token_skipping_space;{{d672:cd2cde}}  get next token skipping space
_command_defreal_14:              ;{{Addr=$d675 Code Calls/jump count: 1 Data use count: 0}}
        call    _zero_6_bytes_at_aded_33;{{d675:cd3dd6}} 
        call    next_token_if_prev_is_comma;{{d678:cd41de}} 
        jr      c,_command_defreal_1;{{d67b:38dd}}  (-$23)
        ret                       ;{{d67d:c9}} 

_command_defreal_18:              ;{{Addr=$d67e Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Syntax_Error;{{d67e:c349cb}}  Error: Syntax Error

_command_defreal_19:              ;{{Addr=$d681 Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d681:cd45cb}} 
        defb $09                  ;Inline error code: Subscript out of range

_command_defreal_21:              ;{{Addr=$d685 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d685:cd45cb}} 
        defb $0a                  ;Inline error code: Array already dimensioned

_command_defreal_23:              ;{{Addr=$d689 Code Calls/jump count: 1 Data use count: 0}}
        cp      $f8               ;{{d689:fef8}}  '|'
        jp      z,BAR_command     ;{{d68b:ca45f2}} 

;;========================================================================
;; command LET

command_LET:                      ;{{Addr=$d68e Code Calls/jump count: 0 Data use count: 1}}
        call    prob_parse_and_find_or_create_a_var;{{d68e:cdbfd6}} 
        push    de                ;{{d691:d5}} 
        call    next_token_if_ef_token_for_equals_sign;{{d692:cd21de}} 
        call    eval_expression   ;{{d695:cd62cf}} 
        ld      a,b               ;{{d698:78}} 
        ex      (sp),hl           ;{{d699:e3}} 
        call    copy_accumulator_to_atHL_as_type_B;{{d69a:cd9fd6}} 
        pop     hl                ;{{d69d:e1}} 
        ret                       ;{{d69e:c9}} 

;;=copy accumulator to atHL as type B
copy_accumulator_to_atHL_as_type_B:;{{Addr=$d69f Code Calls/jump count: 3 Data use count: 0}}
        ld      b,a               ;{{d69f:47}} 
        call    get_accumulator_data_type;{{d6a0:cd4bff}} 
        cp      b                 ;{{d6a3:b8}} 
        ld      a,b               ;{{d6a4:78}} 
        call    nz,convert_accumulator_to_type_in_A;{{d6a5:c4fffe}} 
;;=copy accumulator to atHL
copy_accumulator_to_atHL:         ;{{Addr=$d6a8 Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_a_string;{{d6a8:cd66ff}} 
        jp      nz,copy_accumulator_to_athl_B;{{d6ab:c283ff}} 
        push    hl                ;{{d6ae:e5}} 
        call    _copy_accumulator_to_strings_area_4;{{d6af:cd94fb}} 
        pop     de                ;{{d6b2:d1}} 
        jp      copy_value_atHL_to_atDE_accumulator_type;{{d6b3:c387ff}} 

;;========================================================================
;; command DIM

command_DIM:                      ;{{Addr=$d6b6 Code Calls/jump count: 1 Data use count: 1}}
        call    do_DIM_item       ;{{d6b6:cde0d7}} 
        call    next_token_if_prev_is_comma;{{d6b9:cd41de}} 
        jr      c,command_DIM     ;{{d6bc:38f8}}  (-$08)
        ret                       ;{{d6be:c9}} 

;;=prob parse and find or create a var
prob_parse_and_find_or_create_a_var:;{{Addr=$d6bf Code Calls/jump count: 7 Data use count: 0}}
        call    get_offset_into_var_table;{{d6bf:cd31d9}} 
        call    prob_get_var_or_array_address;{{d6c2:cd06d8}} 
        jr      c,get_accum_data_type_in_A_B_and_C;{{d6c5:3842}}  (+$42)
        jr      _prob_parse_and_find_for_var_2;{{d6c7:1828}}  (+$28)

;;=prob parse and find var
prob_parse_and_find_var:          ;{{Addr=$d6c9 Code Calls/jump count: 2 Data use count: 0}}
        call    get_offset_into_var_table;{{d6c9:cd31d9}} 
        call    prob_get_var_or_array_address;{{d6cc:cd06d8}} 
        jr      c,get_accum_data_type_in_A_B_and_C;{{d6cf:3838}}  (+$38)
        push    hl                ;{{d6d1:e5}} 
        ld      a,c               ;{{d6d2:79}} 
        call    _zero_6_bytes_at_aded_11;{{d6d3:cd19d6}} 
        call    xd717_code        ;{{d6d6:cd17d7}} 
        jr      get_accum_data_type_in_A_B_and_C_;{{d6d9:182d}}  (+$2d)

;;=prob parse and find an FN
prob_parse_and_find_an_FN:        ;{{Addr=$d6db Code Calls/jump count: 2 Data use count: 0}}
        call    get_offset_into_var_table;{{d6db:cd31d9}} 
        jr      c,unknown_alloc_DE_bytes_at_start_of_var_FN_area;{{d6de:3821}}  (+$21)
        push    hl                ;{{d6e0:e5}} 
        call    _zero_6_bytes_at_aded_10;{{d6e1:cd17d6}} 
        call    xd732_code        ;{{d6e4:cd32d7}} 
        call    nc,unknown_alloc_var_space;{{d6e7:d46fd7}} 
        jr      get_accum_data_type_in_A_B_and_C_;{{d6ea:181c}}  (+$1c)

;;=prob parse and find FOR var
prob_parse_and_find_FOR_var:      ;{{Addr=$d6ec Code Calls/jump count: 1 Data use count: 0}}
        call    get_offset_into_var_table;{{d6ec:cd31d9}} 
        jr      c,unknown_alloc_DE_bytes_at_start_of_var_FN_area;{{d6ef:3810}}  (+$10)
_prob_parse_and_find_for_var_2:   ;{{Addr=$d6f1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d6f1:e5}} 
        ld      a,c               ;{{d6f2:79}} 
        call    _zero_6_bytes_at_aded_11;{{d6f3:cd19d6}} 
        call    xd717_code        ;{{d6f6:cd17d7}} 
        ld      a,(accumulator_data_type);{{d6f9:3a9fb0}} 
        call    nc,prob_alloc_space_for_new_var;{{d6fc:d47bd7}} 
        jr      get_accum_data_type_in_A_B_and_C_;{{d6ff:1807}}  (+$07)

;;=unknown alloc DE bytes at start of var FN area
unknown_alloc_DE_bytes_at_start_of_var_FN_area:;{{Addr=$d701 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d701:e5}} 
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{d702:2a68ae}} 
        dec     hl                ;{{d705:2b}} 
        add     hl,de             ;{{d706:19}} 
        ex      de,hl             ;{{d707:eb}} 

;;=get accum data type in A B and C 
get_accum_data_type_in_A_B_and_C_:;{{Addr=$d708 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{d708:e1}} 

;;=get accum data type in A B and C
get_accum_data_type_in_A_B_and_C: ;{{Addr=$d709 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(accumulator_data_type);{{d709:3a9fb0}} 
        ld      b,a               ;{{d70c:47}} 
        ld      c,a               ;{{d70d:4f}} 
        ret                       ;{{d70e:c9}} 

;;============================
xd70f_code:                       ;{{Addr=$d70f Code Calls/jump count: 1 Data use count: 0}}
        call    get_offset_into_var_table;{{d70f:cd31d9}} 
        call    _skip_to_else_statement_17;{{d712:cd7ae9}} 
        jr      get_accum_data_type_in_A_B_and_C;{{d715:18f2}}  (-$0e)

xd717_code:                       ;{{Addr=$d717 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{d717:d5}} 
        push    hl                ;{{d718:e5}} 
        ld      hl,(RAM_ae12)     ;{{d719:2a12ae}} 
        ld      a,h               ;{{d71c:7c}} 
        or      l                 ;{{d71d:b5}} 
        jr      z,xd730_code      ;{{d71e:2810}}  (+$10)
        inc     hl                ;{{d720:23}} 
        inc     hl                ;{{d721:23}} 
        push    bc                ;{{d722:c5}} 
        ld      bc,RESET_ENTRY    ;{{d723:010000}} 
        call    xd740_code        ;{{d726:cd40d7}} 
        pop     bc                ;{{d729:c1}} 
        jr      nc,xd730_code     ;{{d72a:3004}}  (+$04)
        pop     af                ;{{d72c:f1}} 
        pop     af                ;{{d72d:f1}} 
        scf                       ;{{d72e:37}} 
        ret                       ;{{d72f:c9}} 

xd730_code:                       ;{{Addr=$d730 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{d730:e1}} 
        pop     de                ;{{d731:d1}} 
xd732_code:                       ;{{Addr=$d732 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{d732:d5}} 
        push    hl                ;{{d733:e5}} 
        call    xd740_code        ;{{d734:cd40d7}} 
        pop     hl                ;{{d737:e1}} 
        jr      c,xd73c_code      ;{{d738:3802}}  (+$02)
        pop     de                ;{{d73a:d1}} 
        ret                       ;{{d73b:c9}} 

xd73c_code:                       ;{{Addr=$d73c Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d73c:e1}} 
        jp      _prob_alloc_space_for_new_var_22;{{d73d:c39ed7}} 

xd740_code:                       ;{{Addr=$d740 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,(hl)            ;{{d740:7e}} 
        inc     hl                ;{{d741:23}} 
        ld      h,(hl)            ;{{d742:66}} 
        ld      l,a               ;{{d743:6f}} 
        or      h                 ;{{d744:b4}} 
        ret     z                 ;{{d745:c8}} 

        add     hl,bc             ;{{d746:09}} 
        push    hl                ;{{d747:e5}} 
        inc     hl                ;{{d748:23}} 
        inc     hl                ;{{d749:23}} 
        ld      de,(RAM_ae0e)     ;{{d74a:ed5b0eae}} 
xd74e_code:                       ;{{Addr=$d74e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{d74e:1a}} 
        cp      (hl)              ;{{d74f:be}} 
        jr      nz,xd75f_code     ;{{d750:200d}}  (+$0d)
        inc     hl                ;{{d752:23}} 
        inc     de                ;{{d753:13}} 
        rla                       ;{{d754:17}} 
        jr      nc,xd74e_code     ;{{d755:30f7}}  (-$09)
        ld      a,(accumulator_data_type);{{d757:3a9fb0}} 
        dec     a                 ;{{d75a:3d}} 
        xor     (hl)              ;{{d75b:ae}} 
        and     $07               ;{{d75c:e607}} 
        ex      de,hl             ;{{d75e:eb}} 
xd75f_code:                       ;{{Addr=$d75f Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d75f:e1}} 
        jr      nz,xd740_code     ;{{d760:20de}}  (-$22)
        inc     de                ;{{d762:13}} 
        scf                       ;{{d763:37}} 
        ret                       ;{{d764:c9}} 

;;=poss step over string
poss_step_over_string:            ;{{Addr=$d765 Code Calls/jump count: 3 Data use count: 0}}
        ld      d,h               ;{{d765:54}} 
        ld      e,l               ;{{d766:5d}} 
        inc     hl                ;{{d767:23}} 
        inc     hl                ;{{d768:23}} 
_poss_step_over_string_4:         ;{{Addr=$d769 Code Calls/jump count: 1 Data use count: 0}}
        bit     7,(hl)            ;{{d769:cb7e}} 
        inc     hl                ;{{d76b:23}} 
        jr      z,_poss_step_over_string_4;{{d76c:28fb}}  (-$05)
        ret                       ;{{d76e:c9}} 

;;=unknown alloc var space
unknown_alloc_var_space:          ;{{Addr=$d76f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$02             ;{{d76f:3e02}} 
        call    prob_alloc_space_for_new_var;{{d771:cd7bd7}} 
        dec     de                ;{{d774:1b}} 
        ld      a,(de)            ;{{d775:1a}} 
        or      $40               ;{{d776:f640}} 
        ld      (de),a            ;{{d778:12}} 
        inc     de                ;{{d779:13}} 
        ret                       ;{{d77a:c9}} 

;;=prob alloc space for new var
prob_alloc_space_for_new_var:     ;{{Addr=$d77b Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{d77b:d5}} 
        push    hl                ;{{d77c:e5}} 
        push    bc                ;{{d77d:c5}} 
        push    af                ;{{d77e:f5}} 
        call    _prob_alloc_space_for_new_var_32;{{d77f:cda8d7}} 
        push    af                ;{{d782:f5}} 
        ld      hl,(address_of_start_of_Arrays_area_);{{d783:2a6aae}} 
        ex      de,hl             ;{{d786:eb}} 
        call    unknown_alloc_and_move_memory_up;{{d787:cdb8f6}} 
        call    prob_grow_variables_space_ptrs_by_BC;{{d78a:cd1af6}} 
        pop     af                ;{{d78d:f1}} 
        call    _prob_alloc_space_for_new_var_43;{{d78e:cdb8d7}} 
        pop     bc                ;{{d791:c1}} 
        xor     a                 ;{{d792:af}} 
_prob_alloc_space_for_new_var_14: ;{{Addr=$d793 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d793:2b}} 
        ld      (hl),a            ;{{d794:77}} 
        djnz    _prob_alloc_space_for_new_var_14;{{d795:10fc}}  (-$04)
        pop     bc                ;{{d797:c1}} 
        ex      (sp),hl           ;{{d798:e3}} 
        call    _prob_alloc_space_for_new_var_61;{{d799:cdd0d7}} 
        pop     de                ;{{d79c:d1}} 
        pop     hl                ;{{d79d:e1}} 
_prob_alloc_space_for_new_var_22: ;{{Addr=$d79e Code Calls/jump count: 3 Data use count: 0}}
        inc     hl                ;{{d79e:23}} 
        ld      a,e               ;{{d79f:7b}} 
        sub     c                 ;{{d7a0:91}} 
        ld      (hl),a            ;{{d7a1:77}} 
        inc     hl                ;{{d7a2:23}} 
        ld      a,d               ;{{d7a3:7a}} 
        sbc     a,b               ;{{d7a4:98}} 
        ld      (hl),a            ;{{d7a5:77}} 
        scf                       ;{{d7a6:37}} 
        ret                       ;{{d7a7:c9}} 

_prob_alloc_space_for_new_var_32: ;{{Addr=$d7a8 Code Calls/jump count: 2 Data use count: 0}}
        add     a,$03             ;{{d7a8:c603}} 
        ld      c,a               ;{{d7aa:4f}} 
        ld      hl,(RAM_ae0e)     ;{{d7ab:2a0eae}} 
        xor     a                 ;{{d7ae:af}} 
        ld      b,a               ;{{d7af:47}} 
_prob_alloc_space_for_new_var_37: ;{{Addr=$d7b0 Code Calls/jump count: 1 Data use count: 0}}
        inc     bc                ;{{d7b0:03}} 
        inc     a                 ;{{d7b1:3c}} 
        bit     7,(hl)            ;{{d7b2:cb7e}} 
        inc     hl                ;{{d7b4:23}} 
        jr      z,_prob_alloc_space_for_new_var_37;{{d7b5:28f9}}  (-$07)
        ret                       ;{{d7b7:c9}} 

_prob_alloc_space_for_new_var_43: ;{{Addr=$d7b8 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,d               ;{{d7b8:62}} 
        ld      l,e               ;{{d7b9:6b}} 
        add     hl,bc             ;{{d7ba:09}} 
        push    hl                ;{{d7bb:e5}} 
        push    de                ;{{d7bc:d5}} 
        inc     de                ;{{d7bd:13}} 
        inc     de                ;{{d7be:13}} 
        ld      hl,(RAM_ae0e)     ;{{d7bf:2a0eae}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{d7c2:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        ld      a,(accumulator_data_type);{{d7c5:3a9fb0}} 
        dec     a                 ;{{d7c8:3d}} 
        ld      (de),a            ;{{d7c9:12}} 
        inc     de                ;{{d7ca:13}} 
        ld      b,d               ;{{d7cb:42}} 
        ld      c,e               ;{{d7cc:4b}} 
        pop     de                ;{{d7cd:d1}} 
        pop     hl                ;{{d7ce:e1}} 
        ret                       ;{{d7cf:c9}} 

_prob_alloc_space_for_new_var_61: ;{{Addr=$d7d0 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{d7d0:7e}} 
        ld      (de),a            ;{{d7d1:12}} 
        ld      a,e               ;{{d7d2:7b}} 
        sub     c                 ;{{d7d3:91}} 
        ld      (hl),a            ;{{d7d4:77}} 
        inc     hl                ;{{d7d5:23}} 
        ld      a,(hl)            ;{{d7d6:7e}} 
        push    af                ;{{d7d7:f5}} 
        ld      a,d               ;{{d7d8:7a}} 
        sbc     a,b               ;{{d7d9:98}} 
        ld      (hl),a            ;{{d7da:77}} 
        pop     af                ;{{d7db:f1}} 
        inc     de                ;{{d7dc:13}} 
        ld      (de),a            ;{{d7dd:12}} 
        inc     de                ;{{d7de:13}} 
        ret                       ;{{d7df:c9}} 

;;==================================
;;do DIM item
do_DIM_item:                      ;{{Addr=$d7e0 Code Calls/jump count: 1 Data use count: 0}}
        call    get_offset_into_var_table;{{d7e0:cd31d9}} 
        ld      a,(hl)            ;{{d7e3:7e}} 
        cp      $28               ;{{d7e4:fe28}} '('
        jr      z,_do_dim_item_6  ;{{d7e6:2805}}  (+$05)
        xor     $5b               ;{{d7e8:ee5b}} '['
        jp      nz,Error_Syntax_Error;{{d7ea:c249cb}}  Error: Syntax Error
_do_dim_item_6:                   ;{{Addr=$d7ed Code Calls/jump count: 1 Data use count: 0}}
        call    read_array_dimensions;{{d7ed:cd83d8}} 
        push    hl                ;{{d7f0:e5}} 
        push    bc                ;{{d7f1:c5}} 
        ld      a,(accumulator_data_type);{{d7f2:3a9fb0}} 
        call    _zero_6_bytes_at_aded_20;{{d7f5:cd27d6}} 
        call    xd740_code        ;{{d7f8:cd40d7}} 
        jp      c,_command_defreal_21;{{d7fb:da85d6}} 
        pop     bc                ;{{d7fe:c1}} 
        ld      a,$ff             ;{{d7ff:3eff}} 
        call    prob_create_and_alloc_space_for_array;{{d801:cdb3d8}} 
        pop     hl                ;{{d804:e1}} 
        ret                       ;{{d805:c9}} 

;;=prob get var or array address
;allocates space for array if needed
;;DE=offset into var table??
prob_get_var_or_array_address:    ;{{Addr=$d806 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{d806:f5}} 
        ld      a,(hl)            ;{{d807:7e}} 
        cp      $28               ;{{d808:fe28}} '('
        jr      z,prob_get_array_element_address;{{d80a:2810}}  (+$10)
        xor     $5b               ;{{d80c:ee5b}} '['
        jr      z,prob_get_array_element_address;{{d80e:280c}}  (+$0c)
        pop     af                ;{{d810:f1}} 
        ret     nc                ;{{d811:d0}} 

        push    hl                ;{{d812:e5}} 
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{d813:2a68ae}} 
        dec     hl                ;{{d816:2b}} 
        add     hl,de             ;{{d817:19}} 
        ex      de,hl             ;{{d818:eb}} 
        pop     hl                ;{{d819:e1}} 
        scf                       ;{{d81a:37}} 
        ret                       ;{{d81b:c9}} 

;;=prob get array element address
;allocates space for array if needed
prob_get_array_element_address:   ;{{Addr=$d81c Code Calls/jump count: 2 Data use count: 0}}
        call    read_array_dimensions;{{d81c:cd83d8}} 
        pop     af                ;{{d81f:f1}} 
        push    hl                ;{{d820:e5}} 
        jr      nc,_prob_get_array_element_address_8;{{d821:3007}}  (+$07)
        ld      hl,(address_of_start_of_Arrays_area_);{{d823:2a6aae}} 
        dec     hl                ;{{d826:2b}} 
        add     hl,de             ;{{d827:19}} 
        jr      _prob_get_array_element_address_20;{{d828:1815}}  (+$15)

_prob_get_array_element_address_8:;{{Addr=$d82a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{d82a:c5}} 
        push    de                ;{{d82b:d5}} 
        ld      a,(accumulator_data_type);{{d82c:3a9fb0}} 
        call    _zero_6_bytes_at_aded_20;{{d82f:cd27d6}} 
        call    xd740_code        ;{{d832:cd40d7}} 
        jr      nc,_prob_get_array_element_address_24;{{d835:300f}}  (+$0f)
        inc     de                ;{{d837:13}} 
        inc     de                ;{{d838:13}} 
        pop     hl                ;{{d839:e1}} 
        call    _prob_alloc_space_for_new_var_22;{{d83a:cd9ed7}} 
        pop     bc                ;{{d83d:c1}} 
        ex      de,hl             ;{{d83e:eb}} 
_prob_get_array_element_address_20:;{{Addr=$d83f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{d83f:78}} 
        sub     (hl)              ;{{d840:96}} 
        jp      nz,_command_defreal_19;{{d841:c281d6}} 
        jr      _prob_get_array_element_address_30;{{d844:180a}}  (+$0a)

_prob_get_array_element_address_24:;{{Addr=$d846 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d846:e1}} 
        pop     bc                ;{{d847:c1}} 
        xor     a                 ;{{d848:af}} 
        call    prob_create_and_alloc_space_for_array;{{d849:cdb3d8}} 
        call    _prob_alloc_space_for_new_var_22;{{d84c:cd9ed7}} 
        ex      de,hl             ;{{d84f:eb}} 
_prob_get_array_element_address_30:;{{Addr=$d850 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,RESET_ENTRY    ;{{d850:110000}} 
        ld      b,(hl)            ;{{d853:46}} 
        inc     hl                ;{{d854:23}} 
_prob_get_array_element_address_33:;{{Addr=$d855 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d855:e5}} 
        push    de                ;{{d856:d5}} 
        ld      e,(hl)            ;{{d857:5e}} 
        inc     hl                ;{{d858:23}} 
        ld      d,(hl)            ;{{d859:56}} 
        call    _prob_create_and_alloc_space_for_array_79;{{d85a:cd27d9}} 
        call    compare_HL_DE     ;{{d85d:cdd8ff}}  HL=DE?
        jp      nc,_command_defreal_19;{{d860:d281d6}} 
        ex      (sp),hl           ;{{d863:e3}} 
        call    do_16x16_multiply_with_overflow;{{d864:cd72dd}} 
        pop     de                ;{{d867:d1}} 
        add     hl,de             ;{{d868:19}} 
        ex      de,hl             ;{{d869:eb}} 
        pop     hl                ;{{d86a:e1}} 
        inc     hl                ;{{d86b:23}} 
        inc     hl                ;{{d86c:23}} 
        djnz    _prob_get_array_element_address_33;{{d86d:10e6}}  (-$1a)
        ex      de,hl             ;{{d86f:eb}} 
        ld      b,h               ;{{d870:44}} 
        ld      c,l               ;{{d871:4d}} 
        ld      a,(accumulator_data_type);{{d872:3a9fb0}} 
        sub     $03               ;{{d875:d603}} 
        jr      c,_prob_get_array_element_address_59;{{d877:3804}}  (+$04)
        add     hl,hl             ;{{d879:29}} 
        jr      z,_prob_get_array_element_address_59;{{d87a:2801}}  (+$01)
        add     hl,hl             ;{{d87c:29}} 
_prob_get_array_element_address_59:;{{Addr=$d87d Code Calls/jump count: 2 Data use count: 0}}
        add     hl,bc             ;{{d87d:09}} 
        add     hl,de             ;{{d87e:19}} 
        ex      de,hl             ;{{d87f:eb}} 
        pop     hl                ;{{d880:e1}} 
        scf                       ;{{d881:37}} 
        ret                       ;{{d882:c9}} 

;;=read array dimensions
read_array_dimensions:            ;{{Addr=$d883 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{d883:d5}} 
        call    get_next_token_skipping_space;{{d884:cd2cde}}  get next token skipping space
        ld      a,(accumulator_data_type);{{d887:3a9fb0}} 
        push    af                ;{{d88a:f5}} 
        ld      b,$00             ;{{d88b:0600}} 
_read_array_dimensions_5:         ;{{Addr=$d88d Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expr_as_positive_int_or_error;{{d88d:cdcece}} 
        push    hl                ;{{d890:e5}} 
        ld      a,$02             ;{{d891:3e02}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{d893:cd72f6}} 
        ld      (hl),e            ;{{d896:73}} 
        inc     hl                ;{{d897:23}} 
        ld      (hl),d            ;{{d898:72}} 
        pop     hl                ;{{d899:e1}} 
        inc     b                 ;{{d89a:04}} 
        call    next_token_if_prev_is_comma;{{d89b:cd41de}} 
        jr      c,_read_array_dimensions_5;{{d89e:38ed}}  (-$13)
        ld      a,(hl)            ;{{d8a0:7e}} 
        cp      $29               ;{{d8a1:fe29}} ')'
        jr      z,_read_array_dimensions_21;{{d8a3:2805}}  (+$05)
        cp      $5d               ;{{d8a5:fe5d}} ']'
        jp      nz,Error_Syntax_Error;{{d8a7:c249cb}}  Error: Syntax Error
_read_array_dimensions_21:        ;{{Addr=$d8aa Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{d8aa:cd2cde}}  get next token skipping space
        pop     af                ;{{d8ad:f1}} 
        ld      (accumulator_data_type),a;{{d8ae:329fb0}} 
        pop     de                ;{{d8b1:d1}} 
        ret                       ;{{d8b2:c9}} 

;;=prob create and alloc space for array
prob_create_and_alloc_space_for_array:;{{Addr=$d8b3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d8b3:e5}} 
        ld      (RAM_ae0d),a      ;{{d8b4:320dae}} 
        push    bc                ;{{d8b7:c5}} 
        ld      a,b               ;{{d8b8:78}} 
        add     a,a               ;{{d8b9:87}} 
        add     a,$03             ;{{d8ba:c603}} 
        call    _prob_alloc_space_for_new_var_32;{{d8bc:cda8d7}} 
        push    af                ;{{d8bf:f5}} 
        ld      hl,(address_of_start_of_free_space_);{{d8c0:2a6cae}} 
        ex      de,hl             ;{{d8c3:eb}} 
        call    unknown_alloc_and_move_memory_up;{{d8c4:cdb8f6}} 
        pop     af                ;{{d8c7:f1}} 
        call    _prob_alloc_space_for_new_var_43;{{d8c8:cdb8d7}} 
        ld      h,b               ;{{d8cb:60}} 
        ld      l,c               ;{{d8cc:69}} 
        pop     bc                ;{{d8cd:c1}} 
        push    de                ;{{d8ce:d5}} 
        inc     hl                ;{{d8cf:23}} 
        inc     hl                ;{{d8d0:23}} 
        ld      a,(accumulator_data_type);{{d8d1:3a9fb0}} 
        ld      e,a               ;{{d8d4:5f}} 
        ld      d,$00             ;{{d8d5:1600}} 
        ld      (hl),b            ;{{d8d7:70}} 
        push    hl                ;{{d8d8:e5}} 
        inc     hl                ;{{d8d9:23}} 
_prob_create_and_alloc_space_for_array_25:;{{Addr=$d8da Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{d8da:d5}} 
        ld      a,(RAM_ae0d)      ;{{d8db:3a0dae}} 
        or      a                 ;{{d8de:b7}} 
        ld      de,$000a          ;{{d8df:110a00}} 
        ex      de,hl             ;{{d8e2:eb}} 
        call    nz,_prob_create_and_alloc_space_for_array_79;{{d8e3:c427d9}} 
        ex      de,hl             ;{{d8e6:eb}} 
        inc     de                ;{{d8e7:13}} 
        ld      (hl),e            ;{{d8e8:73}} 
        inc     hl                ;{{d8e9:23}} 
        ld      (hl),d            ;{{d8ea:72}} 
        inc     hl                ;{{d8eb:23}} 
        ex      (sp),hl           ;{{d8ec:e3}} 
        call    do_16x16_multiply_with_overflow;{{d8ed:cd72dd}} 
        jp      c,_command_defreal_19;{{d8f0:da81d6}} 
        ex      de,hl             ;{{d8f3:eb}} 
        pop     hl                ;{{d8f4:e1}} 
        djnz    _prob_create_and_alloc_space_for_array_25;{{d8f5:10e3}}  (-$1d)
        ld      b,d               ;{{d8f7:42}} 
        ld      c,e               ;{{d8f8:4b}} 
        ld      d,h               ;{{d8f9:54}} 
        ld      e,l               ;{{d8fa:5d}} 
        call    _unknown_alloc_and_move_memory_up_1;{{d8fb:cdbbf6}} 
        ld      (address_of_start_of_free_space_),hl;{{d8fe:226cae}} 
        push    bc                ;{{d901:c5}} 
_prob_create_and_alloc_space_for_array_50:;{{Addr=$d902 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d902:2b}} 
        ld      (hl),$00          ;{{d903:3600}} 
        dec     bc                ;{{d905:0b}} 
        ld      a,b               ;{{d906:78}} 
        or      c                 ;{{d907:b1}} 
        jr      nz,_prob_create_and_alloc_space_for_array_50;{{d908:20f8}}  (-$08)
        pop     bc                ;{{d90a:c1}} 
        pop     hl                ;{{d90b:e1}} 
        ld      e,(hl)            ;{{d90c:5e}} 
        ld      d,a               ;{{d90d:57}} 
        ex      de,hl             ;{{d90e:eb}} 
        add     hl,hl             ;{{d90f:29}} 
        inc     hl                ;{{d910:23}} 
        add     hl,bc             ;{{d911:09}} 
        ex      de,hl             ;{{d912:eb}} 
        dec     hl                ;{{d913:2b}} 
        dec     hl                ;{{d914:2b}} 
        ld      (hl),e            ;{{d915:73}} 
        inc     hl                ;{{d916:23}} 
        ld      (hl),d            ;{{d917:72}} 
        inc     hl                ;{{d918:23}} 
        ex      (sp),hl           ;{{d919:e3}} 
        ex      de,hl             ;{{d91a:eb}} 
        ld      a,(accumulator_data_type);{{d91b:3a9fb0}} 
        call    _zero_6_bytes_at_aded_20;{{d91e:cd27d6}} 
        call    _prob_alloc_space_for_new_var_61;{{d921:cdd0d7}} 
        pop     de                ;{{d924:d1}} 
        pop     hl                ;{{d925:e1}} 
        ret                       ;{{d926:c9}} 

_prob_create_and_alloc_space_for_array_79:;{{Addr=$d927 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$02             ;{{d927:3e02}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d929:cd62f6}} 
        ld      a,(hl)            ;{{d92c:7e}} 
        inc     hl                ;{{d92d:23}} 
        ld      h,(hl)            ;{{d92e:66}} 
        ld      l,a               ;{{d92f:6f}} 
        ret                       ;{{d930:c9}} 

;;=================================
;;get offset into var table
;;returns value in DE
get_offset_into_var_table:        ;{{Addr=$d931 Code Calls/jump count: 7 Data use count: 0}}
        call    set_accum_type_from_variable_type_atHL;{{d931:cdafd9}} 
        inc     hl                ;{{d934:23}} 
        ld      e,(hl)            ;{{d935:5e}} read var offset into DE
        inc     hl                ;{{d936:23}} 
        ld      d,(hl)            ;{{d937:56}} 
        ld      a,d               ;{{d938:7a}} 
        or      e                 ;{{d939:b3}} 
        jr      z,prob_parse_var_name_and_find;{{d93a:280a}}  (+$0a) if offset is zero we need to find offset
_get_offset_into_var_table_8:     ;{{Addr=$d93c Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{d93c:23}} skip over var name (ends with bit 7 set)
        ld      a,(hl)            ;{{d93d:7e}} 
        rla                       ;{{d93e:17}} 
        jr      nc,_get_offset_into_var_table_8;{{d93f:30fb}}  (-$05)
        call    get_next_token_skipping_space;{{d941:cd2cde}}  get next token skipping space
        scf                       ;{{d944:37}} 
        ret                       ;{{d945:c9}} 

;;=prob parse var name and find
prob_parse_var_name_and_find:     ;{{Addr=$d946 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d946:2b}} 
        dec     hl                ;{{d947:2b}} 
        ex      de,hl             ;{{d948:eb}} 
        pop     bc                ;{{d949:c1}} 
        ld      hl,(RAM_ae0e)     ;{{d94a:2a0eae}} 
        push    hl                ;{{d94d:e5}} 
        ld      hl,_prob_parse_var_name_and_find_15;{{d94e:215ed9}} ;WARNING: Code area used as literal
        push    hl                ;{{d951:e5}} 
        push    bc                ;{{d952:c5}} 
        ex      de,hl             ;{{d953:eb}} 
        push    hl                ;{{d954:e5}} 
        call    prob_copy_var_name_onto_execution_stack;{{d955:cd6cd9}} 
        ld      (RAM_ae0e),de     ;{{d958:ed530eae}} 
        pop     de                ;{{d95c:d1}} 
        ret                       ;{{d95d:c9}} 

_prob_parse_var_name_and_find_15: ;{{Addr=$d95e Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d95e:e5}} 
        ld      hl,(RAM_ae0e)     ;{{d95f:2a0eae}} 
        call    set_execution_stack_next_free_ptr;{{d962:cd6ef6}} 
        pop     hl                ;{{d965:e1}} 
        ex      (sp),hl           ;{{d966:e3}} 
        ld      (RAM_ae0e),hl     ;{{d967:220eae}} 
        pop     hl                ;{{d96a:e1}} 
        ret                       ;{{d96b:c9}} 

;;=prob copy var name onto execution stack
prob_copy_var_name_onto_execution_stack:;{{Addr=$d96c Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d96c:e5}} 
        ld      a,(hl)            ;{{d96d:7e}} 
        inc     hl                ;{{d96e:23}} 
        inc     hl                ;{{d96f:23}} 
        inc     hl                ;{{d970:23}} 
        ld      c,(hl)            ;{{d971:4e}} 
        res     5,c               ;{{d972:cba9}} 
        ex      (sp),hl           ;{{d974:e3}} 
        cp      $0b               ;{{d975:fe0b}} 
        jr      c,_prob_copy_var_name_onto_execution_stack_24;{{d977:3817}}  (+$17)
        ld      a,c               ;{{d979:79}} 
        and     $1f               ;{{d97a:e61f}} 
        add     a,$f2             ;{{d97c:c6f2}} 
        ld      e,a               ;{{d97e:5f}} 
        adc     a,$ad             ;{{d97f:cead}} 
        sub     e                 ;{{d981:93}} 
        ld      d,a               ;{{d982:57}} 
        ld      a,(de)            ;{{d983:1a}} 
        ld      (accumulator_data_type),a;{{d984:329fb0}} 
        ld      (hl),$0d          ;{{d987:360d}} 
        cp      $05               ;{{d989:fe05}} 
        jr      z,_prob_copy_var_name_onto_execution_stack_24;{{d98b:2803}}  (+$03)
        add     a,$09             ;{{d98d:c609}} 
        ld      (hl),a            ;{{d98f:77}} 
_prob_copy_var_name_onto_execution_stack_24:;{{Addr=$d990 Code Calls/jump count: 2 Data use count: 0}}
        pop     de                ;{{d990:d1}} 
        ld      a,$28             ;{{d991:3e28}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{d993:cd72f6}} 
        push    hl                ;{{d996:e5}} 
        ld      b,$29             ;{{d997:0629}} 
_prob_copy_var_name_onto_execution_stack_29:;{{Addr=$d999 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{d999:05}} 
        jp      z,Error_Syntax_Error;{{d99a:ca49cb}}  Error: Syntax Error
        ld      a,(de)            ;{{d99d:1a}} 
        inc     de                ;{{d99e:13}} 
        and     $df               ;{{d99f:e6df}} 
        ld      (hl),a            ;{{d9a1:77}} 
        inc     hl                ;{{d9a2:23}} 
        rla                       ;{{d9a3:17}} 
        jr      nc,_prob_copy_var_name_onto_execution_stack_29;{{d9a4:30f3}}  (-$0d)
        call    set_execution_stack_next_free_ptr;{{d9a6:cd6ef6}} 
        ex      de,hl             ;{{d9a9:eb}} 
        dec     hl                ;{{d9aa:2b}} 
        pop     de                ;{{d9ab:d1}} 
        jp      get_next_token_skipping_space;{{d9ac:c32cde}}  get next token skipping space

;;=set accum type from variable type atHL
;variable data types = 2/3/4 if have suffix, $b/$c/$d if no suffix
set_accum_type_from_variable_type_atHL:;{{Addr=$d9af Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{d9af:7e}} 
        cp      $0b               ;{{d9b0:fe0b}} No suffix
        jr      c,_set_accum_type_from_variable_type_athl_4;{{d9b2:3802}}  (+$02)
        add     a,$f7             ;{{d9b4:c6f7}} Subtract 9
_set_accum_type_from_variable_type_athl_4:;{{Addr=$d9b6 Code Calls/jump count: 1 Data use count: 0}}
        cp      $04               ;{{d9b6:fe04}} REAL type
        jr      z,set_accum_type_as_REAL;{{d9b8:2809}}  (+$09)
        jr      nc,raise_syntax_error_B;{{d9ba:3004}}  (+$04)
        cp      $02               ;{{d9bc:fe02}} INT type
        jr      nc,set_accumulator_type;{{d9be:3005}}  (+$05)

;;=raise Syntax Error
raise_syntax_error_B:             ;{{Addr=$d9c0 Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Syntax_Error;{{d9c0:c349cb}}  Error: Syntax Error

;;=set accum type as REAL
set_accum_type_as_REAL:           ;{{Addr=$d9c3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$05             ;{{d9c3:3e05}} 
;;=set accumulator type
set_accumulator_type:             ;{{Addr=$d9c5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator_data_type),a;{{d9c5:329fb0}} 
        ret                       ;{{d9c8:c9}} 

;=============
_set_accumulator_type_2:          ;{{Addr=$d9c9 Code Calls/jump count: 1 Data use count: 0}}
        call    zero_6_bytes_at_aded;{{d9c9:cd02d6}} 
        ld      hl,(address_of_start_of_free_space_);{{d9cc:2a6cae}} 
        ex      de,hl             ;{{d9cf:eb}} 
        ld      hl,(address_of_start_of_Arrays_area_);{{d9d0:2a6aae}} 
_set_accumulator_type_6:          ;{{Addr=$d9d3 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_DE     ;{{d9d3:cdd8ff}}  HL=DE?
        ret     z                 ;{{d9d6:c8}} 

        push    de                ;{{d9d7:d5}} 
        call    poss_step_over_string;{{d9d8:cd65d7}} 
        ld      a,(hl)            ;{{d9db:7e}} 
        inc     hl                ;{{d9dc:23}} 
        and     $07               ;{{d9dd:e607}} 
        inc     a                 ;{{d9df:3c}} 
        push    hl                ;{{d9e0:e5}} 
        call    _zero_6_bytes_at_aded_20;{{d9e1:cd27d6}} 
        call    _prob_alloc_space_for_new_var_61;{{d9e4:cdd0d7}} 
        pop     hl                ;{{d9e7:e1}} 
        ld      e,(hl)            ;{{d9e8:5e}} 
        inc     hl                ;{{d9e9:23}} 
        ld      d,(hl)            ;{{d9ea:56}} 
        inc     hl                ;{{d9eb:23}} 
        add     hl,de             ;{{d9ec:19}} 
        pop     de                ;{{d9ed:d1}} 
        jr      _set_accumulator_type_6;{{d9ee:18e3}}  (-$1d)

;;========================================================================
;; command ERASE

command_ERASE:                    ;{{Addr=$d9f0 Code Calls/jump count: 0 Data use count: 1}}
        call    prob_reset_links_to_variables_data;{{d9f0:cd4dea}} 
_command_erase_1:                 ;{{Addr=$d9f3 Code Calls/jump count: 1 Data use count: 0}}
        call    _command_erase_5  ;{{d9f3:cdfcd9}} 
        call    next_token_if_prev_is_comma;{{d9f6:cd41de}} 
        jr      c,_command_erase_1;{{d9f9:38f8}}  (-$08)
        ret                       ;{{d9fb:c9}} 

_command_erase_5:                 ;{{Addr=$d9fc Code Calls/jump count: 1 Data use count: 0}}
        call    get_offset_into_var_table;{{d9fc:cd31d9}} 
        push    hl                ;{{d9ff:e5}} 
        ld      a,(accumulator_data_type);{{da00:3a9fb0}} 
        call    _zero_6_bytes_at_aded_20;{{da03:cd27d6}} 
        call    xd740_code        ;{{da06:cd40d7}} 
        jp      nc,Error_Improper_Argument;{{da09:d24dcb}}  Error: Improper Argument
        ex      de,hl             ;{{da0c:eb}} 
        ld      c,(hl)            ;{{da0d:4e}} 
        inc     hl                ;{{da0e:23}} 
        ld      b,(hl)            ;{{da0f:46}} 
        inc     hl                ;{{da10:23}} 
        add     hl,bc             ;{{da11:09}} 
        call    BC_equal_HL_minus_DE;{{da12:cde4ff}}  BC = HL-DE
        call    move_lower_memory_down;{{da15:cde5f6}} 
        call    prob_grow_array_space_ptrs_by_BC;{{da18:cd21f6}} 
        call    _set_accumulator_type_2;{{da1b:cdc9d9}} 
        pop     hl                ;{{da1e:e1}} 
        ret                       ;{{da1f:c9}} 

;;=clear AE12 AE10 words
clear_AE12_AE10_words:            ;{{Addr=$da20 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$0000          ;{{da20:210000}} ##LIT##
        ld      (RAM_ae12),hl     ;{{da23:2212ae}} 
        ld      (RAM_ae10),hl     ;{{da26:2210ae}} 
        ret                       ;{{da29:c9}} 

;;=prob push FN data on execution stack
prob_push_FN_data_on_execution_stack:;{{Addr=$da2a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da2a:e5}} 
        ld      hl,(RAM_ae10)     ;{{da2b:2a10ae}} 
        ex      de,hl             ;{{da2e:eb}} 
        ld      a,$06             ;{{da2f:3e06}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{da31:cd72f6}} 
        ld      (RAM_ae10),hl     ;{{da34:2210ae}} 
        ld      (hl),e            ;{{da37:73}} 
        inc     hl                ;{{da38:23}} 
        ld      (hl),d            ;{{da39:72}} 
        inc     hl                ;{{da3a:23}} 
        xor     a                 ;{{da3b:af}} 
        ld      (hl),a            ;{{da3c:77}} 
        inc     hl                ;{{da3d:23}} 
        ld      (hl),a            ;{{da3e:77}} 
        inc     hl                ;{{da3f:23}} 
        ld      de,(RAM_ae12)     ;{{da40:ed5b12ae}} 
        ld      (hl),e            ;{{da44:73}} 
        inc     hl                ;{{da45:23}} 
        ld      (hl),d            ;{{da46:72}} 
        pop     hl                ;{{da47:e1}} 
        ret                       ;{{da48:c9}} 

;;=copy ae10 word to ae12
copy_ae10_word_to_ae12:           ;{{Addr=$da49 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da49:e5}} 
        ld      hl,(RAM_ae10)     ;{{da4a:2a10ae}} 
        ld      (RAM_ae12),hl     ;{{da4d:2212ae}} 
        pop     hl                ;{{da50:e1}} 
        ret                       ;{{da51:c9}} 

;;=prob remove FN data from stack
prob_remove_FN_data_from_stack:   ;{{Addr=$da52 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(RAM_ae10)     ;{{da52:2a10ae}} 
        call    set_execution_stack_next_free_ptr;{{da55:cd6ef6}} 
        ld      e,(hl)            ;{{da58:5e}} 
        inc     hl                ;{{da59:23}} 
        ld      d,(hl)            ;{{da5a:56}} 
        inc     hl                ;{{da5b:23}} 
        ld      (RAM_ae10),de     ;{{da5c:ed5310ae}} 
        inc     hl                ;{{da60:23}} 
        inc     hl                ;{{da61:23}} 
        ld      e,(hl)            ;{{da62:5e}} 
        inc     hl                ;{{da63:23}} 
        ld      d,(hl)            ;{{da64:56}} 
        ex      de,hl             ;{{da65:eb}} 
        ld      (RAM_ae12),hl     ;{{da66:2212ae}} 
        ret                       ;{{da69:c9}} 

;;=prob alloc an FN parameter on execution stack
prob_alloc_an_FN_parameter_on_execution_stack:;{{Addr=$da6a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da6a:e5}} 
        ld      a,$02             ;{{da6b:3e02}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{da6d:cd72f6}} 
        ex      (sp),hl           ;{{da70:e3}} 
        call    set_accum_type_from_variable_type_atHL;{{da71:cdafd9}} 
        call    prob_copy_var_name_onto_execution_stack;{{da74:cd6cd9}} 
        ex      (sp),hl           ;{{da77:e3}} 
        ex      de,hl             ;{{da78:eb}} 
        ld      hl,(RAM_ae10)     ;{{da79:2a10ae}} 
        inc     hl                ;{{da7c:23}} 
        inc     hl                ;{{da7d:23}} 
        ld      bc,RESET_ENTRY    ;{{da7e:010000}} 
        call    _prob_alloc_space_for_new_var_61;{{da81:cdd0d7}} 
        ld      a,(accumulator_data_type);{{da84:3a9fb0}} 
        ld      b,a               ;{{da87:47}} 
        inc     a                 ;{{da88:3c}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{da89:cd72f6}} 
        ld      a,b               ;{{da8c:78}} 
        dec     a                 ;{{da8d:3d}} 
        ld      (hl),a            ;{{da8e:77}} 
        inc     hl                ;{{da8f:23}} 
        ex      de,hl             ;{{da90:eb}} 
        pop     hl                ;{{da91:e1}} 
        ret                       ;{{da92:c9}} 

;;takes a code address in DE
_prob_alloc_an_fn_parameter_on_execution_stack_24:;{{Addr=$da93 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(RAM_ae10)     ;{{da93:2a10ae}} 
_prob_alloc_an_fn_parameter_on_execution_stack_25:;{{Addr=$da96 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{da96:7c}} 
        or      l                 ;{{da97:b5}} 
        jr      z,_prob_alloc_an_fn_parameter_on_execution_stack_37;{{da98:280e}}  (+$0e)
        ld      c,(hl)            ;{{da9a:4e}} 
        inc     hl                ;{{da9b:23}} 
        ld      b,(hl)            ;{{da9c:46}} 
        inc     hl                ;{{da9d:23}} 
        push    bc                ;{{da9e:c5}} 
        ld      bc,RESET_ENTRY    ;{{da9f:010000}} 
        call    _prob_alloc_an_fn_parameter_on_execution_stack_81;{{daa2:cde9da}} 
        pop     hl                ;{{daa5:e1}} 
        jr      _prob_alloc_an_fn_parameter_on_execution_stack_25;{{daa6:18ee}}  (-$12)

_prob_alloc_an_fn_parameter_on_execution_stack_37:;{{Addr=$daa8 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$1a41          ;{{daa8:01411a}} 
_prob_alloc_an_fn_parameter_on_execution_stack_38:;{{Addr=$daab Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{daab:c5}} 
        ld      a,c               ;{{daac:79}} 
        call    _zero_6_bytes_at_aded_11;{{daad:cd19d6}} 
        call    _prob_alloc_an_fn_parameter_on_execution_stack_81;{{dab0:cde9da}} 
        pop     bc                ;{{dab3:c1}} 
        inc     c                 ;{{dab4:0c}} 
        djnz    _prob_alloc_an_fn_parameter_on_execution_stack_38;{{dab5:10f4}}  (-$0c)
        ld      a,$03             ;{{dab7:3e03}} 
        call    _zero_6_bytes_at_aded_20;{{dab9:cd27d6}} 
        push    hl                ;{{dabc:e5}} 
_prob_alloc_an_fn_parameter_on_execution_stack_48:;{{Addr=$dabd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{dabd:e1}} 
        ld      c,(hl)            ;{{dabe:4e}} 
        inc     hl                ;{{dabf:23}} 
        ld      b,(hl)            ;{{dac0:46}} 
        ld      a,b               ;{{dac1:78}} 
        or      c                 ;{{dac2:b1}} 
        ret     z                 ;{{dac3:c8}} 

        ld      hl,(address_of_start_of_Arrays_area_);{{dac4:2a6aae}} 
        dec     hl                ;{{dac7:2b}} 
        add     hl,bc             ;{{dac8:09}} 
        push    hl                ;{{dac9:e5}} 
        push    de                ;{{daca:d5}} 
        call    poss_step_over_string;{{dacb:cd65d7}} 
        pop     de                ;{{dace:d1}} 
        inc     hl                ;{{dacf:23}} 
        ld      c,(hl)            ;{{dad0:4e}} 
        inc     hl                ;{{dad1:23}} 
        ld      b,(hl)            ;{{dad2:46}} 
        inc     hl                ;{{dad3:23}} 
        push    hl                ;{{dad4:e5}} 
        add     hl,bc             ;{{dad5:09}} 
        ex      (sp),hl           ;{{dad6:e3}} 
        ld      c,(hl)            ;{{dad7:4e}} 
        inc     hl                ;{{dad8:23}} 
        ld      b,$00             ;{{dad9:0600}} 
        add     hl,bc             ;{{dadb:09}} 
        add     hl,bc             ;{{dadc:09}} 
        pop     bc                ;{{dadd:c1}} 
_prob_alloc_an_fn_parameter_on_execution_stack_76:;{{Addr=$dade Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_BC     ;{{dade:cddeff}}  HL=BC?
        jr      z,_prob_alloc_an_fn_parameter_on_execution_stack_48;{{dae1:28da}}  (-$26)
        call    _prob_alloc_an_fn_parameter_on_execution_stack_99;{{dae3:cd02db}} 
        inc     hl                ;{{dae6:23}} 
        jr      _prob_alloc_an_fn_parameter_on_execution_stack_76;{{dae7:18f5}}  (-$0b)

_prob_alloc_an_fn_parameter_on_execution_stack_81:;{{Addr=$dae9 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{dae9:7e}} 
        inc     hl                ;{{daea:23}} 
        ld      h,(hl)            ;{{daeb:66}} 
        ld      l,a               ;{{daec:6f}} 
        or      h                 ;{{daed:b4}} 
        ret     z                 ;{{daee:c8}} 

        add     hl,bc             ;{{daef:09}} 
        push    hl                ;{{daf0:e5}} 
        push    de                ;{{daf1:d5}} 
        call    poss_step_over_string;{{daf2:cd65d7}} 
        pop     de                ;{{daf5:d1}} 
        ld      a,(hl)            ;{{daf6:7e}} 
        inc     hl                ;{{daf7:23}} 
        and     $07               ;{{daf8:e607}} 
        cp      $02               ;{{dafa:fe02}} 
        call    z,_prob_alloc_an_fn_parameter_on_execution_stack_99;{{dafc:cc02db}} 
        pop     hl                ;{{daff:e1}} 
        jr      _prob_alloc_an_fn_parameter_on_execution_stack_81;{{db00:18e7}}  (-$19)

_prob_alloc_an_fn_parameter_on_execution_stack_99:;{{Addr=$db02 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{db02:c5}} 
        push    de                ;{{db03:d5}} 
        ld      a,(hl)            ;{{db04:7e}} 
        inc     hl                ;{{db05:23}} 
        ld      c,(hl)            ;{{db06:4e}} 
        inc     hl                ;{{db07:23}} 
        ld      b,(hl)            ;{{db08:46}} 
        push    hl                ;{{db09:e5}} 
        ex      de,hl             ;{{db0a:eb}} 
        or      a                 ;{{db0b:b7}} 
        call    nz,JP_HL          ;{{db0c:c4fbff}}  JP (HL)
        pop     hl                ;{{db0f:e1}} 
        pop     de                ;{{db10:d1}} 
        pop     bc                ;{{db11:c1}} 
        ret                       ;{{db12:c9}} 





