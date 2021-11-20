;;<< VARIABLE ALLOCATION AND ASSIGNMENT
;;< DEFINT/REAL/STR, LET, DIM, ERASE
;;< (Lots more work to do here)
;;===================================

;;=delete program
delete_program:                   ;{{Addr=$d5ea Code Calls/jump count: 2 Data use count: 0}}
        call    prob_reset_variable_linked_list_pointers;{{d5ea:cdfad5}} 
        ld      hl,(address_after_end_of_program);{{d5ed:2a66ae}} 
        ld      (address_of_start_of_Variables_and_DEF_FN),hl;{{d5f0:2268ae}} 
        ld      (address_of_start_of_Arrays_area_),hl;{{d5f3:226aae}} 
        ld      (address_of_start_of_free_space_),hl;{{d5f6:226cae}} 
        ret                       ;{{d5f9:c9}} 

;;=prob reset variable linked list pointers
;zero 36h bytes at adb7
prob_reset_variable_linked_list_pointers:;{{Addr=$d5fa Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,linked_list_headers_for_variables;{{d5fa:21b7ad}} 
        ld      a,$36             ;{{d5fd:3e36}} 
        call    zero_A_bytes_at_HL;{{d5ff:cd07d6}} 

;;=reset array linked list headers
;zero 6 bytes at aded
reset_array_linked_list_headers:  ;{{Addr=$d602 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,real_array_linked_list_head;{{d602:21edad}} 
        ld      a,$06             ;{{d605:3e06}} 

;;=zero A bytes at HL
zero_A_bytes_at_HL:               ;{{Addr=$d607 Code Calls/jump count: 2 Data use count: 0}}
        ld      (hl),$00          ;{{d607:3600}} 
        inc     hl                ;{{d609:23}} 
        dec     a                 ;{{d60a:3d}} 
        jr      nz,zero_A_bytes_at_HL;{{d60b:20fa}}  (-$06)
        ret                       ;{{d60d:c9}} 

;;===================================
;;=clear DEFFN list and reset variable types and pointers
clear_DEFFN_list_and_reset_variable_types_and_pointers:;{{Addr=$d60e Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$0000          ;{{d60e:210000}} ##LIT##
        ld      (DEFFN_linked_list_head),hl;{{d611:22ebad}} 
        jp      reset_variable_types_and_pointers;{{d614:c34dea}} 

;;===================================
;;=get VarFN area and FN list head ptr
get_VarFN_area_and_FN_list_head_ptr:;{{Addr=$d617 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$5b             ;{{d617:3e5b}} 91 Returns with HL=&ade6

;;=get VarFN area and list head ptr
;Calculates an address for a linked list header relative to &ad35
;Entry: A=a value between &41 .. &5b, i.e. one of 'A'..'Z','[' (that final entry is for DEF FNs)
;Exit: BC=addr of variables/DEF FN area -1
;HL=address (based on A) in the BASIC data area of a pointer to a linked list
;HL=&ad35 + (A*2) = (&adb7 - ('A' * 2)) + (A * 2)
;where &adb7 is the block of data for the variable linked list headers
get_VarFN_area_and_list_head_ptr: ;{{Addr=$d619 Code Calls/jump count: 3 Data use count: 0}}
        ld      bc,(address_of_start_of_Variables_and_DEF_FN);{{d619:ed4b68ae}} 
        dec     bc                ;{{d61d:0b}} A=&41   |&5b 
        add     a,a               ;{{d61e:87}} A=&82   |&b6  A=A*2
        add a,linked_list_headers_for_variables - ('A' * 2) and $ff;{{d61e:c635}} formula version
;OLDd61f c635      add     a,$35            ;A=&b7   |&eb. A=A*2+53
        ld      l,a               ;{{d621:6f}} L=&b7   |&eb
        adc a,linked_list_headers_for_variables >> 8;{{d622:cead}} formula version
;OLDd622 cead      adc     a,$ad            ;A=&(1)64|$(1)98 (ie. carry)  173 
        sub     l                 ;{{d624:95}} A=&ad   |$ad
        ld      h,a               ;{{d625:67}} HL=&adb7|&adeb
        ret                       ;{{d626:c9}} 

;;===================================
;;=get array area and array list head ptr for type
;Usually (always?) called with A=a variable data type 
;Entry: A=variable data type (which equals a variable data size) = 2,3 or 5
;Exit: BC=addr of arrays area -1
;HL=address (based on A) in the BASIC data area (adef, adf1, or aded) of
;a pointer for a linked list of arrays of the given type
;Calculates: HL=&aded + (((A and 3) - 1) * 2)
get_array_area_and_array_list_head_ptr_for_type:;{{Addr=$d627 Code Calls/jump count: 6 Data use count: 0}}
        ld      bc,(address_of_start_of_Arrays_area_);{{d627:ed4b6aae}} 
        dec     bc                ;{{d62b:0b}} A=   2  |  3  |  5    (int|string|real)
        and     $03               ;{{d62c:e603}} A=   2  |  3  |  1
        dec     a                 ;{{d62e:3d}} A=   1  |  2  |  0
        add     a,a               ;{{d62f:87}} A=   2  |  4  |  0
        add     a,real_array_linked_list_head and 255;{{d630:c6ed}} formula version
;OLDd630 c6ed      add     a,$ed            ;A= $ef  |$f1  |$ed  I.e add a,$aded and $ff
        ld      l,a               ;{{d632:6f}} L= $ef  |$f1  |$ed
        adc     a,real_array_linked_list_head >> 8;{{d633:cead}} formula version
;OLDd633 cead      adc     a,$ad            ;A= $19c |$19e |$19a (i.e. carry)  I.e. adc a,&aded shr 8
        sub     l                 ;{{d635:95}} A= $ad  |$ad  |$ad
        ld      h,a               ;{{d636:67}} HL=$adef|$adf1|$aded -> addresses in BASIC data area!
        ret                       ;{{d637:c9}} 

;;===================================
;;=defreal a to z
defreal_a_to_z:                   ;{{Addr=$d638 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$415a          ;{{d638:015a41}} 'A''Z' - letter range
        ld      e,$05             ;{{d63b:1e05}} REAL data type

;;=def letters BC to type E
;DEFs the type of a range of variables
;B=start of letter range ('A' to 'Z')
;C=end of letter range ('A' to 'Z')
;E=variable type (2,3,5)
def_letters_BC_to_type_E:         ;{{Addr=$d63d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{d63d:79}} 
        sub     b                 ;{{d63e:90}} calc number of items to set
        jr      c,raise_syntax_error_B;{{d63f:383d}}  (+$3d)
        push    hl                ;{{d641:e5}} 
        inc     a                 ;{{d642:3c}} 
        ld      hl,table_of_DEFINT_ - 'A';{{d643:21b2ad}} Relative to start of DEFxxxx table
        ld      b,$00             ;{{d646:0600}} 
        add     hl,bc             ;{{d648:09}} HL=last item in range

_def_letters_bc_to_type_e_8:      ;{{Addr=$d649 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),e            ;{{d649:73}} 
        dec     hl                ;{{d64a:2b}} 
        dec     a                 ;{{d64b:3d}} 
        jr      nz,_def_letters_bc_to_type_e_8;{{d64c:20fb}}  (-$05) Loop

        pop     hl                ;{{d64e:e1}} 
        ret                       ;{{d64f:c9}} 


;;======================================================
;; command DEFSTR

command_DEFSTR:                   ;{{Addr=$d650 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$03             ;{{d650:1e03}} String type
        jr      do_DEFtype        ;{{d652:1806}}  (+$06)

;;=============================================================================
;; command DEFINT

command_DEFINT:                   ;{{Addr=$d654 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$02             ;{{d654:1e02}} Int type
        jr      do_DEFtype        ;{{d656:1802}}  (+$02)

;;=============================================================================
;; command DEFREAL
command_DEFREAL:                  ;{{Addr=$d658 Code Calls/jump count: 0 Data use count: 1}}
        ld      e,$05             ;{{d658:1e05}} Real type

;;-----------------------------------------------------------------------------
;;=do DEFtype
do_DEFtype:                       ;{{Addr=$d65a Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{d65a:7e}} 
        call    test_if_letter    ;{{d65b:cd92ff}}  is a alphabetical letter?
        jr      nc,raise_syntax_error_B;{{d65e:301e}}  (+$1e)
        ld      c,a               ;{{d660:4f}} 
        ld      b,a               ;{{d661:47}} 
        call    get_next_token_skipping_space;{{d662:cd2cde}}  get next token skipping space
        cp      $2d               ;{{d665:fe2d}}  '-' - range of values
        jr      nz,_do_deftype_13 ;{{d667:200c}}  (+$0c)
        call    get_next_token_skipping_space;{{d669:cd2cde}}  get next token skipping space
        call    test_if_letter    ;{{d66c:cd92ff}}  is a alphabetical letter?
        jr      nc,raise_syntax_error_B;{{d66f:300d}}  (+$0d)
        ld      c,a               ;{{d671:4f}} 
        call    get_next_token_skipping_space;{{d672:cd2cde}}  get next token skipping space

_do_deftype_13:                   ;{{Addr=$d675 Code Calls/jump count: 1 Data use count: 0}}
        call    def_letters_BC_to_type_E;{{d675:cd3dd6}} 
        call    next_token_if_prev_is_comma;{{d678:cd41de}} 
        jr      c,do_DEFtype      ;{{d67b:38dd}}  (-$23) comma = more items in list
        ret                       ;{{d67d:c9}} 

;;=raise Syntax Error
raise_syntax_error_B:             ;{{Addr=$d67e Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Syntax_Error;{{d67e:c349cb}}  Error: Syntax Error

;;=raise Subscript out of range
raise_Subscript_out_of_range:     ;{{Addr=$d681 Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d681:cd45cb}} 
        defb $09                  ;Inline error code: Subscript out of range

;;=raise Array already dimensioned
raise_Array_already_dimensioned:  ;{{Addr=$d685 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d685:cd45cb}} 
        defb $0a                  ;Inline error code: Array already dimensioned

;;========================================================================
;; BAR command or implicit LET
BAR_command_or_implicit_LET:      ;{{Addr=$d689 Code Calls/jump count: 1 Data use count: 0}}
        cp      $f8               ;{{d689:fef8}}  '|'
        jp      z,BAR_command     ;{{d68b:ca45f2}} 

;;========================================================================
;; command LET

command_LET:                      ;{{Addr=$d68e Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_or_create_a_var;{{d68e:cdbfd6}} Find (or alloc) the variables
        push    de                ;{{d691:d5}} Preserve address(?)
        call    next_token_if_equals_sign;{{d692:cd21de}} Test for '=' sign
        call    eval_expression   ;{{d695:cd62cf}} Evaluate the new value
        ld      a,b               ;{{d698:78}} 
        ex      (sp),hl           ;{{d699:e3}} Retrieve the address
        call    copy_accumulator_to_atHL_as_type_B;{{d69a:cd9fd6}} Store the new value (also stores a string if appropriate)
        pop     hl                ;{{d69d:e1}} Retrieve code pointer
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
        jp      nz,copy_numeric_accumulator_to_atHL;{{d6ab:c283ff}} It's a number
        push    hl                ;{{d6ae:e5}} Otherwise it's a string
        call    _copy_accumulator_to_strings_area_4;{{d6af:cd94fb}} Store string to strings area
        pop     de                ;{{d6b2:d1}} 
        jp      copy_value_atHL_to_atDE_accumulator_type;{{d6b3:c387ff}} 

;;========================================================================
;; command DIM

command_DIM:                      ;{{Addr=$d6b6 Code Calls/jump count: 1 Data use count: 1}}
        call    do_DIM_item       ;{{d6b6:cde0d7}} 
        call    next_token_if_prev_is_comma;{{d6b9:cd41de}} 
        jr      c,command_DIM     ;{{d6bc:38f8}}  (-$08) Comma = more items in list
        ret                       ;{{d6be:c9}} 

;;===================================================
;The variable/array/deffn token is followed by a pointer into the variables/arrays/deffn area.
;At reset this value is cleared to zero. Here we read the value. If it's set then add it to the base address,
;if not the search the relevant linked list to: find it; store the found value (and possibly clarify the variables type);
;(depeding on the routine) allocate space if the item isn't already created.


;;=parse and find or create a var
;Returns DE = address of variables value
parse_and_find_or_create_a_var:   ;{{Addr=$d6bf Code Calls/jump count: 7 Data use count: 0}}
        call    parse_var_type_and_name;{{d6bf:cd31d9}} 
        call    convert_var_or_array_offset_into_address;{{d6c2:cd06d8}} 
        jr      c,get_accum_data_type_in_A_B_and_C;{{d6c5:3842}}  (+$42) variable offset set -> return
        jr      find_var_and_alloc_if_not_found;{{d6c7:1828}}  (+$28) variable offset not set -> find (and maybe alloc)

;;=parse and find var
parse_and_find_var:               ;{{Addr=$d6c9 Code Calls/jump count: 2 Data use count: 0}}
        call    parse_var_type_and_name;{{d6c9:cd31d9}} 
        call    convert_var_or_array_offset_into_address;{{d6cc:cd06d8}} 
        jr      c,get_accum_data_type_in_A_B_and_C;{{d6cf:3838}}  (+$38) variable offset set -> return
        push    hl                ;{{d6d1:e5}} 
        ld      a,c               ;{{d6d2:79}} 
        call    get_VarFN_area_and_list_head_ptr;{{d6d3:cd19d6}} search list of vars (list depends on type)
        call    find_var_in_FN_or_var_linked_lists;{{d6d6:cd17d7}} 
        jr      pop_hl_and_get_accum_data_type_in_A_B_and_C_;{{d6d9:182d}}  (+$2d) return

;;=parse and find or create an FN
parse_and_find_or_create_an_FN:   ;{{Addr=$d6db Code Calls/jump count: 2 Data use count: 0}}
        call    parse_var_type_and_name;{{d6db:cd31d9}} 
        jr      c,add_offset_to_addr_in_var_FN_area;{{d6de:3821}}  (+$21) variable offset set -> add offset and return
        push    hl                ;{{d6e0:e5}} 
        call    get_VarFN_area_and_FN_list_head_ptr;{{d6e1:cd17d6}} search list of DEF FNs
        call    _prob_find_item_in_linked_list_2;{{d6e4:cd32d7}} 
        call    nc,prob_alloc_space_for_a_DEF_FN;{{d6e7:d46fd7}} not found - alloc
        jr      pop_hl_and_get_accum_data_type_in_A_B_and_C_;{{d6ea:181c}}  (+$1c)

;;=parse and find or alloc FOR var
parse_and_find_or_alloc_FOR_var:  ;{{Addr=$d6ec Code Calls/jump count: 1 Data use count: 0}}
        call    parse_var_type_and_name;{{d6ec:cd31d9}} 
        jr      c,add_offset_to_addr_in_var_FN_area;{{d6ef:3810}}  (+$10) variable offset set -> return

;;=find var and alloc if not found
find_var_and_alloc_if_not_found:  ;{{Addr=$d6f1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d6f1:e5}} 
        ld      a,c               ;{{d6f2:79}} 
        call    get_VarFN_area_and_list_head_ptr;{{d6f3:cd19d6}} search list of variables (list depends on type)
        call    find_var_in_FN_or_var_linked_lists;{{d6f6:cd17d7}} 
        ld      a,(accumulator_data_type);{{d6f9:3a9fb0}} 
        call    nc,prob_alloc_space_for_new_var;{{d6fc:d47bd7}} not found - alloc
        jr      pop_hl_and_get_accum_data_type_in_A_B_and_C_;{{d6ff:1807}}  (+$07)

;;=add offset to addr in var FN area
add_offset_to_addr_in_var_FN_area:;{{Addr=$d701 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d701:e5}} 
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{d702:2a68ae}} 
        dec     hl                ;{{d705:2b}} 
        add     hl,de             ;{{d706:19}} 
        ex      de,hl             ;{{d707:eb}} 

;;=pop hl and get accum data type in A B and C 
pop_hl_and_get_accum_data_type_in_A_B_and_C_:;{{Addr=$d708 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{d708:e1}} 

;;=get accum data type in A B and C
get_accum_data_type_in_A_B_and_C: ;{{Addr=$d709 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(accumulator_data_type);{{d709:3a9fb0}} 
        ld      b,a               ;{{d70c:47}} 
        ld      c,a               ;{{d70d:4f}} 
        ret                       ;{{d70e:c9}} 

;;============================
;;prob just skip over variable
prob_just_skip_over_variable:     ;{{Addr=$d70f Code Calls/jump count: 1 Data use count: 0}}
        call    parse_var_type_and_name;{{d70f:cd31d9}} 
        call    skip_over_batched_braces;{{d712:cd7ae9}} 
        jr      get_accum_data_type_in_A_B_and_C;{{d715:18f2}}  (-$0e)

;;==================================
;;=find var in FN or var linked lists
;Appears to check multiple lists? Maybe depends on variable type
find_var_in_FN_or_var_linked_lists:;{{Addr=$d717 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{d717:d5}} 
        push    hl                ;{{d718:e5}} 
        ld      hl,(FN_param_end) ;{{d719:2a12ae}} Are we in an FN?
        ld      a,h               ;{{d71c:7c}} 
        or      l                 ;{{d71d:b5}} 
        jr      z,prob_find_item_in_linked_list;{{d71e:2810}}  (+$10) Nope - just check regular variables
        inc     hl                ;{{d720:23}} otherwise check variable linked list for the FN...
        inc     hl                ;{{d721:23}} 
        push    bc                ;{{d722:c5}} 
        ld      bc,$0000          ;{{d723:010000}} which uses an absolute address (well, an offset from zero) ##LIT##
        call    find_named_item_in_linked_list;{{d726:cd40d7}} 
        pop     bc                ;{{d729:c1}} and then check the regular variable linked list
        jr      nc,prob_find_item_in_linked_list;{{d72a:3004}}  (+$04)
        pop     af                ;{{d72c:f1}} 
        pop     af                ;{{d72d:f1}} 
        scf                       ;{{d72e:37}} 
        ret                       ;{{d72f:c9}} 

;;=prob find item in linked list
;finds an item within a single list
prob_find_item_in_linked_list:    ;{{Addr=$d730 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{d730:e1}} 
        pop     de                ;{{d731:d1}} 

_prob_find_item_in_linked_list_2: ;{{Addr=$d732 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{d732:d5}} this entry point searches DEF FNs list
        push    hl                ;{{d733:e5}} 
        call    find_named_item_in_linked_list;{{d734:cd40d7}} 
        pop     hl                ;{{d737:e1}} 
        jr      c,_prob_find_item_in_linked_list_9;{{d738:3802}}  (+$02)
        pop     de                ;{{d73a:d1}} 
        ret                       ;{{d73b:c9}} 

_prob_find_item_in_linked_list_9: ;{{Addr=$d73c Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d73c:e1}} 
        jp      prob_store_offset_into_code;{{d73d:c39ed7}} 

;;==================================
;;find named item in linked list
;BC=start of linked list
;HL=ptr to offset into list - item is at BC + (HL)
;($AE0E) addr of ASCIIZ name to compare to
;Type must match that of the accumulator
;EXIT: Carry set if item found
;(If found):
;HL = address of start of item
;DE = address of items data area (address after type specifier)

;Table format:
;Word: Offset (from BC) of next item in table (or zero if end of list)
;ASCIIZ string: item name
;Byte: Item type (2/3/5)
;Data area

find_named_item_in_linked_list:   ;{{Addr=$d740 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,(hl)            ;{{d740:7e}} 
        inc     hl                ;{{d741:23}} 
        ld      h,(hl)            ;{{d742:66}} 
        ld      l,a               ;{{d743:6f}} 
        or      h                 ;{{d744:b4}} 
        ret     z                 ;{{d745:c8}} Offset? is zero - end of list (or empty list)  

        add     hl,bc             ;{{d746:09}} Add offset to start of table
        push    hl                ;{{d747:e5}} 
        inc     hl                ;{{d748:23}} Step over (pointer) to string (var name)
        inc     hl                ;{{d749:23}} Ptr = offset of next item?
        ld      de,(poss_cached_addrvariable_name_address_o);{{d74a:ed5b0eae}} Address of another string

_find_named_item_in_linked_list_11:;{{Addr=$d74e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{d74e:1a}} Compare ASCII7 string at HL to that at DE
        cp      (hl)              ;{{d74f:be}} 
        jr      nz,_find_named_item_in_linked_list_23;{{d750:200d}}  (+$0d) Char doesn't match - fail
        inc     hl                ;{{d752:23}} Next char
        inc     de                ;{{d753:13}} 
        rla                       ;{{d754:17}} Is bit 7 set?
        jr      nc,_find_named_item_in_linked_list_11;{{d755:30f7}}  (-$09) Loop for next char if not

        ld      a,(accumulator_data_type);{{d757:3a9fb0}} Does the type also match?
        dec     a                 ;{{d75a:3d}} 
        xor     (hl)              ;{{d75b:ae}} 
        and     $07               ;{{d75c:e607}} 
        ex      de,hl             ;{{d75e:eb}} 
_find_named_item_in_linked_list_23:;{{Addr=$d75f Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d75f:e1}} Retrieve start address of item = ptr to next item
        jr      nz,find_named_item_in_linked_list;{{d760:20de}}  (-$22) Not a match, loop. 
        inc     de                ;{{d762:13}} DE = ptr to the items data
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

;;=prob alloc space for a DEF FN
prob_alloc_space_for_a_DEF_FN:    ;{{Addr=$d76f Code Calls/jump count: 1 Data use count: 0}}
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
        call    count_length_of_cached_string;{{d77f:cda8d7}} 
        push    af                ;{{d782:f5}} 
        ld      hl,(address_of_start_of_Arrays_area_);{{d783:2a6aae}} 
        ex      de,hl             ;{{d786:eb}} 
        call    unknown_alloc_and_move_memory_up;{{d787:cdb8f6}} 
        call    prob_grow_variables_space_ptrs_by_BC;{{d78a:cd1af6}} 
        pop     af                ;{{d78d:f1}} 
        call    copy_cached_string_and_store_data_type;{{d78e:cdb8d7}} 
        pop     bc                ;{{d791:c1}} 

        xor     a                 ;{{d792:af}} Zero B bytes
_prob_alloc_space_for_new_var_14: ;{{Addr=$d793 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d793:2b}} 
        ld      (hl),a            ;{{d794:77}} 
        djnz    _prob_alloc_space_for_new_var_14;{{d795:10fc}}  (-$04)

        pop     bc                ;{{d797:c1}} 
        ex      (sp),hl           ;{{d798:e3}} 
        call    poss_update_list_headers;{{d799:cdd0d7}} 
        pop     de                ;{{d79c:d1}} 
        pop     hl                ;{{d79d:e1}} 

;;=prob store offset into code
;stores the newly found/created variable/fn/array offset into the code where it is referenced
prob_store_offset_into_code:      ;{{Addr=$d79e Code Calls/jump count: 3 Data use count: 0}}
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

;;=count length of cached string
count_length_of_cached_string:    ;{{Addr=$d7a8 Code Calls/jump count: 2 Data use count: 0}}
        add     a,$03             ;{{d7a8:c603}} 
        ld      c,a               ;{{d7aa:4f}} 
        ld      hl,(poss_cached_addrvariable_name_address_o);{{d7ab:2a0eae}} Address of cached string
        xor     a                 ;{{d7ae:af}} Count length of string
        ld      b,a               ;{{d7af:47}} 
_count_length_of_cached_string_5: ;{{Addr=$d7b0 Code Calls/jump count: 1 Data use count: 0}}
        inc     bc                ;{{d7b0:03}} 
        inc     a                 ;{{d7b1:3c}} 
        bit     7,(hl)            ;{{d7b2:cb7e}} 
        inc     hl                ;{{d7b4:23}} 
        jr      z,_count_length_of_cached_string_5;{{d7b5:28f9}}  (-$07)
        ret                       ;{{d7b7:c9}} 

;;=copy cached string and store data type
copy_cached_string_and_store_data_type:;{{Addr=$d7b8 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,d               ;{{d7b8:62}} 
        ld      l,e               ;{{d7b9:6b}} 
        add     hl,bc             ;{{d7ba:09}} 
        push    hl                ;{{d7bb:e5}} 
        push    de                ;{{d7bc:d5}} 
        inc     de                ;{{d7bd:13}} 
        inc     de                ;{{d7be:13}} 
        ld      hl,(poss_cached_addrvariable_name_address_o);{{d7bf:2a0eae}} 
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

;;=poss update list headers
poss_update_list_headers:         ;{{Addr=$d7d0 Code Calls/jump count: 4 Data use count: 0}}
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
        call    parse_var_type_and_name;{{d7e0:cd31d9}} skip over the array name...
        ld      a,(hl)            ;{{d7e3:7e}} ...and we should have an open brace (either type)
        cp      $28               ;{{d7e4:fe28}} '('
        jr      z,_do_dim_item_6  ;{{d7e6:2805}}  (+$05)
        xor     $5b               ;{{d7e8:ee5b}} '['
        jp      nz,Error_Syntax_Error;{{d7ea:c249cb}}  Error: Syntax Error

_do_dim_item_6:                   ;{{Addr=$d7ed Code Calls/jump count: 1 Data use count: 0}}
        call    read_array_dimensions;{{d7ed:cd83d8}} 
        push    hl                ;{{d7f0:e5}} 
        push    bc                ;{{d7f1:c5}} 
        ld      a,(accumulator_data_type);{{d7f2:3a9fb0}} 
        call    get_array_area_and_array_list_head_ptr_for_type;{{d7f5:cd27d6}} Is the array already dimmed? Go look for it
        call    find_named_item_in_linked_list;{{d7f8:cd40d7}} 
        jp      c,raise_Array_already_dimensioned;{{d7fb:da85d6}} if so, error

        pop     bc                ;{{d7fe:c1}} 
        ld      a,$ff             ;{{d7ff:3eff}} 
        call    create_and_alloc_space_for_array;{{d801:cdb3d8}} and create it
        pop     hl                ;{{d804:e1}} 
        ret                       ;{{d805:c9}} 

;;=convert var or array offset into address
;allocates space for array if needed
;Entry: DE=offset into variables or arrays tables, unless:
;Carry set if the address has stored in the code, and DE = offset of element
;Exit: DE=absolute address of var/FN/array element data
convert_var_or_array_offset_into_address:;{{Addr=$d806 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{d806:f5}} 
        ld      a,(hl)            ;{{d807:7e}} token after variable name/type
        cp      $28               ;{{d808:fe28}} '('
        jr      z,get_array_element_address;{{d80a:2810}}  (+$10)
        xor     $5b               ;{{d80c:ee5b}} '['
        jr      z,get_array_element_address;{{d80e:280c}}  (+$0c)
        pop     af                ;{{d810:f1}} 
        ret     nc                ;{{d811:d0}} 

        push    hl                ;{{d812:e5}} variable of FN
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{d813:2a68ae}} 
        dec     hl                ;{{d816:2b}} 
        add     hl,de             ;{{d817:19}} 
        ex      de,hl             ;{{d818:eb}} 
        pop     hl                ;{{d819:e1}} 
        scf                       ;{{d81a:37}} 
        ret                       ;{{d81b:c9}} 

;;=get array element address
;allocates space for array if needed
get_array_element_address:        ;{{Addr=$d81c Code Calls/jump count: 2 Data use count: 0}}
        call    read_array_dimensions;{{d81c:cd83d8}} push array dimensions onto execution stack;count in B
        pop     af                ;{{d81f:f1}} 
        push    hl                ;{{d820:e5}} 
        jr      nc,_get_array_element_address_8;{{d821:3007}}  (+$07) 
        ld      hl,(address_of_start_of_Arrays_area_);{{d823:2a6aae}} address stored in code (which means it's a constant value??)
        dec     hl                ;{{d826:2b}} 
        add     hl,de             ;{{d827:19}} get absolute address
        jr      _get_array_element_address_20;{{d828:1815}}  (+$15)

_get_array_element_address_8:     ;{{Addr=$d82a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{d82a:c5}} 
        push    de                ;{{d82b:d5}} 
        ld      a,(accumulator_data_type);{{d82c:3a9fb0}} 
        call    get_array_area_and_array_list_head_ptr_for_type;{{d82f:cd27d6}} try and find the array
        call    find_named_item_in_linked_list;{{d832:cd40d7}} 
        jr      nc,_get_array_element_address_24;{{d835:300f}}  (+$0f) not found - create it
        inc     de                ;{{d837:13}} 
        inc     de                ;{{d838:13}} 
        pop     hl                ;{{d839:e1}} 
        call    prob_store_offset_into_code;{{d83a:cd9ed7}} 
        pop     bc                ;{{d83d:c1}} 
        ex      de,hl             ;{{d83e:eb}} 
_get_array_element_address_20:    ;{{Addr=$d83f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{d83f:78}} number of dimensions
        sub     (hl)              ;{{d840:96}} compare with stored value
        jp      nz,raise_Subscript_out_of_range;{{d841:c281d6}} 
        jr      _get_array_element_address_30;{{d844:180a}}  (+$0a)

_get_array_element_address_24:    ;{{Addr=$d846 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d846:e1}} create array
        pop     bc                ;{{d847:c1}} 
        xor     a                 ;{{d848:af}} 
        call    create_and_alloc_space_for_array;{{d849:cdb3d8}} 
        call    prob_store_offset_into_code;{{d84c:cd9ed7}} 
        ex      de,hl             ;{{d84f:eb}} 

_get_array_element_address_30:    ;{{Addr=$d850 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0000          ;{{d850:110000}} we now have the address of the array ##LIT##
        ld      b,(hl)            ;{{d853:46}} get number of dimensions

        inc     hl                ;{{d854:23}} point to size of first dimension
_get_array_element_address_33:    ;{{Addr=$d855 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d855:e5}} read size of dimension
        push    de                ;{{d856:d5}} 
        ld      e,(hl)            ;{{d857:5e}} 
        inc     hl                ;{{d858:23}} 
        ld      d,(hl)            ;{{d859:56}} 
        call    pop_word_off_execution_stack;{{d85a:cd27d9}} pop index into dimension
        call    compare_HL_DE     ;{{d85d:cdd8ff}}  HL=DE? validate
        jp      nc,raise_Subscript_out_of_range;{{d860:d281d6}} index * size of dimension?
        ex      (sp),hl           ;{{d863:e3}} 
        call    do_16x16_multiply_with_overflow;{{d864:cd72dd}} 
        pop     de                ;{{d867:d1}} 
        add     hl,de             ;{{d868:19}} add to offset -> new offset
        ex      de,hl             ;{{d869:eb}} 
        pop     hl                ;{{d86a:e1}} 
        inc     hl                ;{{d86b:23}} 
        inc     hl                ;{{d86c:23}} 
        djnz    _get_array_element_address_33;{{d86d:10e6}}  (-$1a) loop for more dimensions

        ex      de,hl             ;{{d86f:eb}} 
        ld      b,h               ;{{d870:44}} Multiply index by element size
        ld      c,l               ;{{d871:4d}} 
        ld      a,(accumulator_data_type);{{d872:3a9fb0}} 
        sub     $03               ;{{d875:d603}} 
        jr      c,_get_array_element_address_59;{{d877:3804}}  (+$04)
        add     hl,hl             ;{{d879:29}} 
        jr      z,_get_array_element_address_59;{{d87a:2801}}  (+$01)
        add     hl,hl             ;{{d87c:29}} 
_get_array_element_address_59:    ;{{Addr=$d87d Code Calls/jump count: 2 Data use count: 0}}
        add     hl,bc             ;{{d87d:09}} 
        add     hl,de             ;{{d87e:19}} 
        ex      de,hl             ;{{d87f:eb}} 
        pop     hl                ;{{d880:e1}} 
        scf                       ;{{d881:37}} 
        ret                       ;{{d882:c9}} 

;;=read array dimensions
;reads array dimensions and pushes them onto the execution stack
;B returns the number of dimensions
read_array_dimensions:            ;{{Addr=$d883 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{d883:d5}} 
        call    get_next_token_skipping_space;{{d884:cd2cde}}  get next token skipping space
        ld      a,(accumulator_data_type);{{d887:3a9fb0}} 

        push    af                ;{{d88a:f5}} 
        ld      b,$00             ;{{d88b:0600}} B=number of dimensions
_read_array_dimensions_5:         ;{{Addr=$d88d Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expr_as_positive_int_or_error;{{d88d:cdcece}} Read value
        push    hl                ;{{d890:e5}} 
        ld      a,$02             ;{{d891:3e02}} push value onto the execution stack
        call    possibly_alloc_A_bytes_on_execution_stack;{{d893:cd72f6}} 
        ld      (hl),e            ;{{d896:73}} 
        inc     hl                ;{{d897:23}} 
        ld      (hl),d            ;{{d898:72}} 
        pop     hl                ;{{d899:e1}} 

        inc     b                 ;{{d89a:04}} inc dimension counter
        call    next_token_if_prev_is_comma;{{d89b:cd41de}} any more?
        jr      c,_read_array_dimensions_5;{{d89e:38ed}}  (-$13) if so, loop
        ld      a,(hl)            ;{{d8a0:7e}} finish list with brackets of either type
        cp      $29               ;{{d8a1:fe29}} ')'
        jr      z,_read_array_dimensions_21;{{d8a3:2805}}  (+$05)
        cp      $5d               ;{{d8a5:fe5d}} ']'
        jp      nz,Error_Syntax_Error;{{d8a7:c249cb}}  otherwise, Error: Syntax Error

_read_array_dimensions_21:        ;{{Addr=$d8aa Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{d8aa:cd2cde}}  get next token skipping space
        pop     af                ;{{d8ad:f1}} 
        ld      (accumulator_data_type),a;{{d8ae:329fb0}} 
        pop     de                ;{{d8b1:d1}} 
        ret                       ;{{d8b2:c9}} 

;;=create and alloc space for array
;B=number of dimensions
;Sizes of each dimension are pushed on the execution stack
create_and_alloc_space_for_array: ;{{Addr=$d8b3 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d8b3:e5}} 
        ld      (RAM_ae0d),a      ;{{d8b4:320dae}} 
        push    bc                ;{{d8b7:c5}} 
        ld      a,b               ;{{d8b8:78}} 
        add     a,a               ;{{d8b9:87}} 
        add     a,$03             ;{{d8ba:c603}} 
        call    count_length_of_cached_string;{{d8bc:cda8d7}} 
        push    af                ;{{d8bf:f5}} 
        ld      hl,(address_of_start_of_free_space_);{{d8c0:2a6cae}} 
        ex      de,hl             ;{{d8c3:eb}} 
        call    unknown_alloc_and_move_memory_up;{{d8c4:cdb8f6}} Move data up out of the way
        pop     af                ;{{d8c7:f1}} 
        call    copy_cached_string_and_store_data_type;{{d8c8:cdb8d7}} Copy/store array name and type
        ld      h,b               ;{{d8cb:60}} 
        ld      l,c               ;{{d8cc:69}} 
        pop     bc                ;{{d8cd:c1}} 
        push    de                ;{{d8ce:d5}} 
        inc     hl                ;{{d8cf:23}} 
        inc     hl                ;{{d8d0:23}} 
        ld      a,(accumulator_data_type);{{d8d1:3a9fb0}} 
        ld      e,a               ;{{d8d4:5f}} 
        ld      d,$00             ;{{d8d5:1600}} 

        ld      (hl),b            ;{{d8d7:70}} number of dimensions (and loop counter)
        push    hl                ;{{d8d8:e5}} 
        inc     hl                ;{{d8d9:23}} 

_create_and_alloc_space_for_array_25:;{{Addr=$d8da Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{d8da:d5}} Loop for each dimension
        ld      a,(RAM_ae0d)      ;{{d8db:3a0dae}} 
        or      a                 ;{{d8de:b7}} 
        ld      de,$000a          ;{{d8df:110a00}} 
        ex      de,hl             ;{{d8e2:eb}} 
        call    nz,pop_word_off_execution_stack;{{d8e3:c427d9}} pop size of this dimension
        ex      de,hl             ;{{d8e6:eb}} 
        inc     de                ;{{d8e7:13}} 
        ld      (hl),e            ;{{d8e8:73}} store dimension size
        inc     hl                ;{{d8e9:23}} 
        ld      (hl),d            ;{{d8ea:72}} 
        inc     hl                ;{{d8eb:23}} 
        ex      (sp),hl           ;{{d8ec:e3}} 
        call    do_16x16_multiply_with_overflow;{{d8ed:cd72dd}} size of this dimension?
        jp      c,raise_Subscript_out_of_range;{{d8f0:da81d6}} 

        ex      de,hl             ;{{d8f3:eb}} 
        pop     hl                ;{{d8f4:e1}} 
        djnz    _create_and_alloc_space_for_array_25;{{d8f5:10e3}}  (-$1d) loop for more dimensions

        ld      b,d               ;{{d8f7:42}} Restore the following memory
        ld      c,e               ;{{d8f8:4b}} 
        ld      d,h               ;{{d8f9:54}} 
        ld      e,l               ;{{d8fa:5d}} 
        call    _unknown_alloc_and_move_memory_up_1;{{d8fb:cdbbf6}} 
        ld      (address_of_start_of_free_space_),hl;{{d8fe:226cae}} 

        push    bc                ;{{d901:c5}} Clear BC bytes of memory - cleanup? zero allocated space?
_create_and_alloc_space_for_array_50:;{{Addr=$d902 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d902:2b}} 
        ld      (hl),$00          ;{{d903:3600}} 
        dec     bc                ;{{d905:0b}} 
        ld      a,b               ;{{d906:78}} 
        or      c                 ;{{d907:b1}} 
        jr      nz,_create_and_alloc_space_for_array_50;{{d908:20f8}}  (-$08)

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
        ld      (hl),e            ;{{d915:73}} store pointer to next item in list?
        inc     hl                ;{{d916:23}} 
        ld      (hl),d            ;{{d917:72}} 
        inc     hl                ;{{d918:23}} 
        ex      (sp),hl           ;{{d919:e3}} 
        ex      de,hl             ;{{d91a:eb}} 

        ld      a,(accumulator_data_type);{{d91b:3a9fb0}} 
        call    get_array_area_and_array_list_head_ptr_for_type;{{d91e:cd27d6}} 
        call    poss_update_list_headers;{{d921:cdd0d7}} and update list header?
        pop     de                ;{{d924:d1}} 
        pop     hl                ;{{d925:e1}} 
        ret                       ;{{d926:c9}} 

;;=pop word off execution stack
pop_word_off_execution_stack:     ;{{Addr=$d927 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$02             ;{{d927:3e02}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d929:cd62f6}} 
        ld      a,(hl)            ;{{d92c:7e}} 
        inc     hl                ;{{d92d:23}} 
        ld      h,(hl)            ;{{d92e:66}} 
        ld      l,a               ;{{d92f:6f}} 
        ret                       ;{{d930:c9}} 

;;=================================
;;parse var type and name
;if the offset is set within the variables token data, returns it in DE and skips over the name,
;otherwise copies the variables name onto the execution stack and sets (&ae0e) to point to the first char,
;and returns the first letter in uppercase in C
;Carry set if we're returning the offset.
;Entry: HL=pointer to variable definition, token data
;Exit:DE=value (offset)
;C=first letter of name converted to upper case
;Carry set if offset found
parse_var_type_and_name:          ;{{Addr=$d931 Code Calls/jump count: 7 Data use count: 0}}
        call    set_accum_type_from_variable_type_atHL;{{d931:cdafd9}} Set accumulator to match variable token type
        inc     hl                ;{{d934:23}} 
        ld      e,(hl)            ;{{d935:5e}} read var offset into DE
        inc     hl                ;{{d936:23}} 
        ld      d,(hl)            ;{{d937:56}} 
        ld      a,d               ;{{d938:7a}} 
        or      e                 ;{{d939:b3}} 
        jr      z,copy_var_name_onto_exec_stack;{{d93a:280a}}  (+$0a) if offset is zero we need to find offset

_parse_var_type_and_name_8:       ;{{Addr=$d93c Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{d93c:23}} skip over var name (ends with bit 7 set)
        ld      a,(hl)            ;{{d93d:7e}} 
        rla                       ;{{d93e:17}} 
        jr      nc,_parse_var_type_and_name_8;{{d93f:30fb}}  (-$05)

        call    get_next_token_skipping_space;{{d941:cd2cde}}  get next token skipping space
        scf                       ;{{d944:37}} 
        ret                       ;{{d945:c9}} 

;;=copy var name onto exec stack
;;Parse variable name onto execution stack, set (AE0E) as a poiner to it
;Exit: C=first letter of name converted to uppercase
copy_var_name_onto_exec_stack:    ;{{Addr=$d946 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{d946:2b}} 
        dec     hl                ;{{d947:2b}} HL now ponts to variable type token
        ex      de,hl             ;{{d948:eb}} 
        pop     bc                ;{{d949:c1}} 
        ld      hl,(poss_cached_addrvariable_name_address_o);{{d94a:2a0eae}} Old top of execution stack?
        push    hl                ;{{d94d:e5}} 
        ld      hl,_copy_var_name_onto_exec_stack_15;{{d94e:215ed9}} ##LABEL##
        push    hl                ;{{d951:e5}} !!!Push code address onto stack - not sure where this comes out!!!
        push    bc                ;{{d952:c5}} 
        ex      de,hl             ;{{d953:eb}} 
        push    hl                ;{{d954:e5}} 
        call    copy_var_name_onto_execution_stack;{{d955:cd6cd9}} 
        ld      (poss_cached_addrvariable_name_address_o),de;{{d958:ed530eae}} 
        pop     de                ;{{d95c:d1}} 
        ret                       ;{{d95d:c9}} 

_copy_var_name_onto_exec_stack_15:;{{Addr=$d95e Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d95e:e5}} 
        ld      hl,(poss_cached_addrvariable_name_address_o);{{d95f:2a0eae}} 
        call    set_execution_stack_next_free_ptr;{{d962:cd6ef6}} 
        pop     hl                ;{{d965:e1}} 
        ex      (sp),hl           ;{{d966:e3}} 
        ld      (poss_cached_addrvariable_name_address_o),hl;{{d967:220eae}} 
        pop     hl                ;{{d96a:e1}} 
        ret                       ;{{d96b:c9}} 

;;=======================================
;;=copy var name onto execution stack
;Entry: DE=address of a variable type token
;Exit: C=first letter of name converted to uppercase
copy_var_name_onto_execution_stack:;{{Addr=$d96c Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{d96c:e5}} 
        ld      a,(hl)            ;{{d96d:7e}} Get var type
        inc     hl                ;{{d96e:23}} 
        inc     hl                ;{{d96f:23}} 
        inc     hl                ;{{d970:23}} HL=pointer to var name
        ld      c,(hl)            ;{{d971:4e}} First char of name
        res     5,c               ;{{d972:cba9}} To upper case
        ex      (sp),hl           ;{{d974:e3}} 
        cp      $0b               ;{{d975:fe0b}} 
        jr      c,do_the_name_copying;{{d977:3817}}  (+$17) variable type is known

;establish the variables type ... and poke that into the variables token data
        ld      a,c               ;{{d979:79}} Get index into DEFtype table...
        and     $1f               ;{{d97a:e61f}} 
        add     a,$f2             ;{{d97c:c6f2}} ...which starts at ADF3
        ld      e,a               ;{{d97e:5f}} 
        adc     a,$ad             ;{{d97f:cead}} 
        sub     e                 ;{{d981:93}} 
        ld      d,a               ;{{d982:57}} 
        ld      a,(de)            ;{{d983:1a}} Type from DEFtype table
        ld      (accumulator_data_type),a;{{d984:329fb0}} 
        ld      (hl),$0d          ;{{d987:360d}} Set the vars type as real/unspecified
        cp      $05               ;{{d989:fe05}} Real?
        jr      z,do_the_name_copying;{{d98b:2803}}  (+$03)

        add     a,$09             ;{{d98d:c609}} Set the variables type (as no suffix defined)
        ld      (hl),a            ;{{d98f:77}} 

;;=do the name copying
do_the_name_copying:              ;{{Addr=$d990 Code Calls/jump count: 2 Data use count: 0}}
        pop     de                ;{{d990:d1}} 
        ld      a,$28             ;{{d991:3e28}} Max name length??
        call    possibly_alloc_A_bytes_on_execution_stack;{{d993:cd72f6}} 
        push    hl                ;{{d996:e5}} 
        ld      b,$29             ;{{d997:0629}} 

_do_the_name_copying_5:           ;{{Addr=$d999 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{d999:05}} 
        jp      z,Error_Syntax_Error;{{d99a:ca49cb}}  Error: Syntax Error (name too long)

        ld      a,(de)            ;{{d99d:1a}} Copy char
        inc     de                ;{{d99e:13}} 
        and     $df               ;{{d99f:e6df}} Convert to upper case
        ld      (hl),a            ;{{d9a1:77}} 
        inc     hl                ;{{d9a2:23}} 
        rla                       ;{{d9a3:17}} Bit 7 set? (Last char)
        jr      nc,_do_the_name_copying_5;{{d9a4:30f3}}  (-$0d) Loop for next char

        call    set_execution_stack_next_free_ptr;{{d9a6:cd6ef6}} Push onto execution stack
        ex      de,hl             ;{{d9a9:eb}} 
        dec     hl                ;{{d9aa:2b}} 
        pop     de                ;{{d9ab:d1}} 
        jp      get_next_token_skipping_space;{{d9ac:c32cde}}  get next token skipping space

;;==============================================
;;=set accum type from variable type atHL
;variable data type tokens = 2/3/4 if have suffix, $b/$c/$d if no suffix
set_accum_type_from_variable_type_atHL:;{{Addr=$d9af Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{d9af:7e}} 
        cp      $0b               ;{{d9b0:fe0b}} No suffix
        jr      c,_set_accum_type_from_variable_type_athl_4;{{d9b2:3802}}  (+$02)
        add     a,$f7             ;{{d9b4:c6f7}} Subtract 9
_set_accum_type_from_variable_type_athl_4:;{{Addr=$d9b6 Code Calls/jump count: 1 Data use count: 0}}
        cp      $04               ;{{d9b6:fe04}} REAL type token
        jr      z,set_accum_type_as_REAL;{{d9b8:2809}}  (+$09)
        jr      nc,raise_syntax_error_C;{{d9ba:3004}}  (+$04)
        cp      $02               ;{{d9bc:fe02}} INT type token
        jr      nc,set_accumulator_type;{{d9be:3005}}  (+$05)

;;=raise Syntax Error
raise_syntax_error_C:             ;{{Addr=$d9c0 Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Syntax_Error;{{d9c0:c349cb}}  Error: Syntax Error

;;=set accum type as REAL
set_accum_type_as_REAL:           ;{{Addr=$d9c3 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$05             ;{{d9c3:3e05}} 
;;=set accumulator type
set_accumulator_type:             ;{{Addr=$d9c5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator_data_type),a;{{d9c5:329fb0}} 
        ret                       ;{{d9c8:c9}} 

;;=========================================
;;=update array list heads
;iterate over all arrays and update the list heads (there's one for each data type 2,3,5)
;works by:
;reset heads to nil
;works from start to arrays area
;for each array, update list head for that type
;until end of arrays area
;so, each list head will now point to the last array for it's type
update_array_list_heads:          ;{{Addr=$d9c9 Code Calls/jump count: 1 Data use count: 0}}
        call    reset_array_linked_list_headers;{{d9c9:cd02d6}} 
        ld      hl,(address_of_start_of_free_space_);{{d9cc:2a6cae}} get bounds of arrays area
        ex      de,hl             ;{{d9cf:eb}} 
        ld      hl,(address_of_start_of_Arrays_area_);{{d9d0:2a6aae}} 
_update_array_list_heads_4:       ;{{Addr=$d9d3 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_DE     ;{{d9d3:cdd8ff}}  HL=DE?
        ret     z                 ;{{d9d6:c8}} end once we go beyond end of arrays area

        push    de                ;{{d9d7:d5}} DE = start of arrays area
        call    poss_step_over_string;{{d9d8:cd65d7}} skip over array name...
        ld      a,(hl)            ;{{d9db:7e}} ...to get to type
        inc     hl                ;{{d9dc:23}} 
        and     $07               ;{{d9dd:e607}} 
        inc     a                 ;{{d9df:3c}} 
        push    hl                ;{{d9e0:e5}} HL=start of current item
        call    get_array_area_and_array_list_head_ptr_for_type;{{d9e1:cd27d6}} get list head ptr for item type
        call    poss_update_list_headers;{{d9e4:cdd0d7}} update head ptr to current item
        pop     hl                ;{{d9e7:e1}} back to start of item
        ld      e,(hl)            ;{{d9e8:5e}} read offset ptr to next item
        inc     hl                ;{{d9e9:23}} 
        ld      d,(hl)            ;{{d9ea:56}} 
        inc     hl                ;{{d9eb:23}} 
        add     hl,de             ;{{d9ec:19}} add offset to start of arrays area
        pop     de                ;{{d9ed:d1}} retrieve start of arrays area
        jr      _update_array_list_heads_4;{{d9ee:18e3}}  (-$1d) next

;;========================================================================
;; command ERASE

command_ERASE:                    ;{{Addr=$d9f0 Code Calls/jump count: 0 Data use count: 1}}
        call    reset_variable_types_and_pointers;{{d9f0:cd4dea}} 
_command_erase_1:                 ;{{Addr=$d9f3 Code Calls/jump count: 1 Data use count: 0}}
        call    do_ERASE_parameter;{{d9f3:cdfcd9}} 
        call    next_token_if_prev_is_comma;{{d9f6:cd41de}} 
        jr      c,_command_erase_1;{{d9f9:38f8}}  (-$08) loop if more parameters
        ret                       ;{{d9fb:c9}} 

;;=do ERASE parameter
do_ERASE_parameter:               ;{{Addr=$d9fc Code Calls/jump count: 1 Data use count: 0}}
        call    parse_var_type_and_name;{{d9fc:cd31d9}} find the array
        push    hl                ;{{d9ff:e5}} 
        ld      a,(accumulator_data_type);{{da00:3a9fb0}} 
        call    get_array_area_and_array_list_head_ptr_for_type;{{da03:cd27d6}} 
        call    find_named_item_in_linked_list;{{da06:cd40d7}} 
        jp      nc,Error_Improper_Argument;{{da09:d24dcb}}  Error: Improper Argument (array not dimmed)

        ex      de,hl             ;{{da0c:eb}} 
        ld      c,(hl)            ;{{da0d:4e}} offset to next item
        inc     hl                ;{{da0e:23}} 
        ld      b,(hl)            ;{{da0f:46}} 
        inc     hl                ;{{da10:23}} 
        add     hl,bc             ;{{da11:09}} calc size of item
        call    BC_equal_HL_minus_DE;{{da12:cde4ff}}  BC = HL-DE
        call    move_lower_memory_down;{{da15:cde5f6}} move other items to fill gap
        call    prob_grow_array_space_ptrs_by_BC;{{da18:cd21f6}} 
        call    update_array_list_heads;{{da1b:cdc9d9}} rebuild list pointers??
        pop     hl                ;{{da1e:e1}} 
        ret                       ;{{da1f:c9}} 

;;============================
;;=clear FN params data
clear_FN_params_data:             ;{{Addr=$da20 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$0000          ;{{da20:210000}} ##LIT##
        ld      (FN_param_end),hl ;{{da23:2212ae}} 
        ld      (FN_param_start),hl;{{da26:2210ae}} 
        ret                       ;{{da29:c9}} 

;;=push FN header on execution stack
;DE=address of the DEF FN for this FN
push_FN_header_on_execution_stack:;{{Addr=$da2a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da2a:e5}} 
        ld      hl,(FN_param_start);{{da2b:2a10ae}} 
        ex      de,hl             ;{{da2e:eb}} 
        ld      a,$06             ;{{da2f:3e06}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{da31:cd72f6}} 
        ld      (FN_param_start),hl;{{da34:2210ae}} 
        ld      (hl),e            ;{{da37:73}} store address of DEF FN
        inc     hl                ;{{da38:23}} 
        ld      (hl),d            ;{{da39:72}} 
        inc     hl                ;{{da3a:23}} 
        xor     a                 ;{{da3b:af}} 
        ld      (hl),a            ;{{da3c:77}} store zero
        inc     hl                ;{{da3d:23}} 
        ld      (hl),a            ;{{da3e:77}} store zero
        inc     hl                ;{{da3f:23}} 
        ld      de,(FN_param_end) ;{{da40:ed5b12ae}} 
        ld      (hl),e            ;{{da44:73}} store end of FN params
        inc     hl                ;{{da45:23}} 
        ld      (hl),d            ;{{da46:72}} 
        pop     hl                ;{{da47:e1}} 
        ret                       ;{{da48:c9}} 

;;=copy FN param start to FN param end
copy_FN_param_start_to_FN_param_end:;{{Addr=$da49 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da49:e5}} Called after pushing all params on exec stack
        ld      hl,(FN_param_start);{{da4a:2a10ae}} 
        ld      (FN_param_end),hl ;{{da4d:2212ae}} 
        pop     hl                ;{{da50:e1}} 
        ret                       ;{{da51:c9}} 

;;=remove FN data from stack
remove_FN_data_from_stack:        ;{{Addr=$da52 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(FN_param_start);{{da52:2a10ae}} free our data off the exec stack
        call    set_execution_stack_next_free_ptr;{{da55:cd6ef6}} 
        ld      e,(hl)            ;{{da58:5e}} read and restore previous param_start
        inc     hl                ;{{da59:23}} 
        ld      d,(hl)            ;{{da5a:56}} 
        inc     hl                ;{{da5b:23}} 
        ld      (FN_param_start),de;{{da5c:ed5310ae}} 
        inc     hl                ;{{da60:23}} step over list header
        inc     hl                ;{{da61:23}} 
        ld      e,(hl)            ;{{da62:5e}} read and restore prev param_end
        inc     hl                ;{{da63:23}} 
        ld      d,(hl)            ;{{da64:56}} 
        ex      de,hl             ;{{da65:eb}} 
        ld      (FN_param_end),hl ;{{da66:2212ae}} 
        ret                       ;{{da69:c9}} 

;;=push FN parameter on execution stack
;An FN parameter uses the same data structures a regular variable. I.e a linked list
;this allocates space, copies the name and type, and updates the relevant list pointers
push_FN_parameter_on_execution_stack:;{{Addr=$da6a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{da6a:e5}} 
        ld      a,$02             ;{{da6b:3e02}} alloc space for link to next item
        call    possibly_alloc_A_bytes_on_execution_stack;{{da6d:cd72f6}} 
        ex      (sp),hl           ;{{da70:e3}} 
        call    set_accum_type_from_variable_type_atHL;{{da71:cdafd9}} 
        call    copy_var_name_onto_execution_stack;{{da74:cd6cd9}} 
        ex      (sp),hl           ;{{da77:e3}} 
        ex      de,hl             ;{{da78:eb}} 
        ld      hl,(FN_param_start);{{da79:2a10ae}} 
        inc     hl                ;{{da7c:23}} 
        inc     hl                ;{{da7d:23}} 
        ld      bc,$0000          ;{{da7e:010000}} ##LIT##
        call    poss_update_list_headers;{{da81:cdd0d7}} 
        ld      a,(accumulator_data_type);{{da84:3a9fb0}} variable type (and byte-size)
        ld      b,a               ;{{da87:47}} 
        inc     a                 ;{{da88:3c}} add a byte for data type descriptor
        call    possibly_alloc_A_bytes_on_execution_stack;{{da89:cd72f6}} alloc space for variable type and data
        ld      a,b               ;{{da8c:78}} 
        dec     a                 ;{{da8d:3d}} 
        ld      (hl),a            ;{{da8e:77}} store the data type
        inc     hl                ;{{da8f:23}} 
        ex      de,hl             ;{{da90:eb}} 
        pop     hl                ;{{da91:e1}} 
        ret                       ;{{da92:c9}} 

;;=iterate all string variables
;iterates through all string variables and calls the code in DE for each one.
iterate_all_string_variables:     ;{{Addr=$da93 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(FN_param_start);{{da93:2a10ae}} start with any FNs, if present

;;=FN stack loop
FN_stack_loop:                    ;{{Addr=$da96 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{da96:7c}} 
        or      l                 ;{{da97:b5}} 
        jr      z,iterate_all_main_variables;{{da98:280e}}  (+$0e) no/end of/ FNs, do main variables
        ld      c,(hl)            ;{{da9a:4e}} pointer to next FN data block on stack
        inc     hl                ;{{da9b:23}} 
        ld      b,(hl)            ;{{da9c:46}} 
        inc     hl                ;{{da9d:23}} 
        push    bc                ;{{da9e:c5}} 
        ld      bc,$0000          ;{{da9f:010000}} FN pointers are relative to start of memory ##LIT##
        call    iterate_all_strings_in_a_linked_list;{{daa2:cde9da}} 
        pop     hl                ;{{daa5:e1}} 
        jr      FN_stack_loop     ;{{daa6:18ee}}  (-$12)

;;=iterate all main variables
iterate_all_main_variables:       ;{{Addr=$daa8 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$1a41          ;{{daa8:01411a}} B=number of linked lists. C=index of first one ('A')
;;=var linked list headers loop
var_linked_list_headers_loop:     ;{{Addr=$daab Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{daab:c5}} 
        ld      a,c               ;{{daac:79}} list index
        call    get_VarFN_area_and_list_head_ptr;{{daad:cd19d6}} get list header (and base for offsets)
        call    iterate_all_strings_in_a_linked_list;{{dab0:cde9da}} 
        pop     bc                ;{{dab3:c1}} 
        inc     c                 ;{{dab4:0c}} next index
        djnz    var_linked_list_headers_loop;{{dab5:10f4}}  (-$0c) loop

                                  ;now do array linked lists
        ld      a,$03             ;{{dab7:3e03}} string type
        call    get_array_area_and_array_list_head_ptr_for_type;{{dab9:cd27d6}} get list header for string arrays (and base for offsets)
        push    hl                ;{{dabc:e5}} 

;;=array linked list loop
array_linked_list_loop:           ;{{Addr=$dabd Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{dabd:e1}} walk each item in the linked list
        ld      c,(hl)            ;{{dabe:4e}} get offset for first/next item
        inc     hl                ;{{dabf:23}} 
        ld      b,(hl)            ;{{dac0:46}} 
        ld      a,b               ;{{dac1:78}} 
        or      c                 ;{{dac2:b1}} 
        ret     z                 ;{{dac3:c8}} end of list

        ld      hl,(address_of_start_of_Arrays_area_);{{dac4:2a6aae}} 
        dec     hl                ;{{dac7:2b}} 
        add     hl,bc             ;{{dac8:09}} absolute address of item
        push    hl                ;{{dac9:e5}} 
        push    de                ;{{daca:d5}} 
        call    poss_step_over_string;{{dacb:cd65d7}} step over array name and type
        pop     de                ;{{dace:d1}} 
        inc     hl                ;{{dacf:23}} 
        ld      c,(hl)            ;{{dad0:4e}} 
        inc     hl                ;{{dad1:23}} 
        ld      b,(hl)            ;{{dad2:46}} BC=size of array data?
        inc     hl                ;{{dad3:23}} 
        push    hl                ;{{dad4:e5}} current
        add     hl,bc             ;{{dad5:09}} array end
        ex      (sp),hl           ;{{dad6:e3}} stack=array end/HL=current
        ld      c,(hl)            ;{{dad7:4e}} C=number of dimensions
        inc     hl                ;{{dad8:23}} 
        ld      b,$00             ;{{dad9:0600}} BC=number of dimensions
        add     hl,bc             ;{{dadb:09}} step over dimensions data
        add     hl,bc             ;{{dadc:09}} HL=first element of array
        pop     bc                ;{{dadd:c1}} BC=end of elements data

;;=array elements loop
array_elements_loop:              ;{{Addr=$dade Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_BC     ;{{dade:cddeff}}  HL=BC?
        jr      z,array_linked_list_loop;{{dae1:28da}}  (-$26) next item in list
        call    read_string_data_and_call_callback;{{dae3:cd02db}} 
        inc     hl                ;{{dae6:23}} 
        jr      array_elements_loop;{{dae7:18f5}}  (-$0b)

;;=iterate all strings in a linked list
iterate_all_strings_in_a_linked_list:;{{Addr=$dae9 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{dae9:7e}} offset of next item
        inc     hl                ;{{daea:23}} 
        ld      h,(hl)            ;{{daeb:66}} 
        ld      l,a               ;{{daec:6f}} 
        or      h                 ;{{daed:b4}} 
        ret     z                 ;{{daee:c8}} end of list

        add     hl,bc             ;{{daef:09}} add base to offset
        push    hl                ;{{daf0:e5}} 
        push    de                ;{{daf1:d5}} 
        call    poss_step_over_string;{{daf2:cd65d7}} step over variable name
        pop     de                ;{{daf5:d1}} 
        ld      a,(hl)            ;{{daf6:7e}} type??
        inc     hl                ;{{daf7:23}} 
        and     $07               ;{{daf8:e607}} 
        cp      $02               ;{{dafa:fe02}} type must be 2??? that's int, not strings!!
        call    z,read_string_data_and_call_callback;{{dafc:cc02db}} do callback
        pop     hl                ;{{daff:e1}} 
        jr      iterate_all_strings_in_a_linked_list;{{db00:18e7}}  (-$19) loop

;;=read string data and call callback
read_string_data_and_call_callback:;{{Addr=$db02 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{db02:c5}} 
        push    de                ;{{db03:d5}} 
        ld      a,(hl)            ;{{db04:7e}} length
        inc     hl                ;{{db05:23}} 
        ld      c,(hl)            ;{{db06:4e}} address
        inc     hl                ;{{db07:23}} 
        ld      b,(hl)            ;{{db08:46}} 
        push    hl                ;{{db09:e5}} 
        ex      de,hl             ;{{db0a:eb}} 
        or      a                 ;{{db0b:b7}} 
        call    nz,JP_HL          ;{{db0c:c4fbff}}  JP (HL) - dispatch callback
        pop     hl                ;{{db0f:e1}} 
        pop     de                ;{{db10:d1}} 
        pop     bc                ;{{db11:c1}} 
        ret                       ;{{db12:c9}} 




