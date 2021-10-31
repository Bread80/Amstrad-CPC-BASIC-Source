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
        call    internal_subroutine__not_useful_C;{{c022:cdbbbd}}  maths function - initialise random number generator?
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





