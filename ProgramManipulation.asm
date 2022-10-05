;;<< PROGRAM EDITING AND MANIPULATION
;;< DELETE, RENUM, DATA, REM, ', ELSE and
;;< a bunch of related utility stuff
;;=====================================================
;;clear program
clear_program:                    ;{{Addr=$e761 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{e761:af}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e762:2a64ae}} 
        ld      (hl),a            ;{{e765:77}} Write zeros to line length and number. aka no program
        inc     hl                ;{{e766:23}} 
        ld      (hl),a            ;{{e767:77}} 
        inc     hl                ;{{e768:23}} 
        ld      (hl),a            ;{{e769:77}} 
        inc     hl                ;{{e76a:23}} 
        ld      (address_after_end_of_program),hl;{{e76b:2266ae}} 
        jr      clear_line_address_vs_line_number_flag;{{e76e:1811}}  (+$11)

;;=============================================================================
;;=convert all line addresses to line numbers
;Line numbers are stored as line numbers during editing,
;then converted to addresses as they are encountered during execution.
;This routine converts them back to numbers (ready for edit mode)
convert_all_line_addresses_to_line_numbers:;{{Addr=$e770 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(line_address_vs_line_number_flag);{{e770:3a21ae}} 
        or      a                 ;{{e773:b7}} 
        ret     z                 ;{{e774:c8}} Abort if we already have line addresses

        push    bc                ;{{e775:c5}} 
        push    de                ;{{e776:d5}} 
        push    hl                ;{{e777:e5}} 
        ld      bc,convert_line_addresses_to_line_numbers;{{e778:0186e7}}  convert line addresses to line number ##LABEL##
        call    statement_iterator;{{e77b:cdb9e9}} Iterator - calls code at BC for every statement
        pop     hl                ;{{e77e:e1}} 
        pop     de                ;{{e77f:d1}} 
        pop     bc                ;{{e780:c1}} 

;;=clear line address vs line number flag
clear_line_address_vs_line_number_flag:;{{Addr=$e781 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{e781:af}} 
        ld      (line_address_vs_line_number_flag),a;{{e782:3221ae}} Set flag
        ret                       ;{{e785:c9}} 

;;=================================================
;; convert line addresses to line numbers
;Converts any line addresses (pointers) within a statement to line numbers
convert_line_addresses_to_line_numbers:;{{Addr=$e786 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e786:cdfde9}} 
        cp      $02               ;{{e789:fe02}} 
        ret     c                 ;{{e78b:d8}} Return at end of line or end of statement

        cp      $1d               ;{{e78c:fe1d}}  16-bit line address pointer token
        jr      nz,convert_line_addresses_to_line_numbers;{{e78e:20f6}} 

        ld      d,(hl)            ;{{e790:56}}  get line address (target of GOTO, GOSUB etc)
        dec     hl                ;{{e791:2b}} 
        ld      e,(hl)            ;{{e792:5e}} 
        dec     hl                ;{{e793:2b}} 
        push    hl                ;{{e794:e5}} 
        ex      de,hl             ;{{e795:eb}} 
        inc     hl                ;{{e796:23}} 
        inc     hl                ;{{e797:23}} 
        inc     hl                ;{{e798:23}} 
        ld      e,(hl)            ;{{e799:5e}}  get line number
        inc     hl                ;{{e79a:23}} 
        ld      d,(hl)            ;{{e79b:56}} 
        pop     hl                ;{{e79c:e1}} 
        ld      (hl),$1e          ;{{e79d:361e}}  16-bit line number token
        inc     hl                ;{{e79f:23}} 
        ld      (hl),e            ;{{e7a0:73}} Write line number back into code
        inc     hl                ;{{e7a1:23}} 
        ld      (hl),d            ;{{e7a2:72}} 
        jr      convert_line_addresses_to_line_numbers;{{e7a3:18e1}} 

;;-----------------------------------------------------------------
;;=prob tokenise and insert line
;Tokenises the line in the edit buffer and inserts into the program
;at the appropriate position. The rest of the program is shifted up 
;(or down if the new line is shorter) as needed.
;Also handles deleting a line if only a line number is in the buffer.
prob_tokenise_and_insert_line:    ;{{Addr=$e7a5 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e7a5:7e}} Step over if leading space
        cp      $20               ;{{e7a6:fe20}} 
        jr      nz,_prob_tokenise_and_insert_line_4;{{e7a8:2001}}  (+$01)
        inc     hl                ;{{e7aa:23}} 

_prob_tokenise_and_insert_line_4: ;{{Addr=$e7ab Code Calls/jump count: 1 Data use count: 0}}
        call    convert_all_line_addresses_to_line_numbers;{{e7ab:cd70e7}}  line address to line number
        call    tokenise_a_BASIC_line;{{e7ae:cda4df}} 
        push    hl                ;{{e7b1:e5}} 
        call    skip_space_tab_or_line_feed;{{e7b2:cd4dde}}  skip space, lf or tab
        or      a                 ;{{e7b5:b7}} Empty line? if so, delete
        jr      z,do_delete_line  ;{{e7b6:2828}}  (+$28)
        push    bc                ;{{e7b8:c5}} 
        push    de                ;{{e7b9:d5}} 
        ld      hl,$0004          ;{{e7ba:210400}} Add four bytes for line length and line number...
        add     hl,bc             ;{{e7bd:09}} ...to raw tokenised line length
        push    hl                ;{{e7be:e5}} 
        push    hl                ;{{e7bf:e5}} 
        call    find_line         ;{{e7c0:cd64e8}} 
        push    hl                ;{{e7c3:e5}} 
        call    c,prob_move_program_data_down;{{e7c4:dce4e7}} 
        pop     de                ;{{e7c7:d1}} 
        pop     bc                ;{{e7c8:c1}} 
        call    move_lower_memory_up;{{e7c9:cdb8f6}} 
        call    prob_grow_all_program_space_pointers_by_BC;{{e7cc:cd07f6}} 
        ex      de,hl             ;{{e7cf:eb}} 
        pop     de                ;{{e7d0:d1}} 
        ld      (hl),e            ;{{e7d1:73}} Write line length?
        inc     hl                ;{{e7d2:23}} 
        ld      (hl),d            ;{{e7d3:72}} 
        inc     hl                ;{{e7d4:23}} 
        pop     de                ;{{e7d5:d1}} 
        ld      (hl),e            ;{{e7d6:73}} Write line number?
        inc     hl                ;{{e7d7:23}} 
        ld      (hl),d            ;{{e7d8:72}} 
        inc     hl                ;{{e7d9:23}} 
        pop     bc                ;{{e7da:c1}} 
        ex      de,hl             ;{{e7db:eb}} 
        pop     hl                ;{{e7dc:e1}} 
        ldir                      ;{{e7dd:edb0}} Copy line from buffer
        ret                       ;{{e7df:c9}} 

;;=do delete line
;(internal routine)
do_delete_line:                   ;{{Addr=$e7e0 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e7e0:e1}} 
        call    find_line_or_error;{{e7e1:cd5ce8}} 

;---------------------------------------------
;;=prob move program data down
;E.g. after deleting a line, or when an edited line is shorter
prob_move_program_data_down:      ;{{Addr=$e7e4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{e7e4:78}} BC=bytes to delete
        or      c                 ;{{e7e5:b1}} 
        ret     z                 ;{{e7e6:c8}} Abort if zero

        ex      de,hl             ;{{e7e7:eb}} 
        call    move_lower_memory_down;{{e7e8:cde5f6}} 
        jp      prob_grow_all_program_space_pointers_by_BC;{{e7eb:c307f6}} 

;;========================================================================
;; command DELETE
;DELETE <line number range>
;Deletes the lines in the given range

command_DELETE:                   ;{{Addr=$e7ee Code Calls/jump count: 0 Data use count: 1}}
        call    do_DELETE_find_byte_range;{{e7ee:cd00e8}} 
        call    error_if_not_end_of_statement_or_eoln;{{e7f1:cd37de}} 
        call    copy_all_strings_vars_to_strings_area_if_not_in_strings_area;{{e7f4:cd4dfb}} 
        call    do_DELETE_delete_lines;{{e7f7:cd1ae8}} 
        call    reset_exec_data   ;{{e7fa:cd8fc1}} 
        jp      REPL_Read_Eval_Print_Loop;{{e7fd:c358c0}} 

;;+do DELETE find byte range
do_DELETE_find_byte_range:        ;{{Addr=$e800 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_line_number_range_params;{{e800:cd0fcf}} 
        push    hl                ;{{e803:e5}} 
        push    bc                ;{{e804:c5}} 
        call    find_line_at_or_after_line_number;{{e805:cd82e8}} Find addr of first line to delete?
        pop     de                ;{{e808:d1}} 
        push    hl                ;{{e809:e5}} 
        call    find_line         ;{{e80a:cd64e8}} Find addr of end of last line to delete?
        ld      (DELETE_range_start),hl;{{e80d:2222ae}} Save start address
        ex      de,hl             ;{{e810:eb}} 
        pop     hl                ;{{e811:e1}} 
        or      a                 ;{{e812:b7}} 
        sbc     hl,de             ;{{e813:ed52}} Start - end = byte count
        ld      (DELETE_range_length),hl;{{e815:2224ae}} Save byte count
        pop     hl                ;{{e818:e1}} 
        ret                       ;{{e819:c9}} 

;;+do DELETE delete lines
do_DELETE_delete_lines:           ;{{Addr=$e81a Code Calls/jump count: 2 Data use count: 0}}
        call    convert_all_line_addresses_to_line_numbers;{{e81a:cd70e7}} 
        ld      bc,(DELETE_range_length);{{e81d:ed4b24ae}} Retrieve byte count
        ld      hl,(DELETE_range_start);{{e821:2a22ae}} Retrieve start address
        jp      prob_move_program_data_down;{{e824:c3e4e7}} 

;;=============================================================================
;;=eval and convert line number to line address
;HL points to either a line number ($1e) or line address ($1d) token
;If it's a line address, just return it.
;If it's a line number then convert it to a line address, store
;it back in the code and return it.
eval_and_convert_line_number_to_line_address:;{{Addr=$e827 Code Calls/jump count: 7 Data use count: 0}}
        inc     hl                ;{{e827:23}} 
        ld      e,(hl)            ;{{e828:5e}} Read line number or address
        inc     hl                ;{{e829:23}} 
        ld      d,(hl)            ;{{e82a:56}} 
        cp      $1d               ;{{e82b:fe1d}}  16-bit line address pointer token
        jr      z,_eval_and_convert_line_number_to_line_address_31;{{e82d:282a}}  (+$2a) if already an address so skip to end
        cp      $1e               ;{{e82f:fe1e}}  16-bit line number token
        jp      nz,Error_Syntax_Error;{{e831:c249cb}}  Error: Syntax Error

        push    hl                ;{{e834:e5}} 
        call    get_current_line_number;{{e835:cdb5de}} Compare target line number to current?
        call    c,compare_HL_DE   ;{{e838:dcd8ff}}  HL=DE? Carry = we have current line
        jr      nc,_eval_and_convert_line_number_to_line_address_18;{{e83b:300a}}  (+$0a), if target <= current line skip next bit

        pop     hl                ;{{e83d:e1}} If target line after current then scan to next line and scan from there
        push    hl                ;{{e83e:e5}} 
        inc     hl                ;{{e83f:23}} 
        call    skip_to_end_of_line;{{e840:cdade9}} ; Start scanning at next line
        inc     hl                ;{{e843:23}} 
        call    find_line_from_current;{{e844:cd68e8}} 

_eval_and_convert_line_number_to_line_address_18:;{{Addr=$e847 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,find_line_or_error;{{e847:d45ce8}} If NC then line number <= current so scan from the start
        dec     hl                ;{{e84a:2b}} 
        ex      de,hl             ;{{e84b:eb}} 
        pop     hl                ;{{e84c:e1}} Retrieve execution address (last byte of line number/address)
        dec     hl                ;{{e84d:2b}} Point to token
        dec     hl                ;{{e84e:2b}} 

                                  ;write line address and suitable token
        ld      a,$1d             ;{{e84f:3e1d}}  16-bit line address pointer
        ld      (line_address_vs_line_number_flag),a;{{e851:3221ae}} 
        ld      (hl),a            ;{{e854:77}} Write token
        inc     hl                ;{{e855:23}} 
        ld      (hl),e            ;{{e856:73}} Write address
        inc     hl                ;{{e857:23}} 
        ld      (hl),d            ;{{e858:72}} 

_eval_and_convert_line_number_to_line_address_31:;{{Addr=$e859 Code Calls/jump count: 1 Data use count: 0}}
        jp      get_next_token_skipping_space;{{e859:c32cde}}  get next token skipping space

;;==================================
;;find line or error
find_line_or_error:               ;{{Addr=$e85c Code Calls/jump count: 6 Data use count: 0}}
        call    find_line         ;{{e85c:cd64e8}} 
        ret     c                 ;{{e85f:d8}} 

        call    byte_following_call_is_error_code;{{e860:cd45cb}} 
        defb $08                  ;Inline error code: "Line does not exist"

;;====================================
;;find line
;;DE=line number
find_line:                        ;{{Addr=$e864 Code Calls/jump count: 9 Data use count: 0}}
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e864:2a64ae}} 
        inc     hl                ;{{e867:23}} 
;;=find line from current
;Scan forward starting at current
;If line found, returns C, Z
;If next line >= requested, returns NC, NZ
;If end of program found before line (last line number < requested line), returns NC, Z
find_line_from_current:           ;{{Addr=$e868 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,(hl)            ;{{e868:4e}} BC=line length
        inc     hl                ;{{e869:23}} 
        ld      b,(hl)            ;{{e86a:46}} 
        dec     hl                ;{{e86b:2b}} 
        ld      a,b               ;{{e86c:78}} End of program?
        or      c                 ;{{e86d:b1}} 
        ret     z                 ;{{e86e:c8}} 

        push    hl                ;{{e86f:e5}} 
        inc     hl                ;{{e870:23}} Step over length
        inc     hl                ;{{e871:23}} 
        ld      a,(hl)            ;{{e872:7e}} HL=line number
        inc     hl                ;{{e873:23}} 
        ld      h,(hl)            ;{{e874:66}} 
        ld      l,a               ;{{e875:6f}} 
        ex      de,hl             ;{{e876:eb}} 
        call    compare_HL_DE     ;{{e877:cdd8ff}}  Compare line number to requested
        ex      de,hl             ;{{e87a:eb}} 
        pop     hl                ;{{e87b:e1}} Retrieve start of line
        ccf                       ;{{e87c:3f}} 
        ret     nc                ;{{e87d:d0}} Line number > requested?

        ret     z                 ;{{e87e:c8}} Line number = requested?

        add     hl,bc             ;{{e87f:09}} Add line length to line address (ie. get next line)
        jr      find_line_from_current;{{e880:18e6}}  (-$1a)

;;======================================
;;find line at or after line number
;;BC=line number
find_line_at_or_after_line_number:;{{Addr=$e882 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e882:2a64ae}} 
        inc     hl                ;{{e885:23}} 
;Loop
_find_line_at_or_after_line_number_2:;{{Addr=$e886 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e886:e5}} 
        ld      c,(hl)            ;{{e887:4e}} BC=Line length
        inc     hl                ;{{e888:23}} 
        ld      b,(hl)            ;{{e889:46}} 
        inc     hl                ;{{e88a:23}} 
        ld      a,b               ;{{e88b:78}} End of program?
        or      c                 ;{{e88c:b1}} 
        scf                       ;{{e88d:37}} 
        jr      z,_find_line_at_or_after_line_number_18;{{e88e:2809}}  (+$09)

        ld      a,(hl)            ;{{e890:7e}} HL=line number
        inc     hl                ;{{e891:23}} 
        ld      h,(hl)            ;{{e892:66}} 
        ld      l,a               ;{{e893:6f}} 
        ex      de,hl             ;{{e894:eb}} 
        call    compare_HL_DE     ;{{e895:cdd8ff}}  Compare line number to requested
        ex      de,hl             ;{{e898:eb}} 

_find_line_at_or_after_line_number_18:;{{Addr=$e899 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e899:e1}} 
        ret     c                 ;{{e89a:d8}} 

        add     hl,bc             ;{{e89b:09}} Add line length to line address
        jr      _find_line_at_or_after_line_number_2;{{e89c:18e8}}  (-$18) Loop

;;========================================================================
;; command RENUM
;RENUM [<new line number>][,[<old line number>][,<increment>]]
;Renumbers part or all of a program and any references to line numbers

command_RENUM:                    ;{{Addr=$e89e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$000a          ;{{e89e:110a00}} Default first new line number
        call    nz,eval_renum_parameter;{{e8a1:c41ae9}} Eval first new line number, if given
        push    de                ;{{e8a4:d5}} 
        ld      de,$0000          ;{{e8a5:110000}} Default first old line number ###LIT### 
        call    next_token_if_prev_is_comma;{{e8a8:cd41de}} 
        call    c,eval_renum_parameter;{{e8ab:dc1ae9}} Eval first old line number, if given
        push    de                ;{{e8ae:d5}} 
        ld      de,$000a          ;{{e8af:110a00}} Default step
        call    next_token_if_prev_is_comma;{{e8b2:cd41de}} 
        call    c,eval_line_number_or_error;{{e8b5:dc48cf}} Eval step, if given
        call    error_if_not_end_of_statement_or_eoln;{{e8b8:cd37de}} 

        pop     hl                ;{{e8bb:e1}} HL=old line
        ex      de,hl             ;{{e8bc:eb}} HL=step, DE=old line
        ex      (sp),hl           ;{{e8bd:e3}} HL=new line, TOS=step
        ex      de,hl             ;{{e8be:eb}} HL=old line, DE=new line
        push    de                ;{{e8bf:d5}} Push new line number
        push    hl                ;{{e8c0:e5}} Push old line number
        call    find_line         ;{{e8c1:cd64e8}}  find address of first new line
        pop     de                ;{{e8c4:d1}} Retrieve old line number
        push    hl                ;{{e8c5:e5}} Save new line address
        call    find_line         ;{{e8c6:cd64e8}}  find address of first old line
        ex      de,hl             ;{{e8c9:eb}} DE=address of first old line
        pop     hl                ;{{e8ca:e1}} HL=address of first new line
        call    compare_HL_DE     ;{{e8cb:cdd8ff}} 
        jr      c,raise_improper_argument_error_E;{{e8ce:381d}}  (+$1d) Error if renumbering would re-order lines

        ex      de,hl             ;{{e8d0:eb}} HL=addr of first old
        pop     de                ;{{e8d1:d1}} DE=first new line number
        pop     bc                ;{{e8d2:c1}} BC=step
        push    de                ;{{e8d3:d5}} first new line number
        push    hl                ;{{e8d4:e5}} addr of first line

;;=renum scan loop
;Steps over the lines to be renumbered, this verifies the line numbers won't overflow
;before writing any changes
;DE=new line number
;HL=line address
renum_scan_loop:                  ;{{Addr=$e8d5 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e8d5:c5}} step
        ld      c,(hl)            ;{{e8d6:4e}} BC=line length
        inc     hl                ;{{e8d7:23}} 
        ld      b,(hl)            ;{{e8d8:46}} 
        ld      a,b               ;{{e8d9:78}} End of program?
        or      c                 ;{{e8da:b1}} 
        jr      z,do_renum        ;{{e8db:2813}}  (+$13)
        dec     hl                ;{{e8dd:2b}} HL=line addr

        add     hl,bc             ;{{e8de:09}} HL=line addr + line length
        ld      a,(hl)            ;{{e8df:7e}} End of program?
        inc     hl                ;{{e8e0:23}} 
        or      (hl)              ;{{e8e1:b6}} 
        jr      z,do_renum        ;{{e8e2:280c}}  (+$0c)
        dec     hl                ;{{e8e4:2b}} 

        pop     bc                ;{{e8e5:c1}} Step
        push    hl                ;{{e8e6:e5}} Current
        ex      de,hl             ;{{e8e7:eb}} HL=new line number
        add     hl,bc             ;{{e8e8:09}} Next line number
        ex      de,hl             ;{{e8e9:eb}} DE=next line number
        pop     hl                ;{{e8ea:e1}} Current
        jr      nc,renum_scan_loop;{{e8eb:30e8}}  (-$18) Loop if no overflow on next line number

;;=raise Improper Argument error
raise_improper_argument_error_E:  ;{{Addr=$e8ed Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{e8ed:c34dcb}}  Error: Improper Argument

;;=do renum
;Do the renumbering, having verified there won't be any errors
do_renum:                         ;{{Addr=$e8f0 Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,convert_line_numbers_to_line_addresses_callback;{{e8f0:0120e9}}  convert all line number tokens to line address tokens ##LABEL##
                                  ;this ensures any GOTOs, GOSUBs etc will still point to the correct place
        call    statement_iterator;{{e8f3:cdb9e9}} 

        pop     bc                ;{{e8f6:c1}} Step
        pop     hl                ;{{e8f7:e1}} Addr of first line
        pop     de                ;{{e8f8:d1}} First new line number

;;=do renum loop
do_renum_loop:                    ;{{Addr=$e8f9 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e8f9:c5}} Step
        push    hl                ;{{e8fa:e5}} Addr of line
        ld      c,(hl)            ;{{e8fb:4e}} BC=line length
        inc     hl                ;{{e8fc:23}} 
        ld      b,(hl)            ;{{e8fd:46}} 
        inc     hl                ;{{e8fe:23}} 
        ld      a,b               ;{{e8ff:78}} End of program?
        or      c                 ;{{e900:b1}} 
        jr      z,renum_done      ;{{e901:280c}}  (+$0c)

        ld      (hl),e            ;{{e903:73}} Write new line number
        inc     hl                ;{{e904:23}} 
        ld      (hl),d            ;{{e905:72}} 
        inc     hl                ;{{e906:23}} 

        pop     hl                ;{{e907:e1}} Addr of line
        add     hl,bc             ;{{e908:09}} Add line length
        pop     bc                ;{{e909:c1}} Step
        ex      de,hl             ;{{e90a:eb}} DE=line addr, HL=new line number
        add     hl,bc             ;{{e90b:09}} Next line number
        ex      de,hl             ;{{e90c:eb}} HL=line addr, DE=new line number
        jr      do_renum_loop     ;{{e90d:18ea}}  (-$16) Loop

;;=renum done
renum_done:                       ;{{Addr=$e90f Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e90f:e1}} Cleanup stack
        pop     hl                ;{{e910:e1}} 
        ld      bc,report_hanging_line_numbers;{{e911:0144e9}} RENUM can't cope with any references to lines which don't exist ##LABEL##
        call    statement_iterator;{{e914:cdb9e9}} This call will find any report them as errors to the user
        jp      REPL_Read_Eval_Print_Loop;{{e917:c358c0}} 

;;=eval renum parameter
eval_renum_parameter:             ;{{Addr=$e91a Code Calls/jump count: 2 Data use count: 0}}
        cp      $2c               ;{{e91a:fe2c}} ","
        call    nz,eval_line_number_or_error;{{e91c:c448cf}} 
        ret                       ;{{e91f:c9}} 

;;----------------------------------------------------------
;;=convert line numbers to line addresses callback
;Called via iterator__call_BC_for_each_statement
;Converts any line numbers (i.e GOTO, GOSUB etc) within a statement to line addresses
convert_line_numbers_to_line_addresses_callback:;{{Addr=$e920 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e920:cdfde9}} 
        cp      $02               ;{{e923:fe02}} 
        ret     c                 ;{{e925:d8}} End of line/end of statement - done

;; convert line number to line address

        cp      $1e               ;{{e926:fe1e}}  16-bit line number token
        jr      nz,convert_line_numbers_to_line_addresses_callback;{{e928:20f6}} Loop across any tokens we're not interested in

;; 16-bit line number
        push    hl                ;{{e92a:e5}} 
        ld      d,(hl)            ;{{e92b:56}} DE=Line number
        dec     hl                ;{{e92c:2b}} 
        ld      e,(hl)            ;{{e92d:5e}} 
        call    find_line         ;{{e92e:cd64e8}}  find address of line
        jr      nc,_convert_line_numbers_to_line_addresses_callback_22;{{e931:300e}} Not found - should never happen
        dec     hl                ;{{e933:2b}} 
        ex      de,hl             ;{{e934:eb}} 
        pop     hl                ;{{e935:e1}} 
        push    hl                ;{{e936:e5}} 

;; store 16-bit line address in reverse order
        ld      (hl),d            ;{{e937:72}} 
        dec     hl                ;{{e938:2b}} 
        ld      (hl),e            ;{{e939:73}} 
        dec     hl                ;{{e93a:2b}} 
;; Convert token to 16-bit line address
        ld      a,$1d             ;{{e93b:3e1d}}  16 bit line address pointer
        ld      (hl),a            ;{{e93d:77}} 

        ld      (line_address_vs_line_number_flag),a;{{e93e:3221ae}} 

_convert_line_numbers_to_line_addresses_callback_22:;{{Addr=$e941 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e941:e1}} 
        jr      convert_line_numbers_to_line_addresses_callback;{{e942:18dc}} Loop 

;;-------------------------------------------------------
;;=report hanging line numbers
;Called via iterator__call_BC_for_each_statement
;Looks for any line number (i.e GOTO, GOSUB etc) and raises an error if it finds any
;RENUMbering will fail if there are any references to line numbers which don't exist,
;this routine finds any and reports them.
report_hanging_line_numbers:      ;{{Addr=$e944 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e944:cdfde9}} 
        cp      $02               ;{{e947:fe02}} 
        ret     c                 ;{{e949:d8}} End of line/end of statement - done

;; 16-bit line number?
        cp      $1e               ;{{e94a:fe1e}}  16-bit line number token
        jr      nz,report_hanging_line_numbers;{{e94c:20f6}}  (-$0a) Loop across any tokens we're not interested in

        push    hl                ;{{e94e:e5}} 
        ld      d,(hl)            ;{{e94f:56}} DE=line number
        dec     hl                ;{{e950:2b}} 
        ld      e,(hl)            ;{{e951:5e}} 
        call    get_current_line_number;{{e952:cdb5de}} Get current line number for error reporting?
        call    undefined_line_n_in_n_error;{{e955:cde6cb}} Report the error
        pop     hl                ;{{e958:e1}} 
        jr      report_hanging_line_numbers;{{e959:18e9}}  (-$17) Loop

;;=============================================================================
;;=skip to ELSE statement
;Skip tokens within a line until the matching ELSE statement.
;We also need to skip nested IF statements. This is done by
;storing the nesting depth in the B register.
skip_to_ELSE_statement:           ;{{Addr=$e95b Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{e95b:0600}} 
        dec     hl                ;{{e95d:2b}} 
_skip_to_else_statement_2:        ;{{Addr=$e95e Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{e95e:04}} Inc nesting depth
_skip_to_else_statement_3:        ;{{Addr=$e95f Code Calls/jump count: 2 Data use count: 0}}
        call    skip_next_tokenised_item;{{e95f:cdfde9}} 
_skip_to_else_statement_4:        ;{{Addr=$e962 Code Calls/jump count: 1 Data use count: 0}}
        cp      $a1               ;{{e962:fea1}} IF token
        jr      z,_skip_to_else_statement_2;{{e964:28f8}}  (-$08) - inc nesting depth
        cp      $02               ;{{e966:fe02}} end of statement
        jr      nc,_skip_to_else_statement_3;{{e968:30f5}}  (-$0b)
        or      a                 ;{{e96a:b7}} 
        ret     z                 ;{{e96b:c8}} end of line - done

        call    skip_next_tokenised_item;{{e96c:cdfde9}} 
        cp      $97               ;{{e96f:fe97}} ELSE token
        jr      nz,_skip_to_else_statement_4;{{e971:20ef}}  (-$11)
        djnz    _skip_to_else_statement_3;{{e973:10ea}}  (-$16) dec nesting depth and loop if non zero
        call    get_next_token_skipping_space;{{e975:cd2cde}}  get next token skipping space
        inc     b                 ;{{e978:04}} 
        ret                       ;{{e979:c9}} 

;;=============================================================================
;;=skip over matched braces
;Starting at a '[' or '(', skips to the matching ')' or ']'.
;Note that array dimensions can use either character and start and end characters need 
;not be of the same type!
;Maintains a nesting depth in the B register
skip_over_matched_braces:         ;{{Addr=$e97a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e97a:7e}} 
        cp      $5b               ;{{e97b:fe5b}}  '['
        jr      z,_skip_over_matched_braces_5;{{e97d:2803}}  (+$03)
        cp      $28               ;{{e97f:fe28}}  '('
        ret     nz                ;{{e981:c0}} 

_skip_over_matched_braces_5:      ;{{Addr=$e982 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{e982:0600}} Initialise nesting depth
_skip_over_matched_braces_6:      ;{{Addr=$e984 Code Calls/jump count: 2 Data use count: 0}}
        inc     b                 ;{{e984:04}} 
_skip_over_matched_braces_7:      ;{{Addr=$e985 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_next_tokenised_item;{{e985:cdfde9}} 
        cp      $5b               ;{{e988:fe5b}} '['
        jr      z,_skip_over_matched_braces_6;{{e98a:28f8}}  (-$08) Inc depth
        cp      $28               ;{{e98c:fe28}} '('
        jr      z,_skip_over_matched_braces_6;{{e98e:28f4}}  (-$0c) Inc depth
        cp      $5d               ;{{e990:fe5d}} ']'
        jr      z,_skip_over_matched_braces_19;{{e992:280b}}  (+$0b) Dec depth
        cp      $29               ;{{e994:fe29}} ')'
        jr      z,_skip_over_matched_braces_19;{{e996:2807}}  (+$07) Dec depth

        cp      $02               ;{{e998:fe02}} End of line/statement?
        jr      nc,_skip_over_matched_braces_7;{{e99a:30e9}}  (-$17) No - loop

        jp      Error_Syntax_Error;{{e99c:c349cb}}  Error: Syntax Error (unmatched braces)

_skip_over_matched_braces_19:     ;{{Addr=$e99f Code Calls/jump count: 2 Data use count: 0}}
        djnz    _skip_over_matched_braces_7;{{e99f:10e4}}  (-$1c) Dec depth and loop
        inc     hl                ;{{e9a1:23}} 
        ret                       ;{{e9a2:c9}} 

;;=============================================================================
;;skip to end of statement
;; command DATA
;DATA <list of: <constant>>
;Declares constant data
skip_to_end_of_statement:         ;{{Addr=$e9a3 Code Calls/jump count: 4 Data use count: 1}}
        ld      b,$01             ;{{e9a3:0601}} End of statement token
        jr      skip_to_EOLN_or_token_in_B;{{e9a5:1808}}  (+$08)

;;========================================================================
;; command ' or REM
;REM <rest of line>
;' <rest of line>
;Remark
;Ignores eveything until the end of the line, including colons
;The single quote version is invalid in a DATA statement

command__or_REM:                  ;{{Addr=$e9a7 Code Calls/jump count: 2 Data use count: 2}}
        ld      a,(hl)            ;{{e9a7:7e}} Loop over everything until we hit an end of line ($00) value
        or      a                 ;{{e9a8:b7}} 
        ret     z                 ;{{e9a9:c8}} 
        inc     hl                ;{{e9aa:23}} 
        jr      command__or_REM   ;{{e9ab:18fa}}  (-$06)

;;========================================================================
;; skip to end of line
;;command ELSE
;We arrive at an ELSE because we've just executed the preceding THEN code.

skip_to_end_of_line:              ;{{Addr=$e9ad Code Calls/jump count: 1 Data use count: 1}}
        ld      b,$00             ;{{e9ad:0600}} End of line token

;;=skip to EOLN or token in B
skip_to_EOLN_or_token_in_B:       ;{{Addr=$e9af Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{e9af:2b}} 

_skip_to_eoln_or_token_in_b_1:    ;{{Addr=$e9b0 Code Calls/jump count: 1 Data use count: 0}}
        call    skip_next_tokenised_item;{{e9b0:cdfde9}} 
        or      a                 ;{{e9b3:b7}} 
        ret     z                 ;{{e9b4:c8}} return at end of line

        cp      b                 ;{{e9b5:b8}} check for token
        jr      nz,_skip_to_eoln_or_token_in_b_1;{{e9b6:20f8}}  (-$08) Loop if no match
        ret                       ;{{e9b8:c9}} 

;;===================================================================
;;=statement iterator
;Iterates over every statement and calls the code in BC for each.
;BC=address of subroutine to call.
;The subroutine returns with HL pointing to the end-of-statement or end-of-line marker
statement_iterator:               ;{{Addr=$e9b9 Code Calls/jump count: 4 Data use count: 0}}
        call    get_current_line_address;{{e9b9:cdb1de}} Fetch and preserve current line
        push    hl                ;{{e9bc:e5}} 

        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e9bd:2a64ae}} Address of first line

;Loop for each line
_statement_iterator_3:            ;{{Addr=$e9c0 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e9c0:23}} 
        ld      a,(hl)            ;{{e9c1:7e}} Line length = 0?
        inc     hl                ;{{e9c2:23}} 
        or      (hl)              ;{{e9c3:b6}} 
        jr      z,_statement_iterator_19;{{e9c4:2813}}  (+$13) If so, we're done
        inc     hl                ;{{e9c6:23}} 
        call    set_current_line_address;{{e9c7:cdadde}} 
        inc     hl                ;{{e9ca:23}} 

;Loop for each statement
_statement_iterator_11:           ;{{Addr=$e9cb Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e9cb:c5}} 
        call    JP_BC             ;{{e9cc:cdfcff}}  JP (BC) - execute the code
        pop     bc                ;{{e9cf:c1}} 
        dec     hl                ;{{e9d0:2b}} 
        call    skip_until_ELSE_THEN_or_next_statement;{{e9d1:cdefe9}} Skip to next statment
        or      a                 ;{{e9d4:b7}} 
        jr      nz,_statement_iterator_11;{{e9d5:20f4}}  (-$0c) Not end of line, next statement

        jr      _statement_iterator_3;{{e9d7:18e7}}  (-$19) Otherwise, next line

_statement_iterator_19:           ;{{Addr=$e9d9 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e9d9:e1}} 
        jp      set_current_line_address;{{e9da:c3adde}} 

;;=================================================
;;=skip until ELSE, THEN or next statement or error
;Raises an error if we hit the end of program before any of the above
;C=error code
skip_until_ELSE_THEN_or_next_statement_or_error:;{{Addr=$e9dd Code Calls/jump count: 2 Data use count: 0}}
        call    skip_until_ELSE_THEN_or_next_statement;{{e9dd:cdefe9}} 
        or      a                 ;{{e9e0:b7}} 
        ret     nz                ;{{e9e1:c0}} Non-zero = not end of statement

        inc     hl                ;{{e9e2:23}} 
        ld      a,(hl)            ;{{e9e3:7e}} 
        inc     hl                ;{{e9e4:23}} 
        or      (hl)              ;{{e9e5:b6}} Test for end of program marker (line length zero)
        ld      a,c               ;{{e9e6:79}} Error code
        jp      z,raise_error     ;{{e9e7:ca55cb}} 
        inc     hl                ;{{e9ea:23}} 
        ld      d,h               ;{{e9eb:54}} 
        ld      e,l               ;{{e9ec:5d}} 
        inc     hl                ;{{e9ed:23}} 
        ret                       ;{{e9ee:c9}} 

;;---------------------------------------------
;;=skip until ELSE, THEN or next statement
skip_until_ELSE_THEN_or_next_statement:;{{Addr=$e9ef Code Calls/jump count: 3 Data use count: 0}}
        call    skip_next_tokenised_item;{{e9ef:cdfde9}} 
        cp      $02               ;{{e9f2:fe02}} End of line/end of statement
        ret     c                 ;{{e9f4:d8}} 

        cp      $97               ;{{e9f5:fe97}} ELSE
        ret     z                 ;{{e9f7:c8}} 

        cp      $eb               ;{{e9f8:feeb}} THEN
        jr      nz,skip_until_ELSE_THEN_or_next_statement;{{e9fa:20f3}}  (-$0d) Loop
        ret                       ;{{e9fc:c9}} 

;;==============================================
;;=skip next tokenised item
;Advances over the next tokenised item, 
;including stepping over strings, comments, bar commands etc.
skip_next_tokenised_item:         ;{{Addr=$e9fd Code Calls/jump count: 9 Data use count: 0}}
        call    get_next_token_skipping_space;{{e9fd:cd2cde}}  get next token skipping space
        ret     z                 ;{{ea00:c8}} 

        cp      $0e               ;{{ea01:fe0e}} Tokens $02 to $0d are variables
        jr      c,skip_over_variable;{{ea03:3825}}  (+$25)
        cp      $20               ;{{ea05:fe20}}  space
        jr      c,skip_over_numbers;{{ea07:382b}}  Tokens $0e to $19 are number constants
        cp      $22               ;{{ea09:fe22}}  double quote
        jr      z,skip_over_string;{{ea0b:2811}} 
        cp      $7c               ;{{ea0d:fe7c}} '|'
        jr      z,skip_over_bar_command;{{ea0f:281b}}  (+$1b)
        cp      $c0               ;{{ea11:fec0}} "'" comment
        jr      z,skip_over_comment;{{ea13:2830}}  (+$30)
        cp      $c5               ;{{ea15:fec5}} REM
        jr      z,skip_over_comment;{{ea17:282c}}  (+$2c)
        cp      $ff               ;{{ea19:feff}}  Extended/function tokens
        ret     nz                ;{{ea1b:c0}} 

        inc     hl                ;{{ea1c:23}} 
        ret                       ;{{ea1d:c9}} 

;;----------------------------------------------
;;=skip over string
;Skip until $22 - double quote - or end of line
skip_over_string:                 ;{{Addr=$ea1e Code Calls/jump count: 2 Data use count: 0}}
        inc     hl                ;{{ea1e:23}} 
        ld      a,(hl)            ;{{ea1f:7e}} 
        cp      $22               ;{{ea20:fe22}} '"'
        ret     z                 ;{{ea22:c8}} Done
        or      a                 ;{{ea23:b7}} End of line?
        jr      nz,skip_over_string;{{ea24:20f8}}  (-$08) If not, loop

        dec     hl                ;{{ea26:2b}} Step back to last character of string
        ld      a,$22             ;{{ea27:3e22}} '"' - Return the correct token
        ret                       ;{{ea29:c9}} 

;;----------------------------------------------
;;=skip over variable
skip_over_variable:               ;{{Addr=$ea2a Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea2a:23}} Step over variable (data) pointer
        inc     hl                ;{{ea2b:23}} 

;;=skip over bar command
skip_over_bar_command:            ;{{Addr=$ea2c Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{ea2c:f5}} 

_skip_over_bar_command_1:         ;{{Addr=$ea2d Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea2d:23}} Skip over ASCII7 string - loop until bit 7 set
        ld      a,(hl)            ;{{ea2e:7e}} 
        rla                       ;{{ea2f:17}} 
        jr      nc,_skip_over_bar_command_1;{{ea30:30fb}}  (-$05)

        pop     af                ;{{ea32:f1}} 
        ret                       ;{{ea33:c9}} 

;;--------------------------------------------------
;;=skip over numbers
skip_over_numbers:                ;{{Addr=$ea34 Code Calls/jump count: 1 Data use count: 0}}
        cp      $18               ;{{ea34:fe18}} Tokens $0e to $18 encode numbers 0..10
                                  ;But shouldn't that be CP $19?
        ret     c                 ;{{ea36:d8}} 

        cp      $19               ;{{ea37:fe19}}  token for 8-bit integer decimal value
        jr      z,skip_1_byte_    ;{{ea39:2808}} 
        cp      $1f               ;{{ea3b:fe1f}}  Tokens $1a to $1e are two-byte values. $1f is floating point value
        jr      c,skip_2_bytes_   ;{{ea3d:3803}} 

; skip 5 bytes (length of floating point value representation)
        inc     hl                ;{{ea3f:23}} 
        inc     hl                ;{{ea40:23}} 
        inc     hl                ;{{ea41:23}} 

;;=skip 2 bytes 
;(length of 16-bit values)
;; - 16 bit integer decimal value
;; - 16 bit integer binary value
;; - 16 bit integer hexidecimal value
skip_2_bytes_:                    ;{{Addr=$ea42 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea42:23}} 

;;=skip 1 byte 
;(length of 8-bit values)
skip_1_byte_:                     ;{{Addr=$ea43 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea43:23}} 
        ret                       ;{{ea44:c9}} 
   
;;--------------------------------
;;=skip over comment
skip_over_comment:                ;{{Addr=$ea45 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{ea45:f5}} 
        inc     hl                ;{{ea46:23}} 
        call    command__or_REM   ;{{ea47:cda7e9}}  ' or REM
        pop     af                ;{{ea4a:f1}} 
        dec     hl                ;{{ea4b:2b}} 
        ret                       ;{{ea4c:c9}} 

;;==============================================================
;;=reset variable types and pointers
;Could also be removing links to allocated strings, arrays etc.
;Iterates over program and:
; - resets all variable type tokens to &0d (real)
; - clears the pointer to the variables data &0000
reset_variable_types_and_pointers:;{{Addr=$ea4d Code Calls/jump count: 4 Data use count: 0}}
        push    bc                ;{{ea4d:c5}} 
        push    de                ;{{ea4e:d5}} 
        push    hl                ;{{ea4f:e5}} 
        ld      bc,callback_for_reset_variable_types_and_pointers;{{ea50:015aea}} ##LABEL##
        call    statement_iterator;{{ea53:cdb9e9}} 
        pop     hl                ;{{ea56:e1}} 
        pop     de                ;{{ea57:d1}} 
        pop     bc                ;{{ea58:c1}} 
        ret                       ;{{ea59:c9}} 

;;=callback for reset variable types and pointers
callback_for_reset_variable_types_and_pointers:;{{Addr=$ea5a Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{ea5a:e5}} 
        call    skip_next_tokenised_item;{{ea5b:cdfde9}} 
        pop     de                ;{{ea5e:d1}} 
        cp      $02               ;{{ea5f:fe02}} 
        ret     c                 ;{{ea61:d8}} Exit at end of line or end (&00) of statement (&01)

        cp      $0e               ;{{ea62:fe0e}} Tokens $02 ..$0d are for variables
        jr      nc,callback_for_reset_variable_types_and_pointers;{{ea64:30f4}}  (-$0c) Loop for other tokens

        ex      de,hl             ;{{ea66:eb}} So, token is a variable
        call    get_next_token_skipping_space;{{ea67:cd2cde}}  get next token skipping space
        cp      $0d               ;{{ea6a:fe0d}} 
        jr      c,_callback_for_reset_variable_types_and_pointers_12;{{ea6c:3802}}  (+$02) Skip if token is already $0d (real)
        ld      (hl),$0d          ;{{ea6e:360d}} Otherwise change token to $0d (real)

_callback_for_reset_variable_types_and_pointers_12:;{{Addr=$ea70 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea70:23}} 
        xor     a                 ;{{ea71:af}} 
        ld      (hl),a            ;{{ea72:77}} Next two bytes are the pointer to the data - reset them
        inc     hl                ;{{ea73:23}} 
        ld      (hl),a            ;{{ea74:77}} 
        ex      de,hl             ;{{ea75:eb}} 
        jr      callback_for_reset_variable_types_and_pointers;{{ea76:18e2}}  (-$1e) loop for more





