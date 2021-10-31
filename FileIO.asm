;;<< FILE I/O COMMANDS
;;< CAT, OPENIN, OPENOUT, CLOSEIN, CLOSEOUT
;;=============================================================================
;; command CAT
command_CAT:                      ;{{Addr=$d296 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{d296:c0}} 
        push    hl                ;{{d297:e5}} 
        call    close_input_and_output_streams;{{d298:cd00d3}} 
        call    prob_alloc_2k_file_buffer_C;{{d29b:cd2af7}} alloc 2k buffer??
        call    CAS_CATALOG       ;{{d29e:cd9bbc}}  firmware function: cas catalog
        jp      z,raise_file_not_open_error_C;{{d2a1:ca37cc}} 
        pop     hl                ;{{d2a4:e1}} 
        jp      prob_release_2k_file_buffer_C;{{d2a5:c361f7}} release 2k buffer??

;;=============================================================================
;; command OPENOUT

command_OPENOUT:                  ;{{Addr=$d2a8 Code Calls/jump count: 1 Data use count: 1}}
        call    read_filename     ;{{d2a8:cdc7d2}} 
        call    prob_alloc_2k_file_buffer_B;{{d2ab:cd25f7}} 
        call    set_file_output_stream_line_pos_to_1;{{d2ae:cd69c4}} 
        jp      CAS_OUT_OPEN      ;{{d2b1:c38cbc}}  firmware function: cas out open

;;=============================================================================
;; command OPENIN

command_OPENIN:                   ;{{Addr=$d2b4 Code Calls/jump count: 0 Data use count: 1}}
        call    read_filename_and_open_in;{{d2b4:cdbed2}} 
        cp      $16               ;{{d2b7:fe16}} 
        ret     z                 ;{{d2b9:c8}} 

        call    byte_following_call_is_error_code;{{d2ba:cd45cb}} 
        defb $19                  ;Inline error code: File type error

;;=read filename and open in
read_filename_and_open_in:        ;{{Addr=$d2be Code Calls/jump count: 2 Data use count: 0}}
        call    read_filename     ;{{d2be:cdc7d2}} 
        call    prob_alloc_2k_file_buffer;{{d2c1:cd20f7}} 
        jp      CAS_IN_OPEN       ;{{d2c4:c377bc}}  firmware function: cas in open

;;=read filename
read_filename:                    ;{{Addr=$d2c7 Code Calls/jump count: 2 Data use count: 0}}
        call    prob_alloc_2k_file_buffer_C;{{d2c7:cd2af7}} 
        call    eval_expr_as_string_and_get_length;{{d2ca:cd03cf}} 
        ex      (sp),hl           ;{{d2cd:e3}} 
        ex      de,hl             ;{{d2ce:eb}} 
        call    set_CAS_NOISY     ;{{d2cf:cddbd2}} 
        jp      z,raise_file_not_open_error_C;{{d2d2:ca37cc}} 
        pop     hl                ;{{d2d5:e1}} 
        ret     c                 ;{{d2d6:d8}} 

        call    byte_following_call_is_error_code;{{d2d7:cd45cb}} 
        defb $1b                  ;Inline error code: File already open

;;=set CAS NOISY
set_CAS_NOISY:                    ;{{Addr=$d2db Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{d2db:d5}} 
        ld      a,b               ;{{d2dc:78}} 
        or      a                 ;{{d2dd:b7}} 
        jr      z,_set_cas_noisy_11;{{d2de:280a}}  (+$0a)
        ld      a,(hl)            ;{{d2e0:7e}} 
        cp      $21               ;{{d2e1:fe21}}  "!" character?
        ld      a,$00             ;{{d2e3:3e00}} 
        jr      nz,_set_cas_noisy_11;{{d2e5:2003}}  (+$03)
        inc     hl                ;{{d2e7:23}} 
        dec     b                 ;{{d2e8:05}} 
        cpl                       ;{{d2e9:2f}} 
_set_cas_noisy_11:                ;{{Addr=$d2ea Code Calls/jump count: 2 Data use count: 0}}
        jp      CAS_NOISY         ;{{d2ea:c36bbc}}  firmware function: cas set noisy

;;==========================================================================
;; command CLOSEIN

command_CLOSEIN:                  ;{{Addr=$d2ed Code Calls/jump count: 3 Data use count: 1}}
        push    hl                ;{{d2ed:e5}} 
        call    CAS_IN_CLOSE      ;{{d2ee:cd7abc}}  firmware function: cas in close
        pop     hl                ;{{d2f1:e1}} 
        jp      prob_release_2k_file_buffer;{{d2f2:c359f7}} 

;;==========================================================================
;; command CLOSEOUT

command_CLOSEOUT:                 ;{{Addr=$d2f5 Code Calls/jump count: 2 Data use count: 1}}
        push    hl                ;{{d2f5:e5}} 
        call    CAS_OUT_CLOSE     ;{{d2f6:cd8fbc}}  firmware function: cas out close
        jp      z,raise_file_not_open_error_C;{{d2f9:ca37cc}} 
        pop     hl                ;{{d2fc:e1}} 
        jp      prob_release_2k_file_buffer_B;{{d2fd:c35df7}} 

;;==========================================================================
;;close input and output streams
close_input_and_output_streams:   ;{{Addr=$d300 Code Calls/jump count: 6 Data use count: 0}}
        push    bc                ;{{d300:c5}} 
        push    de                ;{{d301:d5}} 
        push    hl                ;{{d302:e5}} 
        call    CAS_IN_ABANDON    ;{{d303:cd7dbc}}  firmware function: cas in abandon
        call    prob_release_2k_file_buffer;{{d306:cd59f7}} 
        call    CAS_OUT_ABANDON   ;{{d309:cd92bc}}  firmware function: cas out abandon
        call    prob_release_2k_file_buffer_B;{{d30c:cd5df7}} 
        pop     hl                ;{{d30f:e1}} 
        pop     de                ;{{d310:d1}} 
        pop     bc                ;{{d311:c1}} 
        ret                       ;{{d312:c9}} 




