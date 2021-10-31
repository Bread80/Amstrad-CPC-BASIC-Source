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

;**tk
