;;***Main.asm
;#dialect=RASM

;Current progress:
;(Mostly) fully reverse engineered as far as **TK

;'Unassembled'[1] Amstrad CPC6128 BASIC 1.1 Source Code

;[1] 'Unassembled' meaning that this code can be modified and reassembled.
;(As far as I can tell) all links etc have been converted to labels etc in
;such a way that the code can be assembled at a different target address
;and still function correctly (excepting code which must run at a specific
;address).

;Based on the riginal commented disassembly at:
; http://cpctech.cpc-live.com/docs/basic.asm

;There are two versions of this file: a single monolithic version and
;one which has been broken out into separate 'includes'. The latter may
;prove better for modification, assembly and re-use. The former for 
;exploration and reverse engineering.

;For more details see: https://github.com/Bread80/Amstrad-CPC-BASIC-Source
;and http://Bread80.com


;;***Initialisation.asm
;;=======
;;BASIC 1.1

org $c000                         ;##LIT##
include "Includes/JumpblockLow.asm"
include "Includes/JumpblockMain6128.asm"
include "Includes/MemoryBASIC.asm"
                                  
;ROM header
        defb $80                  ; foreground rom
        defb $01                  ;mark
        defb $02                  ;version
        defb $00                  ;modification

        defw rsx_name_table       ; name table

;On entry DE = first byte of available memory
;HL,BC = upper memory addreses??

        ld      sp,$c000          ;{{c006:3100c0}} ##LIT##
        call    KL_ROM_WALK       ;{{c009:cdcbbc}}  firmware function: kl rom walk

        call    initialise_memory_model;{{c00c:cd3ff5}} 
        jp      c,RESET_ENTRY     ;{{c00f:da0000}} ; reboot if not enough memory

        xor     a                 ;{{c012:af}} 
        ld      (program_line_redundant_spaces_flag_),a;{{c013:3200ac}} 

        ld      hl,version_string_message;{{c016:2133c0}}  startup message "BASIC 1.1"
        call    init_streams_and_display_ASCIIZ_string;{{c019:cd7dc3}} 

        call    zero_current_line_address;{{c01c:cdaade}} 
        call    clear_errors_and_set_resume_addr_to_current;{{c01f:cd37cb}} 
        call    REAL_init_random_number_generator;{{c022:cdbbbd}}  maths function - initialise random number generator?
        call    cancel_AUTO_mode  ;{{c025:cddec0}} 
        call    reset_basic       ;{{c028:cd45c1}} 
        ld      de,$00f0          ;{{c02b:11f000}}  DE = 240
        call    SYMBOL_AFTER      ;{{c02e:cde9f7}}  symbol after 240
        jr      REPL_Read_Eval_Print_Loop;{{c031:1825}} 

;;= version string message

version_string_message:           ;{{Addr=$c033 Data Calls/jump count: 0 Data use count: 1}}
        defb " BASIC 1.1",10,10,0 

;;=rsx name table
rsx_name_table:                   ;{{Addr=$c040 Data Calls/jump count: 0 Data use count: 1}}
        defb "BASI","C"+$80       ; |BASIC
        defb 0                    ;end of rsx name table




;;***ProgramEntry.asm
;;<< PROGRAM ENTRY ROUTINES
;;< REPL loop, EDIT, AUTO, NEW, CLEAR (INPUT)
;;========================================================================
;; command EDIT
command_EDIT:                     ;{{Addr=$c046 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_line_number_or_error;{{c046:cd48cf}} 
        ret     nz                ;{{c049:c0}} 

_command_edit_2:                  ;{{Addr=$c04a Code Calls/jump count: 1 Data use count: 0}}
        ld      sp,$c000          ;{{c04a:3100c0}} ##LIT##
        call    find_address_of_line_or_error;{{c04d:cd5ce8}} 
        call    detokenise_line_atHL_to_buffer;{{c050:cd54e2}} convert line to string (detokenise)

        call    edit_text_in_BASIC_input_area_and_display_new_line;{{c053:cd01cb}}  edit
        jr      c,_display_ready_message_22;{{c056:385f}}  (+$5f)

;;========================================
;;REPL Read Eval Print Loop
;;REPL = Read, Evaluate, Print, Loop
;;This is the command line!
REPL_Read_Eval_Print_Loop:        ;{{Addr=$c058 Code Calls/jump count: 10 Data use count: 0}}
        ld      sp,$c000          ;{{c058:3100c0}} ##LIT##
        call    _reset_basic_16   ;{{c05b:cd66c1}} 
        call    get_current_line_number;{{c05e:cdb5de}} 
        call    c,SOUND_HOLD      ;{{c061:dcb6bc}}  firmware function: sound hold
        call    ON_BREAK_CONT     ;{{c064:cdd0c4}}  ON BREAK CONT

        call    turn_display_on   ;{{c067:cdd0c3}} 
        ld      a,(program_protection_flag_);{{c06a:3a2cae}}  program protection flag
;; do a new
        or      a                 ;{{c06d:b7}} 
        call    nz,reset_basic    ;{{c06e:c445c1}} 

        ld      a,(ERR__Error_No) ;{{c071:3a90ad}} ; error number
        sub     $02               ;{{c074:d602}} 
        jr      nz,display_ready_message;{{c076:2009}}  (+$09)
        ld      (ERR__Error_No),a ;{{c078:3290ad}} 

        call    get_resume_line_number;{{c07b:cdaacb}} 
        ex      de,hl             ;{{c07e:eb}} 
        jr      c,_command_edit_2 ;{{c07f:38c9}}  (-$37)

;;=display ready message
display_ready_message:            ;{{Addr=$c081 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,ready_message  ;{{c081:21d7c0}}  "Ready" message
        call    output_ASCIIZ_string;{{c084:cd8bc3}} ; display 0 terminated string

;;-----------------------------------------------------------------

_display_ready_message_2:         ;{{Addr=$c087 Code Calls/jump count: 3 Data use count: 0}}
        call    zero_current_line_address;{{c087:cdaade}} 
_display_ready_message_3:         ;{{Addr=$c08a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(AUTO_active_flag_);{{c08a:3a01ac}}  AUTO active?
        or      a                 ;{{c08d:b7}} 
        jr      z,_display_ready_message_19;{{c08e:281f}}  (+$1f)

;;next AUTO line number
        call    next_AUTO_line_number;{{c090:cd0dc1}} 
        jr      nc,REPL_Read_Eval_Print_Loop;{{c093:30c3}}  (-$3d)

        call    skip_space_tab_or_line_feed;{{c095:cd4dde}}  skip space, lf or tab	
        call    convert_number_a  ;{{c098:cdcfee}} 
        jr      nc,_display_ready_message_16;{{c09b:300a}} 
        call    skip_space_tab_or_line_feed;{{c09d:cd4dde}}  skip space, lf or tab	
        or      a                 ;{{c0a0:b7}} 
        scf                       ;{{c0a1:37}} 
        call    z,find_address_of_line;{{c0a2:cc64e8}} 
        jr      nc,_display_ready_message_3;{{c0a5:30e3}}  (-$1d)
_display_ready_message_16:        ;{{Addr=$c0a7 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,cancel_AUTO_mode;{{c0a7:d4dec0}} 
        ld      hl,BASIC_input_area_for_lines_;{{c0aa:218aac}} 
        jr      _display_ready_message_22;{{c0ad:1808}}  (+$08)

;;-----------------------------------------------------------------

_display_ready_message_19:        ;{{Addr=$c0af Code Calls/jump count: 2 Data use count: 0}}
        call    input_text_to_BASIC_input_area;{{c0af:cdf9ca}}  edit
        jr      nc,_display_ready_message_19;{{c0b2:30fb}}  (-$05)
        call    output_new_line   ;{{c0b4:cd98c3}} ; new text line

;; either execute or edit/insert in program
_display_ready_message_22:        ;{{Addr=$c0b7 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{c0b7:cd4dde}}  skip space, lf or tab
        or      a                 ;{{c0ba:b7}} 
        jr      z,_display_ready_message_2;{{c0bb:28ca}}  (-$36) empty buffer - loop
        call    convert_number_a  ;{{c0bd:cdcfee}} 
        jr      nc,tokenise_and_execute;{{c0c0:300b}}  (+$0b) no line number so execute
        call    _function_instr_70;{{c0c2:cd4dfb}} 
        call    _convert_line_addresses_to_line_numbers_24;{{c0c5:cda5e7}} 
        call    _reset_basic_33   ;{{c0c8:cd8fc1}} 
        jr      _display_ready_message_2;{{c0cb:18ba}}  (-$46)

;;+-----------------------------------------------------------------
;;tokenise and execute
tokenise_and_execute:             ;{{Addr=$c0cd Code Calls/jump count: 1 Data use count: 0}}
        call    tokenise_a_BASIC_line;{{c0cd:cda4df}} 
        call    ON_BREAK_STOP     ;{{c0d0:cdd3c4}}  ON BREAK STOP
        dec     hl                ;{{c0d3:2b}} 
        jp      execute_line_atHL ;{{c0d4:c360de}} 

;;========================================================================
;; ready message
ready_message:                    ;{{Addr=$c0d7 Data Calls/jump count: 0 Data use count: 1}}
        defb "Ready",10,0         

;;========================================================================
;; cancel AUTO mode
cancel_AUTO_mode:                 ;{{Addr=$c0de Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{c0de:af}} 
        jr      set_auto_mode_B   ;{{c0df:1805}}  (+$05)

;;+------------------
;; set AUTO mode
set_AUTO_mode:                    ;{{Addr=$c0e1 Code Calls/jump count: 2 Data use count: 0}}
        ld      (AUTO_line_number),hl;{{c0e1:2202ac}} current auto mode
        ld      a,$ff             ;{{c0e4:3eff}} auto mode active

;;=set auto mode
;A=ff=active, A=0=inactive
set_auto_mode_B:                  ;{{Addr=$c0e6 Code Calls/jump count: 1 Data use count: 0}}
        ld      (AUTO_active_flag_),a;{{c0e6:3201ac}} current auto mode
        ret                       ;{{c0e9:c9}} 
  
 
;;==================================================================
;; command AUTO
command_AUTO:                     ;{{Addr=$c0ea Code Calls/jump count: 0 Data use count: 1}}
        ld      de,$000a          ;{{c0ea:110a00}}  default line number is 10
        jr      z,_command_auto_3 ;{{c0ed:2802}} no parameters

        cp      $2c               ;{{c0ef:fe2c}}  ',' no first parameter
_command_auto_3:                  ;{{Addr=$c0f1 Code Calls/jump count: 1 Data use count: 0}}
        call    nz,eval_line_number_or_error;{{c0f1:c448cf}} read initial line number, if given
        push    de                ;{{c0f4:d5}} 
        ld      de,$000a          ;{{c0f5:110a00}}  default increment is 10
        call    next_token_if_prev_is_comma;{{c0f8:cd41de}} 
        call    c,eval_line_number_or_error;{{c0fb:dc48cf}}  read increment if given
        call    syntax_error_if_not_02;{{c0fe:cd37de}} 
        ex      de,hl             ;{{c101:eb}} 
        ld      (AUTO_increment_step),hl;{{c102:2204ac}} AUTO increment step
        pop     hl                ;{{c105:e1}} 
        call    set_AUTO_mode     ;{{c106:cde1c0}} store line number to create or edit
        pop     bc                ;{{c109:c1}} 
        jp      _display_ready_message_2;{{c10a:c387c0}} 

;;=-----------------------------------------------------------------
;;next AUTO line number
next_AUTO_line_number:            ;{{Addr=$c10d Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(AUTO_line_number);{{c10d:2a02ac}} 
        ex      de,hl             ;{{c110:eb}} 
        push    de                ;{{c111:d5}} 
        call    detokenise_line_from_line_number;{{c112:cd38e2}} 
        call    cancel_AUTO_mode  ;{{c115:cddec0}} 
        call    edit_text_in_BASIC_input_area_and_display_new_line;{{c118:cd01cb}}  edit
        pop     de                ;{{c11b:d1}} 
        ret     nc                ;{{c11c:d0}} 
;;========================================================================

        push    hl                ;{{c11d:e5}} 
        ld      hl,(AUTO_increment_step);{{c11e:2a04ac}} AUTO increment step
        add     hl,de             ;{{c121:19}} 
        call    nc,set_AUTO_mode  ;{{c122:d4e1c0}} 
        pop     hl                ;{{c125:e1}} 
        scf                       ;{{c126:37}} 
        ret                       ;{{c127:c9}} 

;;========================================================================
;; command NEW
command_NEW:                      ;{{Addr=$c128 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{c128:c0}} 
        call    reset_basic       ;{{c129:cd45c1}} 
        jp      REPL_Read_Eval_Print_Loop;{{c12c:c358c0}} 

;;=============================================================================
;; command CLEAR, CLEAR INPUT

command_CLEAR_CLEAR_INPUT:        ;{{Addr=$c12f Code Calls/jump count: 0 Data use count: 1}}
        cp      $a3               ;{{c12f:fea3}}  token for "INPUT"
        jr      z,CLEAR_INPUT     ;{{c131:280c}}  CLEAR INPUT

        push    hl                ;{{c133:e5}} 
        call    _reset_basic_22   ;{{c134:cd78c1}} 
        call    _reset_basic_13   ;{{c137:cd5fc1}} 
        call    _reset_basic_33   ;{{c13a:cd8fc1}} 
        pop     hl                ;{{c13d:e1}} 
        ret                       ;{{c13e:c9}} 

;;========================================================================
;; CLEAR INPUT
CLEAR_INPUT:                      ;{{Addr=$c13f Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c13f:cd2cde}}  get next token skipping space
        jp      KM_FLUSH          ;{{c142:c33dbd}}  firmware function: km flush

;;========================================================================
;; reset basic
;; clear all memory and reset
reset_basic:                      ;{{Addr=$c145 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(address_of_start_of_ROM_lower_reserved_a);{{c145:2a62ae}} input buffer/start of BASIC memory
        ex      de,hl             ;{{c148:eb}} 

        ld      hl,(HIMEM_)       ;{{c149:2a5eae}}  HIMEM
        call    BC_equal_HL_minus_DE;{{c14c:cde4ff}}  BC = HL-DE
        ld      h,d               ;{{c14f:62}} 
        ld      l,e               ;{{c150:6b}} 
        inc     de                ;{{c151:13}} 
        xor     a                 ;{{c152:af}} 
        ld      (hl),a            ;{{c153:77}} 
        ldir                      ;{{c154:edb0}} 
        ld      (program_protection_flag_),a;{{c156:322cae}} 
        call    delete_program    ;{{c159:cdead5}} 
        call    _reset_basic_19   ;{{c15c:cd6fc1}} 
_reset_basic_13:                  ;{{Addr=$c15f Code Calls/jump count: 1 Data use count: 0}}
        call    close_input_and_output_streams;{{c15f:cd00d3}}  close input and output streams
_reset_basic_14:                  ;{{Addr=$c162 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{c162:af}} 
        call    SET_ANGLE_MODE    ;{{c163:cd97bd}}  maths: set angle mode


_reset_basic_16:                  ;{{Addr=$c166 Code Calls/jump count: 1 Data use count: 0}}
        call    get_string_stack_first_free_ptr;{{c166:cdccfb}}  string catenation
        call    clear_FN_params_data;{{c169:cd20da}} 
        jp      select_txt_stream_zero;{{c16c:c3a1c1}} 

;;-------------------------------------------------------------------

_reset_basic_19:                  ;{{Addr=$c16f Code Calls/jump count: 3 Data use count: 0}}
        call    command_TROFF     ;{{c16f:cdc5de}} ; TROFF
        call    cancel_AUTO_mode  ;{{c172:cddec0}} 
        call    _reset_basic_31   ;{{c175:cd89c1}} 
_reset_basic_22:                  ;{{Addr=$c178 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{c178:c5}} 
        push    hl                ;{{c179:e5}} 
        call    empty_strings_area;{{c17a:cd8cf6}} 
        call    delete_program    ;{{c17d:cdead5}} 
        call    defreal_a_to_z    ;{{c180:cd38d6}} 
        call    reset_variable_types_and_pointers;{{c183:cd4dea}} 
        pop     hl                ;{{c186:e1}} 
        pop     bc                ;{{c187:c1}} 
        ret                       ;{{c188:c9}} 

;;-----------------------------------------------------------------
_reset_basic_31:                  ;{{Addr=$c189 Code Calls/jump count: 2 Data use count: 0}}
        call    set_zone_13       ;{{c189:cd99f2}} 
        call    poss_clear_program_area;{{c18c:cd61e7}} ; ?

;;-----------------------------------------------------------------
_reset_basic_33:                  ;{{Addr=$c18f Code Calls/jump count: 7 Data use count: 0}}
        call    clear_error_handlers;{{c18f:cdaccc}} 
        call    clear_last_RUN_error_line_address;{{c192:cd7ecc}} 
        call    initialise_event_system;{{c195:cda3c9}} 
        call    prob_clear_execution_stack;{{c198:cd4ff6}} 
        call    clear_DEFFN_list_and_reset_variable_types_and_pointers;{{c19b:cd0ed6}} 
        jp      reset_READ_pointer;{{c19e:c3d4dc}} 



;;***Streams.asm
;;<< (TEXT) STREAM MANAGEMENT
;;=========================================
;;select txt stream zero
select_txt_stream_zero:           ;{{Addr=$c1a1 Code Calls/jump count: 4 Data use count: 0}}
        xor     a                 ;{{c1a1:af}} 
        call    swap_input_streams;{{c1a2:cdb3c1}} 
        xor     a                 ;{{c1a5:af}} 
;;=select txt stream
select_txt_stream:                ;{{Addr=$c1a6 Code Calls/jump count: 7 Data use count: 0}}
        push    hl                ;{{c1a6:e5}} 
        push    af                ;{{c1a7:f5}} 
        cp      $08               ;{{c1a8:fe08}} 
        call    c,TXT_STR_SELECT  ;{{c1aa:dcb4bb}}  firmware function: txt str select
        pop     af                ;{{c1ad:f1}} 
        ld      hl,current_output_stream_;{{c1ae:2106ac}} 
        jr      swap_stream_number_atHL;{{c1b1:1804}}  (+$04)

;;==========================================
;;swap input streams
swap_input_streams:               ;{{Addr=$c1b3 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{c1b3:e5}} 
        ld      hl,current_input_stream_;{{c1b4:2107ac}} 

;;=swap stream number atHL
swap_stream_number_atHL:          ;{{Addr=$c1b7 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c1b7:d5}} 
        ld      e,a               ;{{c1b8:5f}} 
        ld      a,(hl)            ;{{c1b9:7e}} 
        ld      (hl),e            ;{{c1ba:73}} 
        pop     de                ;{{c1bb:d1}} 
        pop     hl                ;{{c1bc:e1}} 
        ret                       ;{{c1bd:c9}} 

;;-----------------------------------------------------------------
;;=get output stream
get_output_stream:                ;{{Addr=$c1be Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(current_output_stream_);{{c1be:3a06ac}} 
        cp      $08               ;{{c1c1:fe08}} 
        ret                       ;{{c1c3:c9}} 

;;-----------------------------------------------------------------
;;=get input stream
;returns Carry clear if stream is on screen, Carry set if not on screen (i.e. a file)
get_input_stream:                 ;{{Addr=$c1c4 Code Calls/jump count: 7 Data use count: 0}}
        ld      a,(current_input_stream_);{{c1c4:3a07ac}} 
        cp      $09               ;{{c1c7:fe09}} 
        ret                       ;{{c1c9:c9}} 

;;-----------------------------------------------------------------
;;=eval and select txt stream
eval_and_select_txt_stream:       ;{{Addr=$c1ca Code Calls/jump count: 1 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1ca:cdfbc1}} 
        jr      select_txt_stream ;{{c1cd:18d7}}  (-$29)

;;=exec BC on evalled stream and swap back
exec_BC_on_evalled_stream_and_swap_back:;{{Addr=$c1cf Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1cf:cdfbc1}} 
        jr      exec_TOS_on_stream_and_swap_back;{{c1d2:1818}}  (+$18)

;;=swap both streams, exec TOS and swap back
swap_both_streams_exec_TOS_and_swap_back:;{{Addr=$c1d4 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1d4:cdfbc1}} 
        call    swap_input_streams;{{c1d7:cdb3c1}} 
        pop     bc                ;{{c1da:c1}} 
        push    af                ;{{c1db:f5}} 
        call    get_input_stream  ;{{c1dc:cdc4c1}} 
        call    exec_BC_on_stream_and_swap_back;{{c1df:cdedc1}} 
        pop     af                ;{{c1e2:f1}} 
        jr      swap_input_streams;{{c1e3:18ce}}  (-$32)


;;===============================================
;;=exec TOS on evalled stream and swap back
exec_TOS_on_evalled_stream_and_swap_back:;{{Addr=$c1e5 Code Calls/jump count: 8 Data use count: 0}}
        call    eval_and_validate_stream_number_if_present;{{c1e5:cdfbc1}} 
        cp      $08               ;{{c1e8:fe08}} 
        jr      nc,raise_Improper_Argument_error;{{c1ea:3031}}  (+$31)
;;=exec TOS on stream and swap back
exec_TOS_on_stream_and_swap_back: ;{{Addr=$c1ec Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{c1ec:c1}} 
;;=exec BC on stream and swap back
exec_BC_on_stream_and_swap_back:  ;{{Addr=$c1ed Code Calls/jump count: 1 Data use count: 0}}
        call    select_txt_stream ;{{c1ed:cda6c1}} 
        push    af                ;{{c1f0:f5}} 
        ld      a,(hl)            ;{{c1f1:7e}} 
        cp      $2c               ;{{c1f2:fe2c}}  ','
        call    JP_BC             ;{{c1f4:cdfcff}}  JP (BC)
        pop     af                ;{{c1f7:f1}} 
        jp      select_txt_stream ;{{c1f8:c3a6c1}} 

;;======================================
;;=eval and validate stream number if present
eval_and_validate_stream_number_if_present:;{{Addr=$c1fb Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{c1fb:7e}} 
        cp      $23               ;{{c1fc:fe23}}  #
        ld      a,$00             ;{{c1fe:3e00}} 
        ret     nz                ;{{c200:c0}} 

        call    eval_and_validate_stream_number;{{c201:cd0dc2}} 
        push    af                ;{{c204:f5}} 
        call    next_token_if_prev_is_comma;{{c205:cd41de}} 
        call    nc,syntax_error_if_not_02;{{c208:d437de}} 
        pop     af                ;{{c20b:f1}} 
        ret                       ;{{c20c:c9}} 

;;====================================
;;=eval and validate stream number
eval_and_validate_stream_number:  ;{{Addr=$c20d Code Calls/jump count: 3 Data use count: 0}}
        call    next_token_if_equals_inline_data_byte;{{c20d:cd25de}} 
        defb $23                  ;Inline token to test "#"

        ld      a,$0a             ;{{c211:3e0a}} 
;;=check byte value in range.
;; if not give "Improper Argument" error message
;; In: A = max value
;; Out: A = value if in range
check_byte_value_in_range:        ;{{Addr=$c213 Code Calls/jump count: 6 Data use count: 0}}
        push    bc                ;{{c213:c5}} 
        push    de                ;{{c214:d5}} 
        ld      b,a               ;{{c215:47}} 
        call    eval_expr_as_byte_or_error;{{c216:cdb8ce}}  get number and check it's less than 255 
        cp      b                 ;{{c219:b8}}  compare to value we want
        pop     de                ;{{c21a:d1}} 
        pop     bc                ;{{c21b:c1}} 
        ret     c                 ;{{c21c:d8}} ; return if less than value

;; greater than value
;;=raise Improper Argument error
raise_Improper_Argument_error:    ;{{Addr=$c21d Code Calls/jump count: 2 Data use count: 0}}
        jp      Error_Improper_Argument;{{c21d:c34dcb}}  Error: Improper Argument

;;========================================================================
;; check number is less than 2
check_number_is_less_than_2:      ;{{Addr=$c220 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,$02             ;{{c220:3e02}} 
        jr      check_byte_value_in_range;{{c222:18ef}}  check value is in range        





;;***Screen.asm
;;<< SCREEN HANDLING FUNCTIONS
;;========================================================================
;; command PEN

command_PEN:                      ;{{Addr=$c224 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c224:cde5c1}} 
        ld      bc,TXT_SET_PEN    ;{{c227:0190bb}}  firmware function: txt set pen
        call    nz,_command_paper_2;{{c22a:c43fc2}} 
        call    next_token_if_prev_is_comma;{{c22d:cd41de}} 
        ret     nc                ;{{c230:d0}} 
        call    check_number_is_less_than_2;{{c231:cd20c2}}  check number is less than 2
        ld      bc,TXT_SET_BACK   ;{{c234:019fbb}}  firmware function: txt set back
        jr      _command_paper_3  ;{{c237:1809}} 

;;========================================================================
;; command PAPER

command_PAPER:                    ;{{Addr=$c239 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c239:cde5c1}} 
        ld      bc,TXT_SET_PAPER  ;{{c23c:0196bb}}  firmware function: txt set paper
_command_paper_2:                 ;{{Addr=$c23f Code Calls/jump count: 1 Data use count: 0}}
        call    check_value_is_less_than_16;{{c23f:cd71c2}}  check parameter is less than 16

_command_paper_3:                 ;{{Addr=$c242 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c242:e5}} 
        call    JP_BC             ;{{c243:cdfcff}}  JP (BC)
        pop     hl                ;{{c246:e1}} 
        ret                       ;{{c247:c9}} 

;;=========================================================================
;; command BORDER

command_BORDER:                   ;{{Addr=$c248 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_one_or_two_numbers_less_than_32;{{c248:cd62c2}}  one or two numbers each less than 32
;; B,C = numbers which are the inks
        push    hl                ;{{c24b:e5}} 
        call    SCR_SET_BORDER    ;{{c24c:cd38bc}}  firmware function: scr set border
        pop     hl                ;{{c24f:e1}} 
        ret                       ;{{c250:c9}} 

;;=========================================================================
;; command INK

command_INK:                      ;{{Addr=$c251 Code Calls/jump count: 0 Data use count: 1}}
        call    check_value_is_less_than_16;{{c251:cd71c2}}  check parameter is less than 16
        push    af                ;{{c254:f5}} 
        call    next_token_if_comma;{{c255:cd15de}}  check for comma
        call    eval_one_or_two_numbers_less_than_32;{{c258:cd62c2}}  one or two numbers each less than 32

;; B,C = numbers which are the inks
        pop     af                ;{{c25b:f1}} 
        push    hl                ;{{c25c:e5}} 
        call    SCR_SET_INK       ;{{c25d:cd32bc}}  firmware function: scr set ink
        pop     hl                ;{{c260:e1}} 
        ret                       ;{{c261:c9}} 

;;=========================================================================
;; eval one or two numbers less than 32
;; used to get ink values
;;
;; first number in B, second number in C

eval_one_or_two_numbers_less_than_32:;{{Addr=$c262 Code Calls/jump count: 2 Data use count: 0}}
        call    _eval_one_or_two_numbers_less_than_32_4;{{c262:cd6ac2}} 
        ld      b,c               ;{{c265:41}} 
        call    next_token_if_prev_is_comma;{{c266:cd41de}} 
        ret     nc                ;{{c269:d0}} 

_eval_one_or_two_numbers_less_than_32_4:;{{Addr=$c26a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$20             ;{{c26a:3e20}} 
        call    check_byte_value_in_range;{{c26c:cd13c2}}  check value is in range
        ld      c,a               ;{{c26f:4f}} 
        ret                       ;{{c270:c9}} 

;;========================================================================
;; check value is less than 16
check_value_is_less_than_16:      ;{{Addr=$c271 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,$10             ;{{c271:3e10}} 
        jr      check_byte_value_in_range;{{c273:189e}}  check value is in range            

;;========================================================================
;; command MODE

command_MODE:                     ;{{Addr=$c275 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$03             ;{{c275:3e03}} 
        call    check_byte_value_in_range;{{c277:cd13c2}}  check value is in range
;; A = mode
        push    hl                ;{{c27a:e5}} 
        call    SCR_SET_MODE      ;{{c27b:cd0ebc}}  firmware function: scr set mode
        pop     hl                ;{{c27e:e1}} 
        ret                       ;{{c27f:c9}} 

;;=============================================================================
;; command CLS

command_CLS:                      ;{{Addr=$c280 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c280:cde5c1}} 
        push    hl                ;{{c283:e5}} 
        call    TXT_CLEAR_WINDOW  ;{{c284:cd6cbb}}  firmware function: txt clear window
        pop     hl                ;{{c287:e1}} 
        ret                       ;{{c288:c9}} 

;;=eval stream param, and exec TOS, and swap back
eval_stream_param_and_exec_TOS_and_swap_back:;{{Addr=$c289 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_validate_stream_number;{{c289:cd0dc2}} 
        cp      $08               ;{{c28c:fe08}} 
        jr      nc,raise_Improper_Argument_error;{{c28e:308d}}  (-$73)
;;=exec TOS on stream and swap back
exec_tos_on_stream_and_swap_back_B:;{{Addr=$c290 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{c290:f5}} 
        call    next_token_if_close_bracket;{{c291:cd1dde}}  check for close bracket
        pop     af                ;{{c294:f1}} 
        jp      exec_TOS_on_stream_and_swap_back;{{c295:c3ecc1}} 

;;========================================================================
;; function COPYCHR$

function_COPYCHR:                 ;{{Addr=$c298 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_stream_param_and_exec_TOS_and_swap_back;{{c298:cd89c2}} 
        call    TXT_RD_CHAR       ;{{c29b:cd60bb}}  firmware function: txt rd char
        jp      _function_chr_2   ;{{c29e:c378fa}} 

;;========================================================================
;; function VPOS
function_VPOS:                    ;{{Addr=$c2a1 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_stream_param_and_exec_TOS_and_swap_back;{{c2a1:cd89c2}} 
        push    hl                ;{{c2a4:e5}} 
        call    get_Y_cursor_position;{{c2a5:cdc7c2}}  get y cursor position
        jr      _function_pos_4   ;{{c2a8:180a}}  (+$0a)

;;========================================================================
;; function POS
function_POS:                     ;{{Addr=$c2aa Code Calls/jump count: 0 Data use count: 1}}
        call    eval_and_validate_stream_number;{{c2aa:cd0dc2}} 
        call    exec_tos_on_stream_and_swap_back_B;{{c2ad:cd90c2}} 
        push    hl                ;{{c2b0:e5}} 
        call    get_xpos_of_output_stream;{{c2b1:cdb9c2}} 
_function_pos_4:                  ;{{Addr=$c2b4 Code Calls/jump count: 1 Data use count: 0}}
        call    store_A_in_accumulator_as_INT;{{c2b4:cd32ff}} 
        pop     hl                ;{{c2b7:e1}} 
        ret                       ;{{c2b8:c9}} 

;;========================================================================
;;=get xpos of output stream
;stream can be stream, file or printer
get_xpos_of_output_stream:        ;{{Addr=$c2b9 Code Calls/jump count: 4 Data use count: 0}}
        call    get_output_stream ;{{c2b9:cdbec1}} 
        ld      a,(printer_stream_current_x_position_);{{c2bc:3a08ac}} 
        ret     z                 ;{{c2bf:c8}} 

        ld      a,(file_output_stream_current_line_position);{{c2c0:3a0aac}} 
        ret     nc                ;{{c2c3:d0}} 

        jp      get_x_cursor_position;{{c2c4:c3ecc3}} 

;;========================================================================
;; get Y cursor position
get_Y_cursor_position:            ;{{Addr=$c2c7 Code Calls/jump count: 2 Data use count: 0}}
        call    TXT_GET_CURSOR    ;{{c2c7:cd78bb}}  firmware function: txt get cursor
        call    TXT_VALIDATE      ;{{c2ca:cd87bb}}  firmware function: txt validate
        ld      a,l               ;{{c2cd:7d}} 
        ret                       ;{{c2ce:c9}} 

;;========================================================================
;;=pos is xpos in D in range
pos_is_xpos_in_D_in_range:        ;{{Addr=$c2cf Code Calls/jump count: 2 Data use count: 0}}
        call    get_output_stream ;{{c2cf:cdbec1}} 
        jr      z,poss_get_screen_width;{{c2d2:280d}}  (+$0d)
        ret     nc                ;{{c2d4:d0}} 

        push    de                ;{{c2d5:d5}} 
        push    hl                ;{{c2d6:e5}} 
        call    TXT_GET_WINDOW    ;{{c2d7:cd69bb}}  firmware function: txt get window
        ld      a,d               ;{{c2da:7a}} 
        sub     h                 ;{{c2db:94}} 
        inc     a                 ;{{c2dc:3c}} 
        pop     hl                ;{{c2dd:e1}} 
        pop     de                ;{{c2de:d1}} 
        scf                       ;{{c2df:37}} 
        ret                       ;{{c2e0:c9}} 

;;=poss get screen width
poss_get_screen_width:            ;{{Addr=$c2e1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(WIDTH_)        ;{{c2e1:3a09ac}} 
        cp      $ff               ;{{c2e4:feff}} 
        ret                       ;{{c2e6:c9}} 

;;=poss validate xpos in D
poss_validate_xpos_in_D:          ;{{Addr=$c2e7 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{c2e7:e5}} 
        ld      h,a               ;{{c2e8:67}} 
        call    pos_is_xpos_in_D_in_range;{{c2e9:cdcfc2}} 
        ccf                       ;{{c2ec:3f}} 
        jr      c,_poss_validate_xpos_in_d_15;{{c2ed:380e}}  (+$0e)
        ld      l,a               ;{{c2ef:6f}} 
        call    get_xpos_of_output_stream;{{c2f0:cdb9c2}} 
        dec     a                 ;{{c2f3:3d}} 
        scf                       ;{{c2f4:37}} 
        jr      z,_poss_validate_xpos_in_d_15;{{c2f5:2806}}  (+$06)
        add     a,h               ;{{c2f7:84}} 
        ccf                       ;{{c2f8:3f}} 
        jr      nc,_poss_validate_xpos_in_d_15;{{c2f9:3002}}  (+$02)
        dec     a                 ;{{c2fb:3d}} 
        cp      l                 ;{{c2fc:bd}} 
_poss_validate_xpos_in_d_15:      ;{{Addr=$c2fd Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{c2fd:e1}} 
        ret                       ;{{c2fe:c9}} 

;;========================================================================
;; command LOCATE

command_LOCATE:                   ;{{Addr=$c2ff Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c2ff:cde5c1}} 
        call    eval_two_params_minus_1_to_D_E;{{c302:cd51c3}} 
        push    hl                ;{{c305:e5}} 
        ex      de,hl             ;{{c306:eb}} 
        inc     h                 ;{{c307:24}} 
        inc     l                 ;{{c308:2c}} 
        call    TXT_SET_CURSOR    ;{{c309:cd75bb}}  firmware function: txt set cursor
        pop     hl                ;{{c30c:e1}} 
        ret                       ;{{c30d:c9}} 

;;========================================================================
;; command WINDOW, WINDOW SWAP
command_WINDOW_WINDOW_SWAP:       ;{{Addr=$c30e Code Calls/jump count: 0 Data use count: 1}}
        cp      $e7               ;{{c30e:fee7}} 
        jr      z,window_swap     ;{{c310:2816}}  (+$16)
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c312:cde5c1}} 
        call    eval_two_params_minus_1_to_D_E;{{c315:cd51c3}} 
        push    de                ;{{c318:d5}} 
        call    next_token_if_comma;{{c319:cd15de}}  check for comma
        call    eval_two_params_minus_1_to_D_E;{{c31c:cd51c3}} 
        ex      (sp),hl           ;{{c31f:e3}} 
        ld      a,d               ;{{c320:7a}} 
        ld      d,l               ;{{c321:55}} 
        ld      l,a               ;{{c322:6f}} 
        call    TXT_WIN_ENABLE    ;{{c323:cd66bb}}  firmware function: txt win enable
        pop     hl                ;{{c326:e1}} 
        ret                       ;{{c327:c9}} 

;;========================================================================
;;=window swap
window_swap:                      ;{{Addr=$c328 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c328:cd2cde}}  get next token skipping space
        call    eval_number_less_than_8;{{c32b:cd3ec3}}  get number less than 8
        ld      c,a               ;{{c32e:4f}} 
        call    next_token_if_prev_is_comma;{{c32f:cd41de}} 
        ld      a,$00             ;{{c332:3e00}} 
        call    c,eval_number_less_than_8;{{c334:dc3ec3}}  get number less than 8
        ld      b,a               ;{{c337:47}} 
        push    hl                ;{{c338:e5}} 
        call    TXT_SWAP_STREAMS  ;{{c339:cdb7bb}}  firmware function: txt swap streams
        pop     hl                ;{{c33c:e1}} 
        ret                       ;{{c33d:c9}} 

;;=eval number less than 8
eval_number_less_than_8:          ;{{Addr=$c33e Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$08             ;{{c33e:3e08}} 
        jp      check_byte_value_in_range;{{c340:c313c2}}  check value is in range

;;========================================================================
;; command TAG
command_TAG:                      ;{{Addr=$c343 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c343:cde5c1}} 
        ld      a,$ff             ;{{c346:3eff}} 
        jr      _command_tagoff_2 ;{{c348:1804}}  (+$04)

;;========================================================================
;; command TAGOFF
command_TAGOFF:                   ;{{Addr=$c34a Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c34a:cde5c1}} 
        xor     a                 ;{{c34d:af}} 
_command_tagoff_2:                ;{{Addr=$c34e Code Calls/jump count: 1 Data use count: 0}}
        jp      TXT_SET_GRAPHIC   ;{{c34e:c363bb}}  firmware function: txt set graphic

;;-------------------------------------------------------------------------
;;=eval two params minus 1 to D E
eval_two_params_minus_1_to_D_E:   ;{{Addr=$c351 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_param_minus_1_to_E;{{c351:cd58c3}} 
        ld      d,e               ;{{c354:53}} 
        call    next_token_if_comma;{{c355:cd15de}}  check for comma

;;--------------------------------------------------------------------------
;;=eval param minus 1 to E
eval_param_minus_1_to_E:          ;{{Addr=$c358 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c358:d5}} 
        call    eval_expr_as_int_less_than_256;{{c359:cdc3ce}} 
        pop     de                ;{{c35c:d1}} 
        ld      e,a               ;{{c35d:5f}} 
        dec     e                 ;{{c35e:1d}} 
        ret                       ;{{c35f:c9}} 

;;========================================================================
;; command CURSOR

command_CURSOR:                   ;{{Addr=$c360 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_TOS_on_evalled_stream_and_swap_back;{{c360:cde5c1}} 
        jr      z,_command_cursor_6;{{c363:280a}}  (+$0a)
        call    check_number_is_less_than_2;{{c365:cd20c2}}  check number is less than 2
        or      a                 ;{{c368:b7}} 
        call    z,TXT_CUR_OFF     ;{{c369:cc84bb}}  firmware function: txt cur off
        call    nz,TXT_CUR_ON     ;{{c36c:c481bb}}  firmware function: txt cur on
_command_cursor_6:                ;{{Addr=$c36f Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c36f:cd41de}} 
        ret     nc                ;{{c372:d0}} 

        call    check_number_is_less_than_2;{{c373:cd20c2}}  check number is less than 2
        or      a                 ;{{c376:b7}} 
        jp      z,TXT_CUR_DISABLE ;{{c377:ca7ebb}}  firmware function: txt cur disable
        jp      TXT_CUR_ENABLE    ;{{c37a:c37bbb}}  firmware function: txt cur enable





;;***StreamIO.asm
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




;;***Keyboard.asm
;;<< LOW LEVEL KEYBOARD HANDLING
;;< including BREAK key handler
;;=======================================================================================
;;jp km read char
jp_km_read_char:                  ;{{Addr=$c46f Code Calls/jump count: 1 Data use count: 0}}
        jp      KM_READ_CHAR      ;{{c46f:c309bb}}  firmware function: km read char

;;=======================================================================================
;;test for break key
test_for_break_key:               ;{{Addr=$c472 Code Calls/jump count: 2 Data use count: 0}}
        call    KM_READ_CHAR      ;{{c472:cd09bb}}  firmware function: km read char
        ret     nc                ;{{c475:d0}} 
        cp      $fc               ;{{c476:fefc}} Break?
        ret     nz                ;{{c478:c0}} 
        call    break_pause       ;{{c479:cda1c4}}  key
        jp      c,unknown_execution_error;{{c47c:da3ecc}} 

;;=arm break handler
arm_break_handler:                ;{{Addr=$c47f Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{c47f:e5}} 
;;=arm break handler
arm_break_handler_B:              ;{{Addr=$c480 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{c480:c5}} 
        push    de                ;{{c481:d5}} 
        ld      de,break_handling_routine;{{c482:1192c4}} ##LABEL##
        ld      c,$fd             ;{{c485:0efd}} ROM select address for break handling routine
        ld      a,(ON_BREAK_flag_);{{c487:3a0bac}} &00=ON BREAK CONTINUE, else ON BREAK STOP
        or      a                 ;{{c48a:b7}} 
        call    nz,KM_ARM_BREAK   ;{{c48b:c445bb}}  firmware function: km arm break
        pop     de                ;{{c48e:d1}} 
        pop     bc                ;{{c48f:c1}} 
        pop     hl                ;{{c490:e1}} 
        ret                       ;{{c491:c9}} 

;;=======================================================================================
;;break handling routine
;Called from firmware break handler
break_handling_routine:           ;{{Addr=$c492 Code Calls/jump count: 1 Data use count: 1}}
        call    KM_READ_CHAR      ;{{c492:cd09bb}}  firmware function: km read char
        jr      nc,_break_handling_routine_4;{{c495:3004}}  (+$04) No key available  
        cp      $ef               ;{{c497:feef}}  
        jr      nz,break_handling_routine;{{c499:20f7}}  (-$09) Loop until $ef. Code for break released?

_break_handling_routine_4:        ;{{Addr=$c49b Code Calls/jump count: 1 Data use count: 0}}
        call    break_pause       ;{{c49b:cda1c4}}  wait for second break, or resume
        jp      do_ON_BREAK       ;{{c49e:c3f2c8}} 

;;=======================================================================================
;;=break pause
;Wait for second break key (break)
;or any other key (continue execution)
break_pause:                      ;{{Addr=$c4a1 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{c4a1:c5}} 
        push    de                ;{{c4a2:d5}} 
        push    hl                ;{{c4a3:e5}} 
        call    SOUND_HOLD        ;{{c4a4:cdb6bc}}  firmware function: sound hold
        push    af                ;{{c4a7:f5}} 
        call    TXT_ASK_STATE     ;{{c4a8:cd40bd}}  firmware function: txt ask state
        ld      b,a               ;{{c4ab:47}} 
        call    TXT_CUR_ON        ;{{c4ac:cd81bb}}  firmware function: txt cur on
_break_pause_8:                   ;{{Addr=$c4af Code Calls/jump count: 1 Data use count: 0}}
        call    KM_WAIT_CHAR      ;{{c4af:cd06bb}}  firmware function: km wait char
        cp      $ef               ;{{c4b2:feef}} token for '='
        jr      z,_break_pause_8  ;{{c4b4:28f9}}  (-$07)
        bit     1,b               ;{{c4b6:cb48}} 
        call    nz,TXT_CUR_OFF    ;{{c4b8:c484bb}}  firmware function: txt cur off
        cp      $fc               ;{{c4bb:fefc}} 
        scf                       ;{{c4bd:37}} 
        jr      z,_break_pause_22 ;{{c4be:280b}}  (+$0b)
        cp      $20               ;{{c4c0:fe20}}  ' ' 
        call    nz,KM_CHAR_RETURN ;{{c4c2:c40cbb}}  firmware function: km char return
        pop     af                ;{{c4c5:f1}} 
        push    af                ;{{c4c6:f5}} 
        call    c,SOUND_CONTINUE  ;{{c4c7:dcb9bc}}  firmware function: sound continue
        or      a                 ;{{c4ca:b7}} 
_break_pause_22:                  ;{{Addr=$c4cb Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c4cb:e1}} 
        pop     hl                ;{{c4cc:e1}} 
        pop     de                ;{{c4cd:d1}} 
        pop     bc                ;{{c4ce:c1}} 
        ret                       ;{{c4cf:c9}} 

;;========================================================================
;; ON BREAK CONT
ON_BREAK_CONT:                    ;{{Addr=$c4d0 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{c4d0:af}} 
        jr      _on_break_stop_1  ;{{c4d1:1802}}  (+$02)

;;========================================================================
;; ON BREAK STOP
ON_BREAK_STOP:                    ;{{Addr=$c4d3 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$ff             ;{{c4d3:3eff}} 
;;------------------------------------------------------------------------
_on_break_stop_1:                 ;{{Addr=$c4d5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ON_BREAK_flag_),a;{{c4d5:320bac}} 
        push    hl                ;{{c4d8:e5}} 
        call    KM_DISARM_BREAK   ;{{c4d9:cd48bb}}  firmware function: km disarm break
        jr      arm_break_handler_B;{{c4dc:18a2}}  (-$5e)




;;***Graphics.asm
;;<< GRAPHICS FUNCTIONS
;;========================================================================
;; command ORIGIN

command_ORIGIN:                   ;{{Addr=$c4de Code Calls/jump count: 0 Data use count: 1}}
        call    eval_two_int_params;{{c4de:cd8cc5}} params x,y
        push    bc                ;{{c4e1:c5}} 
        push    de                ;{{c4e2:d5}} 
        call    next_token_if_prev_is_comma;{{c4e3:cd41de}} 
        jr      nc,_command_origin_18;{{c4e6:3017}}  (+$17) only two params
        call    eval_two_int_params;{{c4e8:cd8cc5}} params left, right
        push    bc                ;{{c4eb:c5}} 
        push    de                ;{{c4ec:d5}} 
        call    next_token_if_comma;{{c4ed:cd15de}}  check for comma
        call    eval_two_int_params;{{c4f0:cd8cc5}} params top,bottom
        push    bc                ;{{c4f3:c5}} 
        ex      (sp),hl           ;{{c4f4:e3}} 
        call    GRA_WIN_HEIGHT    ;{{c4f5:cdd2bb}}  firmware function: gra win height
        pop     hl                ;{{c4f8:e1}} 
        pop     de                ;{{c4f9:d1}} 
        ex      (sp),hl           ;{{c4fa:e3}} 
        call    GRA_WIN_WIDTH     ;{{c4fb:cdcfbb}}  firmware function: gra win width
        pop     hl                ;{{c4fe:e1}} 
_command_origin_18:               ;{{Addr=$c4ff Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{c4ff:d1}} 
        ex      (sp),hl           ;{{c500:e3}} 
        call    GRA_SET_ORIGIN    ;{{c501:cdc9bb}}  firmware function: gra set origin
        pop     hl                ;{{c504:e1}} 
        ret                       ;{{c505:c9}} 

;;=============================================================================
;; command CLG

command_CLG:                      ;{{Addr=$c506 Code Calls/jump count: 0 Data use count: 1}}
        call    is_next_02        ;{{c506:cd3dde}} 
        call    nc,validate_and_set_graphics_paper;{{c509:d4b4c5}} 
        push    hl                ;{{c50c:e5}} 
        call    GRA_CLEAR_WINDOW  ;{{c50d:cddbbb}}  firmware function: GRA CLEAR WINDOW
        pop     hl                ;{{c510:e1}} 
        ret                       ;{{c511:c9}} 

;;========================================================================
;; command FILL
command_FILL:                     ;{{Addr=$c512 Code Calls/jump count: 0 Data use count: 1}}
        call    check_value_is_less_than_16;{{c512:cd71c2}}  check parameter is less than 16
        push    hl                ;{{c515:e5}} 
        push    af                ;{{c516:f5}} 
        call    _function_fre_6   ;{{c517:cd64fc}} (free up?) and calc free memory?
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{c51a:cdfcf6}} 
        ld      bc,$001d          ;{{c51d:011d00}} 
        call    compare_HL_BC     ;{{c520:cddeff}}  HL=BC?
        ld      a,$07             ;{{c523:3e07}} Memory full error
        jp      c,raise_error     ;{{c525:da55cb}} 
        ex      de,hl             ;{{c528:eb}} 
        pop     af                ;{{c529:f1}} 
        call    GRA_FILL          ;{{c52a:cd52bd}}  firmware function: GRA FILL
        pop     hl                ;{{c52d:e1}} 
        ret                       ;{{c52e:c9}} 

;;========================================================================
;; command MOVE
command_MOVE:                     ;{{Addr=$c52f Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_MOVE_ABSOLUTE;{{c52f:01c0bb}}  firmware function: gra move absolute
        jr      plotdraw_general_function;{{c532:1817}} 

;;========================================================================
;; command MOVER
command_MOVER:                    ;{{Addr=$c534 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_MOVE_RELATIVE;{{c534:01c3bb}}  firmware function: gra move relative
        jr      plotdraw_general_function;{{c537:1812}} 

;;========================================================================
;; command DRAW
command_DRAW:                     ;{{Addr=$c539 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_LlNE_ABSOLUTE;{{c539:01f6bb}}  firmware function: gra line absolute
        jr      plotdraw_general_function;{{c53c:180d}} 

;;========================================================================
;; command DRAWR
command_DRAWR:                    ;{{Addr=$c53e Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_LINE_RELATIVE;{{c53e:01f9bb}}  firmware function: gra line relative
        jr      plotdraw_general_function;{{c541:1808}} 

;;========================================================================
;; command PLOT
command_PLOT:                     ;{{Addr=$c543 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_PLOT_ABSOLUTE;{{c543:01eabb}}  firmware function: gra plot absolute
        jr      plotdraw_general_function;{{c546:1803}} 

;;========================================================================
;; command PLOTR
command_PLOTR:                    ;{{Addr=$c548 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_PLOT_RELATIVE;{{c548:01edbb}}  firmware function: gra plot relative

;;+------------------------------------------------------------------------
;; plot/draw general function
;;reads parameters and calls the address in BC to do the actual function
plotdraw_general_function:        ;{{Addr=$c54b Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{c54b:c5}} 
        call    eval_two_int_params;{{c54c:cd8cc5}} 
        call    next_token_if_prev_is_comma;{{c54f:cd41de}} 
        jr      nc,_plotdraw_general_function_6;{{c552:3005}}  (+$05)
        cp      $2c               ;{{c554:fe2c}}  ','
        call    nz,validate_and_set_graphics_pen;{{c556:c4bac5}} 

_plotdraw_general_function_6:     ;{{Addr=$c559 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c559:cd41de}} 
        jr      nc,_plotdraw_general_function_13;{{c55c:300a}}  (+$0a)
        ld      a,$04             ;{{c55e:3e04}} 
        call    check_byte_value_in_range;{{c560:cd13c2}}  check value is in range
        push    hl                ;{{c563:e5}} 
        call    SCR_ACCESS        ;{{c564:cd59bc}}  firmware function: scr access 
        pop     hl                ;{{c567:e1}} 

_plotdraw_general_function_13:    ;{{Addr=$c568 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{c568:e3}} 
        push    bc                ;{{c569:c5}} 
        ex      (sp),hl           ;{{c56a:e3}} 
        pop     bc                ;{{c56b:c1}} 
        call    JP_BC             ;{{c56c:cdfcff}}  JP (BC)
        pop     hl                ;{{c56f:e1}} 
        ret                       ;{{c570:c9}} 

;;========================================================================
;; function TEST
function_TEST:                    ;{{Addr=$c571 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_TEST_ABSOLUTE;{{c571:01f0bb}}  firmware function: GRA TEST ABSOLUTE
        jr      _function_testr_1 ;{{c574:1803}}  

;;========================================================================
;; function TESTR
function_TESTR:                   ;{{Addr=$c576 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,GRA_TEST_RELATIVE;{{c576:01f3bb}}  firmware function: GRA TEST RELATIVE
;;------------------------------------------------------------------------
_function_testr_1:                ;{{Addr=$c579 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{c579:c5}} 
        call    eval_two_int_params;{{c57a:cd8cc5}} 
        call    next_token_if_close_bracket;{{c57d:cd1dde}}  check for close bracket
        ex      (sp),hl           ;{{c580:e3}} 
        push    bc                ;{{c581:c5}} 
        ex      (sp),hl           ;{{c582:e3}} 
        pop     bc                ;{{c583:c1}} 
        call    JP_BC             ;{{c584:cdfcff}}  JP (BC)
        call    store_A_in_accumulator_as_INT;{{c587:cd32ff}} 
        pop     hl                ;{{c58a:e1}} 
        ret                       ;{{c58b:c9}} 
;;------------------------------------------------------------------------
;;=eval two int params
eval_two_int_params:              ;{{Addr=$c58c Code Calls/jump count: 5 Data use count: 0}}
        call    eval_expr_as_int  ;{{c58c:cdd8ce}}  get number
        push    de                ;{{c58f:d5}} 
        call    next_token_if_comma;{{c590:cd15de}}  check for comma
        call    eval_expr_as_int  ;{{c593:cdd8ce}}  get number
        ld      b,d               ;{{c596:42}} 
        ld      c,e               ;{{c597:4b}} 
        pop     de                ;{{c598:d1}} 
        ret                       ;{{c599:c9}} 

;;========================================================================
;; command GRAPHICS PAPER / GRAPHICS PEN and set graphics draw mode
command_GRAPHICS_PAPER__GRAPHICS_PEN_and_set_graphics_draw_mode:;{{Addr=$c59a Code Calls/jump count: 0 Data use count: 1}}
        cp      $ba               ;{{c59a:feba}}  token for "PAPER"
        jr      z,eval_and_set_graphics_paper;{{c59c:2813}}  set graphics paper
      
        call    next_token_if_equals_inline_data_byte;{{c59e:cd25de}} 
        defb $bb                  ; token for "PEN"
        cp      $2c               ;{{c5a2:fe2c}}  ','
        call    nz,validate_and_set_graphics_pen;{{c5a4:c4bac5}}  set graphics pen

        call    next_token_if_prev_is_comma;{{c5a7:cd41de}} 
        ret     nc                ;{{c5aa:d0}} 

;;=validate and set graphics background mode
        call    check_number_is_less_than_2;{{c5ab:cd20c2}}  check number is less than 2
        jp      GRA_SET_BACK      ;{{c5ae:c346bd}}  firmware function: GRA SET BACK

;;=eval and set graphics paper
eval_and_set_graphics_paper:      ;{{Addr=$c5b1 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c5b1:cd2cde}}  get next token skipping space
;;=validate and set graphics paper
validate_and_set_graphics_paper:  ;{{Addr=$c5b4 Code Calls/jump count: 1 Data use count: 0}}
        call    check_value_is_less_than_16;{{c5b4:cd71c2}}  check parameter is less than 16
        jp      GRA_SET_PAPER     ;{{c5b7:c3e4bb}}  firmware function: GRA SET PAPER	

;;=validate and set graphics pen
validate_and_set_graphics_pen:    ;{{Addr=$c5ba Code Calls/jump count: 2 Data use count: 0}}
        call    check_value_is_less_than_16;{{c5ba:cd71c2}}  check parameter is less than 16
        jp      GRA_SET_PEN       ;{{c5bd:c3debb}}  firmware function: GRA SET PEN

;;========================================================================
;; command MASK

command_MASK:                     ;{{Addr=$c5c0 Code Calls/jump count: 0 Data use count: 1}}
        cp      $2c               ;{{c5c0:fe2c}}  ','
        jr      z,_command_mask_4 ;{{c5c2:2806}}  

        call    eval_expr_as_byte_or_error;{{c5c4:cdb8ce}}  get number and check it's less than 255 
        call    GRA_SET_LINE_MASK ;{{c5c7:cd4cbd}}  firmware function: GRA SET LINE MASK	

_command_mask_4:                  ;{{Addr=$c5ca Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{c5ca:cd41de}} 
        ret     nc                ;{{c5cd:d0}} 

        call    check_number_is_less_than_2;{{c5ce:cd20c2}}  check number is less than 2
        jp      GRA_SET_FIRST     ;{{c5d1:c349bd}}  firmware function: GRA SET FIRST





;;***ControlFlow.asm
;;<< CONTROL FLOW
;;< FOR, IF, GOTO, GOSUB, WHILE
;;========================================================================

;; command FOR

command_FOR:                      ;{{Addr=$c5d4 Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_or_alloc_FOR_var;{{c5d4:cdecd6}} 
        push    hl                ;{{c5d7:e5}} 
        push    bc                ;{{c5d8:c5}} 
        push    de                ;{{c5d9:d5}} 
        call    find_matching_NEXT;{{c5da:cd76ca}} 
        ld      (address_of_colon_or_line_end_byte_after_),hl;{{c5dd:2212ac}} 
        push    de                ;{{c5e0:d5}} 
        push    hl                ;{{c5e1:e5}} 
        ex      de,hl             ;{{c5e2:eb}} 
        call    get_execution_stack_data;{{c5e3:cdd9c6}} 
        call    z,set_execution_stack_next_free_ptr_and_its_cache;{{c5e6:cc5df6}} 
        pop     hl                ;{{c5e9:e1}} 
        call    is_next_02        ;{{c5ea:cd3dde}} 
        ld      de,$0000          ;{{c5ed:110000}} ##LIT##
        call    nc,parse_and_find_or_create_a_var;{{c5f0:d4bfd6}} 
        ld      b,h               ;{{c5f3:44}} 
        ld      c,l               ;{{c5f4:4d}} 
        pop     hl                ;{{c5f5:e1}} 
        ex      (sp),hl           ;{{c5f6:e3}} 
        ld      a,d               ;{{c5f7:7a}} 
        or      e                 ;{{c5f8:b3}} 
        call    nz,compare_HL_DE  ;{{c5f9:c4d8ff}}  HL=DE?
        jp      nz,raise_Unexpected_NEXT;{{c5fc:c29ec6}} 

        ex      de,hl             ;{{c5ff:eb}} 
        call    get_current_line_address;{{c600:cdb1de}} 
        ex      (sp),hl           ;{{c603:e3}} 
        call    set_current_line_address;{{c604:cdadde}} 
        pop     hl                ;{{c607:e1}} 
        pop     af                ;{{c608:f1}} 
        ex      (sp),hl           ;{{c609:e3}} 
        push    de                ;{{c60a:d5}} 
        push    bc                ;{{c60b:c5}} 
        push    hl                ;{{c60c:e5}} 
        ld      bc,$1605          ;{{c60d:010516}} 
        cp      c                 ;{{c610:b9}} 
        jr      z,_command_for_40 ;{{c611:2809}}  (+$09)

        ld      bc,$1002          ;{{c613:010210}} B=bytes to allocate on execution stack. C=int variable type
        cp      c                 ;{{c616:b9}} 
        ld      a,$0d             ;{{c617:3e0d}} Type mismatch error
        jp      nz,raise_error    ;{{c619:c255cb}} 

_command_for_40:                  ;{{Addr=$c61c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{c61c:78}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c61d:cd72f6}} 
        ld      (hl),e            ;{{c620:73}} 
        inc     hl                ;{{c621:23}} 
        ld      (hl),d            ;{{c622:72}} 
        inc     hl                ;{{c623:23}} 
        ex      (sp),hl           ;{{c624:e3}} 

        call    next_token_if_equals_sign;{{c625:cd21de}} test for "=" after var name
        call    eval_expression   ;{{c628:cd62cf}} Get initial value
        ld      a,c               ;{{c62b:79}} 
        call    convert_accumulator_to_type_in_A;{{c62c:cdfffe}} 
        push    hl                ;{{c62f:e5}} 
        ld      hl,FOR_start_value_;{{c630:210dac}} 
        call    copy_numeric_accumulator_to_atHL;{{c633:cd83ff}} 
        pop     hl                ;{{c636:e1}} 

        call    next_token_if_equals_inline_data_byte;{{c637:cd25de}} 
        defb $ec                  ;Inline token to test "TO"
        call    eval_expression   ;{{c6eb:cd62cf}} Read to value
        ex      (sp),hl           ;{{c63e:e3}} 
        ld      a,c               ;{{c63f:79}} 
        call    convert_accumulator_to_type_in_A;{{c640:cdfffe}} 
        call    copy_numeric_accumulator_to_atHL;{{c643:cd83ff}} 
        ex      de,hl             ;{{c646:eb}} 
        ex      (sp),hl           ;{{c647:e3}} 
        ex      de,hl             ;{{c648:eb}} 

        ld      hl,$0001          ;{{c649:210100}} Default step to 1
        call    store_HL_in_accumulator_as_INT;{{c64c:cd35ff}} 
        ex      de,hl             ;{{c64f:eb}} 
        ld      a,(hl)            ;{{c650:7e}} 
        cp      $e6               ;{{c651:fee6}} STEP token
        jr      nz,_command_for_73;{{c653:2006}}  (+$06)

        call    get_next_token_skipping_space;{{c655:cd2cde}}  get next token skipping space
        call    eval_expression   ;{{c658:cd62cf}} Step value

_command_for_73:                  ;{{Addr=$c65b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{c65b:79}} 
        call    convert_accumulator_to_type_in_A;{{c65c:cdfffe}} 
        ex      (sp),hl           ;{{c65f:e3}} 
        call    copy_numeric_accumulator_to_atHL;{{c660:cd83ff}} 
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c663:cdc4fd}} 
        ex      de,hl             ;{{c666:eb}} 
        ld      (hl),a            ;{{c667:77}} 
        inc     hl                ;{{c668:23}} 
        ex      de,hl             ;{{c669:eb}} 
        pop     hl                ;{{c66a:e1}} 
        call    syntax_error_if_not_02;{{c66b:cd37de}} Validate step is an INT
        ex      de,hl             ;{{c66e:eb}} 
        ld      (hl),e            ;{{c66f:73}} 
        inc     hl                ;{{c670:23}} 
        ld      (hl),d            ;{{c671:72}} 
        inc     hl                ;{{c672:23}} 
        ex      de,hl             ;{{c673:eb}} 

        call    get_current_line_address;{{c674:cdb1de}} Address of current line (for NEXT to jump to)
        ex      de,hl             ;{{c677:eb}} 
        ld      (hl),e            ;{{c678:73}} 
        inc     hl                ;{{c679:23}} 
        ld      (hl),d            ;{{c67a:72}} 
        inc     hl                ;{{c67b:23}} 
        pop     de                ;{{c67c:d1}} 
        ld      (hl),e            ;{{c67d:73}} 
        inc     hl                ;{{c67e:23}} 
        ld      (hl),d            ;{{c67f:72}} 
        inc     hl                ;{{c680:23}} 
        ld      de,(address_of_colon_or_line_end_byte_after_);{{c681:ed5b12ac}} 
        ld      (hl),e            ;{{c685:73}} 
        inc     hl                ;{{c686:23}} 
        ld      (hl),d            ;{{c687:72}} 
        inc     hl                ;{{c688:23}} 
        ld      (hl),b            ;{{c689:70}} 
        pop     de                ;{{c68a:d1}} 

        ld      hl,FOR_start_value_;{{c68b:210dac}} 
        call    copy_value_atHL_to_atDE_accumulator_type;{{c68e:cd87ff}} 
        xor     a                 ;{{c691:af}} 
        ld      (FORNEXT_flag_),a ;{{c692:320cac}} &00=NEXT not yet used
        pop     hl                ;{{c695:e1}} 
        call    set_current_line_address;{{c696:cdadde}} 
        ld      hl,(address_of_colon_or_line_end_byte_after_);{{c699:2a12ac}} 
        jr      _command_next_2   ;{{c69c:1809}}  (+$09)

;;=raise Unexpected NEXT
raise_Unexpected_NEXT:            ;{{Addr=$c69e Code Calls/jump count: 2 Data use count: 0}}
        call    byte_following_call_is_error_code;{{c69e:cd45cb}} 
        defb $01                  ;Inline error code: Unexpected NEXT

;;========================================================================
;; command NEXT
command_NEXT:                     ;{{Addr=$c6a2 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$ff             ;{{c6a2:3eff}} 
        ld      (FORNEXT_flag_),a ;{{c6a4:320cac}} &ff=NEXT has been used
_command_next_2:                  ;{{Addr=$c6a7 Code Calls/jump count: 2 Data use count: 0}}
        ex      de,hl             ;{{c6a7:eb}} 
        call    get_execution_stack_data;{{c6a8:cdd9c6}} 
        jr      nz,raise_Unexpected_NEXT;{{c6ab:20f1}}  (-$0f)

        ex      de,hl             ;{{c6ad:eb}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c6ae:cd5df6}} 
        ex      de,hl             ;{{c6b1:eb}} 
        push    hl                ;{{c6b2:e5}} 
        call    update_and_test_FOR_loop_counter;{{c6b3:cd02c7}} 
        jr      z,for_loop_done   ;{{c6b6:280f}}  (+$0f)

;;Go to end of for statement
        pop     af                ;{{c6b8:f1}} 
        inc     hl                ;{{c6b9:23}} 
        ld      e,(hl)            ;{{c6ba:5e}} 
        inc     hl                ;{{c6bb:23}} 
        ld      d,(hl)            ;{{c6bc:56}} 
        inc     hl                ;{{c6bd:23}} 
        ld      a,(hl)            ;{{c6be:7e}} 
        inc     hl                ;{{c6bf:23}} 
        ld      h,(hl)            ;{{c6c0:66}} 
        ld      l,a               ;{{c6c1:6f}} 
        call    set_current_line_address;{{c6c2:cdadde}} 
        ex      de,hl             ;{{c6c5:eb}} 
        ret                       ;{{c6c6:c9}} 

;;=for loop done
;remove data from execution stack
for_loop_done:                    ;{{Addr=$c6c7 Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,$0005          ;{{c6c7:010500}} 
        add     hl,bc             ;{{c6ca:09}} 
        ld      e,(hl)            ;{{c6cb:5e}} 
        inc     hl                ;{{c6cc:23}} 
        ld      d,(hl)            ;{{c6cd:56}} 
        pop     hl                ;{{c6ce:e1}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c6cf:cd5df6}} 
        ex      de,hl             ;{{c6d2:eb}} 
        call    next_token_if_prev_is_comma;{{c6d3:cd41de}} Test for another NEXT variable
        jr      c,_command_next_2 ;{{c6d6:38cf}}  (-$31) if so, process it
        ret                       ;{{c6d8:c9}} 

;;=get execution stack data
get_execution_stack_data:         ;{{Addr=$c6d9 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c6d9:2a6fb0}} 
_get_execution_stack_data_1:      ;{{Addr=$c6dc Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c6dc:e5}} 
        dec     hl                ;{{c6dd:2b}} 
        ld      b,(hl)            ;{{c6de:46}} 
        inc     hl                ;{{c6df:23}} 
        ld      a,l               ;{{c6e0:7d}} 
        sub     b                 ;{{c6e1:90}} 
        ld      l,a               ;{{c6e2:6f}} 
        sbc     a,a               ;{{c6e3:9f}} 
        add     a,h               ;{{c6e4:84}} 
        ld      h,a               ;{{c6e5:67}} 
        ex      (sp),hl           ;{{c6e6:e3}} 
        ld      a,b               ;{{c6e7:78}} 
        cp      $07               ;{{c6e8:fe07}} 
        jr      c,_get_execution_stack_data_26;{{c6ea:380f}}  (+$0f)
        jr      nz,_get_execution_stack_data_16;{{c6ec:2000}}  (+$00)
_get_execution_stack_data_16:     ;{{Addr=$c6ee Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c6ee:e5}} 
        dec     hl                ;{{c6ef:2b}} 
        dec     hl                ;{{c6f0:2b}} 
        ld      a,(hl)            ;{{c6f1:7e}} 
        dec     hl                ;{{c6f2:2b}} 
        ld      l,(hl)            ;{{c6f3:6e}} 
        ld      h,a               ;{{c6f4:67}} 
        call    compare_HL_DE     ;{{c6f5:cdd8ff}}  HL=DE?
        pop     hl                ;{{c6f8:e1}} 
        jr      nz,_get_execution_stack_data_30;{{c6f9:2004}}  (+$04)
_get_execution_stack_data_26:     ;{{Addr=$c6fb Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c6fb:eb}} 
        pop     hl                ;{{c6fc:e1}} 
        ld      a,b               ;{{c6fd:78}} 
        ret                       ;{{c6fe:c9}} 

_get_execution_stack_data_30:     ;{{Addr=$c6ff Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c6ff:e1}} 
        jr      _get_execution_stack_data_1;{{c700:18da}}  (-$26)

;;=update and test FOR loop counter
update_and_test_FOR_loop_counter: ;{{Addr=$c702 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{c702:5e}} 
        inc     hl                ;{{c703:23}} 
        ld      d,(hl)            ;{{c704:56}} 
        inc     hl                ;{{c705:23}} 
        push    hl                ;{{c706:e5}} 
        cp      $10               ;{{c707:fe10}} Alternative loop counter variable type??
        jr      z,update_and_test_INT_for_loop_counter;{{c709:282c}}  (+$2c)

;counter is a float
        ld      bc,$0005          ;{{c70b:010500}} 
        ld      a,c               ;{{c70e:79}} 
        ex      de,hl             ;{{c70f:eb}} 
        call    copy_atHL_to_accumulator_type_A;{{c710:cd6cff}} 
        pop     hl                ;{{c713:e1}} 
        ld      a,(FORNEXT_flag_) ;{{c714:3a0cac}} 
        or      a                 ;{{c717:b7}} 
        jr      z,_update_and_test_for_loop_counter_27;{{c718:2810}}  (+$10) &00=NEXT not yet used (we're still in the FOR!)

        push    hl                ;{{c71a:e5}} Otherwise update FOR variable (var = var + step)
        add     hl,bc             ;{{c71b:09}} 
        call    infix_plus_       ;{{c71c:cd0cfd}} 
        pop     hl                ;{{c71f:e1}} 
        push    hl                ;{{c720:e5}} 
        dec     hl                ;{{c721:2b}} 
        ld      d,(hl)            ;{{c722:56}} 
        dec     hl                ;{{c723:2b}} 
        ld      e,(hl)            ;{{c724:5e}} 
        ex      de,hl             ;{{c725:eb}} 
        call    copy_numeric_accumulator_to_atHL;{{c726:cd83ff}} 
        pop     hl                ;{{c729:e1}} 

_update_and_test_for_loop_counter_27:;{{Addr=$c72a Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c72a:e5}} Compare counter to 'to' value
        ld      c,$05             ;{{c72b:0e05}} Comparison operation? greater or equals?
        call    infix_comparisons_plural;{{c72d:cd49fd}} 
        pop     hl                ;{{c730:e1}} 
        ld      bc,$000a          ;{{c731:010a00}} 
        add     hl,bc             ;{{c734:09}} 
        sub     (hl)              ;{{c735:96}} 
        ret                       ;{{c736:c9}} 

;;=update and test INT for loop counter
update_and_test_INT_for_loop_counter:;{{Addr=$c737 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c737:eb}} 
        ld      e,(hl)            ;{{c738:5e}} 
        inc     hl                ;{{c739:23}} 
        ld      d,(hl)            ;{{c73a:56}} 
        ld      a,(FORNEXT_flag_) ;{{c73b:3a0cac}} 
        or      a                 ;{{c73e:b7}} 
        jr      z,_update_and_test_int_for_loop_counter_24;{{c73f:2816}}  (+$16) &00=NEXT not yet used (still in FOR statement!)

        ex      (sp),hl           ;{{c741:e3}} 
        push    hl                ;{{c742:e5}} 
        inc     hl                ;{{c743:23}} 
        inc     hl                ;{{c744:23}} 
        ld      a,(hl)            ;{{c745:7e}} 
        inc     hl                ;{{c746:23}} 
        ld      h,(hl)            ;{{c747:66}} 
        ld      l,a               ;{{c748:6f}} 
        call    INT_addition_with_overflow_test;{{c749:cd4add}} 
        ld      a,$06             ;{{c74c:3e06}} Overflow error
        jp      nc,raise_error    ;{{c74e:d255cb}} 

        ex      de,hl             ;{{c751:eb}} 
        pop     hl                ;{{c752:e1}} 
        ex      (sp),hl           ;{{c753:e3}} 
        ld      (hl),d            ;{{c754:72}} 
        dec     hl                ;{{c755:2b}} 
        ld      (hl),e            ;{{c756:73}} 

_update_and_test_int_for_loop_counter_24:;{{Addr=$c757 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c757:e1}} Test loop counter against 'to' condition
        ld      a,(hl)            ;{{c758:7e}} 
        inc     hl                ;{{c759:23}} 
        push    hl                ;{{c75a:e5}} 
        ld      h,(hl)            ;{{c75b:66}} 
        ld      l,a               ;{{c75c:6f}} 
        ex      de,hl             ;{{c75d:eb}} 
        call    prob_compare_DE_to_HL;{{c75e:cd02de}} 
        pop     hl                ;{{c761:e1}} 
        inc     hl                ;{{c762:23}} 
        inc     hl                ;{{c763:23}} 
        inc     hl                ;{{c764:23}} 
        sub     (hl)              ;{{c765:96}} 
        ret                       ;{{c766:c9}} 

;;========================================================================
;; command IF

command_IF:                       ;{{Addr=$c767 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{c767:cd62cf}} 
        cp      $a0               ;{{c76a:fea0}} GOTO token
        jr      z,_command_if_5   ;{{c76c:2804}}  (+$04) IF [cond] GOTO [n] syntax
        call    next_token_if_equals_inline_data_byte;{{c76e:cd25de}} 
        defb $eb                  ;Token to test "THEN"

_command_if_5:                    ;{{Addr=$c772 Code Calls/jump count: 1 Data use count: 0}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c772:cdc4fd}} test condition
        call    z,skip_to_ELSE_statement;{{c775:cc5be9}} condition false - skip to ELSE
        ret     z                 ;{{c778:c8}} No else?

        call    is_next_02        ;{{c779:cd3dde}} 
        ret     c                 ;{{c77c:d8}} end of statement/line

        cp      $1e               ;{{c77d:fe1e}}  16-bit integer BASIC line number
        jr      z,command_GOTO    ;{{c77f:2805}} if so it's a GOTO
        cp      $1d               ;{{c781:fe1d}}  16-bit BASIC program line memory address pointer
        jp      nz,execute_command_token;{{c783:c28fde}} if not memory address pointer then execute whatever it is
                                  ;otherwise fall through to...

;;========================================================================
;; command GOTO

command_GOTO:                     ;{{Addr=$c786 Code Calls/jump count: 1 Data use count: 1}}
        call    eval_and_convert_line_number_to_line_address;{{c786:cd27e8}} 
        ret     nz                ;{{c789:c0}} 

        ex      de,hl             ;{{c78a:eb}} 
        ret                       ;{{c78b:c9}} 

;;========================================================================
;; command GOSUB

command_GOSUB:                    ;{{Addr=$c78c Code Calls/jump count: 0 Data use count: 1}}
        call    eval_and_convert_line_number_to_line_address;{{c78c:cd27e8}} 
        ret     nz                ;{{c78f:c0}} 

;;=GOSUB HL
GOSUB_HL:                         ;{{Addr=$c790 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{c790:eb}} 
        ld      c,$00             ;{{c791:0e00}} C=type of GOSUB. &00=regular

;;=special GOSUB HL
;C=gosub type (e.g. ON ERROR, ON BREAK, event etc).
;This code sets the next current line pointer and returns eith execution address in HL
special_GOSUB_HL:                 ;{{Addr=$c793 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c793:e5}} 
        ld      a,$06             ;{{c794:3e06}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c796:cd72f6}} 
        ld      (hl),c            ;{{c799:71}} 
        inc     hl                ;{{c79a:23}} 
        ld      (hl),e            ;{{c79b:73}} 
        inc     hl                ;{{c79c:23}} 
        ld      (hl),d            ;{{c79d:72}} 
        inc     hl                ;{{c79e:23}} 
        ex      de,hl             ;{{c79f:eb}} 
        call    get_current_line_address;{{c7a0:cdb1de}} 
        ex      de,hl             ;{{c7a3:eb}} 
        ld      (hl),e            ;{{c7a4:73}} 
        inc     hl                ;{{c7a5:23}} 
        ld      (hl),d            ;{{c7a6:72}} 
        inc     hl                ;{{c7a7:23}} 
        ld      (hl),$06          ;{{c7a8:3606}} 
        inc     hl                ;{{c7aa:23}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c7ab:cd5df6}} 
        pop     hl                ;{{c7ae:e1}} 
        ret                       ;{{c7af:c9}} 

;;========================================================================
;; command RETURN

command_RETURN:                   ;{{Addr=$c7b0 Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{c7b0:c0}} 
        call    find_last_RETURN_item_on_execution_stack;{{c7b1:cdcfc7}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c7b4:cd5df6}} 
        ld      c,(hl)            ;{{c7b7:4e}} 
        inc     hl                ;{{c7b8:23}} 
        ld      e,(hl)            ;{{c7b9:5e}} 
        inc     hl                ;{{c7ba:23}} 
        ld      d,(hl)            ;{{c7bb:56}} 
        inc     hl                ;{{c7bc:23}} 
        ld      a,(hl)            ;{{c7bd:7e}} 
        inc     hl                ;{{c7be:23}} 
        ld      h,(hl)            ;{{c7bf:66}} 
        ld      l,a               ;{{c7c0:6f}} 
        call    set_current_line_address;{{c7c1:cdadde}} 
        ex      de,hl             ;{{c7c4:eb}} 
        ld      a,c               ;{{c7c5:79}} 
        cp      $01               ;{{c7c6:fe01}} 
        ret     c                 ;{{c7c8:d8}} 

        jp      z,prob_RETURN_from_event_handler;{{c7c9:ca51c9}} 
        jp      prob_RETURN_from_break_handler;{{c7cc:c361c9}} 

;;=find last RETURN item on execution stack
find_last_RETURN_item_on_execution_stack:;{{Addr=$c7cf Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c7cf:2a6fb0}} 
_find_last_return_item_on_execution_stack_1:;{{Addr=$c7d2 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{c7d2:2b}} 
        ld      a,(hl)            ;{{c7d3:7e}} 
        push    af                ;{{c7d4:f5}} 
        ld      a,l               ;{{c7d5:7d}} 
        sub     (hl)              ;{{c7d6:96}} 
        ld      l,a               ;{{c7d7:6f}} 
        sbc     a,a               ;{{c7d8:9f}} 
        add     a,h               ;{{c7d9:84}} 
        ld      h,a               ;{{c7da:67}} 
        inc     hl                ;{{c7db:23}} 
        pop     af                ;{{c7dc:f1}} 
        cp      $06               ;{{c7dd:fe06}} 
        ret     z                 ;{{c7df:c8}} 

        or      a                 ;{{c7e0:b7}} 
        jr      nz,_find_last_return_item_on_execution_stack_1;{{c7e1:20ef}}  (-$11)
        call    byte_following_call_is_error_code;{{c7e3:cd45cb}} 
        defb $03                  ;Inline error code: Unexpected RETURN

;;========================================================================
;; command WHILE
command_WHILE:                    ;{{Addr=$c7e7 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c7e7:e5}} 
        call    find_matching_WEND;{{c7e8:cdc9ca}} 
        push    hl                ;{{c7eb:e5}} 
        ex      de,hl             ;{{c7ec:eb}} 

;Find data on execution stack
        ld      (address_of_LB_of_the_line_number_contain),hl;{{c7ed:2214ac}} 
        call    find_WHILEWEND_data_on_execution_stack;{{c7f0:cd5dc8}} 
        call    z,set_execution_stack_next_free_ptr_and_its_cache;{{c7f3:cc5df6}} 

;Data not found on execution stack so add it
        ld      a,$07             ;{{c7f6:3e07}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{c7f8:cd72f6}} 
        ex      de,hl             ;{{c7fb:eb}} 
        call    get_current_line_address;{{c7fc:cdb1de}} 
        ex      de,hl             ;{{c7ff:eb}} 
        ld      (hl),e            ;{{c800:73}} 
        inc     hl                ;{{c801:23}} 
        ld      (hl),d            ;{{c802:72}} 
        inc     hl                ;{{c803:23}} 
        pop     de                ;{{c804:d1}} 
        ld      (hl),e            ;{{c805:73}} 
        inc     hl                ;{{c806:23}} 
        ld      (hl),d            ;{{c807:72}} 
        inc     hl                ;{{c808:23}} 
        ex      de,hl             ;{{c809:eb}} 
        ex      (sp),hl           ;{{c80a:e3}} 
        ex      de,hl             ;{{c80b:eb}} 
        ld      (hl),e            ;{{c80c:73}} 
        inc     hl                ;{{c80d:23}} 
        ld      (hl),d            ;{{c80e:72}} 
        inc     hl                ;{{c80f:23}} 
        ld      (hl),$07          ;{{c810:3607}} 
        inc     hl                ;{{c812:23}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c813:cd5df6}} 
        ex      de,hl             ;{{c816:eb}} 
        pop     de                ;{{c817:d1}} 
        jr      eval_WHILE_condition;{{c818:182a}}  (+$2a)

;;========================================================================
;; command WEND

command_WEND:                     ;{{Addr=$c81a Code Calls/jump count: 0 Data use count: 1}}
        ret     nz                ;{{c81a:c0}} 
        ex      de,hl             ;{{c81b:eb}} 
        call    find_WHILEWEND_data_on_execution_stack;{{c81c:cd5dc8}} 
        ld      a,$1e             ;{{c81f:3e1e}}  Unexpected WEND error
        jp      nz,raise_error    ;{{c821:c255cb}} 

        push    hl                ;{{c824:e5}} 
        ld      de,$0007          ;{{c825:110700}} 
        add     hl,de             ;{{c828:19}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c829:cd5df6}} 
        call    get_current_line_address;{{c82c:cdb1de}} 
        ld      (address_of_LB_of_the_line_number_contain),hl;{{c82f:2214ac}} 
        pop     hl                ;{{c832:e1}} 
        ld      e,(hl)            ;{{c833:5e}} 
        inc     hl                ;{{c834:23}} 
        ld      d,(hl)            ;{{c835:56}} 
        inc     hl                ;{{c836:23}} 
        ex      de,hl             ;{{c837:eb}} 
        call    set_current_line_address;{{c838:cdadde}} Go to the WHILE statement?
        ex      de,hl             ;{{c83b:eb}} 
        ld      e,(hl)            ;{{c83c:5e}} 
        inc     hl                ;{{c83d:23}} 
        ld      d,(hl)            ;{{c83e:56}} 
        inc     hl                ;{{c83f:23}} 
        ld      a,(hl)            ;{{c840:7e}} 
        inc     hl                ;{{c841:23}} 
        ld      h,(hl)            ;{{c842:66}} 
        ld      l,a               ;{{c843:6f}} 

;;=eval WHILE condition
eval_WHILE_condition:             ;{{Addr=$c844 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c844:d5}} 
        call    eval_expression   ;{{c845:cd62cf}} 
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{c848:cdc4fd}} 
        pop     de                ;{{c84b:d1}} 
        ret     nz                ;{{c84c:c0}} Condition true? - continue after the WHILE

        ld      hl,(address_of_LB_of_the_line_number_contain);{{c84d:2a14ac}} else remove execution stack data and continue after the WEND
        call    set_current_line_address;{{c850:cdadde}} 
        ld      a,$07             ;{{c853:3e07}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{c855:cd62f6}} 
        call    set_execution_stack_next_free_ptr_and_its_cache;{{c858:cd5df6}} 
        ex      de,hl             ;{{c85b:eb}} 
        ret                       ;{{c85c:c9}} 

;;=find WHILE/WEND data on execution stack
find_WHILEWEND_data_on_execution_stack:;{{Addr=$c85d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{c85d:2a6fb0}} 
_find_whilewend_data_on_execution_stack_1:;{{Addr=$c860 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{c860:2b}} 
        push    hl                ;{{c861:e5}} 
        ld      a,l               ;{{c862:7d}} 
        sub     (hl)              ;{{c863:96}} 
        ld      l,a               ;{{c864:6f}} 
        sbc     a,a               ;{{c865:9f}} 
        add     a,h               ;{{c866:84}} 
        ld      h,a               ;{{c867:67}} 
        inc     hl                ;{{c868:23}} 
        ex      (sp),hl           ;{{c869:e3}} 
        ld      a,(hl)            ;{{c86a:7e}} 
        cp      $07               ;{{c86b:fe07}} 
        jr      c,_find_whilewend_data_on_execution_stack_24;{{c86d:380e}}  (+$0e)
        jr      nz,_find_whilewend_data_on_execution_stack_26;{{c86f:200e}}  (+$0e)
        dec     hl                ;{{c871:2b}} 
        dec     hl                ;{{c872:2b}} 
        dec     hl                ;{{c873:2b}} 
        ld      a,(hl)            ;{{c874:7e}} 
        dec     hl                ;{{c875:2b}} 
        ld      l,(hl)            ;{{c876:6e}} 
        ld      h,a               ;{{c877:67}} 
        call    compare_HL_DE     ;{{c878:cdd8ff}}  HL=DE?
        jr      nz,_find_whilewend_data_on_execution_stack_26;{{c87b:2002}}  (+$02)
_find_whilewend_data_on_execution_stack_24:;{{Addr=$c87d Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{c87d:e1}} 
        ret                       ;{{c87e:c9}} 

_find_whilewend_data_on_execution_stack_26:;{{Addr=$c87f Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{c87f:e1}} 
        jr      _find_whilewend_data_on_execution_stack_1;{{c880:18de}}  (-$22)




;;***EventsExceptions.asm
;;<< ERROR AND EVENT HANDLERS
;;< ON xx, DI, EI, AFTER, EVERY, REMAIN
;;========================================================================
;; command ON, ON ERROR GOTO
;(except ON ERROR GOTO 0!)

command_ON_ON_ERROR_GOTO:         ;{{Addr=$c882 Code Calls/jump count: 0 Data use count: 1}}
        cp      $9c               ;{{c882:fe9c}} token for ERROR
        jp      z,ON_ERROR_GOTO   ;{{c884:cab8cc}} 

;ON [expr] GOTO/GOSUB [list of line numbers]
        call    eval_expr_as_byte_or_error;{{c887:cdb8ce}}  get number and check it's less than 255 
        ld      c,a               ;{{c88a:4f}} C = index into list of item to goto/gosub
        ld      a,(hl)            ;{{c88b:7e}} 
        cp      $a0               ;{{c88c:fea0}} GOTO token
        push    af                ;{{c88e:f5}} 
        jr      z,_command_on_on_error_goto_11;{{c88f:2805}}  (+$05)

        call    next_token_if_equals_inline_data_byte;{{c891:cd25de}} 
        defb $9f                  ;Inline token to test "GOSUB"
        dec     hl                ;{{c895:2b}} 

;Loop reading line numbers and decrementing C until C gets to zero or we run out of items
_command_on_on_error_goto_11:     ;{{Addr=$c896 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{c896:cd2cde}}  get next token skipping space
_command_on_on_error_goto_12:     ;{{Addr=$c899 Code Calls/jump count: 1 Data use count: 0}}
        dec     c                 ;{{c899:0d}} 
        jr      z,do_on_goto_gosub;{{c89a:280a}}  (+$0a)
        call    eval_line_number_or_error;{{c89c:cd48cf}} 
        call    next_token_if_prev_is_comma;{{c89f:cd41de}} 
        jr      c,_command_on_on_error_goto_12;{{c8a2:38f5}}  (-$0b)
        pop     af                ;{{c8a4:f1}} 
        ret                       ;{{c8a5:c9}} 

;;=do on goto gosub
do_on_goto_gosub:                 ;{{Addr=$c8a6 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_and_convert_line_number_to_line_address;{{c8a6:cd27e8}} 
        call    nz,skip_to_end_of_statement;{{c8a9:c4a3e9}} NZ means item not found - call DATA to 
                                  ;skip over list and contnue execution at the next line
        pop     af                ;{{c8ac:f1}} 
        jp      nz,GOSUB_HL       ;{{c8ad:c290c7}} Do a GOSUB
        ex      de,hl             ;{{c8b0:eb}} else do a GOTO
        ret                       ;{{c8b1:c9}} 

;;=prob process pending events
prob_process_pending_events:      ;{{Addr=$c8b2 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{c8b2:af}} 
        ld      (unknown_event_handler_data),a;{{c8b3:3216ac}} 

_prob_process_pending_events_2:   ;{{Addr=$c8b6 Code Calls/jump count: 1 Data use count: 0}}
        call    KL_NEXT_SYNC      ;{{c8b6:cdfbbc}}  firmware function: kl next sync 
        jr      nc,finished_processing_events;{{c8b9:301d}}  (+$1d)
        ld      b,a               ;{{c8bb:47}} 
        ld      a,(unknown_event_handler_data);{{c8bc:3a16ac}} 
        and     $7f               ;{{c8bf:e67f}} 
        ld      (unknown_event_handler_data),a;{{c8c1:3216ac}} 
        push    bc                ;{{c8c4:c5}} 
        push    hl                ;{{c8c5:e5}} 
        call    KL_DO_SYNC        ;{{c8c6:cdfebc}}  firmware function: kl do sync
        pop     hl                ;{{c8c9:e1}} 
        pop     bc                ;{{c8ca:c1}} 
        ld      a,(unknown_event_handler_data);{{c8cb:3a16ac}} 
        rla                       ;{{c8ce:17}} 
        push    af                ;{{c8cf:f5}} 
        ld      a,b               ;{{c8d0:78}} 
        call    nc,KL_DONE_SYNC   ;{{c8d1:d401bd}}  firmware function: kl done sync
        pop     af                ;{{c8d4:f1}} 
        rla                       ;{{c8d5:17}} 
        jr      nc,_prob_process_pending_events_2;{{c8d6:30de}}  (-$22) Loop for more

;;=finished processing events
finished_processing_events:       ;{{Addr=$c8d8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(unknown_event_handler_data);{{c8d8:3a16ac}} 
        and     $04               ;{{c8db:e604}} 
        call    nz,arm_break_handler;{{c8dd:c47fc4}} 
        ld      hl,(address_of_byte_before_current_statement);{{c8e0:2a1bae}} 
        ld      a,(unknown_event_handler_data);{{c8e3:3a16ac}} 
        and     $03               ;{{c8e6:e603}} 
        ret     z                 ;{{c8e8:c8}} 

        rra                       ;{{c8e9:1f}} 
        jp      c,unknown_execution_error;{{c8ea:da3ecc}} 
        inc     hl                ;{{c8ed:23}} 
        pop     af                ;{{c8ee:f1}} 
        jp      execute_end_of_line;{{c8ef:c377de}} 

;;=do ON BREAK
;(Called after the break pause and then unpause)
do_ON_BREAK:                      ;{{Addr=$c8f2 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_location_holding_ROM_routine_),hl;{{c8f2:221cac}} 
        ld      a,$04             ;{{c8f5:3e04}} 
        jr      nc,poss_event_done;{{c8f7:3052}}  (+$52) ON BREAK STOP?

        ld      hl,(ON_BREAK_GOSUB_handler_line_address_);{{c8f9:2a1aac}} 
        ld      a,h               ;{{c8fc:7c}} 
        or      l                 ;{{c8fd:b5}} 
        call    nz,get_current_line_number;{{c8fe:c4b5de}} 
        ld      a,$41             ;{{c901:3e41}} 
        jr      nc,poss_event_done;{{c903:3046}}  (+$46) ON BREAK GOSUB

        push    bc                ;{{c905:c5}} ON BREAK CONTinue?
        call    SOUND_CONTINUE    ;{{c906:cdb9bc}}  firmware function: sound continue
        pop     bc                ;{{c909:c1}} 
        ld      de,RAM_ac17       ;{{c90a:1117ac}} 
        ld      c,$02             ;{{c90d:0e02}} 
        jr      handle_event_etc_GOSUBs;{{c90f:1822}}  (+$22)

;;=eval and setup event GOSUB handler
;Used by ON SQ, AFTER and EVERY
;evals the gosub and line number and stores in the relevant event data block
;DE=event data block address?
eval_and_setup_event_GOSUB_handler:;{{Addr=$c911 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{c911:d5}} 
        call    next_token_if_equals_inline_data_byte;{{c912:cd25de}} 
        defb $9f                  ;Inline token to test "GOSUB"
        call    eval_and_convert_line_number_to_line_address;{{c916:cd27e8}} 
        ld      b,d               ;{{c919:42}} 
        ld      c,e               ;{{c91a:4b}} 
        pop     de                ;{{c91b:d1}} 
        push    hl                ;{{c91c:e5}} 
        ld      hl,$000a          ;{{c91d:210a00}} 
        add     hl,de             ;{{c920:19}} 
        ld      (hl),c            ;{{c921:71}} 
        inc     hl                ;{{c922:23}} 
        ld      (hl),b            ;{{c923:70}} 
        pop     hl                ;{{c924:e1}} 
        ret                       ;{{c925:c9}} 

;;==============================================
;;event handler routine
;Called by the firmware for events
event_handler_routine:            ;{{Addr=$c926 Code Calls/jump count: 0 Data use count: 1}}
        inc     hl                ;{{c926:23}} 
        inc     hl                ;{{c927:23}} 
        inc     hl                ;{{c928:23}} 
        ex      de,hl             ;{{c929:eb}} 
        call    get_current_line_number;{{c92a:cdb5de}} 
        ld      a,$40             ;{{c92d:3e40}} 
        jr      nc,poss_event_done;{{c92f:301a}}  (+$1a)
        ld      c,$01             ;{{c931:0e01}} GOSUB type

;;=handle event etc GOSUBs
;C specifies gosub type
;DE=address to store data for this event type
handle_event_etc_GOSUBs:          ;{{Addr=$c933 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{c933:d5}} 
        call    special_GOSUB_HL  ;{{c934:cd93c7}} 
        ld      hl,(address_of_byte_before_current_statement);{{c937:2a1bae}} 
        ex      de,hl             ;{{c93a:eb}} 
        pop     hl                ;{{c93b:e1}} 
        ld      (hl),b            ;{{c93c:70}} 
        inc     hl                ;{{c93d:23}} 
        ld      (hl),e            ;{{c93e:73}} 
        inc     hl                ;{{c93f:23}} 
        ld      (hl),d            ;{{c940:72}} 
        inc     hl                ;{{c941:23}} 
        ld      e,(hl)            ;{{c942:5e}} 
        inc     hl                ;{{c943:23}} 
        ld      d,(hl)            ;{{c944:56}} 
        ex      de,hl             ;{{c945:eb}} 
        ld      (address_of_byte_before_current_statement),hl;{{c946:221bae}} 
        ld      a,$c2             ;{{c949:3ec2}} 

;;=poss event done?
poss_event_done:                  ;{{Addr=$c94b Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,unknown_event_handler_data;{{c94b:2116ac}} 
        or      (hl)              ;{{c94e:b6}} 
        ld      (hl),a            ;{{c94f:77}} 
        ret                       ;{{c950:c9}} 

;;=prob RETURN from event handler
;RETURN statement executed in an event handler
prob_RETURN_from_event_handler:   ;{{Addr=$c951 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{c951:7e}} 
        inc     hl                ;{{c952:23}} 
        ld      e,(hl)            ;{{c953:5e}} 
        inc     hl                ;{{c954:23}} 
        ld      d,(hl)            ;{{c955:56}} 
        push    de                ;{{c956:d5}} 
        ld      bc,$fff7          ;{{c957:01f7ff}} ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{c95a:09}} 
        call    KL_DONE_SYNC      ;{{c95b:cd01bd}}  firmware function: KL DONE SYNC
        pop     hl                ;{{c95e:e1}} 
        jr      _prob_return_from_break_handler_7;{{c95f:1811}}  (+$11)

;;=prob RETURN from break handler
prob_RETURN_from_break_handler:   ;{{Addr=$c961 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{c961:7e}} 
        ld      hl,(address_of_location_holding_ROM_routine_);{{c962:2a1cac}} 
        ld      bc,$fffc          ;{{c965:01fcff}}  JP (BC) ##LIT##;WARNING: Code area used as literal
        add     hl,bc             ;{{c968:09}} 
        call    KL_DONE_SYNC      ;{{c969:cd01bd}}  firmware function: KL DONE SYNC
        call    arm_break_handler ;{{c96c:cd7fc4}} 
        ld      hl,(RAM_ac18)     ;{{c96f:2a18ac}} 
_prob_return_from_break_handler_7:;{{Addr=$c972 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{c972:f1}} 
        jp      execute_line_atHL ;{{c973:c360de}} 

;;========================================================================
;; command ON BREAK, ON BREAK CONT, ON BREAK STOP

command_ON_BREAK_ON_BREAK_CONT_ON_BREAK_STOP:;{{Addr=$c976 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_on_break_on_break_cont_on_break_stop_2;{{c976:cd7cc9}} 
        jp      get_next_token_skipping_space;{{c979:c32cde}}  get next token skipping space

_command_on_break_on_break_cont_on_break_stop_2:;{{Addr=$c97c Code Calls/jump count: 1 Data use count: 0}}
        cp      $8b               ;{{c97c:fe8b}}  token for "CONT"
        jp      z,ON_BREAK_CONT   ;{{c97e:cad0c4}}  ON BREAK CONT

        cp      $ce               ;{{c981:fece}}  token for "STOP"
        ld      de,$0000          ;{{c983:110000}} ##LIT##
        jr      z,set_ON_BREAK_handler_line_address;{{c986:2808}}  ON BREAK STOP

;; 
        call    next_token_if_equals_inline_data_byte;{{c988:cd25de}} 
        defb $9f                  ; token for "GOSUB"
        call    eval_and_convert_line_number_to_line_address;{{c98c:cd27e8}} 
        dec     hl                ;{{c98f:2b}} 

;;=set ON BREAK handler line address
set_ON_BREAK_handler_line_address:;{{Addr=$c990 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ON_BREAK_GOSUB_handler_line_address_),de;{{c990:ed531aac}} 
        jp      ON_BREAK_STOP     ;{{c994:c3d3c4}}  ON BREAK STOP


;;EVENTS
;;========================================================================
;; command DI
command_DI:                       ;{{Addr=$c997 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c997:e5}} 
        call    KL_EVENT_DISABLE  ;{{c998:cd04bd}}  firmware function: KL EVENT DISABLE
        pop     hl                ;{{c99b:e1}} 
        ret                       ;{{c99c:c9}} 

;;========================================================================
;; command EI
command_EI:                       ;{{Addr=$c99d Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{c99d:e5}} 
        call    KL_EVENT_ENABLE   ;{{c99e:cd07bd}}  firmware function: KL EVENT ENABLE
        pop     hl                ;{{c9a1:e1}} 
        ret                       ;{{c9a2:c9}} 

;;========================================================================
;;initialise event system
initialise_event_system:          ;{{Addr=$c9a3 Code Calls/jump count: 1 Data use count: 0}}
        call    SOUND_RESET       ;{{c9a3:cda7bc}}  firmware function: SOUND RESET
        ld      hl,Ticker_and_Event_Block_for_AFTEREVERY_T;{{c9a6:2142ac}} 
        ld      b,$04             ;{{c9a9:0604}} 

;;delete sound events loop
_initialise_event_system_3:       ;{{Addr=$c9ab Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{c9ab:e5}} 
        call    KL_DEL_TICKER     ;{{c9ac:cdecbc}}  firmware function: KL DEL TICKER
        pop     hl                ;{{c9af:e1}} 
        ld      de,$0012          ;{{c9b0:111200}} 
        add     hl,de             ;{{c9b3:19}} 
        djnz    _initialise_event_system_3;{{c9b4:10f5}} 

        call    KM_DISARM_BREAK   ;{{c9b6:cd48bb}}  firmware function: KL DISARM BREAK
        call    KL_SYNC_RESET     ;{{c9b9:cdf5bc}}  firmware function: KL SYNC RESET
        ld      hl,$0000          ;{{c9bc:210000}} ##LIT##
        ld      (ON_BREAK_GOSUB_handler_line_address_),hl;{{c9bf:221aac}} 
        call    arm_break_handler ;{{c9c2:cd7fc4}} 
        ld      hl,CEvent_Block_for_ON_SQ;{{c9c5:211eac}} 
        ld      de,$0305          ;{{c9c8:110503}} 
        ld      bc,$0800          ;{{c9cb:010008}} 
        call    Initialise_event_blocks;{{c9ce:cddac9}} 
        ld      hl,chain_address_to_next_ticker_block;{{c9d1:2148ac}} address of event block
        ld      de,$040b          ;{{c9d4:110b04}} 
        ld      bc,$0201          ;{{c9d7:010102}} B = event class

;;=Initialise event blocks
;D=count of event blocks to initialise
Initialise_event_blocks:          ;{{Addr=$c9da Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{c9da:c5}} 
        push    de                ;{{c9db:d5}} 
        ld      c,$fd             ;{{c9dc:0efd}} ROM select address
        ld      de,event_handler_routine;{{c9de:1126c9}} address of event routine ##LLABEL##;WARNING: Code area used as literal
        call    KL_INIT_EVENT     ;{{c9e1:cdefbc}}  firmware function: KL INIT EVENT 
        pop     de                ;{{c9e4:d1}} 
        push    de                ;{{c9e5:d5}} 
        ld      d,$00             ;{{c9e6:1600}} 
        add     hl,de             ;{{c9e8:19}} 
        pop     de                ;{{c9e9:d1}} 
        pop     bc                ;{{c9ea:c1}} 
        ld      a,c               ;{{c9eb:79}} 
        or      a                 ;{{c9ec:b7}} 
        jr      z,_initialise_event_blocks_15;{{c9ed:2802}}  (+$02)
        rlc     b                 ;{{c9ef:cb00}} 
_initialise_event_blocks_15:      ;{{Addr=$c9f1 Code Calls/jump count: 1 Data use count: 0}}
        dec     d                 ;{{c9f1:15}} 
        jr      nz,Initialise_event_blocks;{{c9f2:20e6}}  (-$1a) Loop for next block
        ret                       ;{{c9f4:c9}} 

;;========================================================================
;; command ON SQ
;ON SQ(channel) GOSUB [line]
;channel number = 1,2,4

command_ON_SQ:                    ;{{Addr=$c9f5 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{c9f5:cd19de}}  check for open bracket
        call    eval_expr_as_byte_or_error;{{c9f8:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{c9fb:f5}} 
        call    get_event_block_for_channel;{{c9fc:cd10ca}} 
        or      a                 ;{{c9ff:b7}} 
        jr      nz,raise_improper_argument_error_B;{{ca00:201d}}  (+$1d)
        call    next_token_if_close_bracket;{{ca02:cd1dde}}  check for close bracket
        call    eval_and_setup_event_GOSUB_handler;{{ca05:cd11c9}} Read GOSUB and address and set up
        pop     af                ;{{ca08:f1}} 
        push    hl                ;{{ca09:e5}} 
        ex      de,hl             ;{{ca0a:eb}} 
        call    SOUND_ARM_EVENT   ;{{ca0b:cdb0bc}}  firmware function: sound arm event
        pop     hl                ;{{ca0e:e1}} 
        ret                       ;{{ca0f:c9}} 

;;=get event block for channel
get_event_block_for_channel:      ;{{Addr=$ca10 Code Calls/jump count: 1 Data use count: 0}}
        rra                       ;{{ca10:1f}} 
        ld      de,CEvent_Block_for_ON_SQ;{{ca11:111eac}} 
        ret     c                 ;{{ca14:d8}} 

        rra                       ;{{ca15:1f}} 
        ld      de,cevent_block_for_on_sq_B;{{ca16:112aac}} 
        ret     c                 ;{{ca19:d8}} 

        rra                       ;{{ca1a:1f}} 
        ld      de,cevent_block_for_on_sq_C;{{ca1b:1136ac}} 
        ret     c                 ;{{ca1e:d8}} 

;;=raise Improper argument error
raise_improper_argument_error_B:  ;{{Addr=$ca1f Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Improper_Argument;{{ca1f:c34dcb}}  Error: Improper Argument

;;==================================================================
;; command AFTER
command_AFTER:                    ;{{Addr=$ca22 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_positive_int_or_error;{{ca22:cdcece}} Get delay
        ld      bc,$0000          ;{{ca25:010000}} ##LIT##
        jr      init_timer_event  ;{{ca28:1805}}  (+$05)

;;==================================================================
;; command EVERY
command_EVERY:                    ;{{Addr=$ca2a Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_positive_int_or_error;{{ca2a:cdcece}} Get period
        ld      b,d               ;{{ca2d:42}} 
        ld      c,e               ;{{ca2e:4b}} 

;;=init timer event
init_timer_event:                 ;{{Addr=$ca2f Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ca2f:d5}} 
        push    bc                ;{{ca30:c5}} 
        call    next_token_if_prev_is_comma;{{ca31:cd41de}} 
        ld      de,$0000          ;{{ca34:110000}} ##LIT##
        call    c,eval_expr_as_int;{{ca37:dcd8ce}}  get timer number
        ex      de,hl             ;{{ca3a:eb}} 
        call    calc_AFTEREVERY_ticker_block_address;{{ca3b:cd62ca}} 

        push    hl                ;{{ca3e:e5}} 
        ld      bc,$0006          ;{{ca3f:010600}} 
        add     hl,bc             ;{{ca42:09}} 
        ex      de,hl             ;{{ca43:eb}} 
        call    eval_and_setup_event_GOSUB_handler;{{ca44:cd11c9}} 
        pop     de                ;{{ca47:d1}} 
        pop     bc                ;{{ca48:c1}} 
        ex      (sp),hl           ;{{ca49:e3}} 
        ex      de,hl             ;{{ca4a:eb}} 
        call    KL_ADD_TICKER     ;{{ca4b:cde9bc}}  firmware function: kl add ticker
        pop     hl                ;{{ca4e:e1}} 
        ret                       ;{{ca4f:c9}} 

;;========================================================
;; function REMAIN

function_REMAIN:                  ;{{Addr=$ca50 Code Calls/jump count: 0 Data use count: 1}}
        call    function_CINT     ;{{ca50:cdb6fe}} 
        call    calc_AFTEREVERY_ticker_block_address;{{ca53:cd62ca}} 
        call    KL_DEL_TICKER     ;{{ca56:cdecbc}}  firmware function: kl del ticker
        jr      c,_function_remain_5;{{ca59:3803}}  (+$03)
        ld      de,$0000          ;{{ca5b:110000}} ##LIT##
_function_remain_5:               ;{{Addr=$ca5e Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ca5e:eb}} 
        jp      store_HL_in_accumulator_as_INT;{{ca5f:c335ff}} 

;;=calc AFTER/EVERY ticker block address
;HL=ticker block number (0-3)
;out: HL=address
calc_AFTEREVERY_ticker_block_address:;{{Addr=$ca62 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{ca62:7c}} 
        or      a                 ;{{ca63:b7}} 
        jr      nz,raise_improper_argument_error_B;{{ca64:20b9}}  (-$47)
        ld      a,l               ;{{ca66:7d}} 
        cp      $04               ;{{ca67:fe04}} 
        jr      nc,raise_improper_argument_error_B;{{ca69:30b4}}  (-$4c)
        add     a,a               ;{{ca6b:87}} Calc offset/address within ticker block
        add     a,a               ;{{ca6c:87}} 
        add     a,a               ;{{ca6d:87}} 
        add     a,l               ;{{ca6e:85}} 
        add     a,a               ;{{ca6f:87}} 
        ld      l,a               ;{{ca70:6f}} 
        ld      bc,Ticker_and_Event_Block_for_AFTEREVERY_T;{{ca71:0142ac}} 
        add     hl,bc             ;{{ca74:09}} 
        ret                       ;{{ca75:c9}} 




;;***ControlFlowUtils.asm
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
        call    parse_and_find_or_create_a_var;{{caa8:cdbfd6}} 
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






;;***BasicInput.asm
;;<< BASIC INPUT BUFFER
;;< As used by EDIT and INPUT etc.
;;===================================

;; prob read buffer and or break
prob_read_buffer_and_or_break:    ;{{Addr=$caec Code Calls/jump count: 2 Data use count: 0}}
        call    input_text_to_BASIC_input_area;{{caec:cdf9ca}}  edit
        ret     c                 ;{{caef:d8}} 

        call    select_txt_stream_zero;{{caf0:cda1c1}} 
        ld      sp,$c000          ;{{caf3:3100c0}} ##LIT##
        jp      execute_tokenised_line;{{caf6:c35dde}} 

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






;;***Errors.asm
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





;;***ExprEvaluator.asm
;;<< EXPRESSION EVALUATION
;;< Includes prefix operators and various lookup tables (operators, system vars etc.)
;;=====================================
;;EVAL EXPRESSIONS
;;====================================================
;;eval expr as byte or error
;; returns value in A
eval_expr_as_byte_or_error:       ;{{Addr=$ceb8 Code Calls/jump count: 15 Data use count: 0}}
        call    eval_expr_as_int  ;{{ceb8:cdd8ce}}  get number
        push    af                ;{{cebb:f5}} 

;;=error if D non zero
error_if_D_non_zero:              ;{{Addr=$cebc Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{cebc:7a}} 
        or      a                 ;{{cebd:b7}} 
        jr      nz,raise_improper_argument_error_C;{{cebe:200b}}  Error: Improper argument      

;; it's lower than 256 return number
        pop     af                ;{{cec0:f1}} 
        ld      a,e               ;{{cec1:7b}} 
        ret                       ;{{cec2:c9}} 

;;=============================================
;;eval expr as int less than 256
eval_expr_as_int_less_than_256:   ;{{Addr=$cec3 Code Calls/jump count: 7 Data use count: 0}}
        call    eval_expr_as_int  ;{{cec3:cdd8ce}}  get number
        push    af                ;{{cec6:f5}} 
        ld      a,d               ;{{cec7:7a}} 
        or      e                 ;{{cec8:b3}} 
        jr      nz,error_if_D_non_zero;{{cec9:20f1}}  (-$0f)

;;+raise improper argument error
raise_improper_argument_error_C:  ;{{Addr=$cecb Code Calls/jump count: 2 Data use count: 0}}
        jp      Error_Improper_Argument;{{cecb:c34dcb}}  Error: Improper Argument

;;=======================================
;;eval expr as positive int or error
;(0-32676)
eval_expr_as_positive_int_or_error:;{{Addr=$cece Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expr_as_int  ;{{cece:cdd8ce}}  get number
        push    af                ;{{ced1:f5}} 
        ld      a,d               ;{{ced2:7a}} 
        rla                       ;{{ced3:17}} 
        jr      c,raise_improper_argument_error_C;{{ced4:38f5}}  (-$0b)
        pop     af                ;{{ced6:f1}} 
        ret                       ;{{ced7:c9}} 

;;========================================
;;eval expr as int
eval_expr_as_int:                 ;{{Addr=$ced8 Code Calls/jump count: 12 Data use count: 0}}
        call    eval_expression   ;{{ced8:cd62cf}} 
        push    af                ;{{cedb:f5}} 
        ex      de,hl             ;{{cedc:eb}} 
        call    function_CINT     ;{{cedd:cdb6fe}} 
        ex      de,hl             ;{{cee0:eb}} 
        pop     af                ;{{cee1:f1}} 
        ret                       ;{{cee2:c9}} 

;;========================================
;;eval expr as string
eval_expr_as_string:              ;{{Addr=$cee3 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{cee3:cd62cf}} 
        call    is_accumulator_a_string;{{cee6:cd66ff}} 
        jr      nz,_eval_expr_as_uint_1;{{cee9:200d}}  (+$0d)
        push    hl                ;{{ceeb:e5}} 
        ld      hl,(accumulator)  ;{{ceec:2aa0b0}} 
        call    prob_copy_string_to_strings_area;{{ceef:cd58fb}} 
        ex      de,hl             ;{{cef2:eb}} 
        pop     hl                ;{{cef3:e1}} 
        ret                       ;{{cef4:c9}} 

;;========================================
;;eval expr as uint
eval_expr_as_uint:                ;{{Addr=$cef5 Code Calls/jump count: 10 Data use count: 0}}
        call    eval_expression   ;{{cef5:cd62cf}} 
_eval_expr_as_uint_1:             ;{{Addr=$cef8 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{cef8:f5}} 
        push    bc                ;{{cef9:c5}} 
        push    hl                ;{{cefa:e5}} 
        call    function_UNT      ;{{cefb:cdebfe}} 
        ex      de,hl             ;{{cefe:eb}} 
        pop     hl                ;{{ceff:e1}} 
        pop     bc                ;{{cf00:c1}} 
        pop     af                ;{{cf01:f1}} 
        ret                       ;{{cf02:c9}} 

;;===========================================
;;eval expr as string and get length
eval_expr_as_string_and_get_length:;{{Addr=$cf03 Code Calls/jump count: 5 Data use count: 0}}
        call    eval_expression   ;{{cf03:cd62cf}} 
        jp      get_accumulator_string_length;{{cf06:c3f5fb}} 

;;===========================================
;;eval expr and error if not string
eval_expr_and_error_if_not_string:;{{Addr=$cf09 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expression   ;{{cf09:cd62cf}} 
        jp      error_if_accumulator_is_not_a_string;{{cf0c:c35eff}} 

;;===========================================
;;eval line number range params
;Params for LIST and DELETE: [first][,|-][last]
eval_line_number_range_params:    ;{{Addr=$cf0f Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$0001          ;{{cf0f:010100}} Default values
        ld      de,$ffff          ;{{cf12:11ffff}} ##LIT##;WARNING: Code area used as literal
        call    next_token_if_prev_is_comma;{{cf15:cd41de}} 
        call    nc,is_next_02     ;{{cf18:d43dde}} 
        ret     c                 ;{{cf1b:d8}} 

        cp      $23               ;{{cf1c:fe23}}  "#"
        ret     z                 ;{{cf1e:c8}} 

        cp      $f5               ;{{cf1f:fef5}} "-"
        jr      z,get_range_end   ;{{cf21:280a}}  (+$0a)

        call    eval_line_number_or_error;{{cf23:cd48cf}} 
        ld      b,d               ;{{cf26:42}} 
        ld      c,e               ;{{cf27:4b}} 
        ret     z                 ;{{cf28:c8}} 

        call    next_token_if_prev_is_comma;{{cf29:cd41de}} 
        ret     c                 ;{{cf2c:d8}} 

;;=get range end
get_range_end:                    ;{{Addr=$cf2d Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_equals_inline_data_byte;{{cf2d:cd25de}} 
        defb $f5                  ;Inline token to test "-"
        ld      de,$ffff          ;{{cf31:11ffff}} ##LIT##;WARNING: Code area used as literal
        ret     z                 ;{{cf34:c8}} 

        call    next_token_if_prev_is_comma;{{cf35:cd41de}} 
        ret     c                 ;{{cf38:d8}} 

        call    eval_line_number_or_error;{{cf39:cd48cf}} 
        call    nz,next_token_if_prev_is_comma;{{cf3c:c441de}} 
        ex      de,hl             ;{{cf3f:eb}} 
        call    compare_HL_BC     ;{{cf40:cddeff}}  HL=BC?
        jp      c,Error_Improper_Argument;{{cf43:da4dcb}}  Error: Improper Argument
        ex      de,hl             ;{{cf46:eb}} 
        ret                       ;{{cf47:c9}} 

;;===============================================
;;eval line number or error
;If data is a line pointer returns the line number of the line it points to.
eval_line_number_or_error:        ;{{Addr=$cf48 Code Calls/jump count: 10 Data use count: 0}}
        ld      a,(hl)            ;{{cf48:7e}} 
        inc     hl                ;{{cf49:23}} 
        ld      e,(hl)            ;{{cf4a:5e}} 
        inc     hl                ;{{cf4b:23}} 
        ld      d,(hl)            ;{{cf4c:56}} 
        cp      $1e               ;{{cf4d:fe1e}}  16-bit line number
        jr      z,_eval_line_number_or_error_18;{{cf4f:280e}}  (+$0e)

        cp      $1d               ;{{cf51:fe1d}}  16-bit line address pointer
        jp      nz,Error_Syntax_Error;{{cf53:c249cb}}  Error: Syntax Error
        push    hl                ;{{cf56:e5}} 
        ex      de,hl             ;{{cf57:eb}} fetch line number from line address pointer
        inc     hl                ;{{cf58:23}} 
        inc     hl                ;{{cf59:23}} 
        inc     hl                ;{{cf5a:23}} 
        ld      e,(hl)            ;{{cf5b:5e}} 
        inc     hl                ;{{cf5c:23}} 
        ld      d,(hl)            ;{{cf5d:56}} 
        pop     hl                ;{{cf5e:e1}} 

_eval_line_number_or_error_18:    ;{{Addr=$cf5f Code Calls/jump count: 1 Data use count: 0}}
        jp      get_next_token_skipping_space;{{cf5f:c32cde}}  get next token skipping space

;; EXPRESSION EVALUATOR
;;==================================
;; eval expression
;; This gets called to evaluate an expression after a statement or function
;; but will also be called recursively for sub-expressions, 
;; eg. after an open bracket or by a function call within the expression
;; HL = ptr to first token

eval_expression:                  ;{{Addr=$cf62 Code Calls/jump count: 27 Data use count: 0}}
        push    bc                ;{{cf62:c5}} 
        ld      b,$00             ;{{cf63:0600}} B=operator precedence
        call    do_eval_expression;{{cf65:cd6dcf}} 
        pop     bc                ;{{cf68:c1}} 
        dec     hl                ;{{cf69:2b}} 
        jp      get_next_token_skipping_space;{{cf6a:c32cde}}  return with the next token after the expression
                                  ; or sub expression

;;=do eval expression
do_eval_expression:               ;{{Addr=$cf6d Code Calls/jump count: 3 Data use count: 0}}
        dec     hl                ;{{cf6d:2b}} 
_do_eval_expression_1:            ;{{Addr=$cf6e Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{cf6e:c5}} 
        call    eval_sub_expression;{{cf6f:cd33d0}}  process tokenised line
        push    hl                ;{{cf72:e5}} 

;;=infix operator or done
;If next token is an infix operator then expression continues, 
;otherwise end of expression so return
infix_operator_or_done:           ;{{Addr=$cf73 Code Calls/jump count: 3 Data use count: 0}}
        pop     hl                ;{{cf73:e1}}  look for possible infix operator
        pop     bc                ;{{cf74:c1}} 
        ld      a,(hl)            ;{{cf75:7e}} 
        cp      $ee               ;{{cf76:feee}} 
        ret     c                 ;{{cf78:d8}} 

        cp      $fe               ;{{cf79:fefe}} 
        ret     nc                ;{{cf7b:d0}} continue if token >= $ee and < $fe (infix operators)

; infix operators

;comparison
; ee: >
; ef: =
; f0: >= =>
; f1: <
; f2: <>
; f3: <= =<

;maths and logic
; f4: +
; f5: -
; f6: *
; f7: /
; f8: ^
; f9: \ integer division
; fa: AND
; fb: MOD
; fc: OR
; fd: XOR

;;infix operators
        cp      $f4               ;{{cf7c:fef4}} "+" token
        jr      c,comparison_infix_operator;{{cf7e:3845}}  (+$45) tokens $ee to $f3
        call    z,is_accumulator_a_string;{{cf80:cc66ff}} If "+" then is operand a string?
        jr      nz,maths_and_logic_infix_operators;{{cf83:2012}}  (+$12) 

;accumulator is a string and operator is addition.
        push    bc                ;{{cf85:c5}} 
        push    hl                ;{{cf86:e5}} 
        ld      hl,(accumulator)  ;{{cf87:2aa0b0}} 
        ex      (sp),hl           ;{{cf8a:e3}} 
        call    eval_sub_expression;{{cf8b:cd33d0}}  process tokenised line
        call    error_if_accumulator_is_not_a_string;{{cf8e:cd5eff}} 
        ex      (sp),hl           ;{{cf91:e3}} 
        call    concat_two_strings;{{cf92:cd1df9}} 
        jr      infix_operator_or_done;{{cf95:18dc}}  (-$24)

;;=maths and logic infix operators
;; handle tokens f4 to fd
maths_and_logic_infix_operators:  ;{{Addr=$cf97 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{cf97:7e}} 
        sub     $f4               ;{{cf98:d6f4}} Table address = table start + ((token - $f4) * 3)
        ld      e,a               ;{{cf9a:5f}}  E = A * 3
        add     a,a               ;{{cf9b:87}} 
        add     a,e               ;{{cf9c:83}}  use A as index into table at $cfed
        add     a,infix_maths_table and $ff;{{cf9d:c6ed}}    $ed
        ld      e,a               ;{{cf9f:5f}} 
        adc     a,infix_maths_table >> 8;{{cfa0:cecf}}  $cf
        sub     e                 ;{{cfa2:93}} 
        ld      d,a               ;{{cfa3:57}} 
        ex      de,hl             ;{{cfa4:eb}} HL=table item addr
        ld      a,b               ;{{cfa5:78}} Precedence of previous operator
        cp      (hl)              ;{{cfa6:be}} Compare with value in table
        ex      de,hl             ;{{cfa7:eb}} 
        ret     nc                ;{{cfa8:d0}} Return if new operator is lower precedence

        push    bc                ;{{cfa9:c5}} 
;;=dispatch infix operator
;;DE = ptr to address of table entry
dispatch_infix_operator:          ;{{Addr=$cfaa Code Calls/jump count: 1 Data use count: 0}}
        call    probably_push_accumulator_on_execution_stack;{{cfaa:cd74ff}} 
        push    de                ;{{cfad:d5}} 
        push    bc                ;{{cfae:c5}} 
        ld      a,(de)            ;{{cfaf:1a}} Read or restore previous operator precedence value?
        ld      b,a               ;{{cfb0:47}} 
        call    _do_eval_expression_1;{{cfb1:cd6ecf}} eval expression after operator
        pop     bc                ;{{cfb4:c1}} 
        ex      (sp),hl           ;{{cfb5:e3}} 
        inc     hl                ;{{cfb6:23}} 
        ld      a,(hl)            ;{{cfb7:7e}} Read code address from table...
        inc     hl                ;{{cfb8:23}} 
        ld      h,(hl)            ;{{cfb9:66}} 
        ld      l,a               ;{{cfba:6f}} 
        ex      de,hl             ;{{cfbb:eb}} ...into DE
        ld      a,c               ;{{cfbc:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{cfbd:cd62f6}} 
        call    JP_DE             ;{{cfc0:cdfeff}}  JP (DE) call infix eval routine
        jr      infix_operator_or_done;{{cfc3:18ae}}  (-$52)

;;=comparison infix operator
; tokens ee to f3
comparison_infix_operator:        ;{{Addr=$cfc5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{cfc5:78}} Precedence
        cp      $0a               ;{{cfc6:fe0a}} 
        ret     nc                ;{{cfc8:d0}} Return if previous operator is higher

        push    bc                ;{{cfc9:c5}} 
        ld      a,(hl)            ;{{cfca:7e}} Operator
        sub     $ed               ;{{cfcb:d6ed}} Calc precedence?
        ld      b,a               ;{{cfcd:47}} Predence
        call    is_accumulator_a_string;{{cfce:cd66ff}}  check operand type
        ld      de,infix_comparison_table;{{cfd1:110bd0}}  
        jr      nz,dispatch_infix_operator;{{cfd4:20d4}}  (-$2c) do comparison for non strings

        push    hl                ;{{cfd6:e5}}  otherwise it's a string comparison
        ld      hl,(accumulator)  ;{{cfd7:2aa0b0}} 
        ex      (sp),hl           ;{{cfda:e3}} 
        push    bc                ;{{cfdb:c5}} 
        ld      b,$0a             ;{{cfdc:060a}} Precedence
        call    _do_eval_expression_1;{{cfde:cd6ecf}} eval expression after operator
        pop     bc                ;{{cfe1:c1}} 
        ex      (sp),hl           ;{{cfe2:e3}} 
        push    bc                ;{{cfe3:c5}} 
        call    probably_string_comparison;{{cfe4:cd3ff9}} string compare???
        pop     bc                ;{{cfe7:c1}} 
        call    process_comparison_result;{{cfe8:cd13d0}} 
        jr      infix_operator_or_done;{{cfeb:1886}}  (-$7a)

;;=======================================
;Maths infix operator table format:
;byte=operator precedence? (higher values take higher priority)
;word=code address or evaluation routine


;;infix maths table
infix_maths_table:                ;{{Addr=$cfed Data Calls/jump count: 0 Data use count: 2}}
        defb $0c                  
        defw infix_plus_          ; + ##LABEL##
        defb $0c                  
        defw infix_minus_         ; - ##LABEL##
        defb $12                  
        defw infix_multiply_      ; * ##LABEL##
        defb $12                  
        defw infix_divide_        ; / ##LABEL##
        defb $16                  
        defw infix_power_         ; ^ ##LABEL##
        defb $10                  
        defw infix_integer_division; \ integer division ##LABEL##
        defb $06                  
        defw infix_AND            ; AND ##LABEL##
        defb $0e                  
        defw infix_MOD            ; MOD ##LABEL##
        defb $04                  
        defw infix_OR             ;OR ##LABEL##
        defb $02                  
        defw infix_XOR            ;XOR ##LABEL##

;;=infix comparison table
infix_comparison_table:           ;{{Addr=$d00b Data Calls/jump count: 0 Data use count: 1}}
        defb $0a                  
        defw eval_comparison_infix; ##LABEL##

;;=eval comparison infix
; ee: >
; ef: =
; f0: >= =>
; f1: <
; f2: <>
; f3: <= =<
eval_comparison_infix:            ;{{Addr=$d00e Code Calls/jump count: 0 Data use count: 1}}
        push bc                   ;{{d00e:c5}} 
        call infix_comparisons_plural;{{d00f:cd49fd}} 
        pop bc                    ;{{d012:c1}} 

;;= process comparison result
;called after we've done a comparison operator. Presumably converts the result
;into a boolean value?
process_comparison_result:        ;{{Addr=$d013 Code Calls/jump count: 1 Data use count: 0}}
        add     a,$01             ;{{d013:c601}} 
        adc     a,a               ;{{d015:8f}} 
        and     b                 ;{{d016:a0}} 
        add     a,$ff             ;{{d017:c6ff}} 
        sbc     a,a               ;{{d019:9f}} 
        jp      store_sign_extended_byte_in_A_in_accumulator;{{d01a:c32dff}} 




;;=======================================
;; PREFIX OPERATORS
;;=======================================================================
;; prefix minus -
prefix_minus_:                    ;{{Addr=$d01d Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$14             ;{{d01d:0614}} Operator precedence
        call    do_eval_expression;{{d01f:cd6dcf}} 
        push    hl                ;{{d022:e5}} 
        call    negate_accumulator;{{d023:cdb4fd}} 
        pop     hl                ;{{d026:e1}} 
        ret                       ;{{d027:c9}} 

;;=======================================================================
;; prefix NOT

prefix_NOT:                       ;{{Addr=$d028 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$08             ;{{d028:0608}} Operator precedence
        call    do_eval_expression;{{d02a:cd6dcf}} 
        push    hl                ;{{d02d:e5}} 
        call    bitwise_complementinvert;{{d02e:cda6fd}} 
        pop     hl                ;{{d031:e1}} 
        ret                       ;{{d032:c9}} 

;;=========================================
;; EVAL A TOKENISED EXPRESSION
;;==========================================================================
;; eval sub expression
;; evaluate a sub-expression. Doesn't evaluate infix operators

eval_sub_expression:              ;{{Addr=$d033 Code Calls/jump count: 2 Data use count: 0}}
        call    get_next_token_skipping_space;{{d033:cd2cde}}  get next token skipping space
;;+-----------
;;prefix plus
;if we have + as a prefix operator we don't need to do anything!

prefix_plus:                      ;{{Addr=$d036 Code Calls/jump count: 0 Data use count: 1}}
        jr      z,raise_missing_operand;{{d036:281d}}  (+$1d)
        cp      $0e               ;{{d038:fe0e}} 
        jr      c,eval_variable_references;{{d03a:3838}}  
        cp      $20               ;{{d03c:fe20}}  (space)
        jr      c,eval_constants  ;{{d03e:3852}}  
        cp      $22               ;{{d040:fe22}}  (double quote)
        jp      z,get_quoted_string;{{d042:ca79f8}} 

        cp      $ff               ;{{d045:feff}}  keyword with $ff prefix?
        jp      z,eval_functions_with_ff_prefix;{{d047:cadad0}} 

        push    hl                ;{{d04a:e5}} 
        ld      hl,prefix_token_table;{{d04b:2159d0}} 
        call    get_address_from_table;{{d04e:cdb4ff}} 
        ex      (sp),hl           ;{{d051:e3}} 
        jp      get_next_token_skipping_space;{{d052:c32cde}}  get next token skipping space
                                  ; (Function will be returned to with a token in A)

;;+---------------------------------------------------------------------------
;;raise missing operand
raise_missing_operand:            ;{{Addr=$d055 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{d055:cd45cb}} 
        defb $16                  ; Error: Operand Missing

;;===========================================================================
;; prefix token table
prefix_token_table:               ;{{Addr=$d059 Data Calls/jump count: 0 Data use count: 1}}
                                  

;(call this entry if token not found)
        defb $08                  
        defw raise_syntax_error   ; Error: Syntax Error ##LABEL##

        defb $f5                  ; -
        defw prefix_minus_        ;##LABEL##
        defb $f4                  ; +
        defw prefix_plus          ;##LABEL##
        defb $28                  ; (
        defw prefix_open_bracket_ ;##LABEL##
        defb $fe                  ; NOT
        defw prefix_NOT           ;##LABEL##
        defb $e3                  ; ERL
        defw prefix_ERL           ;##LABEL##
        defb $e4                  ; FN
        defw prefix_FN            ;##LABEL##
        defb $ac                  ; MID$
        defw prefix_MID           ;##LABEL##
        defb $40                  ; @
        defw prefix_at_operator_  ;##LABEL##

;;===========================================================================
;; eval variable references
;eval tokens $00 to $0d
;These tokens are for variables. Tokens $00 (end of line) and $01 (end of statement)
;have already been preocessed.
;Tokens:
;&02: integer variable definition with % suffix
;&03: string variable definition with $ suffix
;&04: real variable definition with % suffix
;&05: ??
;&06: ??
;&07: ??
;&08: ??
;&09: ??
;&0a: ??
;&0b: integer variable definition (no suffix)
;&0c: string variable definition (no suffix)
;&0d: real variable definition (no suffix)
;Unknown stuff probably includes DEF FNs and DIMs

eval_variable_references:         ;{{Addr=$d074 Code Calls/jump count: 1 Data use count: 0}}
        call    parse_and_find_var;{{d074:cdc9d6}} 
        jr      nc,undeclared_variable;{{d077:300b}}  (+$0b) Variable not declared/no value set yet
        cp      $03               ;{{d079:fe03}} String
        jr      z,eval_string_variable_reference;{{d07b:280f}}  (+$0f)
        push    hl                ;{{d07d:e5}} 
        ex      de,hl             ;{{d07e:eb}} 
        call    copy_atHL_to_accumulator_type_A;{{d07f:cd6cff}} 
        pop     hl                ;{{d082:e1}} 
        ret                       ;{{d083:c9}} 

;;=undeclared variable
;undeclared/no value set so return zero or empty string
undeclared_variable:              ;{{Addr=$d084 Code Calls/jump count: 1 Data use count: 0}}
        cp      $03               ;{{d084:fe03}} 
        jp      nz,zero_accumulator;{{d086:c21bff}} 
        ld      de,empty_string   ;{{d089:1191d0}} Pointer to an empty string

;;=eval string variable reference
eval_string_variable_reference:   ;{{Addr=$d08c Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator),de  ;{{d08c:ed53a0b0}} 
        ret                       ;{{d090:c9}} 

;;=empty string
empty_string:                     ;{{Addr=$d091 Data Calls/jump count: 0 Data use count: 1}}
        defb $00                  

;;===========================================================================
;;eval constants
;; eval tokens $0e to $1f
;; Raw token|After sub $0e|Meaning
;; $0e..$17? $00-$0a       Constants 0-10
;; $18       $0b:          Byte constant following token
;; $19       $0c:          Word constant following token = decimal constant
;; $1a       $0d:          Word constant following token = binary constant (&X prefix)
;; $1b       $0e:          Word constant following token = hex constant (&H or & prefix)
;; $1c       $0f:          UINT at (token + 3)?? = BASIC program line pointer
;; $1d       $10:          UINT constant following token = BASIC line number
;; $1e       $11:          REAL cinstant following token

eval_constants:                   ;{{Addr=$d092 Code Calls/jump count: 1 Data use count: 0}}
        sub     $0e               ;{{d092:d60e}} 
        ld      e,a               ;{{d094:5f}} 
        ld      d,$00             ;{{d095:1600}} 
        cp      $0a               ;{{d097:fe0a}} Constant 0-10
        jr      c,eval_DE_as_number_constant;{{d099:381b}} 

        inc     hl                ;{{d09b:23}} 
        ld      e,(hl)            ;{{d09c:5e}} 
        cp      $0b               ;{{d09d:fe0b}} Token $18: Byte following token
        jr      z,eval_DE_as_number_constant;{{d09f:2815}} 

        inc     hl                ;{{d0a1:23}} 
        ld      d,(hl)            ;{{d0a2:56}} 
        cp      $0f               ;{{d0a3:fe0f}} Tokens $19, $1a, $1b. Word following token. Values 0c, 0d, 0e
        jr      c,eval_DE_as_number_constant;{{d0a5:380f}}  (+$0f)
        cp      $11               ;{{d0a7:fe11}} Tokens $1c, $1d. Extended. Values 0f, 10h
        jr      c,eval_number_constant_extended;{{d0a9:3812}}  (+$12)
        jr      nz,raise_syntax_error;{{d0ab:202a}} ; Error: Syntax Error. Values <> 11h (shouldn't be here!)
        dec     hl                ;{{d0ad:2b}} Token $1e, Value 11h
        ld      a,$05             ;{{d0ae:3e05}} REAL
        call    copy_atHL_to_accumulator_type_A;{{d0b0:cd6cff}} 
        dec     hl                ;{{d0b3:2b}} 
        jr      eval_number_done  ;{{d0b4:1818}}  (+$18)

;;===========================================================================
;; eval DE as number constant
;; DE=value

eval_DE_as_number_constant:       ;{{Addr=$d0b6 Code Calls/jump count: 3 Data use count: 0}}
        ex      de,hl             ;{{d0b6:eb}} 
        call    store_HL_in_accumulator_as_INT;{{d0b7:cd35ff}} 
        ex      de,hl             ;{{d0ba:eb}} 
        jr      eval_number_done  ;{{d0bb:1811}}  (+$11)

;;+---------------------------------------------------------------------------
;;eval number constant extended
;DE=value stored after token
eval_number_constant_extended:    ;{{Addr=$d0bd Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d0bd:e5}} 
        cp      $0f               ;{{d0be:fe0f}} 
        jr      nz,eval_DE_as_UINT;{{d0c0:2007}}  (+$07)

        inc     de                ;{{d0c2:13}} Token $1c value $0f
        ex      de,hl             ;{{d0c3:eb}} 
        inc     hl                ;{{d0c4:23}} 
        inc     hl                ;{{d0c5:23}} 
        ld      e,(hl)            ;{{d0c6:5e}} Read word at (token + 3)??
        inc     hl                ;{{d0c7:23}} 
        ld      d,(hl)            ;{{d0c8:56}} 

;;=eval DE as UINT
eval_DE_as_UINT:                  ;{{Addr=$d0c9 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{d0c9:eb}} 
        call    set_accumulator_as_REAL_from_unsigned_INT;{{d0ca:cd89fe}} 
        pop     hl                ;{{d0cd:e1}} 

;;=eval number done
eval_number_done:                 ;{{Addr=$d0ce Code Calls/jump count: 2 Data use count: 0}}
        jp      get_next_token_skipping_space;{{d0ce:c32cde}}  get next token skipping space

;;=======================================================================
;; prefix open bracket (
prefix_open_bracket_:             ;{{Addr=$d0d1 Code Calls/jump count: 1 Data use count: 1}}
        call    eval_expression   ;{{d0d1:cd62cf}} 
        jp      next_token_if_close_bracket;{{d0d4:c31dde}}  check for close bracket

;;======================================================================
;; raise syntax error
raise_syntax_error:               ;{{Addr=$d0d7 Code Calls/jump count: 2 Data use count: 1}}
        jp      Error_Syntax_Error;{{d0d7:c349cb}}  Error: Syntax Error

;;======================================================================
;; eval functions with $ff prefix

eval_functions_with_ff_prefix:    ;{{Addr=$d0da Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{d0da:23}} 
        ld      c,(hl)            ;{{d0db:4e}} ; get function token
        call    get_next_token_skipping_space;{{d0dc:cd2cde}}  get next token skipping space

;; A = keyword id
        ld      a,c               ;{{d0df:79}} 
        cp      $40               ;{{d0e0:fe40}} 
        jr      c,eval_function_which_arent_system_variables;{{d0e2:3805}}  (+$05)
        cp      $4a               ;{{d0e4:fe4a}} ****Change this value if extending the table.
        jp      c,eval_system_variables;{{d0e6:da10d1}} 

;;-------------------------------------------------------------------------
;;=eval function which arent system variables
;; value < $40 or => $4a
eval_function_which_arent_system_variables:;{{Addr=$d0e9 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_open_bracket;{{d0e9:cd19de}}  function so we need opening bracket

;Convert token to index into table.
;Function tokens are $71 - $7f (complex parameter functions) and 
;$00 - $1d (single simple parameter functions)
;This code converts them to a zero based index into the function look up table.
        ld      a,c               ;{{d0ec:79}} 
        add     a,a               ;{{d0ed:87}} Doubling A gives us values <initial> - $fe and $00 - <final>
        add     a,simple_function_table - function_table;{{d0ee:c61e}} <function_table>
;d0ee c61e      add     a,$1e    ;(Original) This value is twice the number of entries in the 
                                  ;complex parameter function part of the table (tokens $71 - $7f)
                                  ;Adding it to A gives us our zero based index.
        ld      c,a               ;{{d0f0:4f}} 

;; $00-$1d -> $1e->$58
;; $71-$7f -> $00->$1c
;; $40-$49 -> $9e->$b0

        cp    function_MIN - function_table - 1;{{d0f1:fe59}} ;WARNING: Code area used as literal
;d0f1 fe59      cp      $59             ;(Original) Number of bytes in total function table plus 1
        jr      nc,raise_syntax_error;{{d0f3:30e2}}  Error: Syntax Error
        cp      simple_function_table - function_table - 1;{{d0f5:fe1d}} 
;d0f5 fe1d      cp      $1d              ;(Original) Number of bytes in complex parameter function table + 1
;For these functions we'll make them process their own parameters.
;Presumably for functions which don't take a single, simple, parameter.
;(Contrast with next code section). Tokens $71 - $7f
        jr      c,jp_to_routine_in_function_table;{{d0f7:3809}}  (+$09)

;; $ff prefix, then $00-$1d
;For these functions we'll eval the parameter beforehand and save it some work.
;These are, presumably, functions which take a single, simple, parameter.
;(Contrast with JR immediately above). Tokens $00 - $1d
        call    prefix_open_bracket_;{{d0f9:cdd1d0}} 
        push    hl                ;{{d0fc:e5}} 
        call    jp_to_routine_in_function_table;{{d0fd:cd02d1}} 
        pop     hl                ;{{d100:e1}} 
        ret                       ;{{d101:c9}} 

;;==========================================================================
;;jp to routine in function table
;; $ff prefix, then $71 to $7f

jp_to_routine_in_function_table:  ;{{Addr=$d102 Code Calls/jump count: 2 Data use count: 0}}
        ld      de,function_table ;{{d102:11e5d1}}  functions
;;= jp to routine in table
;; DE=table
;; C=offset
jp_to_routine_in_table:           ;{{Addr=$d105 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d105:e5}} 
        ex      de,hl             ;{{d106:eb}} 
        ld      b,$00             ;{{d107:0600}} 
        add     hl,bc             ;{{d109:09}} 
        ld      a,(hl)            ;{{d10a:7e}} 
        inc     hl                ;{{d10b:23}} 
        ld      h,(hl)            ;{{d10c:66}} 
        ld      l,a               ;{{d10d:6f}} 
        ex      (sp),hl           ;{{d10e:e3}}  Routine address on stack
        ret                       ;{{d10f:c9}} 

;;==========================================================================
;;eval system variables
;; keywords: $ff and $40 to $49
;; 
;; A = keyword index ($40-$49)

eval_system_variables:            ;{{Addr=$d110 Code Calls/jump count: 1 Data use count: 0}}
        add     a,a               ;{{d110:87}} ; $40->$80, $41->$82...
        ld      c,a               ;{{d111:4f}} 

;; A = keyword index
;; C = offset in table
        ld      de,system_variables_table - $80;{{d112:1197d0}}  d117-$80
        jr      jp_to_routine_in_table;{{d115:18ee}} 

;;+------------------------------------------------------------
;; system variables table
system_variables_table:           ;{{Addr=$d117 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defw variable_EOF         ; EOF  ##LABEL##
        defw variable_ERR         ; ERR  ##LABEL##
        defw variable_HIMEM       ; HIMEM  ##LABEL##
        defw variable_INKEY       ; INKEY$  ##LABEL##
        defw variable_PI          ; PI  ##LABEL##
        defw variable_RND         ; RND  ##LABEL##
        defw variable_TIME        ; TIME  ##LABEL##
        defw variable_XPOS        ; XPOS  ##LABEL##
        defw variable_YPOS        ; YPOS  ##LABEL##
        defw variable_DERR        ; DERR  ##LABEL##




;;***SystemVars.asm
;;<< SYSTEM VARIABLES
;;< (most of them). And the @ prefix operator.
;;==========================================================================
;; variable DERR
variable_DERR:                    ;{{Addr=$d12b Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(DERR__Disc_Error_No);{{d12b:3a91ad}} 
        jr      _variable_err_1   ;{{d12e:1803}} 
            
;;==========================================================================
;; variable ERR
variable_ERR:                     ;{{Addr=$d130 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(ERR__Error_No) ;{{d130:3a90ad}} 
_variable_err_1:                  ;{{Addr=$d133 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d133:e5}} 
        call    store_A_in_accumulator_as_INT;{{d134:cd32ff}} 
        pop     hl                ;{{d137:e1}} 
        ret                       ;{{d138:c9}} 

;;==========================================================================
;; variable TIME
variable_TIME:                    ;{{Addr=$d139 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d139:e5}} 
        call    KL_TIME_PLEASE    ;{{d13a:cd0dbd}} ; firmware function: KL TIME PLEASE
        call    store_int_to_accumulator;{{d13d:cda5fe}} 
        pop     hl                ;{{d140:e1}} 
        ret                       ;{{d141:c9}} 

;;=======================================================================
;; prefix ERL

prefix_ERL:                       ;{{Addr=$d142 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d142:e5}} 
        call    get_resume_line_number;{{d143:cdaacb}} 
        jr      store_UINT_to_accumulator;{{d146:1814}}  (+$14)

;;==========================================================================
;; variable HIMEM
variable_HIMEM:                   ;{{Addr=$d148 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d148:e5}} 
        ld      hl,(HIMEM_)       ;{{d149:2a5eae}}  HIMEM
        jr      store_UINT_to_accumulator;{{d14c:180e}}  (+$0e)

;;==========================================================================
;; prefix at operator @
;returns the address of (pointer to) a variable

prefix_at_operator_:              ;{{Addr=$d14e Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_var;{{d14e:cdc9d6}} 
        jp      nc,Error_Improper_Argument;{{d151:d24dcb}}  Error: Improper Argument

        push    hl                ;{{d154:e5}} 
        ex      de,hl             ;{{d155:eb}} 
        ld      a,b               ;{{d156:78}} 
        cp      $03               ;{{d157:fe03}} String type
        call    z,prob_copy_string_to_strings_area;{{d159:cc58fb}} 
;;=store UINT to accumulator
store_UINT_to_accumulator:        ;{{Addr=$d15c Code Calls/jump count: 2 Data use count: 0}}
        call    set_accumulator_as_REAL_from_unsigned_INT;{{d15c:cd89fe}} 
        pop     hl                ;{{d15f:e1}} 
        ret                       ;{{d160:c9}} 

;;==========================================================================
;; variable XPOS
variable_XPOS:                    ;{{Addr=$d161 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d161:e5}} 
        call    GRA_ASK_CURSOR    ;{{d162:cdc6bb}} ; firmware function: gra ask cursor 
        ex      de,hl             ;{{d165:eb}} 
        jr      _variable_ypos_2  ;{{d166:1804}} 

;;==========================================================================
;; variable YPOS
variable_YPOS:                    ;{{Addr=$d168 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d168:e5}} 
        call    GRA_ASK_CURSOR    ;{{d169:cdc6bb}} ; firmware function: gra ask cursor
_variable_ypos_2:                 ;{{Addr=$d16c Code Calls/jump count: 1 Data use count: 0}}
        call    store_HL_in_accumulator_as_INT;{{d16c:cd35ff}} 
        pop     hl                ;{{d16f:e1}} 
        ret                       ;{{d170:c9}} 





;;***DEFFN.asm
;;<< DEF and DEF FN
;;========================================================================
;; command DEF

command_DEF:                      ;{{Addr=$d171 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_equals_inline_data_byte;{{d171:cd25de}} 
        defb $e4                  ; inline token to test "FN"
        ex      de,hl             ;{{d175:eb}} 
        call    get_current_line_number;{{d176:cdb5de}} 
        ex      de,hl             ;{{d179:eb}} 
        ld      a,$0c             ;{{d17a:3e0c}} Invalid direct command error
        jp      nc,raise_error    ;{{d17c:d255cb}} 
        call    parse_and_find_or_create_an_FN;{{d17f:cddbd6}} 
        ex      de,hl             ;{{d182:eb}} 
        ld      (hl),e            ;{{d183:73}} 
        inc     hl                ;{{d184:23}} 
        ld      (hl),d            ;{{d185:72}} 
        ex      de,hl             ;{{d186:eb}} 
        jp      skip_to_end_of_statement;{{d187:c3a3e9}} ; DATA

;;=======================================================================
;; prefix FN

prefix_FN:                        ;{{Addr=$d18a Code Calls/jump count: 0 Data use count: 1}}
        call    parse_and_find_or_create_an_FN;{{d18a:cddbd6}} find the DEF FN for this item
        push    bc                ;{{d18d:c5}} 
        push    hl                ;{{d18e:e5}} 
        ex      de,hl             ;{{d18f:eb}} 
        ld      e,(hl)            ;{{d190:5e}} read DEF FN address
        inc     hl                ;{{d191:23}} 
        ld      d,(hl)            ;{{d192:56}} 
        ex      de,hl             ;{{d193:eb}} HL=DEF FN address. We are now 'executing' the DEF FN code
        ld      a,h               ;{{d194:7c}} is address zero?
        or      l                 ;{{d195:b5}} 
        ld      a,$12             ;{{d196:3e12}} Unknown user function error
        jp      z,raise_error     ;{{d198:ca55cb}} 

;alloc space on execution stack for the FN and any parameters
        call    push_FN_header_on_execution_stack;{{d19b:cd2ada}} 
        ld      a,(hl)            ;{{d19e:7e}} Does the DEF FN have any parameters?
        cp      $28               ;{{d19f:fe28}}  '('
        jr      nz,prefix_FN_execute;{{d1a1:2028}}  (+$28) no params, skip next bit
        call    get_next_token_skipping_space;{{d1a3:cd2cde}}  get next token skipping space
        ex      (sp),hl           ;{{d1a6:e3}} 
        call    next_token_if_open_bracket;{{d1a7:cd19de}}  check for open bracket
        ex      (sp),hl           ;{{d1aa:e3}} 

;;=prefix FN read params loop
prefix_FN_read_params_loop:       ;{{Addr=$d1ab Code Calls/jump count: 1 Data use count: 0}}
        call    push_FN_parameter_on_execution_stack;{{d1ab:cd6ada}} Read both DEF FN definition parameter list...
        ex      (sp),hl           ;{{d1ae:e3}} ...and parameters passed in FN invocation
        push    de                ;{{d1af:d5}} 
        call    eval_expression   ;{{d1b0:cd62cf}} eval parameter
        ex      (sp),hl           ;{{d1b3:e3}} 
        ld      a,b               ;{{d1b4:78}} 
        call    copy_accumulator_to_atHL_as_type_B;{{d1b5:cd9fd6}} 
        pop     hl                ;{{d1b8:e1}} 
        call    next_token_if_prev_is_comma;{{d1b9:cd41de}} more parameters?
        jr      nc,prefix_FN_finished_reading_params;{{d1bc:3006}}  (+$06) nope, done
        ex      (sp),hl           ;{{d1be:e3}} 
        call    next_token_if_comma;{{d1bf:cd15de}}  check for comma
        jr      prefix_FN_read_params_loop;{{d1c2:18e7}}  (-$19)

;;=prefix FN finished reading params
prefix_FN_finished_reading_params:;{{Addr=$d1c4 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_close_bracket;{{d1c4:cd1dde}}  check for close bracket at end of FN
        ex      (sp),hl           ;{{d1c7:e3}} 
        call    next_token_if_close_bracket;{{d1c8:cd1dde}}  check for close bracket at end of DEF FN
;;=prefix FN execute
prefix_FN_execute:                ;{{Addr=$d1cb Code Calls/jump count: 1 Data use count: 0}}
        call    copy_FN_param_start_to_FN_param_end;{{d1cb:cd49da}} tidy up system variables?

        call    next_token_if_equals_sign;{{d1ce:cd21de}} HL=address of the equals sign in the DEF FN
        call    eval_expression   ;{{d1d1:cd62cf}} eval the FN (ie run it as code)
        jp      nz,Error_Syntax_Error;{{d1d4:c249cb}}  Error: Syntax Error
        call    is_accumulator_a_string;{{d1d7:cd66ff}} 
        call    z,copy_accumulator_to_strings_area;{{d1da:cc8afb}} 

        call    remove_FN_data_from_stack;{{d1dd:cd52da}} 
        pop     hl                ;{{d1e0:e1}} 
        pop     af                ;{{d1e1:f1}} 
        jp      convert_accumulator_to_type_in_A;{{d1e2:c3fffe}} 




;;***FunctionTable.asm
;;<< FUNCTION LOOK UP TABLE
;;======================================================
;; function table

;These functions take multiple parameters, or less straight-forward parameter(s).
;The function will have to read it's own parameters.
;Numbers after function names are the tokens
function_table:                   ;{{Addr=$d1e5 Data Calls/jump count: 0 Data use count: 4}}
                                  
        defw function_BIN         ; BIN$ $71 ##LABEL##
        defw function_DEC         ; DEC$ $72 ##LABEL##
        defw function_HEX         ; HEX$ $73 ##LABEL##
        defw function_INSTR       ; INSTR$ $74 ##LABEL##
        defw function_LEFT        ; LEFT$ $75 ##LABEL##
        defw function_MAX         ; MAX $76 ##LABEL##
        defw function_MIN         ; MIN $77 ##LABEL##
        defw function_POS         ; POS $78	  ##LABEL##
        defw function_RIGHT       ; RIGHT$ $79 ##LABEL##
        defw function_ROUND       ; ROUND $7a	  ##LABEL##
        defw function_STRING      ; STRING$ $7b	  ##LABEL##
        defw function_TEST        ; TEST	$7c	  ##LABEL##
        defw function_TESTR       ; TESTR $7d ##LABEL##
        defw function_COPYCHR     ; COPYCHR$	$7e	  ##LABEL##
        defw function_VPOS        ; VPOS $7f ##LABEL##

;;=simple function table
;These functions take a single, simple, parameter. The parameter will be read before the
;function is dispatched and passed to it.
simple_function_table:            ;{{Addr=$d203 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defw function_ABS         ; ABS $00     ##LABEL##
        defw function_ASC         ; ASC $01 ##LABEL##
        defw funciton_ATN         ; ATN $02 ##LABEL##
        defw function_CHR         ; CHR$  ##LABEL##
        defw function_CINT        ; CINT  ##LABEL##
        defw function_COS         ; COS  ##LABEL##
        defw function_CREAL       ; CREAL  ##LABEL##
        defw function_EXP         ; EXP  ##LABEL##
        defw function_FIX         ; FIX  ##LABEL##
        defw function_FRE         ; FRE  ##LABEL##
        defw function_INKEY       ; INKEY  ##LABEL##
        defw function_INP         ; INP  ##LABEL##
        defw function_INT         ; INT  ##LABEL##
        defw function_JOY         ; JOY  ##LABEL##
        defw function_LEN         ; LEN  ##LABEL##
        defw function_LOG         ; LOG  ##LABEL##
        defw function_LOG10       ; LOG10  ##LABEL##
        defw function_LOWER       ; LOWER$  ##LABEL##
        defw function_PEEK        ; PEEK  ##LABEL##
        defw function_REMAIN      ; REMAIN  ##LABEL##
        defw function_SGN         ; SGN  ##LABEL##
        defw function_SIN         ; SIN  ##LABEL##
        defw function_SPACE       ; SPACE$  ##LABEL##
        defw function_SQ          ; SQ  ##LABEL##
        defw function_SQR         ; SQR  ##LABEL##
        defw function_STR         ; STR$  ##LABEL##
        defw function_TAN         ; TAN  ##LABEL##
        defw function_UNT         ; UNT  ##LABEL##
        defw function_UPPER       ; UPPER$  ##LABEL##
        defw function_VAL         ; VAL $1d ##LABEL##




;;***MathsAgain.asm
;;<< MATHS FUNCTIONS MIN, MAX and ROUND
;;========================================================================
;; function MIN
function_MIN:                     ;{{Addr=$d23f Code Calls/jump count: 0 Data use count: 2}}
        ld      b,$ff             ;{{d23f:06ff}} 
        jr      _function_max_1   ;{{d241:1802}}  (+$02)

;;========================================================================
;; function MAX
function_MAX:                     ;{{Addr=$d243 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$01             ;{{d243:0601}} 
;;------------------------------------------------------------------------
_function_max_1:                  ;{{Addr=$d245 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{d245:cd62cf}} 
_function_max_2:                  ;{{Addr=$d248 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{d248:cd41de}} 
        jp      nc,next_token_if_close_bracket;{{d24b:d21dde}}  check for close bracket
        call    probably_push_accumulator_on_execution_stack;{{d24e:cd74ff}} 
        call    eval_expression   ;{{d251:cd62cf}} 
        push    hl                ;{{d254:e5}} 
        ld      a,c               ;{{d255:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d256:cd62f6}} 
        push    bc                ;{{d259:c5}} 
        push    hl                ;{{d25a:e5}} 
        call    infix_comparisons_plural;{{d25b:cd49fd}} 
        pop     hl                ;{{d25e:e1}} 
        pop     bc                ;{{d25f:c1}} 
        or      a                 ;{{d260:b7}} 
        jr      z,_function_max_18;{{d261:2804}}  (+$04)
        cp      b                 ;{{d263:b8}} 
        call    nz,copy_atHL_to_accumulator_using_accumulator_type;{{d264:c46fff}} 
_function_max_18:                 ;{{Addr=$d267 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{d267:e1}} 
        jr      _function_max_2   ;{{d268:18de}}  (-$22)

;;========================================================================
;; function ROUND
function_ROUND:                   ;{{Addr=$d26a Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{d26a:cd62cf}} 
        call    probably_push_accumulator_on_execution_stack;{{d26d:cd74ff}} 
        call    next_token_if_prev_is_comma;{{d270:cd41de}} 
        ld      de,$0000          ;{{d273:110000}} ##LIT##
        call    c,eval_expr_as_int;{{d276:dcd8ce}}  get number
        call    next_token_if_close_bracket;{{d279:cd1dde}}  check for close bracket
        push    hl                ;{{d27c:e5}} 
        push    de                ;{{d27d:d5}} 
        ld      hl,$0027          ;{{d27e:212700}} 
        add     hl,de             ;{{d281:19}} 
        ld      de,$004f          ;{{d282:114f00}} 
        call    compare_HL_DE     ;{{d285:cdd8ff}}  HL=DE?
        jp      nc,Error_Improper_Argument;{{d288:d24dcb}}  Error: Improper Argument
        pop     de                ;{{d28b:d1}} 
        ld      a,c               ;{{d28c:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{d28d:cd62f6}} 
        ld      b,e               ;{{d290:43}} 
        call    round_accumulator ;{{d291:cdd5fd}} 
        pop     hl                ;{{d294:e1}} 
        ret                       ;{{d295:c9}} 


;;***FileIO.asm
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




;;***Sound.asm
;;<< SOUND FUNCTIONS
;;========================================================================
;; command SOUND
command_SOUND:                    ;{{Addr=$d313 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_byte_or_error;{{d313:cdb8ce}}  get number and check it's less than 255 
        ld      (Current_SOUND_parameter_block_),a;{{d316:3299ad}} 
        call    next_token_if_comma;{{d319:cd15de}}  check for comma
        call    eval_and_validate_tone_period;{{d31c:cd4cd4}} 
        ld      (tone_period),de  ;{{d31f:ed539cad}} 
        call    next_token_if_prev_is_comma;{{d323:cd41de}} 
        ld      de,$0014          ;{{d326:111400}} 
        call    c,eval_expr_as_int;{{d329:dcd8ce}}  get number
        ld      (duration_or_envelope_repeat_count),de;{{d32c:ed53a0ad}} 
        ld      bc,$100c          ;{{d330:010c10}} 
        call    eval_and_validate_sound_parameter;{{d333:cd5fd3}} 
        ld      (initial_amplitude),a;{{d336:329fad}} 
        ld      c,$00             ;{{d339:0e00}} 
        call    eval_and_validate_sound_parameter;{{d33b:cd5fd3}} 
        ld      (amplitude_envelope_),a;{{d33e:329aad}} 
        call    eval_and_validate_sound_parameter;{{d341:cd5fd3}} 
        ld      (tone_envelope_),a;{{d344:329bad}} 
        ld      b,$20             ;{{d347:0620}} 
        call    eval_and_validate_sound_parameter;{{d349:cd5fd3}} 
        ld      (noise_period),a  ;{{d34c:329ead}} 
        call    syntax_error_if_not_02;{{d34f:cd37de}} 
        push    hl                ;{{d352:e5}} 
        ld      hl,Current_SOUND_parameter_block_;{{d353:2199ad}} 
        call    SOUND_QUEUE       ;{{d356:cdaabc}}  firmware function: sound queue
        pop     hl                ;{{d359:e1}} 
        ret     c                 ;{{d35a:d8}} 

        pop     af                ;{{d35b:f1}} 
        jp      execute_tokenised_line;{{d35c:c35dde}} 

;;=eval and validate sound parameter
eval_and_validate_sound_parameter:;{{Addr=$d35f Code Calls/jump count: 4 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{d35f:cd41de}} 
        ld      a,c               ;{{d362:79}} 
        ret     nc                ;{{d363:d0}} 

        ld      a,(hl)            ;{{d364:7e}} 
        cp      $2c               ;{{d365:fe2c}} 
        ld      a,c               ;{{d367:79}} 
        ret     z                 ;{{d368:c8}} 

;;=eval expr and check less than B
eval_expr_and_check_less_than_B:  ;{{Addr=$d369 Code Calls/jump count: 7 Data use count: 0}}
        call    eval_expr_as_byte_or_error;{{d369:cdb8ce}}  get number and check it's less than 255 
        cp      b                 ;{{d36c:b8}} 
        ret     c                 ;{{d36d:d8}} 

        jr      raise_improper_argument_error_D;{{d36e:182b}}  (+$2b)

;;========================================================================
;; command RELEASE

command_RELEASE:                  ;{{Addr=$d370 Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$08             ;{{d370:0608}} 
        call    eval_expr_and_check_less_than_B;{{d372:cd69d3}} 
        push    hl                ;{{d375:e5}} 
        call    SOUND_RELEASE     ;{{d376:cdb3bc}}  firmware function: sound release
        pop     hl                ;{{d379:e1}} 
        ret                       ;{{d37a:c9}} 

;;========================================================
;; function SQ

function_SQ:                      ;{{Addr=$d37b Code Calls/jump count: 0 Data use count: 1}}
        call    function_CINT     ;{{d37b:cdb6fe}} 
        ld      a,l               ;{{d37e:7d}} 
        or      a                 ;{{d37f:b7}} 
        rra                       ;{{d380:1f}} 
        jr      c,_function_sq_9  ;{{d381:3806}}  (+$06)
        rra                       ;{{d383:1f}} 
        jr      c,_function_sq_9  ;{{d384:3803}}  (+$03)
        rra                       ;{{d386:1f}} 
        jr      nc,raise_improper_argument_error_D;{{d387:3012}}  (+$12)
_function_sq_9:                   ;{{Addr=$d389 Code Calls/jump count: 2 Data use count: 0}}
        or      h                 ;{{d389:b4}} 
        jr      nz,raise_improper_argument_error_D;{{d38a:200f}}  (+$0f)
        ld      a,l               ;{{d38c:7d}} 
        call    SOUND_CHECK       ;{{d38d:cdadbc}}  firmware function: sound check
        jp      store_A_in_accumulator_as_INT;{{d390:c332ff}} 

;;=eval expr and validate less than 128
eval_expr_and_validate_less_than_128:;{{Addr=$d393 Code Calls/jump count: 2 Data use count: 0}}
        call    eval_expr_as_int  ;{{d393:cdd8ce}}  get number
        ld      a,e               ;{{d396:7b}} 
        add     a,a               ;{{d397:87}} 
        sbc     a,a               ;{{d398:9f}} 
        cp      d                 ;{{d399:ba}} 
        ret     z                 ;{{d39a:c8}} 

;;=raise improper argument error
raise_improper_argument_error_D:  ;{{Addr=$d39b Code Calls/jump count: 7 Data use count: 0}}
        jp      Error_Improper_Argument;{{d39b:c34dcb}}  Error: Improper Argument

;;========================================================================
;; command ENV

;; get envelope number (must be between 0 and 15)
command_ENV:                      ;{{Addr=$d39e Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_int_less_than_256;{{d39e:cdc3ce}} 
        cp      $10               ;{{d3a1:fe10}}  16
        jr      nc,raise_improper_argument_error_D;{{d3a3:30f6}} 

        push    af                ;{{d3a5:f5}} 
        ld      de,callback_for_ENV;{{d3a6:11b7d3}}  read parameters    ##LABEL##
        call    read_parameters_for_ENV_and_ENT;{{d3a9:cd25d4}} 
        pop     af                ;{{d3ac:f1}} 
        push    hl                ;{{d3ad:e5}} 
        ld      hl,Current_Amplitude_or_Tone_Envelope_param;{{d3ae:21a2ad}} 
        ld      (hl),c            ;{{d3b1:71}}  number of sections

        call    SOUND_AMPL_ENVELOPE;{{d3b2:cdbcbc}}  firmware function: sound ampl envelope
        pop     hl                ;{{d3b5:e1}} 
        ret                       ;{{d3b6:c9}} 

;;----------------------------------
;;=callback for ENV
callback_for_ENV:                 ;{{Addr=$d3b7 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(hl)            ;{{d3b7:7e}} 
        cp      $ef               ;{{d3b8:feef}}  equals???
        jr      nz,_callback_for_env_10;{{d3ba:2011}} 

        call    get_next_token_skipping_space;{{d3bc:cd2cde}}  get next token skipping space
        ld      b,$10             ;{{d3bf:0610}} 
        call    eval_expr_and_check_less_than_B;{{d3c1:cd69d3}}  get number and check less than 255
        or      $80               ;{{d3c4:f680}} 
        ld      c,a               ;{{d3c6:4f}} 
        call    next_token_if_comma;{{d3c7:cd15de}}  check for comma
        jp      eval_expr_as_uint ;{{d3ca:c3f5ce}} 

;; ------------------------------?
_callback_for_env_10:             ;{{Addr=$d3cd Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$80             ;{{d3cd:0680}} 
        call    eval_expr_and_check_less_than_B;{{d3cf:cd69d3}}  get number and check less than 255
        jr      _callback_for_ent_12;{{d3d2:1840}}  (+$40)

;;========================================================================
;; command ENT

command_ENT:                      ;{{Addr=$d3d4 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_and_validate_less_than_128;{{d3d4:cd93d3}}  get number
        ld      a,d               ;{{d3d7:7a}} 
        or      a                 ;{{d3d8:b7}} 
        ld      a,e               ;{{d3d9:7b}} 
        jr      z,_command_ent_7  ;{{d3da:2802}}  (+$02)

;; negate?
        cpl                       ;{{d3dc:2f}} 
        inc     a                 ;{{d3dd:3c}} 

_command_ent_7:                   ;{{Addr=$d3de Code Calls/jump count: 1 Data use count: 0}}
        ld      e,a               ;{{d3de:5f}} 
        or      a                 ;{{d3df:b7}} 
        jr      z,raise_improper_argument_error_D;{{d3e0:28b9}}  (-$47)

        cp      $10               ;{{d3e2:fe10}}  16
        jr      nc,raise_improper_argument_error_D;{{d3e4:30b5}} 

        push    de                ;{{d3e6:d5}} 
        ld      de,callback_for_ENT;{{d3e7:11fdd3}}  read parameters   ##LABEL##
        call    read_parameters_for_ENV_and_ENT;{{d3ea:cd25d4}} 
        pop     de                ;{{d3ed:d1}} 
        push    hl                ;{{d3ee:e5}} 
        ld      hl,Current_Amplitude_or_Tone_Envelope_param;{{d3ef:21a2ad}} 
        ld      a,d               ;{{d3f2:7a}} 
        and     $80               ;{{d3f3:e680}} 
        or      c                 ;{{d3f5:b1}} 
        ld      (hl),a            ;{{d3f6:77}} 
        ld      a,e               ;{{d3f7:7b}} 
        call    SOUND_TONE_ENVELOPE;{{d3f8:cdbfbc}}  firmware function: sound tone envelope
        pop     hl                ;{{d3fb:e1}} 
        ret                       ;{{d3fc:c9}} 

;;--------------------------------------
;;=callback for ENT
callback_for_ENT:                 ;{{Addr=$d3fd Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(hl)            ;{{d3fd:7e}} 
        cp      $ef               ;{{d3fe:feef}} 
        jr      nz,_callback_for_ent_10;{{d400:200d}}  (+$0d)

        call    get_next_token_skipping_space;{{d402:cd2cde}}  get next token skipping space
        call    eval_and_validate_tone_period;{{d405:cd4cd4}} 
        ld      a,d               ;{{d408:7a}} 
        add     a,$f0             ;{{d409:c6f0}} 
        ld      c,a               ;{{d40b:4f}} 
        ld      b,e               ;{{d40c:43}} 
        jr      _callback_for_ent_16;{{d40d:180d}}  (+$0d)

_callback_for_ent_10:             ;{{Addr=$d40f Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$f0             ;{{d40f:06f0}} 
        call    eval_expr_and_check_less_than_B;{{d411:cd69d3}} 
_callback_for_ent_12:             ;{{Addr=$d414 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{d414:4f}} 
        call    next_token_if_comma;{{d415:cd15de}}  check for comma
        call    eval_expr_and_validate_less_than_128;{{d418:cd93d3}} 
        ld      b,e               ;{{d41b:43}} 
_callback_for_ent_16:             ;{{Addr=$d41c Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_comma;{{d41c:cd15de}}  check for comma
        call    eval_expr_as_byte_or_error;{{d41f:cdb8ce}}  get number and check it's less than 255 
        ld      d,a               ;{{d422:57}} 
        ld      e,b               ;{{d423:58}} 
        ret                       ;{{d424:c9}} 

;;==================================
;;read parameters for ENV and ENT
; DE = address of subroutine to eval parameters for a single step
read_parameters_for_ENV_and_ENT:  ;{{Addr=$d425 Code Calls/jump count: 2 Data use count: 0}}
        ld      bc,$0500          ;{{d425:010005}} 
_read_parameters_for_env_and_ent_1:;{{Addr=$d428 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{d428:cd41de}} 
        jr      nc,_read_parameters_for_env_and_ent_25;{{d42b:301c}}  (+$1c)
        push    de                ;{{d42d:d5}} push callback as return address
        push    bc                ;{{d42e:c5}} 
        call    JP_DE             ;{{d42f:cdfeff}}  JP (DE)
        ld      a,c               ;{{d432:79}} 
        pop     bc                ;{{d433:c1}} 
        push    bc                ;{{d434:c5}} 
        push    hl                ;{{d435:e5}} 
        ld      hl,first_section_of_the_envelope;{{d436:21a3ad}} 
        ld      b,$00             ;{{d439:0600}} 
        add     hl,bc             ;{{d43b:09}} 
        add     hl,bc             ;{{d43c:09}} 
        add     hl,bc             ;{{d43d:09}} 
        ld      (hl),a            ;{{d43e:77}} 
        inc     hl                ;{{d43f:23}} 
        ld      (hl),e            ;{{d440:73}} 
        inc     hl                ;{{d441:23}} 
        ld      (hl),d            ;{{d442:72}} 
        pop     hl                ;{{d443:e1}} 
        pop     bc                ;{{d444:c1}} 
        inc     c                 ;{{d445:0c}} 
        pop     de                ;{{d446:d1}} 
        djnz    _read_parameters_for_env_and_ent_1;{{d447:10df}}  (-$21)
_read_parameters_for_env_and_ent_25:;{{Addr=$d449 Code Calls/jump count: 1 Data use count: 0}}
        jp      syntax_error_if_not_02;{{d449:c337de}} 

;;=eval and validate tone period
eval_and_validate_tone_period:    ;{{Addr=$d44c Code Calls/jump count: 2 Data use count: 0}}
        call    eval_expr_as_int  ;{{d44c:cdd8ce}}  get number
        ld      a,d               ;{{d44f:7a}} 
        and     $f0               ;{{d450:e6f0}} 
        jp      nz,raise_improper_argument_error_D;{{d452:c29bd3}} 
        ret                       ;{{d455:c9}} 





;;***Input.asm
;;<< INPUT FUNCTIONS
;;< INKEY, JOY, KEY (DEF). Also SPEED (WRITE/KEY/INK)
;;========================================================
;; function INKEY
function_INKEY:                   ;{{Addr=$d456 Code Calls/jump count: 0 Data use count: 1}}
        call    function_CINT     ;{{d456:cdb6fe}} 
        ld      de,$0050          ;{{d459:115000}} 
        call    compare_HL_DE     ;{{d45c:cdd8ff}}  HL=DE?
        jr      nc,raise_improper_argument;{{d45f:3022}}  (+$22)
        ld      a,l               ;{{d461:7d}} 
        call    KM_TEST_KEY       ;{{d462:cd1ebb}}  firmware function: km read key
        ld      hl,$ffff          ;{{d465:21ffff}} ##LIT##;WARNING: Code area used as literal
        jr      z,_function_inkey_10;{{d468:2803}}  (+$03)
        ld      l,c               ;{{d46a:69}} 
        ld      h,$00             ;{{d46b:2600}} 
_function_inkey_10:               ;{{Addr=$d46d Code Calls/jump count: 1 Data use count: 0}}
        jp      store_HL_in_accumulator_as_INT;{{d46d:c335ff}} 

;;========================================================
;; function JOY
function_JOY:                     ;{{Addr=$d470 Code Calls/jump count: 0 Data use count: 1}}
        call    KM_GET_JOYSTICK   ;{{d470:cd24bb}}  firmware function: km get joystick
        ex      de,hl             ;{{d473:eb}} 
        call    function_CINT     ;{{d474:cdb6fe}} 
        ld      a,h               ;{{d477:7c}} 
        or      l                 ;{{d478:b5}} 
        jr      z,_function_joy_8 ;{{d479:2802}}  (+$02)
        ld      d,e               ;{{d47b:53}} 
        dec     hl                ;{{d47c:2b}} 
_function_joy_8:                  ;{{Addr=$d47d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{d47d:7c}} 
        or      l                 ;{{d47e:b5}} 
        ld      a,d               ;{{d47f:7a}} 
        jp      z,store_A_in_accumulator_as_INT;{{d480:ca32ff}} 

;;=raise improper argument
raise_improper_argument:          ;{{Addr=$d483 Code Calls/jump count: 2 Data use count: 0}}
        jp      Error_Improper_Argument;{{d483:c34dcb}}  Error: Improper Argument

;;========================================================================
;; command KEY

command_KEY:                      ;{{Addr=$d486 Code Calls/jump count: 0 Data use count: 1}}
        cp      $8d               ;{{d486:fe8d}}  DEF token
        jr      z,KEY_DEF         ;{{d488:2816}}  

        call    eval_expr_as_byte_or_error;{{d48a:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{d48d:f5}} 
        call    next_token_if_comma;{{d48e:cd15de}}  check for comma
        call    eval_expr_as_string_and_get_length;{{d491:cd03cf}} 
        ld      c,b               ;{{d494:48}} 
        pop     af                ;{{d495:f1}} 
        ld      b,a               ;{{d496:47}} 
        push    hl                ;{{d497:e5}} 
        ex      de,hl             ;{{d498:eb}} 
        call    KM_SET_EXPAND     ;{{d499:cd0fbb}}  firmware function: KM SET EXPAND
        pop     hl                ;{{d49c:e1}} 
        jr      nc,raise_improper_argument;{{d49d:30e4}}  (-$1c)
        ret                       ;{{d49f:c9}} 

;;========================================================================
;; KEY DEF
KEY_DEF:                          ;{{Addr=$d4a0 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{d4a0:cd2cde}}  get next token skipping space
        ld      b,$50             ;{{d4a3:0650}} 
        call    eval_expr_and_check_less_than_B;{{d4a5:cd69d3}} 
        ld      c,a               ;{{d4a8:4f}} 
        call    next_token_if_comma;{{d4a9:cd15de}}  check for comma
        ld      b,$02             ;{{d4ac:0602}} 
        call    eval_expr_and_check_less_than_B;{{d4ae:cd69d3}} 
        rra                       ;{{d4b1:1f}} 
        sbc     a,a               ;{{d4b2:9f}} 
        ld      b,a               ;{{d4b3:47}} 
        push    bc                ;{{d4b4:c5}} 
        push    hl                ;{{d4b5:e5}} 
        ld      a,c               ;{{d4b6:79}} 
        call    KM_SET_REPEAT     ;{{d4b7:cd39bb}}  firmware function: KM SET REPEAT
        pop     hl                ;{{d4ba:e1}} 
        pop     bc                ;{{d4bb:c1}} 
        ld      de,KM_SET_TRANSLATE;{{d4bc:1127bb}}  KM SET TRANSLATE
        call    _key_def_21       ;{{d4bf:cdcbd4}} 
        ld      de,KM_SET_SHIFT   ;{{d4c2:112dbb}}  KM SET SHIFT
        call    _key_def_21       ;{{d4c5:cdcbd4}} 
        ld      de,KM_SET_CONTROL ;{{d4c8:1133bb}}  KM SET CONTROL
_key_def_21:                      ;{{Addr=$d4cb Code Calls/jump count: 2 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{d4cb:cd41de}} 
        ret     nc                ;{{d4ce:d0}} 

        push    de                ;{{d4cf:d5}} 
        call    eval_expr_as_byte_or_error;{{d4d0:cdb8ce}}  get number and check it's less than 255 
        ld      b,a               ;{{d4d3:47}} 
        ex      (sp),hl           ;{{d4d4:e3}} 
        ld      a,c               ;{{d4d5:79}} 
        call    JP_HL             ;{{d4d6:cdfbff}}  JP (HL)
        pop     hl                ;{{d4d9:e1}} 
        ret                       ;{{d4da:c9}} 

;;========================================================================
;; command SPEED WRITE, SPEED KEY, SPEED INK

command_SPEED_WRITE_SPEED_KEY_SPEED_INK:;{{Addr=$d4db Code Calls/jump count: 0 Data use count: 1}}
        cp      $d9               ;{{d4db:fed9}}  token for "WRITE"
        jr      z,do_SPEED_WRITE  ;{{d4dd:2826}} 

        cp      $a4               ;{{d4df:fea4}}  token for "KEY"
        ld      bc,KM_SET_DELAY   ;{{d4e1:013fbb}}  firmware function: KM SET DELAY
        jr      z,do_SPEED_KEY_SPEED_INK;{{d4e4:2808}}  
        cp      $a2               ;{{d4e6:fea2}}  token for "INK"
        ld      bc,SCR_SET_FLASHING;{{d4e8:013ebc}}  firmware function: SCR SET FLASHING
        jp      nz,Error_Syntax_Error;{{d4eb:c249cb}}  Error: Syntax Error

;;=do SPEED KEY, SPEED INK
do_SPEED_KEY_SPEED_INK:           ;{{Addr=$d4ee Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{d4ee:c5}} BC = routine to call to set delay
        call    get_next_token_skipping_space;{{d4ef:cd2cde}}  get next token skipping space
        call    eval_expr_as_int_less_than_256;{{d4f2:cdc3ce}} 
        ld      c,a               ;{{d4f5:4f}} 
        call    next_token_if_comma;{{d4f6:cd15de}}  check for comma
        call    eval_expr_as_int_less_than_256;{{d4f9:cdc3ce}} 
        ld      e,a               ;{{d4fc:5f}} 
        ld      d,c               ;{{d4fd:51}} 
        pop     bc                ;{{d4fe:c1}} 
        ex      de,hl             ;{{d4ff:eb}} 
        call    JP_BC             ;{{d500:cdfcff}}  JP (BC)
        ex      de,hl             ;{{d503:eb}} 
        ret                       ;{{d504:c9}} 

;;=do SPEED WRITE
do_SPEED_WRITE:                   ;{{Addr=$d505 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{d505:cd2cde}}  get next token skipping space
        ld      b,$02             ;{{d508:0602}} 
        call    eval_expr_and_check_less_than_B;{{d50a:cd69d3}} 
        push    hl                ;{{d50d:e5}} 
        ld      hl,$00a7          ;{{d50e:21a700}} 
        dec     a                 ;{{d511:3d}} 
        ld      a,$32             ;{{d512:3e32}} 
        jr      z,_do_speed_write_10;{{d514:2802}}  (+$02)
        add     hl,hl             ;{{d516:29}} 
        rrca                      ;{{d517:0f}} 
_do_speed_write_10:               ;{{Addr=$d518 Code Calls/jump count: 1 Data use count: 0}}
        call    CAS_SET_SPEED     ;{{d518:cd68bc}}  firmware function: cas set speed
        pop     hl                ;{{d51b:e1}} 
        ret                       ;{{d51c:c9}} 


;;***MathsFunctions.asm
;;<< (REAL) MATHS FUNCTIONS
;;< Including ^ and random numbers
;;========================================================================
;; variable PI

variable_PI:                      ;{{Addr=$d51d Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d51d:e5}} 
        call    set_accumulator_type_to_real;{{d51e:cd41ff}} 
        call    get_accumulator_type_in_c_and_addr_in_HL;{{d521:cd45ff}} 
        call    REAL_PI           ;{{d524:cd9abd}} 
        pop     hl                ;{{d527:e1}} 
        ret                       ;{{d528:c9}} 

;;========================================================================
;; command DEG
command_DEG:                      ;{{Addr=$d529 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$ff             ;{{d529:3eff}} 
        jr      _command_rad_1    ;{{d52b:1801}}  (+$01)

;;========================================================================
;; command RAD

command_RAD:                      ;{{Addr=$d52d Code Calls/jump count: 0 Data use count: 1}}
        xor     a                 ;{{d52d:af}} 
_command_rad_1:                   ;{{Addr=$d52e Code Calls/jump count: 1 Data use count: 0}}
        jp      SET_ANGLE_MODE    ;{{d52e:c397bd}}  maths: set angle mode

;;========================================================
;; function SQR

function_SQR:                     ;{{Addr=$d531 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_SQR       ;{{d531:019dbd}} 
        jr      read_real_param_and_validate;{{d534:1816}}  (+$16)

;;========================================================
;; infix power ^
infix_power_:                     ;{{Addr=$d536 Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{d536:e5}} 
        push    bc                ;{{d537:c5}} 
        call    function_CREAL    ;{{d538:cd14ff}} 
        ex      de,hl             ;{{d53b:eb}} 
        ld      hl,RAM_adb2       ;{{d53c:21b2ad}} 
        call    REAL_copy_atDE_to_atHL;{{d53f:cd61bd}} 
        pop     bc                ;{{d542:c1}} 
        ex      (sp),hl           ;{{d543:e3}} 
        ld      a,c               ;{{d544:79}} 
        call    copy_atHL_to_accumulator_type_A;{{d545:cd6cff}} 
        pop     de                ;{{d548:d1}} 
        ld      bc,REAL_POWER     ;{{d549:01a0bd}} 

;;+-----------------
;; read real param and validate

read_real_param_and_validate:     ;{{Addr=$d54c Code Calls/jump count: 8 Data use count: 0}}
        call    read_real_param   ;{{d54c:cd59d5}} 
        ret     c                 ;{{d54f:d8}} 

        jp      z,division_by_zero_error;{{d550:cab5cb}} 
        jp      m,overflow_error  ;{{d553:fabecb}} 
        jp      Error_Improper_Argument;{{d556:c34dcb}}  Error: Improper Argument

;;= read real param
read_real_param:                  ;{{Addr=$d559 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{d559:c5}} 
        push    de                ;{{d55a:d5}} 
        call    function_CREAL    ;{{d55b:cd14ff}} 
        pop     de                ;{{d55e:d1}} 
        ret                       ;{{d55f:c9}} 

;;========================================================
;; function EXP
function_EXP:                     ;{{Addr=$d560 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_EXP       ;{{d560:01a9bd}} 
        jr      read_real_param_and_validate;{{d563:18e7}}  (-$19)

;;========================================================
;; function LOG10

function_LOG10:                   ;{{Addr=$d565 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_LOG_10    ;{{d565:01a6bd}} 
        jr      read_real_param_and_validate;{{d568:18e2}}  (-$1e)

;;========================================================
;; function LOG
function_LOG:                     ;{{Addr=$d56a Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_LOG       ;{{d56a:01a3bd}} 
        jr      read_real_param_and_validate;{{d56d:18dd}}  (-$23)

;;========================================================
;; function SIN

function_SIN:                     ;{{Addr=$d56f Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_SINE      ;{{d56f:01acbd}} 
        jr      read_real_param_and_validate;{{d572:18d8}}  (-$28)

;;========================================================
;; function COS
function_COS:                     ;{{Addr=$d574 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_COSINE    ;{{d574:01afbd}} 
        jr      read_real_param_and_validate;{{d577:18d3}}  (-$2d)

;;========================================================
;; function TAN

function_TAN:                     ;{{Addr=$d579 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_TANGENT   ;{{d579:01b2bd}} 
        jr      read_real_param_and_validate;{{d57c:18ce}}  (-$32)

;;========================================================
;; funciton ATN
funciton_ATN:                     ;{{Addr=$d57e Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,REAL_ARCTANGENT;{{d57e:01b5bd}} 
        jr      read_real_param_and_validate;{{d581:18c9}}  (-$37)

;;========================================================================
;; random number seed message
random_number_seed_message:       ;{{Addr=$d583 Data Calls/jump count: 0 Data use count: 1}}
        defb "Random number seed ? ",0
;;========================================================================
;; command RANDOMIZE
command_RANDOMIZE:                ;{{Addr=$d599 Code Calls/jump count: 0 Data use count: 1}}
        jr      z,random_seed_prompt;{{d599:2806}}  (+$06) Do we have inline parameter, if not prompt for input
        call    eval_expression   ;{{d59b:cd62cf}}  if so read it
        push    hl                ;{{d59e:e5}}  Save code ptr
        jr      dorandomize       ;{{d59f:1818}}  (+$18)

;;=random seed prompt
random_seed_prompt:               ;{{Addr=$d5a1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d5a1:e5}}  Save code ptr
;;=random seed loop
random_seed_loop:                 ;{{Addr=$d5a2 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,random_number_seed_message;{{d5a2:2183d5}} ; "Random number seed?" message
        call    output_ASCIIZ_string;{{d5a5:cd8bc3}} ; display 0 terminated string
        call    prob_read_buffer_and_or_break;{{d5a8:cdecca}}  Key input text
        call    output_new_line   ;{{d5ab:cd98c3}} ; new text line
        call    possibly_validate_input_buffer_is_a_number;{{d5ae:cd6fed}}  Validate/convert to a number
        jr      nc,random_seed_loop;{{d5b1:30ef}}  (-$11) Loop if invalid
        call    skip_space_tab_or_line_feed;{{d5b3:cd4dde}}  skip space, lf or tab
        or      a                 ;{{d5b6:b7}} 
        jr      nz,random_seed_loop;{{d5b7:20e9}}  (-$17) Loop if invalid

;;=do_randomize
dorandomize:                      ;{{Addr=$d5b9 Code Calls/jump count: 1 Data use count: 0}}
        call    function_CREAL    ;{{d5b9:cd14ff}}  Convert to a real
        call    REAL_RANDOMIZE_seed;{{d5bc:cdbebd}}  Firmware: RANDOMIZE seed
        pop     hl                ;{{d5bf:e1}}  Retrieve code ptr
        ret                       ;{{d5c0:c9}} 

;;========================================================================
;; variable RND

variable_RND:                     ;{{Addr=$d5c1 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,(hl)            ;{{d5c1:7e}} Do we have a parameter?
        cp      $28               ;{{d5c2:fe28}}  '('
        jr      nz,rnd_generate   ;{{d5c4:201b}} If not return simple value

        call    get_next_token_skipping_space;{{d5c6:cd2cde}}  get next token skipping space
        call    eval_expression   ;{{d5c9:cd62cf}} 
        call    next_token_if_close_bracket;{{d5cc:cd1dde}}  check for close bracket
        push    hl                ;{{d5cf:e5}} 
        call    function_CREAL    ;{{d5d0:cd14ff}} 
        call    REAL_SIGNUMSGN    ;{{d5d3:cd94bd}} Is parameter +ve, zero or -ve?
        jr      nz,rnd_param_nonzero;{{d5d6:2005}}  (+$05) Non-zero
        call    REAL_rnd0         ;{{d5d8:cd8bbd}} If zero, return copy of previous value
        pop     hl                ;{{d5db:e1}} 
        ret                       ;{{d5dc:c9}} 

;;=rnd param non-zero
rnd_param_nonzero:                ;{{Addr=$d5dd Code Calls/jump count: 1 Data use count: 0}}
        call    m,REAL_RANDOMIZE_seed;{{d5dd:fcbebd}} If parameter is negative, new random seed
        pop     hl                ;{{d5e0:e1}} 
;;=rnd generate
rnd_generate:                     ;{{Addr=$d5e1 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{d5e1:e5}} 
        call    set_accumulator_type_to_real_and_HL_to_accumulator_addr;{{d5e2:cd3eff}} 
        call    REAL_RND          ;{{d5e5:cd7fbd}} 
        pop     hl                ;{{d5e8:e1}} 
        ret                       ;{{d5e9:c9}} 





;;***VariableArrayFN.asm
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




;;***DataInput.asm
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




;;***IntegerMaths.asm
;;<< INTEGER MATHS
;;< (used both internally and by functions)
;;=====================================
;;unknown maths fixup
unknown_maths_fixup:              ;{{Addr=$dd2a Code Calls/jump count: 1 Data use count: 0}}
        ld      b,h               ;{{dd2a:44}} 
        call    negate_HL_if_negative_and_test_if_INT;{{dd2b:cdeadd}} 
        jr      set_E_zero_C_to_2_int_type;{{dd2e:1802}}  (+$02)

;;=set B zero E zero C to 2 int type
set_B_zero_E_zero_C_to_2_int_type:;{{Addr=$dd30 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{dd30:0600}} 
;;=set E zero C to 2 int type
set_E_zero_C_to_2_int_type:       ;{{Addr=$dd32 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,$00             ;{{dd32:1e00}} 
        ld      c,$02             ;{{dd34:0e02}} 
        ret                       ;{{dd36:c9}} 

;;=unknown maths fixup
;Bit 7 of B = invert value in HL
unknown_maths_fixup_B:            ;{{Addr=$dd37 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,h               ;{{dd37:7c}} 
        or      a                 ;{{dd38:b7}} 
        jp      m,unknown_maths_fixup_C;{{dd39:fa42dd}} 
        or      b                 ;{{dd3c:b0}} 
        jp      m,negate_HL_and_test_if_INT;{{dd3d:faeddd}} 
        scf                       ;{{dd40:37}} 
        ret                       ;{{dd41:c9}} 

;;--------------------------------------------------------------
;;=unknown maths fixup
unknown_maths_fixup_C:            ;{{Addr=$dd42 Code Calls/jump count: 1 Data use count: 0}}
        xor     $80               ;{{dd42:ee80}} Toggle bit 7
        or      l                 ;{{dd44:b5}} 
        ret     nz                ;{{dd45:c0}} 

        ld      a,b               ;{{dd46:78}} 
        scf                       ;{{dd47:37}} 
        adc     a,a               ;{{dd48:8f}} A = 2 * B + 1
        ret                       ;{{dd49:c9}} 

;;================================================================
;;INT addition with overflow test
INT_addition_with_overflow_test:  ;{{Addr=$dd4a Code Calls/jump count: 2 Data use count: 0}}
        or      a                 ;{{dd4a:b7}} 
        adc     hl,de             ;{{dd4b:ed5a}} 
        scf                       ;{{dd4d:37}} 
        ret     po                ;{{dd4e:e0}} 

        or      $ff               ;{{dd4f:f6ff}} 
        ret                       ;{{dd51:c9}} 

;;==============================================
;;INT subtraction with overflow test
INT_subtraction_with_overflow_test:;{{Addr=$dd52 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{dd52:eb}} 
        or      a                 ;{{dd53:b7}} 
        sbc     hl,de             ;{{dd54:ed52}} 
        scf                       ;{{dd56:37}} 
        ret     po                ;{{dd57:e0}} 

        or      $ff               ;{{dd58:f6ff}} 
        ret                       ;{{dd5a:c9}} 

;;=============================================
;;INT multiply with overflow test
INT_multiply_with_overflow_test:  ;{{Addr=$dd5b Code Calls/jump count: 1 Data use count: 0}}
        call    make_both_operands_positive;{{dd5b:cd67dd}} 
        call    do_16x16_multiply_with_overflow;{{dd5e:cd72dd}} 
        jp      nc,unknown_maths_fixup_B;{{dd61:d237dd}} negate result if operands where different signs (B bit 7 set) and ??
        or      $ff               ;{{dd64:f6ff}} 
        ret                       ;{{dd66:c9}} 

;;=make both operands positive
make_both_operands_positive:      ;{{Addr=$dd67 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{dd67:7c}} 
        xor     d                 ;{{dd68:aa}} 
        ld      b,a               ;{{dd69:47}} Bit 7 of B = are both operands the same sign?
        ex      de,hl             ;{{dd6a:eb}} 
        call    negate_HL_if_negative_and_test_if_INT;{{dd6b:cdeadd}} 
        ex      de,hl             ;{{dd6e:eb}} 
        jp      negate_HL_if_negative_and_test_if_INT;{{dd6f:c3eadd}} 

;;=do 16x16 multiply with overflow
do_16x16_multiply_with_overflow:  ;{{Addr=$dd72 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,h               ;{{dd72:7c}} 
        or      a                 ;{{dd73:b7}} 
        jr      z,_do_16x16_multiply_with_overflow_8;{{dd74:2805}}  (+$05)
        ld      a,d               ;{{dd76:7a}} 
        or      a                 ;{{dd77:b7}} 
        scf                       ;{{dd78:37}} 
        ret     nz                ;{{dd79:c0}} 

        ex      de,hl             ;{{dd7a:eb}} 
_do_16x16_multiply_with_overflow_8:;{{Addr=$dd7b Code Calls/jump count: 1 Data use count: 0}}
        or      l                 ;{{dd7b:b5}} 
        ret     z                 ;{{dd7c:c8}} 

        ld      a,d               ;{{dd7d:7a}} 
        or      e                 ;{{dd7e:b3}} 
        ld      a,l               ;{{dd7f:7d}} 
        ld      l,e               ;{{dd80:6b}} 
        ld      h,d               ;{{dd81:62}} 
        ret     z                 ;{{dd82:c8}} 

        cp      $03               ;{{dd83:fe03}} 
        jr      c,_do_16x16_multiply_with_overflow_30;{{dd85:3810}}  (+$10)
        scf                       ;{{dd87:37}} 
_do_16x16_multiply_with_overflow_19:;{{Addr=$dd88 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{dd88:8f}} 
        jr      nc,_do_16x16_multiply_with_overflow_19;{{dd89:30fd}}  (-$03)
_do_16x16_multiply_with_overflow_21:;{{Addr=$dd8b Code Calls/jump count: 1 Data use count: 0}}
        add     hl,hl             ;{{dd8b:29}} 
        ret     c                 ;{{dd8c:d8}} 

        add     a,a               ;{{dd8d:87}} 
        jr      nc,_do_16x16_multiply_with_overflow_27;{{dd8e:3002}}  (+$02)
        add     hl,de             ;{{dd90:19}} 
        ret     c                 ;{{dd91:d8}} 

_do_16x16_multiply_with_overflow_27:;{{Addr=$dd92 Code Calls/jump count: 1 Data use count: 0}}
        cp      $80               ;{{dd92:fe80}} 
        jr      nz,_do_16x16_multiply_with_overflow_21;{{dd94:20f5}}  (-$0b)
        ret                       ;{{dd96:c9}} 

_do_16x16_multiply_with_overflow_30:;{{Addr=$dd97 Code Calls/jump count: 1 Data use count: 0}}
        cp      $01               ;{{dd97:fe01}} 
        ret     z                 ;{{dd99:c8}} 

        add     hl,hl             ;{{dd9a:29}} 
        ret                       ;{{dd9b:c9}} 

;;===================
;;INT division with overflow test
INT_division_with_overflow_test:  ;{{Addr=$dd9c Code Calls/jump count: 1 Data use count: 0}}
        call    _int_modulo_5     ;{{dd9c:cdabdd}} 
_int_division_with_overflow_test_1:;{{Addr=$dd9f Code Calls/jump count: 1 Data use count: 0}}
        jp      c,unknown_maths_fixup_B;{{dd9f:da37dd}} 
        ret                       ;{{dda2:c9}} 

;;=INT modulo
INT_modulo:                       ;{{Addr=$dda3 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,h               ;{{dda3:4c}} 
        call    _int_modulo_5     ;{{dda4:cdabdd}} 
        ex      de,hl             ;{{dda7:eb}} 
        ld      b,c               ;{{dda8:41}} 
        jr      _int_division_with_overflow_test_1;{{dda9:18f4}}  (-$0c)

_int_modulo_5:                    ;{{Addr=$ddab Code Calls/jump count: 2 Data use count: 0}}
        call    make_both_operands_positive;{{ddab:cd67dd}} 
_int_modulo_6:                    ;{{Addr=$ddae Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{ddae:7a}} 
        or      e                 ;{{ddaf:b3}} 
        ret     z                 ;{{ddb0:c8}} 

        push    bc                ;{{ddb1:c5}} 
        ex      de,hl             ;{{ddb2:eb}} 
        ld      b,$01             ;{{ddb3:0601}} 
        ld      a,h               ;{{ddb5:7c}} 
        or      a                 ;{{ddb6:b7}} 
        jr      nz,_int_modulo_21 ;{{ddb7:2009}}  (+$09)
        ld      a,d               ;{{ddb9:7a}} 
        cp      l                 ;{{ddba:bd}} 
        jr      c,_int_modulo_21  ;{{ddbb:3805}}  (+$05)
        ld      h,l               ;{{ddbd:65}} 
        ld      l,$00             ;{{ddbe:2e00}} 
        ld      b,$09             ;{{ddc0:0609}} 
_int_modulo_21:                   ;{{Addr=$ddc2 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,e               ;{{ddc2:7b}} 
        sub     l                 ;{{ddc3:95}} 
        ld      a,d               ;{{ddc4:7a}} 
        sbc     a,h               ;{{ddc5:9c}} 
        jr      c,_int_modulo_30  ;{{ddc6:3805}}  (+$05)
        inc     b                 ;{{ddc8:04}} 
        add     hl,hl             ;{{ddc9:29}} 
        jr      nc,_int_modulo_21 ;{{ddca:30f6}}  (-$0a)
        ccf                       ;{{ddcc:3f}} 
_int_modulo_30:                   ;{{Addr=$ddcd Code Calls/jump count: 1 Data use count: 0}}
        ccf                       ;{{ddcd:3f}} 
        ld      a,b               ;{{ddce:78}} 
        ld      b,h               ;{{ddcf:44}} 
        ld      c,l               ;{{ddd0:4d}} 
        ld      hl,RESET_ENTRY    ;{{ddd1:210000}} 
        jr      _int_modulo_45    ;{{ddd4:180e}}  (+$0e)

_int_modulo_36:                   ;{{Addr=$ddd6 Code Calls/jump count: 1 Data use count: 0}}
        rr      b                 ;{{ddd6:cb18}} 
        rr      c                 ;{{ddd8:cb19}} 
        ex      de,hl             ;{{ddda:eb}} 
        sbc     hl,bc             ;{{dddb:ed42}} 
        jr      nc,_int_modulo_42 ;{{dddd:3001}}  (+$01)
        add     hl,bc             ;{{dddf:09}} 
_int_modulo_42:                   ;{{Addr=$dde0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{dde0:eb}} 
        ccf                       ;{{dde1:3f}} 
        adc     hl,hl             ;{{dde2:ed6a}} 
_int_modulo_45:                   ;{{Addr=$dde4 Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{dde4:3d}} 
        jr      nz,_int_modulo_36 ;{{dde5:20ef}}  (-$11)
        scf                       ;{{dde7:37}} 
        pop     bc                ;{{dde8:c1}} 
        ret                       ;{{dde9:c9}} 

;;--------------------------------------------------------------
;;=negate HL if negative and test if INT
negate_HL_if_negative_and_test_if_INT:;{{Addr=$ddea Code Calls/jump count: 3 Data use count: 0}}
        ld      a,h               ;{{ddea:7c}} 
        or      a                 ;{{ddeb:b7}} 
        ret     p                 ;{{ddec:f0}} if HL is >= 0

;;=negate HL and test if INT
;HL = -HL, then test if it's a valid INT value
;Returns NC if the result is not a valid INT
negate_HL_and_test_if_INT:        ;{{Addr=$dded Code Calls/jump count: 3 Data use count: 0}}
        xor     a                 ;{{dded:af}} 
        sub     l                 ;{{ddee:95}} 
        ld      l,a               ;{{ddef:6f}} L = -L
        sbc     a,h               ;{{ddf0:9c}} H = -L - H
        sub     l                 ;{{ddf1:95}} H = -L - H - L
        cp      h                 ;{{ddf2:bc}} 
        ld      h,a               ;{{ddf3:67}} 
        scf                       ;{{ddf4:37}} 
        ret     nz                ;{{ddf5:c0}} 

        cp      $01               ;{{ddf6:fe01}} 
        ret                       ;{{ddf8:c9}} 

;;--------------------------------------------------------------
;;=unknown test HL
;; HL = value

;; HL = 0?
unknown_test_HL:                  ;{{Addr=$ddf9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{ddf9:7c}} 
        or      l                 ;{{ddfa:b5}} 
        ret     z                 ;{{ddfb:c8}} return if HL = 0

        ld      a,h               ;{{ddfc:7c}} 
        add     a,a               ;{{ddfd:87}} A = H + H
        sbc     a,a               ;{{ddfe:9f}} A = H + H - H
        ret     c                 ;{{ddff:d8}} 

        inc     a                 ;{{de00:3c}} 
        ret                       ;{{de01:c9}} 

;;==================================================
;;prob compare DE to HL?
;if HL >= 0 and DE=HL then A := 0
prob_compare_DE_to_HL:            ;{{Addr=$de02 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,h               ;{{de02:7c}} 
        xor     d                 ;{{de03:aa}} 
        ld      a,h               ;{{de04:7c}} 
        jp      p,_prob_compare_de_to_hl_9;{{de05:f20dde}} if H >= 0 then if DE=HL then return with A=A+1
        add     a,a               ;{{de08:87}} If A > &7f then set A to &ff, otherwise 0

_prob_compare_de_to_hl_5:         ;{{Addr=$de09 Code Calls/jump count: 2 Data use count: 0}}
        sbc     a,a               ;{{de09:9f}} if carry, A will be &ff, otherwise 0
        ret     c                 ;{{de0a:d8}} A=&ff

        inc     a                 ;{{de0b:3c}} A=1
        ret                       ;{{de0c:c9}} 

_prob_compare_de_to_hl_9:         ;{{Addr=$de0d Code Calls/jump count: 1 Data use count: 0}}
        cp      d                 ;{{de0d:ba}} 
        jr      nz,_prob_compare_de_to_hl_5;{{de0e:20f9}}  (-$07) if A <> D
        ld      a,l               ;{{de10:7d}} 
        sub     e                 ;{{de11:93}} 
        jr      nz,_prob_compare_de_to_hl_5;{{de12:20f5}}  (-$0b) if A,L <> DE
        ret                       ;{{de14:c9}} A=0




;;***Execution.asm
;;<< PROGRAM EXECUTION
;;< Execute tokenised code (except expressions)
;;< Includes token handling utilities, TRON, TROFF, 
;;< and the command/statement look up table.
;;============================================
;; next token if comma
next_token_if_comma:              ;{{Addr=$de15 Code Calls/jump count: 23 Data use count: 0}}
        ld      a,$2c             ;{{de15:3e2c}}  ','
        jr      next_token_if_value_in_A;{{de17:1810}}  

;;+----------------------------------------------------------
;; next token if open bracket
next_token_if_open_bracket:       ;{{Addr=$de19 Code Calls/jump count: 6 Data use count: 0}}
        ld      a,$28             ;{{de19:3e28}}  '('
        jr      next_token_if_value_in_A;{{de1b:180c}}  

;;+----------------------------------------------------------
;; next token if close bracket
next_token_if_close_bracket:      ;{{Addr=$de1d Code Calls/jump count: 16 Data use count: 0}}
        ld      a,$29             ;{{de1d:3e29}}  ')'
        jr      next_token_if_value_in_A;{{de1f:1808}} 

;;+----------------------------------------------------------
;; next token if equals sign
next_token_if_equals_sign:        ;{{Addr=$de21 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,$ef             ;{{de21:3eef}} token for '='
        jr      next_token_if_value_in_A;{{de23:1804}} 

;;+----------------------------------------------------------
;; next token if equals inline data byte
next_token_if_equals_inline_data_byte:;{{Addr=$de25 Code Calls/jump count: 15 Data use count: 0}}
        ex      (sp),hl           ;{{de25:e3}}  get return address from top of stack/save HL
        ld      a,(hl)            ;{{de26:7e}}  get byte
        inc     hl                ;{{de27:23}}  increment pointer
        ex      (sp),hl           ;{{de28:e3}}  put return address back to stack/restore HL

;;+----------------------------------------------------------
;; next token if value in A
;; A = char to check against
next_token_if_value_in_A:         ;{{Addr=$de29 Code Calls/jump count: 4 Data use count: 0}}
        cp      (hl)              ;{{de29:be}} 
        jr      nz,raise_syntax_error_D;{{de2a:200f}}  (+$0f)

;;=get next token skipping space
;; skip spaces
get_next_token_skipping_space:    ;{{Addr=$de2c Code Calls/jump count: 53 Data use count: 1}}
        inc     hl                ;{{de2c:23}} 
        ld      a,(hl)            ;{{de2d:7e}} 
        cp      $20               ;{{de2e:fe20}}  ' '
        jr      z,get_next_token_skipping_space;{{de30:28fa}} 
 

        cp      $01               ;{{de32:fe01}} 
        ret     nc                ;{{de34:d0}} 
        or      a                 ;{{de35:b7}} 
        ret                       ;{{de36:c9}} 

;;+----------------------------------------------------------
;;syntax error if not $02
syntax_error_if_not_02:           ;{{Addr=$de37 Code Calls/jump count: 16 Data use count: 0}}
        ld      a,(hl)            ;{{de37:7e}} 
        cp      $02               ;{{de38:fe02}} 
        ret     c                 ;{{de3a:d8}} 

;;=raise syntax error
raise_syntax_error_D:             ;{{Addr=$de3b Code Calls/jump count: 1 Data use count: 0}}
        jr      raise_syntax_error_E;{{de3b:186a}}  (+$6a)

;;=is next $02
;Carry set if EOLN or end of statement
is_next_02:                       ;{{Addr=$de3d Code Calls/jump count: 9 Data use count: 0}}
        ld      a,(hl)            ;{{de3d:7e}} 
        cp      $02               ;{{de3e:fe02}} 
        ret                       ;{{de40:c9}} 

;;=next token if prev is comma
next_token_if_prev_is_comma:      ;{{Addr=$de41 Code Calls/jump count: 44 Data use count: 0}}
        dec     hl                ;{{de41:2b}} 
        call    get_next_token_skipping_space;{{de42:cd2cde}}  get next token skipping space
        xor     $2c               ;{{de45:ee2c}}  ','
        ret     nz                ;{{de47:c0}} 

        call    get_next_token_skipping_space;{{de48:cd2cde}}  get next token skipping space
        scf                       ;{{de4b:37}} 
        ret                       ;{{de4c:c9}} 

;;=======================================================================
;; skip space, tab or line feed
skip_space_tab_or_line_feed:      ;{{Addr=$de4d Code Calls/jump count: 20 Data use count: 0}}
        ld      a,(hl)            ;{{de4d:7e}} 
        inc     hl                ;{{de4e:23}} 
        cp      $20               ;{{de4f:fe20}}  ' '
        jr      z,skip_space_tab_or_line_feed;{{de51:28fa}}  skip space, lf or tab          
        cp      $09               ;{{de53:fe09}}  TAB
        jr      z,skip_space_tab_or_line_feed;{{de55:28f6}}  skip space, lf or tab          
        cp      $0a               ;{{de57:fe0a}}  LF
        jr      z,skip_space_tab_or_line_feed;{{de59:28f2}}  skip space, lf or tab          
        dec     hl                ;{{de5b:2b}} 
        ret                       ;{{de5c:c9}} 



;**tk
;;=======================================================================
;; execute tokenised line
execute_tokenised_line:           ;{{Addr=$de5d Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_of_byte_before_current_statement);{{de5d:2a1bae}} 

;;=execute line atHL
;HL points to first token, NOT line number
execute_line_atHL:                ;{{Addr=$de60 Code Calls/jump count: 7 Data use count: 0}}
        ld      (address_of_byte_before_current_statement),hl;{{de60:221bae}} HL=current execution address
        call    KL_POLL_SYNCHRONOUS;{{de63:cd21b9}} handle pending events
        call    c,prob_process_pending_events;{{de66:dcb2c8}} 
        call    get_next_token_skipping_space;{{de69:cd2cde}}  get next token skipping space
        call    nz,execute_command_token;{{de6c:c48fde}} end of buffer?
        ld      a,(hl)            ;{{de6f:7e}} 
        cp      $01               ;{{de70:fe01}} next statement on same line
        jr      z,execute_line_atHL;{{de72:28ec}}  (-$14) Loop until end of line

        jr      nc,raise_syntax_error_E;{{de74:3031}}  (+$31)
        inc     hl                ;{{de76:23}} 

;;=execute end of line
execute_end_of_line:              ;{{Addr=$de77 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{de77:7e}} Next line number?
        inc     hl                ;{{de78:23}} 
        or      (hl)              ;{{de79:b6}} 
        inc     hl                ;{{de7a:23}} 
        jr      z,end_execution   ;{{de7b:280f}}  (+$0f) line number zero = end of code marker

        ld      (address_of_line_number_LB_of_line_of_cur),hl;{{de7d:221dae}}  Start of current line
        inc     hl                ;{{de80:23}} 
        ld      a,(trace_flag)    ;{{de81:3a1fae}} trace on??
        or      a                 ;{{de84:b7}} 
        jr      z,execute_line_atHL;{{de85:28d9}}  (-$27) if not loop - execute next line
        call    do_trace          ;{{de87:cdcade}}  trace
        jr      execute_line_atHL ;{{de8a:18d4}}  (-$2c) loop - execute next line

;;====================================
;;end execution
end_execution:                    ;{{Addr=$de8c Code Calls/jump count: 1 Data use count: 0}}
        jp      prob_end_of_program;{{de8c:c349cc}} 

;;============================================
;;execute command token
;A=token
;Tokens >= &80 are tokenised words
;the only token < &80 we should have here are for bar commands or variable names (implicit LET)
execute_command_token:            ;{{Addr=$de8f Code Calls/jump count: 2 Data use count: 0}}
        add     a,a               ;{{de8f:87}} 
        jp      nc,BAR_command_or_implicit_LET;{{de90:d289d6}} token < &80: either a bar command or a variable (implicit LET)
        cp tokenise_a_BASIC_line - command_to_code_address_LUT - 1;{{de93:fec3}} version with formula;WARNING: Code area used as literal
;OLD de93 fec3      cp      $c3              ;the last valid token is &e1 which doubles to &c2, so >= &c3 is error
        jr      nc,raise_syntax_error_E;{{de95:3010}}  (+$10)
        ex      de,hl             ;{{de97:eb}} 
        add     a,command_to_code_address_LUT and $ff;{{de98:c6e0}} $e0 lookup token in table
        ld      l,a               ;{{de9a:6f}} 
        adc     a,command_to_code_address_LUT >> 8;{{de9b:cede}} $de
        sub     l                 ;{{de9d:95}} 
        ld      h,a               ;{{de9e:67}} 
        ld      c,(hl)            ;{{de9f:4e}} code address into BC
        inc     hl                ;{{dea0:23}} 
        ld      b,(hl)            ;{{dea1:46}} 
        push    bc                ;{{dea2:c5}} push so we'll return to code with next token
        ex      de,hl             ;{{dea3:eb}} 
        jp      get_next_token_skipping_space;{{dea4:c32cde}}  get next token skipping space

;;=raise syntax error
raise_syntax_error_E:             ;{{Addr=$dea7 Code Calls/jump count: 3 Data use count: 0}}
        jp      Error_Syntax_Error;{{dea7:c349cb}}  Error: Syntax Error

;;========================================================================
;; zero current line address
zero_current_line_address:        ;{{Addr=$deaa Code Calls/jump count: 7 Data use count: 0}}
        ld      hl,$0000          ;{{deaa:210000}} ##LIT##

;;=set current line address
set_current_line_address:         ;{{Addr=$dead Code Calls/jump count: 15 Data use count: 0}}
        ld      (address_of_line_number_LB_of_line_of_cur),hl;{{dead:221dae}} 
        ret                       ;{{deb0:c9}} 

;;========================================================================
;;get current line address
get_current_line_address:         ;{{Addr=$deb1 Code Calls/jump count: 12 Data use count: 0}}
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{deb1:2a1dae}} 
        ret                       ;{{deb4:c9}} 

;;========================================================================
;; get current line number
;; returns Z if current line number address is zero
;; returns C if we HL returns a current line number
get_current_line_number:          ;{{Addr=$deb5 Code Calls/jump count: 10 Data use count: 0}}
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{deb5:2a1dae}} address of current line

;;+get line number atHL
get_line_number_atHL:             ;{{Addr=$deb8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,h               ;{{deb8:7c}} 
        or      l                 ;{{deb9:b5}} 
        ret     z                 ;{{deba:c8}} ; no current line 

        ld      a,(hl)            ;{{debb:7e}} get line number
        inc     hl                ;{{debc:23}} 
        ld      h,(hl)            ;{{debd:66}} 
        ld      l,a               ;{{debe:6f}} 
        scf                       ;{{debf:37}} 
        ret                       ;{{dec0:c9}} 

;;========================================================================
;; command TRON
command_TRON:                     ;{{Addr=$dec1 Code Calls/jump count: 0 Data use count: 1}}
        ld      a,$ff             ;{{dec1:3eff}} 
        jr      _command_troff_1  ;{{dec3:1801}}  (+$01)

;;========================================================================
;; command TROFF
command_TROFF:                    ;{{Addr=$dec5 Code Calls/jump count: 1 Data use count: 1}}
        xor     a                 ;{{dec5:af}} 
_command_troff_1:                 ;{{Addr=$dec6 Code Calls/jump count: 1 Data use count: 0}}
        ld      (trace_flag),a    ;{{dec6:321fae}} 
        ret                       ;{{dec9:c9}} 

;;=============
;;do trace
do_trace:                         ;{{Addr=$deca Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$5b             ;{{deca:3e5b}} '['
        call    output_char       ;{{decc:cda0c3}} ; display text char
        push    hl                ;{{decf:e5}} 
        ld      hl,(address_of_line_number_LB_of_line_of_cur);{{ded0:2a1dae}} Current line address
        ld      a,(hl)            ;{{ded3:7e}} get line number
        inc     hl                ;{{ded4:23}} 
        ld      h,(hl)            ;{{ded5:66}} 
        ld      l,a               ;{{ded6:6f}} 
        call    display_decimal_number;{{ded7:cd44ef}} Display current line number
        pop     hl                ;{{deda:e1}} 
        ld      a,$5d             ;{{dedb:3e5d}} ']'
        jp      output_char       ;{{dedd:c3a0c3}} ; display text char

;;====================================================
;; command to code address LUT

;you can add extra items to the end of this list, HOWEVER, there is only one unused item before
;current last item in the table is &e1. You can add an item &e2. Items &e3 onwards are used for other keywords
command_to_code_address_LUT:      ;{{Addr=$dee0 Data Calls/jump count: 0 Data use count: 3}}
                                  
        defw command_AFTER        ; AFTER  ##LABEL##
        defw command_AUTO         ; AUTO  ##LABEL##
        defw command_BORDER       ; BORDER  ##LABEL##
        defw command_CALL         ; CALL  ##LABEL##
        defw command_CAT          ; CAT  ##LABEL##
        defw command_CHAIN        ; CHAIN  ##LABEL##
        defw command_CLEAR_CLEAR_INPUT; CLEAR  ##LABEL##
        defw command_CLG          ; CLG  ##LABEL##
        defw command_CLOSEIN      ; CLOSEIN  ##LABEL##
        defw command_CLOSEOUT     ; CLOSEOUT  ##LABEL##
        defw command_CLS          ; CLS   ##LABEL##
        defw command_CONT         ; CONT  ##LABEL##
        defw skip_to_end_of_statement; DATA  ##LABEL##
        defw command_DEF          ; DEF   ##LABEL##
        defw command_DEFINT       ; DEFINT  ##LABEL##
        defw command_DEFREAL      ; DEFREAL  ##LABEL##
        defw command_DEFSTR       ; DEFSTR  ##LABEL##
        defw command_DEG          ; DEG  ##LABEL##
        defw command_DELETE       ; DELETE  ##LABEL##
        defw command_DIM          ; DIM  ##LABEL##
        defw command_DRAW         ; DRAW  ##LABEL##
        defw command_DRAWR        ; DRAWR  ##LABEL##
        defw command_EDIT         ; EDIT  ##LABEL##
        defw skip_to_end_of_line  ; ELSE  ##LABEL##
        defw command_END          ; END  ##LABEL##
        defw command_ENT          ; ENT  ##LABEL##
        defw command_ENV          ; ENV  ##LABEL##
        defw command_ERASE        ; ERASE  ##LABEL##
        defw command_ERROR        ; ERROR  ##LABEL##
        defw command_EVERY        ; EVERY  ##LABEL##
        defw command_FOR          ; FOR  ##LABEL##
        defw command_GOSUB        ; GOSUB  ##LABEL##
        defw command_GOTO         ; GOTO  ##LABEL##
        defw command_IF           ; IF  ##LABEL##
        defw command_INK          ; INK  ##LABEL##
        defw command_INPUT        ; INPUT  ##LABEL##
        defw command_KEY          ; KEY  ##LABEL##
        defw command_LET          ; LET   ##LABEL##
        defw command_LINE_INPUT   ; LINE  ##LABEL##
        defw command_LIST         ; LIST  ##LABEL##
        defw command_LOAD         ; LOAD  ##LABEL##
        defw command_LOCATE       ; LOCATE  ##LABEL##
        defw command_MEMORY       ; MEMORY  ##LABEL##
        defw command_MERGE        ; MERGE  ##LABEL##
        defw command_MID          ; MID$  ##LABEL##
        defw command_MODE         ; MODE  ##LABEL##
        defw command_MOVE         ; MOVE  ##LABEL##
        defw command_MOVER        ; MOVER  ##LABEL##
        defw command_NEXT         ; NEXT  ##LABEL##
        defw command_NEW          ; NEW  ##LABEL##
        defw command_ON_ON_ERROR_GOTO; ON   ##LABEL## (and ON ERROR GOTO [line])
        defw command_ON_BREAK_ON_BREAK_CONT_ON_BREAK_STOP; ON BREAK  ##LABEL##
        defw command_ON_ERROR_GOTO_0; ON ERROR GOTO 0 ##LABEL##
        defw command_ON_SQ        ; ON SQ  ##LABEL##
        defw command_OPENIN       ; OPENIN  ##LABEL##
        defw command_OPENOUT      ; OPENOUT  ##LABEL##
        defw command_ORIGIN       ; ORIGIN  ##LABEL##
        defw command_OUT          ; OUT  ##LABEL##
        defw command_PAPER        ; PAPER  ##LABEL##
        defw command_PEN          ; PEN  ##LABEL##
        defw command_PLOT         ; PLOT  ##LABEL##
        defw command_PLOTR        ; PLOTR  ##LABEL##
        defw command_POKE         ; POKE  ##LABEL##
        defw command_PRINT        ; PRINT  ##LABEL##
        defw command__or_REM      ; '  ##LABEL##
        defw command_RAD          ; RAD  ##LABEL##
        defw command_RANDOMIZE    ; RANDOMIZE  ##LABEL##
        defw command_READ         ; READ  ##LABEL##
        defw command_RELEASE      ; RELEASE  ##LABEL##
        defw command__or_REM      ; REM  ##LABEL##
        defw command_RENUM        ; RENUM  ##LABEL##
        defw command_RESTORE      ; RESTORE  ##LABEL##
        defw command_RESUME       ; RESUME  ##LABEL##
        defw command_RETURN       ; RETURN  ##LABEL##
        defw command_RUN          ; RUN  ##LABEL##
        defw command_SAVE         ; SAVE  ##LABEL##
        defw command_SOUND        ; SOUND  ##LABEL##
        defw command_SPEED_WRITE_SPEED_KEY_SPEED_INK; SPEED  ##LABEL##
        defw command_STOP         ; STOP  ##LABEL##
        defw command_SYMBOL       ; SYMBOL  ##LABEL##
        defw command_TAG          ; TAG  ##LABEL##
        defw command_TAGOFF       ; TAGOFF  ##LABEL##
        defw command_TROFF        ; TROFF  ##LABEL##
        defw command_TRON         ; TRON  ##LABEL##
        defw command_WAIT         ; WAIT  ##LABEL##
        defw command_WEND         ; WEND  ##LABEL##
        defw command_WHILE        ; WHILE  ##LABEL##
        defw command_WIDTH        ; WIDTH   ##LABEL##
        defw command_WINDOW_WINDOW_SWAP; WINDOW  ##LABEL##
        defw command_WRITE        ; WRITE  ##LABEL##
        defw command_ZONE         ; ZONE  ##LABEL##
        defw command_DI           ; DI  ##LABEL##
        defw command_EI           ; EI  ##LABEL##
        defw command_FILL         ; FILL  ##LABEL##
        defw command_GRAPHICS_PAPER__GRAPHICS_PEN_and_set_graphics_draw_mode; GRAPHICS  ##LABEL##
        defw command_MASK         ; MASK  ##LABEL##
        defw MC_WAIT_FLYBACK      ; FRAME  ##LABEL##
        defw command_CURSOR       ; CURSOR  ##LABEL##





;;***Tokenising.asm
;;<< TOKENISING SOURCE CODE
;;==================================================
;; tokenise a BASIC line
tokenise_a_BASIC_line:            ;{{Addr=$dfa4 Code Calls/jump count: 2 Data use count: 1}}
        push    de                ;{{dfa4:d5}} 
        ld de,(address_of_start_of_ROM_lower_reserved_a);{{dfa5:ed5b62ae}} input buffer address
        push    de                ;{{dfa9:d5}} 
        call    clear_tokenisation_state_flag;{{dfaa:cd35e0}} 
        ld      bc,$012c          ;{{dfad:012c01}} max tokenised line length/buffer length

_tokenise_a_basic_line_5:         ;{{Addr=$dfb0 Code Calls/jump count: 1 Data use count: 0}}
        call    tokenise_item     ;{{dfb0:cdc8df}} 
        ld      a,(hl)            ;{{dfb3:7e}} 
        or      a                 ;{{dfb4:b7}} 
        jr      nz,_tokenise_a_basic_line_5;{{dfb5:20f9}}  (-$07) Loop until end of buffer

        ld      a,"-"             ;{{dfb7:3e2d}}  '-'
        sub     c                 ;{{dfb9:91}} 
        ld      c,a               ;{{dfba:4f}} 
        ld      a,$01             ;{{dfbb:3e01}} 
        sbc     a,b               ;{{dfbd:98}} 
        ld      b,a               ;{{dfbe:47}} 
        xor     a                 ;{{dfbf:af}} 
        ld      (de),a            ;{{dfc0:12}} 
        inc     de                ;{{dfc1:13}} 
        ld      (de),a            ;{{dfc2:12}} 
        inc     de                ;{{dfc3:13}} 
        ld      (de),a            ;{{dfc4:12}} 
        pop     hl                ;{{dfc5:e1}} 
        pop     de                ;{{dfc6:d1}} 
        ret                       ;{{dfc7:c9}} 

;;=tokenise item
tokenise_item:                    ;{{Addr=$dfc8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{dfc8:7e}} get char
        or      a                 ;{{dfc9:b7}} 
        ret     z                 ;{{dfca:c8}} end of buffer

        call    test_if_letter    ;{{dfcb:cd92ff}}  is a alphabetical letter?
        jr      c,tokenise_letters;{{dfce:381c}}  (+$1c)
        call    test_if_period_or_digit;{{dfd0:cda0ff}} 
        jp      c,tokenise_a_number;{{dfd3:dae2e0}} 
        cp      "&"               ;{{dfd6:fe26}} '&' = hex or binary prefix
        jp      z,tokenise_hex_or_binary_number;{{dfd8:ca36e1}} 
        inc     hl                ;{{dfdb:23}} 
        or      a                 ;{{dfdc:b7}} 
        ret     m                 ;{{dfdd:f8}} 

        cp      "!"               ;{{dfde:fe21}} '!'
        jp      nc,tokenise_any_other_ascii_char;{{dfe0:d25ce1}} anything else which is not whitespace

        ld      a,(program_line_redundant_spaces_flag_);{{dfe3:3a00ac}} do we store whitespace?
        or      a                 ;{{dfe6:b7}} 
        ret     nz                ;{{dfe7:c0}} 

        ld      a," "             ;{{dfe8:3e20}} ' '
        jr      write_tokenised_byte_to_memory;{{dfea:181c}}  (+$1c)

;;+----------------
;;tokenise letters
;keywords and variables??
tokenise_letters:                 ;{{Addr=$dfec Code Calls/jump count: 1 Data use count: 0}}
        call    tokenise_identifiers;{{dfec:cd3ae0}} 
        ret     c                 ;{{dfef:d8}} carry set if it's already been written
                                  ;othwise it's a token >= &80
        cp      $c5               ;{{dff0:fec5}} REM
        jp      z,copy_until_end_of_buffer;{{dff2:cac3e1}} 
        push    hl                ;{{dff5:e5}} 
        ld      hl,tokenisation_table_A;{{dff6:2112e0}} DATA and DEFxxxx
        call    check_if_byte_exists_in_table;{{dff9:cdcaff}} ; check if byte exists in table 
        pop     hl                ;{{dffc:e1}} 
        jr      c,token_is_in_tokenisation_table_A;{{dffd:3818}}  (+$18) copy sanitised ASCII until end of statement
        push    af                ;{{dfff:f5}} 
        cp      $97               ;{{e000:fe97}} ELSE
        ld      a,$01             ;{{e002:3e01}} 
        call    z,write_tokenised_byte_to_memory;{{e004:cc08e0}} insert a New Statement token before an ELSE
        pop     af                ;{{e007:f1}} 

;;+-----------------------------
;; write tokenised byte to memory
write_tokenised_byte_to_memory:   ;{{Addr=$e008 Code Calls/jump count: 22 Data use count: 0}}
        ld      (de),a            ;{{e008:12}} write token
        inc     de                ;{{e009:13}} 
        dec     bc                ;{{e00a:0b}} 
        ld      a,c               ;{{e00b:79}} 
        or      b                 ;{{e00c:b0}} 
        ret     nz                ;{{e00d:c0}} buffer full?

        call    byte_following_call_is_error_code;{{e00e:cd45cb}} 
        defb $17                  ;Inline error code: Line too long

;;====================================
;; tokenisation table A

tokenisation_table_A:             ;{{Addr=$e012 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $8c                  ;DATA
        defb $8e                  ;DEFINT
        defb $90                  ;DEFSTR
        defb $8f                  ;DEFREAL
        defb $00                  

;;+------------------------------------------
;; token is in tokenisation table A
;; copy literal data until end of statement or end of line
;ignores chars >= &80
;chars < &20 are converted to spaces
;quoted strings are copied unmodified
;; Code is jumped to - loop until return

token_is_in_tokenisation_table_A: ;{{Addr=$e017 Code Calls/jump count: 2 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e017:cd08e0}} 

_token_is_in_tokenisation_table_a_1:;{{Addr=$e01a Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e01a:7e}} 
        or      a                 ;{{e01b:b7}} 
        ret     z                 ;{{e01c:c8}}  End of buffer

        cp      ":"               ;{{e01d:fe3a}} ':' - end of statement
        jr      z,clear_tokenisation_state_flag;{{e01f:2814}}  (+$14)
        inc     hl                ;{{e021:23}} 
        or      a                 ;{{e022:b7}} 
        jp      m,_token_is_in_tokenisation_table_a_1;{{e023:fa1ae0}} ignore chars >= &80

        cp      " "               ;{{e026:fe20}}  ' '
        jr      nc,_token_is_in_tokenisation_table_a_12;{{e028:3002}}  (+$02)
        ld      a,$20             ;{{e02a:3e20}}  convert control codes to spaces
_token_is_in_tokenisation_table_a_12:;{{Addr=$e02c Code Calls/jump count: 1 Data use count: 0}}
        cp      $22               ;{{e02c:fe22}}  '"'
        jr      nz,token_is_in_tokenisation_table_A;{{e02e:20e7}}  (-$19) write byte and next
        call    tokenise_string   ;{{e030:cd95e1}} 
        jr      _token_is_in_tokenisation_table_a_1;{{e033:18e5}}  (-$1b) next

;;+----------------------
;;clear tokenisation state flag
clear_tokenisation_state_flag:    ;{{Addr=$e035 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{e035:af}} 
        ld      (tokenisation_state_flag),a;{{e036:3220ae}} 
        ret                       ;{{e039:c9}} 

;;===================================================
;; tokenise identifiers
;tokens >= &80 are returned with carry set, for caller to process
;other items are written by as, and carry returns clear

tokenise_identifiers:             ;{{Addr=$e03a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e03a:c5}} 
        push    de                ;{{e03b:d5}} 
        push    hl                ;{{e03c:e5}} 

        ld      a,(hl)            ;{{e03d:7e}} ; get initial character of BASIC keyword
        inc     hl                ;{{e03e:23}} 
        call    convert_character_to_upper_case;{{e03f:cdabff}} ; convert character to upper case
        call    get_keyword_table_for_letter;{{e042:cda8e3}} ; get list of keywords beginning with this letter
        call    keyword_to_token_within_single_table;{{e045:cdebe3}} 
        jr      nc,tokenise_variable;{{e048:3026}} ;not found? - it's a variable!

        ld      a,c               ;{{e04a:79}} 
        and     $7f               ;{{e04b:e67f}} 
        call    test_if_letter_period_or_digit;{{e04d:cd9cff}} 
        jr      nc,_tokenise_identifiers_18;{{e050:3009}}  (+$09)
        ld      a,(de)            ;{{e052:1a}} get prev token
        cp      $e4               ;{{e053:fee4}} FN token
        ld      a,(hl)            ;{{e055:7e}} 
        call    nz,test_if_letter_period_or_digit;{{e056:c49cff}} 
        jr      c,tokenise_variable;{{e059:3815}}  (+$15) tokenise variable name after FN

_tokenise_identifiers_18:         ;{{Addr=$e05b Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{e05b:f1}} 
        ld      a,(de)            ;{{e05c:1a}} get prev token
        or      a                 ;{{e05d:b7}} tokens >= &80 = statements and miscellaneous
        jp      m,test_for_specially_encoded_keywords;{{e05e:faafe0}} do tests and return the token for caller to process
        pop     de                ;{{e061:d1}} tokens <&80 = functions
        pop     bc                ;{{e062:c1}} 
        push    af                ;{{e063:f5}} 
        ld      a,$ff             ;{{e064:3eff}} functions have a &ff prefix
        call    write_tokenised_byte_to_memory;{{e066:cd08e0}} 
        pop     af                ;{{e069:f1}} 
        call    write_tokenised_byte_to_memory;{{e06a:cd08e0}} write function token
        xor     a                 ;{{e06d:af}} 
        jr      set_tokenisation_status_flag;{{e06e:183a}}  (+$3a)

;;=tokenise variable
tokenise_variable:                ;{{Addr=$e070 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{e070:e1}} 
        pop     de                ;{{e071:d1}} 
        pop     bc                ;{{e072:c1}} 
        push    hl                ;{{e073:e5}} 
        dec     hl                ;{{e074:2b}} 

_tokenise_variable_5:             ;{{Addr=$e075 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e075:23}} skip over the variable name to get to the type char
        ld      a,(hl)            ;{{e076:7e}} 
        call    test_if_letter_period_or_digit;{{e077:cd9cff}} I was today years old when I learnt variable names can contain periods :)
        jr      c,_tokenise_variable_5;{{e07a:38f9}}  (-$07)

        call    convert_variable_type_suffix;{{e07c:cdd1e0}} interpret the type suffix
        jr      c,_tokenise_variable_13;{{e07f:3804}}  (+$04)
        ld      a,$0d             ;{{e081:3e0d}} no type suffix - default to a real
        jr      got_var_type      ;{{e083:1806}}  (+$06)

_tokenise_variable_13:            ;{{Addr=$e085 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e085:23}} 
        cp      $05               ;{{e086:fe05}} massage var type from 2/3/5 (internal data type) to 2/3/4 (token data type)
        jr      nz,got_var_type   ;{{e088:2001}}  (+$01)
        dec     a                 ;{{e08a:3d}} 
;;=got var type
got_var_type:                     ;{{Addr=$e08b Code Calls/jump count: 2 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e08b:cd08e0}} write type type token
        xor     a                 ;{{e08e:af}} write null link pointer (to variable data storage)
        call    write_tokenised_byte_to_memory;{{e08f:cd08e0}} 
        xor     a                 ;{{e092:af}} 
        call    write_tokenised_byte_to_memory;{{e093:cd08e0}} 
        ex      (sp),hl           ;{{e096:e3}} 

;;=tokenise variable name loop
tokenise_variable_name_loop:      ;{{Addr=$e097 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e097:7e}} copy the variable name
        call    test_if_letter_period_or_digit;{{e098:cd9cff}} 
        jr      nc,_tokenise_variable_name_loop_7;{{e09b:3007}}  (+$07) done
        ld      a,(hl)            ;{{e09d:7e}} 
        call    write_tokenised_byte_to_memory;{{e09e:cd08e0}} 
        inc     hl                ;{{e0a1:23}} 
        jr      tokenise_variable_name_loop;{{e0a2:18f3}}  (-$0d)

_tokenise_variable_name_loop_7:   ;{{Addr=$e0a4 Code Calls/jump count: 1 Data use count: 0}}
        call    set_bit7_of_prev_byte;{{e0a4:cdb5e1}} set bit 7 of last char of name
        pop     hl                ;{{e0a7:e1}} 
        ld      a,$ff             ;{{e0a8:3eff}} 
;;=set tokenisation status flag
set_tokenisation_status_flag:     ;{{Addr=$e0aa Code Calls/jump count: 1 Data use count: 0}}
        ld      (tokenisation_state_flag),a;{{e0aa:3220ae}} 
        scf                       ;{{e0ad:37}} 
        ret                       ;{{e0ae:c9}} 

;;==================================
;; test for specially encoded keywords
;sets tokenisation state flag (ae20) to &ff if token is one of these
test_for_specially_encoded_keywords:;{{Addr=$e0af Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e0af:e5}} 
        ld      c,a               ;{{e0b0:4f}} 
        ld      hl,specially_encoded_keywords;{{e0b1:21c3e0}} 
        call    check_if_byte_exists_in_table;{{e0b4:cdcaff}} ;check if byte exists in table
        sbc     a,a               ;{{e0b7:9f}} 
        and     $01               ;{{e0b8:e601}} 
        ld      (tokenisation_state_flag),a;{{e0ba:3220ae}} 
        ld      a,c               ;{{e0bd:79}} 
        pop     hl                ;{{e0be:e1}} 
        pop     de                ;{{e0bf:d1}} 
        pop     bc                ;{{e0c0:c1}} 
        or      a                 ;{{e0c1:b7}} 
        ret                       ;{{e0c2:c9}} 

;;================================================
;; specially encoded keywords
;; keywords which need special encoding(??)
specially_encoded_keywords:       ;{{Addr=$e0c3 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb $c7                  ;RESTORE
        defb $81                  ;AUTO
        defb $c6                  ;RENUM
        defb $92                  ;DELETE
        defb $96                  ;EDIT
        defb $c8                  ;RESUME
        defb $e3                  ;ERL
        defb $97                  ;ELSE
        defb $ca                  ;RUN
        defb $a7                  ;LIST
        defb $a0                  ;GOTO
        defb $eb                  ;THEN
        defb $9f                  ;GOSUB
        defb $00                  

;;===========================================
;; convert variable type suffix

convert_variable_type_suffix:     ;{{Addr=$e0d1 Code Calls/jump count: 2 Data use count: 0}}
        cp      "!"               ;{{e0d1:fe21}} '!' real
        jr      z,_convert_variable_type_suffix_7;{{e0d3:2807}}  (+$07)
        cp      "&"               ;{{e0d5:fe26}} '&' we want < '&'
        ret     nc                ;{{e0d7:d0}} 

        cp      "$"               ;{{e0d8:fe24}} '$' string 
        ccf                       ;{{e0da:3f}} 
        ret     nc                ;{{e0db:d0}} we want >= '$'

_convert_variable_type_suffix_7:  ;{{Addr=$e0dc Code Calls/jump count: 1 Data use count: 0}}
        sbc     a,$1f             ;{{e0dc:de1f}} Use maths to massage them into 2,3,5 (int, string, real)
        xor     $07               ;{{e0de:ee07}} 
        scf                       ;{{e0e0:37}} 
        ret                       ;{{e0e1:c9}} 

;;==============================================
;;tokenise a number

tokenise_a_number:                ;{{Addr=$e0e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(tokenisation_state_flag);{{e0e2:3a20ae}} 
        or      a                 ;{{e0e5:b7}} 
        jr      z,_tokenise_a_number_12;{{e0e6:2810}}  (+$10)
        ld      a,(hl)            ;{{e0e8:7e}} 
        inc     hl                ;{{e0e9:23}} 
        jp      m,write_tokenised_byte_to_memory;{{e0ea:fa08e0}} 
        dec     hl                ;{{e0ed:2b}} 
        push    de                ;{{e0ee:d5}} 
        call    convert_number_a  ;{{e0ef:cdcfee}} 
        jr      nc,_tokenise_a_number_37;{{e0f2:3032}}  (+$32)
        ld      a,$1e             ;{{e0f4:3e1e}}  16-bit line number
        jr      _tokenise_hex_or_binary_number_9;{{e0f6:184d}}  (+$4d)

_tokenise_a_number_12:            ;{{Addr=$e0f8 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{e0f8:d5}} 
        push    bc                ;{{e0f9:c5}} 
        call    _possibly_validate_input_buffer_is_a_number_12;{{e0fa:cd8aed}} 
        pop     bc                ;{{e0fd:c1}} 
        jr      nc,_tokenise_a_number_37;{{e0fe:3026}}  (+$26)
        call    is_accumulator_a_string;{{e100:cd66ff}} 
        ld      a,$1f             ;{{e103:3e1f}} 
        jr      nc,_tokenise_hex_or_binary_number_9;{{e105:303e}}  (+$3e)
        ld      de,(accumulator)  ;{{e107:ed5ba0b0}} 
        ld      a,d               ;{{e10b:7a}} 
        or      a                 ;{{e10c:b7}} 
        ld      a,$1a             ;{{e10d:3e1a}} 
        jr      nz,_tokenise_hex_or_binary_number_9;{{e10f:2034}}  (+$34)
        ex      (sp),hl           ;{{e111:e3}} 
        ex      de,hl             ;{{e112:eb}} 
        ld      a,l               ;{{e113:7d}} 
        cp      $0a               ;{{e114:fe0a}} 
        jr      nc,_tokenise_a_number_32;{{e116:3004}}  (+$04)
        add     a,$0e             ;{{e118:c60e}} 
        jr      _tokenise_a_number_35;{{e11a:1806}}  (+$06)

_tokenise_a_number_32:            ;{{Addr=$e11c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$19             ;{{e11c:3e19}} 
        call    write_tokenised_byte_to_memory;{{e11e:cd08e0}} 
        ld      a,l               ;{{e121:7d}} 
_tokenise_a_number_35:            ;{{Addr=$e122 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e122:e1}} 
        jp      write_tokenised_byte_to_memory;{{e123:c308e0}} 

_tokenise_a_number_37:            ;{{Addr=$e126 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{e126:7e}} 
        inc     hl                ;{{e127:23}} 
        ex      (sp),hl           ;{{e128:e3}} 
        ex      de,hl             ;{{e129:eb}} 
        call    write_tokenised_byte_to_memory;{{e12a:cd08e0}} 
        ex      de,hl             ;{{e12d:eb}} 
        ex      (sp),hl           ;{{e12e:e3}} 
        call    compare_HL_DE     ;{{e12f:cdd8ff}}  HL=DE?
        jr      nz,_tokenise_a_number_37;{{e132:20f2}}  (-$0e)
        pop     de                ;{{e134:d1}} 
        ret                       ;{{e135:c9}} 

;;===========================================
;; tokenise hex or binary number
tokenise_hex_or_binary_number:    ;{{Addr=$e136 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{e136:d5}} 
        push    bc                ;{{e137:c5}} 
        call    _possibly_validate_input_buffer_is_a_number_12;{{e138:cd8aed}} 
        pop     bc                ;{{e13b:c1}} 
        jr      nc,_tokenise_a_number_37;{{e13c:30e8}}  (-$18)
        cp      $02               ;{{e13e:fe02}} 
        ld      a,$1b             ;{{e140:3e1b}} 
        jr      z,_tokenise_hex_or_binary_number_9;{{e142:2801}}  (+$01)
        inc     a                 ;{{e144:3c}} 

_tokenise_hex_or_binary_number_9: ;{{Addr=$e145 Code Calls/jump count: 4 Data use count: 0}}
        pop     de                ;{{e145:d1}} 
        call    write_tokenised_byte_to_memory;{{e146:cd08e0}} 
        push    hl                ;{{e149:e5}} 
        ld      hl,accumulator    ;{{e14a:21a0b0}} 
        call    get_accumulator_data_type;{{e14d:cd4bff}} 
_tokenise_hex_or_binary_number_14:;{{Addr=$e150 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{e150:f5}} 
        ld      a,(hl)            ;{{e151:7e}} 
        inc     hl                ;{{e152:23}} 
        call    write_tokenised_byte_to_memory;{{e153:cd08e0}} 
        pop     af                ;{{e156:f1}} 
        dec     a                 ;{{e157:3d}} 
        jr      nz,_tokenise_hex_or_binary_number_14;{{e158:20f6}}  (-$0a)
        pop     hl                ;{{e15a:e1}} 
        ret                       ;{{e15b:c9}} 

;;=====================================
;; tokenise any other ascii char
;; Any ASCII char between $33 and $127 which is not a letter, number, period or '&'

tokenise_any_other_ascii_char:    ;{{Addr=$e15c Code Calls/jump count: 1 Data use count: 0}}
        cp      $22               ;{{e15c:fe22}}  '"'
        jr      z,tokenise_string ;{{e15e:2835}}  (+$35)
        cp      "|"               ;{{e160:fe7c}}  '|' 
        jr      z,tokenise_bar_command;{{e162:283f}}  (+$3f)
        push    bc                ;{{e164:c5}} 
        push    de                ;{{e165:d5}} 
        xor     $3f               ;{{e166:ee3f}} 
        ld      b,$bf             ;{{e168:06bf}} 
        jr      z,_tokenise_any_other_ascii_char_18;{{e16a:2810}}  (+$10)
        dec     hl                ;{{e16c:2b}} 
        ld      de,symbols_table  ;{{e16d:1136e7}} 
        call    keyword_to_token_within_single_table;{{e170:cdebe3}} 
        ld      a,(de)            ;{{e173:1a}} 
        jr      c,_tokenise_any_other_ascii_char_16;{{e174:3802}}  (+$02)
        ld      a,(hl)            ;{{e176:7e}} 
        inc     hl                ;{{e177:23}} 
_tokenise_any_other_ascii_char_16:;{{Addr=$e178 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{e178:47}} 
        call    _tokenise_any_other_ascii_char_25;{{e179:cd89e1}} 
_tokenise_any_other_ascii_char_18:;{{Addr=$e17c Code Calls/jump count: 1 Data use count: 0}}
        ld      (tokenisation_state_flag),a;{{e17c:3220ae}} 
        ld      a,b               ;{{e17f:78}} 
        pop     de                ;{{e180:d1}} 
        pop     bc                ;{{e181:c1}} 
        cp      $c0               ;{{e182:fec0}} "'" comment
        jr      z,tokenise_single_quote_comment;{{e184:2836}}  (+$36)
        jp      write_tokenised_byte_to_memory;{{e186:c308e0}} 

_tokenise_any_other_ascii_char_25:;{{Addr=$e189 Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{e189:3d}} 
        ret     z                 ;{{e18a:c8}} 

        xor     $22               ;{{e18b:ee22}}  '"'
        ret     z                 ;{{e18d:c8}} 

        ld      a,(tokenisation_state_flag);{{e18e:3a20ae}} 
        inc     a                 ;{{e191:3c}} 
        ret     z                 ;{{e192:c8}} 

        dec     a                 ;{{e193:3d}} 
        ret                       ;{{e194:c9}} 

;;=============================================
;; tokenise string
;; Called after a double quote
tokenise_string:                  ;{{Addr=$e195 Code Calls/jump count: 3 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e195:cd08e0}} 
        ld      a,(hl)            ;{{e198:7e}} 
        or      a                 ;{{e199:b7}} 
        ret     z                 ;{{e19a:c8}} 

        inc     hl                ;{{e19b:23}} 
        cp      $22               ;{{e19c:fe22}}  '"'
        jr      nz,tokenise_string;{{e19e:20f5}}  (-$0b)
        jp      write_tokenised_byte_to_memory;{{e1a0:c308e0}} 

;;=============================
;;tokenise bar command

tokenise_bar_command:             ;{{Addr=$e1a3 Code Calls/jump count: 1 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e1a3:cd08e0}} 
        xor     a                 ;{{e1a6:af}} 
        ld      (tokenisation_state_flag),a;{{e1a7:3220ae}} 
_tokenise_bar_command_3:          ;{{Addr=$e1aa Code Calls/jump count: 1 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e1aa:cd08e0}} 
        ld      a,(hl)            ;{{e1ad:7e}} 
        inc     hl                ;{{e1ae:23}} 
        call    test_if_letter_period_or_digit;{{e1af:cd9cff}} 
        jr      c,_tokenise_bar_command_3;{{e1b2:38f6}}  (-$0a)
        dec     hl                ;{{e1b4:2b}} 

;;=set bit7 of prev byte
set_bit7_of_prev_byte:            ;{{Addr=$e1b5 Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{e1b5:1b}} 
        ld      a,(de)            ;{{e1b6:1a}} 
        or      $80               ;{{e1b7:f680}} 
        ld      (de),a            ;{{e1b9:12}} 
        inc     de                ;{{e1ba:13}} 
        ret                       ;{{e1bb:c9}} 

;;====================================
;; tokenise single quote comment
tokenise_single_quote_comment:    ;{{Addr=$e1bc Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$01             ;{{e1bc:3e01}} 
        call    write_tokenised_byte_to_memory;{{e1be:cd08e0}} 
        ld      a,$c0             ;{{e1c1:3ec0}} "'"
;;=copy until end of buffer
copy_until_end_of_buffer:         ;{{Addr=$e1c3 Code Calls/jump count: 2 Data use count: 0}}
        call    write_tokenised_byte_to_memory;{{e1c3:cd08e0}} 
        ld      a,(hl)            ;{{e1c6:7e}} 
        inc     hl                ;{{e1c7:23}} 
        or      a                 ;{{e1c8:b7}} 
        jr      nz,copy_until_end_of_buffer;{{e1c9:20f8}}  (-$08)
        dec     hl                ;{{e1cb:2b}} 
        ret                       ;{{e1cc:c9}} 




;;***Detokenising.asm
;;<< LIST AND DETOKENISING BACK TO ASCII
;;========================================================================
;; command LIST
command_LIST:                     ;{{Addr=$e1cd Code Calls/jump count: 0 Data use count: 1}}
        call    eval_line_number_range_params;{{e1cd:cd0fcf}} 
        push    bc                ;{{e1d0:c5}} 
        push    de                ;{{e1d1:d5}} 
        call    eval_and_select_txt_stream;{{e1d2:cdcac1}} 
        call    syntax_error_if_not_02;{{e1d5:cd37de}} 
        call    zero_current_line_address;{{e1d8:cdaade}} 
        pop     de                ;{{e1db:d1}} 
        pop     bc                ;{{e1dc:c1}} 
        call    do_LIST           ;{{e1dd:cde3e1}} 
        jp      REPL_Read_Eval_Print_Loop;{{e1e0:c358c0}} 

;;========================================================================
;; do LIST
;;BC = starting line number
;;DE = ending line number

do_LIST:                          ;{{Addr=$e1e3 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{e1e3:d5}} 
        ld      d,b               ;{{e1e4:50}} 
        ld      e,c               ;{{e1e5:59}} 
        call    find_address_of_line;{{e1e6:cd64e8}} 
        pop     de                ;{{e1e9:d1}} 
_do_list_5:                       ;{{Addr=$e1ea Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{e1ea:4e}} 
        inc     hl                ;{{e1eb:23}} 
        ld      b,(hl)            ;{{e1ec:46}} 
        dec     hl                ;{{e1ed:2b}} 
        ld      a,b               ;{{e1ee:78}} 
        or      c                 ;{{e1ef:b1}} 
        ret     z                 ;{{e1f0:c8}} 

        call    test_for_break_key;{{e1f1:cd72c4}}  key
        push    hl                ;{{e1f4:e5}} 
        add     hl,bc             ;{{e1f5:09}} 
        ex      (sp),hl           ;{{e1f6:e3}} 
        push    de                ;{{e1f7:d5}} 
        push    hl                ;{{e1f8:e5}} 
        inc     hl                ;{{e1f9:23}} 
        inc     hl                ;{{e1fa:23}} 
        ld      e,(hl)            ;{{e1fb:5e}} 
        inc     hl                ;{{e1fc:23}} 
        ld      d,(hl)            ;{{e1fd:56}} 
        pop     hl                ;{{e1fe:e1}} 
        ex      (sp),hl           ;{{e1ff:e3}} 
        call    compare_HL_DE     ;{{e200:cdd8ff}}  HL=DE? Test for > final line number?
        ex      (sp),hl           ;{{e203:e3}} 
        jr      c,_do_list_37     ;{{e204:3812}}  (+$12)
        call    detokenise_line_atHL_to_buffer;{{e206:cd54e2}} 
        ld      hl,BASIC_input_area_for_lines_;{{e209:218aac}} 
_do_list_30:                      ;{{Addr=$e20c Code Calls/jump count: 1 Data use count: 0}}
        call    output_buffer_to_stream;{{e20c:cd1de2}} 
        inc     hl                ;{{e20f:23}} 
        ld      a,(hl)            ;{{e210:7e}} 
        or      a                 ;{{e211:b7}} 
        jr      nz,_do_list_30    ;{{e212:20f8}}  (-$08)
        call    output_new_line   ;{{e214:cd98c3}} ; new text line
        or      a                 ;{{e217:b7}} 
_do_list_37:                      ;{{Addr=$e218 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{e218:d1}} 
        pop     hl                ;{{e219:e1}} 
        jr      nc,_do_list_5     ;{{e21a:30ce}}  (-$32) Loop for next line
        ret                       ;{{e21c:c9}} 

;;=output buffer to stream
output_buffer_to_stream:          ;{{Addr=$e21d Code Calls/jump count: 1 Data use count: 0}}
        call    get_output_stream ;{{e21d:cdbec1}} 
        ld      a,(hl)            ;{{e220:7e}} 
        jr      c,_output_buffer_to_stream_8;{{e221:380a}}  (+$0a)
        call    output_raw_char   ;{{e223:cdb8c3}} 
        cp      $0a               ;{{e226:fe0a}} 
        ret     nz                ;{{e228:c0}} 

        ld      a,$0d             ;{{e229:3e0d}} 
        jr      _output_buffer_to_stream_12;{{e22b:1808}}  (+$08)

_output_buffer_to_stream_8:       ;{{Addr=$e22d Code Calls/jump count: 1 Data use count: 0}}
        cp      $20               ;{{e22d:fe20}} 
        ld      a,$01             ;{{e22f:3e01}} 
        call    c,output_raw_char ;{{e231:dcb8c3}} 
        ld      a,(hl)            ;{{e234:7e}} 
_output_buffer_to_stream_12:      ;{{Addr=$e235 Code Calls/jump count: 1 Data use count: 0}}
        jp      output_raw_char   ;{{e235:c3b8c3}} 

;;=detokenise line from line number
;Line number in HL
;If line number not found creates an empty buffer with the line number
detokenise_line_from_line_number: ;{{Addr=$e238 Code Calls/jump count: 1 Data use count: 0}}
        call    find_address_of_line;{{e238:cd64e8}} 
        jr      c,detokenise_line_atHL_to_buffer;{{e23b:3817}}  (+$17) Line found?
                                  ;Else create empty buffer with line number
;;=detokenise prepare buffer
detokenise_prepare_buffer:        ;{{Addr=$e23d Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{e23d:eb}} 
        call    convert_int_to_string;{{e23e:cd4aef}} 
        ld      de,$0100          ;{{e241:110001}} D=buffer length, E='append space' flag.
        ld      bc,BASIC_input_area_for_lines_;{{e244:018aac}} Buffer address
_detokenise_prepare_buffer_4:     ;{{Addr=$e247 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e247:7e}} Copy D bytes from (HL) to (BC) - line number?
        inc     hl                ;{{e248:23}} 
        ld      (bc),a            ;{{e249:02}} 
        inc     bc                ;{{e24a:03}} 
        dec     d                 ;{{e24b:15}} 
        or      a                 ;{{e24c:b7}} 
        jr      nz,_detokenise_prepare_buffer_4;{{e24d:20f8}}  (-$08)
        ld      (bc),a            ;{{e24f:02}} 
        dec     bc                ;{{e250:0b}} 
        jp      detokenise_append_space;{{e251:c3e8e2}} 

;;========================================
;;detokenise line atHL to buffer
;HL=address of line
detokenise_line_atHL_to_buffer:   ;{{Addr=$e254 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{e254:e5}} 
        call    detokenise_prepare_buffer;{{e255:cd3de2}} 
        pop     hl                ;{{e258:e1}} 
        inc     hl                ;{{e259:23}} 
        inc     hl                ;{{e25a:23}} 
        inc     hl                ;{{e25b:23}} 
        inc     hl                ;{{e25c:23}} 
;;=detokenise item loop
detokenise_item_loop:             ;{{Addr=$e25d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e25d:7e}} 
        ld      (bc),a            ;{{e25e:02}} 
        or      a                 ;{{e25f:b7}} 
        ret     z                 ;{{e260:c8}} 

        call    detokenise_single_item;{{e261:cd66e2}} 
        jr      detokenise_item_loop;{{e264:18f7}}  (-$09)

;;=detokenise single item
detokenise_single_item:           ;{{Addr=$e266 Code Calls/jump count: 1 Data use count: 0}}
        jp      m,detokenise_keyword;{{e266:faf8e2}} 
        cp      $02               ;{{e269:fe02}} 
        jr      c,detokenise_next_statement_tokens;{{e26b:381c}}  (+$1c)
        cp      $05               ;{{e26d:fe05}} 
        jr      c,detokenise_bit7_terminated_string;{{e26f:3842}}  (+$42)
        cp      $0e               ;{{e271:fe0e}} 
        jr      c,detokenise_bit7_terminated_string;{{e273:383e}}  (+$3e)
        cp      $20               ;{{e275:fe20}}  ' '
        jr      c,detokenise_number;{{e277:3831}}  (+$31)
        cp      $7c               ;{{e279:fe7c}}  '|'
        jr      z,detokenise_bar_command;{{e27b:2854}}  (+$54)
        call    convert_variable_type_suffix;{{e27d:cdd1e0}} 
        call    nc,test_if_letter_period_or_digit;{{e280:d49cff}} 
        call    c,detokenise_append_space_if_needed;{{e283:dce6e2}} 
        ld      a,(hl)            ;{{e286:7e}} 
        jr      detokenise_colon_string_or_unknown;{{e287:180d}}  (+$0d)

;;=detokenise next statement tokens
;Items which follow a &01 (next statement) token
detokenise_next_statement_tokens: ;{{Addr=$e289 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e289:23}} 
        ld      a,(hl)            ;{{e28a:7e}} 
        cp      $c0               ;{{e28b:fec0}} "'" comment
        jr      z,detokenise_comment;{{e28d:285d}}  (+$5d)
        cp      $97               ;{{e28f:fe97}} ELSE
        jr      z,_detokenise_keyword_2;{{e291:2869}}  (+$69)
        dec     hl                ;{{e293:2b}} 

        ld      a,$3a             ;{{e294:3e3a}} ":" If none of the above apply then we actually have a next statement
;;=detokenise colon string or unknown
detokenise_colon_string_or_unknown:;{{Addr=$e296 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,$00             ;{{e296:1e00}} 
        cp      $22               ;{{e298:fe22}}  '"'
        jr      nz,detokenise_literal_char;{{e29a:200b}}  (+$0b)
;;=detokenise string literal
;terninates with double quote or &00
detokenise_string_literal:        ;{{Addr=$e29c Code Calls/jump count: 1 Data use count: 0}}
        call    detokenise_append_char_literal;{{e29c:cdcae2}} 
        inc     hl                ;{{e29f:23}} 
        ld      a,(hl)            ;{{e2a0:7e}} 
        or      a                 ;{{e2a1:b7}} 
        ret     z                 ;{{e2a2:c8}} 

        cp      $22               ;{{e2a3:fe22}}  '"'
        jr      nz,detokenise_string_literal;{{e2a5:20f5}}  (-$0b)
;;=detokenise literal char
;(or unknown value)
detokenise_literal_char:          ;{{Addr=$e2a7 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e2a7:23}} 
        jr      detokenise_append_char_literal;{{e2a8:1820}}  (+$20)

;;=detokenise number
detokenise_number:                ;{{Addr=$e2aa Code Calls/jump count: 1 Data use count: 0}}
        call    detokenise_append_space_if_needed;{{e2aa:cde6e2}} 
        call    detokenise_numeric_literal;{{e2ad:cd2fe3}} 
        ld      e,$01             ;{{e2b0:1e01}} 
        ret                       ;{{e2b2:c9}} 

;;=detokenise bit7 terminated string
detokenise_bit7_terminated_string:;{{Addr=$e2b3 Code Calls/jump count: 2 Data use count: 0}}
        call    detokenise_append_space_if_needed;{{e2b3:cde6e2}} 
        ld      a,(hl)            ;{{e2b6:7e}} 
        push    af                ;{{e2b7:f5}} 
        inc     hl                ;{{e2b8:23}} 
        inc     hl                ;{{e2b9:23}} 
        inc     hl                ;{{e2ba:23}} 
        call    detokenise_copy_bit7_terminated_string;{{e2bb:cddbe2}} 
        pop     af                ;{{e2be:f1}} 
        ld      e,$01             ;{{e2bf:1e01}} 
        cp      $0b               ;{{e2c1:fe0b}} 
        ret     nc                ;{{e2c3:d0}} 

        ld      e,$00             ;{{e2c4:1e00}} 
        xor     $27               ;{{e2c6:ee27}} 
        and     $fd               ;{{e2c8:e6fd}} 

;;=detokenise append char literal
;Copy char in A to buffer at (BC), inc BC and dec D.
;D=remaining free chars in buffer space.
;But if buffer full (D=1) leave BC and D unchanged
;(future calls will overwrite last char in buffer)
detokenise_append_char_literal:   ;{{Addr=$e2ca Code Calls/jump count: 11 Data use count: 0}}
        ld      (bc),a            ;{{e2ca:02}} 
        inc     bc                ;{{e2cb:03}} 
        dec     d                 ;{{e2cc:15}} 
        ret     nz                ;{{e2cd:c0}} 

        dec     bc                ;{{e2ce:0b}} 
        inc     d                 ;{{e2cf:14}} 
        ret                       ;{{e2d0:c9}} 

;;=detokenise bar command
detokenise_bar_command:           ;{{Addr=$e2d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,$01             ;{{e2d1:1e01}} 
        call    detokenise_append_char_literal;{{e2d3:cdcae2}} 
        inc     hl                ;{{e2d6:23}} 
        ld      a,(hl)            ;{{e2d7:7e}} 
        inc     hl                ;{{e2d8:23}} 
        or      a                 ;{{e2d9:b7}} 
        ret     nz                ;{{e2da:c0}} 

;;=detokenise copy bit7 terminated string
;(string where last char has bit 7 set)
detokenise_copy_bit7_terminated_string:;{{Addr=$e2db Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e2db:7e}} 
        and     $7f               ;{{e2dc:e67f}} 
        call    detokenise_append_char_literal;{{e2de:cdcae2}} 
        cp      (hl)              ;{{e2e1:be}} 
        inc     hl                ;{{e2e2:23}} 
        jr      nc,detokenise_copy_bit7_terminated_string;{{e2e3:30f6}}  (-$0a)
        ret                       ;{{e2e5:c9}} 

;;=detokenise append space if needed
;Appends a space is E = 1
;I think this is optionally inserting spaces. Ie if one is needed after a keyword etc.
;Thus E = 'we've just read a keyword etc' flag
detokenise_append_space_if_needed:;{{Addr=$e2e6 Code Calls/jump count: 4 Data use count: 0}}
        dec     e                 ;{{e2e6:1d}} 
        ret     nz                ;{{e2e7:c0}} 

;;=detokenise append space
detokenise_append_space:          ;{{Addr=$e2e8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$20             ;{{e2e8:3e20}} 
        jr      detokenise_append_char_literal;{{e2ea:18de}}  (-$22)

;;---------------------------------------------------------------------------
;;=detokenise comment
detokenise_comment:               ;{{Addr=$e2ec Code Calls/jump count: 2 Data use count: 0}}
        call    _detokenise_keyword_2;{{e2ec:cdfce2}} 
_detokenise_comment_1:            ;{{Addr=$e2ef Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e2ef:7e}}  get token
        or      a                 ;{{e2f0:b7}}  end of line?
        ret     z                 ;{{e2f1:c8}} 
        call    detokenise_append_char_literal;{{e2f2:cdcae2}} 
        inc     hl                ;{{e2f5:23}}  increment pointer for next token
        jr      _detokenise_comment_1;{{e2f6:18f7}} 

;;---------------------------------------------------------------------------
;;=detokenise keyword
detokenise_keyword:               ;{{Addr=$e2f8 Code Calls/jump count: 1 Data use count: 0}}
        cp      $c5               ;{{e2f8:fec5}} REM
        jr      z,detokenise_comment;{{e2fa:28f0}}  (-$10)
;; =detokenise else and comment
_detokenise_keyword_2:            ;{{Addr=$e2fc Code Calls/jump count: 2 Data use count: 0}}
        inc     hl                ;{{e2fc:23}} 
        cp      $ff               ;{{e2fd:feff}} 
        jr      nz,_detokenise_keyword_7;{{e2ff:2002}}  (+$02)
        ld      a,(hl)            ;{{e301:7e}} 
        inc     hl                ;{{e302:23}} 
_detokenise_keyword_7:            ;{{Addr=$e303 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{e303:f5}} 
        push    hl                ;{{e304:e5}} 
        call    convert_token_to_keyword_text_ptr;{{e305:cdb8e3}} 
        or      a                 ;{{e308:b7}} 
        jr      z,_detokenise_keyword_16;{{e309:2808}}  (+$08)
        push    af                ;{{e30b:f5}} 
        call    detokenise_append_space_if_needed;{{e30c:cde6e2}} 
        pop     af                ;{{e30f:f1}} 

;Copy keyword text to buffer
        call    detokenise_append_char_literal;{{e310:cdcae2}} 
_detokenise_keyword_16:           ;{{Addr=$e313 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e313:7e}} 
        and     $7f               ;{{e314:e67f}} 
        cp      $09               ;{{e316:fe09}} Filter out TAB chars. These are used in GO TO and GO SUB...
        call    nz,detokenise_append_char_literal;{{e318:c4cae2}} ...so you can type them in either way.
        cp      (hl)              ;{{e31b:be}} 
        inc     hl                ;{{e31c:23}} 
        jr      z,_detokenise_keyword_16;{{e31d:28f4}}  (-$0c)

;Set E depending on whether keyword ends in a letter/number or not
;(E='need a space after this' flag)
        call    test_if_letter_period_or_digit;{{e31f:cd9cff}} 
        ld      e,$00             ;{{e322:1e00}} 
        jr      nc,_detokenise_keyword_27;{{e324:3002}}  (+$02)
        ld      e,$01             ;{{e326:1e01}} 
_detokenise_keyword_27:           ;{{Addr=$e328 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e328:e1}} 
        pop     af                ;{{e329:f1}} 
        sub     $e4               ;{{e32a:d6e4}} 
        ret     nz                ;{{e32c:c0}} 

        ld      e,a               ;{{e32d:5f}} 
        ret                       ;{{e32e:c9}} 

;;----------------------------------------------------
;;=detokenise numeric literal
detokenise_numeric_literal:       ;{{Addr=$e32f Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{e32f:d5}} 

        ld      a,(hl)            ;{{e330:7e}} ; get token
        inc     hl                ;{{e331:23}} 
        cp      $1f               ;{{e332:fe1f}}  floating point value
        jr      z,detokenise_floating_point;{{e334:285d}} 

        ld      e,(hl)            ;{{e336:5e}} ; read 16-bit value
        inc     hl                ;{{e337:23}} 
        ld      d,(hl)            ;{{e338:56}} 
        inc     hl                ;{{e339:23}} 

;; DE = 16-bit value
;; A = token value (indicates type of 16-bit data)

        cp      $1b               ;{{e33a:fe1b}}  16-bit integer binary value
        jr      z,detokenise_binary_number;{{e33c:2832}} 
        cp      $1c               ;{{e33e:fe1c}}  16-bt integer hexadecimal value
        jr      z,detokenise_hex_number;{{e340:2839}} 
        cp      $1e               ;{{e342:fe1e}}  16-bit integer BASIC line number
        jr      z,detokenise_line_number;{{e344:2823}} 
        cp      $1d               ;{{e346:fe1d}}  16-bit BASIC program line memory address pointer
        jr      z,detokenise_line_number_ptr;{{e348:2816}} 
        cp      $1a               ;{{e34a:fe1a}}  16-bit integer decimal value
        jr      z,detokenise_16bit_decimal;{{e34c:280b}} 

;;------------------------
;;=detokenise 8-bit value

        dec     hl                ;{{e34e:2b}} 
        ld      d,$00             ;{{e34f:1600}} 
        cp      $19               ;{{e351:fe19}}  8-bit integer decimal value
        jr      z,detokenise_16bit_decimal;{{e353:2804}}  (+$04)
        dec     hl                ;{{e355:2b}} 
        sub     $0e               ;{{e356:d60e}} 
        ld      e,a               ;{{e358:5f}} 

;;=detokenise 16bit decimal
detokenise_16bit_decimal:         ;{{Addr=$e359 Code Calls/jump count: 2 Data use count: 0}}
        ex      (sp),hl           ;{{e359:e3}} 
        ex      de,hl             ;{{e35a:eb}} 
        call    store_HL_in_accumulator_as_INT;{{e35b:cd35ff}} 
        jr      _detokenise_floating_point_4;{{e35e:183a}}  (+$3a)

;;=detokenise line number ptr
detokenise_line_number_ptr:       ;{{Addr=$e360 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e360:e5}} 
        ex      de,hl             ;{{e361:eb}} 
        inc     hl                ;{{e362:23}} 
        inc     hl                ;{{e363:23}} 
        inc     hl                ;{{e364:23}} 
        ld      e,(hl)            ;{{e365:5e}} 
        inc     hl                ;{{e366:23}} 
        ld      d,(hl)            ;{{e367:56}} 
        pop     hl                ;{{e368:e1}} 
;;=detokenise line number
detokenise_line_number:           ;{{Addr=$e369 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{e369:e3}} 
        ex      de,hl             ;{{e36a:eb}} 
        call    convert_int_to_string;{{e36b:cd4aef}} 
        jr      detokenise_copy_asciiz;{{e36e:182d}}  (+$2d)

;;=detokenise binary number
detokenise_binary_number:         ;{{Addr=$e370 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{e370:e3}} 
        ld      a,$58             ;{{e371:3e58}}  "X" - binary number prefix
        scf                       ;{{e373:37}} 
        push    af                ;{{e374:f5}} 
        push    bc                ;{{e375:c5}} 
        ld      bc,$0101          ;{{e376:010101}} 
        jr      detokenise_based_number;{{e379:1807}}  (+$07)

;;=detokenise hex number
detokenise_hex_number:            ;{{Addr=$e37b Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{e37b:e3}} 
        or      a                 ;{{e37c:b7}} 
        push    af                ;{{e37d:f5}} 
        push    bc                ;{{e37e:c5}} 
        ld      bc,$040f          ;{{e37f:010f04}} 

;;=detokenise based number
;BC=format. See convert_based_number_to_string
detokenise_based_number:          ;{{Addr=$e382 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{e382:eb}} 
        xor     a                 ;{{e383:af}} 
        call    convert_based_number_to_string;{{e384:cddff1}} 
        pop     bc                ;{{e387:c1}} 
        ld      a,$26             ;{{e388:3e26}} "&"
        call    detokenise_append_char_literal;{{e38a:cdcae2}} 
        pop     af                ;{{e38d:f1}} 
        call    c,detokenise_append_char_literal;{{e38e:dccae2}} Append binary number prefix
        jr      detokenise_copy_asciiz;{{e391:180a}}  (+$0a)

;;------------------------------------------------
;;=detokenise floating point

detokenise_floating_point:        ;{{Addr=$e393 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$05             ;{{e393:3e05}} 
        call    copy_atHL_to_accumulator_type_A;{{e395:cd6cff}} 
        ex      (sp),hl           ;{{e398:e3}} 
        ex      de,hl             ;{{e399:eb}} 

;;------------------------------------------------
_detokenise_floating_point_4:     ;{{Addr=$e39a Code Calls/jump count: 1 Data use count: 0}}
        call    convert_float_atHL_to_string;{{e39a:cd5aef}} 

;;=detokenise copy asciiz
detokenise_copy_asciiz:           ;{{Addr=$e39d Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{e39d:7e}} 
        inc     hl                ;{{e39e:23}} 
        call    detokenise_append_char_literal;{{e39f:cdcae2}} 
        ld      a,(hl)            ;{{e3a2:7e}} 
        or      a                 ;{{e3a3:b7}} 
        jr      nz,detokenise_copy_asciiz;{{e3a4:20f7}}  (-$09)
        pop     hl                ;{{e3a6:e1}} 
        ret                       ;{{e3a7:c9}} 





;;***KeywordLUTs.asm
;;<< KEYWORD LOOK UP TABLES
;;< And associated functions
;;=======================================================================
;; get keyword table for letter
;; A = initial letter of BASIC keyword
get_keyword_table_for_letter:     ;{{Addr=$e3a8 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e3a8:e5}} 
        sub     $41               ;{{e3a9:d641}}  initial letter - 'A'
                                  ; number in range 0->27
        add     a,a               ;{{e3ab:87}}  x2 (two bytes per table entry)
                                  ; A = offset into table

        add     a,(keyword_table_per_letter) and $ff;{{e3ac:c618}} $18  table starts at $e418 Low byte of keyword table address
        ld      l,a               ;{{e3ae:6f}} 
        adc     a,(keyword_table_per_letter >> 8);{{e3af:cee4}} $e4  high byte of keyword table address
        sub     l                 ;{{e3b1:95}} 
        ld      h,a               ;{{e3b2:67}} 

        ld      e,(hl)            ;{{e3b3:5e}}  get address of keyword list from table
        inc     hl                ;{{e3b4:23}} 
        ld      d,(hl)            ;{{e3b5:56}} 
        pop     hl                ;{{e3b6:e1}} 
        ret                       ;{{e3b7:c9}} 

;;========================================================================
;;convert token to keyword text ptr
convert_token_to_keyword_text_ptr:;{{Addr=$e3b8 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e3b8:c5}} 
        ld      c,a               ;{{e3b9:4f}} 
        ld      b,$1a             ;{{e3ba:061a}}  Table count
        ld      hl,keyword_table_Z;{{e3bc:214ce4}} 

_convert_token_to_keyword_text_ptr_4:;{{Addr=$e3bf Code Calls/jump count: 1 Data use count: 0}}
        call    search_within_a_single_table;{{e3bf:cdd7e3}}  Loop through each table
        jr      c,_convert_token_to_keyword_text_ptr_12;{{e3c2:380e}}  (+$0e)
        inc     hl                ;{{e3c4:23}} 
        djnz    _convert_token_to_keyword_text_ptr_4;{{e3c5:10f8}}  (-$08)

        ld      hl,symbols_table  ;{{e3c7:2136e7}}  Also search symbols table
        call    search_within_a_single_table;{{e3ca:cdd7e3}} 
        jp      nc,Error_Syntax_Error;{{e3cd:d249cb}}  Not found: Syntax Error
        ld      b,$c0             ;{{e3d0:06c0}} "'" comment

_convert_token_to_keyword_text_ptr_12:;{{Addr=$e3d2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{e3d2:78}} 
        add     a,$40             ;{{e3d3:c640}} 
        pop     bc                ;{{e3d5:c1}} 
        ret                       ;{{e3d6:c9}} 

;;=search within a single table
search_within_a_single_table:     ;{{Addr=$e3d7 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(hl)            ;{{e3d7:7e}} 
        or      a                 ;{{e3d8:b7}} 
        ret     z                 ;{{e3d9:c8}}  Until trailing zero byte found

        push    hl                ;{{e3da:e5}} 
_search_within_a_single_table_4:  ;{{Addr=$e3db Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e3db:7e}} 
        inc     hl                ;{{e3dc:23}} 
        rla                       ;{{e3dd:17}}  Find byte with bit 7 set
        jr      nc,_search_within_a_single_table_4;{{e3de:30fb}}  (-$05)

        ld      a,(hl)            ;{{e3e0:7e}} 
        inc     hl                ;{{e3e1:23}} 
        cp      c                 ;{{e3e2:b9}}  Next byte is the token
        jr      z,_search_within_a_single_table_14;{{e3e3:2803}}  (+$03)
        pop     af                ;{{e3e5:f1}} 
        jr      search_within_a_single_table;{{e3e6:18ef}}  (-$11)

_search_within_a_single_table_14: ;{{Addr=$e3e8 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e3e8:e1}}  Entry found
        scf                       ;{{e3e9:37}} 
        ret                       ;{{e3ea:c9}} 

;;==========================================
;;keyword to token within single table
;;DE=ptr in buffer
;;HL=ptr to table
keyword_to_token_within_single_table:;{{Addr=$e3eb Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(de)            ;{{e3eb:1a}} End of buffer?
        or      a                 ;{{e3ec:b7}} 
        ret     z                 ;{{e3ed:c8}} 

        push    hl                ;{{e3ee:e5}} 
_keyword_to_token_within_single_table_4:;{{Addr=$e3ef Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{e3ef:1a}}  Get buffer char, skipping white space
        inc     de                ;{{e3f0:13}} 
        cp      $09               ;{{e3f1:fe09}} 
        jr      z,_keyword_to_token_within_single_table_10;{{e3f3:2804}}  (+$04)
        cp      $20               ;{{e3f5:fe20}} 
        jr      nz,test_letter_for_match;{{e3f7:2005}}  (+$05)
_keyword_to_token_within_single_table_10:;{{Addr=$e3f9 Code Calls/jump count: 1 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{e3f9:cd4dde}}  skip space, lf or tab
        jr      _keyword_to_token_within_single_table_4;{{e3fc:18f1}}  (-$0f)

;;-----------------------------------------------------
;;=test letter for match
test_letter_for_match:            ;{{Addr=$e3fe Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{e3fe:4f}} 
        ld      a,(hl)            ;{{e3ff:7e}} 
        inc     hl                ;{{e400:23}} 
        call    convert_character_to_upper_case;{{e401:cdabff}} ; convert character to upper case
        xor     c                 ;{{e404:a9}} ; character the same?
        jr      z,_keyword_to_token_within_single_table_4;{{e405:28e8}} match but not end of keyword - next character

;; character not the same?
        and     $7f               ;{{e407:e67f}} mask out bit 7 - end of word
        jr      z,entry_found     ;{{e409:280a}}  (+$0a) if it wasn't zero but now is the we've found word
        dec     de                ;{{e40b:1b}}  else skip to next entry
_test_letter_for_match_9:         ;{{Addr=$e40c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{e40c:1a}} 
        inc     de                ;{{e40d:13}} 
        rla                       ;{{e40e:17}} 
        jr      nc,_test_letter_for_match_9;{{e40f:30fb}}  (-$05)
        inc     de                ;{{e411:13}} 
        pop     hl                ;{{e412:e1}} 
        jr      keyword_to_token_within_single_table;{{e413:18d6}}  (-$2a)

;;=entry found
entry_found:                      ;{{Addr=$e415 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{e415:f1}} 
        scf                       ;{{e416:37}} 
        ret                       ;{{e417:c9}} 

;;===================
;; keyword table per letter
;; list of keywords sorted into alphabetical order
keyword_table_per_letter:         ;{{Addr=$e418 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defw keyword_table_A      ; AUTO, ATN, ASC, AND, AFTER, ABS
        defw keyword_table_B      ; BORDER, BIN$
        defw keyword_table_C      ; CURSOR, CREAL, COS, COPYCHR$, CONT, CLS, CLOSEOUT, CLOSEIN, CLG, CLEAR, CINT, CHR$, CHAIN, CAT, CALL
        defw keyword_table_D      ; DRAWR, DRAW, DIM, DI, DERR, DELETE, DEG, DEFSTR, DEFREAL, DEFINT, DEF, DEC$, DATA
        defw keyword_table_E      ; EXP, EVERY, ERROR, ERR, ERL, ERASE, EOF, ENV, ENT, END, ELSE, EI, EDIT
        defw keyword_table_F      ; FRE, FRAME, FOR, FN, FIX, FILL
        defw keyword_table_G      ; GRAPHICS, GOTO, GOSUB
        defw keyword_table_H      ; HIMEM, HEX$
        defw keyword_table_I      ; INT,INSTR, INPUT, INP, INKEY$, INKEY, INK, IF
        defw keyword_table_J      ; JOY
        defw keyword_table_K      ; KEY
        defw keyword_table_L      ; LOWER$, LOG10, LOG, LOCATE, LOAD, LIST, LINE, LET, LEN, LEFT$
        defw keyword_table_M      ; MOVER, MOVE, MODE, MOD, MIN, MID$, MERGE, MEMORY, MAX, MASK
        defw keyword_table_N      ; NOT, NEW, NEXT
        defw keyword_table_O      ; OUT, ORIGIN, OR, OPENOUT, OPENIN, ON SQ, ON ERROR GOTO, ON BREAK, ON
        defw keyword_table_P      ; PRINT, POS, POKE PLOTR, PLOT, PI, PEN, PEEK, PAPER
        defw keyword_table_Q      ; (no keywords defined)
        defw keyword_table_R      ; RUN, ROUND, RND, RIGHT$, RETURN, RESUME, RESTORE, RENUM, REMAIN, REM, RELEASE, READ, RANDOMIZE, RAD
        defw keyword_table_S      ; SYMBOL, SWAP, STRING$, STR$, STOP, STEP, SQR, SQ, SPEED, SPC, SPACE$, SOUND, SIN, SGN, SAVE
        defw keyword_table_T      ; TRON, TROFF, TO, TIME, THEN, TESTR, TEST, TAN, TAGOFF, TAG, TAB
        defw keyword_table_U      ; USING, UPPER$, UNT
        defw keyword_table_V      ; VPOS, VAL
        defw keyword_table_W      ; WRITE, WINDOW, WIDTH, WHILE, WEND, WAIT
        defw keyword_table_X      ; XPOS, XOR
        defw keyword_table_Y      ; YPOS
        defw keyword_table_Z      ; ZONE


;;======================================================================
;; Keyword table
;; list of keyword as text followed by keyword byte (token?)
;; end of list signalled with a 0 byte 
;;
;; - BASIC keyword stored excluding initial letter
;; e.g. "ZONE" is stored as "ONE"
;; - BASIC keyword stored with bit 7 of last letter of keyword set.
;; e.g. "ON","E"+$80 for ZONE
;; - keyword followed by keyword byte (token?)

;;=keyword table Z
keyword_table_Z:                  ;{{Addr=$e44c Data Calls/jump count: 0 Data use count: 2}}
                                  
        defb "ON","E"+$80,$da     ; ZONE
        defb 0                    

;;=keyword table Y
keyword_table_Y:                  ;{{Addr=$e451 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$48     ; YPOS
        defb 0                    

;;=keyword table X
keyword_table_X:                  ;{{Addr=$e456 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$47     ; XPOS
        defb "O","R"+$80,$fd      ; XOR
        defb 0                    

;;=keyword table W
keyword_table_W:                  ;{{Addr=$e45e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RIT","E"+$80,$d9    ; WRITE
        defb "INDO","W"+$80,$d8   ; WINDOW
        defb "IDT","H"+$80,$d7    ; WIDTH
        defb "HIL","E"+$80,$d6    ; WHILE
        defb "EN","D"+$80,$d5     ; WEND 
        defb "AI","T"+$80,$d4     ; WAIT
        defb 0                    

;;=keyword table V
keyword_table_V:                  ;{{Addr=$e47c Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "PO","S"+$80,$7f     ; VPOS
        defb "A","L"+$80,$1d      ; VAL
        defb 0                    

;;=keyword table U
keyword_table_U:                  ;{{Addr=$e484 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "SIN","G"+$80,$ed    ; USING
        defb "PPER","$"+$80,$1c   ; UPPER$
        defb "N","T"+$80,$1b      ; UNT
        defb 0                    

;;=keyword table T
keyword_table_T:                  ;{{Addr=$e493 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RO","N"+$80,$d3     ; TRON
        defb "ROF","F"+$80,$d2    ; TROFF
        defb "O"+$80,$ec          ; TO
        defb "IM","E"+$80,$46     ; TIME
        defb "HE","N"+$80,$eb     ; THEN
        defb "EST","R"+$80,$7d    ; TESTR
        defb "ES","T"+$80,$7c     ; TEST 
        defb "A","N"+$80,$1a      ; TAN
        defb "AGOF","F"+$80,$d1   ; TAFOFF
        defb "A","G"+$80,$d0      ; TAG
        defb "A","B"+$80,$ea      ; TAB
        defb 0                    

;;=keyword table S
keyword_table_S:                  ;{{Addr=$e4bf Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "YMBO","L"+$80,$cf   ; SYMBOL
        defb "WA","P"+$80,$e7     ; SWAP
        defb "TRING","$"+$80,$7b  ; STRING$
        defb "TR","$"+$80,$19     ; STR$
        defb "TO","P"+$80,$ce     ; STOP
        defb "TE","P"+$80,$e6     ; STEP
        defb "Q","R"+$80,$18      ; SQR
        defb "Q"+$80,$17          ; SQ
        defb "PEE","D"+$80,$cd    ; SPEED
        defb "P","C"+$80,$e5      ; SPC
        defb "PACE","$"+$80,$16   ; SPACE$
        defb "OUN","D"+$80,$cc    ; SOUND
        defb "I","N"+$80,$15      ; SIN
        defb "G","N"+$80,$14      ; SGN
        defb "AV","E"+$80,$cb     ; SAVE
        defb 0                    

;;=keyword table R
keyword_table_R:                  ;{{Addr=$e4ff Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "U","N"+$80,$ca      ; RUN
        defb "OUN","D"+$80,$7a    ; ROUND
        defb "N","D"+$80,$45      ; RND
        defb "IGHT","$"+$80,$79   ; RIGHT$
        defb "ETUR","N"+$80,$c9   ; RETURN
        defb "ESUM","E"+$80,$c8   ; RESUME
        defb "ESTOR","E"+$80,$c7  ; RESTORE
        defb "ENU","M"+$80,$c6    ; RENUM
        defb "EMAI","N"+$80,$13   ; REMAIN
        defb "E","M"+$80,$c5      ; REM
        defb "ELEAS","E"+$80,$c4  ; RELEASE
        defb "EA","D"+$80,$c3     ; READ
        defb "ANDOMIZ","E"+$80,$c2; RANDOMIZE
        defb "A","D"+$80,$c1      ; RAD
        defb 0                    

;;=keyword table Q
keyword_table_Q:                  ;{{Addr=$e549 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb 0                    

;;=keyword table P
keyword_table_P:                  ;{{Addr=$e54a Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RIN","T"+$80,$bf    ; PRINT
        defb "O","S"+$80,$78      ; POS
        defb "OK","E"+$80,$be     ; POKE
        defb "LOT","R"+$80,$bd    ; PLOTR
        defb "LO","T"+$80,$bc     ; PLOT
        defb "I"+$80,$44          ; PI
        defb "E","N"+$80,$bb      ; PEN 
        defb "EE","K"+$80,$12     ; PEEK
        defb "APE","R"+$80,$ba    ; PAPER
        defb 0                    

;;=keyword table O
keyword_table_O:                  ;{{Addr=$e56e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "U","T"+$80,$b9      ; OUT
        defb "RIGI","N"+$80,$b8   ; ORIGIN
        defb "R"+$80,$fc          ; OR
        defb "PENOU","T"+$80,$b7  ; OPENOUT
        defb "PENI","N"+$80,$b6   ; OPENIN
        defb "N S","Q"+$80,$b5    ; ON SQ
        defb "N ERROR GO",$09,"TO ","0"+$80,$b4; ON ERROR GOTO 0, ON ERROR GO TO 0 (but not ON ERROR GOTO/GO TO [n])
        defb "N BREA","K"+$80,$b3 ; ON BREAK
        defb "N"+$80,$b2          ; ON (and ON ERROR GOTO, ON ERROR GO TO)
        defb 0                    

;;=keyword table N
keyword_table_N:                  ;{{Addr=$e5a6 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "O","T"+$80,$fe      ; NOT
        defb "E","W"+$80,$b1      ; NEW
        defb "EX","T"+$80,$b0     ; NEXT
        defb 0                    

;;=keyword table M
keyword_table_M:                  ;{{Addr=$e5b1 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "OVE","R"+$80,$af    ; MOVER
        defb "OV","E"+$80,$ae     ; MOVE
        defb "OD","E"+$80,$ad     ; MODE
        defb "O","D"+$80,$fb      ; MOD
        defb "I","N"+$80,$77      ; MIN
        defb "ID","$"+$80,$ac     ; MID$
        defb "ERG","E"+$80,$ab    ; MERGE
        defb "EMOR","Y"+$80,$aa   ; MEMORY
        defb "A","X"+$80,$76      ; MAX
        defb "AS","K"+$80,$df     ; MASK
        defb 0                    

;;=keyword table L
keyword_table_L:                  ;{{Addr=$e5db Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "OWER","$"+$80,$11   ; LOWER$
        defb "OG1","0"+$80,$10    ; LOG10
        defb "O","G"+$80,$0f      ; LOG
        defb "OCAT","E"+$80,$a9   ; LOCATE
        defb "OA","D"+$80,$a8     ; LOAD
        defb "IS","T"+$80,$a7     ; LIST
        defb "IN","E"+$80,$a6     ; LINE
        defb "E","T"+$80,$a5      ; LET
        defb "E","N"+$80,$0e      ; LEN 
        defb "EFT","$"+$80,$75    ; LEFT$
        defb 0                    

;;=keyword table K
keyword_table_K:                  ;{{Addr=$e607 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "E","Y"+$80,$a4      ; KEY
        defb 0                    

;;=keyword table J
keyword_table_J:                  ;{{Addr=$e60b Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "O","Y"+$80,$0d      ; JOY
        defb 0                    

;;=keyword table I
keyword_table_I:                  ;{{Addr=$e60f Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "N","T"+$80,$0c      ; INT
        defb "NST","R"+$80,$74    ; INSTR
        defb "NPU","T"+$80,$a3    ; INPUT
        defb "N","P"+$80,$0b      ; INP
        defb "NKEY","$"+$80,$43   ; INKEY$
        defb "NKE","Y"+$80,$0a    ; INKEY
        defb "N","K"+$80,$a2      ; INK
        defb "F"+$80,$a1          ; IF
        defb 0                    

;;=keyword table H
keyword_table_H:                  ;{{Addr=$e630 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "IME","M"+$80,$42    ; HIMEM
        defb "EX","$"+$80,$73     ; HEX$
        defb 0                    

;;=keyword table G
keyword_table_G:                  ;{{Addr=$e63a Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RAPHIC","S"+$80,$de ; GRAPHICS
        defb "O",$09,"T","O"+$80,$a0;GO TO, GOTO
        defb "O",$09,"SU","B"+$80,$9f;GO SUB, GOSUB
        defb 0                    

;;=keyword table F
keyword_table_F:                  ;{{Addr=$e64e Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "R","E"+$80,$09      ; FRE
        defb "RAM","E"+$80,$e0    ; FRAME
        defb "O","R"+$80,$9e      ; FOR
        defb "N"+$80,$e4          ; FN
        defb "I","X"+$80,$08      ; FIX
        defb "IL","L"+$80,$dd     ; FILL
        defb 0                    

;;=keyword table E
keyword_table_E:                  ;{{Addr=$e663 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "X","P"+$80,$07      ; EXP
        defb "VER","Y"+$80,$9d    ; EVERY
        defb "RRO","R"+$80,$9c    ; ERROR
        defb "R","R"+$80,$41      ; ERR
        defb "R","L"+$80,$e3      ; ERL
        defb "RAS","E"+$80,$9b    ; ERASE
        defb "O","F"+$80,$40      ; EOF
        defb "N","V"+$80,$9a      ; ENV
        defb "N","T"+$80,$99      ; ENT
        defb "N","D"+$80,$98      ; END
        defb "LS","E"+$80,$97     ; ELSE
        defb "I"+$80,$dc          ; EI
        defb "DI","T"+$80,$96     ; EDIT
        defb 0                    

;;=keyword table D
keyword_table_D:                  ;{{Addr=$e692 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "RAW","R"+$80,$95    ; DRAWR
        defb "RA","W"+$80,$94     ; DRAW
        defb "I","M"+$80,$93      ; DIM
        defb "I"+$80,$db          ; DI
        defb "ER","R"+$80,$49     ; DERR
        defb "ELET","E"+$80,$92   ; DELETE
        defb "E","G"+$80,$91      ; DEG
        defb "EFST","R"+$80,$90   ; DEFSTR
        defb "EFREA","L"+$80,$8f  ; DEFREAL
        defb "EFIN","T"+$80,$8e   ; DEFINT
        defb "E","F"+$80,$8d      ; DEF
        defb "EC","$"+$80,$72     ; DEC$
        defb "AT","A"+$80,$8c     ; DATA
        defb 0                    

;;=keyword table C
keyword_table_C:                  ;{{Addr=$e6cc Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "URSO","R"+$80,$e1   ; CURSOR
        defb "REA","L"+$80,$06    ; CREAL
        defb "O","S"+$80,$05      ; COS
        defb "OPYCHR","$"+$80,$7e ; COPYCHR$
        defb "ON","T"+$80,$8b     ; CONT
        defb "L","S"+$80,$8a      ; CLS
        defb "LOSEOU","T"+$80,$89 ; CLOSEOUT
        defb "LOSEI","N"+$80,$88  ; CLOSEIN
        defb "L","G"+$80,$87      ; CLG
        defb "LEA","R"+$80,$86    ; CLEAR
        defb "IN","T"+$80,$04     ; CINT
        defb "HR","$"+$80,$03     ; CHR$
        defb "HAI","N"+$80,$85    ; CHAIN
        defb "A","T"+$80,$84      ; CAT
        defb "AL","L"+$80,$83     ; CALL
        defb 0                    

;;=keyword table B
keyword_table_B:                  ;{{Addr=$e715 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "ORDE","R"+$80,$82   ; BORDER
        defb "IN","$"+$80,$71     ; BIN$
        defb 0                    

;;=keyword table A
keyword_table_A:                  ;{{Addr=$e720 Data Calls/jump count: 0 Data use count: 1}}
                                  
        defb "UT","O"+$80,$81     ; AUTO
        defb "T","N"+$80,$02      ; ATN
        defb "S","C"+$80,$01      ; ASC
        defb "N","D"+$80,$fa      ; AND
        defb "FTE","R"+$80,$80    ; AFTER
        defb "B","S"+$80,$00      ; ABS
        defb 0                    

;;=symbols table
symbols_table:                    ;{{Addr=$e736 Data Calls/jump count: 0 Data use count: 2}}
                                  
        defb "^"+$80,$f8          ;
        defb $5c+$80,$f9          ; "\"
        defb ">",$09,"="+$80,$f0  ;
        defb "= ",">"+$80,$f0     ;
        defb ">"+$80,$ee          ;
        defb "<",$09,">"+$80,$f2  ;
        defb "<",$09,"="+$80,$f3  ;
        defb "= ","<"+$80,$f3     ;
        defb "="+$80,$ef          ;
        defb "<"+$80,$f1          ;
        defb "/"+$80,$f7          ;
        defb ":"+$80,$01          ;
        defb "*"+$80,$f6          ;
        defb "-"+$80,$f5          ;
        defb "+"+$80,$f4          ;
        defb "'"+$80,$c0          ;
        defb 0                    





;;***ProgramManipulation.asm
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




;;***LoadSaveRun.asm
;;<< FILE HANDLING
;;< RUN, LOAD, CHAIN, MERGE, SAVE
;;==========================================================================
;; command RUN

command_RUN:                      ;{{Addr=$ea78 Code Calls/jump count: 0 Data use count: 1}}
        call    is_next_02        ;{{ea78:cd3dde}} 
        ld      de,(address_of_end_of_ROM_lower_reserved_are);{{ea7b:ed5b64ae}} 
        jr      c,_command_run_15 ;{{ea7f:381d}}  (+$1d)
        cp      $1e               ;{{ea81:fe1e}}  16-bit line number
        jr      z,_command_run_13 ;{{ea83:2815}}  (+$15)
        cp      $1d               ;{{ea85:fe1d}} 
        jr      z,_command_run_13 ;{{ea87:2811}}  (+$11)
        call    LOAD_read_parameters;{{ea89:cdd1ea}} 
        ld      hl,RUN_a_program_after_loading;{{ea8c:21f1ea}} ##LABEL##
        jp      nc,MC_BOOT_PROGRAM;{{ea8f:d213bd}}  firmware function: mc boot program

        call    validate_and_LOAD_BASIC;{{ea92:cd6dec}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ea95:2a64ae}} 
        jr      _command_run_21   ;{{ea98:1812}}  (+$12)


_command_run_13:                  ;{{Addr=$ea9a Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_convert_line_number_to_line_address;{{ea9a:cd27e8}} 
        ret     nz                ;{{ea9d:c0}} 
_command_run_15:                  ;{{Addr=$ea9e Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ea9e:d5}} 
        call    close_input_and_output_streams;{{ea9f:cd00d3}}  close input and output streams
        call    _reset_basic_22   ;{{eaa2:cd78c1}} 
        call    _reset_basic_33   ;{{eaa5:cd8fc1}} 
        call    _reset_basic_14   ;{{eaa8:cd62c1}} 
        pop     hl                ;{{eaab:e1}} 
_command_run_21:                  ;{{Addr=$eaac Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{eaac:e3}} 
        call    GRA_DEFAULT       ;{{eaad:cd43bd}} 
        pop     hl                ;{{eab0:e1}} 
        inc     hl                ;{{eab1:23}} 
        jp      execute_end_of_line;{{eab2:c377de}} 

;;========================================================================
;; command LOAD

command_LOAD:                     ;{{Addr=$eab5 Code Calls/jump count: 0 Data use count: 1}}
        call    LOAD_read_parameters;{{eab5:cdd1ea}} 
        jr      nc,do_LOAD_binary ;{{eab8:3006}}  (+$06)
        call    validate_and_LOAD_BASIC;{{eaba:cd6dec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eabd:c358c0}} 

;;=do LOAD binary
do_LOAD_binary:                   ;{{Addr=$eac0 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{eac0:e5}} 
        call    _raise_memory_full_error_1;{{eac1:cdabf5}} 
        ld      hl,(address_to_load_cassette_file_to);{{eac4:2a26ae}} 
        call    CAS_IN_DIRECT     ;{{eac7:cd83bc}}  firmware function: cas in direct
        jp      z,raise_file_not_open_error_C;{{eaca:ca37cc}} 
        pop     hl                ;{{eacd:e1}} 
        jp      command_CLOSEIN   ;{{eace:c3edd2}}  CLOSEIN

;;=LOAD read parameters
LOAD_read_parameters:             ;{{Addr=$ead1 Code Calls/jump count: 2 Data use count: 0}}
        call    read_filename_and_open_for_input;{{ead1:cd54ec}} 
        and     $0e               ;{{ead4:e60e}} 
        xor     $02               ;{{ead6:ee02}} 
        jr      z,LOAD_read_dest_addr;{{ead8:2808}}  (+$08)
        call    syntax_error_if_not_02;{{eada:cd37de}} 
        call    _reset_basic_19   ;{{eadd:cd6fc1}} 
        scf                       ;{{eae0:37}} 
        ret                       ;{{eae1:c9}} 

;;=LOAD read dest addr
LOAD_read_dest_addr:              ;{{Addr=$eae2 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{eae2:cd41de}} 
        call    c,eval_expr_as_uint;{{eae5:dcf5ce}} 
        ld      (address_to_load_cassette_file_to),de;{{eae8:ed5326ae}} 
        call    syntax_error_if_not_02;{{eaec:cd37de}} 
        or      a                 ;{{eaef:b7}} 
        ret                       ;{{eaf0:c9}} 

;;==========================================================================
;; RUN a program after loading

RUN_a_program_after_loading:      ;{{Addr=$eaf1 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_to_load_cassette_file_to);{{eaf1:2a26ae}}  load address
        call    CAS_IN_DIRECT     ;{{eaf4:cd83bc}}  firmware function: cas in direct
        push    hl                ;{{eaf7:e5}}  execution address
        call    c,CAS_IN_CLOSE    ;{{eaf8:dc7abc}}  firmware function: cas in close
        pop     hl                ;{{eafb:e1}}  execution address passed into firmare function "mc boot program"
        ret                       ;{{eafc:c9}} 

;;==========================================================================
;; command CHAIN
command_CHAIN:                    ;{{Addr=$eafd Code Calls/jump count: 0 Data use count: 1}}
        xor     $ab               ;{{eafd:eeab}} 
        ld      (RAM_ae28),a      ;{{eaff:3228ae}} 
        call    z,get_next_token_skipping_space;{{eb02:cc2cde}}  get next token skipping space
        call    read_filename_and_open_for_input;{{eb05:cd54ec}} 
        ld      de,RESET_ENTRY    ;{{eb08:110000}} 
        call    next_token_if_prev_is_comma;{{eb0b:cd41de}} 
        jr      nc,_command_chain_10;{{eb0e:3006}}  (+$06)
        ld      a,(hl)            ;{{eb10:7e}} 
        cp      $2c               ;{{eb11:fe2c}} 
        call    nz,eval_expr_as_uint;{{eb13:c4f5ce}} 
_command_chain_10:                ;{{Addr=$eb16 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{eb16:d5}} 
        call    next_token_if_prev_is_comma;{{eb17:cd41de}} 
        jr      nc,_command_chain_17;{{eb1a:3008}}  (+$08)
        call    next_token_if_equals_inline_data_byte;{{eb1c:cd25de}} 
        defb $92                  ;Inline token to test for "DELETE"
        call    do_DELETE_find_first_line;{{eb20:cd00e8}} 
        scf                       ;{{eb23:37}} 
_command_chain_17:                ;{{Addr=$eb24 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{eb24:f5}} 
        call    syntax_error_if_not_02;{{eb25:cd37de}} 
        call    _function_instr_70;{{eb28:cd4dfb}} 
        call    _function_fre_6   ;{{eb2b:cd64fc}} 
        call    clear_DEFFN_list_and_reset_variable_types_and_pointers;{{eb2e:cd0ed6}} 
        pop     af                ;{{eb31:f1}} 
        call    c,do_DELETE_find_last_line;{{eb32:dc1ae8}} 
        call    _command_chain_34 ;{{eb35:cd47eb}} 
        pop     de                ;{{eb38:d1}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{eb39:2a64ae}} 
        ld      a,d               ;{{eb3c:7a}} 
        or      e                 ;{{eb3d:b3}} 
        ret     z                 ;{{eb3e:c8}} 

        call    zero_current_line_address;{{eb3f:cdaade}} 
        call    find_address_of_line_or_error;{{eb42:cd5ce8}} 
        dec     hl                ;{{eb45:2b}} 
        ret                       ;{{eb46:c9}} 

_command_chain_34:                ;{{Addr=$eb47 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(RAM_ae28)      ;{{eb47:3a28ae}} 
        or      a                 ;{{eb4a:b7}} 
        jp      z,validate_and_MERGE;{{eb4b:ca62ec}} 
        call    _reset_basic_31   ;{{eb4e:cd89c1}} 
        jp      validate_and_LOAD_BASIC;{{eb51:c36dec}} 

;;========================================================================
;; command MERGE

command_MERGE:                    ;{{Addr=$eb54 Code Calls/jump count: 0 Data use count: 1}}
        call    read_filename_and_open_for_input;{{eb54:cd54ec}} 
        call    syntax_error_if_not_02;{{eb57:cd37de}} 
        call    _reset_basic_22   ;{{eb5a:cd78c1}} 
        call    validate_and_MERGE;{{eb5d:cd62ec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eb60:c358c0}} 

;;========================================================================
;;do MERGE
do_MERGE:                         ;{{Addr=$eb63 Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{eb63:cd8fc1}} 
        call    convert_all_line_addresses_to_line_numbers;{{eb66:cd70e7}}  line address to line number
        call    prob_move_vars_and_arrays_to_end_of_memory;{{eb69:cd29f6}} 
        ld      hl,(address_after_end_of_program);{{eb6c:2a66ae}} 
        ex      de,hl             ;{{eb6f:eb}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{eb70:2a64ae}} 
        inc     hl                ;{{eb73:23}} 
        ld      (address_after_end_of_program),hl;{{eb74:2266ae}} 
        ex      de,hl             ;{{eb77:eb}} 
        call    BC_equal_HL_minus_DE;{{eb78:cde4ff}}  BC = HL-DE
        ex      de,hl             ;{{eb7b:eb}} 
        call    get_end_of_free_space_or_start_of_variables;{{eb7c:cd07f7}} 
        ex      de,hl             ;{{eb7f:eb}} 
        dec     hl                ;{{eb80:2b}} 
        lddr                      ;{{eb81:edb8}} 
        inc     de                ;{{eb83:13}} 
        ex      de,hl             ;{{eb84:eb}} 
_do_merge_17:                     ;{{Addr=$eb85 Code Calls/jump count: 1 Data use count: 0}}
        call    _do_merge_142     ;{{eb85:cd4bec}} 
        jr      nc,_do_merge_71   ;{{eb88:304a}}  (+$4a)
        or      e                 ;{{eb8a:b3}} 
        jr      z,_do_merge_73    ;{{eb8b:284c}}  (+$4c)
        push    de                ;{{eb8d:d5}} 
        call    _do_merge_142     ;{{eb8e:cd4bec}} 
        jr      nc,_do_merge_71   ;{{eb91:3041}}  (+$41)
_do_merge_24:                     ;{{Addr=$eb93 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{eb93:7e}} 
        inc     hl                ;{{eb94:23}} 
        or      (hl)              ;{{eb95:b6}} 
        dec     hl                ;{{eb96:2b}} 
        jr      z,_do_merge_49    ;{{eb97:281b}}  (+$1b)
        push    hl                ;{{eb99:e5}} 
        inc     hl                ;{{eb9a:23}} 
        inc     hl                ;{{eb9b:23}} 
        ld      a,(hl)            ;{{eb9c:7e}} 
        inc     hl                ;{{eb9d:23}} 
        ld      h,(hl)            ;{{eb9e:66}} 
        ld      l,a               ;{{eb9f:6f}} 
        call    compare_HL_DE     ;{{eba0:cdd8ff}}  HL=DE?
        pop     hl                ;{{eba3:e1}} 
        jr      z,_do_merge_42    ;{{eba4:2807}}  (+$07)
        jr      nc,_do_merge_49   ;{{eba6:300c}}  (+$0c)
        call    _do_merge_107     ;{{eba8:cd19ec}} 
        jr      _do_merge_24      ;{{ebab:18e6}}  (-$1a)

_do_merge_42:                     ;{{Addr=$ebad Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ebad:d5}} 
        ld      e,(hl)            ;{{ebae:5e}} 
        inc     hl                ;{{ebaf:23}} 
        ld      d,(hl)            ;{{ebb0:56}} 
        dec     hl                ;{{ebb1:2b}} 
        add     hl,de             ;{{ebb2:19}} 
        pop     de                ;{{ebb3:d1}} 
_do_merge_49:                     ;{{Addr=$ebb4 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ebb4:e5}} 
        ld      hl,(address_after_end_of_program);{{ebb5:2a66ae}} 
        inc     hl                ;{{ebb8:23}} 
        inc     hl                ;{{ebb9:23}} 
        ld      (hl),e            ;{{ebba:73}} 
        inc     hl                ;{{ebbb:23}} 
        ld      (hl),d            ;{{ebbc:72}} 
        ld      de,$001d          ;{{ebbd:111d00}} 
        add     hl,de             ;{{ebc0:19}} 
        ex      de,hl             ;{{ebc1:eb}} 
        pop     hl                ;{{ebc2:e1}} 
        ex      (sp),hl           ;{{ebc3:e3}} 
        ex      de,hl             ;{{ebc4:eb}} 
        add     hl,de             ;{{ebc5:19}} 
        ex      de,hl             ;{{ebc6:eb}} 
        ex      (sp),hl           ;{{ebc7:e3}} 
        call    compare_HL_DE     ;{{ebc8:cdd8ff}}  HL=DE?
        jr      c,_do_merge_88    ;{{ebcb:3825}}  (+$25)
        ex      (sp),hl           ;{{ebcd:e3}} 
        call    _do_merge_119     ;{{ebce:cd2cec}} 
        pop     hl                ;{{ebd1:e1}} 
        jr      c,_do_merge_17    ;{{ebd2:38b1}}  (-$4f)
_do_merge_71:                     ;{{Addr=$ebd4 Code Calls/jump count: 2 Data use count: 0}}
        call    _do_merge_73      ;{{ebd4:cdd9eb}} 
        jr      _do_merge_102     ;{{ebd7:1836}}  (+$36)

_do_merge_73:                     ;{{Addr=$ebd9 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{ebd9:7e}} 
        inc     hl                ;{{ebda:23}} 
        or      (hl)              ;{{ebdb:b6}} 
        dec     hl                ;{{ebdc:2b}} 
        jr      z,_do_merge_80    ;{{ebdd:2805}}  (+$05)
        call    _do_merge_107     ;{{ebdf:cd19ec}} 
        jr      _do_merge_73      ;{{ebe2:18f5}}  (-$0b)

_do_merge_80:                     ;{{Addr=$ebe4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_after_end_of_program);{{ebe4:2a66ae}} 
        xor     a                 ;{{ebe7:af}} 
        ld      (hl),a            ;{{ebe8:77}} 
        inc     hl                ;{{ebe9:23}} 
        ld      (hl),a            ;{{ebea:77}} 
        inc     hl                ;{{ebeb:23}} 
        ld      (address_after_end_of_program),hl;{{ebec:2266ae}} 
        jp      _load_tokenised_23;{{ebef:c3b0ec}} 

_do_merge_88:                     ;{{Addr=$ebf2 Code Calls/jump count: 1 Data use count: 0}}
        call    _do_merge_73      ;{{ebf2:cdd9eb}} 
_do_merge_89:                     ;{{Addr=$ebf5 Code Calls/jump count: 1 Data use count: 0}}
        call    zero_current_line_address;{{ebf5:cdaade}} 
        ld      a,$07             ;{{ebf8:3e07}} 
        jr      _do_merge_103     ;{{ebfa:1815}}  (+$15)

_do_merge_92:                     ;{{Addr=$ebfc Code Calls/jump count: 3 Data use count: 0}}
        call    CAS_IN_CHAR       ;{{ebfc:cd80bc}}  firmware function: cas in char
        ret     c                 ;{{ebff:d8}} 

        cp      $1a               ;{{ec00:fe1a}} 
        scf                       ;{{ec02:37}} 
        ret     z                 ;{{ec03:c8}} 

        ld      (DERR__Disc_Error_No),a;{{ec04:3291ad}} 
        ccf                       ;{{ec07:3f}} 
        ret                       ;{{ec08:c9}} 

_do_merge_100:                    ;{{Addr=$ec09 Code Calls/jump count: 1 Data use count: 0}}
        ld      (DERR__Disc_Error_No),a;{{ec09:3291ad}} 
        call    _reset_basic_19   ;{{ec0c:cd6fc1}} 
_do_merge_102:                    ;{{Addr=$ec0f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$18             ;{{ec0f:3e18}} EOF met error
_do_merge_103:                    ;{{Addr=$ec11 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{ec11:f5}} 
        call    close_input_and_output_streams;{{ec12:cd00d3}}  close input and output streams
        pop     af                ;{{ec15:f1}} 
        jp      raise_error       ;{{ec16:c355cb}} 

_do_merge_107:                    ;{{Addr=$ec19 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{ec19:c5}} 
        push    de                ;{{ec1a:d5}} 
        ld      c,(hl)            ;{{ec1b:4e}} 
        inc     hl                ;{{ec1c:23}} 
        ld      b,(hl)            ;{{ec1d:46}} 
        dec     hl                ;{{ec1e:2b}} 
        ld      de,(address_after_end_of_program);{{ec1f:ed5b66ae}} 
        ldir                      ;{{ec23:edb0}} 
        ld      (address_after_end_of_program),de;{{ec25:ed5366ae}} 
        pop     de                ;{{ec29:d1}} 
        pop     bc                ;{{ec2a:c1}} 
        ret                       ;{{ec2b:c9}} 

_do_merge_119:                    ;{{Addr=$ec2c Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ec2c:eb}} 
        ld      hl,(address_after_end_of_program);{{ec2d:2a66ae}} 
        ld      (hl),e            ;{{ec30:73}} 
        inc     hl                ;{{ec31:23}} 
        ld      (hl),d            ;{{ec32:72}} 
        inc     hl                ;{{ec33:23}} 
        inc     hl                ;{{ec34:23}} 
        inc     hl                ;{{ec35:23}} 
        dec     de                ;{{ec36:1b}} 
        dec     de                ;{{ec37:1b}} 
        dec     de                ;{{ec38:1b}} 
_do_merge_130:                    ;{{Addr=$ec39 Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{ec39:1b}} 
        ld      a,d               ;{{ec3a:7a}} 
        or      e                 ;{{ec3b:b3}} 
        jr      z,_do_merge_139   ;{{ec3c:2808}}  (+$08)
        call    _do_merge_92      ;{{ec3e:cdfceb}} 
        ld      (hl),a            ;{{ec41:77}} 
        inc     hl                ;{{ec42:23}} 
        jr      c,_do_merge_130   ;{{ec43:38f4}}  (-$0c)
        ret                       ;{{ec45:c9}} 

_do_merge_139:                    ;{{Addr=$ec46 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_after_end_of_program),hl;{{ec46:2266ae}} 
        scf                       ;{{ec49:37}} 
        ret                       ;{{ec4a:c9}} 

_do_merge_142:                    ;{{Addr=$ec4b Code Calls/jump count: 2 Data use count: 0}}
        call    _do_merge_92      ;{{ec4b:cdfceb}} 
        ld      e,a               ;{{ec4e:5f}} 
        call    c,_do_merge_92    ;{{ec4f:dcfceb}} 
        ld      d,a               ;{{ec52:57}} 
        ret                       ;{{ec53:c9}} 

;;=read filename and open for input
read_filename_and_open_for_input: ;{{Addr=$ec54 Code Calls/jump count: 3 Data use count: 0}}
        call    close_input_and_output_streams;{{ec54:cd00d3}}  close input and output streams
        call    read_filename_and_open_in;{{ec57:cdbed2}} 
        ld      (file_type_from_cassette_header),a;{{ec5a:3229ae}} 
        ld      (file_length_from_cassette_header),bc;{{ec5d:ed432aae}} 
        ret                       ;{{ec61:c9}} 

;;=========
;;=validate and MERGE
validate_and_MERGE:               ;{{Addr=$ec62 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(file_type_from_cassette_header);{{ec62:3a29ae}} 
        or      a                 ;{{ec65:b7}} 
        jp      z,do_MERGE        ;{{ec66:ca63eb}} Type 0 = tokenised, unprotected
        cp      $16               ;{{ec69:fe16}} 
        jr      nz,raise_File_type_error;{{ec6b:200b}}  (+$0b)
;;=validate and LOAD BASIC
validate_and_LOAD_BASIC:          ;{{Addr=$ec6d Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(file_type_from_cassette_header);{{ec6d:3a29ae}} 
        cp      $16               ;{{ec70:fe16}} 
        jr      z,load_ASCII      ;{{ec72:2842}}  (+$42)
        and     $fe               ;{{ec74:e6fe}} Bit 0 set = protected
        jr      z,load_tokenised  ;{{ec76:2804}}  (+$04)
;;=raise File type error
raise_File_type_error:            ;{{Addr=$ec78 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{ec78:cd45cb}} 
        defb $19                  ;Inline error code: File type error

;;===
;;=load tokenised
load_tokenised:                   ;{{Addr=$ec7c Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{ec7c:cd8fc1}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ec7f:cd29f6}} 
        ld      bc,(address_of_end_of_ROM_lower_reserved_are);{{ec82:ed4b64ae}} 
        inc     bc                ;{{ec86:03}} 
        call    get_end_of_free_space_or_start_of_variables;{{ec87:cd07f7}} 
        ld      de,$ff80          ;{{ec8a:1180ff}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{ec8d:19}} 
        or      a                 ;{{ec8e:b7}} 
        sbc     hl,bc             ;{{ec8f:ed42}} 
        ld      de,(file_length_from_cassette_header);{{ec91:ed5b2aae}} 
        call    nc,compare_HL_DE  ;{{ec95:d4d8ff}}  HL=DE?
        jp      c,_do_merge_89    ;{{ec98:daf5eb}} 
        ex      de,hl             ;{{ec9b:eb}} 
        add     hl,bc             ;{{ec9c:09}} 
        ld      (address_after_end_of_program),hl;{{ec9d:2266ae}} 
        ld      a,(file_type_from_cassette_header);{{eca0:3a29ae}} 
        rra                       ;{{eca3:1f}} 
        sbc     a,a               ;{{eca4:9f}} 
        ld      (program_protection_flag_),a;{{eca5:322cae}} 
        ld      h,b               ;{{eca8:60}} 
        ld      l,c               ;{{eca9:69}} 
        call    CAS_IN_DIRECT     ;{{ecaa:cd83bc}}  firmware function: CAS IN DIRECT
        jp      z,_do_merge_100   ;{{ecad:ca09ec}} 
_load_tokenised_23:               ;{{Addr=$ecb0 Code Calls/jump count: 2 Data use count: 0}}
        call    prob_move_vars_and_arrays_back_from_end_of_memory;{{ecb0:cd3cf6}} 
        jp      command_CLOSEIN   ;{{ecb3:c3edd2}}  CLOSEIN

;;=load ASCII
load_ASCII:                       ;{{Addr=$ecb6 Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{ecb6:cd8fc1}} 
        call    zero_current_line_address;{{ecb9:cdaade}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ecbc:cd29f6}} 
_load_ascii_3:                    ;{{Addr=$ecbf Code Calls/jump count: 1 Data use count: 0}}
        call    read_line_from_cassette_or_disc;{{ecbf:cd0acb}} 
        jr      nc,_load_tokenised_23;{{ecc2:30ec}}  (-$14)
        call    skip_space_tab_or_line_feed;{{ecc4:cd4dde}}  skip space, lf or tab
        or      a                 ;{{ecc7:b7}} 
        call    nz,_load_ascii_9  ;{{ecc8:c4cdec}} 
        jr      _load_ascii_3     ;{{eccb:18f2}}  (-$0e)

_load_ascii_9:                    ;{{Addr=$eccd Code Calls/jump count: 1 Data use count: 0}}
        call    convert_number_a  ;{{eccd:cdcfee}} 
        jp      c,_convert_line_addresses_to_line_numbers_24;{{ecd0:daa5e7}} 
        ld      a,$15             ;{{ecd3:3e15}} 
        jr      z,_load_ascii_14  ;{{ecd5:2802}}  (+$02)
        ld      a,$06             ;{{ecd7:3e06}} Overflow error
_load_ascii_14:                   ;{{Addr=$ecd9 Code Calls/jump count: 1 Data use count: 0}}
        jp      raise_error       ;{{ecd9:c355cb}} 

;;========================================================================
;; command SAVE

command_SAVE:                     ;{{Addr=$ecdc Code Calls/jump count: 0 Data use count: 1}}
        call    close_input_and_output_streams;{{ecdc:cd00d3}} ; close input and output streams
        call    command_OPENOUT   ;{{ecdf:cda8d2}} ; OPENOUT
        ld      b,$00             ;{{ece2:0600}} 
        call    next_token_if_prev_is_comma;{{ece4:cd41de}} 
        jr      nc,save_BASIC_normal;{{ece7:3025}}  (+$25)
        call    next_token_if_equals_inline_data_byte;{{ece9:cd25de}}  read string
        defb $0d                  ;inline token to test CR
        inc     hl                ;{{eced:23}} 
        inc     hl                ;{{ecee:23}} 
        ld      a,(hl)            ;{{ecef:7e}}  parameter (,A ,B ,P)
        and     $df               ;{{ecf0:e6df}} 
        jp      p,Error_Syntax_Error;{{ecf2:f249cb}}  Error: Syntax Error
        push    hl                ;{{ecf5:e5}} 
        ld      hl,save_parameters_list;{{ecf6:2100ed}} 
        call    get_address_from_table;{{ecf9:cdb4ff}} 
        ex      (sp),hl           ;{{ecfc:e3}} 
        jp      get_next_token_skipping_space;{{ecfd:c32cde}}  get next token skipping space

;;=save parameters list
save_parameters_list:             ;{{Addr=$ed00 Data Calls/jump count: 0 Data use count: 1}}
        defb $03                  ;Number of parameter options
        defw Error_Syntax_Error   ; Error if not found: Syntax Error   ##LABEL##

        defb $c1                  ; ,A
        defw ASCII_save           ;  ##LABEL##
        defb $c2                  ; ,B
        defw Binary_save          ;  ##LABEL##
        defb $d0                  ; ,P
        defw Protected_BASIC_save ;  ##LABEL##

;;---------------------------------------------------
;; SAVE ,P
;;=Protected BASIC save
Protected_BASIC_save:             ;{{Addr=$ed0c Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$01             ;{{ed0c:0601}} 
;;=save BASIC normal
save_BASIC_normal:                ;{{Addr=$ed0e Code Calls/jump count: 1 Data use count: 0}}
        call    syntax_error_if_not_02;{{ed0e:cd37de}} 
        push hl                   ;{{ed11:e5}} 
        push    bc                ;{{ed12:c5}} 
        call    convert_all_line_addresses_to_line_numbers;{{ed13:cd70e7}}  line address to line number
        call    reset_variable_types_and_pointers;{{ed16:cd4dea}} 
;; save basic?
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ed19:2a64ae}} 
        inc     hl                ;{{ed1c:23}} 
        ex      de,hl             ;{{ed1d:eb}} 
        ld      hl,(address_after_end_of_program);{{ed1e:2a66ae}} 
        or      a                 ;{{ed21:b7}} 
        sbc     hl,de             ;{{ed22:ed52}} 
        ex      de,hl             ;{{ed24:eb}} 
        pop     af                ;{{ed25:f1}} 
        ld      bc,RESET_ENTRY    ;{{ed26:010000}} 
        jr      _binary_save_15   ;{{ed29:1820}}  (+$20)

;; SAVE ,B
;;=Binary save
Binary_save:                      ;{{Addr=$ed2b Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_comma;{{ed2b:cd15de}}  check for comma			; start
        call    eval_expr_as_uint ;{{ed2e:cdf5ce}} 
        push    de                ;{{ed31:d5}} 
        call    next_token_if_comma;{{ed32:cd15de}}  check for comma			; length
        call    eval_expr_as_uint ;{{ed35:cdf5ce}} 
        push    de                ;{{ed38:d5}} 
        call    next_token_if_prev_is_comma;{{ed39:cd41de}}  execution
        ld      de,RESET_ENTRY    ;{{ed3c:110000}} 
        call    c,eval_expr_as_uint;{{ed3f:dcf5ce}} 
        push    de                ;{{ed42:d5}} 
        call    syntax_error_if_not_02;{{ed43:cd37de}} 
        ld      a,$02             ;{{ed46:3e02}} ; binary
        pop     bc                ;{{ed48:c1}} 
        pop     de                ;{{ed49:d1}} 
        ex      (sp),hl           ;{{ed4a:e3}} 
_binary_save_15:                  ;{{Addr=$ed4b Code Calls/jump count: 1 Data use count: 0}}
        call    CAS_OUT_DIRECT    ;{{ed4b:cd98bc}} ; firmware function: cas out direct
        jp      nc,raise_file_not_open_error_C;{{ed4e:d237cc}} 
        jr      _ascii_save_10    ;{{ed51:1817}}  (+$17)

;; SAVE ,A
;;=ASCII save
ASCII_save:                       ;{{Addr=$ed53 Code Calls/jump count: 0 Data use count: 1}}
        call    syntax_error_if_not_02;{{ed53:cd37de}} 
        push    hl                ;{{ed56:e5}} 
        ld      a,$09             ;{{ed57:3e09}} 
        call    select_txt_stream ;{{ed59:cda6c1}} 
        push    af                ;{{ed5c:f5}} 
        ld      bc,$0001          ;{{ed5d:010100}} starting line number
        ld      de,$ffff          ;{{ed60:11ffff}} ending line number ##LIT##;WARNING: Code area used as literal
        call    do_LIST           ;{{ed63:cde3e1}} 
        pop     af                ;{{ed66:f1}} 
        call    select_txt_stream ;{{ed67:cda6c1}} 
_ascii_save_10:                   ;{{Addr=$ed6a Code Calls/jump count: 1 Data use count: 0}}
        call    command_CLOSEOUT  ;{{ed6a:cdf5d2}}  CLOSEOUT
        pop     hl                ;{{ed6d:e1}} 
        ret                       ;{{ed6e:c9}} 





;;***StringsToNumbers.asm
;;<< STRINGS TO NUMBERS
;;==============================
;;possibly validate input buffer is a number

possibly_validate_input_buffer_is_a_number:;{{Addr=$ed6f Code Calls/jump count: 3 Data use count: 0}}
        call    _possibly_validate_input_buffer_is_a_number_87;{{ed6f:cd0fee}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_4;{{ed72:2005}}  (+$05)
        call    skip_space_tab_or_line_feed;{{ed74:cd4dde}}  skip space, lf or tab
        jr      _possibly_validate_input_buffer_is_a_number_31;{{ed77:182f}}  (+$2f)

_possibly_validate_input_buffer_is_a_number_4:;{{Addr=$ed79 Code Calls/jump count: 1 Data use count: 0}}
        cp      $26               ;{{ed79:fe26}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_22;{{ed7b:281c}}  (+$1c)
        call    test_if_period_or_digit;{{ed7d:cda0ff}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_31;{{ed80:3826}}  (+$26)
        call    set_accumulator_type_to_int;{{ed82:cd38ff}} 
        call    zero_accumulator  ;{{ed85:cd1bff}} 
        scf                       ;{{ed88:37}} 
        ret                       ;{{ed89:c9}} 

_possibly_validate_input_buffer_is_a_number_12:;{{Addr=$ed8a Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ed8a:e5}} 
        call    _possibly_validate_input_buffer_is_a_number_18;{{ed8b:cd92ed}} 
        pop     de                ;{{ed8e:d1}} 
        ret     c                 ;{{ed8f:d8}} 

        ex      de,hl             ;{{ed90:eb}} 
        ret                       ;{{ed91:c9}} 

_possibly_validate_input_buffer_is_a_number_18:;{{Addr=$ed92 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,$00             ;{{ed92:1600}} 
        ld      a,(hl)            ;{{ed94:7e}} 
        cp      $26               ;{{ed95:fe26}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_31;{{ed97:200f}}  (+$0f)
_possibly_validate_input_buffer_is_a_number_22:;{{Addr=$ed99 Code Calls/jump count: 1 Data use count: 0}}
        call    convert_number_b  ;{{ed99:cde7ee}} 
        ex      de,hl             ;{{ed9c:eb}} 
        push    af                ;{{ed9d:f5}} 
        call    store_HL_in_accumulator_as_INT;{{ed9e:cd35ff}} 
        pop     af                ;{{eda1:f1}} 
        ex      de,hl             ;{{eda2:eb}} 
        ret     c                 ;{{eda3:d8}} 

        ret     z                 ;{{eda4:c8}} 

        jp      overflow_error    ;{{eda5:c3becb}} 

_possibly_validate_input_buffer_is_a_number_31:;{{Addr=$eda8 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{eda8:e5}} 
        ld      a,(hl)            ;{{eda9:7e}} 
        inc     hl                ;{{edaa:23}} 
        cp      $2e               ;{{edab:fe2e}} 
        call    z,skip_space_tab_or_line_feed;{{edad:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{edb0:cda4ff}} ; test if ASCII character represents a decimal number digit
        pop     hl                ;{{edb3:e1}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_44;{{edb4:3806}}  (+$06)
        ld      a,(hl)            ;{{edb6:7e}} 
        xor     $2e               ;{{edb7:ee2e}} 
        ret     nz                ;{{edb9:c0}} 

        inc     hl                ;{{edba:23}} 
        ret                       ;{{edbb:c9}} 

_possibly_validate_input_buffer_is_a_number_44:;{{Addr=$edbc Code Calls/jump count: 1 Data use count: 0}}
        call    set_accumulator_type_to_int;{{edbc:cd38ff}} 
        push    de                ;{{edbf:d5}} 
        ld      bc,RESET_ENTRY    ;{{edc0:010000}} 
        ld      de,buffer_used_to_form_binary_or_hexadecima;{{edc3:112dae}} 
        call    _possibly_validate_input_buffer_is_a_number_97;{{edc6:cd1eee}} 
        cp      $2e               ;{{edc9:fe2e}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_56;{{edcb:200b}}  (+$0b)
        call    _possibly_validate_input_buffer_is_a_number_170;{{edcd:cd94ee}} 
        call    set_accumulator_type_to_real;{{edd0:cd41ff}} 
        inc     c                 ;{{edd3:0c}} 
        call    _possibly_validate_input_buffer_is_a_number_97;{{edd4:cd1eee}} 
        dec     c                 ;{{edd7:0d}} 
_possibly_validate_input_buffer_is_a_number_56:;{{Addr=$edd8 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{edd8:eb}} 
        ld      (hl),$ff          ;{{edd9:36ff}} 
        ex      de,hl             ;{{eddb:eb}} 
        call    _possibly_validate_input_buffer_is_a_number_120;{{eddc:cd42ee}} 
        pop     de                ;{{eddf:d1}} 
        ld      e,a               ;{{ede0:5f}} 
        push    hl                ;{{ede1:e5}} 
        push    de                ;{{ede2:d5}} 
        ld      hl,buffer_used_to_form_binary_or_hexadecima;{{ede3:212dae}} 
        call    _possibly_validate_input_buffer_is_a_number_173;{{ede6:cd99ee}} 
        pop     de                ;{{ede9:d1}} 
        call    is_accumulator_a_string;{{edea:cd66ff}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_74;{{eded:3008}}  (+$08)
        push    hl                ;{{edef:e5}} 
        ld      b,d               ;{{edf0:42}} 
        call    _function_int_11  ;{{edf1:cd2cfe}} 
        pop     hl                ;{{edf4:e1}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_83;{{edf5:3811}}  (+$11)
_possibly_validate_input_buffer_is_a_number_74:;{{Addr=$edf7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{edf7:7a}} 
        ld      c,(hl)            ;{{edf8:4e}} 
        inc     hl                ;{{edf9:23}} 
        call    REAL_5byte_to_real;{{edfa:cdb8bd}} 
        ld      a,e               ;{{edfd:7b}} 
        call    REAL_10A          ;{{edfe:cd79bd}} 
        ex      de,hl             ;{{ee01:eb}} 
        call    set_accumulator_type_to_real_and_HL_to_accumulator_addr;{{ee02:cd3eff}} 
        call    c,REAL_copy_atDE_to_atHL;{{ee05:dc61bd}} 
_possibly_validate_input_buffer_is_a_number_83:;{{Addr=$ee08 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0a             ;{{ee08:3e0a}} 
        pop     hl                ;{{ee0a:e1}} 
        ret     c                 ;{{ee0b:d8}} 

        jp      overflow_error    ;{{ee0c:c3becb}} 

_possibly_validate_input_buffer_is_a_number_87:;{{Addr=$ee0f Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee0f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee12:23}} 
        ld      d,$ff             ;{{ee13:16ff}} 
        cp      $2d               ;{{ee15:fe2d}} '-'
        ret     z                 ;{{ee17:c8}} 

        inc     d                 ;{{ee18:14}} 
        cp      $2b               ;{{ee19:fe2b}} 
        ret     z                 ;{{ee1b:c8}} 

        dec     hl                ;{{ee1c:2b}} 
        ret                       ;{{ee1d:c9}} 

_possibly_validate_input_buffer_is_a_number_97:;{{Addr=$ee1e Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{ee1e:e5}} 
        call    skip_space_tab_or_line_feed;{{ee1f:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee22:23}} 
        call    test_if_digit     ;{{ee23:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_possibly_validate_input_buffer_is_a_number_104;{{ee26:3804}}  (+$04)
        pop     hl                ;{{ee28:e1}} 
        jp      convert_character_to_upper_case;{{ee29:c3abff}} ; convert character to upper case

_possibly_validate_input_buffer_is_a_number_104:;{{Addr=$ee2c Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee2c:e3}} 
        pop     hl                ;{{ee2d:e1}} 
        sub     $30               ;{{ee2e:d630}} 
        ld      (de),a            ;{{ee30:12}} 
        or      b                 ;{{ee31:b0}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_115;{{ee32:2807}}  (+$07)
        ld      a,b               ;{{ee34:78}} 
        inc     b                 ;{{ee35:04}} 
        cp      $0c               ;{{ee36:fe0c}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_115;{{ee38:3001}}  (+$01)
        inc     de                ;{{ee3a:13}} 
_possibly_validate_input_buffer_is_a_number_115:;{{Addr=$ee3b Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{ee3b:79}} 
        or      a                 ;{{ee3c:b7}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_97;{{ee3d:28df}}  (-$21)
        inc     c                 ;{{ee3f:0c}} 
        jr      _possibly_validate_input_buffer_is_a_number_97;{{ee40:18dc}} 

_possibly_validate_input_buffer_is_a_number_120:;{{Addr=$ee42 Code Calls/jump count: 1 Data use count: 0}}
        cp      $45               ;{{ee42:fe45}} ; 'E'
        jr      nz,_possibly_validate_input_buffer_is_a_number_129;{{ee44:2010}} 
         
        push    hl                ;{{ee46:e5}} 
        call    _possibly_validate_input_buffer_is_a_number_170;{{ee47:cd94ee}} 
        call    _possibly_validate_input_buffer_is_a_number_87;{{ee4a:cd0fee}} 
        call    z,skip_space_tab_or_line_feed;{{ee4d:cc4dde}}  skip space, lf or tab
        call    test_if_digit     ;{{ee50:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_possibly_validate_input_buffer_is_a_number_131;{{ee53:3804}}  (+$04)
        pop     hl                ;{{ee55:e1}} 

_possibly_validate_input_buffer_is_a_number_129:;{{Addr=$ee56 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{ee56:af}} 
        jr      _possibly_validate_input_buffer_is_a_number_151;{{ee57:181e}}  (+$1e)

_possibly_validate_input_buffer_is_a_number_131:;{{Addr=$ee59 Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{ee59:e3}} 
        pop     hl                ;{{ee5a:e1}} 
        call    set_accumulator_type_to_real;{{ee5b:cd41ff}} 
        push    de                ;{{ee5e:d5}} 
        push    bc                ;{{ee5f:c5}} 
        call    convert_number_in_base_defined;{{ee60:cd00ef}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_144;{{ee63:3009}}  (+$09)
        ld      a,e               ;{{ee65:7b}} 
        sub     $64               ;{{ee66:d664}} 
        ld      a,d               ;{{ee68:7a}} 
        sbc     a,$00             ;{{ee69:de00}} 
        ld      a,e               ;{{ee6b:7b}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_145;{{ee6c:3802}}  (+$02)
_possibly_validate_input_buffer_is_a_number_144:;{{Addr=$ee6e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$7f             ;{{ee6e:3e7f}} 
_possibly_validate_input_buffer_is_a_number_145:;{{Addr=$ee70 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{ee70:c1}} 
        pop     de                ;{{ee71:d1}} 
        inc     d                 ;{{ee72:14}} 
        jr      nz,_possibly_validate_input_buffer_is_a_number_151;{{ee73:2002}}  (+$02)
        cpl                       ;{{ee75:2f}} 
        inc     a                 ;{{ee76:3c}} 

_possibly_validate_input_buffer_is_a_number_151:;{{Addr=$ee77 Code Calls/jump count: 2 Data use count: 0}}
        add     a,$80             ;{{ee77:c680}} 
        ld      e,a               ;{{ee79:5f}} 
        ld      a,b               ;{{ee7a:78}} 
        sub     $0c               ;{{ee7b:d60c}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_157;{{ee7d:3001}}  (+$01)
        xor     a                 ;{{ee7f:af}} 
_possibly_validate_input_buffer_is_a_number_157:;{{Addr=$ee80 Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{ee80:91}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_165;{{ee81:3009}}  (+$09)
        add     a,e               ;{{ee83:83}} 
        jr      c,_possibly_validate_input_buffer_is_a_number_162;{{ee84:3801}}  (+$01)
        xor     a                 ;{{ee86:af}} 
_possibly_validate_input_buffer_is_a_number_162:;{{Addr=$ee87 Code Calls/jump count: 1 Data use count: 0}}
        cp      $01               ;{{ee87:fe01}} 
        adc     a,$80             ;{{ee89:ce80}} 
        ret                       ;{{ee8b:c9}} 

_possibly_validate_input_buffer_is_a_number_165:;{{Addr=$ee8c Code Calls/jump count: 1 Data use count: 0}}
        add     a,e               ;{{ee8c:83}} 
        jr      nc,_possibly_validate_input_buffer_is_a_number_168;{{ee8d:3002}}  (+$02)
        ld      a,$ff             ;{{ee8f:3eff}} 
_possibly_validate_input_buffer_is_a_number_168:;{{Addr=$ee91 Code Calls/jump count: 1 Data use count: 0}}
        sub     $80               ;{{ee91:d680}} 
        ret                       ;{{ee93:c9}} 

_possibly_validate_input_buffer_is_a_number_170:;{{Addr=$ee94 Code Calls/jump count: 2 Data use count: 0}}
        call    skip_space_tab_or_line_feed;{{ee94:cd4dde}}  skip space, lf or tab
        inc     hl                ;{{ee97:23}} 
        ret                       ;{{ee98:c9}} 

_possibly_validate_input_buffer_is_a_number_173:;{{Addr=$ee99 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ee99:eb}} 
        ld      hl,$ae3f          ;{{ee9a:213fae}} 
        ld      bc,$0501          ;{{ee9d:010105}} 
_possibly_validate_input_buffer_is_a_number_176:;{{Addr=$eea0 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{eea0:2b}} 
        ld      (hl),$00          ;{{eea1:3600}} 
        djnz    _possibly_validate_input_buffer_is_a_number_176;{{eea3:10fb}}  (-$05)
        ld      a,(de)            ;{{eea5:1a}} 
        cp      $ff               ;{{eea6:feff}} 
        ret     z                 ;{{eea8:c8}} 

        ld      (hl),a            ;{{eea9:77}} 
_possibly_validate_input_buffer_is_a_number_183:;{{Addr=$eeaa Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,start_of_buffer_used_to_form_hexadecimal;{{eeaa:213aae}} 
        inc     de                ;{{eead:13}} 
        ld      a,(de)            ;{{eeae:1a}} 
        cp      $ff               ;{{eeaf:feff}} 
        ret     z                 ;{{eeb1:c8}} 

        push    de                ;{{eeb2:d5}} 
        ld      b,c               ;{{eeb3:41}} 
        ld      d,$00             ;{{eeb4:1600}} 
_possibly_validate_input_buffer_is_a_number_191:;{{Addr=$eeb6 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{eeb6:e5}} 
        ld      e,(hl)            ;{{eeb7:5e}} 
        ld      h,d               ;{{eeb8:62}} 
        ld      l,e               ;{{eeb9:6b}} 
        add     hl,hl             ;{{eeba:29}} 
        add     hl,hl             ;{{eebb:29}} 
        add     hl,de             ;{{eebc:19}} 
        add     hl,hl             ;{{eebd:29}} 
        ld      e,a               ;{{eebe:5f}} 
        add     hl,de             ;{{eebf:19}} 
        ld      e,l               ;{{eec0:5d}} 
        ld      a,h               ;{{eec1:7c}} 
        pop     hl                ;{{eec2:e1}} 
        ld      (hl),e            ;{{eec3:73}} 
        inc     hl                ;{{eec4:23}} 
        djnz    _possibly_validate_input_buffer_is_a_number_191;{{eec5:10ef}}  (-$11)
        pop     de                ;{{eec7:d1}} 
        or      a                 ;{{eec8:b7}} 
        jr      z,_possibly_validate_input_buffer_is_a_number_183;{{eec9:28df}}  (-$21)
        ld      (hl),a            ;{{eecb:77}} 
        inc     c                 ;{{eecc:0c}} 
        jr      _possibly_validate_input_buffer_is_a_number_183;{{eecd:18db}}  (-$25)





;;***NumbersToStrings.asm
;;<< NUMBERS TO STRINGS
;;=======================================================================
;;convert number a
convert_number_a:                 ;{{Addr=$eecf Code Calls/jump count: 4 Data use count: 0}}
        push    bc                ;{{eecf:c5}} 
        push    hl                ;{{eed0:e5}} 
        call    convert_number_in_base_defined;{{eed1:cd00ef}} 
        ex      de,hl             ;{{eed4:eb}} 
        call    store_HL_in_accumulator_as_INT;{{eed5:cd35ff}} 
        ex      de,hl             ;{{eed8:eb}} 
        pop     bc                ;{{eed9:c1}} 
        jr      nc,_convert_number_a_12;{{eeda:3006}}  (+$06)
        ld      a,d               ;{{eedc:7a}} 
        or      e                 ;{{eedd:b3}} 
        add     a,$ff             ;{{eede:c6ff}} 
        jr      c,_convert_number_a_15;{{eee0:3803}}  (+$03)
_convert_number_a_12:             ;{{Addr=$eee2 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,b               ;{{eee2:50}} 
        ld      e,c               ;{{eee3:59}} 
        ex      de,hl             ;{{eee4:eb}} 
_convert_number_a_15:             ;{{Addr=$eee5 Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{eee5:c1}} 
        ret                       ;{{eee6:c9}} 


;;=======================================================================
;; convert number b
convert_number_b:                 ;{{Addr=$eee7 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eee7:23}} 
        call    skip_space_tab_or_line_feed;{{eee8:cd4dde}}  skip space, lf or tab
        call    convert_character_to_upper_case;{{eeeb:cdabff}} ; convert character to upper case

        ld      b,$02             ;{{eeee:0602}} ; base 2
        cp      $58               ;{{eef0:fe58}} ; X
        jr      z,_convert_number_b_9;{{eef2:2806}} 

        ld      b,$10             ;{{eef4:0610}} ; base 16
        cp      $48               ;{{eef6:fe48}} ; H
        jr      nz,_convert_number_b_11;{{eef8:2004}} 

_convert_number_b_9:              ;{{Addr=$eefa Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{eefa:23}} 
        call    skip_space_tab_or_line_feed;{{eefb:cd4dde}}  skip space, lf or tab
_convert_number_b_11:             ;{{Addr=$eefe Code Calls/jump count: 1 Data use count: 0}}
        jr      _convert_number_in_base_defined_1;{{eefe:1802}}  (+$02)

;;=======================================================================
;; convert number in base defined
convert_number_in_base_defined:   ;{{Addr=$ef00 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$0a             ;{{ef00:060a}} ; base 10

;; A = base: 2 for binary, 16 for hexadecimal, 10 for decimal

_convert_number_in_base_defined_1:;{{Addr=$ef02 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef02:eb}} 
        call    _convert_number_in_base_defined_27;{{ef03:cd2cef}} 
        ld      h,$00             ;{{ef06:2600}} 
        ld      l,a               ;{{ef08:6f}} 
        jr      nc,_convert_number_in_base_defined_24;{{ef09:301e}}  (+$1e)
        ld      c,$00             ;{{ef0b:0e00}} 
_convert_number_in_base_defined_7:;{{Addr=$ef0d Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_in_base_defined_27;{{ef0d:cd2cef}} 
        jr      nc,_convert_number_in_base_defined_22;{{ef10:3014}}  (+$14)
        push    de                ;{{ef12:d5}} 
        ld      d,$00             ;{{ef13:1600}} 
        ld      e,a               ;{{ef15:5f}} 
        push    de                ;{{ef16:d5}} 
        ld      e,b               ;{{ef17:58}} 
        call    do_16x16_multiply_with_overflow;{{ef18:cd72dd}} 
        pop     de                ;{{ef1b:d1}} 
        jr      c,_convert_number_in_base_defined_19;{{ef1c:3803}}  (+$03)
        add     hl,de             ;{{ef1e:19}} 
        jr      nc,_convert_number_in_base_defined_20;{{ef1f:3002}}  (+$02)
_convert_number_in_base_defined_19:;{{Addr=$ef21 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,$ff             ;{{ef21:0eff}} 
_convert_number_in_base_defined_20:;{{Addr=$ef23 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{ef23:d1}} 
        jr      _convert_number_in_base_defined_7;{{ef24:18e7}}  (-$19)

_convert_number_in_base_defined_22:;{{Addr=$ef26 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{ef26:79}} 
        cp      $01               ;{{ef27:fe01}} 
_convert_number_in_base_defined_24:;{{Addr=$ef29 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ef29:eb}} 
        ld      a,b               ;{{ef2a:78}} 
        ret                       ;{{ef2b:c9}} 

_convert_number_in_base_defined_27:;{{Addr=$ef2c Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{ef2c:1a}} 
        inc     de                ;{{ef2d:13}} 
        call    test_if_digit     ;{{ef2e:cda4ff}} ; test if ASCII character represents a decimal number digit
        jr      c,_convert_number_in_base_defined_36;{{ef31:380a}}  (+$0a)
        call    convert_character_to_upper_case;{{ef33:cdabff}} ; convert character to upper case
        cp      $41               ;{{ef36:fe41}} 
        ccf                       ;{{ef38:3f}} 
        jr      nc,_convert_number_in_base_defined_38;{{ef39:3005}}  (+$05)
        sub     $07               ;{{ef3b:d607}} 
_convert_number_in_base_defined_36:;{{Addr=$ef3d Code Calls/jump count: 1 Data use count: 0}}
        sub     $30               ;{{ef3d:d630}} 
        cp      b                 ;{{ef3f:b8}} 
_convert_number_in_base_defined_38:;{{Addr=$ef40 Code Calls/jump count: 1 Data use count: 0}}
        ret     c                 ;{{ef40:d8}} 

        dec     de                ;{{ef41:1b}} 
        xor     a                 ;{{ef42:af}} 
        ret                       ;{{ef43:c9}} 

;;============================================
;;display decimal number
display_decimal_number:           ;{{Addr=$ef44 Code Calls/jump count: 2 Data use count: 0}}
        call    convert_int_to_string;{{ef44:cd4aef}} 
        jp      output_ASCIIZ_string;{{ef47:c38bc3}} ; display 0 terminated string

;;=convert int to string
convert_int_to_string:            ;{{Addr=$ef4a Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{ef4a:d5}} 
        push    bc                ;{{ef4b:c5}} 
        call    store_HL_in_accumulator_as_INT;{{ef4c:cd35ff}} 
        call    _poss_free_string_at_bc_length_a_18;{{ef4f:cd03fd}} 
        xor     a                 ;{{ef52:af}} 
        call    _convert_number_to_string_by_format_4;{{ef53:cd72ef}} 
        inc     hl                ;{{ef56:23}} 
        pop     bc                ;{{ef57:c1}} 
        pop     de                ;{{ef58:d1}} 
        ret                       ;{{ef59:c9}} 

;;=convert float atHL to string
convert_float_atHL_to_string:     ;{{Addr=$ef5a Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{ef5a:d5}} 
        push    bc                ;{{ef5b:c5}} 
        xor     a                 ;{{ef5c:af}} 
        call    convert_number_to_string_by_format;{{ef5d:cd6aef}} 
        pop     bc                ;{{ef60:c1}} 
        pop     de                ;{{ef61:d1}} 
        ld      a,(hl)            ;{{ef62:7e}} 
        cp      $20               ;{{ef63:fe20}} ; ' '
        ret     nz                ;{{ef65:c0}} 

        inc     hl                ;{{ef66:23}} 
        ret                       ;{{ef67:c9}} 

;;==================================
;;prob eval number to decimal string
prob_eval_number_to_decimal_string:;{{Addr=$ef68 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$40             ;{{ef68:3e40}} '@' - Decimal specifier
;;=convert number to string by format
;Format is one of + - $ £ * # , . ^
convert_number_to_string_by_format:;{{Addr=$ef6a Code Calls/jump count: 3 Data use count: 0}}
        ld      (RAM_ae52),hl     ;{{ef6a:2252ae}} 
        push    af                ;{{ef6d:f5}} 
        call    _poss_free_string_at_bc_length_a_12;{{ef6e:cdf3fc}} 
        pop     af                ;{{ef71:f1}} 
_convert_number_to_string_by_format_4:;{{Addr=$ef72 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{ef72:c5}} 
        ld      d,a               ;{{ef73:57}} 
        push    de                ;{{ef74:d5}} 
        call    _convert_number_to_string_by_format_357;{{ef75:cd8af1}} 
        pop     de                ;{{ef78:d1}} 
        call    _convert_number_to_string_by_format_25;{{ef79:cd96ef}} 
        call    _convert_number_to_string_by_format_285;{{ef7c:cd1af1}} 
        pop     af                ;{{ef7f:f1}} 
        ld      e,a               ;{{ef80:5f}} 
        ld      a,b               ;{{ef81:78}} 
        or      a                 ;{{ef82:b7}} 
        call    z,_convert_number_to_string_by_format_297;{{ef83:cc2cf1}} 
        call    _convert_number_to_string_by_format_314;{{ef86:cd45f1}} 
        call    _convert_number_to_string_by_format_321;{{ef89:cd4ff1}} 
        call    _convert_number_to_string_by_format_339;{{ef8c:cd6ff1}} 
        ld      a,d               ;{{ef8f:7a}} 
        rra                       ;{{ef90:1f}} 
        ret     nc                ;{{ef91:d0}} 

        dec     hl                ;{{ef92:2b}} 
        ld      (hl),$25          ;{{ef93:3625}} '%'
        ret                       ;{{ef95:c9}} 

_convert_number_to_string_by_format_25:;{{Addr=$ef96 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{ef96:7a}} 
        add     a,a               ;{{ef97:87}} 
        jr      nc,_convert_number_to_string_by_format_54;{{ef98:302d}}  (+$2d)
        jp      m,_convert_number_to_string_by_format_76;{{ef9a:faedef}} 
        ld      a,e               ;{{ef9d:7b}} 
        add     a,c               ;{{ef9e:81}} 
        sub     $15               ;{{ef9f:d615}} 
        jp      m,_convert_number_to_string_by_format_141;{{efa1:fa56f0}} 
        ld      a,d               ;{{efa4:7a}} 
        or      $41               ;{{efa5:f641}}  'A'
        ld      d,a               ;{{efa7:57}} 
        jr      _convert_number_to_string_by_format_76;{{efa8:1843}}  (+$43)

_convert_number_to_string_by_format_37:;{{Addr=$efaa Code Calls/jump count: 2 Data use count: 0}}
        ld      b,c               ;{{efaa:41}} 
        ld      a,c               ;{{efab:79}} 
        or      a                 ;{{efac:b7}} 
        jr      z,_convert_number_to_string_by_format_53;{{efad:2815}}  (+$15)
        add     a,e               ;{{efaf:83}} 
        dec     a                 ;{{efb0:3d}} 
        ld      e,a               ;{{efb1:5f}} 
        call    _convert_number_to_string_by_format_244;{{efb2:cddef0}} 
        ld      b,$01             ;{{efb5:0601}} 
        ld      a,c               ;{{efb7:79}} 
        cp      $07               ;{{efb8:fe07}} 
        jr      c,_convert_number_to_string_by_format_51;{{efba:3804}}  (+$04)
        bit     6,d               ;{{efbc:cb72}} 
        jr      nz,_convert_number_to_string_by_format_73;{{efbe:2026}}  (+$26)
_convert_number_to_string_by_format_51:;{{Addr=$efc0 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{efc0:b8}} 
        call    nz,_convert_number_to_string_by_format_156;{{efc1:c474f0}} 
_convert_number_to_string_by_format_53:;{{Addr=$efc4 Code Calls/jump count: 1 Data use count: 0}}
        jp      _convert_number_to_string_by_format_121;{{efc4:c332f0}} 

_convert_number_to_string_by_format_54:;{{Addr=$efc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{efc7:7b}} 
        or      a                 ;{{efc8:b7}} 
        jp      m,_convert_number_to_string_by_format_60;{{efc9:fad0ef}} 
        jr      nz,_convert_number_to_string_by_format_37;{{efcc:20dc}}  (-$24)
_convert_number_to_string_by_format_58:;{{Addr=$efce Code Calls/jump count: 1 Data use count: 0}}
        ld      b,c               ;{{efce:41}} 
        ret                       ;{{efcf:c9}} 

_convert_number_to_string_by_format_60:;{{Addr=$efd0 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,e               ;{{efd0:43}} 
        call    _convert_number_to_string_by_format_244;{{efd1:cddef0}} 
        ld      a,b               ;{{efd4:78}} 
        or      a                 ;{{efd5:b7}} 
        jr      z,_convert_number_to_string_by_format_58;{{efd6:28f6}}  (-$0a)
        sub     e                 ;{{efd8:93}} 
        ld      e,b               ;{{efd9:58}} 
        ld      b,a               ;{{efda:47}} 
        add     a,c               ;{{efdb:81}} 
        add     a,e               ;{{efdc:83}} 
        jp      m,_convert_number_to_string_by_format_37;{{efdd:faaaef}} 
        call    _convert_number_to_string_by_format_173;{{efe0:cd87f0}} 
        jp      _convert_number_to_string_by_format_156;{{efe3:c374f0}} 

_convert_number_to_string_by_format_73:;{{Addr=$efe6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$06             ;{{efe6:3e06}} 
        ld      (RAM_ae52),a      ;{{efe8:3252ae}} 
        jr      _convert_number_to_string_by_format_104;{{efeb:182e}}  (+$2e)

_convert_number_to_string_by_format_76:;{{Addr=$efed Code Calls/jump count: 2 Data use count: 0}}
        call    _convert_number_to_string_by_format_263;{{efed:cdfbf0}} 
        jr      nc,_convert_number_to_string_by_format_80;{{eff0:3003}}  (+$03)
        set     0,d               ;{{eff2:cbc2}} 
        xor     a                 ;{{eff4:af}} 
_convert_number_to_string_by_format_80:;{{Addr=$eff5 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,a               ;{{eff5:47}} 
        call    z,_convert_number_to_string_by_format_280;{{eff6:cc13f1}} 
        jr      nz,_convert_number_to_string_by_format_91;{{eff9:200e}}  (+$0e)
        set     0,d               ;{{effb:cbc2}} 
        inc     b                 ;{{effd:04}} 
        ld      a,(RAM_ae52)      ;{{effe:3a52ae}} 
        or      a                 ;{{f001:b7}} 
        jr      z,_convert_number_to_string_by_format_91;{{f002:2805}}  (+$05)
        dec     b                 ;{{f004:05}} 
        inc     a                 ;{{f005:3c}} 
        ld      (RAM_ae52),a      ;{{f006:3252ae}} 
_convert_number_to_string_by_format_91:;{{Addr=$f009 Code Calls/jump count: 2 Data use count: 0}}
        bit     1,d               ;{{f009:cb4a}} 
        jr      z,_convert_number_to_string_by_format_98;{{f00b:2807}}  (+$07)
        ld      a,b               ;{{f00d:78}} 
        inc     b                 ;{{f00e:04}} 
_convert_number_to_string_by_format_95:;{{Addr=$f00f Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{f00f:05}} 
        sub     $04               ;{{f010:d604}} 
        jr      nc,_convert_number_to_string_by_format_95;{{f012:30fb}}  (-$05)
_convert_number_to_string_by_format_98:;{{Addr=$f014 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{f014:79}} 
        or      a                 ;{{f015:b7}} 
        jr      z,_convert_number_to_string_by_format_105;{{f016:2804}}  (+$04)
        add     a,e               ;{{f018:83}} 
        sub     b                 ;{{f019:90}} 
        ld      e,a               ;{{f01a:5f}} 
_convert_number_to_string_by_format_104:;{{Addr=$f01b Code Calls/jump count: 1 Data use count: 0}}
        ld      a,b               ;{{f01b:78}} 
_convert_number_to_string_by_format_105:;{{Addr=$f01c Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{f01c:f5}} 
        ld      b,a               ;{{f01d:47}} 
        call    _convert_number_to_string_by_format_142;{{f01e:cd59f0}} 
        pop     af                ;{{f021:f1}} 
        cp      b                 ;{{f022:b8}} 
        jr      z,_convert_number_to_string_by_format_121;{{f023:280d}}  (+$0d)
        inc     e                 ;{{f025:1c}} 
        inc     hl                ;{{f026:23}} 
        dec     b                 ;{{f027:05}} 
        push    hl                ;{{f028:e5}} 
        ld      a,(hl)            ;{{f029:7e}} 
        cp      $2e               ;{{f02a:fe2e}} 
        jr      nz,_convert_number_to_string_by_format_119;{{f02c:2001}}  (+$01)
        inc     hl                ;{{f02e:23}} 
_convert_number_to_string_by_format_119:;{{Addr=$f02f Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$31          ;{{f02f:3631}} 
        pop     hl                ;{{f031:e1}} 
_convert_number_to_string_by_format_121:;{{Addr=$f032 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$04             ;{{f032:3e04}} 
        call    _convert_number_to_string_by_format_219;{{f034:cdc2f0}} 
        push    hl                ;{{f037:e5}} 
        ld      hl,$2b45          ;{{f038:21452b}} 
        ld      a,e               ;{{f03b:7b}} 
        or      a                 ;{{f03c:b7}} 
        jp      p,_convert_number_to_string_by_format_131;{{f03d:f244f0}} 
        xor     a                 ;{{f040:af}} 
        sub     e                 ;{{f041:93}} 
        ld      h,$2d             ;{{f042:262d}}  '-'
_convert_number_to_string_by_format_131:;{{Addr=$f044 Code Calls/jump count: 1 Data use count: 0}}
        ld      ($ae4c),hl        ;{{f044:224cae}} 
        ld      l,$2f             ;{{f047:2e2f}} 
_convert_number_to_string_by_format_133:;{{Addr=$f049 Code Calls/jump count: 1 Data use count: 0}}
        inc     l                 ;{{f049:2c}} 
        sub     $0a               ;{{f04a:d60a}} 
        jr      nc,_convert_number_to_string_by_format_133;{{f04c:30fb}}  (-$05)
        add     a,$3a             ;{{f04e:c63a}} ":"
        ld      h,a               ;{{f050:67}} 
        ld      (last_byte__B),hl ;{{f051:224eae}} 
        pop     hl                ;{{f054:e1}} 
        ret                       ;{{f055:c9}} 

_convert_number_to_string_by_format_141:;{{Addr=$f056 Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_to_string_by_format_173;{{f056:cd87f0}} 
_convert_number_to_string_by_format_142:;{{Addr=$f059 Code Calls/jump count: 1 Data use count: 0}}
        call    _convert_number_to_string_by_format_280;{{f059:cd13f1}} 
        add     a,b               ;{{f05c:80}} 
        cp      c                 ;{{f05d:b9}} 
        jr      nc,_convert_number_to_string_by_format_148;{{f05e:3005}}  (+$05)
        call    _convert_number_to_string_by_format_188;{{f060:cd9af0}} 
        jr      _convert_number_to_string_by_format_153;{{f063:180a}}  (+$0a)

_convert_number_to_string_by_format_148:;{{Addr=$f065 Code Calls/jump count: 1 Data use count: 0}}
        cp      $15               ;{{f065:fe15}} 
        jr      c,_convert_number_to_string_by_format_151;{{f067:3802}}  (+$02)
        ld      a,$14             ;{{f069:3e14}} 
_convert_number_to_string_by_format_151:;{{Addr=$f06b Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{f06b:91}} 
        call    nz,_convert_number_to_string_by_format_219;{{f06c:c4c2f0}} 
_convert_number_to_string_by_format_153:;{{Addr=$f06f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(RAM_ae52)      ;{{f06f:3a52ae}} 
        or      a                 ;{{f072:b7}} 
        ret     z                 ;{{f073:c8}} 

_convert_number_to_string_by_format_156:;{{Addr=$f074 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,$2e             ;{{f074:0e2e}} 
        ld      a,b               ;{{f076:78}} 
_convert_number_to_string_by_format_158:;{{Addr=$f077 Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f077:c5}} 
        ld      b,a               ;{{f078:47}} 
        inc     b                 ;{{f079:04}} 
        add     a,l               ;{{f07a:85}} 
        ld      l,a               ;{{f07b:6f}} 
        adc     a,h               ;{{f07c:8c}} 
        sub     l                 ;{{f07d:95}} 
        ld      h,a               ;{{f07e:67}} 
_convert_number_to_string_by_format_166:;{{Addr=$f07f Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f07f:2b}} 
        ld      a,c               ;{{f080:79}} 
        ld      c,(hl)            ;{{f081:4e}} 
        ld      (hl),a            ;{{f082:77}} 
        djnz    _convert_number_to_string_by_format_166;{{f083:10fa}}  (-$06)
        pop     bc                ;{{f085:c1}} 
        ret                       ;{{f086:c9}} 

_convert_number_to_string_by_format_173:;{{Addr=$f087 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,e               ;{{f087:7b}} 
        add     a,c               ;{{f088:81}} 
        ld      b,a               ;{{f089:47}} 
        ret     p                 ;{{f08a:f0}} 

        cpl                       ;{{f08b:2f}} 
        inc     a                 ;{{f08c:3c}} 
        ld      b,$14             ;{{f08d:0614}} 
        cp      b                 ;{{f08f:b8}} 
        jr      nc,_convert_number_to_string_by_format_183;{{f090:3001}}  (+$01)
        ld      b,a               ;{{f092:47}} 
_convert_number_to_string_by_format_183:;{{Addr=$f093 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f093:2b}} 
        ld      (hl),$30          ;{{f094:3630}} 
        inc     c                 ;{{f096:0c}} 
        djnz    _convert_number_to_string_by_format_183;{{f097:10fa}}  (-$06)
        ret                       ;{{f099:c9}} 

_convert_number_to_string_by_format_188:;{{Addr=$f09a Code Calls/jump count: 1 Data use count: 0}}
        ld      c,a               ;{{f09a:4f}} 
        add     a,l               ;{{f09b:85}} 
        ld      l,a               ;{{f09c:6f}} 
        adc     a,h               ;{{f09d:8c}} 
        sub     l                 ;{{f09e:95}} 
        ld      h,a               ;{{f09f:67}} 
        push    hl                ;{{f0a0:e5}} 
        push    bc                ;{{f0a1:c5}} 
        ld      a,(hl)            ;{{f0a2:7e}} 
        cp      $35               ;{{f0a3:fe35}} 
        call    nc,_convert_number_to_string_by_format_208;{{f0a5:d4b4f0}} 
        pop     bc                ;{{f0a8:c1}} 
        jr      c,_convert_number_to_string_by_format_205;{{f0a9:3805}}  (+$05)
        dec     hl                ;{{f0ab:2b}} 
        ld      (hl),$31          ;{{f0ac:3631}} 
        inc     b                 ;{{f0ae:04}} 
        inc     c                 ;{{f0af:0c}} 
_convert_number_to_string_by_format_205:;{{Addr=$f0b0 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f0b0:e1}} 
        dec     hl                ;{{f0b1:2b}} 
        jr      _convert_number_to_string_by_format_253;{{f0b2:1838}}  (+$38)

_convert_number_to_string_by_format_208:;{{Addr=$f0b4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f0b4:79}} 
        or      a                 ;{{f0b5:b7}} 
        ret     z                 ;{{f0b6:c8}} 

        dec     hl                ;{{f0b7:2b}} 
        dec     c                 ;{{f0b8:0d}} 
        ld      a,(hl)            ;{{f0b9:7e}} 
        inc     (hl)              ;{{f0ba:34}} 
        cp      $39               ;{{f0bb:fe39}} 
        ret     c                 ;{{f0bd:d8}} 

        ld      (hl),$30          ;{{f0be:3630}} 
        jr      _convert_number_to_string_by_format_208;{{f0c0:18f2}}  (-$0e)

_convert_number_to_string_by_format_219:;{{Addr=$f0c2 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f0c2:d5}} 
        push    bc                ;{{f0c3:c5}} 
        ex      de,hl             ;{{f0c4:eb}} 
        ld      b,a               ;{{f0c5:47}} 
        ld      a,e               ;{{f0c6:7b}} 
        sub     b                 ;{{f0c7:90}} 
        ld      l,a               ;{{f0c8:6f}} 
        sbc     a,a               ;{{f0c9:9f}} 
        add     a,d               ;{{f0ca:82}} 
        ld      h,a               ;{{f0cb:67}} 
        push    hl                ;{{f0cc:e5}} 
_convert_number_to_string_by_format_230:;{{Addr=$f0cd Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f0cd:1a}} 
        inc     de                ;{{f0ce:13}} 
        ld      (hl),a            ;{{f0cf:77}} 
        inc     hl                ;{{f0d0:23}} 
        or      a                 ;{{f0d1:b7}} 
        jr      nz,_convert_number_to_string_by_format_230;{{f0d2:20f9}}  (-$07)
        dec     hl                ;{{f0d4:2b}} 
_convert_number_to_string_by_format_237:;{{Addr=$f0d5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (hl),$30          ;{{f0d5:3630}} 
        inc     hl                ;{{f0d7:23}} 
        djnz    _convert_number_to_string_by_format_237;{{f0d8:10fb}}  (-$05)
        pop     hl                ;{{f0da:e1}} 
        pop     bc                ;{{f0db:c1}} 
        pop     de                ;{{f0dc:d1}} 
        ret                       ;{{f0dd:c9}} 

_convert_number_to_string_by_format_244:;{{Addr=$f0de Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$ae50          ;{{f0de:2150ae}} 
_convert_number_to_string_by_format_245:;{{Addr=$f0e1 Code Calls/jump count: 1 Data use count: 0}}
        dec     hl                ;{{f0e1:2b}} 
        ld      a,(hl)            ;{{f0e2:7e}} 
        cp      $30               ;{{f0e3:fe30}} 
        jr      nz,_convert_number_to_string_by_format_253;{{f0e5:2005}}  (+$05)
        dec     c                 ;{{f0e7:0d}} 
        inc     b                 ;{{f0e8:04}} 
        jr      nz,_convert_number_to_string_by_format_245;{{f0e9:20f6}}  (-$0a)
        dec     hl                ;{{f0eb:2b}} 
_convert_number_to_string_by_format_253:;{{Addr=$f0ec Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f0ec:d5}} 
        push    bc                ;{{f0ed:c5}} 
        ld      de,$ae4f          ;{{f0ee:114fae}} 
        ld      b,$00             ;{{f0f1:0600}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f0f3:cdf5ff}}  copy bytes LDDR (BC = count)
        ex      de,hl             ;{{f0f6:eb}} 
        inc     hl                ;{{f0f7:23}} 
        pop     bc                ;{{f0f8:c1}} 
        pop     de                ;{{f0f9:d1}} 
        ret                       ;{{f0fa:c9}} 

_convert_number_to_string_by_format_263:;{{Addr=$f0fb Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f0fb:c5}} 
        ld      a,d               ;{{f0fc:7a}} 
        and     $04               ;{{f0fd:e604}} 
        rra                       ;{{f0ff:1f}} 
        rra                       ;{{f100:1f}} 
        ld      b,a               ;{{f101:47}} 
        bit     4,d               ;{{f102:cb62}} 
        jr      nz,_convert_number_to_string_by_format_276;{{f104:2007}}  (+$07)
        ld      a,d               ;{{f106:7a}} 
        add     a,a               ;{{f107:87}} 
        or      e                 ;{{f108:b3}} 
        jp      p,_convert_number_to_string_by_format_276;{{f109:f20df1}} 
        inc     b                 ;{{f10c:04}} 
_convert_number_to_string_by_format_276:;{{Addr=$f10d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,($ae53)         ;{{f10d:3a53ae}} 
        sub     b                 ;{{f110:90}} 
        pop     bc                ;{{f111:c1}} 
        ret                       ;{{f112:c9}} 

_convert_number_to_string_by_format_280:;{{Addr=$f113 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(RAM_ae52)      ;{{f113:3a52ae}} 
        or      a                 ;{{f116:b7}} 
        ret     z                 ;{{f117:c8}} 

        dec     a                 ;{{f118:3d}} 
        ret                       ;{{f119:c9}} 

_convert_number_to_string_by_format_285:;{{Addr=$f11a Code Calls/jump count: 1 Data use count: 0}}
        bit     1,d               ;{{f11a:cb4a}} 
        ret     z                 ;{{f11c:c8}} 

        ld      a,b               ;{{f11d:78}} 
_convert_number_to_string_by_format_288:;{{Addr=$f11e Code Calls/jump count: 1 Data use count: 0}}
        sub     $03               ;{{f11e:d603}} 
        ret     c                 ;{{f120:d8}} 

        ret     z                 ;{{f121:c8}} 

        push    af                ;{{f122:f5}} 
        ld      c,$2c             ;{{f123:0e2c}}  ','
        call    _convert_number_to_string_by_format_158;{{f125:cd77f0}} 
        inc     b                 ;{{f128:04}} 
        pop     af                ;{{f129:f1}} 
        jr      _convert_number_to_string_by_format_288;{{f12a:18f2}}  (-$0e)

_convert_number_to_string_by_format_297:;{{Addr=$f12c Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{f12c:e5}} 
_convert_number_to_string_by_format_298:;{{Addr=$f12d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f12d:7e}} 
        inc     hl                ;{{f12e:23}} 
        dec     a                 ;{{f12f:3d}} 
        cp      $30               ;{{f130:fe30}} 
        jr      c,_convert_number_to_string_by_format_298;{{f132:38f9}}  (-$07)
        inc     a                 ;{{f134:3c}} 
        jr      nz,_convert_number_to_string_by_format_306;{{f135:2001}}  (+$01)
        ld      e,a               ;{{f137:5f}} 
_convert_number_to_string_by_format_306:;{{Addr=$f138 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f138:e1}} 
        ld      a,d               ;{{f139:7a}} 
        xor     $80               ;{{f13a:ee80}} 
        call    p,_convert_number_to_string_by_format_263;{{f13c:f4fbf0}} 
        ret     c                 ;{{f13f:d8}} 

        ret     z                 ;{{f140:c8}} 

        ld      a,$30             ;{{f141:3e30}}  '0'
        jr      _convert_number_to_string_by_format_317;{{f143:1806}} 

_convert_number_to_string_by_format_314:;{{Addr=$f145 Code Calls/jump count: 1 Data use count: 0}}
        bit     2,d               ;{{f145:cb52}} 
        ret     z                 ;{{f147:c8}} 

        ld      a,(RAM_ae54)      ;{{f148:3a54ae}} 
_convert_number_to_string_by_format_317:;{{Addr=$f14b Code Calls/jump count: 2 Data use count: 0}}
        inc     b                 ;{{f14b:04}} 
        dec     hl                ;{{f14c:2b}} 
        ld      (hl),a            ;{{f14d:77}} 
        ret                       ;{{f14e:c9}} 

_convert_number_to_string_by_format_321:;{{Addr=$f14f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,e               ;{{f14f:7b}} 
        add     a,a               ;{{f150:87}} 
        ld      a,$2d             ;{{f151:3e2d}}  '-'
        jr      c,_convert_number_to_string_by_format_333;{{f153:380e}}  
        ld      a,d               ;{{f155:7a}} 
        and     $98               ;{{f156:e698}} 
        xor     $80               ;{{f158:ee80}} 
        ret     z                 ;{{f15a:c8}} 

        and     $08               ;{{f15b:e608}} 
        ld      a,$2b             ;{{f15d:3e2b}}  '+'
        jr      nz,_convert_number_to_string_by_format_333;{{f15f:2002}}  
        ld      a,$20             ;{{f161:3e20}}  ' '
_convert_number_to_string_by_format_333:;{{Addr=$f163 Code Calls/jump count: 2 Data use count: 0}}
        bit     4,d               ;{{f163:cb62}} 
        jr      z,_convert_number_to_string_by_format_317;{{f165:28e4}}  (-$1c)
        ld      ($ae50),a         ;{{f167:3250ae}} 
        xor     a                 ;{{f16a:af}} 
        ld      (RAM_ae51),a      ;{{f16b:3251ae}} 
        ret                       ;{{f16e:c9}} 

_convert_number_to_string_by_format_339:;{{Addr=$f16f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,d               ;{{f16f:7a}} 
        or      a                 ;{{f170:b7}} 
        ret     p                 ;{{f171:f0}} 

        ld      a,($ae53)         ;{{f172:3a53ae}} 
        sub     b                 ;{{f175:90}} 
        ret     z                 ;{{f176:c8}} 

        jr      c,_convert_number_to_string_by_format_355;{{f177:380e}}  (+$0e)
        ld      b,a               ;{{f179:47}} 
        bit     5,d               ;{{f17a:cb6a}} 
        ld      a,$2a             ;{{f17c:3e2a}} 
        jr      nz,_convert_number_to_string_by_format_351;{{f17e:2002}}  (+$02)
        ld      a,$20             ;{{f180:3e20}} 
_convert_number_to_string_by_format_351:;{{Addr=$f182 Code Calls/jump count: 2 Data use count: 0}}
        dec     hl                ;{{f182:2b}} 
        ld      (hl),a            ;{{f183:77}} 
        djnz    _convert_number_to_string_by_format_351;{{f184:10fc}}  (-$04)
        ret                       ;{{f186:c9}} 

_convert_number_to_string_by_format_355:;{{Addr=$f187 Code Calls/jump count: 1 Data use count: 0}}
        set     0,d               ;{{f187:cbc2}} 
        ret                       ;{{f189:c9}} 

_convert_number_to_string_by_format_357:;{{Addr=$f18a Code Calls/jump count: 1 Data use count: 0}}
        ld      de,buffer_used_to_form_binary_or_hexadecima;{{f18a:112dae}} 
        xor     a                 ;{{f18d:af}} 
        ld      b,a               ;{{f18e:47}} 
_convert_number_to_string_by_format_360:;{{Addr=$f18f Code Calls/jump count: 1 Data use count: 0}}
        or      (hl)              ;{{f18f:b6}} 
        dec     hl                ;{{f190:2b}} 
        jr      nz,_convert_number_to_string_by_format_366;{{f191:2005}}  (+$05)
        dec     c                 ;{{f193:0d}} 
        jr      nz,_convert_number_to_string_by_format_360;{{f194:20f9}}  (-$07)
        jr      _convert_number_to_string_by_format_397;{{f196:1828}}  (+$28)

_convert_number_to_string_by_format_366:;{{Addr=$f198 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{f198:37}} 
_convert_number_to_string_by_format_367:;{{Addr=$f199 Code Calls/jump count: 1 Data use count: 0}}
        adc     a,a               ;{{f199:8f}} 
        jr      nc,_convert_number_to_string_by_format_367;{{f19a:30fd}}  (-$03)
        ex      de,hl             ;{{f19c:eb}} 
        push    de                ;{{f19d:d5}} 
        ld      d,a               ;{{f19e:57}} 
        jr      _convert_number_to_string_by_format_388;{{f19f:1811}}  (+$11)

_convert_number_to_string_by_format_373:;{{Addr=$f1a1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f1a1:1a}} 
        dec     de                ;{{f1a2:1b}} 
        push    de                ;{{f1a3:d5}} 
        scf                       ;{{f1a4:37}} 
        adc     a,a               ;{{f1a5:8f}} 
_convert_number_to_string_by_format_378:;{{Addr=$f1a6 Code Calls/jump count: 1 Data use count: 0}}
        ld      d,a               ;{{f1a6:57}} 
        ld      e,b               ;{{f1a7:58}} 
_convert_number_to_string_by_format_380:;{{Addr=$f1a8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f1a8:7e}} 
        adc     a,a               ;{{f1a9:8f}} 
        daa                       ;{{f1aa:27}} 
        ld      (hl),a            ;{{f1ab:77}} 
        inc     hl                ;{{f1ac:23}} 
        dec     e                 ;{{f1ad:1d}} 
        jr      nz,_convert_number_to_string_by_format_380;{{f1ae:20f8}}  (-$08)
        jr      nc,_convert_number_to_string_by_format_390;{{f1b0:3003}}  (+$03)
_convert_number_to_string_by_format_388:;{{Addr=$f1b2 Code Calls/jump count: 1 Data use count: 0}}
        inc     b                 ;{{f1b2:04}} 
        ld      (hl),$01          ;{{f1b3:3601}} 
_convert_number_to_string_by_format_390:;{{Addr=$f1b5 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,buffer_used_to_form_binary_or_hexadecima;{{f1b5:212dae}} 
        ld      a,d               ;{{f1b8:7a}} 
        add     a,a               ;{{f1b9:87}} 
        jr      nz,_convert_number_to_string_by_format_378;{{f1ba:20ea}}  (-$16)
        pop     de                ;{{f1bc:d1}} 
        dec     c                 ;{{f1bd:0d}} 
        jr      nz,_convert_number_to_string_by_format_373;{{f1be:20e1}}  (-$1f)
_convert_number_to_string_by_format_397:;{{Addr=$f1c0 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{f1c0:eb}} 
        ld      hl,$ae50          ;{{f1c1:2150ae}} 
        ld      (hl),$00          ;{{f1c4:3600}} 
        ld      a,b               ;{{f1c6:78}} 
        add     a,a               ;{{f1c7:87}} 
        ld      c,a               ;{{f1c8:4f}} 
        ret     z                 ;{{f1c9:c8}} 

        ld      a,$30             ;{{f1ca:3e30}} ; '0'
        ex      de,hl             ;{{f1cc:eb}} 
_convert_number_to_string_by_format_406:;{{Addr=$f1cd Code Calls/jump count: 1 Data use count: 0}}
        rrd                       ;{{f1cd:ed67}} 
        dec     de                ;{{f1cf:1b}} 
        ld      (de),a            ;{{f1d0:12}} 
        rrd                       ;{{f1d1:ed67}} 
        dec     de                ;{{f1d3:1b}} 
        ld      (de),a            ;{{f1d4:12}} 
        inc     hl                ;{{f1d5:23}} 
        djnz    _convert_number_to_string_by_format_406;{{f1d6:10f5}}  (-$0b)
        ex      de,hl             ;{{f1d8:eb}} 
        cp      $30               ;{{f1d9:fe30}} 
        ret     nz                ;{{f1db:c0}} 

        dec     c                 ;{{f1dc:0d}} 
        inc     hl                ;{{f1dd:23}} 
        ret                       ;{{f1de:c9}} 

;;===============================
;;convert based number to string
;C=base (01=binary, 0f=hex)
;B=number of bits per output digit (01 for binary, 04 for hex)
convert_based_number_to_string:   ;{{Addr=$f1df Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{f1df:d5}} 
        ex      de,hl             ;{{f1e0:eb}} 
        ld      hl,last_byte_     ;{{f1e1:213eae}} 
        ld      (hl),$00          ;{{f1e4:3600}} 
        dec     a                 ;{{f1e6:3d}} 
_convert_based_number_to_string_5:;{{Addr=$f1e7 Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{f1e7:f5}} 
        ld      a,e               ;{{f1e8:7b}} 
        and     c                 ;{{f1e9:a1}} 
        or      $f0               ;{{f1ea:f6f0}} 
        daa                       ;{{f1ec:27}} 
        add     a,$a0             ;{{f1ed:c6a0}} 
        adc     a,$40             ;{{f1ef:ce40}} ; 'A'-1
        dec     hl                ;{{f1f1:2b}} 
        ld      (hl),a            ;{{f1f2:77}} 
        ld      a,b               ;{{f1f3:78}} 
_convert_based_number_to_string_15:;{{Addr=$f1f4 Code Calls/jump count: 1 Data use count: 0}}
        srl     d                 ;{{f1f4:cb3a}} 
        rr      e                 ;{{f1f6:cb1b}} 
        djnz    _convert_based_number_to_string_15;{{f1f8:10fa}}  (-$06)
        ld      b,a               ;{{f1fa:47}} 
        pop     af                ;{{f1fb:f1}} 
        dec     a                 ;{{f1fc:3d}} 
        jp      p,_convert_based_number_to_string_5;{{f1fd:f2e7f1}} 
        ld      a,d               ;{{f200:7a}} 
        or      e                 ;{{f201:b3}} 
        ld      a,$00             ;{{f202:3e00}} 
        jr      nz,_convert_based_number_to_string_5;{{f204:20e1}}  (-$1f)
        pop     de                ;{{f206:d1}} 
        ret                       ;{{f207:c9}} 





;;***PeekPokeIOBarCall.asm
;;<< PEEK, POKE, INP, OUT, WAIT, |BAR commands, CALL
;;========================================================
;; function PEEK

function_PEEK:                    ;{{Addr=$f208 Code Calls/jump count: 0 Data use count: 1}}
        call    function_UNT      ;{{f208:cdebfe}} 
        rst     $20               ;{{f20b:e7}} 
        jp      store_A_in_accumulator_as_INT;{{f20c:c332ff}} 

;;========================================================================
;; command POKE

command_POKE:                     ;{{Addr=$f20f Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_uint ;{{f20f:cdf5ce}} 
        push    de                ;{{f212:d5}} 
        call    eval_next_param_as_byte_or_error;{{f213:cd3ff2}} 
        pop     de                ;{{f216:d1}} 
        ld      (de),a            ;{{f217:12}} 
        ret                       ;{{f218:c9}} 

;;========================================================================
;; function INP
function_INP:                     ;{{Addr=$f219 Code Calls/jump count: 0 Data use count: 1}}
        call    function_CINT     ;{{f219:cdb6fe}} 
        ld      b,h               ;{{f21c:44}} 
        ld      c,l               ;{{f21d:4d}} 
        in      a,(c)             ;{{f21e:ed78}} 
        jp      store_A_in_accumulator_as_INT;{{f220:c332ff}} 

;;========================================================================
;; command OUT

command_OUT:                      ;{{Addr=$f223 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_uint_and_byte_params_or_error;{{f223:cd3af2}} 
        out     (c),a             ;{{f226:ed79}} 
        ret                       ;{{f228:c9}} 
 
;;========================================================================
;; command WAIT
command_WAIT:                     ;{{Addr=$f229 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_uint_and_byte_params_or_error;{{f229:cd3af2}} 
        ld      d,a               ;{{f22c:57}} 
        ld      a,$00             ;{{f22d:3e00}} 
        call    nz,eval_next_param_as_byte_or_error;{{f22f:c43ff2}} 
        ld      e,a               ;{{f232:5f}} 
_command_wait_5:                  ;{{Addr=$f233 Code Calls/jump count: 1 Data use count: 0}}
        in      a,(c)             ;{{f233:ed78}} 
        xor     e                 ;{{f235:ab}} 
        and     d                 ;{{f236:a2}} 
        jr      z,_command_wait_5 ;{{f237:28fa}}  (-$06)
        ret                       ;{{f239:c9}} 

;;========================================================================
;;=eval uint and byte params or error
eval_uint_and_byte_params_or_error:;{{Addr=$f23a Code Calls/jump count: 2 Data use count: 0}}
        call    eval_expr_as_uint ;{{f23a:cdf5ce}} 
        ld      b,d               ;{{f23d:42}} 
        ld      c,e               ;{{f23e:4b}} 
;;=eval next param as byte or error
eval_next_param_as_byte_or_error: ;{{Addr=$f23f Code Calls/jump count: 2 Data use count: 0}}
        call    next_token_if_comma;{{f23f:cd15de}}  check for comma
        jp      eval_expr_as_byte_or_error;{{f242:c3b8ce}}  get number and check it's less than 255 

;;=========================================================
;; BAR command

;; skip | symbol
BAR_command:                      ;{{Addr=$f245 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{f245:23}} 
;; this is the name with last char with bit 7 set
        ld      a,(hl)            ;{{f246:7e}} 
        or      a                 ;{{f247:b7}} 
        inc     hl                ;{{f248:23}} 
        push    hl                ;{{f249:e5}} 
        call    z,KL_FIND_COMMAND ;{{f24a:ccd4bc}}  firmware function: KL FIND COMMAND
        ex      de,hl             ;{{f24d:eb}} 
        pop     hl                ;{{f24e:e1}} 
        jr      nc,_bar_command_14;{{f24f:3007}}  command not found...?
;; skip name
_bar_command_9:                   ;{{Addr=$f251 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f251:7e}} 
        inc     hl                ;{{f252:23}} 
        rla                       ;{{f253:17}} 
        jr      nc,_bar_command_9 ;{{f254:30fb}}  (-$05)
        jr      _command_call_2   ;{{f256:1809}}  (+$09)

_bar_command_14:                  ;{{Addr=$f258 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{f258:cd45cb}} 
        defb $1c                  ;Inline error code: Unknown command

;;==================================================================
;; command CALL
command_CALL:                     ;{{Addr=$f25c Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_uint ;{{f25c:cdf5ce}}  get address
        ld      c,$ff             ;{{f25f:0eff}} 
;; store address of function
_command_call_2:                  ;{{Addr=$f261 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_last_used_ROM_or_RSX_JUMP_ins),de;{{f261:ed5355ae}} 
;; store rom select
        ld      a,c               ;{{f265:79}} 
        ld      (ROM_select_number_if_address_above_is_in),a;{{f266:3257ae}} 
        ld      (the_resetting_address_for_machine_Stack_),sp;{{f269:ed735aae}} 
        ld      b,$20             ;{{f26d:0620}}  max 32 parameters
_command_call_7:                  ;{{Addr=$f26f Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{f26f:cd41de}} 
        jr      nc,_command_call_14;{{f272:3008}}  (+$08)
        push    bc                ;{{f274:c5}} 
        call    eval_expr_as_string;{{f275:cde3ce}} 
        pop     bc                ;{{f278:c1}} 
        push    de                ;{{f279:d5}}  push parameter onto stack
        djnz    _command_call_7   ;{{f27a:10f3}}  (-$0d)
_command_call_14:                 ;{{Addr=$f27c Code Calls/jump count: 1 Data use count: 0}}
        call    syntax_error_if_not_02;{{f27c:cd37de}} 
        ld      (BASIC_Parser_position_moved_on_to__),hl;{{f27f:2258ae}} 
        ld      a,$20             ;{{f282:3e20}}  max 32 parameters
;; B = $20-number of parameters specified
        sub     b                 ;{{f284:90}} 
;; A = number of parameters
        ld      ix,$0000          ;{{f285:dd210000}} ##LIT##
        add     ix,sp             ;{{f289:dd39}}  IX points to parameters on stack

;; IX = points to parameters
;; A = number of parameters
;; execute function
        rst     $18               ;{{f28b:df}} 
        defw address_of_last_used_ROM_or_RSX_JUMP_ins                
        ld      sp,(the_resetting_address_for_machine_Stack_);{{f28e:ed7b5aae}} 
        call    get_string_stack_first_free_ptr;{{f292:cdccfb}} 
        ld      hl,(BASIC_Parser_position_moved_on_to__);{{f295:2a58ae}} 
        ret                       ;{{f298:c9}} 







;;***TextOutput.asm
;;<< TEXT OUTPUT (ZONE, PRINT, WRITE)
;;=====================================
;;set zone 13
set_zone_13:                      ;{{Addr=$f299 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0d             ;{{f299:3e0d}} 
        jr      _command_zone_1   ;{{f29b:1803}}  (+$03)

;;========================================================================
;; command ZONE

command_ZONE:                     ;{{Addr=$f29d Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_int_less_than_256;{{f29d:cdc3ce}} 
_command_zone_1:                  ;{{Addr=$f2a0 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ZONE_value),a    ;{{f2a0:325cae}} 
        ret                       ;{{f2a3:c9}} 

;;========================================================================
;; command PRINT

command_PRINT:                    ;{{Addr=$f2a4 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_BC_on_evalled_stream_and_swap_back;{{f2a4:cdcfc1}} 
        call    is_next_02        ;{{f2a7:cd3dde}} 
        jp      c,output_new_line ;{{f2aa:da98c3}} ; new text line
_command_print_3:                 ;{{Addr=$f2ad Code Calls/jump count: 1 Data use count: 0}}
        cp      $ed               ;{{f2ad:feed}} "USING"
        jp      z,PRINT_USING     ;{{f2af:ca7ef3}} 
        ex      de,hl             ;{{f2b2:eb}} 
        ld      hl,PRINT_parameters_LUT;{{f2b3:21c3f2}} 
        call    get_address_from_table;{{f2b6:cdb4ff}} 
        ex      de,hl             ;{{f2b9:eb}} 
        call    JP_DE             ;{{f2ba:cdfeff}}  JP (DE)
        call    is_next_02        ;{{f2bd:cd3dde}} 
        jr      nc,_command_print_3;{{f2c0:30eb}}  (-$15)
        ret                       ;{{f2c2:c9}} 

;;=PRINT parameters LUT
PRINT_parameters_LUT:             ;{{Addr=$f2c3 Data Calls/jump count: 0 Data use count: 1}}
        defb $04                  ;Count of parameters
        defw PRINT_do_other       ;Jump to if not found  ##LABEL##

        defb $2c                  ;","
        defw PRINT_do_comma       ;  ##LABEL##
        defb $e5                  ;"SPC"
        defw PRINT_do_SPC         ;  ##LABEL##
        defb $ea                  ;"TAB"
        defw PRINT_do_TAB         ;  ##LABEL##
        defb $3b                  ;";"
        defw get_next_token_skipping_space;  ##LABEL##

;;+PRINT do other
PRINT_do_other:                   ;{{Addr=$f2d2 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{f2d2:cd62cf}} 
        push    af                ;{{f2d5:f5}} 
        push    hl                ;{{f2d6:e5}} 
        call    is_accumulator_a_string;{{f2d7:cd66ff}} 
        jr      z,_print_do_other_12;{{f2da:280f}}  (+$0f)
        call    prob_eval_number_to_decimal_string;{{f2dc:cd68ef}} 
        call    get_ASCIIZ_string ;{{f2df:cd8af8}} 
        ld      (hl),$20          ;{{f2e2:3620}} 
        ld      hl,(accumulator)  ;{{f2e4:2aa0b0}} 
        inc     (hl)              ;{{f2e7:34}} 
        ld      a,(hl)            ;{{f2e8:7e}} 
        jr      _print_do_other_34;{{f2e9:181f}}  (+$1f)

_print_do_other_12:               ;{{Addr=$f2eb Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(accumulator)  ;{{f2eb:2aa0b0}} 
        ld      b,(hl)            ;{{f2ee:46}} 
        ld      c,$00             ;{{f2ef:0e00}} 
        inc     hl                ;{{f2f1:23}} 
        ld      a,(hl)            ;{{f2f2:7e}} 
        inc     hl                ;{{f2f3:23}} 
        ld      h,(hl)            ;{{f2f4:66}} 
        ld      l,a               ;{{f2f5:6f}} 
        inc     b                 ;{{f2f6:04}} 
        jr      _print_do_other_32;{{f2f7:180e}}  (+$0e)

_print_do_other_22:               ;{{Addr=$f2f9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f2f9:7e}} 
        cp      $20               ;{{f2fa:fe20}} 
        inc     hl                ;{{f2fc:23}} 
        jr      nc,_print_do_other_31;{{f2fd:3007}}  (+$07)
        dec     a                 ;{{f2ff:3d}} 
        jr      nz,_print_do_other_33;{{f300:2007}}  (+$07)
        dec     b                 ;{{f302:05}} 
        jr      z,_print_do_other_33;{{f303:2804}}  (+$04)
        inc     hl                ;{{f305:23}} 
_print_do_other_31:               ;{{Addr=$f306 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{f306:0c}} 
_print_do_other_32:               ;{{Addr=$f307 Code Calls/jump count: 1 Data use count: 0}}
        djnz    _print_do_other_22;{{f307:10f0}}  (-$10)
_print_do_other_33:               ;{{Addr=$f309 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f309:79}} 
_print_do_other_34:               ;{{Addr=$f30a Code Calls/jump count: 1 Data use count: 0}}
        call    poss_validate_xpos_in_D;{{f30a:cde7c2}} 
        call    nc,output_new_line;{{f30d:d498c3}} ; new text line
        call    output_accumulator_string;{{f310:cdd0f8}} 
        pop     hl                ;{{f313:e1}} 
        pop     af                ;{{f314:f1}} 
        call    z,output_new_line ;{{f315:cc98c3}} ; new text line
        ret                       ;{{f318:c9}} 

;;+PRINT do comma
PRINT_do_comma:                   ;{{Addr=$f319 Code Calls/jump count: 0 Data use count: 1}}
        call    get_next_token_skipping_space;{{f319:cd2cde}}  get next token skipping space
        ld      a,(ZONE_value)    ;{{f31c:3a5cae}} 
        ld      c,a               ;{{f31f:4f}} 
        call    get_xpos_of_output_stream;{{f320:cdb9c2}} 
        dec     a                 ;{{f323:3d}} 
_print_do_comma_5:                ;{{Addr=$f324 Code Calls/jump count: 1 Data use count: 0}}
        sub     c                 ;{{f324:91}} 
        jr      nc,_print_do_comma_5;{{f325:30fd}}  (-$03)
        cpl                       ;{{f327:2f}} 
        inc     a                 ;{{f328:3c}} 
        ld      b,a               ;{{f329:47}} 
        add     a,c               ;{{f32a:81}} 
        call    poss_validate_xpos_in_D;{{f32b:cde7c2}} 
        jp      nc,output_new_line;{{f32e:d298c3}} ; new text line
        ld      a,b               ;{{f331:78}} 
        jr      _print_do_tab_12  ;{{f332:181e}}  (+$1e)

;;+PRINT do SPC
PRINT_do_SPC:                     ;{{Addr=$f334 Code Calls/jump count: 0 Data use count: 1}}
        call    _print_do_tab_19  ;{{f334:cd5df3}} 
        call    _print_do_tab_23  ;{{f337:cd69f3}} 
        ld      a,e               ;{{f33a:7b}} 
        jr      _print_do_tab_12  ;{{f33b:1815}}  (+$15)

;;+PRINT do TAB
PRINT_do_TAB:                     ;{{Addr=$f33d Code Calls/jump count: 0 Data use count: 1}}
        call    _print_do_tab_19  ;{{f33d:cd5df3}} 
        dec     de                ;{{f340:1b}} 
        call    _print_do_tab_23  ;{{f341:cd69f3}} 
        call    get_xpos_of_output_stream;{{f344:cdb9c2}} 
        cpl                       ;{{f347:2f}} 
        inc     a                 ;{{f348:3c}} 
        inc     e                 ;{{f349:1c}} 
        add     a,e               ;{{f34a:83}} 
        jr      c,_print_do_tab_12;{{f34b:3805}}  (+$05)
        call    output_new_line   ;{{f34d:cd98c3}} ; new text line
        dec     e                 ;{{f350:1d}} 
        ld      a,e               ;{{f351:7b}} 
_print_do_tab_12:                 ;{{Addr=$f352 Code Calls/jump count: 4 Data use count: 0}}
        ld      b,a               ;{{f352:47}} 
        inc     b                 ;{{f353:04}} 
_print_do_tab_14:                 ;{{Addr=$f354 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{f354:05}} 
        ret     z                 ;{{f355:c8}} 

        ld      a,$20             ;{{f356:3e20}}  ' '
        call    output_char       ;{{f358:cda0c3}} ; display text char
        jr      _print_do_tab_14  ;{{f35b:18f7}}  (-$09)


_print_do_tab_19:                 ;{{Addr=$f35d Code Calls/jump count: 2 Data use count: 0}}
        call    get_next_token_skipping_space;{{f35d:cd2cde}}  get next token skipping space
        call    next_token_if_open_bracket;{{f360:cd19de}}  check for open bracket
        call    eval_expr_as_int  ;{{f363:cdd8ce}}  get number
        jp      next_token_if_close_bracket;{{f366:c31dde}}  check for close bracket


_print_do_tab_23:                 ;{{Addr=$f369 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{f369:7a}} 
        rla                       ;{{f36a:17}} 
        jr      nc,_print_do_tab_27;{{f36b:3003}}  (+$03)
        ld      de,$0000          ;{{f36d:110000}} ##LIT##
_print_do_tab_27:                 ;{{Addr=$f370 Code Calls/jump count: 1 Data use count: 0}}
        call    pos_is_xpos_in_D_in_range;{{f370:cdcfc2}} 
        ret     nc                ;{{f373:d0}} 

        push    hl                ;{{f374:e5}} 
        ex      de,hl             ;{{f375:eb}} 
        ld      e,a               ;{{f376:5f}} 
        ld      d,$00             ;{{f377:1600}} 
        call    _int_modulo_6     ;{{f379:cdaedd}} 
        pop     hl                ;{{f37c:e1}} 
        ret                       ;{{f37d:c9}} 

;;=PRINT USING
PRINT_USING:                      ;{{Addr=$f37e Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{f37e:cd2cde}}  get next token skipping space
        call    eval_expr_and_error_if_not_string;{{f381:cd09cf}} 
        call    next_token_if_equals_inline_data_byte;{{f384:cd25de}} 
        defb $3b                  ;inline token to test ";"
        push    hl                ;{{f388:e5}} 
        ld      hl,(accumulator)  ;{{f389:2aa0b0}} 
        ex      (sp),hl           ;{{f38c:e3}} 
        call    eval_expression   ;{{f38d:cd62cf}} 
        xor     a                 ;{{f390:af}} 
        ld      (RAM_ae5d),a      ;{{f391:325dae}} 
_print_using_10:                  ;{{Addr=$f394 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f394:d1}} 
        push    de                ;{{f395:d5}} 
        ex      de,hl             ;{{f396:eb}} 
        ld      b,(hl)            ;{{f397:46}} 
        inc     hl                ;{{f398:23}} 
        ld      a,(hl)            ;{{f399:7e}} 
        inc     hl                ;{{f39a:23}} 
        ld      h,(hl)            ;{{f39b:66}} 
        ld      l,a               ;{{f39c:6f}} 
        ex      de,hl             ;{{f39d:eb}} 
        call    _print_using_42   ;{{f39e:cdcdf3}} 
        jp      nc,_print_using_187;{{f3a1:d2abf4}} 
_print_using_22:                  ;{{Addr=$f3a4 Code Calls/jump count: 1 Data use count: 0}}
        call    is_next_02        ;{{f3a4:cd3dde}} 
        jr      c,_print_using_32 ;{{f3a7:3811}}  (+$11)
        call    _print_using_64   ;{{f3a9:cdeff3}} 
        jr      z,_print_using_32 ;{{f3ac:280c}}  (+$0c)
        push    de                ;{{f3ae:d5}} 
        call    eval_expression   ;{{f3af:cd62cf}} 
        pop     de                ;{{f3b2:d1}} 
        call    _print_using_42   ;{{f3b3:cdcdf3}} 
        jr      nc,_print_using_10;{{f3b6:30dc}}  (-$24)
        jr      _print_using_22   ;{{f3b8:18ea}}  (-$16)

_print_using_32:                  ;{{Addr=$f3ba Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{f3ba:f5}} 
        ld      a,$ff             ;{{f3bb:3eff}} 
        ld      (RAM_ae5d),a      ;{{f3bd:325dae}} 
        call    _print_using_42   ;{{f3c0:cdcdf3}} 
        pop     af                ;{{f3c3:f1}} 
        call    c,output_new_line ;{{f3c4:dc98c3}} ; new text line
        ex      (sp),hl           ;{{f3c7:e3}} 
        call    various_get_string_from_stack_stuff;{{f3c8:cd03fc}} 
        pop     hl                ;{{f3cb:e1}} 
        ret                       ;{{f3cc:c9}} 

_print_using_42:                  ;{{Addr=$f3cd Code Calls/jump count: 3 Data use count: 0}}
        ld      a,b               ;{{f3cd:78}} 
        or      a                 ;{{f3ce:b7}} 
        ret     z                 ;{{f3cf:c8}} 

        push    hl                ;{{f3d0:e5}} 
_print_using_46:                  ;{{Addr=$f3d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f3d1:1a}} 
        cp      $5f               ;{{f3d2:fe5f}} "_"
        jr      nz,_print_using_54;{{f3d4:2007}}  (+$07)
        inc     de                ;{{f3d6:13}} 
        djnz    _print_using_57   ;{{f3d7:100c}}  (+$0c)
        inc     b                 ;{{f3d9:04}} 
        dec     de                ;{{f3da:1b}} 
        jr      _print_using_57   ;{{f3db:1808}}  (+$08)

_print_using_54:                  ;{{Addr=$f3dd Code Calls/jump count: 1 Data use count: 0}}
        call    _print_using_67   ;{{f3dd:cdf7f3}} 
        call    nc,_print_using_107;{{f3e0:d431f4}} 
        jr      c,_print_using_62 ;{{f3e3:3808}}  (+$08)
_print_using_57:                  ;{{Addr=$f3e5 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{f3e5:1a}} 
        call    output_char       ;{{f3e6:cda0c3}} ; display text char
        inc     de                ;{{f3e9:13}} 
        djnz    _print_using_46   ;{{f3ea:10e5}}  (-$1b)
        or      a                 ;{{f3ec:b7}} 
_print_using_62:                  ;{{Addr=$f3ed Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f3ed:e1}} 
        ret                       ;{{f3ee:c9}} 

_print_using_64:                  ;{{Addr=$f3ef Code Calls/jump count: 2 Data use count: 0}}
        cp      $3b               ;{{f3ef:fe3b}} ";"
        jp      z,get_next_token_skipping_space;{{f3f1:ca2cde}}  get next token skipping space
        jp      next_token_if_comma;{{f3f4:c315de}}  check for comma

_print_using_67:                  ;{{Addr=$f3f7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f3f7:1a}} 
        ld      c,$00             ;{{f3f8:0e00}} 
        cp      $26               ;{{f3fa:fe26}} "&"
        jr      z,_print_using_93 ;{{f3fc:281e}}  (+$1e)
        inc     c                 ;{{f3fe:0c}} 
        cp      $21               ;{{f3ff:fe21}} "!"
        jr      z,_print_using_93 ;{{f401:2819}}  (+$19)
        xor     $5c               ;{{f403:ee5c}} "\"
        ret     nz                ;{{f405:c0}} 

        push    bc                ;{{f406:c5}} 
        push    de                ;{{f407:d5}} 
_print_using_78:                  ;{{Addr=$f408 Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f408:13}} 
        dec     b                 ;{{f409:05}} 
        jr      z,_print_using_87 ;{{f40a:280a}}  (+$0a)
        inc     c                 ;{{f40c:0c}} 
        ld      a,(de)            ;{{f40d:1a}} 
        cp      $5c               ;{{f40e:fe5c}} "\"
        jr      z,_print_using_91 ;{{f410:2808}}  (+$08)
        cp      $20               ;{{f412:fe20}} " "
        jr      z,_print_using_78 ;{{f414:28f2}}  (-$0e)
_print_using_87:                  ;{{Addr=$f416 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f416:d1}} 
        pop     bc                ;{{f417:c1}} 
        or      a                 ;{{f418:b7}} 
        ret                       ;{{f419:c9}} 

_print_using_91:                  ;{{Addr=$f41a Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{f41a:f1}} 
        pop     af                ;{{f41b:f1}} 
_print_using_93:                  ;{{Addr=$f41c Code Calls/jump count: 2 Data use count: 0}}
        inc     de                ;{{f41c:13}} 
        dec     b                 ;{{f41d:05}} 
        push    bc                ;{{f41e:c5}} 
        push    de                ;{{f41f:d5}} 
        ld      a,(RAM_ae5d)      ;{{f420:3a5dae}} 
        or      a                 ;{{f423:b7}} 
        jr      nz,_print_using_103;{{f424:2007}}  (+$07)
        call    unknown_output_accumulator_string;{{f426:cddcf8}} 
        ld      a,c               ;{{f429:79}} 
        call    _print_do_tab_12  ;{{f42a:cd52f3}} 
_print_using_103:                 ;{{Addr=$f42d Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f42d:d1}} 
        pop     bc                ;{{f42e:c1}} 
        scf                       ;{{f42f:37}} 
        ret                       ;{{f430:c9}} 

_print_using_107:                 ;{{Addr=$f431 Code Calls/jump count: 1 Data use count: 0}}
        call    _print_using_121  ;{{f431:cd48f4}} 
        ret     nc                ;{{f434:d0}} 

        ld      a,(RAM_ae5d)      ;{{f435:3a5dae}} 
        or      a                 ;{{f438:b7}} 
        jr      nz,_print_using_119;{{f439:200b}}  (+$0b)
        push    bc                ;{{f43b:c5}} 
        push    de                ;{{f43c:d5}} 
        ld      a,c               ;{{f43d:79}} 
        call    convert_number_to_string_by_format;{{f43e:cd6aef}} 
        call    output_ASCIIZ_string;{{f441:cd8bc3}} ; display 0 terminated string
        pop     de                ;{{f444:d1}} 
        pop     bc                ;{{f445:c1}} 
_print_using_119:                 ;{{Addr=$f446 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{f446:37}} 
        ret                       ;{{f447:c9}} 

_print_using_121:                 ;{{Addr=$f448 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f448:c5}} 
        push    de                ;{{f449:d5}} 
        ld      c,$80             ;{{f44a:0e80}} 
        ld      h,$00             ;{{f44c:2600}} 
        ld      a,(de)            ;{{f44e:1a}} 
        cp      $2b               ;{{f44f:fe2b}}  '+'
        jr      nz,_print_using_133;{{f451:2007}} 
        inc     de                ;{{f453:13}} 
        dec     b                 ;{{f454:05}} 
        jr      z,_print_using_153;{{f455:2824}}  (+$24)
        inc     h                 ;{{f457:24}} 
        ld      c,$88             ;{{f458:0e88}} 
_print_using_133:                 ;{{Addr=$f45a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f45a:1a}} 
        cp      $2e               ;{{f45b:fe2e}}  '.'
        jr      z,_print_using_157;{{f45d:2820}} 
        cp      $23               ;{{f45f:fe23}}  '#'
        jr      z,_print_using_180;{{f461:283e}} 
        inc     de                ;{{f463:13}} 
        dec     b                 ;{{f464:05}} 
        jr      z,_print_using_153;{{f465:2814}}  (+$14)
        ex      de,hl             ;{{f467:eb}} 
        cp      (hl)              ;{{f468:be}} 
        ex      de,hl             ;{{f469:eb}} 
        jr      nz,_print_using_153;{{f46a:200f}}  (+$0f)
        inc     h                 ;{{f46c:24}} 
        inc     h                 ;{{f46d:24}} 
        ld      l,$04             ;{{f46e:2e04}} 
        call    _print_using_248  ;{{f470:cd02f5}} 
        jr      z,_print_using_174;{{f473:2824}}  (+$24)
        ld      l,$20             ;{{f475:2e20}} 
        cp      $2a               ;{{f477:fe2a}} 
        jr      z,_print_using_166;{{f479:2811}}  (+$11)
_print_using_153:                 ;{{Addr=$f47b Code Calls/jump count: 5 Data use count: 0}}
        pop     de                ;{{f47b:d1}} 
        pop     bc                ;{{f47c:c1}} 
        or      a                 ;{{f47d:b7}} 
        ret                       ;{{f47e:c9}} 

_print_using_157:                 ;{{Addr=$f47f Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f47f:13}} 
        dec     b                 ;{{f480:05}} 
        jr      z,_print_using_153;{{f481:28f8}}  (-$08)
        ld      a,(de)            ;{{f483:1a}} 
        cp      $23               ;{{f484:fe23}}  '#'
        jr      nz,_print_using_153;{{f486:20f3}}  (-$0d)
        dec     de                ;{{f488:1b}} 
        inc     b                 ;{{f489:04}} 
        jr      _print_using_180  ;{{f48a:1815}}  (+$15)

_print_using_166:                 ;{{Addr=$f48c Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f48c:13}} 
        dec     b                 ;{{f48d:05}} 
        jr      z,_print_using_177;{{f48e:280e}}  (+$0e)
        ld      a,(de)            ;{{f490:1a}} 
        call    _print_using_248  ;{{f491:cd02f5}} 
        jr      nz,_print_using_177;{{f494:2008}}  (+$08)
        inc     h                 ;{{f496:24}} 
        ld      l,$24             ;{{f497:2e24}} "$"
_print_using_174:                 ;{{Addr=$f499 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_ae54),a      ;{{f499:3254ae}} 
        inc     de                ;{{f49c:13}} 
        dec     b                 ;{{f49d:05}} 
_print_using_177:                 ;{{Addr=$f49e Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f49e:79}} 
        or      l                 ;{{f49f:b5}} 
        ld      c,a               ;{{f4a0:4f}} 
_print_using_180:                 ;{{Addr=$f4a1 Code Calls/jump count: 2 Data use count: 0}}
        pop     af                ;{{f4a1:f1}} 
        pop     af                ;{{f4a2:f1}} 
        call    _print_using_188  ;{{f4a3:cdaef4}} 
        ld      a,h               ;{{f4a6:7c}} 
        add     a,l               ;{{f4a7:85}} 
        cp      $15               ;{{f4a8:fe15}} 
        ret     c                 ;{{f4aa:d8}} 

_print_using_187:                 ;{{Addr=$f4ab Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{f4ab:c34dcb}}  Error: Improper Argument

_print_using_188:                 ;{{Addr=$f4ae Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{f4ae:af}} 
        ld      l,a               ;{{f4af:6f}} 
        or      b                 ;{{f4b0:b0}} 
        ret     z                 ;{{f4b1:c8}} 

_print_using_192:                 ;{{Addr=$f4b2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f4b2:1a}} 
        cp      $2e               ;{{f4b3:fe2e}}  '.'
        jr      z,_print_using_204;{{f4b5:280f}}  (+$0f)
        cp      $23               ;{{f4b7:fe23}}  '#'
        jr      z,_print_using_200;{{f4b9:2806}}  (+$06)
        cp      $2c               ;{{f4bb:fe2c}} ","
        jr      nz,_print_using_211;{{f4bd:2010}}  (+$10)
        set     1,c               ;{{f4bf:cbc9}} 
_print_using_200:                 ;{{Addr=$f4c1 Code Calls/jump count: 1 Data use count: 0}}
        inc     h                 ;{{f4c1:24}} 
        inc     de                ;{{f4c2:13}} 
        djnz    _print_using_192  ;{{f4c3:10ed}}  (-$13)
        ret                       ;{{f4c5:c9}} 

_print_using_204:                 ;{{Addr=$f4c6 Code Calls/jump count: 2 Data use count: 0}}
        inc     l                 ;{{f4c6:2c}} 
        inc     de                ;{{f4c7:13}} 
        dec     b                 ;{{f4c8:05}} 
        ret     z                 ;{{f4c9:c8}} 

        ld      a,(de)            ;{{f4ca:1a}} 
        cp      $23               ;{{f4cb:fe23}}  '#'
        jr      z,_print_using_204;{{f4cd:28f7}}  (-$09)
_print_using_211:                 ;{{Addr=$f4cf Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{f4cf:eb}} 
        push    hl                ;{{f4d0:e5}} 
        cp      $5e               ;{{f4d1:fe5e}} "^"
        jr      nz,_print_using_231;{{f4d3:2016}}  (+$16)
        inc     hl                ;{{f4d5:23}} 
        cp      (hl)              ;{{f4d6:be}} 
        jr      nz,_print_using_231;{{f4d7:2012}}  (+$12)
        inc     hl                ;{{f4d9:23}} 
        cp      (hl)              ;{{f4da:be}} 
        jr      nz,_print_using_231;{{f4db:200e}}  (+$0e)
        inc     hl                ;{{f4dd:23}} 
        cp      (hl)              ;{{f4de:be}} 
        jr      nz,_print_using_231;{{f4df:200a}}  (+$0a)
        inc     hl                ;{{f4e1:23}} 
        ld      a,b               ;{{f4e2:78}} 
        sub     $04               ;{{f4e3:d604}} 
        jr      c,_print_using_231;{{f4e5:3804}}  (+$04)
        ld      b,a               ;{{f4e7:47}} 
        ex      (sp),hl           ;{{f4e8:e3}} 
        set     6,c               ;{{f4e9:cbf1}} 
_print_using_231:                 ;{{Addr=$f4eb Code Calls/jump count: 5 Data use count: 0}}
        pop     hl                ;{{f4eb:e1}} 
        ex      de,hl             ;{{f4ec:eb}} 
        inc     b                 ;{{f4ed:04}} 
        dec     b                 ;{{f4ee:05}} 
        ret     z                 ;{{f4ef:c8}} 

        bit     3,c               ;{{f4f0:cb59}} 
        ret     nz                ;{{f4f2:c0}} 

        ld      a,(de)            ;{{f4f3:1a}} 
        cp      $2d               ;{{f4f4:fe2d}}  '-'
        jr      z,_print_using_244;{{f4f6:2805}}  
        cp      $2b               ;{{f4f8:fe2b}}  '+'
        ret     nz                ;{{f4fa:c0}} 

        set     3,c               ;{{f4fb:cbd9}} 
_print_using_244:                 ;{{Addr=$f4fd Code Calls/jump count: 1 Data use count: 0}}
        set     4,c               ;{{f4fd:cbe1}} 
        inc     de                ;{{f4ff:13}} 
        dec     b                 ;{{f500:05}} 
        ret                       ;{{f501:c9}} 

_print_using_248:                 ;{{Addr=$f502 Code Calls/jump count: 2 Data use count: 0}}
        cp      $24               ;{{f502:fe24}}  '$'
        ret     z                 ;{{f504:c8}} 

        cp      $a3               ;{{f505:fea3}}  '£' 
        ret                       ;{{f507:c9}} 

;;========================================================================
;; command WRITE
command_WRITE:                    ;{{Addr=$f508 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_BC_on_evalled_stream_and_swap_back;{{f508:cdcfc1}} 
        call    is_next_02        ;{{f50b:cd3dde}} 
        jp      c,output_new_line ;{{f50e:da98c3}} ; new text line
_command_write_3:                 ;{{Addr=$f511 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{f511:cd62cf}} 
        push    af                ;{{f514:f5}} 
        push    hl                ;{{f515:e5}} 
        call    is_accumulator_a_string;{{f516:cd66ff}} 
        jr      z,_command_write_11;{{f519:2808}}  (+$08)
        call    convert_float_atHL_to_string;{{f51b:cd5aef}} 
        call    output_ASCIIZ_string;{{f51e:cd8bc3}} ; display 0 terminated string
        jr      _command_write_16 ;{{f521:180d}}  (+$0d)

_command_write_11:                ;{{Addr=$f523 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$22             ;{{f523:3e22}} '"'
        call    output_char       ;{{f525:cda0c3}} ; display text char
        call    output_accumulator_string;{{f528:cdd0f8}} 
        ld      a,$22             ;{{f52b:3e22}} '"'
        call    output_char       ;{{f52d:cda0c3}} ; display text char
_command_write_16:                ;{{Addr=$f530 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f530:e1}} 
        pop     af                ;{{f531:f1}} 
        jp      z,output_new_line ;{{f532:ca98c3}} ; new text line
        call    _print_using_64   ;{{f535:cdeff3}} 
        ld      a,$2c             ;{{f538:3e2c}} 
        call    output_char       ;{{f53a:cda0c3}} ; display text char
        jr      _command_write_3  ;{{f53d:18d2}}  (-$2e)





;;***MemoryAllocation.asm
;;<< MEMORY ALLOCATION FUNCTIONS
;;< Includes MEMORY, SYMBOL (AFTER)
;;=======================================================

;;initialise memory model
;;sets addresses for where stuff is located in memory
;;HL=?? passed from MC_START_PROGRAM
;;DE=first byte of available memory passed from MC_START_PROGRAM
;;BC=?? passed from MC_START_PROGRAM
initialise_memory_model:          ;{{Addr=$f53f Code Calls/jump count: 1 Data use count: 0}}
        ld      bc,program_line_redundant_spaces_flag_;{{f53f:0100ac}} 
        call    compare_HL_BC     ;{{f542:cddeff}}  HL=BC?
        ret     nc                ;{{f545:d0}} 

        ld      (HIMEM_),hl       ;{{f546:225eae}}  HIMEM
        ld      (address_of_end_of_Strings_area_),hl;{{f549:2273b0}} 
        ld      (address_of_highest_byte_of_free_RAM_),hl;{{f54c:2260ae}} 
        ex      de,hl             ;{{f54f:eb}} 
        ld      (address_of_start_of_ROM_lower_reserved_a),hl;{{f550:2262ae}} start of line entry buffer
        ld      bc,$012f          ;{{f553:012f01}} length of line entry buffer (plus other stuff?)
        add     hl,bc             ;{{f556:09}} 
        ret     c                 ;{{f557:d8}} 

        ld      (address_of_end_of_ROM_lower_reserved_are),hl;{{f558:2264ae}} start of program area?
        ex      de,hl             ;{{f55b:eb}} 
        inc     hl                ;{{f55c:23}} 
        sbc     hl,de             ;{{f55d:ed52}} 
        ret     c                 ;{{f55f:d8}} 

        ld      a,h               ;{{f560:7c}} 
        cp      $04               ;{{f561:fe04}} 
        ret     c                 ;{{f563:d8}} 

        call    clear_RAMb075     ;{{f564:cd7ff7}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f567:326eae}} 
        ret                       ;{{f56a:c9}} 

;;========================================================================
;; command MEMORY

command_MEMORY:                   ;{{Addr=$f56b Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_uint ;{{f56b:cdf5ce}} 
        push    hl                ;{{f56e:e5}} 
        ld      hl,(address_of_highest_byte_of_free_RAM_);{{f56f:2a60ae}} 
        call    compare_HL_DE     ;{{f572:cdd8ff}}  HL=DE?
        jr      c,raise_memory_full_error;{{f575:3831}}  (+$31)
        inc     de                ;{{f577:13}} 
        call    compare_DE_to_HIMEM_plus_1;{{f578:cdecf5}}  compare DE with HIMEM
        call    c,_command_memory_14;{{f57b:dc8af5}} 
        ex      de,hl             ;{{f57e:eb}} 
        call    _symbol_after_18  ;{{f57f:cd08f8}} 
        ld      hl,(RAM_b076)     ;{{f582:2a76b0}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f585:2278b0}} 
        pop     hl                ;{{f588:e1}} 
        ret                       ;{{f589:c9}} 

_command_memory_14:               ;{{Addr=$f58a Code Calls/jump count: 1 Data use count: 0}}
        call    TXT_GET_M_TABLE   ;{{f58a:cdaebb}}  firmware function: TXT GET M TABLE
        ld      bc,(HIMEM_)       ;{{f58d:ed4b5eae}}  HIMEM
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f591:dce0f5}} 
        jr      c,raise_memory_full_error;{{f594:3812}}  (+$12)
        ld      hl,(RAM_b076)     ;{{f596:2a76b0}} 
        dec     hl                ;{{f599:2b}} 
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f59a:cde0f5}} 
        ret     nc                ;{{f59d:d0}} 

        ld      a,(RAM_b075)      ;{{f59e:3a75b0}} 
        or      a                 ;{{f5a1:b7}} 
        ret     z                 ;{{f5a2:c8}} 

        cp      $04               ;{{f5a3:fe04}} 
        jp      z,clear_RAMb075   ;{{f5a5:ca7ff7}} 
;;=raise memory full error
raise_memory_full_error:          ;{{Addr=$f5a8 Code Calls/jump count: 3 Data use count: 0}}
        jp      raise_memory_full_error_C;{{f5a8:c375f8}} 

_raise_memory_full_error_1:       ;{{Addr=$f5ab Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{f5ab:d5}} 
        ex      de,hl             ;{{f5ac:eb}} 
        add     hl,bc             ;{{f5ad:09}} 
        dec     hl                ;{{f5ae:2b}} 
        ld      bc,(address_of_start_of_ROM_lower_reserved_a);{{f5af:ed4b62ae}} input buffer address
        ex      (sp),hl           ;{{f5b3:e3}} 
        ex      de,hl             ;{{f5b4:eb}} 
        ld      hl,(HIMEM_)       ;{{f5b5:2a5eae}}  HIMEM
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f5b8:cde0f5}} 
        ex      de,hl             ;{{f5bb:eb}} 
        ex      (sp),hl           ;{{f5bc:e3}} 
        ex      de,hl             ;{{f5bd:eb}} 
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f5be:dce0f5}} 
        jr      nc,raise_memory_full_error;{{f5c1:30e5}}  (-$1b)
        ld      bc,(RAM_b076)     ;{{f5c3:ed4b76b0}} 
        ld      hl,$0fff          ;{{f5c7:21ff0f}} 
        add     hl,bc             ;{{f5ca:09}} 
        call    compare_HL_minus_BC_to_DE_minus_BC;{{f5cb:cde0f5}} 
        pop     de                ;{{f5ce:d1}} 
        call    c,compare_HL_minus_BC_to_DE_minus_BC;{{f5cf:dce0f5}} 
        ret     c                 ;{{f5d2:d8}} 

        ex      de,hl             ;{{f5d3:eb}} 
        ld      d,b               ;{{f5d4:50}} 
        ld      e,c               ;{{f5d5:59}} 
        call    compare_DE_to_HIMEM_plus_1;{{f5d6:cdecf5}}  compare DE with HIMEM
        jp      nz,clear_RAMb075  ;{{f5d9:c27ff7}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f5dc:2278b0}} 
        ret                       ;{{f5df:c9}} 

;;=========================
;;compare HL minus BC to DE minus BC
compare_HL_minus_BC_to_DE_minus_BC:;{{Addr=$f5e0 Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{f5e0:d5}} 
        push    hl                ;{{f5e1:e5}} 
        or      a                 ;{{f5e2:b7}} 
        sbc     hl,bc             ;{{f5e3:ed42}} 
        ex      de,hl             ;{{f5e5:eb}} 
        or      a                 ;{{f5e6:b7}} 
        sbc     hl,bc             ;{{f5e7:ed42}} 
        ex      de,hl             ;{{f5e9:eb}} 
        jr      _compare_de_to_himem_plus_1_4;{{f5ea:1806}}  (+$06)

;;===========================
;;=compare DE to HIMEM plus 1
compare_DE_to_HIMEM_plus_1:       ;{{Addr=$f5ec Code Calls/jump count: 4 Data use count: 0}}
        push    de                ;{{f5ec:d5}} 
        push    hl                ;{{f5ed:e5}} 
        ld      hl,(HIMEM_)       ;{{f5ee:2a5eae}}  HIMEM
        inc     hl                ;{{f5f1:23}} 
_compare_de_to_himem_plus_1_4:    ;{{Addr=$f5f2 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_DE     ;{{f5f2:cdd8ff}}  HL=DE?
        pop     hl                ;{{f5f5:e1}} 
        pop     de                ;{{f5f6:d1}} 
        ret                       ;{{f5f7:c9}} 

;;==========================
;;=get size of strings area in BC
get_size_of_strings_area_in_BC:   ;{{Addr=$f5f8 Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{f5f8:d5}} 
        push    hl                ;{{f5f9:e5}} 
        ld      hl,(address_of_end_of_free_space_);{{f5fa:2a71b0}} 
        ex      de,hl             ;{{f5fd:eb}} 
        ld      hl,(address_of_end_of_Strings_area_);{{f5fe:2a73b0}} 
        call    BC_equal_HL_minus_DE;{{f601:cde4ff}}  BC = HL-DE
        pop     hl                ;{{f604:e1}} 
        pop     de                ;{{f605:d1}} 
        ret                       ;{{f606:c9}} 

;;=prob grow all program space pointers by BC
prob_grow_all_program_space_pointers_by_BC:;{{Addr=$f607 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_after_end_of_program);{{f607:2a66ae}} 
        add     hl,bc             ;{{f60a:09}} 
        ld      (address_after_end_of_program),hl;{{f60b:2266ae}} 
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f60e:3a6eae}} 
        or      a                 ;{{f611:b7}} 
        ret     nz                ;{{f612:c0}} 

;;=prob grow program space ptrs by BC
;;(but DOESN'T do any memory moving)
prob_grow_program_space_ptrs_by_BC:;{{Addr=$f613 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f613:2a68ae}} 
        add     hl,bc             ;{{f616:09}} 
        ld      (address_of_start_of_Variables_and_DEF_FN),hl;{{f617:2268ae}} 
;;=prob grow variables space ptrs by BC
prob_grow_variables_space_ptrs_by_BC:;{{Addr=$f61a Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_Arrays_area_);{{f61a:2a6aae}} 
        add     hl,bc             ;{{f61d:09}} 
        ld      (address_of_start_of_Arrays_area_),hl;{{f61e:226aae}} 
;;=prob grow array space ptrs by BC
prob_grow_array_space_ptrs_by_BC: ;{{Addr=$f621 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f621:2a6cae}} 
        add     hl,bc             ;{{f624:09}} 
        ld      (address_of_start_of_free_space_),hl;{{f625:226cae}} 
        ret                       ;{{f628:c9}} 

;;==============================
;;prob move vars and arrays to end of memory
prob_move_vars_and_arrays_to_end_of_memory:;{{Addr=$f629 Code Calls/jump count: 3 Data use count: 0}}
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{f629:cdfcf6}} 
        ld      b,h               ;{{f62c:44}} 
        ld      c,l               ;{{f62d:4d}} 
        ld      hl,(address_after_end_of_program);{{f62e:2a66ae}} 
        ex      de,hl             ;{{f631:eb}} 
        call    unknown_alloc_and_move_memory_up;{{f632:cdb8f6}} 
        ld      a,$ff             ;{{f635:3eff}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f637:326eae}} 
        jr      prob_grow_program_space_ptrs_by_BC;{{f63a:18d7}}  (-$29)

;;=============================
;;prob move vars and arrays back from end of memory
prob_move_vars_and_arrays_back_from_end_of_memory:;{{Addr=$f63c Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{f63c:af}} 
        ld      (vars_and_data_at_end_of_memory_flag),a;{{f63d:326eae}} 
        ld      hl,(address_after_end_of_program);{{f640:2a66ae}} 
        ex      de,hl             ;{{f643:eb}} 
        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f644:2a68ae}} 
        call    BC_equal_HL_minus_DE;{{f647:cde4ff}}  BC = HL-DE
        call    move_lower_memory_down;{{f64a:cde5f6}} 
        jr      prob_grow_program_space_ptrs_by_BC;{{f64d:18c4}}  (-$3c)

;;==============================
;;prob clear execution stack
prob_clear_execution_stack:       ;{{Addr=$f64f Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$ae6f          ;{{f64f:216fae}} 
        ld      (execution_stack_next_free_ptr),hl;{{f652:226fb0}} 
        ld      a,$01             ;{{f655:3e01}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{f657:cd72f6}} 
        ld      (hl),$00          ;{{f65a:3600}} 
        inc     hl                ;{{f65c:23}} 

;;=set execution stack next free ptr and its cache
set_execution_stack_next_free_ptr_and_its_cache:;{{Addr=$f65d Code Calls/jump count: 9 Data use count: 0}}
        ld      (cache_of_execution_stack_next_free_ptr),hl;{{f65d:2219ae}} 
        jr      set_execution_stack_next_free_ptr;{{f660:180c}}  (+$0c)

;;======================================
;;probably remove A bytes off execution stack and get address
probably_remove_A_bytes_off_execution_stack_and_get_address:;{{Addr=$f662 Code Calls/jump count: 6 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{f662:2a6fb0}} 
        cpl                       ;{{f665:2f}} 
        inc     a                 ;{{f666:3c}} 
        ret     z                 ;{{f667:c8}} 

        add     a,l               ;{{f668:85}} 
        ld      l,a               ;{{f669:6f}} 
        ld      a,$ff             ;{{f66a:3eff}} 
        adc     a,h               ;{{f66c:8c}} 
        ld      h,a               ;{{f66d:67}} 

;;=set execution stack next free ptr
set_execution_stack_next_free_ptr:;{{Addr=$f66e Code Calls/jump count: 5 Data use count: 0}}
        ld      (execution_stack_next_free_ptr),hl;{{f66e:226fb0}} 
        ret                       ;{{f671:c9}} 

;;===================================
;;possibly alloc A bytes on execution stack
possibly_alloc_A_bytes_on_execution_stack:;{{Addr=$f672 Code Calls/jump count: 10 Data use count: 0}}
        ld      hl,(execution_stack_next_free_ptr);{{f672:2a6fb0}} 
        push    hl                ;{{f675:e5}} 
        add     a,l               ;{{f676:85}}  HL = HL + A?
        ld      l,a               ;{{f677:6f}} 
        adc     a,h               ;{{f678:8c}} 
        sub     l                 ;{{f679:95}} 
        ld      h,a               ;{{f67a:67}} 
        ld      (execution_stack_next_free_ptr),hl;{{f67b:226fb0}} 
        ld      a,$94             ;{{f67e:3e94}} check for stack overflow???   
        add     a,l               ;{{f680:85}} 
        ld      a,$4f             ;{{f681:3e4f}} 
        adc     a,h               ;{{f683:8c}} 
        pop     hl                ;{{f684:e1}} 
        ret     nc                ;{{f685:d0}} 

        call    prob_clear_execution_stack;{{f686:cd4ff6}} 
        jp      raise_memory_full_error_C;{{f689:c375f8}} 

;;==================================
;;empty strings area
empty_strings_area:               ;{{Addr=$f68c Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_Strings_area_);{{f68c:2a73b0}} 
        ld      (address_of_end_of_free_space_),hl;{{f68f:2271b0}} 
        ret                       ;{{f692:c9}} 

;;==============================
;;alloc C bytes in string space
alloc_C_bytes_in_string_space:    ;{{Addr=$f693 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,$00             ;{{f693:0600}} 
;;=alloc BC bytes in string space
alloc_BC_bytes_in_string_space:   ;{{Addr=$f695 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f695:2a6cae}} 
        ex      de,hl             ;{{f698:eb}} 
        ld      hl,(address_of_end_of_free_space_);{{f699:2a71b0}} 
        or      a                 ;{{f69c:b7}} 
        sbc     hl,bc             ;{{f69d:ed42}} 
        dec     hl                ;{{f69f:2b}} 
        dec     hl                ;{{f6a0:2b}} 
        call    compare_HL_DE     ;{{f6a1:cdd8ff}}  HL=DE?
        jr      nc,poss_alloc_and_write_string_pointer;{{f6a4:3009}}  (+$09)
        call    _function_fre_6   ;{{f6a6:cd64fc}} 
        jr      c,alloc_BC_bytes_in_string_space;{{f6a9:38ea}}  (-$16)
        call    byte_following_call_is_error_code;{{f6ab:cd45cb}} 
        defb $0e                  ;Inline error code: String Space Full error

;;===============================
;;poss alloc and write string pointer
poss_alloc_and_write_string_pointer:;{{Addr=$f6af Code Calls/jump count: 1 Data use count: 0}}
        ld (address_of_end_of_free_space_),hl;{{f6af:2271b0}} 
        inc     hl                ;{{f6b2:23}} 
        ld      (hl),c            ;{{f6b3:71}} 
        inc     hl                ;{{f6b4:23}} 
        ld      (hl),b            ;{{f6b5:70}} 
        inc     hl                ;{{f6b6:23}} 
        ret                       ;{{f6b7:c9}} 

;;================================
;;unknown alloc and move memory up
;I think this moves memory between DE and HL up by BC bytes
unknown_alloc_and_move_memory_up: ;{{Addr=$f6b8 Code Calls/jump count: 4 Data use count: 0}}
        call    get_start_of_free_space;{{f6b8:cd14f7}} 
_unknown_alloc_and_move_memory_up_1:;{{Addr=$f6bb Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f6bb:c5}} 
        push    de                ;{{f6bc:d5}} 
        push    de                ;{{f6bd:d5}} 
        push    hl                ;{{f6be:e5}} 
        add     hl,bc             ;{{f6bf:09}} 
        jr      c,raise_memory_full_error_B;{{f6c0:380e}}  (+$0e)
        ex      de,hl             ;{{f6c2:eb}} 
_unknown_alloc_and_move_memory_up_8:;{{Addr=$f6c3 Code Calls/jump count: 1 Data use count: 0}}
        call    get_end_of_free_space_or_start_of_variables;{{f6c3:cd07f7}} 
        call    compare_HL_DE     ;{{f6c6:cdd8ff}}  HL=DE?
        jr      nc,move_lower_memory_up;{{f6c9:3008}}  (+$08)
        call    _function_fre_6   ;{{f6cb:cd64fc}} 
        jr      c,_unknown_alloc_and_move_memory_up_8;{{f6ce:38f3}}  (-$0d)
;;=raise Memory Full error
raise_memory_full_error_B:        ;{{Addr=$f6d0 Code Calls/jump count: 1 Data use count: 0}}
        jp      raise_memory_full_error_C;{{f6d0:c375f8}} 

;;=================================
;;move lower memory up
move_lower_memory_up:             ;{{Addr=$f6d3 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f6d3:e1}} 
        pop     bc                ;{{f6d4:c1}} 
        push    de                ;{{f6d5:d5}} 
        ld      a,l               ;{{f6d6:7d}} BC=HL-BC
        sub     c                 ;{{f6d7:91}} 
        ld      c,a               ;{{f6d8:4f}} 
        ld      a,h               ;{{f6d9:7c}} 
        sbc     a,b               ;{{f6da:98}} 
        ld      b,a               ;{{f6db:47}} 
        dec     hl                ;{{f6dc:2b}} 
        dec     de                ;{{f6dd:1b}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f6de:cdf5ff}}  copy bytes LDDR (BC = count)
        pop     hl                ;{{f6e1:e1}} 
        pop     de                ;{{f6e2:d1}} 
        pop     bc                ;{{f6e3:c1}} 
        ret                       ;{{f6e4:c9}} 

;;===================================
;;move lower memory down
move_lower_memory_down:           ;{{Addr=$f6e5 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{f6e5:c5}} 
        push    de                ;{{f6e6:d5}} 
        ex      de,hl             ;{{f6e7:eb}} DE=DE+BC
        add     hl,bc             ;{{f6e8:09}} 
        ex      de,hl             ;{{f6e9:eb}} 
        call    get_start_of_free_space;{{f6ea:cd14f7}} 
        call    BC_equal_HL_minus_DE;{{f6ed:cde4ff}}  BC = HL-DE
        ex      de,hl             ;{{f6f0:eb}} 
        pop     de                ;{{f6f1:d1}} 
        call    copy_bytes_LDIR_BCcount_HLsource_DEdest;{{f6f2:cdefff}}  copy bytes LDIR (BC = count)
        pop     de                ;{{f6f5:d1}} 
        ld      hl,RESET_ENTRY    ;{{f6f6:210000}} 
        jp      BC_equal_HL_minus_DE;{{f6f9:c3e4ff}}  BC = HL-DE

;;============================
;;get free space byte count in HL addr in DE
get_free_space_byte_count_in_HL_addr_in_DE:;{{Addr=$f6fc Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(address_of_start_of_free_space_);{{f6fc:2a6cae}} 
        ex      de,hl             ;{{f6ff:eb}} 
        ld      hl,(address_of_end_of_free_space_);{{f700:2a71b0}} 
        or      a                 ;{{f703:b7}} 
        sbc     hl,de             ;{{f704:ed52}} 
        ret                       ;{{f706:c9}} 

;;==============================
;;get end of free space or start of variables
get_end_of_free_space_or_start_of_variables:;{{Addr=$f707 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f707:3a6eae}} 
        or      a                 ;{{f70a:b7}} 
        ld      hl,(address_of_end_of_free_space_);{{f70b:2a71b0}} 
        ret     z                 ;{{f70e:c8}} 

        ld      hl,(address_of_start_of_Variables_and_DEF_FN);{{f70f:2a68ae}} 
        dec     hl                ;{{f712:2b}} 
        ret                       ;{{f713:c9}} 

;;==================================
;;get start of free space
get_start_of_free_space:          ;{{Addr=$f714 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(vars_and_data_at_end_of_memory_flag);{{f714:3a6eae}} 
        or      a                 ;{{f717:b7}} 
        ld      hl,(address_of_start_of_free_space_);{{f718:2a6cae}} 
        ret     z                 ;{{f71b:c8}} 

        ld      hl,(address_after_end_of_program);{{f71c:2a66ae}} 
        ret                       ;{{f71f:c9}} 

;;=prob alloc 2k file buffer
prob_alloc_2k_file_buffer:        ;{{Addr=$f720 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0001          ;{{f720:110100}} 
        jr      _prob_alloc_2k_file_buffer_c_1;{{f723:1808}}  (+$08)

;;=prob alloc 2k file buffer
prob_alloc_2k_file_buffer_B:      ;{{Addr=$f725 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,$0802          ;{{f725:110208}} 
        jr      _prob_alloc_2k_file_buffer_c_1;{{f728:1803}}  (+$03)

;;=prob alloc 2k file buffer
;returns address in DE
prob_alloc_2k_file_buffer_C:      ;{{Addr=$f72a Code Calls/jump count: 2 Data use count: 0}}
        ld      de,$0800          ;{{f72a:110008}} 
_prob_alloc_2k_file_buffer_c_1:   ;{{Addr=$f72d Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f72d:c5}} 
        push    hl                ;{{f72e:e5}} 
        ld      a,(RAM_b075)      ;{{f72f:3a75b0}} 
        or      a                 ;{{f732:b7}} 
        jr      nz,_prob_alloc_2k_file_buffer_c_17;{{f733:2018}}  (+$18)
        push    de                ;{{f735:d5}} 
        ld      hl,(HIMEM_)       ;{{f736:2a5eae}}  HIMEM
        inc     hl                ;{{f739:23}} 
        ld      (address_of_the_highest_byte_of_free_RAM_),hl;{{f73a:2278b0}} 
        ld      de,$f000          ;{{f73d:1100f0}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{f740:19}} 
        jp      nc,raise_memory_full_error_C;{{f741:d275f8}} 
        call    _symbol_after_18  ;{{f744:cd08f8}} 
        ld      (RAM_b076),hl     ;{{f747:2276b0}} 
        pop     de                ;{{f74a:d1}} 
        ld      a,$04             ;{{f74b:3e04}} 
_prob_alloc_2k_file_buffer_c_17:  ;{{Addr=$f74d Code Calls/jump count: 1 Data use count: 0}}
        or      e                 ;{{f74d:b3}} 
        ld      hl,(RAM_b076)     ;{{f74e:2a76b0}} 
        ld      e,$00             ;{{f751:1e00}} 
        add     hl,de             ;{{f753:19}} 
        ex      de,hl             ;{{f754:eb}} 
        pop     hl                ;{{f755:e1}} 
        pop     bc                ;{{f756:c1}} 
        jr      set_RAMb075       ;{{f757:1827}}  (+$27)

;;=prob release 2k file buffer
prob_release_2k_file_buffer:      ;{{Addr=$f759 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$fe             ;{{f759:3efe}} 
        jr      _prob_release_2k_file_buffer_c_1;{{f75b:1806}}  (+$06)

;;=prob release 2k file buffer
prob_release_2k_file_buffer_B:    ;{{Addr=$f75d Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$fd             ;{{f75d:3efd}} 
        jr      _prob_release_2k_file_buffer_c_1;{{f75f:1802}}  (+$02)

;;=prob release 2k file buffer
;DE=address
prob_release_2k_file_buffer_C:    ;{{Addr=$f761 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$ff             ;{{f761:3eff}} 
_prob_release_2k_file_buffer_c_1: ;{{Addr=$f763 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{f763:e5}} 
        ld      hl,RAM_b075       ;{{f764:2175b0}} 
        and     (hl)              ;{{f767:a6}} 
        ld      (hl),a            ;{{f768:77}} 
        cp      $04               ;{{f769:fe04}} 
        jr      nz,_prob_release_2k_file_buffer_c_11;{{f76b:2009}}  (+$09)
        ld      hl,(RAM_b076)     ;{{f76d:2a76b0}} 
        ex      de,hl             ;{{f770:eb}} 
        call    compare_DE_to_HIMEM_plus_1;{{f771:cdecf5}}  compare DE with HIMEM
        jr      z,_prob_release_2k_file_buffer_c_13;{{f774:2802}}  (+$02)
_prob_release_2k_file_buffer_c_11:;{{Addr=$f776 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f776:e1}} 
        ret                       ;{{f777:c9}} 

_prob_release_2k_file_buffer_c_13:;{{Addr=$f778 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_the_highest_byte_of_free_RAM_);{{f778:2a78b0}} 
        call    _symbol_after_18  ;{{f77b:cd08f8}} 
        pop     hl                ;{{f77e:e1}} 

;;=clear RAM_b075
clear_RAMb075:                    ;{{Addr=$f77f Code Calls/jump count: 3 Data use count: 0}}
        xor     a                 ;{{f77f:af}} 
;;=set RAM_b075
set_RAMb075:                      ;{{Addr=$f780 Code Calls/jump count: 1 Data use count: 0}}
        ld      (RAM_b075),a      ;{{f780:3275b0}} 
        ret                       ;{{f783:c9}} 

;;========================================================================
;; command SYMBOL
command_SYMBOL:                   ;{{Addr=$f784 Code Calls/jump count: 0 Data use count: 1}}
        cp      $80               ;{{f784:fe80}}  AFTER
        jr      z,_command_symbol_26;{{f786:2829}}  (+$29)
        call    eval_expr_as_byte_or_error;{{f788:cdb8ce}}  get number and check it's less than 255 
        ld      c,a               ;{{f78b:4f}} 
        call    next_token_if_comma;{{f78c:cd15de}}  check for comma
        ld      b,$08             ;{{f78f:0608}} 
        scf                       ;{{f791:37}} 
_command_symbol_7:                ;{{Addr=$f792 Code Calls/jump count: 1 Data use count: 0}}
        call    nc,next_token_if_prev_is_comma;{{f792:d441de}} 
        sbc     a,a               ;{{f795:9f}} 
        call    c,eval_expr_as_byte_or_error;{{f796:dcb8ce}}  get number and check it's less than 255 
        push    af                ;{{f799:f5}} 
        or      a                 ;{{f79a:b7}} 
        djnz    _command_symbol_7 ;{{f79b:10f5}}  (-$0b)
        ex      de,hl             ;{{f79d:eb}} 
        ld      a,c               ;{{f79e:79}} 
        call    TXT_GET_MATRIX    ;{{f79f:cda5bb}}  firmware function: TXT GET MATRIX		
        jp      nc,Error_Improper_Argument;{{f7a2:d24dcb}}  Error: Improper Argument
        ld      bc,LOW_JUMP       ;{{f7a5:010800}} 
        add     hl,bc             ;{{f7a8:09}} 
_command_symbol_19:               ;{{Addr=$f7a9 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{f7a9:f1}} 
        dec     hl                ;{{f7aa:2b}} 
        ld      (hl),a            ;{{f7ab:77}} 
        dec     c                 ;{{f7ac:0d}} 
        jr      nz,_command_symbol_19;{{f7ad:20fa}}  (-$06)
        ex      de,hl             ;{{f7af:eb}} 
        ret                       ;{{f7b0:c9}} 

_command_symbol_26:               ;{{Addr=$f7b1 Code Calls/jump count: 1 Data use count: 0}}
        call    get_next_token_skipping_space;{{f7b1:cd2cde}}  get next token skipping space
        call    eval_expr_as_int  ;{{f7b4:cdd8ce}}  get number
        push    hl                ;{{f7b7:e5}} 
        ld      hl,$0100          ;{{f7b8:210001}} 
        call    compare_HL_DE     ;{{f7bb:cdd8ff}}  HL=DE?
        jp      c,Error_Improper_Argument;{{f7be:da4dcb}}  Error: Improper Argument
        push    de                ;{{f7c1:d5}} 
        call    TXT_GET_M_TABLE   ;{{f7c2:cdaebb}}  firmware function: TXT GET M TABLE
        ex      de,hl             ;{{f7c5:eb}} 
        jr      nc,_command_symbol_50;{{f7c6:301b}}  (+$1b)
;; A = first character
;; HL = address of table
        cpl                       ;{{f7c8:2f}} 
        ld      l,a               ;{{f7c9:6f}} 
        ld      h,$00             ;{{f7ca:2600}} 
        inc     hl                ;{{f7cc:23}} 
        add     hl,hl             ;{{f7cd:29}}  x2
        add     hl,hl             ;{{f7ce:29}}  x4
        add     hl,hl             ;{{f7cf:29}}  x8
        call    compare_DE_to_HIMEM_plus_1;{{f7d0:cdecf5}}  compare DE with HIMEM
        jp      nz,Error_Improper_Argument;{{f7d3:c24dcb}}  Error: Improper Argument
        add     hl,de             ;{{f7d6:19}} 
        call    _symbol_after_18  ;{{f7d7:cd08f8}} 
        call    prob_release_2k_file_buffer_C;{{f7da:cd61f7}} 
                                  ; HL = Address of table
        ld      de,$0100          ;{{f7dd:110001}}  first character in table
        call    TXT_SET_M_TABLE   ;{{f7e0:cdabbb}}  firmware function: TXT SET M TABLE
_command_symbol_50:               ;{{Addr=$f7e3 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f7e3:d1}} 
        call    SYMBOL_AFTER      ;{{f7e4:cde9f7}}  no defined table
        pop     hl                ;{{f7e7:e1}} 
        ret                       ;{{f7e8:c9}} 

;;+-------------
;; SYMBOL AFTER
;; A = number
SYMBOL_AFTER:                     ;{{Addr=$f7e9 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,$0100          ;{{f7e9:210001}} 
        or      a                 ;{{f7ec:b7}} 
        sbc     hl,de             ;{{f7ed:ed52}} 
        ret     z                 ;{{f7ef:c8}} 

        push    de                ;{{f7f0:d5}} 
        add     hl,hl             ;{{f7f1:29}} 
        add     hl,hl             ;{{f7f2:29}} 
        add     hl,hl             ;{{f7f3:29}} 
        ex      de,hl             ;{{f7f4:eb}} 
        ld      hl,(HIMEM_)       ;{{f7f5:2a5eae}}  HIMEM
        sbc     hl,de             ;{{f7f8:ed52}} 
        ld      a,h               ;{{f7fa:7c}} 
        cp      $40               ;{{f7fb:fe40}} 
        jp      c,raise_memory_full_error_C;{{f7fd:da75f8}} 
        inc     hl                ;{{f800:23}} 
        call    _symbol_after_18  ;{{f801:cd08f8}} 
        pop     de                ;{{f804:d1}} 
        jp      TXT_SET_M_TABLE   ;{{f805:c3abbb}}  firmware function: TXT SET M TABLE


_symbol_after_18:                 ;{{Addr=$f808 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{f808:e5}} 
        call    _function_fre_6   ;{{f809:cd64fc}} 
        ex      de,hl             ;{{f80c:eb}} 
        call    get_size_of_strings_area_in_BC;{{f80d:cdf8f5}} 
        ld      hl,(address_of_start_of_free_space_);{{f810:2a6cae}} 
        add     hl,bc             ;{{f813:09}} 
        ccf                       ;{{f814:3f}} 
        call    c,compare_HL_DE   ;{{f815:dcd8ff}}  HL=DE?
        jr      nc,raise_memory_full_error_C;{{f818:305b}}  (+$5b)
        ld      hl,(HIMEM_)       ;{{f81a:2a5eae}}  HIMEM
        ex      de,hl             ;{{f81d:eb}} 
        scf                       ;{{f81e:37}} 
        sbc     hl,de             ;{{f81f:ed52}} 
        ld      (RAM_b07a),hl     ;{{f821:227ab0}} 
        push    hl                ;{{f824:e5}} 
        ld      de,_symbol_after_72;{{f825:1165f8}}   ##LABEL##
        call    iterate_all_string_variables;{{f828:cd93da}} 
        pop     bc                ;{{f82b:c1}} 
        ld      a,b               ;{{f82c:78}} 
        rlca                      ;{{f82d:07}} 
        jr      c,_symbol_after_51;{{f82e:3814}}  (+$14)
        or      c                 ;{{f830:b1}} 
        jr      z,_symbol_after_67;{{f831:282b}}  (+$2b)
        ld      hl,(address_of_end_of_Strings_area_);{{f833:2a73b0}} 
        ld      d,h               ;{{f836:54}} 
        ld      e,l               ;{{f837:5d}} 
        add     hl,bc             ;{{f838:09}} 
        push    hl                ;{{f839:e5}} 
        call    get_size_of_strings_area_in_BC;{{f83a:cdf8f5}} 
        ex      de,hl             ;{{f83d:eb}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{f83e:cdf5ff}}  copy bytes LDDR (BC = count)
        pop     hl                ;{{f841:e1}} 
        jr      _symbol_after_64  ;{{f842:1813}}  (+$13)

_symbol_after_51:                 ;{{Addr=$f844 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_of_end_of_free_space_);{{f844:2a71b0}} 
        ld      d,h               ;{{f847:54}} 
        ld      e,l               ;{{f848:5d}} 
        add     hl,bc             ;{{f849:09}} 
        push    hl                ;{{f84a:e5}} 
        call    get_size_of_strings_area_in_BC;{{f84b:cdf8f5}} 
        ex      de,hl             ;{{f84e:eb}} 
        inc     hl                ;{{f84f:23}} 
        inc     de                ;{{f850:13}} 
        call    copy_bytes_LDIR_BCcount_HLsource_DEdest;{{f851:cdefff}}  copy bytes LDIR (BC = count)
        ex      de,hl             ;{{f854:eb}} 
        dec     hl                ;{{f855:2b}} 
        pop     de                ;{{f856:d1}} 
_symbol_after_64:                 ;{{Addr=$f857 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_of_end_of_Strings_area_),hl;{{f857:2273b0}} 
        ex      de,hl             ;{{f85a:eb}} 
        ld      (address_of_end_of_free_space_),hl;{{f85b:2271b0}} 
_symbol_after_67:                 ;{{Addr=$f85e Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f85e:e1}} 
        dec     hl                ;{{f85f:2b}} 
        ld      (HIMEM_),hl       ;{{f860:225eae}}  HIMEM
        inc     hl                ;{{f863:23}} 
        ret                       ;{{f864:c9}} 

_symbol_after_72:                 ;{{Addr=$f865 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_after_end_of_program);{{f865:2a66ae}} 
        call    compare_HL_BC     ;{{f868:cddeff}}  HL=BC?
        ret     nc                ;{{f86b:d0}} 

        ld      hl,(RAM_b07a)     ;{{f86c:2a7ab0}} 
        add     hl,bc             ;{{f86f:09}} 
        ex      de,hl             ;{{f870:eb}} 
        ld      (hl),d            ;{{f871:72}} 
        dec     hl                ;{{f872:2b}} 
        ld      (hl),e            ;{{f873:73}} 
        ret                       ;{{f874:c9}} 

;;=raise Memory Full error
raise_memory_full_error_C:        ;{{Addr=$f875 Code Calls/jump count: 6 Data use count: 0}}
        call    byte_following_call_is_error_code;{{f875:cd45cb}} 
        defb $07                  ;Inline error code: Memory full






;;***Strings.asm
;;<< STRING MANIPULATION
;;< and string$ and string related functions (LEN, ASC etc)
;;< also FRE and some (unexplored) memory management stuff
;;===================================================================
;; get quoted string
;; returns with HL at end of string and B=length
get_quoted_string:                ;{{Addr=$f879 Code Calls/jump count: 3 Data use count: 0}}
        inc     hl                ;{{f879:23}} 
        call    string_getter     ;{{f87a:cda7f8}} 

_get_quoted_string_2:             ;{{Addr=$f87d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f87d:7e}}  read character
        cp      $22               ;{{f87e:fe22}}  double quote
        jp      z,get_next_token_skipping_space;{{f880:ca2cde}}  get next token skipping space
        or      a                 ;{{f883:b7}}  end of line marker
        jr      z,right_trim_and_return;{{f884:2831}} 
        inc     b                 ;{{f886:04}}  increment number of characters
        inc     hl                ;{{f887:23}}  increment pointer
        jr      _get_quoted_string_2;{{f888:18f3}}  

;;+---------------------------------------------------------------------------
;;get ASCIIZ string
get_ASCIIZ_string:                ;{{Addr=$f88a Code Calls/jump count: 3 Data use count: 0}}
        call    string_getter     ;{{f88a:cda7f8}} 

_get_asciiz_string_1:             ;{{Addr=$f88d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f88d:7e}} 
        or      a                 ;{{f88e:b7}} 
        ret     z                 ;{{f88f:c8}} return directly to string getter

        inc     hl                ;{{f890:23}} 
        inc     b                 ;{{f891:04}} 
        jr      _get_asciiz_string_1;{{f892:18f9}}  (-$07)

;;+-------------------------------------------------------------
;;get string until $00, comma or value in A
;; returns with HL at end of string and B=length
get_string_until_00_comma_or_value_in_A:;{{Addr=$f894 Code Calls/jump count: 1 Data use count: 0}}
        call    string_getter     ;{{f894:cda7f8}} 

        ld      c,a               ;{{f897:4f}} 
_get_string_until_00_comma_or_value_in_a_2:;{{Addr=$f898 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f898:7e}} 
        or      a                 ;{{f899:b7}} 
        jr      z,right_trim_and_return;{{f89a:281b}}  (+$1b)
        cp      c                 ;{{f89c:b9}} 
        jr      z,right_trim_and_return;{{f89d:2818}}  (+$18)
        cp      $2c               ;{{f89f:fe2c}} ","
        jr      z,right_trim_and_return;{{f8a1:2814}}  (+$14)
        inc     hl                ;{{f8a3:23}} 
        inc     b                 ;{{f8a4:04}} 
        jr      _get_string_until_00_comma_or_value_in_a_2;{{f8a5:18f1}}  (-$0f)

;;=string getter
;;get string using following code segment as subroutine
;;HL points to data (string)
string_getter:                    ;{{Addr=$f8a7 Code Calls/jump count: 3 Data use count: 0}}
        ld      (address_of_last_String_used),hl;{{f8a7:229db0}} 
        pop     de                ;{{f8aa:d1}} 
        ld      b,$00             ;{{f8ab:0600}}  B = string length
        call    JP_DE             ;{{f8ad:cdfeff}}  JP (DE) call get string subroutine
        ld      a,b               ;{{f8b0:78}}  Only the ASCIIZ variant returns here
        ld      (length_of_last_String_used),a;{{f8b1:329cb0}} 
        jp      push_last_string_on_string_stack;{{f8b4:c3d6fb}} $b09d = start of string. 
                                  ;$b09c, A and B equal length 
                                  ;HL = next byte after string (and after whitespace)
                                        

;;=right trim and return
;;remove whitespace from end of string
right_trim_and_return:            ;{{Addr=$f8b7 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{f8b7:e5}} 
        inc     b                 ;{{f8b8:04}} 
;;=right trim loop
right_trim_loop:                  ;{{Addr=$f8b9 Code Calls/jump count: 4 Data use count: 0}}
        dec     b                 ;{{f8b9:05}} remove character from end of string
        jr      z,_right_trim_loop_12;{{f8ba:2812}}  (+$12) length = zero?
        dec     hl                ;{{f8bc:2b}} 
        ld      a,(hl)            ;{{f8bd:7e}} 
        cp      $20               ;{{f8be:fe20}} " "
        jr      z,right_trim_loop ;{{f8c0:28f7}}  (-$09)
        cp      $09               ;{{f8c2:fe09}} TAB
        jr      z,right_trim_loop ;{{f8c4:28f3}}  (-$0d)
        cp      $0d               ;{{f8c6:fe0d}}  carriage return
        jr      z,right_trim_loop ;{{f8c8:28ef}}  (-$11)
        cp      $0a               ;{{f8ca:fe0a}}  new line
        jr      z,right_trim_loop ;{{f8cc:28eb}}  (-$15)
_right_trim_loop_12:              ;{{Addr=$f8ce Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f8ce:e1}} 
        ret                       ;{{f8cf:c9}}  return to string getter

;;=============================================
;; output accumulator string
output_accumulator_string:        ;{{Addr=$f8d0 Code Calls/jump count: 3 Data use count: 0}}
        call    get_accumulator_string_length;{{f8d0:cdf5fb}} 
        ret     z                 ;{{f8d3:c8}} 

;;=output string atDE length B
output_string_atDE_length_B:      ;{{Addr=$f8d4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{f8d4:1a}} 
        inc     de                ;{{f8d5:13}} 
        call    output_raw_char   ;{{f8d6:cdb8c3}} 
        djnz    output_string_atDE_length_B;{{f8d9:10f9}}  (-$07)
        ret                       ;{{f8db:c9}} 

;;=unknown output accumulator string
unknown_output_accumulator_string:;{{Addr=$f8dc Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{f8dc:cdf5fb}} 
        ret     z                 ;{{f8df:c8}} 

        ld      a,c               ;{{f8e0:79}} 
        sub     b                 ;{{f8e1:90}} 
        jr      nc,_unknown_output_accumulator_string_9;{{f8e2:3005}}  (+$05)
        add     a,b               ;{{f8e4:80}} 
        jr      z,_unknown_output_accumulator_string_9;{{f8e5:2802}}  (+$02)
        ld      b,a               ;{{f8e7:47}} 
        xor     a                 ;{{f8e8:af}} 
_unknown_output_accumulator_string_9:;{{Addr=$f8e9 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{f8e9:4f}} 
        jr      output_string_atDE_length_B;{{f8ea:18e8}}  (-$18)

;;========================================================
;; function LOWER$
function_LOWER:                   ;{{Addr=$f8ec Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,convert_character_to_lower_case;{{f8ec:01f1f8}} ##LABEL##
        jr      string_iterator   ;{{f8ef:180c}}  (+$0c)

;;=convert character to lower case
convert_character_to_lower_case:  ;{{Addr=$f8f1 Code Calls/jump count: 0 Data use count: 1}}
        cp      $41               ;{{f8f1:fe41}} 
        ret     c                 ;{{f8f3:d8}} 

        cp      $5b               ;{{f8f4:fe5b}} 
        ret     nc                ;{{f8f6:d0}} 

        add     a,$20             ;{{f8f7:c620}} 
        ret                       ;{{f8f9:c9}} 

;;========================================================
;; function UPPER$

function_UPPER:                   ;{{Addr=$f8fa Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,convert_character_to_upper_case;{{f8fa:01abff}} ##LABEL##

;;=string iterator
;; BC = routine to call for each character
string_iterator:                  ;{{Addr=$f8fd Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f8fd:c5}} 
        ld      hl,(accumulator)  ;{{f8fe:2aa0b0}} 
        call    get_accumulator_string_length;{{f901:cdf5fb}} 
        call    alloc_space_in_strings_area;{{f904:cd41fc}} 
        inc     hl                ;{{f907:23}} 
        ld      c,(hl)            ;{{f908:4e}} 
        inc     hl                ;{{f909:23}} 
        ld      h,(hl)            ;{{f90a:66}} 
        ld      l,c               ;{{f90b:69}} 
        pop     bc                ;{{f90c:c1}} 
        inc     a                 ;{{f90d:3c}} 
_string_iterator_11:              ;{{Addr=$f90e Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{f90e:3d}} 
        jp      z,push_last_string_on_string_stack;{{f90f:cad6fb}} 
        push    af                ;{{f912:f5}} 
        ld      a,(hl)            ;{{f913:7e}} 
        inc     hl                ;{{f914:23}} 
        call    JP_BC             ;{{f915:cdfcff}}  JP (BC) call callback function
        ld      (de),a            ;{{f918:12}} 
        inc     de                ;{{f919:13}} 
        pop     af                ;{{f91a:f1}} 
        jr      _string_iterator_11;{{f91b:18f1}}  (-$0f)

;;=concat two strings
concat_two_strings:               ;{{Addr=$f91d Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(accumulator)  ;{{f91d:ed5ba0b0}} 
        ld      a,(de)            ;{{f921:1a}} 
        add     a,(hl)            ;{{f922:86}} 
        jr      nc,_concat_two_strings_6;{{f923:3004}}  (+$04)
        call    byte_following_call_is_error_code;{{f925:cd45cb}} 
        defb $0f                  ;Inline error code: String too long
    
_concat_two_strings_6:            ;{{Addr=$f929 Code Calls/jump count: 1 Data use count: 0}}
        call    alloc_space_in_strings_area;{{f929:cd41fc}} 
        call    xf959_code        ;{{f92c:cd59f9}} 
        push    de                ;{{f92f:d5}} 
        push    bc                ;{{f930:c5}} 
        ld      c,b               ;{{f931:48}} 
        call    push_last_string_on_string_stack;{{f932:cdd6fb}} 
        ld      a,c               ;{{f935:79}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f936:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     bc                ;{{f939:c1}} 
        pop     hl                ;{{f93a:e1}} 
        ld      a,c               ;{{f93b:79}} 
        jp      copy_bytes_LDIR__Acount_HLsource_DEdest;{{f93c:c3ecff}} ; copy bytes (A=count, HL=source, DE=dest)

;;================================================
;;probably string comparison

probably_string_comparison:       ;{{Addr=$f93f Code Calls/jump count: 1 Data use count: 0}}
        call    xf959_code        ;{{f93f:cd59f9}} 
        xor     a                 ;{{f942:af}} 
_probably_string_comparison_2:    ;{{Addr=$f943 Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{f943:b9}} 
        jr      z,_probably_string_comparison_17;{{f944:280f}}  (+$0f)
        cp      b                 ;{{f946:b8}} 
        jr      z,_probably_string_comparison_15;{{f947:280a}}  (+$0a)
        dec     b                 ;{{f949:05}} 
        dec     c                 ;{{f94a:0d}} 
        ld      a,(de)            ;{{f94b:1a}} 
        inc     de                ;{{f94c:13}} 
        sub     (hl)              ;{{f94d:96}} 
        inc     hl                ;{{f94e:23}} 
        jr      z,_probably_string_comparison_2;{{f94f:28f2}}  (-$0e)
        sbc     a,a               ;{{f951:9f}} 
        ret     nz                ;{{f952:c0}} 

_probably_string_comparison_15:   ;{{Addr=$f953 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{f953:3c}} 
        ret                       ;{{f954:c9}} 

_probably_string_comparison_17:   ;{{Addr=$f955 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{f955:b8}} 
        ret     z                 ;{{f956:c8}} 

        sbc     a,a               ;{{f957:9f}} 
        ret                       ;{{f958:c9}} 

;;=================================================
xf959_code:                       ;{{Addr=$f959 Code Calls/jump count: 2 Data use count: 0}}
        call    get_accumulator_string_length;{{f959:cdf5fb}} 
        ld      c,b               ;{{f95c:48}} 
        push    de                ;{{f95d:d5}} 
        call    various_get_string_from_stack_stuff;{{f95e:cd03fc}} 
        ex      de,hl             ;{{f961:eb}} 
        pop     de                ;{{f962:d1}} 
        ret                       ;{{f963:c9}} 
;;========================================================================
;; function BIN$
function_BIN:                     ;{{Addr=$f964 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$0101          ;{{f964:010101}} 
        jr      _function_hex_1   ;{{f967:1803}}  (+$03)

;;========================================================================
;; function HEX$
function_HEX:                     ;{{Addr=$f969 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$040f          ;{{f969:010f04}} 
_function_hex_1:                  ;{{Addr=$f96c Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f96c:c5}} 
        call    eval_expression   ;{{f96d:cd62cf}} 
        push    hl                ;{{f970:e5}} 
        call    function_UNT      ;{{f971:cdebfe}} 
        ex      (sp),hl           ;{{f974:e3}} 
        call    next_token_if_prev_is_comma;{{f975:cd41de}} 
        sbc     a,a               ;{{f978:9f}} 
        call    c,eval_expr_as_byte_or_error;{{f979:dcb8ce}}  get number and check it's less than 255 
        cp      $11               ;{{f97c:fe11}} 
        jp      nc,Error_Improper_Argument;{{f97e:d24dcb}}  Error: Improper Argument
        ld      b,a               ;{{f981:47}} 
        call    next_token_if_close_bracket;{{f982:cd1dde}}  check for close bracket
        ld      a,b               ;{{f985:78}} 
        ex      de,hl             ;{{f986:eb}} 
        pop     hl                ;{{f987:e1}} 
        pop     bc                ;{{f988:c1}} 
        push    de                ;{{f989:d5}} 
        call    convert_based_number_to_string;{{f98a:cddff1}} 
        jr      _function_str_2   ;{{f98d:1831}}  (+$31)

;;========================================================================
;; function DEC$
function_DEC:                     ;{{Addr=$f98f Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{f98f:cd62cf}} 
        call    next_token_if_comma;{{f992:cd15de}}  check for comma
        call    probably_push_accumulator_on_execution_stack;{{f995:cd74ff}} 
        call    eval_expr_as_string_and_get_length;{{f998:cd03cf}} 
        call    next_token_if_close_bracket;{{f99b:cd1dde}}  check for close bracket
        push    hl                ;{{f99e:e5}} 
        ld      a,c               ;{{f99f:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{f9a0:cd62f6}} 
        push    de                ;{{f9a3:d5}} 
        ld      a,c               ;{{f9a4:79}} 
        call    copy_atHL_to_accumulator_type_A;{{f9a5:cd6cff}} 
        pop     de                ;{{f9a8:d1}} 
        ld      a,b               ;{{f9a9:78}} 
        or      a                 ;{{f9aa:b7}} 
        call    nz,_print_using_121;{{f9ab:c448f4}} 
        jp      nc,Error_Improper_Argument;{{f9ae:d24dcb}}  Error: Improper Argument
        ld      a,b               ;{{f9b1:78}} 
        or      a                 ;{{f9b2:b7}} 
        jp      nz,Error_Improper_Argument;{{f9b3:c24dcb}}  Error: Improper Argument
        ld      a,c               ;{{f9b6:79}} 
        call    convert_number_to_string_by_format;{{f9b7:cd6aef}} 
        jr      _function_str_2   ;{{f9ba:1804}}  (+$04)

;;========================================================
;; function STR$

function_STR:                     ;{{Addr=$f9bc Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{f9bc:e5}} 
        call    prob_eval_number_to_decimal_string;{{f9bd:cd68ef}} 
_function_str_2:                  ;{{Addr=$f9c0 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{f9c0:e5}} 
        ld      c,$ff             ;{{f9c1:0eff}} 
        xor     a                 ;{{f9c3:af}} 
_function_str_5:                  ;{{Addr=$f9c4 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{f9c4:0c}} 
        cp      (hl)              ;{{f9c5:be}} 
        inc     hl                ;{{f9c6:23}} 
        jr      nz,_function_str_5;{{f9c7:20fb}}  (-$05)
        pop     hl                ;{{f9c9:e1}} 
        ld      a,c               ;{{f9ca:79}} 
        call    _get_string_stack_first_free_ptr_3;{{f9cb:cdd3fb}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f9ce:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{f9d1:e1}} 
        ret                       ;{{f9d2:c9}} 

;;========================================================================
;; function LEFT$
function_LEFT:                    ;{{Addr=$f9d3 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_mid_34   ;{{f9d3:cd43fa}} 
        jr      _prefix_mid_6     ;{{f9d6:1818}}  (+$18)

;;========================================================================
;; function RIGHT$
function_RIGHT:                   ;{{Addr=$f9d8 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_mid_34   ;{{f9d8:cd43fa}} 
        ld      a,(de)            ;{{f9db:1a}} 
        sub     b                 ;{{f9dc:90}} 
        jr      c,_prefix_mid_6   ;{{f9dd:3811}}  (+$11)
        ld      c,a               ;{{f9df:4f}} 
        jr      _prefix_mid_6     ;{{f9e0:180e}}  (+$0e)

;;=======================================================================
;; prefix MID$

prefix_MID:                       ;{{Addr=$f9e2 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{f9e2:cd19de}}  check for open bracket
        call    _command_mid_34   ;{{f9e5:cd43fa}} 
        jp      z,Error_Improper_Argument;{{f9e8:ca4dcb}}  Error: Improper Argument
        dec     b                 ;{{f9eb:05}} 
        ld      c,b               ;{{f9ec:48}} 
        call    _command_mid_40   ;{{f9ed:cd4ffa}} 
;;------------------------------------------------------------------------
_prefix_mid_6:                    ;{{Addr=$f9f0 Code Calls/jump count: 3 Data use count: 0}}
        call    next_token_if_close_bracket;{{f9f0:cd1dde}}  check for close bracket
        push    hl                ;{{f9f3:e5}} 
        ex      de,hl             ;{{f9f4:eb}} 
        call    _command_mid_51   ;{{f9f5:cd60fa}} 
        call    alloc_space_in_strings_area;{{f9f8:cd41fc}} 
        call    various_get_string_from_stack_stuff;{{f9fb:cd03fc}} 
        ex      de,hl             ;{{f9fe:eb}} 
        call    push_last_string_on_string_stack;{{f9ff:cdd6fb}} 
        ld      b,$00             ;{{fa02:0600}} 
        add     hl,bc             ;{{fa04:09}} 
        jr      _command_mid_31   ;{{fa05:1837}}  (+$37)

;;========================================================================
;; command MID$

command_MID:                      ;{{Addr=$fa07 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{fa07:cd19de}}  check for open bracket
        call    parse_and_find_or_create_a_var;{{fa0a:cdbfd6}} 
        call    error_if_accumulator_is_not_a_string;{{fa0d:cd5eff}} 
        push    hl                ;{{fa10:e5}} 
        ex      de,hl             ;{{fa11:eb}} 
        call    prob_copy_string_to_strings_area;{{fa12:cd58fb}} 
        ex      (sp),hl           ;{{fa15:e3}} 
        call    _command_mid_44   ;{{fa16:cd55fa}} 
        jp      z,Error_Improper_Argument;{{fa19:ca4dcb}}  Error: Improper Argument
        dec     a                 ;{{fa1c:3d}} 
        ld      c,a               ;{{fa1d:4f}} 
        call    _command_mid_40   ;{{fa1e:cd4ffa}} 
        call    next_token_if_close_bracket;{{fa21:cd1dde}}  check for close bracket
        call    next_token_if_equals_sign;{{fa24:cd21de}} 
        push    bc                ;{{fa27:c5}} 
        call    eval_expr_as_string_and_get_length;{{fa28:cd03cf}} 
        ld      a,b               ;{{fa2b:78}} 
        pop     bc                ;{{fa2c:c1}} 
        ex      (sp),hl           ;{{fa2d:e3}} 
        cp      b                 ;{{fa2e:b8}} 
        jr      nc,_command_mid_22;{{fa2f:3001}}  (+$01)
        ld      b,a               ;{{fa31:47}} 
_command_mid_22:                  ;{{Addr=$fa32 Code Calls/jump count: 1 Data use count: 0}}
        call    _command_mid_51   ;{{fa32:cd60fa}} 
        inc     hl                ;{{fa35:23}} 
        ld      b,(hl)            ;{{fa36:46}} 
        inc     hl                ;{{fa37:23}} 
        ld      h,(hl)            ;{{fa38:66}} 
        ld      l,b               ;{{fa39:68}} 
        ld      b,$00             ;{{fa3a:0600}} 
        add     hl,bc             ;{{fa3c:09}} 
        ex      de,hl             ;{{fa3d:eb}} 
_command_mid_31:                  ;{{Addr=$fa3e Code Calls/jump count: 1 Data use count: 0}}
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{fa3e:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{fa41:e1}} 
        ret                       ;{{fa42:c9}} 

_command_mid_34:                  ;{{Addr=$fa43 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expr_and_error_if_not_string;{{fa43:cd09cf}} 
        ex      de,hl             ;{{fa46:eb}} 
        ld      hl,(accumulator)  ;{{fa47:2aa0b0}} 
        ex      de,hl             ;{{fa4a:eb}} 
        ld      c,$00             ;{{fa4b:0e00}} 
        jr      _command_mid_44   ;{{fa4d:1806}}  (+$06)

_command_mid_40:                  ;{{Addr=$fa4f Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$ff             ;{{fa4f:06ff}} 
        ld      a,(hl)            ;{{fa51:7e}} 
        cp      $29               ;{{fa52:fe29}} 
        ret     z                 ;{{fa54:c8}} 

_command_mid_44:                  ;{{Addr=$fa55 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{fa55:d5}} 
        call    next_token_if_comma;{{fa56:cd15de}}  check for comma
        call    eval_expr_as_byte_or_error;{{fa59:cdb8ce}}  get number and check it's less than 255 
        ld      b,a               ;{{fa5c:47}} 
        pop     de                ;{{fa5d:d1}} 
        or      a                 ;{{fa5e:b7}} 
        ret                       ;{{fa5f:c9}} 

_command_mid_51:                  ;{{Addr=$fa60 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{fa60:7e}} 
        sub     c                 ;{{fa61:91}} 
        jr      nc,_command_mid_55;{{fa62:3001}}  (+$01)
        xor     a                 ;{{fa64:af}} 
_command_mid_55:                  ;{{Addr=$fa65 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{fa65:b8}} 
        ret     c                 ;{{fa66:d8}} 

        ld      a,b               ;{{fa67:78}} 
        ret                       ;{{fa68:c9}} 

;;========================================================
;; function LEN

function_LEN:                     ;{{Addr=$fa69 Code Calls/jump count: 0 Data use count: 1}}
        call    get_accumulator_string_length;{{fa69:cdf5fb}} 
        jr      _function_asc_1   ;{{fa6c:1803}}  (+$03)

;;========================================================
;; function ASC

function_ASC:                     ;{{Addr=$fa6e Code Calls/jump count: 0 Data use count: 1}}
        call    get_first_char_of_string_or_error;{{fa6e:cda6fa}} 
_function_asc_1:                  ;{{Addr=$fa71 Code Calls/jump count: 1 Data use count: 0}}
        jp      store_A_in_accumulator_as_INT;{{fa71:c332ff}} 

;;========================================================
;; function CHR$

function_CHR:                     ;{{Addr=$fa74 Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{fa74:cdd9fa}} 
_function_chr_1:                  ;{{Addr=$fa77 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{fa77:37}} 

_function_chr_2:                  ;{{Addr=$fa78 Code Calls/jump count: 4 Data use count: 0}}
        ld      c,a               ;{{fa78:4f}} 
        sbc     a,a               ;{{fa79:9f}} 
        and     $01               ;{{fa7a:e601}} 
        jr      _function_space_2 ;{{fa7c:1834}}  (+$34)

;;=========================================================
;; variable INKEY$

variable_INKEY:                   ;{{Addr=$fa7e Code Calls/jump count: 0 Data use count: 1}}
        call    jp_km_read_char   ;{{fa7e:cd6fc4}}  call to firmware function: km read key			
        jr      nc,_function_chr_2;{{fa81:30f5}}  
        cp      $fc               ;{{fa83:fefc}} 
        jr      z,_function_chr_2 ;{{fa85:28f1}} 
        cp      $ef               ;{{fa87:feef}} token for '='
        jr      z,_function_chr_2 ;{{fa89:28ed}}  (-$13)
        jr      _function_chr_1   ;{{fa8b:18ea}}  (-$16)

;;=========================================================
;; function STRING$

function_STRING:                  ;{{Addr=$fa8d Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_byte_or_error;{{fa8d:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{fa90:f5}} 
        call    next_token_if_comma;{{fa91:cd15de}}  check for comma
        call    eval_expression   ;{{fa94:cd62cf}} 
        call    next_token_if_close_bracket;{{fa97:cd1dde}}  check for close bracket
        call    get_first_char_from_accumulator_or_error;{{fa9a:cda1fa}} 
        ld      c,a               ;{{fa9d:4f}} 
        pop     af                ;{{fa9e:f1}} 
        jr      _function_space_2 ;{{fa9f:1811}}  (+$11)

;;=get first char from accumulator or error
get_first_char_from_accumulator_or_error:;{{Addr=$faa1 Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_a_string;{{faa1:cd66ff}} 
        jr      nz,param_less_than_256_or_error;{{faa4:2033}}  (+$33)
;;=get first char of string or error
get_first_char_of_string_or_error:;{{Addr=$faa6 Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{faa6:cdf5fb}} 
        jr      z,raise_improper_argument_error_E;{{faa9:2837}}  (+$37)
        ld      a,(de)            ;{{faab:1a}} 
        ret                       ;{{faac:c9}} 

;;========================================================
;; function SPACE$

function_SPACE:                   ;{{Addr=$faad Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{faad:cdd9fa}} 
        ld      c,$20             ;{{fab0:0e20}} 
_function_space_2:                ;{{Addr=$fab2 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,a               ;{{fab2:47}} 
        call    _get_string_stack_first_free_ptr_3;{{fab3:cdd3fb}} 
        ld      a,c               ;{{fab6:79}} 
        inc     b                 ;{{fab7:04}} 
_function_space_6:                ;{{Addr=$fab8 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{fab8:05}} 
        ret     z                 ;{{fab9:c8}} 

        ld      (de),a            ;{{faba:12}} 
        inc     de                ;{{fabb:13}} 
        jr      _function_space_6 ;{{fabc:18fa}}  (-$06)

;;========================================================
;; function VAL
;convert string to number

function_VAL:                     ;{{Addr=$fabe Code Calls/jump count: 0 Data use count: 1}}
        call    get_accumulator_string_length;{{fabe:cdf5fb}} 
        jp      z,store_A_in_accumulator_as_INT;{{fac1:ca32ff}} 
        ex      de,hl             ;{{fac4:eb}} 
        push    hl                ;{{fac5:e5}} 
        ld      e,a               ;{{fac6:5f}} 
        ld      d,$00             ;{{fac7:1600}} 
        add     hl,de             ;{{fac9:19}} 
        ld      e,(hl)            ;{{faca:5e}} 
        ld      (hl),d            ;{{facb:72}} 
        ex      (sp),hl           ;{{facc:e3}} 
        push    de                ;{{facd:d5}} 
        call    possibly_validate_input_buffer_is_a_number;{{face:cd6fed}} 
        pop     de                ;{{fad1:d1}} 
        pop     hl                ;{{fad2:e1}} 
        ld      (hl),e            ;{{fad3:73}} 
        ret     c                 ;{{fad4:d8}} 

        call    byte_following_call_is_error_code;{{fad5:cd45cb}} 
        defb $0d                  ;Inline error code: Type Mismatch

;;=============================
;;param less than 256 or error
param_less_than_256_or_error:     ;{{Addr=$fad9 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{fad9:e5}} 
        call    function_CINT     ;{{fada:cdb6fe}} 
        ld      a,h               ;{{fadd:7c}} 
        or      a                 ;{{fade:b7}} 
        ld      a,l               ;{{fadf:7d}} 
        pop     hl                ;{{fae0:e1}} 
        ret     z                 ;{{fae1:c8}} 

;;=raise Improper argument error
raise_improper_argument_error_E:  ;{{Addr=$fae2 Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{fae2:c34dcb}}  Error: Improper Argument

;;========================================================================
;; function INSTR$
;find string within string
function_INSTR:                   ;{{Addr=$fae5 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{fae5:cd62cf}} 
        call    is_accumulator_a_string;{{fae8:cd66ff}} 
        ld      c,$01             ;{{faeb:0e01}} 
        jr      z,_function_instr_10;{{faed:280e}}  (+$0e)
        call    param_less_than_256_or_error;{{faef:cdd9fa}} 
        or      a                 ;{{faf2:b7}} 
        jp      z,Error_Improper_Argument;{{faf3:ca4dcb}}  Error: Improper Argument
        ld      c,a               ;{{faf6:4f}} 
        call    next_token_if_comma;{{faf7:cd15de}}  check for comma
        call    eval_expr_and_error_if_not_string;{{fafa:cd09cf}} 
_function_instr_10:               ;{{Addr=$fafd Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_comma;{{fafd:cd15de}}  check for comma
        push    hl                ;{{fb00:e5}} 
        ld      hl,(accumulator)  ;{{fb01:2aa0b0}} 
        ex      (sp),hl           ;{{fb04:e3}} 
        call    eval_expr_as_string_and_get_length;{{fb05:cd03cf}} 
        call    next_token_if_close_bracket;{{fb08:cd1dde}}  check for close bracket
        ex      (sp),hl           ;{{fb0b:e3}} 
        ld      a,c               ;{{fb0c:79}} 
        ld      c,b               ;{{fb0d:48}} 
        push    de                ;{{fb0e:d5}} 
        push    af                ;{{fb0f:f5}} 
        call    various_get_string_from_stack_stuff;{{fb10:cd03fc}} 
        ex      de,hl             ;{{fb13:eb}} 
        pop     af                ;{{fb14:f1}} 
        ld      e,a               ;{{fb15:5f}} 
        ld      d,$00             ;{{fb16:1600}} 
        add     hl,de             ;{{fb18:19}} 
        dec     hl                ;{{fb19:2b}} 
        ld      a,b               ;{{fb1a:78}} 
        sub     e                 ;{{fb1b:93}} 
        inc     a                 ;{{fb1c:3c}} 
        ld      b,a               ;{{fb1d:47}} 
        ld      a,e               ;{{fb1e:7b}} 
        pop     de                ;{{fb1f:d1}} 
        jr      c,_function_instr_66;{{fb20:3825}}  (+$25)
        inc     c                 ;{{fb22:0c}} 
        dec     c                 ;{{fb23:0d}} 
        jr      z,_function_instr_67;{{fb24:2822}}  (+$22)
_function_instr_38:               ;{{Addr=$fb26 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{fb26:f5}} 
        ld      a,b               ;{{fb27:78}} 
        cp      c                 ;{{fb28:b9}} 
        jr      c,_function_instr_65;{{fb29:381b}}  (+$1b)
        push    hl                ;{{fb2b:e5}} 
        push    de                ;{{fb2c:d5}} 
        push    bc                ;{{fb2d:c5}} 
_function_instr_45:               ;{{Addr=$fb2e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{fb2e:1a}} 
        cp      (hl)              ;{{fb2f:be}} 
        jr      nz,_function_instr_57;{{fb30:200b}}  (+$0b)
        inc     hl                ;{{fb32:23}} 
        inc     de                ;{{fb33:13}} 
        dec     c                 ;{{fb34:0d}} 
        jr      nz,_function_instr_45;{{fb35:20f7}}  (-$09)
        pop     bc                ;{{fb37:c1}} 
        pop     de                ;{{fb38:d1}} 
        pop     hl                ;{{fb39:e1}} 
        pop     af                ;{{fb3a:f1}} 
        jr      _function_instr_67;{{fb3b:180b}}  (+$0b)

_function_instr_57:               ;{{Addr=$fb3d Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{fb3d:c1}} 
        pop     de                ;{{fb3e:d1}} 
        pop     hl                ;{{fb3f:e1}} 
        pop     af                ;{{fb40:f1}} 
        inc     a                 ;{{fb41:3c}} 
        inc     hl                ;{{fb42:23}} 
        dec     b                 ;{{fb43:05}} 
        jr      _function_instr_38;{{fb44:18e0}}  (-$20)

_function_instr_65:               ;{{Addr=$fb46 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{fb46:f1}} 
_function_instr_66:               ;{{Addr=$fb47 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{fb47:af}} 
_function_instr_67:               ;{{Addr=$fb48 Code Calls/jump count: 2 Data use count: 0}}
        call    store_A_in_accumulator_as_INT;{{fb48:cd32ff}} 
        pop     hl                ;{{fb4b:e1}} 
        ret                       ;{{fb4c:c9}} 

_function_instr_70:               ;{{Addr=$fb4d Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{fb4d:d5}} 
        push    hl                ;{{fb4e:e5}} 
        ld      de,_prob_copy_string_to_strings_area_11;{{fb4f:1165fb}}   ##LABEL##
        call    iterate_all_string_variables;{{fb52:cd93da}} 
        pop     hl                ;{{fb55:e1}} 
        pop     de                ;{{fb56:d1}} 
        ret                       ;{{fb57:c9}} 

;;==========================
;;prob copy string to strings area
prob_copy_string_to_strings_area: ;{{Addr=$fb58 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{fb58:e5}} 
        ld      a,(hl)            ;{{fb59:7e}} 
        inc     hl                ;{{fb5a:23}} 
        ld      c,(hl)            ;{{fb5b:4e}} 
        inc     hl                ;{{fb5c:23}} 
        ld      b,(hl)            ;{{fb5d:46}} 
        ex      de,hl             ;{{fb5e:eb}} 
        or      a                 ;{{fb5f:b7}} 
        call    nz,_prob_copy_string_to_strings_area_11;{{fb60:c465fb}} 
        pop     hl                ;{{fb63:e1}} 
        ret                       ;{{fb64:c9}} 

_prob_copy_string_to_strings_area_11:;{{Addr=$fb65 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_end_of_free_space_);{{fb65:2a71b0}} 
        call    compare_HL_BC     ;{{fb68:cddeff}}  HL=BC?
        jr      nc,_prob_copy_string_to_strings_area_17;{{fb6b:3007}}  (+$07)
        ld      hl,(address_of_end_of_Strings_area_);{{fb6d:2a73b0}} 
        call    compare_HL_BC     ;{{fb70:cddeff}}  HL=BC?
        ret     nc                ;{{fb73:d0}} 

_prob_copy_string_to_strings_area_17:;{{Addr=$fb74 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fb74:eb}} 
        dec     hl                ;{{fb75:2b}} 
        dec     hl                ;{{fb76:2b}} 
        push    hl                ;{{fb77:e5}} 
        call    copy_last_string_used_to_strings_area;{{fb78:cdb9fb}} 
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

;;=copy accumulator to strings area
copy_accumulator_to_strings_area: ;{{Addr=$fb8a Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_string_concat_area_minus_1;{{fb8a:cd37fc}} 
        ret     c                 ;{{fb8d:d8}} 

        call    copy_last_string_used_to_strings_area;{{fb8e:cdb9fb}} 
        jp      push_last_string_on_string_stack;{{fb91:c3d6fb}} 

_copy_accumulator_to_strings_area_4:;{{Addr=$fb94 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fb94:2aa0b0}} 
        call    get_addr_and_len_of_last_string_in_concat_area;{{fb97:cd1ffc}} 
        ld      a,b               ;{{fb9a:78}} 
        or      a                 ;{{fb9b:b7}} 
        ret     z                 ;{{fb9c:c8}} 

        push    hl                ;{{fb9d:e5}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{fb9e:2a64ae}} 
        call    compare_HL_DE     ;{{fba1:cdd8ff}}  HL=DE?
        ld      hl,(address_of_end_of_Strings_area_);{{fba4:2a73b0}} 
        ex      de,hl             ;{{fba7:eb}} 
        call    c,compare_HL_DE   ;{{fba8:dcd8ff}}  HL=DE?
        jr      nc,_copy_accumulator_to_strings_area_19;{{fbab:300a}}  (+$0a)
        ld      de,(address_after_end_of_program);{{fbad:ed5b66ae}} 
        call    compare_HL_DE     ;{{fbb1:cdd8ff}}  HL=DE?
        call    nc,is_accumulator_string_concat_area_minus_1;{{fbb4:d437fc}} 
_copy_accumulator_to_strings_area_19:;{{Addr=$fbb7 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{fbb7:e1}} 
        ret     c                 ;{{fbb8:d8}} 

;;=copy last string used to strings area
copy_last_string_used_to_strings_area:;{{Addr=$fbb9 Code Calls/jump count: 2 Data use count: 0}}
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
;;get string stack first free ptr
get_string_stack_first_free_ptr:  ;{{Addr=$fbcc Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,string_stack_first;{{fbcc:217eb0}} 
        ld      (string_stack_first_free_ptr),hl;{{fbcf:227cb0}} 
        ret                       ;{{fbd2:c9}} 

_get_string_stack_first_free_ptr_3:;{{Addr=$fbd3 Code Calls/jump count: 2 Data use count: 0}}
        call    alloc_space_in_strings_area;{{fbd3:cd41fc}} 

;;=push last string on string stack
push_last_string_on_string_stack: ;{{Addr=$fbd6 Code Calls/jump count: 5 Data use count: 0}}
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
        call    various_get_string_from_stack_stuff;{{fbfc:cd03fc}} 
        pop     hl                ;{{fbff:e1}} 
        ld      a,b               ;{{fc00:78}} 
        or      a                 ;{{fc01:b7}} 
        ret                       ;{{fc02:c9}} 

;;===================================
;;various get string from stack stuff
;get top string on stack
;or move top to string stack to variables area???
; (or preserve TOS string in data area?)
various_get_string_from_stack_stuff:;{{Addr=$fc03 Code Calls/jump count: 5 Data use count: 0}}
        call    get_addr_and_len_of_last_string_in_concat_area;{{fc03:cd1ffc}} 
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

;;=get addr and len of last string in concat area
;returns HL=addr, B=length
;if HL=address of last item then 'pops' it off the concat stack
get_addr_and_len_of_last_string_in_concat_area:;{{Addr=$fc1f Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{fc1f:e5}} 
        ld      de,(string_stack_first_free_ptr);{{fc20:ed5b7cb0}} 
        dec     de                ;{{fc24:1b}} 
        dec     de                ;{{fc25:1b}} 
        dec     de                ;{{fc26:1b}} 
        call    compare_HL_DE     ;{{fc27:cdd8ff}}  HL=DE?
        jr      nz,_get_addr_and_len_of_last_string_in_concat_area_8;{{fc2a:2004}}  (+$04)
        ld      (string_stack_first_free_ptr),de;{{fc2c:ed537cb0}} 
_get_addr_and_len_of_last_string_in_concat_area_8:;{{Addr=$fc30 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,(hl)            ;{{fc30:46}} 
        inc     hl                ;{{fc31:23}} 
        ld      e,(hl)            ;{{fc32:5e}} 
        inc     hl                ;{{fc33:23}} 
        ld      d,(hl)            ;{{fc34:56}} 
        pop     hl                ;{{fc35:e1}} 
        ret                       ;{{fc36:c9}} 

;;============================
;;is accumulator string concat area minus 1
;are we testing for empty string concat area?
is_accumulator_string_concat_area_minus_1:;{{Addr=$fc37 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fc37:2aa0b0}} 
        ld      a,string_stack_first - 1 and $ff;{{fc3a:3e7d}}  $7d  string stack start - 1 (low byte)
        sub     l                 ;{{fc3c:95}} 
        ld      a,string_stack_first - 1 >> 8;{{fc3d:3eb0}}  $b0  string stack start - 1 (high byte)
        sbc     a,h               ;{{fc3f:9c}} 
        ret                       ;{{fc40:c9}} 

;;==============================
;;alloc space in strings area
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
;count free memory (and do garbage collection)
function_FRE:                     ;{{Addr=$fc53 Code Calls/jump count: 0 Data use count: 1}}
        call    is_accumulator_a_string;{{fc53:cd66ff}} 
        jr      nz,_function_fre_4;{{fc56:2006}}  (+$06)
        call    get_accumulator_string_length;{{fc58:cdf5fb}} 
        call    _function_fre_6   ;{{fc5b:cd64fc}} 
_function_fre_4:                  ;{{Addr=$fc5e Code Calls/jump count: 1 Data use count: 0}}
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{fc5e:cdfcf6}} 
        jp      set_accumulator_as_REAL_from_unsigned_INT;{{fc61:c389fe}} 

_function_fre_6:                  ;{{Addr=$fc64 Code Calls/jump count: 6 Data use count: 0}}
        push    hl                ;{{fc64:e5}} 
        push    de                ;{{fc65:d5}} 
        push    bc                ;{{fc66:c5}} 
        ld      hl,string_stack_first;{{fc67:217eb0}} 
        jr      _function_fre_21  ;{{fc6a:180c}}  (+$0c)

_function_fre_11:                 ;{{Addr=$fc6c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{fc6c:7e}} 
        inc     hl                ;{{fc6d:23}} 
        ld      c,(hl)            ;{{fc6e:4e}} 
        inc     hl                ;{{fc6f:23}} 
        ld      b,(hl)            ;{{fc70:46}} 
        ex      de,hl             ;{{fc71:eb}} 
        or      a                 ;{{fc72:b7}} 
        call    nz,poss_free_string_at_BC_length_A;{{fc73:c4e3fc}} 
        ex      de,hl             ;{{fc76:eb}} 
        inc     hl                ;{{fc77:23}} 
_function_fre_21:                 ;{{Addr=$fc78 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(string_stack_first_free_ptr);{{fc78:ed5b7cb0}} 
        call    compare_HL_DE     ;{{fc7c:cdd8ff}}  HL=DE?
        jr      nz,_function_fre_11;{{fc7f:20eb}}  (-$15) 
        ld      de,poss_free_string_at_BC_length_A;{{fc81:11e3fc}}   ##LABEL##
        call    iterate_all_string_variables;{{fc84:cd93da}} 
        ld      hl,(address_of_end_of_Strings_area_);{{fc87:2a73b0}} 
        push    hl                ;{{fc8a:e5}} 
        ld      hl,(address_of_end_of_free_space_);{{fc8b:2a71b0}} 
        inc     hl                ;{{fc8e:23}} 
        ld      e,l               ;{{fc8f:5d}} 
        ld      d,h               ;{{fc90:54}} 
        jr      _function_fre_49  ;{{fc91:1814}}  (+$14)

_function_fre_33:                 ;{{Addr=$fc93 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{fc93:4e}} 
        inc     hl                ;{{fc94:23}} 
        ld      b,(hl)            ;{{fc95:46}} 
        inc     b                 ;{{fc96:04}} 
        dec     b                 ;{{fc97:05}} 
        jr      z,_function_fre_47;{{fc98:280b}}  (+$0b)
        dec     hl                ;{{fc9a:2b}} 
        ld      a,(bc)            ;{{fc9b:0a}} 
        ld      c,a               ;{{fc9c:4f}} 
        ld      b,$00             ;{{fc9d:0600}} 
        inc     bc                ;{{fc9f:03}} 
        inc     bc                ;{{fca0:03}} 
        ldir                      ;{{fca1:edb0}} 
        jr      _function_fre_49  ;{{fca3:1802}}  (+$02)

_function_fre_47:                 ;{{Addr=$fca5 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{fca5:23}} 
        add     hl,bc             ;{{fca6:09}} 
_function_fre_49:                 ;{{Addr=$fca7 Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{fca7:c1}} 
        push    bc                ;{{fca8:c5}} 
        call    compare_HL_BC     ;{{fca9:cddeff}}  HL=BC?
        jr      c,_function_fre_33;{{fcac:38e5}}  (-$1b)
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
        ld      (address_of_end_of_free_space_),hl;{{fcc0:2271b0}} 
        pop     bc                ;{{fcc3:c1}} 
        inc     hl                ;{{fcc4:23}} 
        jr      _function_fre_83  ;{{fcc5:1812}}  (+$12)

_function_fre_67:                 ;{{Addr=$fcc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{fcc7:5e}} 
        inc     hl                ;{{fcc8:23}} 
        ld      d,(hl)            ;{{fcc9:56}} 
        dec     hl                ;{{fcca:2b}} 
        ld      a,(de)            ;{{fccb:1a}} 
        ld      (hl),a            ;{{fccc:77}} 
        inc     hl                ;{{fccd:23}} 
        ld      (hl),$00          ;{{fcce:3600}} 
        inc     hl                ;{{fcd0:23}} 
        ex      de,hl             ;{{fcd1:eb}} 
        ld      (hl),d            ;{{fcd2:72}} 
        dec     hl                ;{{fcd3:2b}} 
        ld      (hl),e            ;{{fcd4:73}} 
        ld      l,a               ;{{fcd5:6f}} 
        ld      h,$00             ;{{fcd6:2600}} 
        add     hl,de             ;{{fcd8:19}} 
_function_fre_83:                 ;{{Addr=$fcd9 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_BC     ;{{fcd9:cddeff}}  HL=BC?
        jr      c,_function_fre_67;{{fcdc:38e9}}  (-$17)
        pop     af                ;{{fcde:f1}} 
        pop     bc                ;{{fcdf:c1}} 
        pop     de                ;{{fce0:d1}} 
        pop     hl                ;{{fce1:e1}} 
        ret                       ;{{fce2:c9}} 

;;=================================
;;poss free string at BC length A
poss_free_string_at_BC_length_A:  ;{{Addr=$fce3 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_start_of_free_space_);{{fce3:2a6cae}} 
        call    compare_HL_BC     ;{{fce6:cddeff}}  HL=BC?
        ret     nc                ;{{fce9:d0}} 

        dec     bc                ;{{fcea:0b}} 
        ld      a,d               ;{{fceb:7a}} 
        ld      (bc),a            ;{{fcec:02}} 
        dec     bc                ;{{fced:0b}} 
        ld      a,(bc)            ;{{fcee:0a}} 
        ld      (de),a            ;{{fcef:12}} 
        ld      a,e               ;{{fcf0:7b}} 
        ld      (bc),a            ;{{fcf1:02}} 
        ret                       ;{{fcf2:c9}} 

_poss_free_string_at_bc_length_a_12:;{{Addr=$fcf3 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fcf3:cd4fff}} 
        jp      nc,REAL_prepare_for_decimal;{{fcf6:d276bd}}  firmware maths??
        call    unknown_maths_fixup;{{fcf9:cd2add}} 
        ld      (accumulator),hl  ;{{fcfc:22a0b0}} 
        ld      hl,accumulator_plus_1;{{fcff:21a1b0}} 
        ret                       ;{{fd02:c9}} 

_poss_free_string_at_bc_length_a_18:;{{Addr=$fd03 Code Calls/jump count: 1 Data use count: 0}}
        call    function_UNT      ;{{fd03:cdebfe}} 
        ld      hl,accumulator_plus_1;{{fd06:21a1b0}} 
        jp      set_B_zero_E_zero_C_to_2_int_type;{{fd09:c330dd}} 




;;***InfixOperators.asm
;;<< INFIX OPERATORS
;;< Infix +, -, *, / etc. including boolean operators
;;=========================================
;; infix plus +
infix_plus_:                      ;{{Addr=$fd0c Code Calls/jump count: 1 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd0c:cd3bfe}} 
        jr      nc,_infix_plus__5 ;{{fd0f:3009}}  (+$09)
        call    INT_addition_with_overflow_test;{{fd11:cd4add}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd14:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd17:cd78fe}} 
_infix_plus__5:                   ;{{Addr=$fd1a Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_ADDITION     ;{{fd1a:cd7cbd}}  firmware REAL addition
        ret     c                 ;{{fd1d:d8}} 

;;=overflow error
overflow_error_B:                 ;{{Addr=$fd1e Code Calls/jump count: 2 Data use count: 0}}
        jp      overflow_error    ;{{fd1e:c3becb}} 

;;==========================================
;; infix minus -
infix_minus_:                     ;{{Addr=$fd21 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd21:cd3bfe}} 
        jr      nc,_infix_minus__5;{{fd24:3009}}  (+$09)
        call    INT_subtraction_with_overflow_test;{{fd26:cd52dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd29:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd2c:cd78fe}} 
_infix_minus__5:                  ;{{Addr=$fd2f Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_REVERSE_SUBTRACTION;{{fd2f:cd82bd}}  firmware REAL reverse subtraction
        ret     c                 ;{{fd32:d8}} 

        jr      overflow_error_B  ;{{fd33:18e9}}  (-$17)

;;==========================================
;; infix multiply *
infix_multiply_:                  ;{{Addr=$fd35 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd35:cd3bfe}} 
        jr      nc,_infix_multiply__5;{{fd38:3009}}  (+$09)
        call    INT_multiply_with_overflow_test;{{fd3a:cd5bdd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd3d:da35ff}} 
        call    convert_INT_accum_and_INT_param_to_REAL;{{fd40:cd78fe}} 
_infix_multiply__5:               ;{{Addr=$fd43 Code Calls/jump count: 1 Data use count: 0}}
        call    REAL_MULTIPLICATION;{{fd43:cd85bd}} firmware REAL mltiplication
        ret     c                 ;{{fd46:d8}} 

        jr      overflow_error_B  ;{{fd47:18d5}}  (-$2b)

;;===============================================
;; infix comparisons (plural)
infix_comparisons_plural:         ;{{Addr=$fd49 Code Calls/jump count: 3 Data use count: 0}}
        call    convert_accum_and_param_to_same_numeric_type;{{fd49:cd3bfe}} 
        jp      c,prob_compare_DE_to_HL;{{fd4c:da02de}} 
        jp      REAL_COMPARISON   ;{{fd4f:c38ebd}}  firmwware REAL compare

;;=============================================
;;infix divide /
infix_divide_:                    ;{{Addr=$fd52 Code Calls/jump count: 0 Data use count: 1}}
        call    convert_accum_and_param_to_REAL;{{fd52:cd70fe}} 
        ex      de,hl             ;{{fd55:eb}} 
        push    de                ;{{fd56:d5}} 
        call    REAL_DIVISION     ;{{fd57:cd88bd}}  firmware REAL division??
        pop     de                ;{{fd5a:d1}} 
        ld      bc,$0005          ;{{fd5b:010500}} 
        ldir                      ;{{fd5e:edb0}} 
        ret     c                 ;{{fd60:d8}} 

        jp      z,division_by_zero_error;{{fd61:cab5cb}} 
        jp      overflow_error    ;{{fd64:c3becb}} 

;;=================================================
;;infix integer division
infix_integer_division:           ;{{Addr=$fd67 Code Calls/jump count: 0 Data use count: 1}}
        call    _function_cint_6  ;{{fd67:cdc3fe}} 
        ex      de,hl             ;{{fd6a:eb}} 
        call    INT_division_with_overflow_test;{{fd6b:cd9cdd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd6e:da35ff}} 
        jr      z,_infix_mod_4    ;{{fd71:2810}}  (+$10)
        ld      hl,$8000          ;{{fd73:210080}} 
        jp      set_accumulator_as_REAL_from_unsigned_INT;{{fd76:c389fe}} 

;;=================================================
;;infix MOD
infix_MOD:                        ;{{Addr=$fd79 Code Calls/jump count: 0 Data use count: 1}}
        call    _function_cint_6  ;{{fd79:cdc3fe}} 
        ex      de,hl             ;{{fd7c:eb}} 
        call    INT_modulo        ;{{fd7d:cda3dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fd80:da35ff}} 
_infix_mod_4:                     ;{{Addr=$fd83 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{fd83:cd45cb}} 
        defb $0b                  ;Inline error code: Division by zero

;;============================================
;; infix AND
infix_AND:                        ;{{Addr=$fd87 Code Calls/jump count: 0 Data use count: 1}}
        call    _function_cint_6  ;{{fd87:cdc3fe}} 
        ld      a,e               ;{{fd8a:7b}} 
        and     l                 ;{{fd8b:a5}} 
        ld      l,a               ;{{fd8c:6f}} 
        ld      a,h               ;{{fd8d:7c}} 
        and     d                 ;{{fd8e:a2}} 

;;=infix logic done
infix_logic_done:                 ;{{Addr=$fd8f Code Calls/jump count: 3 Data use count: 0}}
        jp      store_AL_in_accumulator_as_INT;{{fd8f:c334ff}} 

;;=============================================
;; infix OR
infix_OR:                         ;{{Addr=$fd92 Code Calls/jump count: 0 Data use count: 1}}
        call    _function_cint_6  ;{{fd92:cdc3fe}} 
        ld      a,e               ;{{fd95:7b}} 
        or      l                 ;{{fd96:b5}} 
        ld      l,a               ;{{fd97:6f}} 
        ld      a,d               ;{{fd98:7a}} 
        or      h                 ;{{fd99:b4}} 
        jr      infix_logic_done  ;{{fd9a:18f3}}  (-$0d)

;;==============================================
;; infix XOR
infix_XOR:                        ;{{Addr=$fd9c Code Calls/jump count: 0 Data use count: 1}}
        call    _function_cint_6  ;{{fd9c:cdc3fe}} 
        ld      a,e               ;{{fd9f:7b}} 
        xor     l                 ;{{fda0:ad}} 
        ld      l,a               ;{{fda1:6f}} 
        ld      a,h               ;{{fda2:7c}} 
        xor     d                 ;{{fda3:aa}} 
        jr      infix_logic_done  ;{{fda4:18e9}}  (-$17)

;;===============================================
;;bitwise complement/invert
bitwise_complementinvert:         ;{{Addr=$fda6 Code Calls/jump count: 1 Data use count: 0}}
        call    function_CINT     ;{{fda6:cdb6fe}} 
        ld      a,l               ;{{fda9:7d}} 
        cpl                       ;{{fdaa:2f}} 
        ld      l,a               ;{{fdab:6f}} 
        ld      a,h               ;{{fdac:7c}} 
        cpl                       ;{{fdad:2f}} 
        jr      infix_logic_done  ;{{fdae:18df}}  (-$21)




;;***TypeConversions.asm
;;<< TYPE CONVERSIONS AND ROUNDING
;;< (from numbers to numbers)
;;========================================================
;; function ABS
function_ABS:                     ;{{Addr=$fdb0 Code Calls/jump count: 0 Data use count: 1}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{fdb0:cdc4fd}} 
        ret     p                 ;{{fdb3:f0}} 

;;=negate accumulator
negate_accumulator:               ;{{Addr=$fdb4 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fdb4:cd4fff}} 
        jp      nc,REAL_UNARY_MINUS;{{fdb7:d291bd}}  firmware REAL negate
        call    negate_HL_and_test_if_INT;{{fdba:cdeddd}} negate HL
        ld      (accumulator),hl  ;{{fdbd:22a0b0}} 
        call    nc,set_accumulator_as_REAL_from_unsigned_INT;{{fdc0:d489fe}} Not a valid INT so convert to a REAL
        ret                       ;{{fdc3:c9}} 

;;=get raw abs of accumulator with reg preserve
get_raw_abs_of_accumulator_with_reg_preserve:;{{Addr=$fdc4 Code Calls/jump count: 5 Data use count: 0}}
        push    bc                ;{{fdc4:c5}} 
        push    hl                ;{{fdc5:e5}} 
        call    get_raw_abs_of_accumulator;{{fdc6:cdccfd}} 
        pop     hl                ;{{fdc9:e1}} 
        pop     bc                ;{{fdca:c1}} 
        ret                       ;{{fdcb:c9}} 

;;=get raw abs of accumulator
;returns A = negative, 0 or positive
get_raw_abs_of_accumulator:       ;{{Addr=$fdcc Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fdcc:cd4fff}} 
        jp      c,unknown_test_HL ;{{fdcf:daf9dd}} 
        jp      REAL_SIGNUMSGN    ;{{fdd2:c394bd}} 

;;=round accumulator
round_accumulator:                ;{{Addr=$fdd5 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{fdd5:e5}} 
        ld      a,c               ;{{fdd6:79}} 
        call    copy_atHL_to_accumulator_type_A;{{fdd7:cd6cff}} 
        pop     de                ;{{fdda:d1}} 
        call    return_accumulator_value_if_int_or_address_if_real;{{fddb:cd4fff}} 
        ld      a,b               ;{{fdde:78}} 
        jr      nc,_round_accumulator_12;{{fddf:300b}}  (+$0b)
        or      a                 ;{{fde1:b7}} 
        ret     p                 ;{{fde2:f0}} 

        call    set_accumulator_as_positive_REAL_from_HL;{{fde3:cd93fe}} 
        call    _round_accumulator_16;{{fde6:cdf4fd}} 
        jp      function_CINT     ;{{fde9:c3b6fe}} 

_round_accumulator_12:            ;{{Addr=$fdec Code Calls/jump count: 1 Data use count: 0}}
        or      a                 ;{{fdec:b7}} 
        jr      nz,_round_accumulator_16;{{fded:2005}}  (+$05)
        ld      de,REAL_TO_BINARY ;{{fdef:116dbd}} firmware REAL to bin
        jr      _function_int_3   ;{{fdf2:1826}}  (+$26)

_round_accumulator_16:            ;{{Addr=$fdf4 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{fdf4:d5}} 
        push    bc                ;{{fdf5:c5}} 
        ld      a,b               ;{{fdf6:78}} 
        call    REAL_10A          ;{{fdf7:cd79bd}} 
        call    c,REAL_TO_BINARY  ;{{fdfa:dc6dbd}} firmware REAL to bin
        ld      a,b               ;{{fdfd:78}} 
        pop     bc                ;{{fdfe:c1}} 
        pop     de                ;{{fdff:d1}} 
        jr      nc,_round_accumulator_29;{{fe00:3008}}  (+$08)
        call    BINARY_TO_REAL    ;{{fe02:cd67bd}} firmware bin to REAL
        xor     a                 ;{{fe05:af}} 
        sub     b                 ;{{fe06:90}} 
        jp      REAL_10A          ;{{fe07:c379bd}}  firmware REAL exp A

_round_accumulator_29:            ;{{Addr=$fe0a Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe0a:eb}} 
        jp      copy_atHL_to_accumulator_using_accumulator_type;{{fe0b:c36fff}} 

;;========================================================
;; function FIX
function_FIX:                     ;{{Addr=$fe0e Code Calls/jump count: 0 Data use count: 1}}
        ld      de,REAL_FIX       ;{{fe0e:1170bd}} firmware REAL fix
        jr      _function_int_1   ;{{fe11:1803}}  (+$03)

;;========================================================
;; function INT
function_INT:                     ;{{Addr=$fe13 Code Calls/jump count: 0 Data use count: 1}}
        ld      de,REAL_INT       ;{{fe13:1173bd}} firmware REAL int
_function_int_1:                  ;{{Addr=$fe16 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fe16:cd4fff}} 
        ret     c                 ;{{fe19:d8}} 

_function_int_3:                  ;{{Addr=$fe1a Code Calls/jump count: 1 Data use count: 0}}
        call    JP_DE             ;{{fe1a:cdfeff}}  JP (DE)
        ret     nc                ;{{fe1d:d0}} 

        ld      a,(accumulator_data_type);{{fe1e:3a9fb0}} 
        call    _function_int_11  ;{{fe21:cd2cfe}} 
        ret     c                 ;{{fe24:d8}} 

        call    get_accumulator_type_in_c_and_addr_in_HL;{{fe25:cd45ff}} 
        ld      a,b               ;{{fe28:78}} 
        jp      BINARY_TO_REAL    ;{{fe29:c367bd}} firmware BIN to REAL

_function_int_11:                 ;{{Addr=$fe2c Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{fe2c:79}} 
        cp      $03               ;{{fe2d:fe03}} 
        ret     nc                ;{{fe2f:d0}} 

        ld      a,(hl)            ;{{fe30:7e}} 
        inc     hl                ;{{fe31:23}} 
        ld      h,(hl)            ;{{fe32:66}} 
        ld      l,a               ;{{fe33:6f}} 
        call    unknown_maths_fixup_B;{{fe34:cd37dd}} 
        ret     nc                ;{{fe37:d0}} 

        jp      store_HL_in_accumulator_as_INT;{{fe38:c335ff}} 

;;=========================================
;;convert accum and param to same numeric type
;(error if either is string).
;C=type of param
convert_accum_and_param_to_same_numeric_type:;{{Addr=$fe3b Code Calls/jump count: 5 Data use count: 0}}
        ld      a,c               ;{{fe3b:79}} C contains a type specifier
        cp      $03               ;{{fe3c:fe03}} 
        jr      z,raise_type_mismatch_error_B;{{fe3e:282d}}  (+$2d) if string?
        ld      a,(accumulator_data_type);{{fe40:3a9fb0}} 
        cp      $03               ;{{fe43:fe03}} 
        jr      z,raise_type_mismatch_error_B;{{fe45:2826}}  (+$26) if string
        cp      c                 ;{{fe47:b9}} 
        jr      z,_convert_accum_and_param_to_same_numeric_type_22;{{fe48:2817}}  (+$17) if same type as C
        jr      nc,_convert_accum_and_param_to_same_numeric_type_17;{{fe4a:300c}}  (+$0c) accum is real C is int
        push    hl                ;{{fe4c:e5}} else accum is int, C is real...
        ld      hl,accumulator_data_type;{{fe4d:219fb0}} ...so convert accum to real
        ld      (hl),c            ;{{fe50:71}} 
        inc     hl                ;{{fe51:23}} 
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe52:cd8cfe}} 
        pop     de                ;{{fe55:d1}} 
        or      a                 ;{{fe56:b7}} 
        ret                       ;{{fe57:c9}} 

_convert_accum_and_param_to_same_numeric_type_17:;{{Addr=$fe58 Code Calls/jump count: 1 Data use count: 0}}
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe58:cd8cfe}} 
        or      a                 ;{{fe5b:b7}} 
_convert_accum_and_param_to_same_numeric_type_19:;{{Addr=$fe5c Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe5c:eb}} 
        ld      hl,accumulator    ;{{fe5d:21a0b0}} 
        ret                       ;{{fe60:c9}} 

_convert_accum_and_param_to_same_numeric_type_22:;{{Addr=$fe61 Code Calls/jump count: 1 Data use count: 0}}
        xor     $02               ;{{fe61:ee02}} 
        jr      nz,_convert_accum_and_param_to_same_numeric_type_19;{{fe63:20f7}}  (-$09)
        ld      e,(hl)            ;{{fe65:5e}} 
        inc     hl                ;{{fe66:23}} 
        ld      d,(hl)            ;{{fe67:56}} 
        ld      hl,(accumulator)  ;{{fe68:2aa0b0}} 
        scf                       ;{{fe6b:37}} 
        ret                       ;{{fe6c:c9}} 

;;=raise Type mismatch error
raise_type_mismatch_error_B:      ;{{Addr=$fe6d Code Calls/jump count: 2 Data use count: 0}}
        jp      raise_type_mismatch_error_C;{{fe6d:c362ff}} 

;;==================================
;;convert accum and param to REAL
convert_accum_and_param_to_REAL:  ;{{Addr=$fe70 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(accumulator_data_type);{{fe70:3a9fb0}} 
        or      c                 ;{{fe73:b1}} 
        cp      $02               ;{{fe74:fe02}} 
        jr      nz,convert_accum_and_param_to_same_numeric_type;{{fe76:20c3}}  (-$3d)

;;=convert INT accum and INT param to REAL
convert_INT_accum_and_INT_param_to_REAL:;{{Addr=$fe78 Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fe78:2aa0b0}} 
        call    set_accumulator_as_positive_REAL_from_HL;{{fe7b:cd93fe}} 
        ld      hl,(execution_stack_next_free_ptr);{{fe7e:2a6fb0}} 
        call    convert_INT_atHL_to_positive_REAL_atHL;{{fe81:cd8cfe}} 
        ex      de,hl             ;{{fe84:eb}} 
        ld      hl,accumulator    ;{{fe85:21a0b0}} 
        ret                       ;{{fe88:c9}} 

;;======================================
;;set accumulator as REAL from unsigned INT
set_accumulator_as_REAL_from_unsigned_INT:;{{Addr=$fe89 Code Calls/jump count: 5 Data use count: 0}}
        xor     a                 ;{{fe89:af}} 
        jr      set_accumulator_from_HL_with_possible_invert;{{fe8a:1808}}  (+$08)

;;=======================================
;;convert INT atHL to positive REAL atHL
convert_INT_atHL_to_positive_REAL_atHL:;{{Addr=$fe8c Code Calls/jump count: 3 Data use count: 0}}
        ld      e,(hl)            ;{{fe8c:5e}} 
        inc     hl                ;{{fe8d:23}} 
        ld      d,(hl)            ;{{fe8e:56}} 
        dec     hl                ;{{fe8f:2b}} 
        ld      a,d               ;{{fe90:7a}} 
        jr      set_atHL_from_DE_with_possible_invert;{{fe91:1808}}  (+$08)

;;=======================================
;;set accumulator as positive REAL from HL
;HL=int value
set_accumulator_as_positive_REAL_from_HL:;{{Addr=$fe93 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,h               ;{{fe93:7c}} 

;;=set accumulator from HL with possible invert
;invert if bit 7 of a is set
set_accumulator_from_HL_with_possible_invert:;{{Addr=$fe94 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe94:eb}} 
        ld      hl,accumulator_data_type;{{fe95:219fb0}} 
        ld      (hl),$05          ;{{fe98:3605}} 
        inc     hl                ;{{fe9a:23}} 

;;=set atHL from DE with possible invert
;invert if bit 7 of a is set
set_atHL_from_DE_with_possible_invert:;{{Addr=$fe9b Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fe9b:eb}} 
        push    af                ;{{fe9c:f5}} 
        or      a                 ;{{fe9d:b7}} 
        call    m,negate_HL_and_test_if_INT;{{fe9e:fceddd}} 
        pop     af                ;{{fea1:f1}} 
        jp      INTEGER_TO_REAL   ;{{fea2:c364bd}} firmware INT to REAL

;;===================================
;;store int to accumulator
store_int_to_accumulator:         ;{{Addr=$fea5 Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator),hl  ;{{fea5:22a0b0}} 

;;=====================================
;;set accumulator as REAL from BINARY zero or minus one
;binary in HL only. (useful only for -1 and zero??)
        ex      de,hl             ;{{fea8:eb}} 
        ld      (accumulator_plus_2),hl;{{fea9:22a2b0}} 
        ld      hl,accumulator_data_type;{{feac:219fb0}} 
        ld      (hl),$05          ;{{feaf:3605}} 
        inc     hl                ;{{feb1:23}} 
        xor     a                 ;{{feb2:af}} 
        jp      BINARY_TO_REAL    ;{{feb3:c367bd}} firmware BIN to REAL

;;========================================================
;; function CINT
function_CINT:                    ;{{Addr=$feb6 Code Calls/jump count: 10 Data use count: 1}}
        call    _function_cint_3  ;{{feb6:cdbcfe}} 
        ret     c                 ;{{feb9:d8}} 

        jr      raise_Overflow_error;{{feba:183f}}  (+$3f)

_function_cint_3:                 ;{{Addr=$febc Code Calls/jump count: 1 Data use count: 0}}
        call    _function_cint_12 ;{{febc:cdcefe}} 
        ld      (accumulator),hl  ;{{febf:22a0b0}} 
        ret                       ;{{fec2:c9}} 

;;-=============================================
;;
_function_cint_6:                 ;{{Addr=$fec3 Code Calls/jump count: 5 Data use count: 0}}
        ld      a,c               ;{{fec3:79}} 
        call    _function_cint_16 ;{{fec4:cdd5fe}} 
        ex      de,hl             ;{{fec7:eb}} 
        call    c,_function_cint_12;{{fec8:dccefe}} carry here means we had a pointer to an int
        ret     c                 ;{{fecb:d8}} 

        jr      raise_Overflow_error;{{fecc:182d}}  (+$2d)

_function_cint_12:                ;{{Addr=$fece Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator_data_type;{{fece:219fb0}} 
        ld      a,(hl)            ;{{fed1:7e}} 
        ld      (hl),$02          ;{{fed2:3602}} 
        inc     hl                ;{{fed4:23}} 
_function_cint_16:                ;{{Addr=$fed5 Code Calls/jump count: 1 Data use count: 0}}
        cp      $03               ;{{fed5:fe03}} 
        jr      c,_function_cint_25;{{fed7:380d}}  (+$0d) if type is int treat it as a pointer to the actual real and redo
        jp      z,raise_type_mismatch_error_C;{{fed9:ca62ff}}  error if string
        push    bc                ;{{fedc:c5}} 
        call    REAL_TO_INTEGER   ;{{fedd:cd6abd}}  firmware REAL to INT
        ld      b,a               ;{{fee0:47}} 
        call    c,unknown_maths_fixup_B;{{fee1:dc37dd}} 
        pop     bc                ;{{fee4:c1}} 
        ret                       ;{{fee5:c9}} 

_function_cint_25:                ;{{Addr=$fee6 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{fee6:7e}} 
        inc     hl                ;{{fee7:23}} 
        ld      h,(hl)            ;{{fee8:66}} 
        ld      l,a               ;{{fee9:6f}} 
        ret                       ;{{feea:c9}} 

;;========================================================
;; function UNT

function_UNT:                     ;{{Addr=$feeb Code Calls/jump count: 4 Data use count: 1}}
        call    return_accumulator_value_if_int_or_address_if_real;{{feeb:cd4fff}} 
        ret     c                 ;{{feee:d8}} 

        call    REAL_TO_INTEGER   ;{{feef:cd6abd}} 
        jr      nc,raise_Overflow_error;{{fef2:3007}}  (+$07)
        ld      b,a               ;{{fef4:47}} 
        call    m,unknown_maths_fixup_B;{{fef5:fc37dd}} 
        jp      c,store_HL_in_accumulator_as_INT;{{fef8:da35ff}} 

;;=raise Overflow error
raise_Overflow_error:             ;{{Addr=$fefb Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{fefb:cd45cb}} 
        defb $06                  ;Inline error code: Overflow

;;=====================================
;;convert accumulator to type in A
;int to real or real to int only
convert_accumulator_to_type_in_A: ;{{Addr=$feff Code Calls/jump count: 5 Data use count: 0}}
        push hl                   ;{{feff:e5}} 
        push    de                ;{{ff00:d5}} 
        push    bc                ;{{ff01:c5}} 
        ld      hl,accumulator_data_type;{{ff02:219fb0}} 
        cp      (hl)              ;{{ff05:be}} 
        call    nz,_convert_accumulator_to_type_in_a_10;{{ff06:c40dff}} 
        pop     bc                ;{{ff09:c1}} 
        pop     de                ;{{ff0a:d1}} 
        pop     hl                ;{{ff0b:e1}} 
        ret                       ;{{ff0c:c9}} 

_convert_accumulator_to_type_in_a_10:;{{Addr=$ff0d Code Calls/jump count: 1 Data use count: 0}}
        sub     $03               ;{{ff0d:d603}} 
        jr      c,function_CINT   ;{{ff0f:38a5}}  (-$5b)
        jp      z,error_if_accumulator_is_not_a_string;{{ff11:ca5eff}} 

;;========================================================
;; function CREAL
function_CREAL:                   ;{{Addr=$ff14 Code Calls/jump count: 4 Data use count: 1}}
        call    return_accumulator_value_if_int_or_address_if_real;{{ff14:cd4fff}} 
        jp      c,set_accumulator_as_positive_REAL_from_HL;{{ff17:da93fe}} 
        ret                       ;{{ff1a:c9}} 

;;========================================
;;zero accumulator
zero_accumulator:                 ;{{Addr=$ff1b Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ff1b:e5}} ##LIT##
        ld      hl,RESET_ENTRY    ;{{ff1c:210000}} 
        ld      (accumulator),hl  ;{{ff1f:22a0b0}} 
        ld      (accumulator_plus_2),hl;{{ff22:22a2b0}} 
        ld      (accumulator_plus_3),hl;{{ff25:22a3b0}} 
        pop     hl                ;{{ff28:e1}} 
        ret                       ;{{ff29:c9}} 

;;========================================================
;; function SGN
function_SGN:                     ;{{Addr=$ff2a Code Calls/jump count: 0 Data use count: 1}}
        call    get_raw_abs_of_accumulator_with_reg_preserve;{{ff2a:cdc4fd}} 

;;=store sign extended byte in A in accumulator
store_sign_extended_byte_in_A_in_accumulator:;{{Addr=$ff2d Code Calls/jump count: 2 Data use count: 0}}
        ld      l,a               ;{{ff2d:6f}} 
        add     a,a               ;{{ff2e:87}} 
        sbc     a,a               ;{{ff2f:9f}} 
        jr      store_AL_in_accumulator_as_INT;{{ff30:1802}}  (+$02)

;;=store A in accumulator as INT
store_A_in_accumulator_as_INT:    ;{{Addr=$ff32 Code Calls/jump count: 10 Data use count: 0}}
        ld      l,a               ;{{ff32:6f}} 
        xor     a                 ;{{ff33:af}} 
;;=store AL in accumulator as INT
store_AL_in_accumulator_as_INT:   ;{{Addr=$ff34 Code Calls/jump count: 2 Data use count: 0}}
        ld      h,a               ;{{ff34:67}} 

;;=store HL in accumulator as INT
store_HL_in_accumulator_as_INT:   ;{{Addr=$ff35 Code Calls/jump count: 16 Data use count: 0}}
        ld      (accumulator),hl  ;{{ff35:22a0b0}} 
;;=set accumulator type to int
set_accumulator_type_to_int:      ;{{Addr=$ff38 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,$02             ;{{ff38:3e02}} int
;;=set accumulator data type
set_accumulator_data_type:        ;{{Addr=$ff3a Code Calls/jump count: 1 Data use count: 0}}
        ld      (accumulator_data_type),a;{{ff3a:329fb0}} 
        ret                       ;{{ff3d:c9}} 

;;=set accumulator type to real and HL to accumulator addr
set_accumulator_type_to_real_and_HL_to_accumulator_addr:;{{Addr=$ff3e Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator    ;{{ff3e:21a0b0}} 
;;=set accumulator type to real
set_accumulator_type_to_real:     ;{{Addr=$ff41 Code Calls/jump count: 3 Data use count: 0}}
        ld      a,$05             ;{{ff41:3e05}} real
        jr      set_accumulator_data_type;{{ff43:18f5}}  (-$0b)

;;======================================
;;get accumulator type in c and addr in HL
get_accumulator_type_in_c_and_addr_in_HL:;{{Addr=$ff45 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,accumulator_data_type;{{ff45:219fb0}} 
        ld      c,(hl)            ;{{ff48:4e}} 
        inc     hl                ;{{ff49:23}} 
        ret                       ;{{ff4a:c9}} 

;;=====================================
;;get accumulator data type
get_accumulator_data_type:        ;{{Addr=$ff4b Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff4b:3a9fb0}} 
        ret                       ;{{ff4e:c9}} 

;;======================================
;;return accumulator value if int or address if real
return_accumulator_value_if_int_or_address_if_real:;{{Addr=$ff4f Code Calls/jump count: 7 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff4f:3a9fb0}} 
        cp      $03               ;{{ff52:fe03}} string
        jr      z,raise_type_mismatch_error_C;{{ff54:280c}}  (+$0c) error if string
        ld      hl,(accumulator)  ;{{ff56:2aa0b0}} 
        ret     c                 ;{{ff59:d8}} 

        ld      hl,accumulator    ;{{ff5a:21a0b0}} 
        ret                       ;{{ff5d:c9}} 

;;==================================
;;error if accumulator is not a string
error_if_accumulator_is_not_a_string:;{{Addr=$ff5e Code Calls/jump count: 6 Data use count: 0}}
        call    is_accumulator_a_string;{{ff5e:cd66ff}} 
        ret     z                 ;{{ff61:c8}} 

;;=raise Type Mismatch error
raise_type_mismatch_error_C:      ;{{Addr=$ff62 Code Calls/jump count: 3 Data use count: 0}}
        call    byte_following_call_is_error_code;{{ff62:cd45cb}} 
        defb $0d                  ;Inline error code: Type mismatch

;;=======================================================
;;is accumulator a string?
is_accumulator_a_string:          ;{{Addr=$ff66 Code Calls/jump count: 14 Data use count: 0}}
        ld      a,(accumulator_data_type);{{ff66:3a9fb0}}  accumulator type
        cp      $03               ;{{ff69:fe03}} string marker
        ret                       ;{{ff6b:c9}} 

;;================
;;copy atHL to accumulator type A
copy_atHL_to_accumulator_type_A:  ;{{Addr=$ff6c Code Calls/jump count: 7 Data use count: 0}}
        ld      (accumulator_data_type),a;{{ff6c:329fb0}} 
;;=copy atHL to accumulator using accumulator type
copy_atHL_to_accumulator_using_accumulator_type:;{{Addr=$ff6f Code Calls/jump count: 2 Data use count: 0}}
        ld      de,accumulator    ;{{ff6f:11a0b0}} 
        jr      copy_value_atHL_to_atDE_accumulator_type;{{ff72:1813}}  (+$13)

;;================
;;probably push accumulator on execution stack
probably_push_accumulator_on_execution_stack:;{{Addr=$ff74 Code Calls/jump count: 4 Data use count: 0}}
        push    de                ;{{ff74:d5}} 
        push    hl                ;{{ff75:e5}} 
        ld      a,(accumulator_data_type);{{ff76:3a9fb0}} 
        ld      c,a               ;{{ff79:4f}} 
        call    possibly_alloc_A_bytes_on_execution_stack;{{ff7a:cd72f6}} 
        call    copy_numeric_accumulator_to_atHL;{{ff7d:cd83ff}} 
        pop     hl                ;{{ff80:e1}} 
        pop     de                ;{{ff81:d1}} 
        ret                       ;{{ff82:c9}} 

;;========================================
;;copy numeric accumulator to atHL
copy_numeric_accumulator_to_atHL: ;{{Addr=$ff83 Code Calls/jump count: 6 Data use count: 0}}
        ex      de,hl             ;{{ff83:eb}} 
        ld      hl,accumulator    ;{{ff84:21a0b0}} 

;;=copy value atHL to atDE accumulator type
copy_value_atHL_to_atDE_accumulator_type:;{{Addr=$ff87 Code Calls/jump count: 3 Data use count: 0}}
        push    bc                ;{{ff87:c5}} 
        ld      a,(accumulator_data_type);{{ff88:3a9fb0}} 
        ld      c,a               ;{{ff8b:4f}} 
        ld      b,$00             ;{{ff8c:0600}} 
        ldir                      ;{{ff8e:edb0}} 
        pop     bc                ;{{ff90:c1}} 
        ret                       ;{{ff91:c9}} 



;;***Utilities.asm
;;<< UTILITY ROUTINES
;;< Assorted memory copies, table lookups etc.
;;=========================================================
;; test if letter

test_if_letter:                   ;{{Addr=$ff92 Code Calls/jump count: 4 Data use count: 0}}
        call    convert_character_to_upper_case;{{ff92:cdabff}} ; convert character to upper case

        cp      $41               ;{{ff95:fe41}} ; 'A'
        ccf                       ;{{ff97:3f}} 
        ret     nc                ;{{ff98:d0}} 
        cp      $5b               ;{{ff99:fe5b}} ; 'Z'+1
        ret                       ;{{ff9b:c9}} 

;;=========================================
;; test if letter period or digit
test_if_letter_period_or_digit:   ;{{Addr=$ff9c Code Calls/jump count: 7 Data use count: 0}}
        call    test_if_letter    ;{{ff9c:cd92ff}} 
        ret     c                 ;{{ff9f:d8}} 

;;+----------------------------------------
;; test if period or digit
test_if_period_or_digit:          ;{{Addr=$ffa0 Code Calls/jump count: 2 Data use count: 0}}
        cp      $2e               ;{{ffa0:fe2e}}  '.'
        scf                       ;{{ffa2:37}} 
        ret     z                 ;{{ffa3:c8}} 

;;+----------------------------------------
;; test if digit
;;
;; entry:
;; A = character
;; exit:
;; carry clear = not a digit
;; carry set = is a digit

test_if_digit:                    ;{{Addr=$ffa4 Code Calls/jump count: 4 Data use count: 0}}
        cp      $30               ;{{ffa4:fe30}}  '0'
        ccf                       ;{{ffa6:3f}} 
        ret     nc                ;{{ffa7:d0}} 
        cp      $3a               ;{{ffa8:fe3a}}  '9'+1
        ret                       ;{{ffaa:c9}} 

;;========================================================
;; convert character to upper case

convert_character_to_upper_case:  ;{{Addr=$ffab Code Calls/jump count: 6 Data use count: 1}}
        cp      $61               ;{{ffab:fe61}} 
        ret     c                 ;{{ffad:d8}} 

        cp      $7b               ;{{ffae:fe7b}} 
        ret     nc                ;{{ffb0:d0}} 

        sub     $20               ;{{ffb1:d620}} 
        ret                       ;{{ffb3:c9}} 

;;=========================================================
;; get address from table
;; HL = address of table
;; A = code to find in table
;;
;; table header:
;; 0: count
;; 1,2: address to return to if not found

;; each entry in table:
;; offset 0: code
;; offset 1,2: address

get_address_from_table:           ;{{Addr=$ffb4 Code Calls/jump count: 3 Data use count: 0}}
        push    af                ;{{ffb4:f5}} 
        push    bc                ;{{ffb5:c5}} 
        ld      b,(hl)            ;{{ffb6:46}}  count in table
        inc     hl                ;{{ffb7:23}} 
        push    hl                ;{{ffb8:e5}}  save ptr to 'not found' routine

_get_address_from_table_5:        ;{{Addr=$ffb9 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{ffb9:23}} 
        inc     hl                ;{{ffba:23}} 
        cp      (hl)              ;{{ffbb:be}}  code = comparison
        inc     hl                ;{{ffbc:23}} 
        jr      z,_get_address_from_table_12;{{ffbd:2803}}  code found?
        djnz    _get_address_from_table_5;{{ffbf:10f8}}  

;;-----------------------------------------------
;; code not found
;;
;; get address from start of table; putting address of end of table onto stack
        ex      (sp),hl           ;{{ffc1:e3}} retrieve ptr to 'not found' routine
;;-----------------------------------------------
;; code found or not found

_get_address_from_table_12:       ;{{Addr=$ffc2 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{ffc2:f1}} remove unwanted from stack - either 'not found' routine or junk from prev. instr

;; get address from table
        ld      a,(hl)            ;{{ffc3:7e}} 
        inc     hl                ;{{ffc4:23}} 
        ld      h,(hl)            ;{{ffc5:66}} 
        ld      l,a               ;{{ffc6:6f}} 
;;-----------------------------------------------
        pop     bc                ;{{ffc7:c1}} 
        pop     af                ;{{ffc8:f1}} 
        ret                       ;{{ffc9:c9}} 

;;=========================================================
;; check if byte exists in table
;;
;; HL = base address of table (table terminated with 0)
;; A = value
;;
;; carry set = byte exists in table
;; carry clear = byte doesn't exist
;; All other registers preserved

check_if_byte_exists_in_table:    ;{{Addr=$ffca Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{ffca:c5}} 
        ld      c,a               ;{{ffcb:4f}} ; C = byte to compare against

_check_if_byte_exists_in_table_2: ;{{Addr=$ffcc Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{ffcc:7e}} ; get byte from table
;; table terminator?
        or      a                 ;{{ffcd:b7}} 
        jr      z,_check_if_byte_exists_in_table_9;{{ffce:2805}} 
        inc     hl                ;{{ffd0:23}} 
;; same as byte we want
        cp      c                 ;{{ffd1:b9}} 
        jr      nz,_check_if_byte_exists_in_table_2;{{ffd2:20f8}}  (-$08)
;; byte found in table
        scf                       ;{{ffd4:37}} 
;; byte found or not found 
_check_if_byte_exists_in_table_9: ;{{Addr=$ffd5 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,c               ;{{ffd5:79}} 
        pop     bc                ;{{ffd6:c1}} 
        ret                       ;{{ffd7:c9}} 

;;=========================================================
;; compare HL DE
compare_HL_DE:                    ;{{Addr=$ffd8 Code Calls/jump count: 30 Data use count: 0}}
        ld      a,h               ;{{ffd8:7c}} 
        sub     d                 ;{{ffd9:92}} 
        ret     nz                ;{{ffda:c0}} 
        ld      a,l               ;{{ffdb:7d}} 
        sub     e                 ;{{ffdc:93}} 
        ret                       ;{{ffdd:c9}} 

;;=========================================================
;; compare HL BC
compare_HL_BC:                    ;{{Addr=$ffde Code Calls/jump count: 10 Data use count: 0}}
        ld      a,h               ;{{ffde:7c}} 
        sub     b                 ;{{ffdf:90}} 
        ret     nz                ;{{ffe0:c0}} 
        ld      a,l               ;{{ffe1:7d}} 
        sub     c                 ;{{ffe2:91}} 
        ret                       ;{{ffe3:c9}} 
    
;;=========================================================
;; BC equal HL minus DE
;;
;; HL,DE preserved
;; flags corrupt

BC_equal_HL_minus_DE:             ;{{Addr=$ffe4 Code Calls/jump count: 8 Data use count: 0}}
        push    hl                ;{{ffe4:e5}} ; store HL
        or      a                 ;{{ffe5:b7}} 
        sbc     hl,de             ;{{ffe6:ed52}} ; HL = HL - DE
        ld      b,h               ;{{ffe8:44}} ; BC = HL - DE
        ld      c,l               ;{{ffe9:4d}} 
        pop     hl                ;{{ffea:e1}} ; restore HL
        ret                       ;{{ffeb:c9}} 

;;=========================================================
;; copy bytes LDIR  (A=count, HL=source, DE=dest)
;;
;; HL = source
;; DE = destination
;; A = count

copy_bytes_LDIR__Acount_HLsource_DEdest:;{{Addr=$ffec Code Calls/jump count: 6 Data use count: 0}}
        ld      c,a               ;{{ffec:4f}} 
        ld      b,$00             ;{{ffed:0600}} 
;; BC = count

;;+--------------------------------------------------------------
;; copy bytes LDIR (BC=count, HL=source, DE=dest)
;; BC=0?
copy_bytes_LDIR_BCcount_HLsource_DEdest:;{{Addr=$ffef Code Calls/jump count: 2 Data use count: 0}}
        ld      a,b               ;{{ffef:78}} 
        or      c                 ;{{fff0:b1}} 
        ret     z                 ;{{fff1:c8}} 

;; copy if BC<>0
        ldir                      ;{{fff2:edb0}} 
        ret                       ;{{fff4:c9}} 

;;=========================================================
;; copy bytes LDDR (BC=count, HL=source, DE=dest)
;; BC=0?
copy_bytes_LDDR_BCcount_HLsource_DEdest:;{{Addr=$fff5 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,b               ;{{fff5:78}} 
        or      c                 ;{{fff6:b1}} 
        ret     z                 ;{{fff7:c8}} 
;; copy if BC<>0
        lddr                      ;{{fff8:edb8}} 
        ret                       ;{{fffa:c9}} 

;;=========================================================
;; JP (HL)
JP_HL:                            ;{{Addr=$fffb Code Calls/jump count: 2 Data use count: 0}}
        jp      (hl)              ;{{fffb:e9}} 

;;=========================================================
;; JP (BC)
JP_BC:                            ;{{Addr=$fffc Code Calls/jump count: 7 Data use count: 0}}
        push    bc                ;{{fffc:c5}} 
        ret                       ;{{fffd:c9}} 

;;=========================================================
;; JP (DE)
JP_DE:                            ;{{Addr=$fffe Code Calls/jump count: 6 Data use count: 0}}
        push    de                ;{{fffe:d5}} 
        ret                       ;{{ffff:c9}} 
;;--------------------------------------------------------------
