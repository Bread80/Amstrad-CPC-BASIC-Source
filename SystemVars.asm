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





