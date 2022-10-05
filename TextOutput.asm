;;<< TEXT OUTPUT (ZONE, PRINT, WRITE)
;;=====================================
;;set zone 13
set_zone_13:                      ;{{Addr=$f299 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$0d             ;{{f299:3e0d}} 
        jr      _command_zone_1   ;{{f29b:1803}}  (+$03)

;;========================================================================
;; command ZONE
;ZONE <integer expression>
;Sets the print zone width. Values 1..255

command_ZONE:                     ;{{Addr=$f29d Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_int_less_than_256;{{f29d:cdc3ce}} 
_command_zone_1:                  ;{{Addr=$f2a0 Code Calls/jump count: 1 Data use count: 0}}
        ld      (ZONE_value),a    ;{{f2a0:325cae}} 
        ret                       ;{{f2a3:c9}} 

;;========================================================================
;; command PRINT
;PRINT [#<stream expression>,][<print list>][<using clause>][<separator>]
;where
;<print list>   is: <print item>[<separator><print item>]*
;<print item>   is: <expression>
;               or: SPC(<integer expression>)
;               or: TAB(<integer expression>)
;<using clause> is: USING <string expression>;<using list>
;<using list>   is: <expression>[<separator><expression>]*
;<separator>    is: comma or semi-colon

;* - these items can be repeated zero or more times

;Print items to the specified stream
;SPC(..) prints the given number of spaces
;TAB(..) moves to the given tab position
;A trailing SPC, TAB or separator prevents a new line being printed
;USING:
;   Valid formatting characters:  ! \ & # . + - * $ ^ , _
;   _   prints the following character as a literal
;   String formatting:
;       !   Prints first character of string
;       \  \    Prints n characters where n equals the number of spaces between \ chars
;       &   Prints the entire string
;   Number formatting:
;       #   Specifies a digit position
;       .   Specifies position of decimal point
;       ,   (before .) Digits will be in groups of three separated by commas
;       $$  (Before number): leading $ sign
;       **  (Before number): leading spaces will be replaced by *
;       **$ (Before number): combination of previous two items
;       +   (Before number): print leading + sign if positive
;       +   (After number):  print trailing + if positive
;       -   (After number):  print trailing + or - sign
;       ^^^^ (After number): print exponent

;If the number can't be displayed in the chosen format a leading % is printed

command_PRINT:                    ;{{Addr=$f2a4 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_following_on_evalled_stream_and_swap_back;{{f2a4:cdcfc1}} 
                                  ;This routine evals a stream number (if present),
                                  ;swaps to it,
                                  ;CALLs the following code (popping address of the stack), 
                                  ;swaps back to original stream,
                                  ;returns to the caller

        call    is_next_02        ;{{f2a7:cd3dde}} 
        jp      c,output_new_line ;{{f2aa:da98c3}} No parameters

;;=print item loop
;Loop though each parameter/item
print_item_loop:                  ;{{Addr=$f2ad Code Calls/jump count: 1 Data use count: 0}}
        cp      $ed               ;{{f2ad:feed}} "USING"
        jp      z,PRINT_USING     ;{{f2af:ca7ef3}} 
        ex      de,hl             ;{{f2b2:eb}} 
        ld      hl,PRINT_parameters_LUT;{{f2b3:21c3f2}} Look up the routine tom process the item in the following table...
        call    get_address_from_table;{{f2b6:cdb4ff}} ...or PRINT_do_other for general items
        ex      de,hl             ;{{f2b9:eb}} 
        call    JP_DE             ;{{f2ba:cdfeff}}  JP (DE)
        call    is_next_02        ;{{f2bd:cd3dde}} Next item
        jr      nc,print_item_loop;{{f2c0:30eb}}  (-$15) Loop if not end of statement/line
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
;Anything other than comma, semicolon, SPC, TAB or USING
PRINT_do_other:                   ;{{Addr=$f2d2 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{f2d2:cd62cf}} 
        push    af                ;{{f2d5:f5}} 
        push    hl                ;{{f2d6:e5}} 
        call    is_accumulator_a_string;{{f2d7:cd66ff}} Parameter type
        jr      z,PRINT_do_string ;{{f2da:280f}}  (+$0f) String

;Print number
        call    conv_number_to_decimal_string;{{f2dc:cd68ef}} Convert to string
        call    get_ASCIIZ_string ;{{f2df:cd8af8}} Put string in accumulator
        ld      (hl),$20          ;{{f2e2:3620}} " " - leading space?
        ld      hl,(accumulator)  ;{{f2e4:2aa0b0}} Addr of string descriptor
        inc     (hl)              ;{{f2e7:34}} inc string length
        ld      a,(hl)            ;{{f2e8:7e}} Get string length
        jr      PRINT_do_string_skip_A_chars;{{f2e9:181f}}  (+$1f)

;;=PRINT do string
PRINT_do_string:                  ;{{Addr=$f2eb Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(accumulator)  ;{{f2eb:2aa0b0}} HL=string descriptor
        ld      b,(hl)            ;{{f2ee:46}} B-length
        ld      c,$00             ;{{f2ef:0e00}} 
        inc     hl                ;{{f2f1:23}} 
        ld      a,(hl)            ;{{f2f2:7e}} HL=string address
        inc     hl                ;{{f2f3:23}} 
        ld      h,(hl)            ;{{f2f4:66}} 
        ld      l,a               ;{{f2f5:6f}} 
        inc     b                 ;{{f2f6:04}} 
        jr      PRINT_do_test_string_wrap;{{f2f7:180e}}  (+$0e)

;;=PRINT do string wrap loop
;Test for leading control codes to see if we need to wrap to next line and ignore them(?)
PRINT_do_string_wrap_loop:        ;{{Addr=$f2f9 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f2f9:7e}} 
        cp      $20               ;{{f2fa:fe20}} Control code < $20 " "
        inc     hl                ;{{f2fc:23}} 
        jr      nc,_print_do_string_wrap_loop_9;{{f2fd:3007}}  (+$07) Control code
        dec     a                 ;{{f2ff:3d}} 
        jr      nz,PRINT_do_string_skip_C_chars;{{f300:2007}}  (+$07) Not control code $01 - print symbol given by parameter(?)
        dec     b                 ;{{f302:05}} 
        jr      z,PRINT_do_string_skip_C_chars;{{f303:2804}}  (+$04) End of string
        inc     hl                ;{{f305:23}} 
_print_do_string_wrap_loop_9:     ;{{Addr=$f306 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{f306:0c}} 
;;=PRINT do test string wrap
PRINT_do_test_string_wrap:        ;{{Addr=$f307 Code Calls/jump count: 1 Data use count: 0}}
        djnz    PRINT_do_string_wrap_loop;{{f307:10f0}}  (-$10)

;;=PRINT do string skip C chars
PRINT_do_string_skip_C_chars:     ;{{Addr=$f309 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f309:79}} 
;;=PRINT do string skip A chars
PRINT_do_string_skip_A_chars:     ;{{Addr=$f30a Code Calls/jump count: 1 Data use count: 0}}
        call    poss_validate_xpos_in_D;{{f30a:cde7c2}} 
        call    nc,output_new_line;{{f30d:d498c3}} Nothing to print?
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
        sub     c                 ;{{f324:91}} C=chars to next print zone?
        jr      nc,_print_do_comma_5;{{f325:30fd}}  (-$03)

        cpl                       ;{{f327:2f}} 
        inc     a                 ;{{f328:3c}} A=current print position
        ld      b,a               ;{{f329:47}} 
        add     a,c               ;{{f32a:81}} A=new print position
        call    poss_validate_xpos_in_D;{{f32b:cde7c2}} 
        jp      nc,output_new_line;{{f32e:d298c3}} ; new text line
        ld      a,b               ;{{f331:78}} 
        jr      PRINT_do_B_minus_1_spaces;{{f332:181e}}  (+$1e)

;;+PRINT do SPC
PRINT_do_SPC:                     ;{{Addr=$f334 Code Calls/jump count: 0 Data use count: 1}}
        call    PRINT_do_eval_SPC_TAB_parameter;{{f334:cd5df3}} 
        call    PRINT_do_process_SPC_TAB_parameter;{{f337:cd69f3}} 
        ld      a,e               ;{{f33a:7b}} 
        jr      PRINT_do_B_minus_1_spaces;{{f33b:1815}}  (+$15)

;;+PRINT do TAB
PRINT_do_TAB:                     ;{{Addr=$f33d Code Calls/jump count: 0 Data use count: 1}}
        call    PRINT_do_eval_SPC_TAB_parameter;{{f33d:cd5df3}} 
        dec     de                ;{{f340:1b}} 
        call    PRINT_do_process_SPC_TAB_parameter;{{f341:cd69f3}} 
        call    get_xpos_of_output_stream;{{f344:cdb9c2}} 
        cpl                       ;{{f347:2f}} 
        inc     a                 ;{{f348:3c}} 
        inc     e                 ;{{f349:1c}} 
        add     a,e               ;{{f34a:83}} 
        jr      c,PRINT_do_B_minus_1_spaces;{{f34b:3805}}  (+$05)
        call    output_new_line   ;{{f34d:cd98c3}} ; new text line
        dec     e                 ;{{f350:1d}} 
        ld      a,e               ;{{f351:7b}} 

;;=PRINT do B minus 1 spaces
PRINT_do_B_minus_1_spaces:        ;{{Addr=$f352 Code Calls/jump count: 4 Data use count: 0}}
        ld      b,a               ;{{f352:47}} 
        inc     b                 ;{{f353:04}} 
_print_do_b_minus_1_spaces_2:     ;{{Addr=$f354 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{f354:05}} 
        ret     z                 ;{{f355:c8}} 

        ld      a,$20             ;{{f356:3e20}}  ' '
        call    output_char       ;{{f358:cda0c3}} ; display text char
        jr      _print_do_b_minus_1_spaces_2;{{f35b:18f7}}  (-$09) Loop


;;=PRINT do eval SPC TAB parameter
PRINT_do_eval_SPC_TAB_parameter:  ;{{Addr=$f35d Code Calls/jump count: 2 Data use count: 0}}
        call    get_next_token_skipping_space;{{f35d:cd2cde}}  get next token skipping space
        call    next_token_if_open_bracket;{{f360:cd19de}}  check for open bracket
        call    eval_expr_as_int  ;{{f363:cdd8ce}}  get number
        jp      next_token_if_close_bracket;{{f366:c31dde}}  check for close bracket

;;=PRINT do process SPC TAB parameter
;Calc new print position?
PRINT_do_process_SPC_TAB_parameter:;{{Addr=$f369 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,d               ;{{f369:7a}} 
        rla                       ;{{f36a:17}} 
        jr      nc,_print_do_process_spc_tab_parameter_4;{{f36b:3003}}  (+$03)
        ld      de,$0000          ;{{f36d:110000}} ##LIT##
_print_do_process_spc_tab_parameter_4:;{{Addr=$f370 Code Calls/jump count: 1 Data use count: 0}}
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
        call    eval_expr_and_error_if_not_string;{{f381:cd09cf}} Format string paramater
        call    next_token_if_equals_inline_data_byte;{{f384:cd25de}} 
        defb $3b                  ;inline token to test ";"
        push    hl                ;{{f388:e5}} 
        ld      hl,(accumulator)  ;{{f389:2aa0b0}} Address of format string descriptor
        ex      (sp),hl           ;{{f38c:e3}} 
        call    eval_expression   ;{{f38d:cd62cf}} Eval first number to format
        xor     a                 ;{{f390:af}} Flag=We have parameters to insert
        ld      (end_of_PRINT_USING_expr_list_flag),a;{{f391:325dae}} 

;;=print using format string loop
;Loops through the format string looking for parameters to format and insert
;If we reach the end of the format string and there are more parameters to insert then
;restart the format string
print_using_format_string_loop:   ;{{Addr=$f394 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f394:d1}} Get format string descriptor
        push    de                ;{{f395:d5}} 
        ex      de,hl             ;{{f396:eb}} 
        ld      b,(hl)            ;{{f397:46}} B=Format string length
        inc     hl                ;{{f398:23}} 
        ld      a,(hl)            ;{{f399:7e}} HL=Format string address
        inc     hl                ;{{f39a:23}} 
        ld      h,(hl)            ;{{f39b:66}} 
        ld      l,a               ;{{f39c:6f}} 
        ex      de,hl             ;{{f39d:eb}} 
        call    print_using_item  ;{{f39e:cdcdf3}} Print item
        jp      nc,raise_improper_argument_error_F;{{f3a1:d2abf4}} NC if zero length format string or format string contains nothing to substitute

;;=print using expr loop
print_using_expr_loop:            ;{{Addr=$f3a4 Code Calls/jump count: 1 Data use count: 0}}
        call    is_next_02        ;{{f3a4:cd3dde}} 
        jr      c,print_using_end_of_parameters;{{f3a7:3811}}  (+$11) End of line/statement
        call    is_A_print_separator;{{f3a9:cdeff3}} 
        jr      z,print_using_end_of_parameters;{{f3ac:280c}}  (+$0c) End if not a valid separator
        push    de                ;{{f3ae:d5}} 
        call    eval_expression   ;{{f3af:cd62cf}} Eval next expression to format
        pop     de                ;{{f3b2:d1}} 
        call    print_using_item  ;{{f3b3:cdcdf3}} Print item
        jr      nc,print_using_format_string_loop;{{f3b6:30dc}}  (-$24) reached end of format string loop so restart it more following parameters
        jr      print_using_expr_loop;{{f3b8:18ea}}  (-$16) Loop for more expressions

;;=print using end of parameters
print_using_end_of_parameters:    ;{{Addr=$f3ba Code Calls/jump count: 2 Data use count: 0}}
        push    af                ;{{f3ba:f5}} 
        ld      a,$ff             ;{{f3bb:3eff}} Set flag to show there are no more parameters available to insert
        ld      (end_of_PRINT_USING_expr_list_flag),a;{{f3bd:325dae}} 
        call    print_using_item  ;{{f3c0:cdcdf3}} 
        pop     af                ;{{f3c3:f1}} 
        call    c,output_new_line ;{{f3c4:dc98c3}} ; new text line
        ex      (sp),hl           ;{{f3c7:e3}} 
        call    pop_TOS_from_string_stack_and_strings_area;{{f3c8:cd03fc}} 
        pop     hl                ;{{f3cb:e1}} 
        ret                       ;{{f3cc:c9}} 

;;=print using item
;Starting from current position in format string looks for the next item to substitute
;printing any literals it comes across along the way. Ends once an item has been subbed or
;at end of format string
;B=chars remaining in format string
;DE=current position in format string

;Returns Carry set if we subbed an item
;DE=addr of next char in format string
print_using_item:                 ;{{Addr=$f3cd Code Calls/jump count: 3 Data use count: 0}}
        ld      a,b               ;{{f3cd:78}} End of format string
        or      a                 ;{{f3ce:b7}} 
        ret     z                 ;{{f3cf:c8}} 

        push    hl                ;{{f3d0:e5}} 

_print_using_item_4:              ;{{Addr=$f3d1 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f3d1:1a}} 
        cp      $5f               ;{{f3d2:fe5f}} "_" Next char is a literal
        jr      nz,_print_using_item_12;{{f3d4:2007}}  (+$07)
        inc     de                ;{{f3d6:13}} 
        djnz    _print_using_item_15;{{f3d7:100c}}  (+$0c)
        inc     b                 ;{{f3d9:04}} 
        dec     de                ;{{f3da:1b}} 
        jr      _print_using_item_15;{{f3db:1808}}  (+$08)

_print_using_item_12:             ;{{Addr=$f3dd Code Calls/jump count: 1 Data use count: 0}}
        call    print_using_string_item;{{f3dd:cdf7f3}} Returns C set if item subbed
        call    nc,PRINT_USING_number_item;{{f3e0:d431f4}} Returns C set if item subbed
        jr      c,_print_using_item_20;{{f3e3:3808}}  (+$08) Done once item subbed 
_print_using_item_15:             ;{{Addr=$f3e5 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{f3e5:1a}} 
        call    output_char       ;{{f3e6:cda0c3}}  display text char
        inc     de                ;{{f3e9:13}} 
        djnz    _print_using_item_4;{{f3ea:10e5}}  (-$1b)

        or      a                 ;{{f3ec:b7}} 
_print_using_item_20:             ;{{Addr=$f3ed Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f3ed:e1}} 
        ret                       ;{{f3ee:c9}} 

;;=is A print separator
;Is A a ';' or ',' token. Returns Z flag set if either was found
is_A_print_separator:             ;{{Addr=$f3ef Code Calls/jump count: 2 Data use count: 0}}
        cp      $3b               ;{{f3ef:fe3b}} ";"
        jp      z,get_next_token_skipping_space;{{f3f1:ca2cde}}  get next token skipping space
        jp      next_token_if_comma;{{f3f4:c315de}}  check for comma

;;=print using string item
;Do if format is one for strings, otherwise returns NC
print_using_string_item:          ;{{Addr=$f3f7 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f3f7:1a}} 
        ld      c,$00             ;{{f3f8:0e00}} 
        cp      $26               ;{{f3fa:fe26}} "&" Print entire string
        jr      z,_print_using_do_string_2;{{f3fc:281e}}  (+$1e)
        inc     c                 ;{{f3fe:0c}} 
        cp      $21               ;{{f3ff:fe21}} "!" Print first character only
        jr      z,_print_using_do_string_2;{{f401:2819}}  (+$19)
        xor     $5c               ;{{f403:ee5c}} "\" Print number of chars equivalent to number of spaces between \ and \
        ret     nz                ;{{f405:c0}} 

        push    bc                ;{{f406:c5}} 
        push    de                ;{{f407:d5}} 

_print_using_string_item_11:      ;{{Addr=$f408 Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f408:13}} Count number of chars (spaces) in C
        dec     b                 ;{{f409:05}} 
        jr      z,_print_using_string_item_20;{{f40a:280a}}  (+$0a) Premature and of string
        inc     c                 ;{{f40c:0c}} 
        ld      a,(de)            ;{{f40d:1a}} 
        cp      $5c               ;{{f40e:fe5c}} "\"
        jr      z,PRINT_USING_do_string;{{f410:2808}}  (+$08) End of specifier
        cp      $20               ;{{f412:fe20}} " "
        jr      z,_print_using_string_item_11;{{f414:28f2}}  (-$0e) Loop

_print_using_string_item_20:      ;{{Addr=$f416 Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f416:d1}} 
        pop     bc                ;{{f417:c1}} 
        or      a                 ;{{f418:b7}} 
        ret                       ;{{f419:c9}} 

;;=PRINT USING do string
;C=number of leading chars of string to print. $00=entire string
PRINT_USING_do_string:            ;{{Addr=$f41a Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{f41a:f1}} 
        pop     af                ;{{f41b:f1}} 
_print_using_do_string_2:         ;{{Addr=$f41c Code Calls/jump count: 2 Data use count: 0}}
        inc     de                ;{{f41c:13}} 
        dec     b                 ;{{f41d:05}} 
        push    bc                ;{{f41e:c5}} 
        push    de                ;{{f41f:d5}} 
        ld      a,(end_of_PRINT_USING_expr_list_flag);{{f420:3a5dae}} Don't print if we've exhausted all the parameters in PRINT statement
        or      a                 ;{{f423:b7}} 
        jr      nz,_print_using_do_string_12;{{f424:2007}}  (+$07)
        call    prob_output_first_C_chars_of_accumulator_string;{{f426:cddcf8}} 
        ld      a,c               ;{{f429:79}} If string shorter than format specifier, pad with spaces
        call    PRINT_do_B_minus_1_spaces;{{f42a:cd52f3}} 
_print_using_do_string_12:        ;{{Addr=$f42d Code Calls/jump count: 1 Data use count: 0}}
        pop     de                ;{{f42d:d1}} 
        pop     bc                ;{{f42e:c1}} 
        scf                       ;{{f42f:37}} 
        ret                       ;{{f430:c9}} 

;;=PRINT USING number item
PRINT_USING_number_item:          ;{{Addr=$f431 Code Calls/jump count: 1 Data use count: 0}}
        call    parse_number_format_template;{{f431:cd48f4}} 
        ret     nc                ;{{f434:d0}} 

        ld      a,(end_of_PRINT_USING_expr_list_flag);{{f435:3a5dae}} Don't print if we've exhausted all the parameters in PRINT statement
        or      a                 ;{{f438:b7}} 
        jr      nz,_print_using_number_item_12;{{f439:200b}}  (+$0b)
        push    bc                ;{{f43b:c5}} 
        push    de                ;{{f43c:d5}} 
        ld      a,c               ;{{f43d:79}} 
        call    convert_number_to_string_by_format;{{f43e:cd6aef}} Number to string
        call    output_ASCIIZ_string;{{f441:cd8bc3}} and output it
        pop     de                ;{{f444:d1}} 
        pop     bc                ;{{f445:c1}} 
_print_using_number_item_12:      ;{{Addr=$f446 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{f446:37}} 
        ret                       ;{{f447:c9}} 

;;===============================================
;;=parse number format template
;DE=addr of format template
;B=length of format template
;Valid chars in format template: + - $ £ * # , . ^

;A returns the number of (printable?) chars in the template
;C returns a bitwise set of flags:
;Bit    Hex
;7      $80 Always set - indicates we have a format 
;            (as opposed to calling the conversion routines without a format)
;6      &40 Exponent ('^^^^' at the end)
;5      $20 Asterisk prefix
;4      $10 If clear then show sign prefix, otherwise sign suffix
;3      $08 If bit 4 set, bit 3 set specifies always show sign prefix, even for positive numbers
;                         bit 3 clear specifies sign prefix only if negative
;                         bit 3 clear specifies sign prefix only if negative
;           If bit 4 clear, bit 3 clear specifies sign suffix of '-' or space
;                           bit 3 set specifies sign suffix of '-' or '+'
;2      &04 Currency symbol prefix (actual symbol is stored at &ae54)
;1      &02 Contains comma(s)
;(Bit zero is used as a flag when doing conversions)

;During processing:
;H=count of the number of chars before the decimal point
;L=the number of chars after the decimal point, including the decimal point (when processing the hash stuff)
;Thus H + L is the total number of chars (when in the hash stuff)

parse_number_format_template:     ;{{Addr=$f448 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{f448:c5}} 
        push    de                ;{{f449:d5}} 
        ld      c,$80             ;{{f44a:0e80}} Set bit 7 to show we have a format
        ld      h,$00             ;{{f44c:2600}} Init character counter
        ld      a,(de)            ;{{f44e:1a}} 

        cp      $2b               ;{{f44f:fe2b}}  '+' - sign prefix
        jr      nz,_parse_number_format_template_12;{{f451:2007}} 
        inc     de                ;{{f453:13}} 
        dec     b                 ;{{f454:05}} 
        jr      z,template_error  ;{{f455:2824}}  (+$24)
        inc     h                 ;{{f457:24}} 
        ld      c,$88             ;{{f458:0e88}} Bit 7 = we have a format, Bit 4=sign prefix

_parse_number_format_template_12: ;{{Addr=$f45a Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f45a:1a}} 
        cp      $2e               ;{{f45b:fe2e}}  '.'
        jr      z,template_period ;{{f45d:2820}} 
        cp      $23               ;{{f45f:fe23}}  '#'
        jr      z,template_hash   ;{{f461:283e}} 
        inc     de                ;{{f463:13}} 
        dec     b                 ;{{f464:05}} 
        jr      z,template_error  ;{{f465:2814}}  (+$14)

        ex      de,hl             ;{{f467:eb}} Test for currency symbols or asterisk
        cp      (hl)              ;{{f468:be}} 
        ex      de,hl             ;{{f469:eb}} 
        jr      nz,template_error ;{{f46a:200f}}  (+$0f)
        inc     h                 ;{{f46c:24}} 
        inc     h                 ;{{f46d:24}} 
        ld      l,$04             ;{{f46e:2e04}} Flags bit 2 = currency symbol
        call    test_for_currency_symbols;{{f470:cd02f5}} 
        jr      z,template_currency_symbol;{{f473:2824}}  (+$24)

        ld      l,$20             ;{{f475:2e20}} Flags bit 5 = asterisk
        cp      $2a               ;{{f477:fe2a}} '*'
        jr      z,template_asterisk;{{f479:2811}}  (+$11)

;;=template error
template_error:                   ;{{Addr=$f47b Code Calls/jump count: 5 Data use count: 0}}
        pop     de                ;{{f47b:d1}} Possibly just premature end of template?
        pop     bc                ;{{f47c:c1}} 
        or      a                 ;{{f47d:b7}} 
        ret                       ;{{f47e:c9}} 

;;=template period
template_period:                  ;{{Addr=$f47f Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f47f:13}} If the first char (other than sign) is a decimal point
        dec     b                 ;{{f480:05}} 
        jr      z,template_error  ;{{f481:28f8}}  (-$08)
        ld      a,(de)            ;{{f483:1a}} 
        cp      $23               ;{{f484:fe23}}  '#' Leading Period must be followed by a hash
        jr      nz,template_error ;{{f486:20f3}}  (-$0d)
        dec     de                ;{{f488:1b}} 
        inc     b                 ;{{f489:04}} 
        jr      template_hash     ;{{f48a:1815}}  (+$15)

;;=template asterisk
template_asterisk:                ;{{Addr=$f48c Code Calls/jump count: 1 Data use count: 0}}
        inc     de                ;{{f48c:13}} 
        dec     b                 ;{{f48d:05}} 
        jr      z,_template_currency_symbol_3;{{f48e:280e}}  (+$0e)
        ld      a,(de)            ;{{f490:1a}} 
        call    test_for_currency_symbols;{{f491:cd02f5}} Asterisk followed by currency symbol
        jr      nz,_template_currency_symbol_3;{{f494:2008}}  (+$08)

        inc     h                 ;{{f496:24}} 
        ld      l,$24             ;{{f497:2e24}} Flag bits for 'asterisk' and 'currency symbol' if asterisk + currency symbol
;;=template currency symbol
template_currency_symbol:         ;{{Addr=$f499 Code Calls/jump count: 1 Data use count: 0}}
        ld      (Print_format_currency_symbol___or_),a;{{f499:3254ae}} Set currency symbol
        inc     de                ;{{f49c:13}} 
        dec     b                 ;{{f49d:05}} 
_template_currency_symbol_3:      ;{{Addr=$f49e Code Calls/jump count: 2 Data use count: 0}}
        ld      a,c               ;{{f49e:79}} OR C,L - Put new flags into C
        or      l                 ;{{f49f:b5}} 
        ld      c,a               ;{{f4a0:4f}} 

;;=template hash
template_hash:                    ;{{Addr=$f4a1 Code Calls/jump count: 2 Data use count: 0}}
        pop     af                ;{{f4a1:f1}} Hashes before the decimal point. (Except if first char is decimal point,
                                  ;in which case we arrive here still at the decimal point)
        pop     af                ;{{f4a2:f1}} 
        call    do_template_hash  ;{{f4a3:cdaef4}} 
        ld      a,h               ;{{f4a6:7c}} Chars before decimal point
        add     a,l               ;{{f4a7:85}} Chars including and after decimal point
        cp      $15               ;{{f4a8:fe15}} 
        ret     c                 ;{{f4aa:d8}} 

;;=raise Improper Argument error
raise_improper_argument_error_F:  ;{{Addr=$f4ab Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{f4ab:c34dcb}}  Error: Improper Argument

;;=do template hash
do_template_hash:                 ;{{Addr=$f4ae Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{f4ae:af}} 
        ld      l,a               ;{{f4af:6f}} L=0. Number of chars after decimal point
        or      b                 ;{{f4b0:b0}} 
        ret     z                 ;{{f4b1:c8}} 

;;=template hash loop
template_hash_loop:               ;{{Addr=$f4b2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{f4b2:1a}} Again hashes before the decimal point, unless the first char is a decimal point
        cp      $2e               ;{{f4b3:fe2e}}  '.'
        jr      z,template_hash_period;{{f4b5:280f}}  (+$0f)
        cp      $23               ;{{f4b7:fe23}}  '#'
        jr      z,template_hash_hash;{{f4b9:2806}}  (+$06)
        cp      $2c               ;{{f4bb:fe2c}} ","
        jr      nz,template_hash_other;{{f4bd:2010}}  (+$10)

        set     1,c               ;{{f4bf:cbc9}} Flag bit 1 = Comma
;;=template hash hash
template_hash_hash:               ;{{Addr=$f4c1 Code Calls/jump count: 1 Data use count: 0}}
        inc     h                 ;{{f4c1:24}} Just loop while hashes
        inc     de                ;{{f4c2:13}} 
        djnz    template_hash_loop;{{f4c3:10ed}}  (-$13)
        ret                       ;{{f4c5:c9}} 

;;=template hash period
;Do items after the decimal point
template_hash_period:             ;{{Addr=$f4c6 Code Calls/jump count: 2 Data use count: 0}}
        inc     l                 ;{{f4c6:2c}} Branch here once we encounter a decimal point, inc after-decimal-point counter
        inc     de                ;{{f4c7:13}} 
        dec     b                 ;{{f4c8:05}} 
        ret     z                 ;{{f4c9:c8}} 

        ld      a,(de)            ;{{f4ca:1a}} 
        cp      $23               ;{{f4cb:fe23}}  '#'
        jr      z,template_hash_period;{{f4cd:28f7}}  (-$09) Loop for hashes after the decimal point

;;=template hash other
;Items at the end of the template
template_hash_other:              ;{{Addr=$f4cf Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{f4cf:eb}} Anything else and we're done with the number part
        push    hl                ;{{f4d0:e5}} 

;Test for four '^' - exponent (Note, if we get past the first test then A contains '^')
        cp      $5e               ;{{f4d1:fe5e}} "^"
        jr      nz,_template_hash_other_20;{{f4d3:2016}}  (+$16)
        inc     hl                ;{{f4d5:23}} 
        cp      (hl)              ;{{f4d6:be}} 
        jr      nz,_template_hash_other_20;{{f4d7:2012}}  (+$12)
        inc     hl                ;{{f4d9:23}} 
        cp      (hl)              ;{{f4da:be}} 
        jr      nz,_template_hash_other_20;{{f4db:200e}}  (+$0e)
        inc     hl                ;{{f4dd:23}} 
        cp      (hl)              ;{{f4de:be}} 
        jr      nz,_template_hash_other_20;{{f4df:200a}}  (+$0a)
        inc     hl                ;{{f4e1:23}} 

;If we got here then we found four '^'
        ld      a,b               ;{{f4e2:78}} 
        sub     $04               ;{{f4e3:d604}} 
        jr      c,_template_hash_other_20;{{f4e5:3804}}  (+$04)
        ld      b,a               ;{{f4e7:47}} 
        ex      (sp),hl           ;{{f4e8:e3}} 
        set     6,c               ;{{f4e9:cbf1}} Flags bit 6 = Exponent

_template_hash_other_20:          ;{{Addr=$f4eb Code Calls/jump count: 5 Data use count: 0}}
        pop     hl                ;{{f4eb:e1}} 
        ex      de,hl             ;{{f4ec:eb}} 
        inc     b                 ;{{f4ed:04}} 
        dec     b                 ;{{f4ee:05}} 
        ret     z                 ;{{f4ef:c8}} 

        bit     3,c               ;{{f4f0:cb59}} Exit if we already have a sign prefix
        ret     nz                ;{{f4f2:c0}} 

        ld      a,(de)            ;{{f4f3:1a}} 
        cp      $2d               ;{{f4f4:fe2d}}  '-'
        jr      z,_template_hash_other_33;{{f4f6:2805}}  
        cp      $2b               ;{{f4f8:fe2b}}  '+'
        ret     nz                ;{{f4fa:c0}} 

        set     3,c               ;{{f4fb:cbd9}} '+' suffix gives us bits 3 and 4
_template_hash_other_33:          ;{{Addr=$f4fd Code Calls/jump count: 1 Data use count: 0}}
        set     4,c               ;{{f4fd:cbe1}} '-' suffix only gives us bit 4
        inc     de                ;{{f4ff:13}} 
        dec     b                 ;{{f500:05}} 
        ret                       ;{{f501:c9}} 

;;=test for currency symbols
;Returns Z if dollar or pound sign
;Patch this is you want another currency - as long as it's a single char prefix.
;Adding Euros might be a fun project?
test_for_currency_symbols:        ;{{Addr=$f502 Code Calls/jump count: 2 Data use count: 0}}
        cp      $24               ;{{f502:fe24}}  '$'
        ret     z                 ;{{f504:c8}} 

        cp      $a3               ;{{f505:fea3}}  '£' 
        ret                       ;{{f507:c9}} 

;;========================================================================
;; command WRITE
;WRITE [#<stream expression>,][<write list>]
;where <write list> is <expression>[<separator>]*

;* - means item can be repeated zero or more times
;<separator> can be a comma or semicolon

;Similar to PRINT but:
;- print zones are ignored
;- strings are enclosed in double quotes
;- commas are added between items
;- does not support the trailing separator
;Intended for writing to files in a form that can be read back by INPUT

command_WRITE:                    ;{{Addr=$f508 Code Calls/jump count: 0 Data use count: 1}}
        call    exec_following_on_evalled_stream_and_swap_back;{{f508:cdcfc1}} 
                                  ;This routine evals a stream number (if present),
                                  ;swaps to it,
                                  ;CALLs the following code (popping address of the stack), 
                                  ;swaps back to original stream,
                                  ;returns to the caller

        call    is_next_02        ;{{f50b:cd3dde}} 
        jp      c,output_new_line ;{{f50e:da98c3}} Nothing to print
;;=WRITE do param loop
WRITE_do_param_loop:              ;{{Addr=$f511 Code Calls/jump count: 1 Data use count: 0}}
        call    eval_expression   ;{{f511:cd62cf}} 
        push    af                ;{{f514:f5}} 
        push    hl                ;{{f515:e5}} 
        call    is_accumulator_a_string;{{f516:cd66ff}} 
        jr      z,WRITE_do_string ;{{f519:2808}}  (+$08)
        call    convert_accumulator_to_string;{{f51b:cd5aef}} 
        call    output_ASCIIZ_string;{{f51e:cd8bc3}} ; display 0 terminated string
        jr      WRITE_do_after_parameter;{{f521:180d}}  (+$0d)

;;=WRITE do string
WRITE_do_string:                  ;{{Addr=$f523 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$22             ;{{f523:3e22}} '"'
        call    output_char       ;{{f525:cda0c3}} ; display text char
        call    output_accumulator_string;{{f528:cdd0f8}} 
        ld      a,$22             ;{{f52b:3e22}} '"'
        call    output_char       ;{{f52d:cda0c3}} ; display text char

;;=WRITE do after parameter
WRITE_do_after_parameter:         ;{{Addr=$f530 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f530:e1}} 
        pop     af                ;{{f531:f1}} 
        jp      z,output_new_line ;{{f532:ca98c3}} ; new text line
        call    is_A_print_separator;{{f535:cdeff3}} 
        ld      a,$2c             ;{{f538:3e2c}} 
        call    output_char       ;{{f53a:cda0c3}} ; display text char
        jr      WRITE_do_param_loop;{{f53d:18d2}}  (-$2e)





