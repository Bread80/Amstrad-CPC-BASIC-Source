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



