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
        ld      ($ae5d),a         ;{{f391:325dae}} 
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
        ld      ($ae5d),a         ;{{f3bd:325dae}} 
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
        ld      a,($ae5d)         ;{{f420:3a5dae}} 
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

        ld      a,($ae5d)         ;{{f435:3a5dae}} 
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





