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
        call    prob_variable_type_suffix;{{e27d:cdd1e0}} 
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





