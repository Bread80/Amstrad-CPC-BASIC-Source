;;<< PROGRAM EDITING AND MANIPULATION
;;< DELETE, RENUM, DATA, REM, ', ELSE and
;;< a bunch of related utility stuff
;;=====================================================
;;poss clear program area
poss_clear_program_area:          ;{{Addr=$e761 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{e761:af}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e762:2a64ae}} 
        ld      (hl),a            ;{{e765:77}} 
        inc     hl                ;{{e766:23}} 
        ld      (hl),a            ;{{e767:77}} 
        inc     hl                ;{{e768:23}} 
        ld      (hl),a            ;{{e769:77}} 
        inc     hl                ;{{e76a:23}} 
        ld      (address_after_end_of_program),hl;{{e76b:2266ae}} 
        jr      _convert_all_line_addresses_to_line_numbers_11;{{e76e:1811}}  (+$11)

;;=convert all line addresses to line numbers
;Scoots over every line to convert the line numbers to line addresses
convert_all_line_addresses_to_line_numbers:;{{Addr=$e770 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(line_address_vs_line_number_flag);{{e770:3a21ae}} 
        or      a                 ;{{e773:b7}} 
        ret     z                 ;{{e774:c8}} Abort if we already have line numbers

        push    bc                ;{{e775:c5}} 
        push    de                ;{{e776:d5}} 
        push    hl                ;{{e777:e5}} 
        ld      bc,convert_line_addresses_to_line_numbers;{{e778:0186e7}}  convert line address to line number ##LABEL##
        call    iterator__call_BC_for_each_line;{{e77b:cdb9e9}} Iterator - calls code at BC for every line/statement
        pop     hl                ;{{e77e:e1}} 
        pop     de                ;{{e77f:d1}} 
        pop     bc                ;{{e780:c1}} 
_convert_all_line_addresses_to_line_numbers_11:;{{Addr=$e781 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{e781:af}} 
        ld      (line_address_vs_line_number_flag),a;{{e782:3221ae}} Set flag
        ret                       ;{{e785:c9}} 

;;=================================================
;; convert line addresses to line numbers
;Converts line addresses (pointers) within a statement to line numbers
convert_line_addresses_to_line_numbers:;{{Addr=$e786 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e786:cdfde9}} 
        cp      $02               ;{{e789:fe02}} 
        ret     c                 ;{{e78b:d8}} 

        cp      $1d               ;{{e78c:fe1d}}  16-bit line address pointer
        jr      nz,convert_line_addresses_to_line_numbers;{{e78e:20f6}} 

        ld      d,(hl)            ;{{e790:56}}  get address
        dec     hl                ;{{e791:2b}} 
        ld      e,(hl)            ;{{e792:5e}} 
        dec     hl                ;{{e793:2b}} 
        push    hl                ;{{e794:e5}} 
        ex      de,hl             ;{{e795:eb}} 
        inc     hl                ;{{e796:23}} 
        inc     hl                ;{{e797:23}} 
        inc     hl                ;{{e798:23}} 
        ld      e,(hl)            ;{{e799:5e}}  line number
        inc     hl                ;{{e79a:23}} 
        ld      d,(hl)            ;{{e79b:56}} 
        pop     hl                ;{{e79c:e1}} 
        ld      (hl),$1e          ;{{e79d:361e}}  16-bit line number
        inc     hl                ;{{e79f:23}} 
        ld      (hl),e            ;{{e7a0:73}} 
        inc     hl                ;{{e7a1:23}} 
        ld      (hl),d            ;{{e7a2:72}} 
        jr      convert_line_addresses_to_line_numbers;{{e7a3:18e1}} 

;;-----------------------------------------------------------------
_convert_line_addresses_to_line_numbers_24:;{{Addr=$e7a5 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e7a5:7e}} 
        cp      $20               ;{{e7a6:fe20}} 
        jr      nz,_convert_line_addresses_to_line_numbers_28;{{e7a8:2001}}  (+$01)
        inc     hl                ;{{e7aa:23}} 
_convert_line_addresses_to_line_numbers_28:;{{Addr=$e7ab Code Calls/jump count: 1 Data use count: 0}}
        call    convert_all_line_addresses_to_line_numbers;{{e7ab:cd70e7}}  line address to line number
        call    tokenise_a_BASIC_line;{{e7ae:cda4df}} 
        push    hl                ;{{e7b1:e5}} 
        call    skip_space_tab_or_line_feed;{{e7b2:cd4dde}}  skip space, lf or tab
        or      a                 ;{{e7b5:b7}} 
        jr      z,_convert_line_addresses_to_line_numbers_63;{{e7b6:2828}}  (+$28)
        push    bc                ;{{e7b8:c5}} 
        push    de                ;{{e7b9:d5}} 
        ld      hl,$0004          ;{{e7ba:210400}} 
        add     hl,bc             ;{{e7bd:09}} 
        push    hl                ;{{e7be:e5}} 
        push    hl                ;{{e7bf:e5}} 
        call    find_address_of_line;{{e7c0:cd64e8}} 
        push    hl                ;{{e7c3:e5}} 
        call    c,_convert_line_addresses_to_line_numbers_65;{{e7c4:dce4e7}} 
        pop     de                ;{{e7c7:d1}} 
        pop     bc                ;{{e7c8:c1}} 
        call    unknown_alloc_and_move_memory_up;{{e7c9:cdb8f6}} 
        call    prob_grow_all_program_space_pointers_by_BC;{{e7cc:cd07f6}} 
        ex      de,hl             ;{{e7cf:eb}} 
        pop     de                ;{{e7d0:d1}} 
        ld      (hl),e            ;{{e7d1:73}} 
        inc     hl                ;{{e7d2:23}} 
        ld      (hl),d            ;{{e7d3:72}} 
        inc     hl                ;{{e7d4:23}} 
        pop     de                ;{{e7d5:d1}} 
        ld      (hl),e            ;{{e7d6:73}} 
        inc     hl                ;{{e7d7:23}} 
        ld      (hl),d            ;{{e7d8:72}} 
        inc     hl                ;{{e7d9:23}} 
        pop     bc                ;{{e7da:c1}} 
        ex      de,hl             ;{{e7db:eb}} 
        pop     hl                ;{{e7dc:e1}} 
        ldir                      ;{{e7dd:edb0}} 
        ret                       ;{{e7df:c9}} 

_convert_line_addresses_to_line_numbers_63:;{{Addr=$e7e0 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e7e0:e1}} 
        call    find_address_of_line_or_error;{{e7e1:cd5ce8}} 
_convert_line_addresses_to_line_numbers_65:;{{Addr=$e7e4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{e7e4:78}} 
        or      c                 ;{{e7e5:b1}} 
        ret     z                 ;{{e7e6:c8}} 

        ex      de,hl             ;{{e7e7:eb}} 
        call    move_lower_memory_down;{{e7e8:cde5f6}} 
        jp      prob_grow_all_program_space_pointers_by_BC;{{e7eb:c307f6}} 

;;========================================================================
;; command DELETE

command_DELETE:                   ;{{Addr=$e7ee Code Calls/jump count: 0 Data use count: 1}}
        call    do_DELETE_find_first_line;{{e7ee:cd00e8}} 
        call    syntax_error_if_not_02;{{e7f1:cd37de}} 
        call    _function_instr_70;{{e7f4:cd4dfb}} 
        call    do_DELETE_find_last_line;{{e7f7:cd1ae8}} 
        call    _reset_basic_33   ;{{e7fa:cd8fc1}} 
        jp      REPL_Read_Eval_Print_Loop;{{e7fd:c358c0}} 

;;+do DELETE find first line
do_DELETE_find_first_line:        ;{{Addr=$e800 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_line_number_range_params;{{e800:cd0fcf}} 
        push    hl                ;{{e803:e5}} 
        push    bc                ;{{e804:c5}} 
        call    find_first_line_at_or_after_line_number;{{e805:cd82e8}} 
        pop     de                ;{{e808:d1}} 
        push    hl                ;{{e809:e5}} 
        call    find_address_of_line;{{e80a:cd64e8}} 
        ld      (RAM_ae22),hl     ;{{e80d:2222ae}} 
        ex      de,hl             ;{{e810:eb}} 
        pop     hl                ;{{e811:e1}} 
        or      a                 ;{{e812:b7}} 
        sbc     hl,de             ;{{e813:ed52}} 
        ld      (RAM_ae24),hl     ;{{e815:2224ae}} 
        pop     hl                ;{{e818:e1}} 
        ret                       ;{{e819:c9}} 

;;+do DELETE find last line
do_DELETE_find_last_line:         ;{{Addr=$e81a Code Calls/jump count: 2 Data use count: 0}}
        call    convert_all_line_addresses_to_line_numbers;{{e81a:cd70e7}}  line address to line number
        ld      bc,(RAM_ae24)     ;{{e81d:ed4b24ae}} 
        ld      hl,(RAM_ae22)     ;{{e821:2a22ae}} 
        jp      _convert_line_addresses_to_line_numbers_65;{{e824:c3e4e7}} 

;;=eval and convert line number to line address
;HL pounts to either a line number ($1e) or line address ($1d) token
;If it's a line address, just return it.
;If it's a line number then convert it to a line address, store
;it back in the code and return it.
eval_and_convert_line_number_to_line_address:;{{Addr=$e827 Code Calls/jump count: 7 Data use count: 0}}
        inc     hl                ;{{e827:23}} 
        ld      e,(hl)            ;{{e828:5e}} 
        inc     hl                ;{{e829:23}} 
        ld      d,(hl)            ;{{e82a:56}} 
        cp      $1d               ;{{e82b:fe1d}}  16-bit line address pointer
        jr      z,_eval_and_convert_line_number_to_line_address_31;{{e82d:282a}}  (+$2a) already a pointer so skip to end
        cp      $1e               ;{{e82f:fe1e}}  16-bit line number
        jp      nz,Error_Syntax_Error;{{e831:c249cb}}  Error: Syntax Error

        push    hl                ;{{e834:e5}} 
        call    get_current_line_number;{{e835:cdb5de}} Compare target line number to current??
        call    c,compare_HL_DE   ;{{e838:dcd8ff}}  HL=DE? Carry = we have current line
        jr      nc,_eval_and_convert_line_number_to_line_address_18;{{e83b:300a}}  (+$0a)

        pop     hl                ;{{e83d:e1}} If target line after current then scan to next line and scan from there?
        push    hl                ;{{e83e:e5}} 
        inc     hl                ;{{e83f:23}} 
        call    skip_to_end_of_line;{{e840:cdade9}} ; ELSE - scans to next statement ignoring nested IFs??
        inc     hl                ;{{e843:23}} 
        call    find_address_of_line_from_current;{{e844:cd68e8}} 

_eval_and_convert_line_number_to_line_address_18:;{{Addr=$e847 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,find_address_of_line_or_error;{{e847:d45ce8}} Scan from the start
        dec     hl                ;{{e84a:2b}} 
        ex      de,hl             ;{{e84b:eb}} 
        pop     hl                ;{{e84c:e1}} 
        dec     hl                ;{{e84d:2b}} 
        dec     hl                ;{{e84e:2b}} 

                                  ;write line address and suitable token
        ld      a,$1d             ;{{e84f:3e1d}}  16-bit line address pointer
        ld      (line_address_vs_line_number_flag),a;{{e851:3221ae}} 
        ld      (hl),a            ;{{e854:77}} 
        inc     hl                ;{{e855:23}} 
        ld      (hl),e            ;{{e856:73}} 
        inc     hl                ;{{e857:23}} 
        ld      (hl),d            ;{{e858:72}} 

_eval_and_convert_line_number_to_line_address_31:;{{Addr=$e859 Code Calls/jump count: 1 Data use count: 0}}
        jp      get_next_token_skipping_space;{{e859:c32cde}}  get next token skipping space

;;==================================
;;find address of line or error
find_address_of_line_or_error:    ;{{Addr=$e85c Code Calls/jump count: 6 Data use count: 0}}
        call    find_address_of_line;{{e85c:cd64e8}} 
        ret     c                 ;{{e85f:d8}} 

        call    byte_following_call_is_error_code;{{e860:cd45cb}} 
        defb $08                  ;Inline error code: "Line does not exist"

;;====================================
;;find address of line
;;BC=line number
find_address_of_line:             ;{{Addr=$e864 Code Calls/jump count: 9 Data use count: 0}}
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e864:2a64ae}} 
        inc     hl                ;{{e867:23}} 
;;=find address of line from current
;Scan forward starting at current
find_address_of_line_from_current:;{{Addr=$e868 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,(hl)            ;{{e868:4e}} 
        inc     hl                ;{{e869:23}} 
        ld      b,(hl)            ;{{e86a:46}} 
        dec     hl                ;{{e86b:2b}} 
        ld      a,b               ;{{e86c:78}} 
        or      c                 ;{{e86d:b1}} 
        ret     z                 ;{{e86e:c8}} 

        push    hl                ;{{e86f:e5}} 
        inc     hl                ;{{e870:23}} 
        inc     hl                ;{{e871:23}} 
        ld      a,(hl)            ;{{e872:7e}} 
        inc     hl                ;{{e873:23}} 
        ld      h,(hl)            ;{{e874:66}} 
        ld      l,a               ;{{e875:6f}} 
        ex      de,hl             ;{{e876:eb}} 
        call    compare_HL_DE     ;{{e877:cdd8ff}}  HL=DE?
        ex      de,hl             ;{{e87a:eb}} 
        pop     hl                ;{{e87b:e1}} 
        ccf                       ;{{e87c:3f}} 
        ret     nc                ;{{e87d:d0}} 

        ret     z                 ;{{e87e:c8}} 

        add     hl,bc             ;{{e87f:09}} 
        jr      find_address_of_line_from_current;{{e880:18e6}}  (-$1a)

;;======================================
;;find first line at or after line number
;;BC=line number
find_first_line_at_or_after_line_number:;{{Addr=$e882 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e882:2a64ae}} 
        inc     hl                ;{{e885:23}} 
_find_first_line_at_or_after_line_number_2:;{{Addr=$e886 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e886:e5}} 
        ld      c,(hl)            ;{{e887:4e}} 
        inc     hl                ;{{e888:23}} 
        ld      b,(hl)            ;{{e889:46}} 
        inc     hl                ;{{e88a:23}} 
        ld      a,b               ;{{e88b:78}} 
        or      c                 ;{{e88c:b1}} 
        scf                       ;{{e88d:37}} 
        jr      z,_find_first_line_at_or_after_line_number_18;{{e88e:2809}}  (+$09)
        ld      a,(hl)            ;{{e890:7e}} 
        inc     hl                ;{{e891:23}} 
        ld      h,(hl)            ;{{e892:66}} 
        ld      l,a               ;{{e893:6f}} 
        ex      de,hl             ;{{e894:eb}} 
        call    compare_HL_DE     ;{{e895:cdd8ff}}  HL=DE?
        ex      de,hl             ;{{e898:eb}} 
_find_first_line_at_or_after_line_number_18:;{{Addr=$e899 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e899:e1}} 
        ret     c                 ;{{e89a:d8}} 

        add     hl,bc             ;{{e89b:09}} 
        jr      _find_first_line_at_or_after_line_number_2;{{e89c:18e8}}  (-$18)

;;========================================================================
;; command RENUM

command_RENUM:                    ;{{Addr=$e89e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$000a          ;{{e89e:110a00}} 
        call    nz,_command_renum_82;{{e8a1:c41ae9}} 
        push    de                ;{{e8a4:d5}} 
        ld      de,RESET_ENTRY    ;{{e8a5:110000}} 
        call    next_token_if_prev_is_comma;{{e8a8:cd41de}} 
        call    c,_command_renum_82;{{e8ab:dc1ae9}} 
        push    de                ;{{e8ae:d5}} 
        ld      de,$000a          ;{{e8af:110a00}} 
        call    next_token_if_prev_is_comma;{{e8b2:cd41de}} 
        call    c,eval_line_number_or_error;{{e8b5:dc48cf}} 
        call    syntax_error_if_not_02;{{e8b8:cd37de}} 
        pop     hl                ;{{e8bb:e1}} 
        ex      de,hl             ;{{e8bc:eb}} 
        ex      (sp),hl           ;{{e8bd:e3}} 
        ex      de,hl             ;{{e8be:eb}} 
        push    de                ;{{e8bf:d5}} 
        push    hl                ;{{e8c0:e5}} 
        call    find_address_of_line;{{e8c1:cd64e8}}  find address of line
        pop     de                ;{{e8c4:d1}} 
        push    hl                ;{{e8c5:e5}} 
        call    find_address_of_line;{{e8c6:cd64e8}}  find address of line
        ex      de,hl             ;{{e8c9:eb}} 
        pop     hl                ;{{e8ca:e1}} 
        call    compare_HL_DE     ;{{e8cb:cdd8ff}}  HL=DE?
        jr      c,_command_renum_51;{{e8ce:381d}}  (+$1d)
        ex      de,hl             ;{{e8d0:eb}} 
        pop     de                ;{{e8d1:d1}} 
        pop     bc                ;{{e8d2:c1}} 
        push    de                ;{{e8d3:d5}} 
        push    hl                ;{{e8d4:e5}} 
_command_renum_30:                ;{{Addr=$e8d5 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e8d5:c5}} 
        ld      c,(hl)            ;{{e8d6:4e}} 
        inc     hl                ;{{e8d7:23}} 
        ld      b,(hl)            ;{{e8d8:46}} 
        ld      a,b               ;{{e8d9:78}} 
        or      c                 ;{{e8da:b1}} 
        jr      z,_command_renum_52;{{e8db:2813}}  (+$13)
        dec     hl                ;{{e8dd:2b}} 
        add     hl,bc             ;{{e8de:09}} 
        ld      a,(hl)            ;{{e8df:7e}} 
        inc     hl                ;{{e8e0:23}} 
        or      (hl)              ;{{e8e1:b6}} 
        jr      z,_command_renum_52;{{e8e2:280c}}  (+$0c)
        dec     hl                ;{{e8e4:2b}} 
        pop     bc                ;{{e8e5:c1}} 
        push    hl                ;{{e8e6:e5}} 
        ex      de,hl             ;{{e8e7:eb}} 
        add     hl,bc             ;{{e8e8:09}} 
        ex      de,hl             ;{{e8e9:eb}} 
        pop     hl                ;{{e8ea:e1}} 
        jr      nc,_command_renum_30;{{e8eb:30e8}}  (-$18)
_command_renum_51:                ;{{Addr=$e8ed Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{e8ed:c34dcb}}  Error: Improper Argument

_command_renum_52:                ;{{Addr=$e8f0 Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,convert_line_numbers_to_line_addresses_callback;{{e8f0:0120e9}}  line number to line address  ##LABEL##
        call    iterator__call_BC_for_each_line;{{e8f3:cdb9e9}} 
        pop     bc                ;{{e8f6:c1}} 
        pop     hl                ;{{e8f7:e1}} 
        pop     de                ;{{e8f8:d1}} 
_command_renum_57:                ;{{Addr=$e8f9 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e8f9:c5}} 
        push    hl                ;{{e8fa:e5}} 
        ld      c,(hl)            ;{{e8fb:4e}} 
        inc     hl                ;{{e8fc:23}} 
        ld      b,(hl)            ;{{e8fd:46}} 
        inc     hl                ;{{e8fe:23}} 
        ld      a,b               ;{{e8ff:78}} 
        or      c                 ;{{e900:b1}} 
        jr      z,_command_renum_77;{{e901:280c}}  (+$0c)
        ld      (hl),e            ;{{e903:73}} 
        inc     hl                ;{{e904:23}} 
        ld      (hl),d            ;{{e905:72}} 
        inc     hl                ;{{e906:23}} 
        pop     hl                ;{{e907:e1}} 
        add     hl,bc             ;{{e908:09}} 
        pop     bc                ;{{e909:c1}} 
        ex      de,hl             ;{{e90a:eb}} 
        add     hl,bc             ;{{e90b:09}} 
        ex      de,hl             ;{{e90c:eb}} 
        jr      _command_renum_57 ;{{e90d:18ea}}  (-$16)

_command_renum_77:                ;{{Addr=$e90f Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e90f:e1}} 
        pop     hl                ;{{e910:e1}} 
        ld      bc,_convert_line_numbers_to_line_addresses_callback_24;{{e911:0144e9}} ##LABEL##
        call    iterator__call_BC_for_each_line;{{e914:cdb9e9}} 
        jp      REPL_Read_Eval_Print_Loop;{{e917:c358c0}} 

_command_renum_82:                ;{{Addr=$e91a Code Calls/jump count: 2 Data use count: 0}}
        cp      $2c               ;{{e91a:fe2c}} 
        call    nz,eval_line_number_or_error;{{e91c:c448cf}} 
        ret                       ;{{e91f:c9}} 

;;----------------------------------------------------------
;;=convert line numbers to line addresses callback
;Converts line numbers within a statement to line addresses
convert_line_numbers_to_line_addresses_callback:;{{Addr=$e920 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e920:cdfde9}} 
        cp      $02               ;{{e923:fe02}} 
        ret     c                 ;{{e925:d8}} 

;; convert line number to line address

        cp      $1e               ;{{e926:fe1e}}  16-bit line number
        jr      nz,convert_line_numbers_to_line_addresses_callback;{{e928:20f6}} 

;; 16-bit line number
        push    hl                ;{{e92a:e5}} 
        ld      d,(hl)            ;{{e92b:56}} 
        dec     hl                ;{{e92c:2b}} 
        ld      e,(hl)            ;{{e92d:5e}} 
        call    find_address_of_line;{{e92e:cd64e8}}  find address of line
        jr      nc,_convert_line_numbers_to_line_addresses_callback_22;{{e931:300e}} 
        dec     hl                ;{{e933:2b}} 
        ex      de,hl             ;{{e934:eb}} 
        pop     hl                ;{{e935:e1}} 
        push    hl                ;{{e936:e5}} 

;; store 16-bit line address in reverse order
        ld      (hl),d            ;{{e937:72}} 
        dec     hl                ;{{e938:2b}} 
        ld      (hl),e            ;{{e939:73}} 
        dec     hl                ;{{e93a:2b}} 
;; store 16-bit line address marker
        ld      a,$1d             ;{{e93b:3e1d}}  16 bit line address pointer
        ld      (hl),a            ;{{e93d:77}} 

        ld      (line_address_vs_line_number_flag),a;{{e93e:3221ae}} 

_convert_line_numbers_to_line_addresses_callback_22:;{{Addr=$e941 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e941:e1}} 
        jr      convert_line_numbers_to_line_addresses_callback;{{e942:18dc}} 

;;-------------------------------------------------------
;;poss validate line number targets??
;Works on every line number found within a statement
_convert_line_numbers_to_line_addresses_callback_24:;{{Addr=$e944 Code Calls/jump count: 2 Data use count: 1}}
        call    skip_next_tokenised_item;{{e944:cdfde9}} 
        cp      $02               ;{{e947:fe02}} 
        ret     c                 ;{{e949:d8}} 

;; 16-bit line number?
        cp      $1e               ;{{e94a:fe1e}} 
        jr      nz,_convert_line_numbers_to_line_addresses_callback_24;{{e94c:20f6}}  (-$0a)

        push    hl                ;{{e94e:e5}} 
        ld      d,(hl)            ;{{e94f:56}} 
        dec     hl                ;{{e950:2b}} 
        ld      e,(hl)            ;{{e951:5e}} 
        call    get_current_line_number;{{e952:cdb5de}} 
        call    undefined_line_n_in_n_error;{{e955:cde6cb}} 
        pop     hl                ;{{e958:e1}} 
        jr      _convert_line_numbers_to_line_addresses_callback_24;{{e959:18e9}}  (-$17)

;;=skip to ELSE statement
;Skip tokens with a line until the matching ELSE statement.
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

;;=skip over batched braces
skip_over_batched_braces:         ;{{Addr=$e97a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e97a:7e}} 
        cp      $5b               ;{{e97b:fe5b}}  '['
        jr      z,_skip_over_batched_braces_5;{{e97d:2803}}  (+$03)
        cp      $28               ;{{e97f:fe28}}  '('
        ret     nz                ;{{e981:c0}} 

_skip_over_batched_braces_5:      ;{{Addr=$e982 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{e982:0600}} 
_skip_over_batched_braces_6:      ;{{Addr=$e984 Code Calls/jump count: 2 Data use count: 0}}
        inc     b                 ;{{e984:04}} 
_skip_over_batched_braces_7:      ;{{Addr=$e985 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_next_tokenised_item;{{e985:cdfde9}} 
        cp      $5b               ;{{e988:fe5b}} '['
        jr      z,_skip_over_batched_braces_6;{{e98a:28f8}}  (-$08)
        cp      $28               ;{{e98c:fe28}} '('
        jr      z,_skip_over_batched_braces_6;{{e98e:28f4}}  (-$0c)
        cp      $5d               ;{{e990:fe5d}} ']'
        jr      z,_skip_over_batched_braces_19;{{e992:280b}}  (+$0b)
        cp      $29               ;{{e994:fe29}} ')'
        jr      z,_skip_over_batched_braces_19;{{e996:2807}}  (+$07)
        cp      $02               ;{{e998:fe02}} 
        jr      nc,_skip_over_batched_braces_7;{{e99a:30e9}}  (-$17)
        jp      Error_Syntax_Error;{{e99c:c349cb}}  Error: Syntax Error

_skip_over_batched_braces_19:     ;{{Addr=$e99f Code Calls/jump count: 2 Data use count: 0}}
        djnz    _skip_over_batched_braces_7;{{e99f:10e4}}  (-$1c)
        inc     hl                ;{{e9a1:23}} 
        ret                       ;{{e9a2:c9}} 





;;=============================================================================
;;skip to end of statement
;; command DATA
skip_to_end_of_statement:         ;{{Addr=$e9a3 Code Calls/jump count: 4 Data use count: 1}}
        ld      b,$01             ;{{e9a3:0601}} 
        jr      skip_to_EOLN_or_token_B;{{e9a5:1808}}  (+$08)

;;========================================================================
;; command ' or REM
command__or_REM:                  ;{{Addr=$e9a7 Code Calls/jump count: 2 Data use count: 2}}
        ld      a,(hl)            ;{{e9a7:7e}} 
        or      a                 ;{{e9a8:b7}} 
        ret     z                 ;{{e9a9:c8}} 
        inc     hl                ;{{e9aa:23}} 
        jr      command__or_REM   ;{{e9ab:18fa}}  (-$06)

;;========================================================================
;; skip to end of line
;;command ELSE
;We arrive at an ELSE because we've just executed the preceding THEN code.

skip_to_end_of_line:              ;{{Addr=$e9ad Code Calls/jump count: 1 Data use count: 1}}
        ld      b,$00             ;{{e9ad:0600}} 
;;=skip to EOLN or token B
skip_to_EOLN_or_token_B:          ;{{Addr=$e9af Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{e9af:2b}} 
_skip_to_eoln_or_token_b_1:       ;{{Addr=$e9b0 Code Calls/jump count: 1 Data use count: 0}}
        call    skip_next_tokenised_item;{{e9b0:cdfde9}} 
        or      a                 ;{{e9b3:b7}} 
        ret     z                 ;{{e9b4:c8}} return at end of line

        cp      b                 ;{{e9b5:b8}} check for koen
        jr      nz,_skip_to_eoln_or_token_b_1;{{e9b6:20f8}}  (-$08) keep going if no match
        ret                       ;{{e9b8:c9}} 

;;=iterator - call BC for each line
;Iterates over every line/statement (not totally sure)
;and calls the code in BC for each.
;;Takes a code address to call in BC
iterator__call_BC_for_each_line:  ;{{Addr=$e9b9 Code Calls/jump count: 4 Data use count: 0}}
        call    get_current_line_address;{{e9b9:cdb1de}} 
        push    hl                ;{{e9bc:e5}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{e9bd:2a64ae}} 
_iterator__call_bc_for_each_line_3:;{{Addr=$e9c0 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e9c0:23}} 
        ld      a,(hl)            ;{{e9c1:7e}} 
        inc     hl                ;{{e9c2:23}} 
        or      (hl)              ;{{e9c3:b6}} 
        jr      z,_iterator__call_bc_for_each_line_19;{{e9c4:2813}}  (+$13)
        inc     hl                ;{{e9c6:23}} 
        call    set_current_line_address;{{e9c7:cdadde}} 
        inc     hl                ;{{e9ca:23}} 
_iterator__call_bc_for_each_line_11:;{{Addr=$e9cb Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e9cb:c5}} 
        call    JP_BC             ;{{e9cc:cdfcff}}  JP (BC)
        pop     bc                ;{{e9cf:c1}} 
        dec     hl                ;{{e9d0:2b}} 
        call    skip_until_ELSE_THEN_or_next_statement;{{e9d1:cdefe9}} 
        or      a                 ;{{e9d4:b7}} 
        jr      nz,_iterator__call_bc_for_each_line_11;{{e9d5:20f4}}  (-$0c)
        jr      _iterator__call_bc_for_each_line_3;{{e9d7:18e7}}  (-$19)

_iterator__call_bc_for_each_line_19:;{{Addr=$e9d9 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e9d9:e1}} 
        jp      set_current_line_address;{{e9da:c3adde}} 

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
        or      (hl)              ;{{e9e5:b6}} Test for end of program marker (line number zero)
        ld      a,c               ;{{e9e6:79}} Error code
        jp      z,raise_error     ;{{e9e7:ca55cb}} 
        inc     hl                ;{{e9ea:23}} 
        ld      d,h               ;{{e9eb:54}} 
        ld      e,l               ;{{e9ec:5d}} 
        inc     hl                ;{{e9ed:23}} 
        ret                       ;{{e9ee:c9}} 

;;=skip until ELSE, THEN or next statement
skip_until_ELSE_THEN_or_next_statement:;{{Addr=$e9ef Code Calls/jump count: 3 Data use count: 0}}
        call    skip_next_tokenised_item;{{e9ef:cdfde9}} 
        cp      $02               ;{{e9f2:fe02}} 
        ret     c                 ;{{e9f4:d8}} 

        cp      $97               ;{{e9f5:fe97}} ELSE
        ret     z                 ;{{e9f7:c8}} 

        cp      $eb               ;{{e9f8:feeb}} THEN
        jr      nz,skip_until_ELSE_THEN_or_next_statement;{{e9fa:20f3}}  (-$0d)
        ret                       ;{{e9fc:c9}} 

;;=skip next tokenised item
;Advances over the next tokenised item, 
;including stepping over strings, comments, bar commands etc.
skip_next_tokenised_item:         ;{{Addr=$e9fd Code Calls/jump count: 9 Data use count: 0}}
        call    get_next_token_skipping_space;{{e9fd:cd2cde}}  get next token skipping space
        ret     z                 ;{{ea00:c8}} 

        cp      $0e               ;{{ea01:fe0e}} 
        jr      c,skip_until_bit7_set;{{ea03:3825}}  (+$25)
        cp      $20               ;{{ea05:fe20}}  space
        jr      c,skip_over_numbers;{{ea07:382b}}  
        cp      $22               ;{{ea09:fe22}}  double quote
        jr      z,skip_over_string;{{ea0b:2811}}  
        cp      $7c               ;{{ea0d:fe7c}} '|'
        jr      z,skip_over_bar_command;{{ea0f:281b}}  (+$1b)
        cp      $c0               ;{{ea11:fec0}} "'" comment
        jr      z,skip_over_comment;{{ea13:2830}}  (+$30)
        cp      $c5               ;{{ea15:fec5}} REM
        jr      z,skip_over_comment;{{ea17:282c}}  (+$2c)
        cp      $ff               ;{{ea19:feff}} 
        ret     nz                ;{{ea1b:c0}} 

        inc     hl                ;{{ea1c:23}} 
        ret                       ;{{ea1d:c9}} 

;;----------------------------------------------
;;=skip over string

skip_over_string:                 ;{{Addr=$ea1e Code Calls/jump count: 2 Data use count: 0}}
        inc     hl                ;{{ea1e:23}} 
        ld      a,(hl)            ;{{ea1f:7e}} 
        cp      $22               ;{{ea20:fe22}} '"'
        ret     z                 ;{{ea22:c8}} 
        or      a                 ;{{ea23:b7}} 
        jr      nz,skip_over_string;{{ea24:20f8}}  (-$08)

        dec     hl                ;{{ea26:2b}} 
        ld      a,$22             ;{{ea27:3e22}} '"'
        ret                       ;{{ea29:c9}} 

;;----------------------------------------------
;;=skip until bit7 set
skip_until_bit7_set:              ;{{Addr=$ea2a Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea2a:23}} 
        inc     hl                ;{{ea2b:23}} 
;;=skip over bar command
skip_over_bar_command:            ;{{Addr=$ea2c Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{ea2c:f5}} 
_skip_over_bar_command_1:         ;{{Addr=$ea2d Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea2d:23}} 
        ld      a,(hl)            ;{{ea2e:7e}} 
        rla                       ;{{ea2f:17}} 
        jr      nc,_skip_over_bar_command_1;{{ea30:30fb}}  (-$05)
        pop     af                ;{{ea32:f1}} 
        ret                       ;{{ea33:c9}} 

;;--------------------------------------------------
;;=skip over numbers
skip_over_numbers:                ;{{Addr=$ea34 Code Calls/jump count: 1 Data use count: 0}}
        cp      $18               ;{{ea34:fe18}} 
        ret     c                 ;{{ea36:d8}} 

        cp      $19               ;{{ea37:fe19}}  8-bit integer decimal value
        jr      z,skip_1_byte_    ;{{ea39:2808}} 
        cp      $1f               ;{{ea3b:fe1f}}  floating point value
        jr      c,skip_2_bytes_   ;{{ea3d:3803}} 

;; skip 5 bytes
; (length of floating point value representation)
        inc     hl                ;{{ea3f:23}} 
        inc     hl                ;{{ea40:23}} 
        inc     hl                ;{{ea41:23}} 

;;--------------------------------
;;=skip 2 bytes 
;(length of 16-bit values)
;; - 16 bit integer decimal value
;; - 16 bit integer binary value
;; - 16 bit integer hexidecimal value
skip_2_bytes_:                    ;{{Addr=$ea42 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea42:23}} 
;;--------------------------------
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

;;=reset variable types and pointers
;Could also be removing links to allocated strings, arrays etc.
;Iterates over program and resets all variable type tokens to &0d (real)
;and two bytes after word pointer after to &0000 (ptr to variable data)
reset_variable_types_and_pointers:;{{Addr=$ea4d Code Calls/jump count: 4 Data use count: 0}}
        push    bc                ;{{ea4d:c5}} 
        push    de                ;{{ea4e:d5}} 
        push    hl                ;{{ea4f:e5}} 
        ld      bc,callback_for_reset_variable_types_and_pointers;{{ea50:015aea}} ##LABEL##
        call    iterator__call_BC_for_each_line;{{ea53:cdb9e9}} 
        pop     hl                ;{{ea56:e1}} 
        pop     de                ;{{ea57:d1}} 
        pop     bc                ;{{ea58:c1}} 
        ret                       ;{{ea59:c9}} 

;;=callback for reset variable types and pointers
callback_for_reset_variable_types_and_pointers:;{{Addr=$ea5a Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{ea5a:e5}} 
        call    skip_next_tokenised_item;{{ea5b:cdfde9}} 
        pop     de                ;{{ea5e:d1}} 
        cp      $02               ;{{ea5f:fe02}} Tokens $02 ..$0d are for variables
        ret     c                 ;{{ea61:d8}} Exit at end of line or end (&00) of statement (&01)

        cp      $0e               ;{{ea62:fe0e}} 
        jr      nc,callback_for_reset_variable_types_and_pointers;{{ea64:30f4}}  (-$0c) Loop for values > &0e

        ex      de,hl             ;{{ea66:eb}} So, token is a variable
        call    get_next_token_skipping_space;{{ea67:cd2cde}}  get next token skipping space
        cp      $0d               ;{{ea6a:fe0d}} 
        jr      c,_callback_for_reset_variable_types_and_pointers_12;{{ea6c:3802}}  (+$02) Skip changing token for $0d and higher
        ld      (hl),$0d          ;{{ea6e:360d}} So we change tokens $02..$0c to $0d??
_callback_for_reset_variable_types_and_pointers_12:;{{Addr=$ea70 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ea70:23}} 
        xor     a                 ;{{ea71:af}} Then zero the two bytes after
        ld      (hl),a            ;{{ea72:77}} 
        inc     hl                ;{{ea73:23}} 
        ld      (hl),a            ;{{ea74:77}} 
        ex      de,hl             ;{{ea75:eb}} 
        jr      callback_for_reset_variable_types_and_pointers;{{ea76:18e2}}  (-$1e) loop for more




