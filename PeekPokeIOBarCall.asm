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







