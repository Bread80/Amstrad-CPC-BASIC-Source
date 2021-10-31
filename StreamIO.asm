;;<< STREAM I/O
;;< Low level I/O via streams, WIDTH and EOF
;;=====================================================

;; init streams and display ASCIIZ string

init_streams_and_display_ASCIIZ_string:;{{Addr=$c37d Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c37d:e5}} 
        ld      hl,$8401          ;{{c37e:210184}} 
        ld      (printer_stream_current_x_position_),hl;{{c381:2208ac}} 
        call    set_file_output_stream_line_pos_to_1;{{c384:cd69c4}} 
        call    select_txt_stream_zero;{{c387:cda1c1}} 
        pop     hl                ;{{c38a:e1}} 

;;+----------------------------------------------------
;;output ASCIIZ string
output_ASCIIZ_string:             ;{{Addr=$c38b Code Calls/jump count: 7 Data use count: 0}}
        push    af                ;{{c38b:f5}} 
        push    hl                ;{{c38c:e5}} 
_output_asciiz_string_2:          ;{{Addr=$c38d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{c38d:7e}}  get character
        inc     hl                ;{{c38e:23}} 
        or      a                 ;{{c38f:b7}} 
        call    nz,output_char    ;{{c390:c4a0c3}} ; display text char
        jr      nz,_output_asciiz_string_2;{{c393:20f8}}  (-$08)

        pop     hl                ;{{c395:e1}} 
        pop     af                ;{{c396:f1}} 
        ret                       ;{{c397:c9}} 

;;=======================================================
;; output new line
output_new_line:                  ;{{Addr=$c398 Code Calls/jump count: 15 Data use count: 0}}
        push    af                ;{{c398:f5}} 
        ld      a,$0a             ;{{c399:3e0a}} 
        call    output_char       ;{{c39b:cda0c3}} ; display text char
        pop     af                ;{{c39e:f1}} 
        ret                       ;{{c39f:c9}} 

;;=======================================================
;; output char
output_char:                      ;{{Addr=$c3a0 Code Calls/jump count: 12 Data use count: 0}}
        push    af                ;{{c3a0:f5}} 
        push    bc                ;{{c3a1:c5}} 
        call    output_char_or_new_line;{{c3a2:cda8c3}} 
        pop     bc                ;{{c3a5:c1}} 
        pop     af                ;{{c3a6:f1}} 
        ret                       ;{{c3a7:c9}} 
;;-=======================================================
;;=output char or new line
output_char_or_new_line:          ;{{Addr=$c3a8 Code Calls/jump count: 1 Data use count: 0}}
        cp      $0a               ;{{c3a8:fe0a}} 
        jr      nz,output_raw_char;{{c3aa:200c}}  (+$0c)

        call    get_output_stream ;{{c3ac:cdbec1}} 
        jp      z,printer_new_line;{{c3af:caf5c3}} 
        jp      nc,write_crlf_to_file;{{c3b2:d231c4}}  write cr, lf to file
        jp      display_cr_lf     ;{{c3b5:c3e2c3}} 

;;-------------------------------------------------------------------
;;=output raw char
;A=char
output_raw_char:                  ;{{Addr=$c3b8 Code Calls/jump count: 5 Data use count: 0}}
        push    af                ;{{c3b8:f5}} 
        push    bc                ;{{c3b9:c5}} 
        ld      c,a               ;{{c3ba:4f}} 
        call    output_raw_char_to_current_stream;{{c3bb:cdc1c3}} 
        pop     bc                ;{{c3be:c1}} 
        pop     af                ;{{c3bf:f1}} 
        ret                       ;{{c3c0:c9}} 
;;-------------------------------------------------------------------
;;=output raw char to current stream
;C=char
;stream could be printer, file or display
output_raw_char_to_current_stream:;{{Addr=$c3c1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(current_output_stream_);{{c3c1:3a06ac}} 
        cp      $08               ;{{c3c4:fe08}} 
        jp      z,output_char_to_printer;{{c3c6:cafcc3}} 

        jp      nc,write_char_to_file;{{c3c9:d238c4}}  write char to file
        ld      a,c               ;{{c3cc:79}} 
        jp      do_txt_output     ;{{c3cd:c3e9c3}} 

;;========================================================================
;;=turn display on
;and move cursor to new line if not at start of line
turn_display_on:                  ;{{Addr=$c3d0 Code Calls/jump count: 3 Data use count: 0}}
        xor     a                 ;{{c3d0:af}}  output letters using text functions
        call    TXT_SET_GRAPHIC   ;{{c3d1:cd63bb}}  firmware function: txt set graphic	
        xor     a                 ;{{c3d4:af}}  opaque characters
        push    hl                ;{{c3d5:e5}} 
        call    TXT_SET_BACK      ;{{c3d6:cd9fbb}}  firmware function: txt set back
        pop     hl                ;{{c3d9:e1}} 
        call    TXT_VDU_ENABLE    ;{{c3da:cd54bb}}  firmware function: txt vdu enable

        call    get_x_cursor_position;{{c3dd:cdecc3}}  get x cursor position
        dec     a                 ;{{c3e0:3d}} 
        ret     z                 ;{{c3e1:c8}} 

;;=display cr lf
display_cr_lf:                    ;{{Addr=$c3e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0d             ;{{c3e2:3e0d}}  print CR,LF
        call    do_txt_output     ;{{c3e4:cde9c3}} 
        ld      a,$0a             ;{{c3e7:3e0a}} 
;;=do txt output
do_txt_output:                    ;{{Addr=$c3e9 Code Calls/jump count: 2 Data use count: 0}}
        jp      TXT_OUTPUT        ;{{c3e9:c35abb}}  firmware function: txt output

;;========================================================================
;; get x cursor position
get_x_cursor_position:            ;{{Addr=$c3ec Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{c3ec:c5}} 
        push    hl                ;{{c3ed:e5}} 
        call    get_Y_cursor_position;{{c3ee:cdc7c2}} 
        ld      a,h               ;{{c3f1:7c}} 
        pop     hl                ;{{c3f2:e1}} 
        pop     bc                ;{{c3f3:c1}} 
        ret                       ;{{c3f4:c9}} 
;;========================================================================
;;=printer new line
printer_new_line:                 ;{{Addr=$c3f5 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$0d             ;{{c3f5:0e0d}} 
        call    output_char_to_printer;{{c3f7:cdfcc3}} 
        ld      c,$0a             ;{{c3fa:0e0a}} 
;;=output char to printer
output_char_to_printer:           ;{{Addr=$c3fc Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{c3fc:e5}} 
        ld      hl,(printer_stream_current_x_position_);{{c3fd:2a08ac}} 
        call    process_new_lines_for_file_or_printer;{{c400:cd11c4}} 
        ld      (printer_stream_current_x_position_),a;{{c403:3208ac}} 
        pop     hl                ;{{c406:e1}} 

;;=print char
print_char:                       ;{{Addr=$c407 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{c407:79}} 
        call    MC_PRINT_CHAR     ;{{c408:cd2bbd}}  firmware function: mc print char
        ret     c                 ;{{c40b:d8}} printed? (otherwise port busy)

        call    test_for_break_key;{{c40c:cd72c4}}  key - abort if break
        jr      print_char        ;{{c40f:18f6}}  repeat until printed?

;;=process new lines for file or printer
process_new_lines_for_file_or_printer:;{{Addr=$c411 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{c411:79}} 
        xor     $0d               ;{{c412:ee0d}} 
        jr      z,_process_new_lines_for_file_or_printer_13;{{c414:2810}}  (+$10)
        ld      a,c               ;{{c416:79}} 
        cp      $20               ;{{c417:fe20}}  ' '
        ld      a,l               ;{{c419:7d}} 
        ret     c                 ;{{c41a:d8}} 

        inc     h                 ;{{c41b:24}} 
        jr      z,_process_new_lines_for_file_or_printer_13;{{c41c:2808}}  (+$08)
        cp      h                 ;{{c41e:bc}} 
        jr      nz,_process_new_lines_for_file_or_printer_13;{{c41f:2005}}  (+$05)
        call    output_new_line   ;{{c421:cd98c3}} ; new text line			
        ld      a,$01             ;{{c424:3e01}} 
_process_new_lines_for_file_or_printer_13:;{{Addr=$c426 Code Calls/jump count: 3 Data use count: 0}}
        inc     a                 ;{{c426:3c}} 
        ret     nz                ;{{c427:c0}} 

        dec     a                 ;{{c428:3d}} 
        ret                       ;{{c429:c9}} 

;;========================================================================
;; command WIDTH
command_WIDTH:                    ;{{Addr=$c42a Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_int_less_than_256;{{c42a:cdc3ce}} 
        ld      (WIDTH_),a        ;{{c42d:3209ac}} 
        ret                       ;{{c430:c9}} 
  
;;========================================================================
;; write cr,lf to file
write_crlf_to_file:               ;{{Addr=$c431 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$0d             ;{{c431:0e0d}} ; cr
        call    write_char_to_file;{{c433:cd38c4}}  write char to file
        ld      c,$0a             ;{{c436:0e0a}} ; lf

;;=write char to file
write_char_to_file:               ;{{Addr=$c438 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{c438:e5}} 
        ld      hl,(file_output_stream_current_line_position);{{c439:2a0aac}} 
        ld      h,$ff             ;{{c43c:26ff}} 
        call    process_new_lines_for_file_or_printer;{{c43e:cd11c4}} 
        ld      (file_output_stream_current_line_position),a;{{c441:320aac}} 
        pop     hl                ;{{c444:e1}} 
        ld      a,c               ;{{c445:79}} 
        call    CAS_OUT_CHAR      ;{{c446:cd95bc}}  firmware function: cas out char
        ret     c                 ;{{c449:d8}} 

        jr      nz,raise_file_not_open_error_B;{{c44a:2019}}  (+$19)
;;=raise File not open error
raise_File_not_open_error:        ;{{Addr=$c44c Code Calls/jump count: 2 Data use count: 0}}
        jp      raise_file_not_open_error_C;{{c44c:c337cc}} 

;;=================================================
;; variable EOF

variable_EOF:                     ;{{Addr=$c44f Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c44f:e5}} 
        call    CAS_TEST_EOF      ;{{c450:cd89bc}}  firmware function: cas test eof
        jr      z,raise_File_not_open_error;{{c453:28f7}}  (-$09)
        ccf                       ;{{c455:3f}} 
        sbc     a,a               ;{{c456:9f}} 
        call    store_sign_extended_byte_in_A_in_accumulator;{{c457:cd2dff}} 
        pop     hl                ;{{c45a:e1}} 
        ret                       ;{{c45b:c9}} 

;;==================================================
;; read byte from cassette or disc
read_byte_from_cassette_or_disc:  ;{{Addr=$c45c Code Calls/jump count: 3 Data use count: 0}}
        call    CAS_IN_CHAR       ;{{c45c:cd80bc}}  firmware function: cas in char
        ret     c                 ;{{c45f:d8}} 

        jr      z,raise_File_not_open_error;{{c460:28ea}}  (-$16)
        xor     $0e               ;{{c462:ee0e}} 
        ret     nz                ;{{c464:c0}} 

;;=raise File not open error
raise_file_not_open_error_B:      ;{{Addr=$c465 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{c465:cd45cb}} 
        defb $1f                  ;Inline error code: File not open

;;=set file output stream line pos to 1
set_file_output_stream_line_pos_to_1:;{{Addr=$c469 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$01             ;{{c469:3e01}} 
        ld      (file_output_stream_current_line_position),a;{{c46b:320aac}} 
        ret                       ;{{c46e:c9}} 




