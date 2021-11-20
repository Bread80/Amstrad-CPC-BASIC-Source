;;<< EXCEPTION HANDLING
;;< Includes ERROR, STOP, END, ON ERROR GOTO 0 (not ON ERROR GOTO n!), RESUME and error messages
;;========================================================================
;; clear errors and set resume addr to current
clear_errors_and_set_resume_addr_to_current:;{{Addr=$cb37 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{cb37:af}} 
        ld      (DERR__Disc_Error_No),a;{{cb38:3291ad}} 
;;=clear error and set resume addr to current
clear_error_and_set_resume_addr_to_current:;{{Addr=$cb3b Code Calls/jump count: 1 Data use count: 0}}
        ld      (ERR__Error_No),a ;{{cb3b:3290ad}} 
        call    get_current_line_address;{{cb3e:cdb1de}} 
        ld      (address_of_line_number_LB_in_line_contai),hl;{{cb41:228cad}} resume address
        ret                       ;{{cb44:c9}} 

;;========================================================================
;; - byte following call is error code
byte_following_call_is_error_code:;{{Addr=$cb45 Code Calls/jump count: 23 Data use count: 0}}
        ex      (sp),hl           ;{{cb45:e3}} 
        ld      a,(hl)            ;{{cb46:7e}} 
        jr      raise_error       ;{{cb47:180c}} 

;;========================================================================
;; Error: Syntax Error
Error_Syntax_Error:               ;{{Addr=$cb49 Code Calls/jump count: 15 Data use count: 1}}
        ld      a,$02             ;{{cb49:3e02}} Syntax error error
        jr      raise_error       ;{{cb4b:1808}}  (+$08)

;;========================================================================
;; Error: Improper Argument

Error_Improper_Argument:          ;{{Addr=$cb4d Code Calls/jump count: 22 Data use count: 0}}
        ld      a,$05             ;{{cb4d:3e05}} Improper argument error
        jr      raise_error       ;{{cb4f:1804}}  (+$04)

;;========================================================================
;; command ERROR
command_ERROR:                    ;{{Addr=$cb51 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_int_less_than_256;{{cb51:cdc3ce}} 
        ret     nz                ;{{cb54:c0}} 

;;+raise error
; A = Error code
raise_error:                      ;{{Addr=$cb55 Code Calls/jump count: 18 Data use count: 0}}
        call    clear_error_and_set_resume_addr_to_current;{{cb55:cd3bcb}} 
        ld      hl,(address_of_byte_before_current_statement);{{cb58:2a1bae}} 
        ld      (address_of_byte_before_statement_contain),hl;{{cb5b:228ead}} 
        call    set_last_RUN_error_line_data;{{cb5e:cd83cc}}  I presume we're testing for ON ERROR handlers
        call    prob_move_vars_and_arrays_back_from_end_of_memory;{{cb61:cd3cf6}} 
;;=raise error no tracking
raise_error_no_tracking:          ;{{Addr=$cb64 Code Calls/jump count: 1 Data use count: 0}}
        ld      sp,$c000          ;{{cb64:3100c0}} ##LIT##
        ld      hl,(cache_of_execution_stack_next_free_ptr);{{cb67:2a19ae}} 
        call    set_execution_stack_next_free_ptr;{{cb6a:cd6ef6}} 
        call    get_string_stack_first_free_ptr;{{cb6d:cdccfb}} 
        call    clear_FN_params_data;{{cb70:cd20da}} 
        call    get_resume_line_number;{{cb73:cdaacb}} C set if we have resume address
        ld      hl,(address_line_specified_by_the_ON_ERROR_);{{cb76:2a96ad}} 
        ex      de,hl             ;{{cb79:eb}} 
        ld      hl,RESUME_flag_   ;{{cb7a:2198ad}} 
        jr      nc,display_error_then_do_REPL;{{cb7d:300c}}  (+$0c) no resume address
        ld      a,d               ;{{cb7f:7a}} 
        or      e                 ;{{cb80:b3}} 
        jr      z,display_error_then_do_REPL;{{cb81:2808}}  (+$08) resume address is zero
        and     (hl)              ;{{cb83:a6}}  test if ON ERROR RESUME active ??
        jr      nz,display_error_then_do_REPL;{{cb84:2005}}  (+$05)
        dec     (hl)              ;{{cb86:35}} 
        ex      de,hl             ;{{cb87:eb}} 
        jp      execute_end_of_line;{{cb88:c377de}}  ON ERROR RESUME??

;;=display error then do REPL
display_error_then_do_REPL:       ;{{Addr=$cb8b Code Calls/jump count: 3 Data use count: 0}}
        ld      (hl),$00          ;{{cb8b:3600}} 
        ld      a,(ERR__Error_No) ;{{cb8d:3a90ad}} 
        call    find_full_error_message;{{cb90:cd8cce}} 
        ld      hl,(address_of_line_number_LB_in_line_contai);{{cb93:2a8cad}} resume address
        call    set_current_line_address;{{cb96:cdadde}} 
        ld      a,(ERR__Error_No) ;{{cb99:3a90ad}} 
        xor     $20               ;{{cb9c:ee20}} 
        jr      nz,_display_error_then_do_repl_10;{{cb9e:2004}}  (+$04)
        ld      a,(DERR__Disc_Error_No);{{cba0:3a91ad}} 
        rla                       ;{{cba3:17}} 
_display_error_then_do_repl_10:   ;{{Addr=$cba4 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,display_error_in_current_line_number;{{cba4:d404cc}} 
        jp      REPL_Read_Eval_Print_Loop;{{cba7:c358c0}} 

;;=======================================================================
;;get resume line number
;C set if we have a resume line
get_resume_line_number:           ;{{Addr=$cbaa Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(address_of_line_number_LB_in_line_contai);{{cbaa:2a8cad}} resume address
        call    get_line_number_atHL;{{cbad:cdb8de}} 
        ret     c                 ;{{cbb0:d8}} 
        ld      hl,$0000          ;{{cbb1:210000}} ##LIT##
        ret                       ;{{cbb4:c9}} 

;;=======================================================================
;;division by zero error
division_by_zero_error:           ;{{Addr=$cbb5 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{cbb5:d5}} 
        push    hl                ;{{cbb6:e5}} 
        ld      hl,division_by_zero_message;{{cbb7:21f6cd}} 
        ld      e,$0b             ;{{cbba:1e0b}} Division by zero error
        jr      maths_error       ;{{cbbc:1807}}  (+$07)

;;=overflow error
overflow_error:                   ;{{Addr=$cbbe Code Calls/jump count: 5 Data use count: 0}}
        push    de                ;{{cbbe:d5}} 
        push    hl                ;{{cbbf:e5}} 
        ld      hl,overflow_message;{{cbc0:21bfcd}} 
        ld      e,$06             ;{{cbc3:1e06}} Overflow error

;;=maths error
;HL=error message address
;E=error code
maths_error:                      ;{{Addr=$cbc5 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{cbc5:f5}} 
        push    hl                ;{{cbc6:e5}} 
        ld      hl,(address_line_specified_by_the_ON_ERROR_);{{cbc7:2a96ad}} 
        ld      a,h               ;{{cbca:7c}} 
        or      l                 ;{{cbcb:b5}} 
        pop     hl                ;{{cbcc:e1}} 
        ld      a,e               ;{{cbcd:7b}} Error code
        jp      nz,raise_error    ;{{cbce:c255cb}} If we have ON ERROR handler raise by usual method

        xor     a                 ;{{cbd1:af}} Otherwise raise manually
        call    select_txt_stream ;{{cbd2:cda6c1}} 
        push    af                ;{{cbd5:f5}} 
        ex      de,hl             ;{{cbd6:eb}} 
        call    display_error_message_atDE;{{cbd7:cd79ce}} 
        ex      de,hl             ;{{cbda:eb}} 
        call    output_new_line   ;{{cbdb:cd98c3}} ; new text line
        pop     af                ;{{cbde:f1}} 
        call    select_txt_stream ;{{cbdf:cda6c1}} 
        pop     af                ;{{cbe2:f1}} 
        pop     hl                ;{{cbe3:e1}} 
        pop     de                ;{{cbe4:d1}} 
        ret                       ;{{cbe5:c9}} 

;;==================================================
;;undefined line n in n error
undefined_line_n_in_n_error:      ;{{Addr=$cbe6 Code Calls/jump count: 1 Data use count: 0}}
        call    turn_display_on   ;{{cbe6:cdd0c3}} 
        ld      hl,undefined_line_message;{{cbe9:21f1cb}} 
        call    display_error_with_line_number;{{cbec:cd15cc}} 
        jr      displey_error_in_current_line_number;{{cbef:181c}}  (+$1c)

;;=undefined line message
undefined_line_message:           ;{{Addr=$cbf1 Data Calls/jump count: 0 Data use count: 1}}
        defb "Undefined line ",0  

;;=========================================
;;break in n error
break_in_n_error:                 ;{{Addr=$cc01 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,Break_message  ;{{cc01:111ccc}}  "Break"

;;=display error "in [current line number]"
display_error_in_current_line_number:;{{Addr=$cc04 Code Calls/jump count: 1 Data use count: 0}}
        call    select_txt_stream_zero;{{cc04:cda1c1}} 
        call    turn_display_on   ;{{cc07:cdd0c3}} 
        call    display_error_message_atDE;{{cc0a:cd79ce}} 

;;=displey error "in [current line number]"
displey_error_in_current_line_number:;{{Addr=$cc0d Code Calls/jump count: 1 Data use count: 0}}
        call    get_current_line_number;{{cc0d:cdb5de}} 
        ret     nc                ;{{cc10:d0}} 

        ex      de,hl             ;{{cc11:eb}} 
        ld      hl,in_message     ;{{cc12:2121cc}} ; " in " message

;;=display error with line number
display_error_with_line_number:   ;{{Addr=$cc15 Code Calls/jump count: 1 Data use count: 0}}
        call    output_ASCIIZ_string;{{cc15:cd8bc3}} ; display 0 terminated string
        ex      de,hl             ;{{cc18:eb}} 
        jp      display_decimal_number;{{cc19:c344ef}} 

;;=Break message
Break_message:                    ;{{Addr=$cc1c Data Calls/jump count: 0 Data use count: 1}}
        defb "Brea","k"+$80       ;($eb)

;;= in message
in_message:                       ;{{Addr=$cc21 Data Calls/jump count: 0 Data use count: 1}}
        defb " in ",0             

;;========================================================================
;; command STOP

command_STOP:                     ;{{Addr=$cc26 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{cc26:c0}} 
        push    hl                ;{{cc27:e5}} 
        call    break_in_n_error  ;{{cc28:cd01cc}} 
        pop     hl                ;{{cc2b:e1}} 
        call    set_if_error_data_before_stopping;{{cc2c:cd66cc}} 
        jr      goto_REPL         ;{{cc2f:1832}}  (+$32)

;;========================================================================
;; command END
command_END:                      ;{{Addr=$cc31 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{cc31:c0}} 
        call    set_if_error_data_before_stopping;{{cc32:cd66cc}} 
        jr      close_files_and_do_REPL;{{cc35:1823}}  (+$23)

;;=raise File not open error
raise_file_not_open_error_C:      ;{{Addr=$cc37 Code Calls/jump count: 6 Data use count: 0}}
        ld      (DERR__Disc_Error_No),a;{{cc37:3291ad}} 
        call    byte_following_call_is_error_code;{{cc3a:cd45cb}} 
        defb $20                  ;File not open error

;;=unknown execution error
unknown_execution_error:          ;{{Addr=$cc3e Code Calls/jump count: 2 Data use count: 0}}
        call break_in_n_error     ;{{cc3e:cd01cc}} 
        ld hl,(address_of_byte_before_current_statement);{{cc41:2a1bae}} 
        call    set_last_RUN_error_line_data;{{cc44:cd83cc}} 
        jr      goto_REPL         ;{{cc47:181a}}  (+$1a)

;;=prob end of program
prob_end_of_program:              ;{{Addr=$cc49 Code Calls/jump count: 1 Data use count: 0}}
        call    get_current_line_number;{{cc49:cdb5de}} 
        jr      nc,zero_current_line_and_do_REPL;{{cc4c:3012}}  (+$12)
        call    clear_last_RUN_error_line_address;{{cc4e:cd7ecc}} 
        ld      a,(RESUME_flag_)  ;{{cc51:3a98ad}} 
        or      a                 ;{{cc54:b7}} 
        ld      a,$13             ;{{cc55:3e13}} RESUME missing error
        jp      nz,raise_error    ;{{cc57:c255cb}} 

;;=close files and do REPL
close_files_and_do_REPL:          ;{{Addr=$cc5a Code Calls/jump count: 1 Data use count: 0}}
        call    command_CLOSEIN   ;{{cc5a:cdedd2}}  CLOSEIN
        call    command_CLOSEOUT  ;{{cc5d:cdf5d2}}  CLOSEOUT

;;=zero current line and do REPL
zero_current_line_and_do_REPL:    ;{{Addr=$cc60 Code Calls/jump count: 1 Data use count: 0}}
        call    zero_current_line_address;{{cc60:cdaade}} 

;;=goto REPL
goto_REPL:                        ;{{Addr=$cc63 Code Calls/jump count: 2 Data use count: 0}}
        jp      REPL_Read_Eval_Print_Loop;{{cc63:c358c0}} 

;;=set if error data before stopping
set_if_error_data_before_stopping:;{{Addr=$cc66 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{cc66:eb}} 
        call    get_current_line_number;{{cc67:cdb5de}} 
        ex      de,hl             ;{{cc6a:eb}} 
        ret     nc                ;{{cc6b:d0}} 

        ld      a,(hl)            ;{{cc6c:7e}} 
        cp      $01               ;{{cc6d:fe01}} 
        jr      z,_set_if_error_data_before_stopping_15;{{cc6f:280b}}  (+$0b)
        inc     hl                ;{{cc71:23}} 
        ld      a,(hl)            ;{{cc72:7e}} 
        inc     hl                ;{{cc73:23}} 
        or      (hl)              ;{{cc74:b6}} 
        jr      z,clear_last_RUN_error_line_address;{{cc75:2807}}  (+$07)
        inc     hl                ;{{cc77:23}} 
        call    set_current_line_address;{{cc78:cdadde}} 
        inc     hl                ;{{cc7b:23}} 
_set_if_error_data_before_stopping_15:;{{Addr=$cc7c Code Calls/jump count: 1 Data use count: 0}}
        jr      set_last_RUN_error_line_data;{{cc7c:1805}}  (+$05)

;;= clear last RUN error line address
clear_last_RUN_error_line_address:;{{Addr=$cc7e Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,$0000          ;{{cc7e:210000}} ##LIT##
        jr      _set_last_run_error_line_data_6;{{cc81:180c}}  (+$0c)

;;=set last RUN error line data
set_last_RUN_error_line_data:     ;{{Addr=$cc83 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{cc83:eb}} 
        call    get_current_line_number;{{cc84:cdb5de}} 
        ret     nc                ;{{cc87:d0}} 

        call    get_current_line_address;{{cc88:cdb1de}} 
        ld      (last_RUN_error_line_number),hl;{{cc8b:2294ad}} 
        ex      de,hl             ;{{cc8e:eb}} 
_set_last_run_error_line_data_6:  ;{{Addr=$cc8f Code Calls/jump count: 1 Data use count: 0}}
        ld      (last_RUN_error_address),hl;{{cc8f:2292ad}} 
        ret                       ;{{cc92:c9}} 

;;=============================================================================
;; command CONT
command_CONT:                     ;{{Addr=$cc93 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{cc93:c0}} 
        ld      hl,(last_RUN_error_address);{{cc94:2a92ad}} 
        ld      a,h               ;{{cc97:7c}} 
        or      l                 ;{{cc98:b5}} 
        ld      a,$11             ;{{cc99:3e11}} Cannot CONTinue error
        jp      z,raise_error     ;{{cc9b:ca55cb}} 
        push    hl                ;{{cc9e:e5}} 
        ld      hl,(last_RUN_error_line_number);{{cc9f:2a94ad}} 
        call    set_current_line_address;{{cca2:cdadde}} 
        call    SOUND_CONTINUE    ;{{cca5:cdb9bc}}  firmware function: sound continue
        pop     hl                ;{{cca8:e1}} 
        jp      execute_line_atHL ;{{cca9:c360de}} 

;;=clear error handlers
clear_error_handlers:             ;{{Addr=$ccac Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{ccac:af}} 
        ld      (RESUME_flag_),a  ;{{ccad:3298ad}} 
;;=clear ON ERROR GOTO target
clear_ON_ERROR_GOTO_target:       ;{{Addr=$ccb0 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0000          ;{{ccb0:110000}} ##LIT##
;;=set ON ERROR GOTO line address
set_ON_ERROR_GOTO_line_address:   ;{{Addr=$ccb3 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_line_specified_by_the_ON_ERROR_),de;{{ccb3:ed5396ad}} 
        ret                       ;{{ccb7:c9}} 

;;=ON ERROR GOTO
ON_ERROR_GOTO:                    ;{{Addr=$ccb8 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{ccb8:cd2cde}}  get next token skipping space
        call    next_token_if_equals_inline_data_byte;{{ccbb:cd25de}} 
        defb $a0                  ;Inline token to test "GOTO"
        call    eval_line_number_or_error;{{ccbf:cd48cf}} 
        push    hl                ;{{ccc2:e5}} 
        call    find_address_of_line_or_error;{{ccc3:cd5ce8}} 
        ex      de,hl             ;{{ccc6:eb}} 
        pop     hl                ;{{ccc7:e1}} 
        jr      set_ON_ERROR_GOTO_line_address;{{ccc8:18e9}}  (-$17)

;;========================================================================
;; command ON ERROR GOTO 0
;(but not ON ERROR GOTO [n]!)
command_ON_ERROR_GOTO_0:          ;{{Addr=$ccca Code Calls/jump count: 0 Data use count: 1}}
        call    clear_ON_ERROR_GOTO_target;{{ccca:cdb0cc}} 
        ld      a,(RESUME_flag_)  ;{{cccd:3a98ad}} 
        or      a                 ;{{ccd0:b7}} 
        ret     z                 ;{{ccd1:c8}} 

        jp      raise_error_no_tracking;{{ccd2:c364cb}} 

;;========================================================================
;; command RESUME

command_RESUME:                   ;{{Addr=$ccd5 Code Calls/jump count: 0 Data use count: 1}}
        jr      z,resume_and_execute;{{ccd5:2811}}  (+$11)
        cp      $b0               ;{{ccd7:feb0}} 
        jr      z,resume_skip_statement_and_execute;{{ccd9:2814}}  (+$14)
        call    eval_and_convert_line_number_to_line_address;{{ccdb:cd27e8}} 
        ret     nz                ;{{ccde:c0}} 

        call    restore_RESUME_data_or_error;{{ccdf:cdfacc}} 
        ex      de,hl             ;{{cce2:eb}} 
        inc     hl                ;{{cce3:23}} 
        pop     af                ;{{cce4:f1}} 
        jp      execute_end_of_line;{{cce5:c377de}} 

;;=resume and execute
resume_and_execute:               ;{{Addr=$cce8 Code Calls/jump count: 1 Data use count: 0}}
        call    restore_RESUME_data_or_error;{{cce8:cdfacc}} 
        pop     af                ;{{cceb:f1}} 
        jp      execute_line_atHL ;{{ccec:c360de}} 

;;=resume, skip statement and execute
resume_skip_statement_and_execute:;{{Addr=$ccef Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{ccef:cd2cde}}  get next token skipping space
        ret     nz                ;{{ccf2:c0}} 

        call    restore_RESUME_data_or_error;{{ccf3:cdfacc}} 
        inc     hl                ;{{ccf6:23}} 
        jp      skip_to_end_of_statement;{{ccf7:c3a3e9}} ; DATA

;;=restore RESUME data or error
restore_RESUME_data_or_error:     ;{{Addr=$ccfa Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(RESUME_flag_)  ;{{ccfa:3a98ad}} 
        or      a                 ;{{ccfd:b7}} 
        ld      a,$14             ;{{ccfe:3e14}} Unexpected RESUME error
        jp      z,raise_error     ;{{cd00:ca55cb}} 
        xor     a                 ;{{cd03:af}} 
        ld      (ERR__Error_No),a ;{{cd04:3290ad}} 
        ld      (RESUME_flag_),a  ;{{cd07:3298ad}} 
        ld      hl,(address_of_line_number_LB_in_line_contai);{{cd0a:2a8cad}} resume address
        call    set_current_line_address;{{cd0d:cdadde}} 
        ld      hl,(address_of_byte_before_statement_contain);{{cd10:2a8ead}} 
        ret                       ;{{cd13:c9}} 


;;ERROR MESSAGES
;;===================================
;;+-----------------------------
;;error message partials list

;Compressed table of error message.
;Each message or sub-message ends with bit 7 set.
;Constants within messages are indexes of other sub-messages to include.
error_message_partials_list:      ;{{Addr=$cd14 Data Calls/jump count: 0 Data use count: 1}}
        defb "p","e"+$80          ;$00 "pe"
        defb "i","n"+$80          ;$01 "in"
        defb "e","r"+$80          ;$02 "er"
        defb "e","x"+$80          ;$03 "ex"
        defb "io","n"+$80         ;$04 "ion"
        defb " f","u"+$80         ;$05 " fu"
        defb "co","m"+$80         ;$06 "com"
        defb "ra","n"+$80         ;$07 "ran"
        defb "t ","o"+$80         ;$08 "t o"
        defb "me","n"+$80         ;$09 "men"
        defb "te","d"+$80         ;$0a "ted"
        defb "WEN","D"+$80        ;$0b "WEND"
        defb "o",$00,"n"+$80      ;$0c "open"
        defb "File"," "+$80       ;$0d "File "
        defb "not"," "+$80        ;$0e "not "
        defb "too"," "+$80        ;$0f "too "
        defb " mi","s"+$80        ;$10 " mis"
        defb "L",$01,"e"," "+$80  ;$11 "Line "
        defb "NEX","T"+$80        ;$12 "NEXT"
        defb "s",$04," "+$80      ;$13 "sion "
        defb $05,"l","l"+$80      ;$14 " full"
        defb " ",$02,"ro","r"+$80 ;$15 " error"
        defb "RESUM","E"+$80      ;$16 "RESUME"
        defb "Str",$01,"g"," "+$80;$17 "String "
        defb " ",$06,"man","d"+$80;$18 " command"
        defb $10,"s",$01,"g"+$80  ;$19 " missing"
        defb "Unknow","n"+$80     ;$1a "Unknown"
        defb $0f,"lon","g"+$80    ;$1b "too long"
        defb "already"," "+$80    ;$1c "already "
        defb "Un",$03,"pec",$0a," "+$80;$1d "Unexpected "
        defb "irect",$18+$80      ;$1e "irect command"

;;=error message full list
;;Value equals error message number
error_message_full_list:          ;{{Addr=$cd94 Data Calls/jump count: 0 Data use count: 1}}
        defb $1a,$15+$80          ;$00 "Unknown error"
        defb $1d,$12+$80          ;$01 "Unexpected NEXT"
        defb "Syntax",$15+$80     ;$02 "Syntax error"
        defb $1d,"RETUR","N"+$80  ;$03 "Unexpected RETURN"
        defb "DATA ",$03,"haus",$0a+$80;$04 "DATA exhausted"
        defb "Impro",$00,"r argu",$09,"t"+$80;$05 "Improper argument"
;;=overflow message
overflow_message:                 ;{{Addr=$cdbf Data Calls/jump count: 0 Data use count: 1}}
        defb "Ov",$02,"flo","w"+$80;$06 "Overflow"
        defb "Memory",$14+$80     ;$07 "Memory full"
        defb $11,"does ",$0e,$03,"is","t"+$80;$08 "Line does not exist"
        defb "Subscrip",$08,"u",$08,"f ",$07,"g","e"+$80;$09 "Subscript out of range"
        defb "Array ",$1c,"di",$09,"s",$04,"e","d"+$80;$0a "Array already dimensioned"
;;=division by zero message
division_by_zero_message:         ;{{Addr=$cdf6 Data Calls/jump count: 0 Data use count: 1}}
        defb "Divi",$13,"by z",$02,"o"+$80;$0b "Division by zero"
        defb "Invalid d",$1e+$80  ;$0c "Invalid direct command"
        defb "Ty",$00,$10,"matc","h"+$80;$0d "Type mismatch"
        defb $17,"space",$14+$80  ;$0e "String space full"
        defb $17,$1b+$80          ;$0f "String too long"
        defb $17,$03,"pres",$13,$0f,$06,"pl",$03+$80;$10 "String expression too complex"
        defb "Can",$0e,"CONT",$01,"u","e"+$80;$11 "Cannot CONTinue"
        defb $1a," us",$02,$05,"nct",$04+$80;$12 "Unknown user function"
        defb $16,$19+$80          ;$13 "RESUME missing"
        defb $1d,$16+$80          ;$14 "Unexpected RESUME"
        defb "D",$1e," foun","d"+$80;$15 "Direct command found"
        defb "O",$00,$07,"d",$19+$80;$16 "Operand missing"
        defb $11,$1b+$80          ;$17 "Line too long"
        defb "EOF me","t"+$80     ;$18 "EOF met"
        defb $0d,"ty",$00,$15+$80 ;$19 "File type error"
        defb $12,$19+$80          ;$1a "NEXT missing"
        defb $0d,$1c,$0c+$80      ;$1b "File already open"
        defb $1a,$18+$80          ;$1c "Unknown command"
        defb $0b,$19+$80          ;$1d "WEND missing"
        defb $1d,$0b+$80          ;$1e "Unexpected WEND"
        defb $0d,$0e,$0c+$80      ;(WAS WRONG!!)$1f "File not open"
        defb "Broken ",$01+$80    ;(WAS WRONG!!)$20 "Broken in" (user terminated a cassette/disc operation?)

;;+------------------------------------------------------
;;display error message inc partials
display_error_message_inc_partials:;{{Addr=$ce73 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,error_message_partials_list;{{ce73:1114cd}} 
        call    find_error_message_in_table;{{ce76:cd92ce}} 

;;+display error message atDE
display_error_message_atDE:       ;{{Addr=$ce79 Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{ce79:d5}} 
        ld      a,(de)            ;{{ce7a:1a}}  get code
        and     $7f               ;{{ce7b:e67f}} 
        cp      $20               ;{{ce7d:fe20}} 

;; if $20<code<$7f -> code is a ASCII character. Display character.
;; if $00<code<$1f -> code is a message number. Display this message.
        call    nc,output_char    ;{{ce7f:d4a0c3}} ; display text char
        call    c,display_error_message_inc_partials;{{ce82:dc73ce}} ; display message partial
        pop     de                ;{{ce85:d1}} 
;; get char
        ld      a,(de)            ;{{ce86:1a}} 
        inc     de                ;{{ce87:13}} 
;; end of string marker
        rla                       ;{{ce88:17}} 
        jr      nc,display_error_message_atDE;{{ce89:30ee}}  (-$12)

        ret                       ;{{ce8b:c9}} 

;;+------------------------------------------------------
;;find full error message
;; A=error number

find_full_error_message:          ;{{Addr=$ce8c Code Calls/jump count: 1 Data use count: 0}}
        ld      de,error_message_full_list;{{ce8c:1194cd}} 
        cp      $21               ;{{ce8f:fe21}} 
        ret     nc                ;{{ce91:d0}} 

;;+find error message in table
;; DE=table ptr
;; A=error index
find_error_message_in_table:      ;{{Addr=$ce92 Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{ce92:b7}} 
        ret     z                 ;{{ce93:c8}} 

        push    bc                ;{{ce94:c5}} 
        ld      b,a               ;{{ce95:47}} 
_find_error_message_in_table_4:   ;{{Addr=$ce96 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{ce96:1a}} 
        inc     de                ;{{ce97:13}} 
        rla                       ;{{ce98:17}} 
        jr      nc,_find_error_message_in_table_4;{{ce99:30fb}}  (-$05)
        djnz    _find_error_message_in_table_4;{{ce9b:10f9}}  (-$07)
        pop     bc                ;{{ce9d:c1}} 
        ret                       ;{{ce9e:c9}} 

;;+---------------------------
;;unknown data block after error messages??
        out     ($c7),a           ;{{ce9f:d3c7}} 
        rst     $00               ;{{cea1:c7}} 
        rst     $00               ;{{cea2:c7}} 
        rst     $00               ;{{cea3:c7}} 
        rst     $00               ;{{cea4:c7}} 
        rst     $00               ;{{cea5:c7}} 
        rst     $00               ;{{cea6:c7}} 
        rst     $00               ;{{cea7:c7}} 
        rst     $00               ;{{cea8:c7}} 
        rst     $00               ;{{cea9:c7}} 
        rst     $00               ;{{ceaa:c7}} 
        rst     $00               ;{{ceab:c7}} 
        rst     $00               ;{{ceac:c7}} 
        rst     $00               ;{{cead:c7}} 
        rst     $00               ;{{ceae:c7}} 
        rst     $00               ;{{ceaf:c7}} 
        rst     $00               ;{{ceb0:c7}} 
        rst     $00               ;{{ceb1:c7}} 
        rst     $00               ;{{ceb2:c7}} 
        rst     $00               ;{{ceb3:c7}} 
        rst     $00               ;{{ceb4:c7}} 
        rst     $00               ;{{ceb5:c7}} 
        rst     $00               ;{{ceb6:c7}} 
        rst     $00               ;{{ceb7:c7}} 





