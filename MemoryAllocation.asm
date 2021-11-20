;;<< MEMORY ALLOCATION FUNCTIONS
;;< Includes MEMORY, SYMBOL (AFTER)
;;=======================================================

;;initialise memory model
;;sets addresses for where stuff is located in memory
;;HL=?? passed from MC_START_PROGRAM
;;DE=first byte of available memory passed from MC_START_PROGRAM
;;BC=?? passed from MC_START_PROGRAM
initialise_memory_model:          ;{{Addr=$f53f Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,program_line_redundant_spaces_flag_;{{f53f:0100ac}} 
        call    compare_HL_BC     ;{{f542:cddeff}}  HL=BC?
        ret     nc                ;{{f545:d0}} 

        ld      (HIMEM_),hl       ;{{f546:225eae}}  HIMEM
        ld      (address_of_end_of_Strings_area_),hl;{{f549:2273b0}} 
        ld      (address_of_highest_byte_of_free_RAM_),hl;{{f54c:2260ae}} 
        ex      de,hl             ;{{f54f:eb}} 
        ld      (address_of_start_of_ROM_lower_reserved_a),hl;{{f550:2262ae}} start of line entry buffer
        ld      bc,$012f          ;{{f553:012f01}} length of line entry buffer (plus other stuff?)
        add     hl,bc             ;{{f556:09}} 
        ret     c                 ;{{f557:d8}} 

        ld      (address_of_end_of_ROM_lower_reserved_are),hl;{{f558:2264ae}} start of program area?
        ex      de,hl             ;{{f55b:eb}} 
        inc     hl                ;{{f55c:23}} 
        sbc     hl,de             ;{{f55d:ed52}} 
        ret     c                 ;{{f55f:d8}} 

        ld      a,h               ;{{f560:7c}} 
        cp      $04               ;{{f561:fe04}} 
        ret     c                 ;{{f563:d8}} 

        call    clear_RAMb075     ;{{f564:cd7ff7}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f567:326eae}} 
        ret                       ;{{f56a:c9}} 

;;========================================================================
;; command MEMORY

command_MEMORY:                   ;{{Addr=$f56b Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_uint ;{{f56b:cdf5ce}} 
        push    hl                ;{{f56e:e5}} 
        ld      hl,(address_of_highest_byte_of_free_RAM_);{{f56f:2a60ae}} 
        call    compare_HL_DE     ;{{f572:cdd8ff}}  HL=DE?
        jr      c,raise_memory_full_error;{{f575:3831}}  (+$31)
        inc     de                ;{{f577:13}} 
        call    compare_DE_to_HIMEM_plus_1;{{f578:cdecf5}}  compare DE with HIMEM
        call    c,_command_memory_14;{{f57b:dc8af5}} 
        ex      de,hl             ;{{f57e:eb}} 
        call    _symbol_after_18  ;{{f57f:cd08f8}} 
        ld      hl,(RAM_b076)     ;{{f582:2a76b0}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f585:2278b0}} 
        pop     hl                ;{{f588:e1}} 
        ret                       ;{{f589:c9}} 

_command_memory_14:               ;{{Addr=$f58a Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_M_TABLE   ;{{f58a:cdaebb}}  firmware function: TXT GET M TABLE
        ld      bc,(HIMEM_)       ;{{f58d:ed4b5eae}}  HIMEM
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f591:dce0f5}} 
        jr      c,raise_memory_full_error;{{f594:3812}}  (+$12)
        ld      hl,(RAM_b076)     ;{{f596:2a76b0}} 
        dec     hl                ;{{f599:2b}} 
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f59a:cde0f5}} 
        ret     nc                ;{{f59d:d0}} 

        ld      a,(RAM_b075)      ;{{f59e:3a75b0}} 
        or      a                 ;{{f5a1:b7}} 
        ret     z                 ;{{f5a2:c8}} 

        cp      $04               ;{{f5a3:fe04}} 
        jp      z,clear_RAMb075   ;{{f5a5:ca7ff7}} 
;;=raise memory full error
raise_memory_full_error:          ;{{Addr=$f5a8 Code Calls/jump count: 3 Data use count: 0}}
        jp      raise_memory_full_error_C;{{f5a8:c375f8}} 

_raise_memory_full_error_1:       ;{{Addr=$f5ab Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{f5ab:d5}} 
        ex      de,hl             ;{{f5ac:eb}} 
        add     hl,bc             ;{{f5ad:09}} 
        dec     hl                ;{{f5ae:2b}} 
        ld      bc,(address_of_start_of_ROM_lower_reserved_a);{{f5af:ed4b62ae}} input buffer address
        ex      (sp),hl           ;{{f5b3:e3}} 
        ex      de,hl             ;{{f5b4:eb}} 
        ld      hl,(HIMEM_)       ;{{f5b5:2a5eae}}  HIMEM
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f5b8:cde0f5}} 
        ex      de,hl             ;{{f5bb:eb}} 
        ex      (sp),hl           ;{{f5bc:e3}} 
        ex      de,hl             ;{{f5bd:eb}} 
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f5be:dce0f5}} 
        jr      nc,raise_memory_full_error;{{f5c1:30e5}}  (-$1b)
        ld      bc,(RAM_b076)     ;{{f5c3:ed4b76b0}} 
        ld      hl,$0fff          ;{{f5c7:21ff0f}} 
        add     hl,bc             ;{{f5ca:09}} 
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f5cb:cde0f5}} 
        pop     de                ;{{f5ce:d1}} 
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f5cf:dce0f5}} 
        ret     c                 ;{{f5d2:d8}} 

        ex      de,hl             ;{{f5d3:eb}} 
        ld      d,b               ;{{f5d4:50}} 
        ld      e,c               ;{{f5d5:59}} 
        call    compare_DE_to_HIMEM_plus_1;{{f5d6:cdecf5}}  compare DE with HIMEM
        jp      nz,clear_RAMb075  ;{{f5d9:c27ff7}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f5dc:2278b0}} 
        ret                       ;{{f5df:c9}} 

;;=========================
;;compare HL minus BC to DE minus BC
compare_HL_minus_BC_to_DE_minus_BC:;{{Addr=$f5e0 Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{f5e0:d5}} 
        push    hl                ;{{f5e1:e5}} 
        or      a                 ;{{f5e2:b7}} 
        sbc     hl,bc             ;{{f5e3:ed42}} 
        ex      de,hl             ;{{f5e5:eb}} 
        or      a                 ;{{f5e6:b7}} 
        sbc     hl,bc             ;{{f5e7:ed42}} 
        ex      de,hl             ;{{f5e9:eb}} 
        jr      _compare_de_to_himem_plus_1_4;{{f5ea:1806}}  (+$06)

;;===========================
;;=compare DE to HIMEM plus 1
compare_DE_to_HIMEM_plus_1:       ;{{Addr=$f5ec Code Calls/jump count: 4 Data use count: 0}}
        push    de                ;{{f5ec:d5}} 
        push    hl                ;{{f5ed:e5}} 
        ld      hl,(HIMEM_)       ;{{f5ee:2a5eae}}  HIMEM
        inc     hl                ;{{f5f1:23}} 
_compare_de_to_himem_plus_1_4:    ;{{Addr=$f5f2 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_DE     ;{{f5f2:cdd8ff}}  HL=DE?
        pop     hl                ;{{f5f5:e1}} 
        pop     de                ;{{f5f6:d1}} 
        ret                       ;{{f5f7:c9}} 

;;==========================
;;=get size of strings area in BC
get_size_of_strings_area_in_BC:   ;{{Addr=$f5f8 Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{f5f8:d5}} 
        push    hl                ;{{f5f9:e5}} 
        ld      hl,(address_of_end_of_free_space_);{{f5fa:2a71b0}} 
        ex      de,hl             ;{{f5fd:eb}} 
        ld      hl,(address_of_end_of_Strings_area_);{{f5fe:2a73b0}} 
        call    BC_equal_HL_minus_DE;{{f601:cde4ff}}  BC = HL-DE
        pop     hl                ;{{f604:e1}} 
        pop     de                ;{{f605:d1}} 
        ret                       ;{{f606:c9}} 

;;=prob grow all program space pointers by BC
prob_grow_all_program_space_pointers_by_BC:;{{Addr=$f607 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_after_end_of_program);{{f607:2a66ae}} 
        add     hl,bc             ;{{f60a:09}} 
        ld      (address_after_end_of_program),hl;{{f60b:2266ae}} 
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f60e:3a6eae}} 
        or      a                 ;{{f611:b7}} 
        ret     nz                ;{{f612:c0}} 

;;=prob grow program space ptrs by BC
;;(but DOESN'T do any memory moving)
prob_grow_program_space_ptrs_by_BC:;{{Addr=$f613 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f613:2a68ae}} 
        add     hl,bc             ;{{f616:09}} 
        ld      (address_of_start_of_Variables_and_DEF_FN),hl;{{f617:2268ae}} 
;;=prob grow variables space ptrs by BC
prob_grow_variables_space_ptrs_by_BC:;{{Addr=$f61a Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_Arrays_area_);{{f61a:2a6aae}} 
        add     hl,bc             ;{{f61d:09}} 
        ld      (address_of_start_of_Arrays_area_),hl;{{f61e:226aae}} 
;;=prob grow array space ptrs by BC
prob_grow_array_space_ptrs_by_BC: ;{{Addr=$f621 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f621:2a6cae}} 
        add     hl,bc             ;{{f624:09}} 
        ld      (address_of_start_of_free_space_),hl;{{f625:226cae}} 
        ret                       ;{{f628:c9}} 

;;==============================
;;prob move vars and arrays to end of memory
prob_move_vars_and_arrays_to_end_of_memory:;{{Addr=$f629 Code Calls/jump count: 3 Data use count: 0}}
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{f629:cdfcf6}} 
        ld      b,h               ;{{f62c:44}} 
        ld      c,l               ;{{f62d:4d}} 
        ld      hl,(address_after_end_of_program);{{f62e:2a66ae}} 
        ex      de,hl             ;{{f631:eb}} 
        call    unknown_alloc_and_move_memory_up;{{f632:cdb8f6}} 
        ld      a,$ff             ;{{f635:3eff}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f637:326eae}} 
        jr      prob_grow_program_space_ptrs_by_BC;{{f63a:18d7}}  (-$29)

;;=============================
;;prob move vars and arrays back from end of memory
prob_move_vars_and_arrays_back_from_end_of_memory:;{{Addr=$f63c Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{f63c:af}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f63d:326eae}} 
        ld      hl,(address_after_end_of_program);{{f640:2a66ae}} 
        ex      de,hl             ;{{f643:eb}} 
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f644:2a68ae}} 
        call    BC_equal_HL_minus_DE;{{f647:cde4ff}}  BC = HL-DE
        call    move_lower_memory_down;{{f64a:cde5f6}} 
        jr      prob_grow_program_space_ptrs_by_BC;{{f64d:18c4}}  (-$3c)

;;==============================
;;prob clear execution stack
prob_clear_execution_stack:       ;{{Addr=$f64f Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$ae6f          ;{{f64f:216fae}} 
        ld      (execution_stack_next_free_ptr),hl;{{f652:226fb0}} 
        ld      a,$01             ;{{f655:3e01}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{f657:cd72f6}} 
        ld      (hl),$00          ;{{f65a:3600}} 
        inc     hl                ;{{f65c:23}} 

;;=set execution stack next free ptr and its cache
set_execution_stack_next_free_ptr_and_its_cache:;{{Addr=$f65d Code Calls/jump count: 9 Data use count: 0}}
        ld      (cache_of_execution_stack_next_free_ptr),hl;{{f65d:2219ae}} 
        jr      set_execution_stack_next_free_ptr;{{f660:180c}}  (+$0c)

;;======================================
;;probably remove A bytes off execution stack and get address
probably_remove_A_bytes_off_execution_stack_and_get_address:;{{Addr=$f662 Code Calls/jump count: 6 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{f662:2a6fb0}} 
        cpl                       ;{{f665:2f}} 
        inc     a                 ;{{f666:3c}} 
        ret     z                 ;{{f667:c8}} 

        add     a,l               ;{{f668:85}} 
        ld      l,a               ;{{f669:6f}} 
        ld      a,$ff             ;{{f66a:3eff}} 
        adc     a,h               ;{{f66c:8c}} 
        ld      h,a               ;{{f66d:67}} 

;;=set execution stack next free ptr
set_execution_stack_next_free_ptr:;{{Addr=$f66e Code Calls/jump count: 5 Data use count: 0}}
        ld      (execution_stack_next_free_ptr),hl;{{f66e:226fb0}} 
        ret                       ;{{f671:c9}} 

;;===================================
;;possibly alloc A bytes on execution stack
possibly_alloc_A_bytes_on_execution_stack:;{{Addr=$f672 Code Calls/jump count: 10 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{f672:2a6fb0}} 
        push    hl                ;{{f675:e5}} 
        add     a,l               ;{{f676:85}}  HL = HL + A?
        ld      l,a               ;{{f677:6f}} 
        adc     a,h               ;{{f678:8c}} 
        sub     l                 ;{{f679:95}} 
        ld      h,a               ;{{f67a:67}} 
        ld      (execution_stack_next_free_ptr),hl;{{f67b:226fb0}} 
        ld      a,$94             ;{{f67e:3e94}} check for stack overflow???   
        add     a,l               ;{{f680:85}} 
        ld      a,$4f             ;{{f681:3e4f}} 
        adc     a,h               ;{{f683:8c}} 
        pop     hl                ;{{f684:e1}} 
        ret     nc                ;{{f685:d0}} 

        call    prob_clear_execution_stack;{{f686:cd4ff6}} 
        jp      raise_memory_full_error_C;{{f689:c375f8}} 

;;==================================
;;empty strings area
empty_strings_area:               ;{{Addr=$f68c Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_Strings_area_);{{f68c:2a73b0}} 
        ld      (address_of_end_of_free_space_),hl;{{f68f:2271b0}} 
        ret                       ;{{f692:c9}} 

;;==============================
;;alloc C bytes in string space
alloc_C_bytes_in_string_space:    ;{{Addr=$f693 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{f693:0600}} 
;;=alloc BC bytes in string space
alloc_BC_bytes_in_string_space:   ;{{Addr=$f695 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f695:2a6cae}} 
        ex      de,hl             ;{{f698:eb}} 
        ld      hl,(address_of_end_of_free_space_);{{f699:2a71b0}} 
        or      a                 ;{{f69c:b7}} 
        sbc     hl,bc             ;{{f69d:ed42}} 
        dec     hl                ;{{f69f:2b}} 
        dec     hl                ;{{f6a0:2b}} 
        call    compare_HL_DE     ;{{f6a1:cdd8ff}}  HL=DE?
        jr      nc,poss_alloc_and_write_string_pointer;{{f6a4:3009}}  (+$09)
        call    _function_fre_6   ;{{f6a6:cd64fc}} 
        jr      c,alloc_BC_bytes_in_string_space;{{f6a9:38ea}}  (-$16)
        call    byte_following_call_is_error_code;{{f6ab:cd45cb}} 
        defb $0e                  ;Inline error code: String Space Full error

;;===============================
;;poss alloc and write string pointer
poss_alloc_and_write_string_pointer:;{{Addr=$f6af Code Calls/jump count: 1 Data use count: 0}}
        ld (address_of_end_of_free_space_),hl;{{f6af:2271b0}} 
        inc     hl                ;{{f6b2:23}} 
        ld      (hl),c            ;{{f6b3:71}} 
        inc     hl                ;{{f6b4:23}} 
        ld      (hl),b            ;{{f6b5:70}} 
        inc     hl                ;{{f6b6:23}} 
        ret                       ;{{f6b7:c9}} 

;;================================
;;unknown alloc and move memory up
;I think this moves memory between DE and HL up by BC bytes
unknown_alloc_and_move_memory_up: ;{{Addr=$f6b8 Code Calls/jump count: 4 Data use count: 0}}
        call    get_start_of_free_space;{{f6b8:cd14f7}} 
_unknown_alloc_and_move_memory_up_1:;{{Addr=$f6bb Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f6bb:c5}} 
        push    de                ;{{f6bc:d5}} 
        push    de                ;{{f6bd:d5}} 
        push    hl                ;{{f6be:e5}} 
        add     hl,bc             ;{{f6bf:09}} 
        jr      c,raise_memory_full_error_B;{{f6c0:380e}}  (+$0e)
        ex      de,hl             ;{{f6c2:eb}} 
_unknown_alloc_and_move_memory_up_8:;{{Addr=$f6c3 Code Calls/jump count: 1 Data use count: 0}}
        call    get_end_of_free_space_or_start_of_variables;{{f6c3:cd07f7}} 
        call    compare_HL_DE     ;{{f6c6:cdd8ff}}  HL=DE?
        jr      nc,move_lower_memory_up;{{f6c9:3008}}  (+$08)
        call    _function_fre_6   ;{{f6cb:cd64fc}} 
        jr      c,_unknown_alloc_and_move_memory_up_8;{{f6ce:38f3}}  (-$0d)
;;=raise Memory Full error
raise_memory_full_error_B:        ;{{Addr=$f6d0 Code Calls/jump count: 1 Data use count: 0}}
        jp      raise_memory_full_error_C;{{f6d0:c375f8}} 

;;=================================
;;move lower memory up
move_lower_memory_up:             ;{{Addr=$f6d3 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f6d3:e1}} 
        pop     bc                ;{{f6d4:c1}} 
        push    de                ;{{f6d5:d5}} 
        ld      a,l               ;{{f6d6:7d}} BC=HL-BC
        sub     c                 ;{{f6d7:91}} 
        ld      c,a               ;{{f6d8:4f}} 
        ld      a,h               ;{{f6d9:7c}} 
        sbc     a,b               ;{{f6da:98}} 
        ld      b,a               ;{{f6db:47}} 
        dec     hl                ;{{f6dc:2b}} 
        dec     de                ;{{f6dd:1b}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f6de:cdf5ff}}  copy bytes LDDR (BC = count)
        pop     hl                ;{{f6e1:e1}} 
        pop     de                ;{{f6e2:d1}} 
        pop     bc                ;{{f6e3:c1}} 
        ret                       ;{{f6e4:c9}} 

;;===================================
;;move lower memory down
move_lower_memory_down:           ;{{Addr=$f6e5 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{f6e5:c5}} 
        push    de                ;{{f6e6:d5}} 
        ex      de,hl             ;{{f6e7:eb}} DE=DE+BC
        add     hl,bc             ;{{f6e8:09}} 
        ex      de,hl             ;{{f6e9:eb}} 
        call    get_start_of_free_space;{{f6ea:cd14f7}} 
        call    BC_equal_HL_minus_DE;{{f6ed:cde4ff}}  BC = HL-DE
        ex      de,hl             ;{{f6f0:eb}} 
        pop     de                ;{{f6f1:d1}} 
        call    copy_bytes_LDIR_BCcount_HLsource_DEdest;{{f6f2:cdefff}}  copy bytes LDIR (BC = count)
        pop     de                ;{{f6f5:d1}} 
        ld      hl,RESET_ENTRY    ;{{f6f6:210000}} 
        jp      BC_equal_HL_minus_DE;{{f6f9:c3e4ff}}  BC = HL-DE

;;============================
;;get free space byte count in HL addr in DE
get_free_space_byte_count_in_HL_addr_in_DE:;{{Addr=$f6fc Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f6fc:2a6cae}} 
        ex      de,hl             ;{{f6ff:eb}} 
        ld      hl,(address_of_end_of_free_space_);{{f700:2a71b0}} 
        or      a                 ;{{f703:b7}} 
        sbc     hl,de             ;{{f704:ed52}} 
        ret                       ;{{f706:c9}} 

;;==============================
;;get end of free space or start of variables
get_end_of_free_space_or_start_of_variables:;{{Addr=$f707 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f707:3a6eae}} 
        or      a                 ;{{f70a:b7}} 
        ld      hl,(address_of_end_of_free_space_);{{f70b:2a71b0}} 
        ret     z                 ;{{f70e:c8}} 

        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f70f:2a68ae}} 
        dec     hl                ;{{f712:2b}} 
        ret                       ;{{f713:c9}} 

;;==================================
;;get start of free space
get_start_of_free_space:          ;{{Addr=$f714 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f714:3a6eae}} 
        or      a                 ;{{f717:b7}} 
        ld      hl,(address_of_start_of_free_space_);{{f718:2a6cae}} 
        ret     z                 ;{{f71b:c8}} 

        ld      hl,(address_after_end_of_program);{{f71c:2a66ae}} 
        ret                       ;{{f71f:c9}} 

;;=prob alloc 2k file buffer
prob_alloc_2k_file_buffer:        ;{{Addr=$f720 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0001          ;{{f720:110100}} 
        jr      _prob_alloc_2k_file_buffer_c_1;{{f723:1808}}  (+$08)

;;=prob alloc 2k file buffer
prob_alloc_2k_file_buffer_B:      ;{{Addr=$f725 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0802          ;{{f725:110208}} 
        jr      _prob_alloc_2k_file_buffer_c_1;{{f728:1803}}  (+$03)

;;=prob alloc 2k file buffer
;returns address in DE
prob_alloc_2k_file_buffer_C:      ;{{Addr=$f72a Code Calls/jump count: 2 Data use count: 0}}
        ld      de,$0800          ;{{f72a:110008}} 
_prob_alloc_2k_file_buffer_c_1:   ;{{Addr=$f72d Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f72d:c5}} 
        push    hl                ;{{f72e:e5}} 
        ld      a,(RAM_b075)      ;{{f72f:3a75b0}} 
        or      a                 ;{{f732:b7}} 
        jr      nz,_prob_alloc_2k_file_buffer_c_17;{{f733:2018}}  (+$18)
        push    de                ;{{f735:d5}} 
        ld      hl,(HIMEM_)       ;{{f736:2a5eae}}  HIMEM
        inc     hl                ;{{f739:23}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f73a:2278b0}} 
        ld      de,$f000          ;{{f73d:1100f0}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{f740:19}} 
        jp      nc,raise_memory_full_error_C;{{f741:d275f8}} 
        call    _symbol_after_18  ;{{f744:cd08f8}} 
        ld      (RAM_b076),hl     ;{{f747:2276b0}} 
        pop     de                ;{{f74a:d1}} 
        ld      a,$04             ;{{f74b:3e04}} 
_prob_alloc_2k_file_buffer_c_17:  ;{{Addr=$f74d Code Calls/jump count: 1 Data use count: 0}}
        or      e                 ;{{f74d:b3}} 
        ld      hl,(RAM_b076)     ;{{f74e:2a76b0}} 
        ld      e,$00             ;{{f751:1e00}} 
        add     hl,de             ;{{f753:19}} 
        ex      de,hl             ;{{f754:eb}} 
        pop     hl                ;{{f755:e1}} 
        pop     bc                ;{{f756:c1}} 
        jr      set_RAMb075       ;{{f757:1827}}  (+$27)

;;=prob release 2k file buffer
prob_release_2k_file_buffer:      ;{{Addr=$f759 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$fe             ;{{f759:3efe}} 
        jr      _prob_release_2k_file_buffer_c_1;{{f75b:1806}}  (+$06)

;;=prob release 2k file buffer
prob_release_2k_file_buffer_B:    ;{{Addr=$f75d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$fd             ;{{f75d:3efd}} 
        jr      _prob_release_2k_file_buffer_c_1;{{f75f:1802}}  (+$02)

;;=prob release 2k file buffer
;DE=address
prob_release_2k_file_buffer_C:    ;{{Addr=$f761 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$ff             ;{{f761:3eff}} 
_prob_release_2k_file_buffer_c_1: ;{{Addr=$f763 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{f763:e5}} 
        ld      hl,RAM_b075       ;{{f764:2175b0}} 
        and     (hl)              ;{{f767:a6}} 
        ld      (hl),a            ;{{f768:77}} 
        cp      $04               ;{{f769:fe04}} 
        jr      nz,_prob_release_2k_file_buffer_c_11;{{f76b:2009}}  (+$09)
        ld      hl,(RAM_b076)     ;{{f76d:2a76b0}} 
        ex      de,hl             ;{{f770:eb}} 
        call    compare_DE_to_HIMEM_plus_1;{{f771:cdecf5}}  compare DE with HIMEM
        jr      z,_prob_release_2k_file_buffer_c_13;{{f774:2802}}  (+$02)
_prob_release_2k_file_buffer_c_11:;{{Addr=$f776 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f776:e1}} 
        ret                       ;{{f777:c9}} 

_prob_release_2k_file_buffer_c_13:;{{Addr=$f778 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_the_highest_byte_of_free_RAM_);{{f778:2a78b0}} 
        call    _symbol_after_18  ;{{f77b:cd08f8}} 
        pop     hl                ;{{f77e:e1}} 

;;=clear RAM_b075
clear_RAMb075:                    ;{{Addr=$f77f Code Calls/jump count: 3 Data use count: 0}}
        xor     a                 ;{{f77f:af}} 
;;=set RAM_b075
set_RAMb075:                      ;{{Addr=$f780 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b075),a      ;{{f780:3275b0}} 
        ret                       ;{{f783:c9}} 

;;========================================================================
;; command SYMBOL
command_SYMBOL:                   ;{{Addr=$f784 Code Calls/jump count: 0 Data use count: 1}}
        cp      $80               ;{{f784:fe80}}  AFTER
        jr      z,_command_symbol_26;{{f786:2829}}  (+$29)
        call    eval_expr_as_byte_or_error;{{f788:cdb8ce}}  get number and check it's less than 255 
        ld      c,a               ;{{f78b:4f}} 
        call    next_token_if_comma;{{f78c:cd15de}}  check for comma
        ld      b,$08             ;{{f78f:0608}} 
        scf                       ;{{f791:37}} 
_command_symbol_7:                ;{{Addr=$f792 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,next_token_if_prev_is_comma;{{f792:d441de}} 
        sbc     a,a               ;{{f795:9f}} 
        call    c,eval_expr_as_byte_or_error;{{f796:dcb8ce}}  get number and check it's less than 255 
        push    af                ;{{f799:f5}} 
        or      a                 ;{{f79a:b7}} 
        djnz    _command_symbol_7 ;{{f79b:10f5}}  (-$0b)
        ex      de,hl             ;{{f79d:eb}} 
        ld      a,c               ;{{f79e:79}} 
        call    TXT_GET_MATRIX    ;{{f79f:cda5bb}}  firmware function: TXT GET MATRIX		
        jp      nc,Error_Improper_Argument;{{f7a2:d24dcb}}  Error: Improper Argument
        ld      bc,LOW_JUMP       ;{{f7a5:010800}} 
        add     hl,bc             ;{{f7a8:09}} 
_command_symbol_19:               ;{{Addr=$f7a9 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{f7a9:f1}} 
        dec     hl                ;{{f7aa:2b}} 
        ld      (hl),a            ;{{f7ab:77}} 
        dec     c                 ;{{f7ac:0d}} 
        jr      nz,_command_symbol_19;{{f7ad:20fa}}  (-$06)
        ex      de,hl             ;{{f7af:eb}} 
        ret                       ;{{f7b0:c9}} 

_command_symbol_26:               ;{{Addr=$f7b1 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{f7b1:cd2cde}}  get next token skipping space
        call    eval_expr_as_int  ;{{f7b4:cdd8ce}}  get number
        push    hl                ;{{f7b7:e5}} 
        ld      hl,$0100          ;{{f7b8:210001}} 
        call    compare_HL_DE     ;{{f7bb:cdd8ff}}  HL=DE?
        jp      c,Error_Improper_Argument;{{f7be:da4dcb}}  Error: Improper Argument
        push    de                ;{{f7c1:d5}} 
        call    TXT_GET_M_TABLE   ;{{f7c2:cdaebb}}  firmware function: TXT GET M TABLE
        ex      de,hl             ;{{f7c5:eb}} 
        jr      nc,_command_symbol_50;{{f7c6:301b}}  (+$1b)
;; A = first character
;; HL = address of table
        cpl                       ;{{f7c8:2f}} 
        ld      l,a               ;{{f7c9:6f}} 
        ld      h,$00             ;{{f7ca:2600}} 
        inc     hl                ;{{f7cc:23}} 
        add     hl,hl             ;{{f7cd:29}}  x2
        add     hl,hl             ;{{f7ce:29}}  x4
        add     hl,hl             ;{{f7cf:29}}  x8
        call    compare_DE_to_HIMEM_plus_1;{{f7d0:cdecf5}}  compare DE with HIMEM
        jp      nz,Error_Improper_Argument;{{f7d3:c24dcb}}  Error: Improper Argument
        add     hl,de             ;{{f7d6:19}} 
        call    _symbol_after_18  ;{{f7d7:cd08f8}} 
        call    prob_release_2k_file_buffer_C;{{f7da:cd61f7}} 
                                  ; HL = Address of table
        ld      de,$0100          ;{{f7dd:110001}}  first character in table
        call    TXT_SET_M_TABLE   ;{{f7e0:cdabbb}}  firmware function: TXT SET M TABLE
_command_symbol_50:               ;{{Addr=$f7e3 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f7e3:d1}} 
        call    SYMBOL_AFTER      ;{{f7e4:cde9f7}}  no defined table
        pop     hl                ;{{f7e7:e1}} 
        ret                       ;{{f7e8:c9}} 

;;+-------------
;; SYMBOL AFTER
;; A = number
SYMBOL_AFTER:                     ;{{Addr=$f7e9 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$0100          ;{{f7e9:210001}} 
        or      a                 ;{{f7ec:b7}} 
        sbc     hl,de             ;{{f7ed:ed52}} 
        ret     z                 ;{{f7ef:c8}} 

        push    de                ;{{f7f0:d5}} 
        add     hl,hl             ;{{f7f1:29}} 
        add     hl,hl             ;{{f7f2:29}} 
        add     hl,hl             ;{{f7f3:29}} 
        ex      de,hl             ;{{f7f4:eb}} 
        ld      hl,(HIMEM_)       ;{{f7f5:2a5eae}}  HIMEM
        sbc     hl,de             ;{{f7f8:ed52}} 
        ld      a,h               ;{{f7fa:7c}} 
        cp      $40               ;{{f7fb:fe40}} 
        jp      c,raise_memory_full_error_C;{{f7fd:da75f8}} 
        inc     hl                ;{{f800:23}} 
        call    _symbol_after_18  ;{{f801:cd08f8}} 
        pop     de                ;{{f804:d1}} 
        jp      TXT_SET_M_TABLE   ;{{f805:c3abbb}}  firmware function: TXT SET M TABLE


_symbol_after_18:                 ;{{Addr=$f808 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{f808:e5}} 
        call    _function_fre_6   ;{{f809:cd64fc}} 
        ex      de,hl             ;{{f80c:eb}} 
        call    get_size_of_strings_area_in_BC;{{f80d:cdf8f5}} 
        ld      hl,(address_of_start_of_free_space_);{{f810:2a6cae}} 
        add     hl,bc             ;{{f813:09}} 
        ccf                       ;{{f814:3f}} 
        call    c,compare_HL_DE   ;{{f815:dcd8ff}}  HL=DE?
        jr      nc,raise_memory_full_error_C;{{f818:305b}}  (+$5b)
        ld      hl,(HIMEM_)       ;{{f81a:2a5eae}}  HIMEM
        ex      de,hl             ;{{f81d:eb}} 
        scf                       ;{{f81e:37}} 
        sbc     hl,de             ;{{f81f:ed52}} 
        ld      (RAM_b07a),hl     ;{{f821:227ab0}} 
        push    hl                ;{{f824:e5}} 
        ld      de,_symbol_after_72;{{f825:1165f8}}   ##LABEL##
        call    iterate_all_string_variables;{{f828:cd93da}} 
        pop     bc                ;{{f82b:c1}} 
        ld      a,b               ;{{f82c:78}} 
        rlca                      ;{{f82d:07}} 
        jr      c,_symbol_after_51;{{f82e:3814}}  (+$14)
        or      c                 ;{{f830:b1}} 
        jr      z,_symbol_after_67;{{f831:282b}}  (+$2b)
        ld      hl,(address_of_end_of_Strings_area_);{{f833:2a73b0}} 
        ld      d,h               ;{{f836:54}} 
        ld      e,l               ;{{f837:5d}} 
        add     hl,bc             ;{{f838:09}} 
        push    hl                ;{{f839:e5}} 
        call    get_size_of_strings_area_in_BC;{{f83a:cdf8f5}} 
        ex      de,hl             ;{{f83d:eb}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f83e:cdf5ff}}  copy bytes LDDR (BC = count)
        pop     hl                ;{{f841:e1}} 
        jr      _symbol_after_64  ;{{f842:1813}}  (+$13)

_symbol_after_51:                 ;{{Addr=$f844 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_free_space_);{{f844:2a71b0}} 
        ld      d,h               ;{{f847:54}} 
        ld      e,l               ;{{f848:5d}} 
        add     hl,bc             ;{{f849:09}} 
        push    hl                ;{{f84a:e5}} 
        call    get_size_of_strings_area_in_BC;{{f84b:cdf8f5}} 
        ex      de,hl             ;{{f84e:eb}} 
        inc     hl                ;{{f84f:23}} 
        inc     de                ;{{f850:13}} 
        call    copy_bytes_LDIR_BCcount_HLsource_DEdest;{{f851:cdefff}}  copy bytes LDIR (BC = count)
        ex      de,hl             ;{{f854:eb}} 
        dec     hl                ;{{f855:2b}} 
        pop     de                ;{{f856:d1}} 
_symbol_after_64:                 ;{{Addr=$f857 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_end_of_Strings_area_),hl;{{f857:2273b0}} 
        ex      de,hl             ;{{f85a:eb}} 
        ld      (address_of_end_of_free_space_),hl;{{f85b:2271b0}} 
_symbol_after_67:                 ;{{Addr=$f85e Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f85e:e1}} 
        dec     hl                ;{{f85f:2b}} 
        ld      (HIMEM_),hl       ;{{f860:225eae}}  HIMEM
        inc     hl                ;{{f863:23}} 
        ret                       ;{{f864:c9}} 

_symbol_after_72:                 ;{{Addr=$f865 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_after_end_of_program);{{f865:2a66ae}} 
        call    compare_HL_BC     ;{{f868:cddeff}}  HL=BC?
        ret     nc                ;{{f86b:d0}} 

        ld      hl,(RAM_b07a)     ;{{f86c:2a7ab0}} 
        add     hl,bc             ;{{f86f:09}} 
        ex      de,hl             ;{{f870:eb}} 
        ld      (hl),d            ;{{f871:72}} 
        dec     hl                ;{{f872:2b}} 
        ld      (hl),e            ;{{f873:73}} 
        ret                       ;{{f874:c9}} 

;;=raise Memory Full error
raise_memory_full_error_C:        ;{{Addr=$f875 Code Calls/jump count: 6 Data use count: 0}}
        call    byte_following_call_is_error_code;{{f875:cd45cb}} 
        defb $07                  ;Inline error code: Memory full






