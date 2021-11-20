;;<< (TEXT) DATA INPUT
;;< (LINE) INPUT, RESTORE, READ (not DATA)
;;========================================================================
;; command LINE INPUT

command_LINE_INPUT:               ;{{Addr=$db13 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_equals_inline_data_byte;{{db13:cd25de}} 
        defb $a3                  ;inline token to test "INPUT"
        call    swap_both_streams_exec_TOS_and_swap_back;{{db17:cdd4c1}} 
        call    input_display_prompt_if_given;{{db1a:cd8bdb}} 
        call    parse_and_find_or_create_a_var;{{db1d:cdbfd6}} 
        call    error_if_accumulator_is_not_a_string;{{db20:cd5eff}} can only read strings
        push    hl                ;{{db23:e5}} 
        push    de                ;{{db24:d5}} 
        call    input_to_buffer   ;{{db25:cd31db}} 
        call    get_ASCIIZ_string ;{{db28:cd8af8}} 
        pop     hl                ;{{db2b:e1}} 
        call    copy_accumulator_to_atHL;{{db2c:cda8d6}} 
        pop     hl                ;{{db2f:e1}} 
        ret                       ;{{db30:c9}} 

;;=input to buffer
input_to_buffer:                  ;{{Addr=$db31 Code Calls/jump count: 1 Data use count: 0}}
        call    get_input_stream  ;{{db31:cdc4c1}} 
        jp      nc,input_line_from_file;{{db34:d257dc}} file stream? read from file
;;=input screen to buffer
input_screen_to_buffer:           ;{{Addr=$db37 Code Calls/jump count: 1 Data use count: 0}}
        call    prob_read_buffer_and_or_break;{{db37:cdecca}} read line to BASIC input buffer
        ld      a,(input_prompt_separator);{{db3a:3a14ae}} 
        cp      $3b               ;{{db3d:fe3b}} ';'
        call    nz,output_new_line;{{db3f:c498c3}} new line unless followed by semicolon?
        ret                       ;{{db42:c9}} 

;;========================================================================
;; command INPUT

command_INPUT:                    ;{{Addr=$db43 Code Calls/jump count: 0 Data use count: 1}}
        call    swap_both_streams_exec_TOS_and_swap_back;{{db43:cdd4c1}} 
        call    input_get_input   ;{{db46:cd5bdb}} 
        push    de                ;{{db49:d5}} 
_command_input_3:                 ;{{Addr=$db4a Code Calls/jump count: 1 Data use count: 0}}
        call    parse_and_find_or_create_a_var;{{db4a:cdbfd6}} 
        ex      (sp),hl           ;{{db4d:e3}} 
        xor     a                 ;{{db4e:af}} 
        call    input_parse_item_or_error;{{db4f:cdbddb}} 
        inc     hl                ;{{db52:23}} 
        ex      (sp),hl           ;{{db53:e3}} 
        call    next_token_if_prev_is_comma;{{db54:cd41de}} 
        jr      c,_command_input_3;{{db57:38f1}}  (-$0f)
        pop     de                ;{{db59:d1}} 
        ret                       ;{{db5a:c9}} 

;;=input get input
input_get_input:                  ;{{Addr=$db5b Code Calls/jump count: 1 Data use count: 0}}
        call    get_input_stream  ;{{db5b:cdc4c1}} 
        jr      nc,input_display_prompt_if_given;{{db5e:302b}}  (+$2b) if file

_input_get_input_2:               ;{{Addr=$db60 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{db60:e5}} 
        call    input_display_prompt_if_given;{{db61:cd8bdb}} show prompt
        push    hl                ;{{db64:e5}} 
        call    input_screen_to_buffer;{{db65:cd37db}} input to buffer
        ex      de,hl             ;{{db68:eb}} 
        pop     hl                ;{{db69:e1}} 
        call    input_parse_buffer;{{db6a:cdcddb}} parse input buffer
        pop     bc                ;{{db6d:c1}} 
        ret     c                 ;{{db6e:d8}} return if valid input

        push    bc                ;{{db6f:c5}} 
        ld      hl,redo_from_start_message;{{db70:2179db}} ; "?Redo from start" message
        call    output_ASCIIZ_string;{{db73:cd8bc3}} ; display 0 terminated string
        pop     hl                ;{{db76:e1}} 
        jr      _input_get_input_2;{{db77:18e7}}  (-$19) retry

;;=redo from start message
redo_from_start_message:          ;{{Addr=$db79 Data Calls/jump count: 0 Data use count: 1}}
        defb "?Redo from start",10,0

;;=input display prompt, if given
input_display_prompt_if_given:    ;{{Addr=$db8b Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{db8b:7e}} 
        cp      $3b               ;{{db8c:fe3b}} ';'
        ld      (input_prompt_separator),a;{{db8e:3214ae}} 
        call    z,get_next_token_skipping_space;{{db91:cc2cde}}  get next token skipping space
        cp      $22               ;{{db94:fe22}} '"' - prompt string
        jr      nz,_input_display_prompt_if_given_11;{{db96:200b}}  (+$0b)
        call    input_display_prompt;{{db98:cdb1db}} 
        call    next_token_if_prev_is_comma;{{db9b:cd41de}} 
        ret     c                 ;{{db9e:d8}} if comma then no '? ' after

        call    next_token_if_equals_inline_data_byte;{{db9f:cd25de}} 
        defb $3b                  ;inline token to test ";"
_input_display_prompt_if_given_11:;{{Addr=$dba3 Code Calls/jump count: 1 Data use count: 0}}
        call    get_input_stream  ;{{dba3:cdc4c1}} 
        ret     nc                ;{{dba6:d0}} exit if not reading from screen

        ld      a,$3f             ;{{dba7:3e3f}} '?'
        call    output_char       ;{{dba9:cda0c3}} ; display text char
        ld      a,$20             ;{{dbac:3e20}} space char
        jp      output_char       ;{{dbae:c3a0c3}} ; display text char

;;=input display prompt
input_display_prompt:             ;{{Addr=$dbb1 Code Calls/jump count: 1 Data use count: 0}}
        call    get_quoted_string ;{{dbb1:cd79f8}} 
        call    get_input_stream  ;{{dbb4:cdc4c1}} 
        jp      nc,get_accumulator_string_length;{{dbb7:d2f5fb}} 
        jp      output_accumulator_string;{{dbba:c3d0f8}} 

;;=input parse item or error
input_parse_item_or_error:        ;{{Addr=$dbbd Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{dbbd:d5}} 
        call    input_parse_item  ;{{dbbe:cdf7db}} 
        jr      nc,raise_Type_Mismatch_error;{{dbc1:3006}}  (+$06)
        ex      (sp),hl           ;{{dbc3:e3}} 
        call    copy_accumulator_to_atHL_as_type_B;{{dbc4:cd9fd6}} 
        pop     hl                ;{{dbc7:e1}} 
        ret                       ;{{dbc8:c9}} 

;;=raise Type Mismatch error
raise_Type_Mismatch_error:        ;{{Addr=$dbc9 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{dbc9:cd45cb}} 
        defb $0d                  ;Inline error code: Type mismatch

;;=input parse buffer
;returns Carry true if the input was valid/matched variable list etc.
input_parse_buffer:               ;{{Addr=$dbcd Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{dbcd:d5}} 
        push    hl                ;{{dbce:e5}} 
        push    de                ;{{dbcf:d5}} 
_input_parse_buffer_3:            ;{{Addr=$dbd0 Code Calls/jump count: 1 Data use count: 0}}
        call    prob_just_skip_over_variable;{{dbd0:cd0fd7}} 
        ex      (sp),hl           ;{{dbd3:e3}} 
        xor     a                 ;{{dbd4:af}} 
        call    input_parse_item  ;{{dbd5:cdf7db}} 
        jr      nc,_input_parse_buffer_23;{{dbd8:3019}}  (+$19) end of buffer? failed
        cp      $03               ;{{dbda:fe03}} string
        call    z,get_accumulator_string_length;{{dbdc:ccf5fb}} 
        ex      (sp),hl           ;{{dbdf:e3}} 
        call    next_token_if_prev_is_comma;{{dbe0:cd41de}} 
        ex      (sp),hl           ;{{dbe3:e3}} 
        ld      a,(hl)            ;{{dbe4:7e}} next token
        jr      nc,_input_parse_buffer_20;{{dbe5:3008}}  (+$08) end of variable list?
        xor     $2c               ;{{dbe7:ee2c}} ','
        jr      nz,_input_parse_buffer_23;{{dbe9:2008}}  (+$08) no more entries in variable list?
        inc     hl                ;{{dbeb:23}} 
        ex      (sp),hl           ;{{dbec:e3}} 
        jr      _input_parse_buffer_3;{{dbed:18e1}}  (-$1f)

_input_parse_buffer_20:           ;{{Addr=$dbef Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{dbef:b7}} A=next token. If zero we have end of line = success
        jr      nz,_input_parse_buffer_23;{{dbf0:2001}}  (+$01)
        scf                       ;{{dbf2:37}} success!!
_input_parse_buffer_23:           ;{{Addr=$dbf3 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{dbf3:e1}} 
        pop     hl                ;{{dbf4:e1}} 
        pop     de                ;{{dbf5:d1}} 
        ret                       ;{{dbf6:c9}} 

;;=input parse item
input_parse_item:                 ;{{Addr=$dbf7 Code Calls/jump count: 2 Data use count: 0}}
        ld      e,a               ;{{dbf7:5f}} what variable type to we have?
        call    is_accumulator_a_string;{{dbf8:cd66ff}} 
        push    af                ;{{dbfb:f5}} 
        jr      nz,input_parse_number;{{dbfc:2006}}  (+$06)
        call    input_parse_string;{{dbfe:cd15dc}} 
        scf                       ;{{dc01:37}} 
        jr      _input_parse_number_3;{{dc02:1809}}  (+$09)

;;=input parse number
input_parse_number:               ;{{Addr=$dc04 Code Calls/jump count: 1 Data use count: 0}}
        call    get_input_stream  ;{{dc04:cdc4c1}} 
        call    nc,input_from_file_ignore_leading_whitespace;{{dc07:d42cdc}} 
        call    possibly_validate_input_buffer_is_a_number;{{dc0a:cd6fed}} 
_input_parse_number_3:            ;{{Addr=$dc0d Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{dc0d:f5}} 

;;=input parse item done
        call    c,skip_space_tab_or_line_feed;{{dc0e:dc4dde}}  skip space, lf or tab
        pop     af                ;{{dc11:f1}} 
        pop     de                ;{{dc12:d1}} 
        ld      a,d               ;{{dc13:7a}} 
        ret                       ;{{dc14:c9}} 

;;=input parse string
;inputs quoted string (keyboard) or ASCIIZ string (not keyboard)
input_parse_string:               ;{{Addr=$dc15 Code Calls/jump count: 1 Data use count: 0}}
        call    get_input_stream  ;{{dc15:cdc4c1}} 
        jr      c,input_parse_quoted_string;{{dc18:3806}}  (+$06)
        call    input_item_from_file;{{dc1a:cd38dc}} 
        jp      get_ASCIIZ_string ;{{dc1d:c38af8}} 

;;=input parse quoted string
input_parse_quoted_string:        ;{{Addr=$dc20 Code Calls/jump count: 1 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{dc20:cd4dde}}  skip space, lf or tab
        cp      $22               ;{{dc23:fe22}} '"'
        jp      z,get_quoted_string;{{dc25:ca79f8}} 
        ld      a,e               ;{{dc28:7b}} 
        jp      get_string_until_00_comma_or_value_in_A;{{dc29:c394f8}} 

;;=====================================
;INPUT from a file
;;=input from file ignore leading whitespace
input_from_file_ignore_leading_whitespace:;{{Addr=$dc2c Code Calls/jump count: 1 Data use count: 0}}
        call    input_char_from_file_ignore_whitespace;{{dc2c:cd8edc}} 
        ld      de,is_A_space_tab_cr_comma_lf;{{dc2f:11b5dc}} ##LABEL##
        jr      c,input_from_file ;{{dc32:382b}}  (+$2b)

;;=raise EOF met error
raise_EOF_met_error:              ;{{Addr=$dc34 Code Calls/jump count: 2 Data use count: 0}}
        call    byte_following_call_is_error_code;{{dc34:cd45cb}} 
        defb $18                  ;Inline error code: EOF met

;;=input item from file
;reads item terminated by comma or LF, or quoted string
input_item_from_file:             ;{{Addr=$dc38 Code Calls/jump count: 1 Data use count: 0}}
        call input_char_from_file_ignore_whitespace;{{dc38:cd8edc}} 
        jr nc,raise_EOF_met_error ;{{dc3b:30f7}} Manually calculated!!! Object code should be 31f7
        cp      $22               ;{{dc3d:fe22}} '"'
        jr      z,input_quoted_string_from_file;{{dc3f:2805}}  (+$05)
        ld      de,is_A_comma_lf  ;{{dc41:11b9dc}} ##LABEL##
        jr      input_from_file   ;{{dc44:1819}}  (+$19)

;;=input quoted string from file
input_quoted_string_from_file:    ;{{Addr=$dc46 Code Calls/jump count: 1 Data use count: 0}}
        call    input_char_from_file;{{dc46:cd99dc}} 
        ld      de,is_A_double_quotes;{{dc49:1154dc}} ##LABEL##
        jr      c,input_from_file ;{{dc4c:3811}}  (+$11)
        ld      hl,BASIC_input_area_for_lines_;{{dc4e:218aac}} 
        ld      (hl),$00          ;{{dc51:3600}} 
        ret                       ;{{dc53:c9}} 

;;=is A double quotes
is_A_double_quotes:               ;{{Addr=$dc54 Code Calls/jump count: 0 Data use count: 1}}
        cp      $22               ;{{dc54:fe22}} "'
        ret                       ;{{dc56:c9}} 

;;=input line from file
input_line_from_file:             ;{{Addr=$dc57 Code Calls/jump count: 1 Data use count: 0}}
        call    input_char_from_file;{{dc57:cd99dc}} 
        jr      nc,raise_EOF_met_error;{{dc5a:30d8}}  (-$28)
        ld      de,is_A_lf        ;{{dc5c:11bcdc}} end of input test routine ##LABEL##

;;=input from file
;;this code takes an address to call in DE
;this routine is called with a character in A and returns Z flag set if it's a terminating character
input_from_file:                  ;{{Addr=$dc5f Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,BASIC_input_area_for_lines_;{{dc5f:218aac}} 
        push    hl                ;{{dc62:e5}} 
        ld      b,$ff             ;{{dc63:06ff}} max line length
_input_from_file_3:               ;{{Addr=$dc65 Code Calls/jump count: 1 Data use count: 0}}
        call    JP_DE             ;{{dc65:cdfeff}}  JP (DE) - test for termination char
        jr      z,_input_from_file_12;{{dc68:280c}}  (+$0c)
        ld      (hl),a            ;{{dc6a:77}} 
        inc     hl                ;{{dc6b:23}} 
        dec     b                 ;{{dc6c:05}} 
        jr      z,_input_from_file_11;{{dc6d:2805}}  (+$05)
        call    input_char_from_file;{{dc6f:cd99dc}} read next char
        jr      c,_input_from_file_3;{{dc72:38f1}}  (-$0f)    loop for more chars

_input_from_file_11:              ;{{Addr=$dc74 Code Calls/jump count: 1 Data use count: 0}}
        or      $ff               ;{{dc74:f6ff}} 
_input_from_file_12:              ;{{Addr=$dc76 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$00          ;{{dc76:3600}} 
        pop     hl                ;{{dc78:e1}} 
        ret     nz                ;{{dc79:c0}} 

        cp      $0d               ;{{dc7a:fe0d}} CR
        ret     z                 ;{{dc7c:c8}} 

        cp      $22               ;{{dc7d:fe22}} '"'
        call    nz,is_A_space_tab_cr;{{dc7f:c4bfdc}} 
        ret     nz                ;{{dc82:c0}} 

        call    input_char_from_file_ignore_whitespace;{{dc83:cd8edc}} 
        ret     nc                ;{{dc86:d0}} 

        call    is_A_comma_lf     ;{{dc87:cdb9dc}} 
        call    nz,CAS_RETURN     ;{{dc8a:c486bc}}  firmware function: CAS RETURN
        ret                       ;{{dc8d:c9}} 

;;=input char from file, ignore whitespace
input_char_from_file_ignore_whitespace:;{{Addr=$dc8e Code Calls/jump count: 4 Data use count: 0}}
        call    input_char_from_file;{{dc8e:cd99dc}} 
        ret     nc                ;{{dc91:d0}} 

        call    is_A_space_tab_cr ;{{dc92:cdbfdc}} 
        jr      z,input_char_from_file_ignore_whitespace;{{dc95:28f7}}  (-$09)
        scf                       ;{{dc97:37}} 
        ret                       ;{{dc98:c9}} 

;;=input char from file
;turns CR+LF and LF+CR into single char (returns the first of the pair)
input_char_from_file:             ;{{Addr=$dc99 Code Calls/jump count: 4 Data use count: 0}}
        call    read_byte_from_cassette_or_disc;{{dc99:cd5cc4}}  read byte from cassette or disc
        ret     nc                ;{{dc9c:d0}} 

        push    af                ;{{dc9d:f5}} 
        push    bc                ;{{dc9e:c5}} 
        ld      bc,$0a0d          ;{{dc9f:010d0a}} LF CR
        cp      c                 ;{{dca2:b9}} CR? test for CR LF
        jr      z,_input_char_from_file_10;{{dca3:2804}}  (+$04)
        cp      b                 ;{{dca5:b8}} not LF? - return as is
        jr      nz,_input_char_from_file_14;{{dca6:200a}}  (+$0a)
        ld      b,c               ;{{dca8:41}} 
_input_char_from_file_10:         ;{{Addr=$dca9 Code Calls/jump count: 1 Data use count: 0}}
        call    read_byte_from_cassette_or_disc;{{dca9:cd5cc4}}  read byte from cassette or disc
        jr      nc,_input_char_from_file_14;{{dcac:3004}}  (+$04)
        cp      b                 ;{{dcae:b8}} CR followed by LF or LF followed by CR? if not, put the second char back
        call    nz,CAS_RETURN     ;{{dcaf:c486bc}} ; firmware function: cas return
_input_char_from_file_14:         ;{{Addr=$dcb2 Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{dcb2:c1}} 
        pop     af                ;{{dcb3:f1}} get back the original char we read
        ret                       ;{{dcb4:c9}} 

;;========================================================================
;; is A space tab cr comma lf
is_A_space_tab_cr_comma_lf:       ;{{Addr=$dcb5 Code Calls/jump count: 0 Data use count: 1}}
        call    is_A_space_tab_cr ;{{dcb5:cdbfdc}} 
        ret     z                 ;{{dcb8:c8}} 

;;=is A comma lf
is_A_comma_lf:                    ;{{Addr=$dcb9 Code Calls/jump count: 1 Data use count: 1}}
        cp      $2c               ;{{dcb9:fe2c}} ; ,
        ret     z                 ;{{dcbb:c8}} 

;;=is A lf
is_A_lf:                          ;{{Addr=$dcbc Code Calls/jump count: 0 Data use count: 1}}
        cp      $0d               ;{{dcbc:fe0d}} ; lf
        ret                       ;{{dcbe:c9}} 

;;========================================================================
;;is A space tab cr
is_A_space_tab_cr:                ;{{Addr=$dcbf Code Calls/jump count: 3 Data use count: 0}}
        cp      $20               ;{{dcbf:fe20}} ; space
        ret     z                 ;{{dcc1:c8}} 

        cp      $09               ;{{dcc2:fe09}} ; tab
        ret     z                 ;{{dcc4:c8}} 

        cp      $0a               ;{{dcc5:fe0a}} ; cr
        ret                       ;{{dcc7:c9}} 

;;========================================================================
;; command RESTORE
command_RESTORE:                  ;{{Addr=$dcc8 Code Calls/jump count: 0 Data use count: 1}}
        jr      z,reset_READ_pointer;{{dcc8:280a}}  (+$0a)
        call    eval_line_number_or_error;{{dcca:cd48cf}} 
        push    hl                ;{{dccd:e5}} 
        call    find_address_of_line_or_error;{{dcce:cd5ce8}} 
        dec     hl                ;{{dcd1:2b}} 
        jr      set_READ_pointer  ;{{dcd2:1831}}  (+$31)

;;=reset READ pointer
reset_READ_pointer:               ;{{Addr=$dcd4 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{dcd4:e5}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{dcd5:2a64ae}} first line
        jr      set_READ_pointer  ;{{dcd8:182b}}  (+$2b)

;;========================================================================
;; command READ
command_READ:                     ;{{Addr=$dcda Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{dcda:e5}} 
        ld      hl,(READ_pointer) ;{{dcdb:2a17ae}} 
;;=READ item loop
READ_item_loop:                   ;{{Addr=$dcde Code Calls/jump count: 1 Data use count: 0}}
        call    update_READ_pointer;{{dcde:cd0add}} 
        ex      (sp),hl           ;{{dce1:e3}} 
        call    parse_and_find_or_create_a_var;{{dce2:cdbfd6}} 
        ex      (sp),hl           ;{{dce5:e3}} 
        inc     hl                ;{{dce6:23}} 
        ld      a,$01             ;{{dce7:3e01}} 
        call    input_parse_item_or_error;{{dce9:cdbddb}} read data
        ld      a,(hl)            ;{{dcec:7e}} next token
        cp      $02               ;{{dced:fe02}} 
        jr      c,_read_item_loop_15;{{dcef:380d}}  (+$0d) end of line/statement
        cp      $2c               ;{{dcf1:fe2c}} ','
        jr      z,_read_item_loop_15;{{dcf3:2809}}  (+$09) comma
        ld      hl,(address_of_line_number_LB_of_last_BASIC_);{{dcf5:2a15ae}} anything else is error
        call    set_current_line_address;{{dcf8:cdadde}} 
        jp      Error_Syntax_Error;{{dcfb:c349cb}}  Error: Syntax Error

_read_item_loop_15:               ;{{Addr=$dcfe Code Calls/jump count: 2 Data use count: 0}}
        ex      (sp),hl           ;{{dcfe:e3}} 
        call    next_token_if_prev_is_comma;{{dcff:cd41de}} another value to read?
        ex      (sp),hl           ;{{dd02:e3}} 
        jr      c,READ_item_loop  ;{{dd03:38d9}}  (-$27) if so, loop
;;=set READ pointer
set_READ_pointer:                 ;{{Addr=$dd05 Code Calls/jump count: 2 Data use count: 0}}
        ld      (READ_pointer),hl ;{{dd05:2217ae}} 
        pop     hl                ;{{dd08:e1}} 
        ret                       ;{{dd09:c9}} 

;;=update READ pointer
;move to comma before next data item, if not currently at one
update_READ_pointer:              ;{{Addr=$dd0a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{dd0a:7e}} 
        cp      $2c               ;{{dd0b:fe2c}} ','
        ret     z                 ;{{dd0d:c8}} 

_update_read_pointer_3:           ;{{Addr=$dd0e Code Calls/jump count: 1 Data use count: 0}}
        call    skip_to_end_of_statement;{{dd0e:cda3e9}} ; DATA
        or      a                 ;{{dd11:b7}} 
        jr      nz,_update_read_pointer_15;{{dd12:200e}}  (+$0e) not end of line
        inc     hl                ;{{dd14:23}} 
        ld      a,(hl)            ;{{dd15:7e}} test for last line
        inc     hl                ;{{dd16:23}} 
        or      (hl)              ;{{dd17:b6}} 
        inc     hl                ;{{dd18:23}} 
        ld      a,$04             ;{{dd19:3e04}} DATA exhausted error
        jp      z,raise_error     ;{{dd1b:ca55cb}} 
        ld      (address_of_line_number_LB_of_last_BASIC_),hl;{{dd1e:2215ae}} update line address
        inc     hl                ;{{dd21:23}} 
_update_read_pointer_15:          ;{{Addr=$dd22 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{dd22:cd2cde}}  get next token skipping space
        cp      $8c               ;{{dd25:fe8c}} DATA token
        jr      nz,_update_read_pointer_3;{{dd27:20e5}}  (-$1b) loop if not DATA token
        ret                       ;{{dd29:c9}} 




