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
        ld      hl,power_operator_parameter;{{d53c:21b2ad}} 
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





