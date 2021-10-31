;;<< FIND ENDS OF CONTROL LOOPS
;;< Don't have a good phrase for this :(
;;============================

;;=find matching NEXT
;Scan forward from a FOR statement to find the matching NEXT,
;ie. the NEXT with the same loop counter variable, considering that a NEXT 
;can list multiple variables, (or with an implicit control variable)
;Records the 'depth' for FOR..NEXT nesting in the B register - this
;must be zero when we find the matching NEXT.

find_matching_NEXT:               ;{{Addr=$ca76 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ca76:eb}} 
        call    get_current_line_address;{{ca77:cdb1de}} 
        ex      de,hl             ;{{ca7a:eb}} 
        dec     hl                ;{{ca7b:2b}} 
        ld      b,$01             ;{{ca7c:0601}} Nesting depth counter
_find_matching_next_5:            ;{{Addr=$ca7e Code Calls/jump count: 3 Data use count: 0}}
        ld      c,$1a             ;{{ca7e:0e1a}} NEXT missing error
        call    skip_until_ELSE_THEN_or_next_statement_or_error;{{ca80:cddde9}} Skip guff
        push    hl                ;{{ca83:e5}} 
        call    get_next_token_skipping_space;{{ca84:cd2cde}} 
        cp      $b0               ;{{ca87:feb0}} NEXT token
        jr      z,match_within_NEXT;{{ca89:2808}}  (+$08)
        pop     hl                ;{{ca8b:e1}} 

        cp      $9e               ;{{ca8c:fe9e}} FOR token
        jr      nz,_find_matching_next_5;{{ca8e:20ee}}  (-$12) Not a FOR - loop
        inc     b                 ;{{ca90:04}} Found a nested FOR - increase depth and loop
        jr      _find_matching_next_5;{{ca91:18eb}}  (-$15)

;;==============================================
;;=match within NEXT
match_within_NEXT:                ;{{Addr=$ca93 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{ca93:f1}} 
        ex      de,hl             ;{{ca94:eb}} 
        push    hl                ;{{ca95:e5}} 
        call    get_current_line_address;{{ca96:cdb1de}} 
        ex      (sp),hl           ;{{ca99:e3}} 
        call    set_current_line_address;{{ca9a:cdadde}} 
        ex      de,hl             ;{{ca9d:eb}} 
        dec     b                 ;{{ca9e:05}} Dec depth
        jr      z,match_within_NEXT_done;{{ca9f:2824}}  (+$24) Done if zero
        call    get_next_token_skipping_space;{{caa1:cd2cde}}  get next token skipping space
        jr      z,_match_within_next_19;{{caa4:280e}}  (+$0e) No variables specified

_match_within_next_11:            ;{{Addr=$caa6 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{caa6:c5}} NEXT has one or more variable names listed - check them
        push    de                ;{{caa7:d5}} 
        call    prob_parse_and_find_or_create_a_var;{{caa8:cdbfd6}} 
        pop     de                ;{{caab:d1}} 
        pop     bc                ;{{caac:c1}} 
        call    next_token_if_prev_is_comma;{{caad:cd41de}} 
        jr      nc,_match_within_next_19;{{cab0:3002}}  (+$02) End of list - done
        djnz    _match_within_next_11;{{cab2:10f2}}  (-$0e) Loop until nestin depth=0

_match_within_next_19:            ;{{Addr=$cab4 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{cab4:2b}} 
        ld      a,b               ;{{cab5:78}} 
        or      a                 ;{{cab6:b7}} 
        jr      z,match_within_NEXT_done;{{cab7:280c}}  (+$0c) Nesting level zero - done

        ex      de,hl             ;{{cab9:eb}} 
        call    get_current_line_address;{{caba:cdb1de}} 
        ex      (sp),hl           ;{{cabd:e3}} 
        call    set_current_line_address;{{cabe:cdadde}} 
        pop     hl                ;{{cac1:e1}} 
        ex      de,hl             ;{{cac2:eb}} 
        jr      _find_matching_next_5;{{cac3:18b9}}  (-$47) Continue looking for NEXTs

;;=match within NEXT done
match_within_NEXT_done:           ;{{Addr=$cac5 Code Calls/jump count: 2 Data use count: 0}}
        pop     de                ;{{cac5:d1}} 
        jp      get_next_token_skipping_space;{{cac6:c32cde}}  get next token skipping space

;;==============================================
;;=find matching WEND
;Scan forward to find the next WEND, ignoring any intermedtiate WHILE/WEND loops
;It does this with a depth counter in the B register
find_matching_WEND:               ;{{Addr=$cac9 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{cac9:2b}} 
        ex      de,hl             ;{{caca:eb}} 
        call    get_current_line_address;{{cacb:cdb1de}} 
        ex      de,hl             ;{{cace:eb}} 
        ld      b,$00             ;{{cacf:0600}} Init depth counter

_find_matching_wend_5:            ;{{Addr=$cad1 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{cad1:04}} Inc depth counter

_find_matching_wend_6:            ;{{Addr=$cad2 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,$1d             ;{{cad2:0e1d}} WEND missing error
        call    skip_until_ELSE_THEN_or_next_statement_or_error;{{cad4:cddde9}} Find next statement
        push    hl                ;{{cad7:e5}} 
        call    get_next_token_skipping_space;{{cad8:cd2cde}}  get next token skipping space
        pop     hl                ;{{cadb:e1}} 
        cp      $d6               ;{{cadc:fed6}} WHILE token
        jr      z,_find_matching_wend_5;{{cade:28f1}}  (-$0f) Inc depth counter

        cp      $d5               ;{{cae0:fed5}} WEND token
        jr      nz,_find_matching_wend_6;{{cae2:20ee}}  (-$12)
        djnz    _find_matching_wend_6;{{cae4:10ec}}  (-$14) Dec depth counter and loop if non zero

        call    get_next_token_skipping_space;{{cae6:cd2cde}}  get next token skipping space
        jp      get_next_token_skipping_space;{{cae9:c32cde}}  get next token skipping space






