;;<< BASIC INPUT BUFFER
;;< As used by EDIT and INPUT etc.
;;===================================

;; prob read buffer and or break
;Called by (LINE) INPUT and RANDOMISE to get text input.
prob_read_buffer_and_or_break:    ;{{Addr=$caec Code Calls/jump count: 2 Data use count: 0}}
        call    input_text_to_BASIC_input_area;{{caec:cdf9ca}}  edit
        ret     c                 ;{{caef:d8}} 

        call    select_txt_stream_zero;{{caf0:cda1c1}} 
        ld      sp,$c000          ;{{caf3:3100c0}} ##LIT##
        jp      execute_current_statement;{{caf6:c35dde}} 

;;------------------------------------------------------------------------------------------
;;=input text to BASIC input area
input_text_to_BASIC_input_area:   ;{{Addr=$caf9 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,BASIC_input_area_for_lines_;{{caf9:218aac}} 
        ld      (hl),$00          ;{{cafc:3600}} 
        jp      TEXT_INPUT        ;{{cafe:c35ebd}}  TEXT INPUT

;;------------------------------------------------------------------------------------------
;;=edit text in BASIC input area and display new line
edit_text_in_BASIC_input_area_and_display_new_line:;{{Addr=$cb01 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,BASIC_input_area_for_lines_;{{cb01:218aac}} 
        call    TEXT_INPUT        ;{{cb04:cd5ebd}}  TEXT INPUT
        jp      output_new_line   ;{{cb07:c398c3}} ; new text line

;;------------------------------------------------------------------------------------------
;;=read line from cassette or disc
;Reads into the BASIC input area
;Returns CF=1 if success
read_line_from_cassette_or_disc:  ;{{Addr=$cb0a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{cb0a:c5}} 
        ld      hl,BASIC_input_area_for_lines_;{{cb0b:218aac}} 
        push    hl                ;{{cb0e:e5}} 
        ld      b,$00             ;{{cb0f:0600}} Buffer free bytes remaining

_read_line_from_cassette_or_disc_4:;{{Addr=$cb11 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,$f5             ;{{cb11:0ef5}} C=previous byte

;;=read to buffer loop
read_to_buffer_loop:              ;{{Addr=$cb13 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{cb13:3600}} End of buffer marker
        call    read_byte_from_cassette_or_disc;{{cb15:cd5cc4}}  read byte from cassette or disc
        jr      nc,_read_to_buffer_loop_19;{{cb18:301a}}  (+$1a) end of file?
        cp      $0d               ;{{cb1a:fe0d}} CR
        jr      z,_read_to_buffer_loop_15;{{cb1c:2810}}  (+$10) end of line = done
        ld      c,a               ;{{cb1e:4f}} 
        inc     b                 ;{{cb1f:04}} 
        djnz    _read_to_buffer_loop_10;{{cb20:1004}}  (+$04) skip if not end of line
        cp      $0a               ;{{cb22:fe0a}} LF 
        jr      z,_read_line_from_cassette_or_disc_4;{{cb24:28eb}}  (-$15) happy to skip LF at end of line
                                  ;(if may be followed by CR, which is true end of line
                                        
_read_to_buffer_loop_10:          ;{{Addr=$cb26 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),a            ;{{cb26:77}} Store byte
        inc     hl                ;{{cb27:23}} 
        djnz    read_to_buffer_loop;{{cb28:10e9}}  (-$17) Loop for next byte

        call    byte_following_call_is_error_code;{{cb2a:cd45cb}} Buffer full
        defb $17                  ;Inline error code: Line too long
     
;CR read
_read_to_buffer_loop_15:          ;{{Addr=$cb2e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{cb2e:79}} get previous byte
        cp      $0a               ;{{cb2f:fe0a}} LF
        jr      z,_read_line_from_cassette_or_disc_4;{{cb31:28de}}  (-$22) End of line is LF followed by CR. If not keep reading
        scf                       ;{{cb33:37}} Success

_read_to_buffer_loop_19:          ;{{Addr=$cb34 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{cb34:e1}} 
        pop     bc                ;{{cb35:c1}} 
        ret                       ;{{cb36:c9}} 






