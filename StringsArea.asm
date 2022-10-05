;;<<STRINGS AREA
;;<Including the string stack, FRE and the garbage collector
;;==========================================
;;=copy all strings vars to strings area if not in strings area
;See comments for the next routine. Makes sure no strings being referenced within the code.
;Used by immediate mode and before a CHAIN or DELETE modifies the program.
copy_all_strings_vars_to_strings_area_if_not_in_strings_area:;{{Addr=$fb4d Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{fb4d:d5}} 
        push    hl                ;{{fb4e:e5}} 
        ld      de,do_copy_string_to_strings_area_if_not_in_strings_area;{{fb4f:1165fb}}   ##LABEL##
        call    iterate_all_string_variables;{{fb52:cd93da}} 
        pop     hl                ;{{fb55:e1}} 
        pop     de                ;{{fb56:d1}} 
        ret                       ;{{fb57:c9}} 

;;==========================
;;copy string to strings area if not in strings area
;Ensures that a string is stored in the strings area. 
;I.e that the string is not a constant in the program.
;This prevent changes to a string from editing the program itself.
;This is used but the statement form of MID$ and the @ operator,
;and also after evaluating a string expression - strings are only ever 
;referenced once, not copying after an expression would leave it being referenced twice
copy_string_to_strings_area_if_not_in_strings_area:;{{Addr=$fb58 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{fb58:e5}} 
        ld      a,(hl)            ;{{fb59:7e}} 
        inc     hl                ;{{fb5a:23}} 
        ld      c,(hl)            ;{{fb5b:4e}} 
        inc     hl                ;{{fb5c:23}} 
        ld      b,(hl)            ;{{fb5d:46}} 
        ex      de,hl             ;{{fb5e:eb}} 
        or      a                 ;{{fb5f:b7}} 
        call    nz,do_copy_string_to_strings_area_if_not_in_strings_area;{{fb60:c465fb}} 
        pop     hl                ;{{fb63:e1}} 
        ret                       ;{{fb64:c9}} 

;;=do copy string to strings area if not in strings area
;Called via string variable iterator
;DE=addr of /last/ byte of string descriptor
;BC=string address
;A=string length
do_copy_string_to_strings_area_if_not_in_strings_area:;{{Addr=$fb65 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_end_of_free_space_);{{fb65:2a71b0}} Checks if BC is withing a strings area and returns if it is
        call    compare_HL_BC     ;{{fb68:cddeff}}  HL=BC?
        jr      nc,_do_copy_string_to_strings_area_if_not_in_strings_area_6;{{fb6b:3007}}  (+$07)
        ld      hl,(address_of_end_of_Strings_area_);{{fb6d:2a73b0}} 
        call    compare_HL_BC     ;{{fb70:cddeff}}  HL=BC?
        ret     nc                ;{{fb73:d0}} 

_do_copy_string_to_strings_area_if_not_in_strings_area_6:;{{Addr=$fb74 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fb74:eb}} 
        dec     hl                ;{{fb75:2b}} 
        dec     hl                ;{{fb76:2b}} 
        push    hl                ;{{fb77:e5}} HL=address of string descriptor
        call    alloc_and_copy_string_atHL_to_strings_area;{{fb78:cdb9fb}} Writes allocated address to last-string-used variable
        pop     hl                ;{{fb7b:e1}} 

;;=store last string used (descriptor) to HL
store_last_string_used_descriptor_to_HL:;{{Addr=$fb7c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(length_of_last_String_used);{{fb7c:3a9cb0}} 
        ld      (hl),a            ;{{fb7f:77}} 
        inc     hl                ;{{fb80:23}} 
        ld      de,(address_of_last_String_used);{{fb81:ed5b9db0}} 
        ld      (hl),e            ;{{fb85:73}} 
        inc     hl                ;{{fb86:23}} 
        ld      (hl),d            ;{{fb87:72}} 
        inc     hl                ;{{fb88:23}} 
        ret                       ;{{fb89:c9}} 

;;====================================================
;;=push accum to strings stack and strings area if not on string stack
push_accum_to_strings_stack_and_strings_area_if_not_on_string_stack:;{{Addr=$fb8a Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_address_in_string_stack;{{fb8a:cd37fc}} 
        ret     c                 ;{{fb8d:d8}} 

        call    alloc_and_copy_string_atHL_to_strings_area;{{fb8e:cdb9fb}} 
        jp      push_last_string_descriptor_on_string_stack;{{fb91:c3d6fb}} 

;;================================================
;;=prob copy to strings area if not const in program or ROM
prob_copy_to_strings_area_if_not_const_in_program_or_ROM:;{{Addr=$fb94 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fb94:2aa0b0}} 
        call    pop_TOS_from_string_stack;{{fb97:cd1ffc}} 
        ld      a,b               ;{{fb9a:78}} 
        or      a                 ;{{fb9b:b7}} 
        ret     z                 ;{{fb9c:c8}} 

        push    hl                ;{{fb9d:e5}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{fb9e:2a64ae}} 
        call    compare_HL_DE     ;{{fba1:cdd8ff}}  HL=DE?
        ld      hl,(address_of_end_of_Strings_area_);{{fba4:2a73b0}} 
        ex      de,hl             ;{{fba7:eb}} 
        call    c,compare_HL_DE   ;{{fba8:dcd8ff}}  HL=DE?
        jr      nc,_prob_copy_to_strings_area_if_not_const_in_program_or_rom_15;{{fbab:300a}}  (+$0a)
        ld      de,(address_after_end_of_program);{{fbad:ed5b66ae}} 
        call    compare_HL_DE     ;{{fbb1:cdd8ff}}  HL=DE?
        call    nc,is_accumulator_address_in_string_stack;{{fbb4:d437fc}} 
_prob_copy_to_strings_area_if_not_const_in_program_or_rom_15:;{{Addr=$fbb7 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{fbb7:e1}} 
        ret     c                 ;{{fbb8:d8}} 

;;=alloc and copy string atHL to strings area
;HL=address of a string descriptor
alloc_and_copy_string_atHL_to_strings_area:;{{Addr=$fbb9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{fbb9:7e}} 
        call    alloc_space_in_strings_area;{{fbba:cd41fc}} 
        push    de                ;{{fbbd:d5}} 
        ld      a,(hl)            ;{{fbbe:7e}} 
        inc     hl                ;{{fbbf:23}} 
        ld      c,(hl)            ;{{fbc0:4e}} 
        inc     hl                ;{{fbc1:23}} 
        ld      h,(hl)            ;{{fbc2:66}} 
        ld      l,c               ;{{fbc3:69}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{fbc4:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     de                ;{{fbc7:d1}} 
        ld      hl,length_of_last_String_used;{{fbc8:219cb0}} 
        ret                       ;{{fbcb:c9}} 

;;=================
;;clear string stack
clear_string_stack:               ;{{Addr=$fbcc Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,string_stack_first;{{fbcc:217eb0}} 
        ld      (string_stack_first_free_ptr),hl;{{fbcf:227cb0}} 
        ret                       ;{{fbd2:c9}} 

;;=alloc string push on stack and accumulator
alloc_string_push_on_stack_and_accumulator:;{{Addr=$fbd3 Code Calls/jump count: 2 Data use count: 0}}
        call    alloc_space_in_strings_area;{{fbd3:cd41fc}} 

;;=push last string descriptor on string stack
;Also puts the address of the pushed descriptor in the accumulator
push_last_string_descriptor_on_string_stack:;{{Addr=$fbd6 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{fbd6:e5}} 
        ld      a,$03             ;{{fbd7:3e03}} accumulator is a string
        ld      (accumulator_data_type),a;{{fbd9:329fb0}} 
        ld      hl,(string_stack_first_free_ptr);{{fbdc:2a7cb0}} 
        ld      (accumulator),hl  ;{{fbdf:22a0b0}} 
        ld      de,string_stack_last + 1;{{fbe2:119cb0}} also next byte after end of string stack
        call    compare_HL_DE     ;{{fbe5:cdd8ff}}  HL=DE?       ;is string stack full
        ld      a,$10             ;{{fbe8:3e10}} String expression too complex error
        jp      z,raise_error     ;{{fbea:ca55cb}} 
        call    store_last_string_used_descriptor_to_HL;{{fbed:cd7cfb}} 
        ld      (string_stack_first_free_ptr),hl;{{fbf0:227cb0}} 
        pop     hl                ;{{fbf3:e1}} 
        ret                       ;{{fbf4:c9}} 

;;===================================
;;get accumulator string length
get_accumulator_string_length:    ;{{Addr=$fbf5 Code Calls/jump count: 11 Data use count: 0}}
        push    hl                ;{{fbf5:e5}} 
        call    error_if_accumulator_is_not_a_string;{{fbf6:cd5eff}} 
        ld      hl,(accumulator)  ;{{fbf9:2aa0b0}} 
        call    pop_TOS_from_string_stack_and_strings_area;{{fbfc:cd03fc}} 
        pop     hl                ;{{fbff:e1}} 
        ld      a,b               ;{{fc00:78}} 
        or      a                 ;{{fc01:b7}} 
        ret                       ;{{fc02:c9}} 

;;===================================
;;pop TOS from string stack and strings area
;Pops the top-most item from the string stack and also from the strings area(?)
pop_TOS_from_string_stack_and_strings_area:;{{Addr=$fc03 Code Calls/jump count: 5 Data use count: 0}}
        call    pop_TOS_from_string_stack;{{fc03:cd1ffc}} 
        ret     nz                ;{{fc06:c0}} string addr <> HL

        ld      a,b               ;{{fc07:78}} 
        or      a                 ;{{fc08:b7}} 
        ret     z                 ;{{fc09:c8}} empty string

        ld      hl,(address_of_end_of_free_space_);{{fc0a:2a71b0}} we've popped a string off the stack
        inc     hl                ;{{fc0d:23}} 
        inc     hl                ;{{fc0e:23}} 
        inc     hl                ;{{fc0f:23}} 
        call    compare_HL_DE     ;{{fc10:cdd8ff}}  HL=DE? (DE = address of popped string)
        ret     nz                ;{{fc13:c0}} 

        dec     hl                ;{{fc14:2b}} 
        dec     hl                ;{{fc15:2b}} 
        ld      l,(hl)            ;{{fc16:6e}} length of last item?
        ld      h,$00             ;{{fc17:2600}} 
        add     hl,de             ;{{fc19:19}} move to free space?
        dec     hl                ;{{fc1a:2b}} 
        ld      (address_of_end_of_free_space_),hl;{{fc1b:2271b0}} 
        ret                       ;{{fc1e:c9}} 

;;=pop TOS from string stack
;Pops the top-most item from the string stack but doesn't affect the strings area
;returns HL=addr, B=length
;if HL=address of last item then 'pops' it off the concat stack
pop_TOS_from_string_stack:        ;{{Addr=$fc1f Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{fc1f:e5}} 
        ld      de,(string_stack_first_free_ptr);{{fc20:ed5b7cb0}} 
        dec     de                ;{{fc24:1b}} 
        dec     de                ;{{fc25:1b}} 
        dec     de                ;{{fc26:1b}} 
        call    compare_HL_DE     ;{{fc27:cdd8ff}}  HL=DE?
        jr      nz,_pop_tos_from_string_stack_8;{{fc2a:2004}}  (+$04)
        ld      (string_stack_first_free_ptr),de;{{fc2c:ed537cb0}} 
_pop_tos_from_string_stack_8:     ;{{Addr=$fc30 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,(hl)            ;{{fc30:46}} 
        inc     hl                ;{{fc31:23}} 
        ld      e,(hl)            ;{{fc32:5e}} 
        inc     hl                ;{{fc33:23}} 
        ld      d,(hl)            ;{{fc34:56}} 
        pop     hl                ;{{fc35:e1}} 
        ret                       ;{{fc36:c9}} 

;;============================
;;is accumulator address in string stack
;Is the uint in the accumulator in the string stack (or higher - but no strings stored higher)
;NOTE: this used tha accumulator value as a pointer to a string descriptor, NOT a string descriptor
is_accumulator_address_in_string_stack:;{{Addr=$fc37 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fc37:2aa0b0}} 
        ld      a,string_stack_first - 1 and $ff;{{fc3a:3e7d}}  $7d  string stack start - 1 (low byte)
        sub     l                 ;{{fc3c:95}} 
        ld      a,string_stack_first - 1 >> 8;{{fc3d:3eb0}}  $b0  string stack start - 1 (high byte)
        sbc     a,h               ;{{fc3f:9c}} 
        ret                       ;{{fc40:c9}} 

;;==============================
;;alloc space in strings area
;Allocs A + 2 bytes in the strings area (i.e to the bottom)
;Two bottom-most bytes store the number of bytes allocated.
;Address above, and string length, that is written to the last-string-used variable
;Writes the bytes allocated to start of strings area
;A=string length
;HL=string address
;Returns A,HL unmodified
alloc_space_in_strings_area:      ;{{Addr=$fc41 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{fc41:e5}} 
        push    bc                ;{{fc42:c5}} 
        ld      c,a               ;{{fc43:4f}} 
        or      a                 ;{{fc44:b7}} 
        call    nz,alloc_C_bytes_in_string_space;{{fc45:c493f6}} 
        ld      a,c               ;{{fc48:79}} 
        ld      (length_of_last_String_used),a;{{fc49:329cb0}} 
        ld      (address_of_last_String_used),hl;{{fc4c:229db0}} 
        ex      de,hl             ;{{fc4f:eb}} 
        pop     bc                ;{{fc50:c1}} 
        pop     hl                ;{{fc51:e1}} 
        ret                       ;{{fc52:c9}} 

;;========================================================
;; function FRE
;FRE(<numeric expression>)
;FRE(<string expression>)
;The value of the arguments is irrelevant, only the type. Thus the preferred forms are:
;FRE(0)
;FRE("")
;FRE with a numeric parameter returns the amount of free space in bytes
;FRE with a string parameter performs a garbage collection before returning the number of free bytes.
;Garbage collection involves removing empty space within the strings allocation area.
;Garbage collection will also happen if BASIC runs out of memory

function_FRE:                     ;{{Addr=$fc53 Code Calls/jump count: 0 Data use count: 1}}
        call    is_accumulator_a_string;{{fc53:cd66ff}} 
        jr      nz,_function_fre_4;{{fc56:2006}}  (+$06) Not a string - just return length
        call    get_accumulator_string_length;{{fc58:cdf5fb}} 
        call    strings_area_garbage_collection;{{fc5b:cd64fc}} 
_function_fre_4:                  ;{{Addr=$fc5e Code Calls/jump count: 1 Data use count: 0}}
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{fc5e:cdfcf6}} 
        jp      set_accumulator_as_REAL_from_unsigned_INT;{{fc61:c389fe}} 

;;=strings area garbage collection
strings_area_garbage_collection:  ;{{Addr=$fc64 Code Calls/jump count: 6 Data use count: 0}}
        push    hl                ;{{fc64:e5}} 
        push    de                ;{{fc65:d5}} 
        push    bc                ;{{fc66:c5}} 
        ld      hl,string_stack_first;{{fc67:217eb0}} 
        jr      _strings_gc_prepare_loop_10;{{fc6a:180c}}  (+$0c)

;Loops over every string in the strings area,
;Swaps the string address in the descriptor with the two bytes preceding the string
;Thus every string is now preceded by it's address
;;=strings gc prepare loop
strings_gc_prepare_loop:          ;{{Addr=$fc6c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{fc6c:7e}} 
        inc     hl                ;{{fc6d:23}} 
        ld      c,(hl)            ;{{fc6e:4e}} 
        inc     hl                ;{{fc6f:23}} 
        ld      b,(hl)            ;{{fc70:46}} 
        ex      de,hl             ;{{fc71:eb}} 
        or      a                 ;{{fc72:b7}} 
        call    nz,_strings_area_gc_finalise_loop_23;{{fc73:c4e3fc}} 
        ex      de,hl             ;{{fc76:eb}} 
        inc     hl                ;{{fc77:23}} 

;HL=bottom of string stack
_strings_gc_prepare_loop_10:      ;{{Addr=$fc78 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(string_stack_first_free_ptr);{{fc78:ed5b7cb0}} Top of string stack
        call    compare_HL_DE     ;{{fc7c:cdd8ff}}  HL=DE?
        jr      nz,strings_gc_prepare_loop;{{fc7f:20eb}}  (-$15) 

;Now does the same for every string variable
        ld      de,_strings_area_gc_finalise_loop_23;{{fc81:11e3fc}}   ##LABEL##
        call    iterate_all_string_variables;{{fc84:cd93da}} 


        ld      hl,(address_of_end_of_Strings_area_);{{fc87:2a73b0}} 
        push    hl                ;{{fc8a:e5}} 
        ld      hl,(address_of_end_of_free_space_);{{fc8b:2a71b0}} 
        inc     hl                ;{{fc8e:23}} 
        ld      e,l               ;{{fc8f:5d}} 
        ld      d,h               ;{{fc90:54}} 
        jr      _strings_gc_compact_loop_16;{{fc91:1814}}  (+$14)


;Loop through every string in the strings area, starting with the first (lowest address).
;Copies each string to the start of the strings area (after any strings already copied),
;BUT does not copy any free space. Thus all current strings are moved to a single block
;at the start of the strings area.
;;=strings gc compact loop
strings_gc_compact_loop:          ;{{Addr=$fc93 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{fc93:4e}} BC=address of string descriptor?
        inc     hl                ;{{fc94:23}} 
        ld      b,(hl)            ;{{fc95:46}} 
        inc     b                 ;{{fc96:04}} 
        dec     b                 ;{{fc97:05}} Test for high byte of address = 0 (free space?)
        jr      z,_strings_gc_compact_loop_14;{{fc98:280b}}  (+$0b)
        dec     hl                ;{{fc9a:2b}} 
        ld      a,(bc)            ;{{fc9b:0a}} String length from descriptor?
        ld      c,a               ;{{fc9c:4f}} 
        ld      b,$00             ;{{fc9d:0600}} 
        inc     bc                ;{{fc9f:03}} 
        inc     bc                ;{{fca0:03}} BC=length+2?
        ldir                      ;{{fca1:edb0}} LDIR - copy string
        jr      _strings_gc_compact_loop_16;{{fca3:1802}}  (+$02)

_strings_gc_compact_loop_14:      ;{{Addr=$fca5 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{fca5:23}} 
        add     hl,bc             ;{{fca6:09}} 

;HL=DE=start of strings area. TOS=end of strings area
_strings_gc_compact_loop_16:      ;{{Addr=$fca7 Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{fca7:c1}} BC=end of strings area
        push    bc                ;{{fca8:c5}} 
        call    compare_HL_BC     ;{{fca9:cddeff}}  HL=BC?
        jr      c,strings_gc_compact_loop;{{fcac:38e5}}  (-$1b)


;All strings now compacted. DE=end of compacted strings
;Calc the number of bytes in this block and LDDR copy them to the end of the strings area
        dec     de                ;{{fcae:1b}} 
        ld      hl,(address_of_end_of_free_space_);{{fcaf:2a71b0}} 
        ex      de,hl             ;{{fcb2:eb}} 
        call    BC_equal_HL_minus_DE;{{fcb3:cde4ff}}  BC = HL-DE
        pop     de                ;{{fcb6:d1}} 
        call    compare_HL_DE     ;{{fcb7:cdd8ff}}  HL=DE?
        push    af                ;{{fcba:f5}} 
        push    de                ;{{fcbb:d5}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{fcbc:cdf5ff}}  copy bytes LDDR (BC = count)

        ex      de,hl             ;{{fcbf:eb}} 
        ld      (address_of_end_of_free_space_),hl;{{fcc0:2271b0}} Now write the new start of strings area
        pop     bc                ;{{fcc3:c1}} 
        inc     hl                ;{{fcc4:23}} 
        jr      _strings_area_gc_finalise_loop_16;{{fcc5:1812}}  (+$12)

;Loops through the strings area and swaps back the address and descriptor info
;;=strings area gc finalise loop
strings_area_gc_finalise_loop:    ;{{Addr=$fcc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{fcc7:5e}} DE=(HL) - string descriptor address?
        inc     hl                ;{{fcc8:23}} 
        ld      d,(hl)            ;{{fcc9:56}} 
        dec     hl                ;{{fcca:2b}} 
        ld      a,(de)            ;{{fccb:1a}} A=string length?
        ld      (hl),a            ;{{fccc:77}} (HL)=length
        inc     hl                ;{{fccd:23}} 
        ld      (hl),$00          ;{{fcce:3600}} 
        inc     hl                ;{{fcd0:23}} 
        ex      de,hl             ;{{fcd1:eb}} 
        ld      (hl),d            ;{{fcd2:72}} String address?
        dec     hl                ;{{fcd3:2b}} 
        ld      (hl),e            ;{{fcd4:73}} 
        ld      l,a               ;{{fcd5:6f}} HL=length?
        ld      h,$00             ;{{fcd6:2600}} 
        add     hl,de             ;{{fcd8:19}} 

;HL=new last byte of free memory (byte before new strings area)
;DE=address of last byte of strings area
_strings_area_gc_finalise_loop_16:;{{Addr=$fcd9 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_BC     ;{{fcd9:cddeff}}  HL=BC?
        jr      c,strings_area_gc_finalise_loop;{{fcdc:38e9}}  (-$17)

        pop     af                ;{{fcde:f1}} 
        pop     bc                ;{{fcdf:c1}} 
        pop     de                ;{{fce0:d1}} 
        pop     hl                ;{{fce1:e1}} 
        ret                       ;{{fce2:c9}} 

;;strings gc prepare string
;DE=addr of /last/ byte of string descriptor passed in A,BC
;BC=string address
;A=string length
_strings_area_gc_finalise_loop_23:;{{Addr=$fce3 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_start_of_free_space_);{{fce3:2a6cae}} 
        call    compare_HL_BC     ;{{fce6:cddeff}}  HL=BC?
        ret     nc                ;{{fce9:d0}} 

;Load DE to (BC-2) and byte what was at (BC-2) to (DE)
;Ie swap the address (of last byte) of string descriptor with the two bytes before the string
;Thus every string is now preceded by the address of it's string descriptor?
        dec     bc                ;{{fcea:0b}} BC=byte before string
        ld      a,d               ;{{fceb:7a}} A=high byte of descriptor address
        ld      (bc),a            ;{{fcec:02}} Byte before string = high byte of descriptor address
        dec     bc                ;{{fced:0b}} BC=two bytes before string
        ld      a,(bc)            ;{{fcee:0a}} A=??
        ld      (de),a            ;{{fcef:12}} 
        ld      a,e               ;{{fcf0:7b}} 
        ld      (bc),a            ;{{fcf1:02}} 
        ret                       ;{{fcf2:c9}} 

;;==========================================
;;=prepare accum and regs for word to string
prepare_accum_and_regs_for_word_to_string:;{{Addr=$fcf3 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fcf3:cd4fff}} 
        jp      nc,REAL_prepare_for_decimal;{{fcf6:d276bd}}  firmware maths??
        call    prep_regs_for_int_to_string;{{fcf9:cd2add}} B=H, C=$01, E=$00
        ld      (accumulator),hl  ;{{fcfc:22a0b0}} 
        ld      hl,accumulator_plus_1;{{fcff:21a1b0}} 
        ret                       ;{{fd02:c9}} 

;;=============================================
;;=set regs for int to string conv
set_regs_for_int_to_string_conv:  ;{{Addr=$fd03 Code Calls/jump count: 1 Data use count: 0}}
        call    function_UNT      ;{{fd03:cdebfe}} 
        ld      hl,accumulator_plus_1;{{fd06:21a1b0}} 
        jp      set_B_zero_E_zero_C_to_2_int_type;{{fd09:c330dd}} 




