;;<< TOKENISING SOURCE CODE
;;==================================================
;; tokenise a BASIC line
tokenise_a_BASIC_line:            ;{{Addr=$dfa4 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{dfa4:d5}} 
        ld de,(address_of_start_of_ROM_lower_reserved_a);{{dfa5:ed5b62ae}} input buffer address
        push    de                ;{{dfa9:d5}} 
        call    zero_ae20_called_at_start_of_statement;{{dfaa:cd35e0}} 
        ld      bc,$012c          ;{{dfad:012c01}} 

_tokenise_a_basic_line_5:         ;{{Addr=$dfb0 Code Calls/jump count: 1 Data use count: 0}}
        call    _tokenise_a_basic_line_24;{{dfb0:cdc8df}} 
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

_tokenise_a_basic_line_24:        ;{{Addr=$dfc8 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{dfc8:7e}} 
        or      a                 ;{{dfc9:b7}} 
        ret     z                 ;{{dfca:c8}} 

        call    test_if_letter    ;{{dfcb:cd92ff}}  is a alphabetical letter?
        jr      c,tokenise_a_keyword;{{dfce:381c}}  (+$1c)
        call    test_if_period_or_digit;{{dfd0:cda0ff}} 
        jp      c,tokenise_a_number;{{dfd3:dae2e0}} 
        cp      "&"               ;{{dfd6:fe26}} '&' = hex or binary prefix
        jp      z,tokenise_hex_or_binary_number;{{dfd8:ca36e1}} 
        inc     hl                ;{{dfdb:23}} 
        or      a                 ;{{dfdc:b7}} 
        ret     m                 ;{{dfdd:f8}} 

        cp      "!"               ;{{dfde:fe21}} '!'
        jp      nc,tokenise_any_other_ascii_char;{{dfe0:d25ce1}} 
        ld      a,(program_line_redundant_spaces_flag_);{{dfe3:3a00ac}} 
        or      a                 ;{{dfe6:b7}} 
        ret     nz                ;{{dfe7:c0}} 

        ld      a," "             ;{{dfe8:3e20}} ' '
        jr      write_token_data_to_memory;{{dfea:181c}}  (+$1c)

;;+----------------
;;tokenise a keyword
tokenise_a_keyword:               ;{{Addr=$dfec Code Calls/jump count: 1 Data use count: 0}}
        call    get_token_for_keyword;{{dfec:cd3ae0}} 
        ret     c                 ;{{dfef:d8}} 

        cp      $c5               ;{{dff0:fec5}} REM
        jp      z,copy_until_end_of_buffer;{{dff2:cac3e1}} 
        push    hl                ;{{dff5:e5}} 
        ld      hl,tokenisation_table_A;{{dff6:2112e0}} 
        call    check_if_byte_exists_in_table;{{dff9:cdcaff}} ; check if byte exists in table 
        pop     hl                ;{{dffc:e1}} 
        jr      c,token_is_in_tokenisation_table_A;{{dffd:3818}}  (+$18)
        push    af                ;{{dfff:f5}} 
        cp      $97               ;{{e000:fe97}} ELSE
        ld      a,$01             ;{{e002:3e01}} 
        call    z,write_token_data_to_memory;{{e004:cc08e0}} 
        pop     af                ;{{e007:f1}} 

;;+-----------------------------
;; write token data to memory
write_token_data_to_memory:       ;{{Addr=$e008 Code Calls/jump count: 22 Data use count: 0}}
        ld      (de),a            ;{{e008:12}} 
        inc     de                ;{{e009:13}} 
        dec     bc                ;{{e00a:0b}} 
        ld      a,c               ;{{e00b:79}} 
        or      b                 ;{{e00c:b0}} 
        ret     nz                ;{{e00d:c0}} 

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
;; Code is jumped to - loop until return

token_is_in_tokenisation_table_A: ;{{Addr=$e017 Code Calls/jump count: 2 Data use count: 0}}
        call    write_token_data_to_memory;{{e017:cd08e0}} 

_token_is_in_tokenisation_table_a_1:;{{Addr=$e01a Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{e01a:7e}} 
        or      a                 ;{{e01b:b7}} 
        ret     z                 ;{{e01c:c8}}  End of buffer

        cp      ":"               ;{{e01d:fe3a}} ':' - end of statement
        jr      z,zero_ae20_called_at_start_of_statement;{{e01f:2814}}  (+$14)
        inc     hl                ;{{e021:23}} 
        or      a                 ;{{e022:b7}} 
        jp      m,_token_is_in_tokenisation_table_a_1;{{e023:fa1ae0}} 

        cp      " "               ;{{e026:fe20}}  ' '
        jr      nc,_token_is_in_tokenisation_table_a_12;{{e028:3002}}  (+$02)
        ld      a,$20             ;{{e02a:3e20}}  convert control codes to spaces
_token_is_in_tokenisation_table_a_12:;{{Addr=$e02c Code Calls/jump count: 1 Data use count: 0}}
        cp      $22               ;{{e02c:fe22}}  '"'
        jr      nz,token_is_in_tokenisation_table_A;{{e02e:20e7}}  (-$19)
        call    tokenise_string   ;{{e030:cd95e1}} 
        jr      _token_is_in_tokenisation_table_a_1;{{e033:18e5}}  (-$1b)

;;+----------------------
;;zero ae20 called at start of statement
zero_ae20_called_at_start_of_statement:;{{Addr=$e035 Code Calls/jump count: 2 Data use count: 0}}
        xor     a                 ;{{e035:af}} 
        ld      (flag_used_with_Trace_),a;{{e036:3220ae}} 
        ret                       ;{{e039:c9}} 

;;===================================================
;; get token for keyword

get_token_for_keyword:            ;{{Addr=$e03a Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{e03a:c5}} 
        push    de                ;{{e03b:d5}} 
        push    hl                ;{{e03c:e5}} 

        ld      a,(hl)            ;{{e03d:7e}} ; get initial character of BASIC keyword
        inc     hl                ;{{e03e:23}} 
        call    convert_character_to_upper_case;{{e03f:cdabff}} ; convert character to upper case
        call    get_keyword_table_for_letter;{{e042:cda8e3}} ; get list of keywords beginning with this letter
        call    keyword_to_token_within_single_table;{{e045:cdebe3}} 
        jr      nc,_get_token_for_keyword_31;{{e048:3026}} ;

        ld      a,c               ;{{e04a:79}} 
        and     $7f               ;{{e04b:e67f}} 
        call    test_if_letter_period_or_digit;{{e04d:cd9cff}} 
        jr      nc,_get_token_for_keyword_18;{{e050:3009}}  (+$09)
        ld      a,(de)            ;{{e052:1a}} 
        cp      $e4               ;{{e053:fee4}} 
        ld      a,(hl)            ;{{e055:7e}} 
        call    nz,test_if_letter_period_or_digit;{{e056:c49cff}} 
        jr      c,_get_token_for_keyword_31;{{e059:3815}}  (+$15)
_get_token_for_keyword_18:        ;{{Addr=$e05b Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{e05b:f1}} 
        ld      a,(de)            ;{{e05c:1a}} 
        or      a                 ;{{e05d:b7}} 
        jp      m,handle_keywords_invalid_in_immediate_mode;{{e05e:faafe0}} 
        pop     de                ;{{e061:d1}} 
        pop     bc                ;{{e062:c1}} 
        push    af                ;{{e063:f5}} 
        ld      a,$ff             ;{{e064:3eff}} 
        call    write_token_data_to_memory;{{e066:cd08e0}} 
        pop     af                ;{{e069:f1}} 
        call    write_token_data_to_memory;{{e06a:cd08e0}} 
        xor     a                 ;{{e06d:af}} 
        jr      _get_token_for_keyword_64;{{e06e:183a}}  (+$3a)

_get_token_for_keyword_31:        ;{{Addr=$e070 Code Calls/jump count: 2 Data use count: 0}}
        pop     hl                ;{{e070:e1}} 
        pop     de                ;{{e071:d1}} 
        pop     bc                ;{{e072:c1}} 
        push    hl                ;{{e073:e5}} 
        dec     hl                ;{{e074:2b}} 
_get_token_for_keyword_36:        ;{{Addr=$e075 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e075:23}} 
        ld      a,(hl)            ;{{e076:7e}} 
        call    test_if_letter_period_or_digit;{{e077:cd9cff}} 
        jr      c,_get_token_for_keyword_36;{{e07a:38f9}}  (-$07)
        call    prob_variable_type_suffix;{{e07c:cdd1e0}} 
        jr      c,_get_token_for_keyword_44;{{e07f:3804}}  (+$04)
        ld      a,$0d             ;{{e081:3e0d}} 
        jr      _get_token_for_keyword_48;{{e083:1806}}  (+$06)

_get_token_for_keyword_44:        ;{{Addr=$e085 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{e085:23}} 
        cp      $05               ;{{e086:fe05}} 
        jr      nz,_get_token_for_keyword_48;{{e088:2001}}  (+$01)
        dec     a                 ;{{e08a:3d}} 
_get_token_for_keyword_48:        ;{{Addr=$e08b Code Calls/jump count: 2 Data use count: 0}}
        call    write_token_data_to_memory;{{e08b:cd08e0}} 
        xor     a                 ;{{e08e:af}} 
        call    write_token_data_to_memory;{{e08f:cd08e0}} 
        xor     a                 ;{{e092:af}} 
        call    write_token_data_to_memory;{{e093:cd08e0}} 
        ex      (sp),hl           ;{{e096:e3}} 
_get_token_for_keyword_54:        ;{{Addr=$e097 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{e097:7e}} 
        call    test_if_letter_period_or_digit;{{e098:cd9cff}} 
        jr      nc,_get_token_for_keyword_61;{{e09b:3007}}  (+$07)
        ld      a,(hl)            ;{{e09d:7e}} 
        call    write_token_data_to_memory;{{e09e:cd08e0}} 
        inc     hl                ;{{e0a1:23}} 
        jr      _get_token_for_keyword_54;{{e0a2:18f3}}  (-$0d)

_get_token_for_keyword_61:        ;{{Addr=$e0a4 Code Calls/jump count: 1 Data use count: 0}}
        call    _tokenise_bar_command_9;{{e0a4:cdb5e1}} 
        pop     hl                ;{{e0a7:e1}} 
        ld      a,$ff             ;{{e0a8:3eff}} 
_get_token_for_keyword_64:        ;{{Addr=$e0aa Code Calls/jump count: 1 Data use count: 0}}
        ld      (flag_used_with_Trace_),a;{{e0aa:3220ae}} 
        scf                       ;{{e0ad:37}} 
        ret                       ;{{e0ae:c9}} 

;;==================================
;; handle keywords invalid in immediate mode
handle_keywords_invalid_in_immediate_mode:;{{Addr=$e0af Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{e0af:e5}} 
        ld      c,a               ;{{e0b0:4f}} 
        ld      hl,immediate_mode_only_token_table;{{e0b1:21c3e0}} 
        call    check_if_byte_exists_in_table;{{e0b4:cdcaff}} ;check if byte exists in table
        sbc     a,a               ;{{e0b7:9f}} 
        and     $01               ;{{e0b8:e601}} 
        ld      (flag_used_with_Trace_),a;{{e0ba:3220ae}} 
        ld      a,c               ;{{e0bd:79}} 
        pop     hl                ;{{e0be:e1}} 
        pop     de                ;{{e0bf:d1}} 
        pop     bc                ;{{e0c0:c1}} 
        or      a                 ;{{e0c1:b7}} 
        ret                       ;{{e0c2:c9}} 

;;================================================
;; immediate mode only token table
;; keywords which are only valid in immediate mode(??)
immediate_mode_only_token_table:  ;{{Addr=$e0c3 Data Calls/jump count: 0 Data use count: 1}}
                                  
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
;; prob variable type suffix

prob_variable_type_suffix:        ;{{Addr=$e0d1 Code Calls/jump count: 2 Data use count: 0}}
        cp      "!"               ;{{e0d1:fe21}} '!'
        jr      z,_prob_variable_type_suffix_7;{{e0d3:2807}}  (+$07)
        cp      "&"               ;{{e0d5:fe26}} '&'
        ret     nc                ;{{e0d7:d0}} 

        cp      "$"               ;{{e0d8:fe24}} '$'
        ccf                       ;{{e0da:3f}} 
        ret     nc                ;{{e0db:d0}} 

_prob_variable_type_suffix_7:     ;{{Addr=$e0dc Code Calls/jump count: 1 Data use count: 0}}
        sbc     a,$1f             ;{{e0dc:de1f}} 
        xor     $07               ;{{e0de:ee07}} 
        scf                       ;{{e0e0:37}} 
        ret                       ;{{e0e1:c9}} 

;;==============================================
;;tokenise a number

tokenise_a_number:                ;{{Addr=$e0e2 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(flag_used_with_Trace_);{{e0e2:3a20ae}} 
        or      a                 ;{{e0e5:b7}} 
        jr      z,_tokenise_a_number_12;{{e0e6:2810}}  (+$10)
        ld      a,(hl)            ;{{e0e8:7e}} 
        inc     hl                ;{{e0e9:23}} 
        jp      m,write_token_data_to_memory;{{e0ea:fa08e0}} 
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
        call    write_token_data_to_memory;{{e11e:cd08e0}} 
        ld      a,l               ;{{e121:7d}} 
_tokenise_a_number_35:            ;{{Addr=$e122 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{e122:e1}} 
        jp      write_token_data_to_memory;{{e123:c308e0}} 

_tokenise_a_number_37:            ;{{Addr=$e126 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{e126:7e}} 
        inc     hl                ;{{e127:23}} 
        ex      (sp),hl           ;{{e128:e3}} 
        ex      de,hl             ;{{e129:eb}} 
        call    write_token_data_to_memory;{{e12a:cd08e0}} 
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
        call    write_token_data_to_memory;{{e146:cd08e0}} 
        push    hl                ;{{e149:e5}} 
        ld      hl,accumulator    ;{{e14a:21a0b0}} 
        call    get_accumulator_data_type;{{e14d:cd4bff}} 
_tokenise_hex_or_binary_number_14:;{{Addr=$e150 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{e150:f5}} 
        ld      a,(hl)            ;{{e151:7e}} 
        inc     hl                ;{{e152:23}} 
        call    write_token_data_to_memory;{{e153:cd08e0}} 
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
        ld      (flag_used_with_Trace_),a;{{e17c:3220ae}} 
        ld      a,b               ;{{e17f:78}} 
        pop     de                ;{{e180:d1}} 
        pop     bc                ;{{e181:c1}} 
        cp      $c0               ;{{e182:fec0}} "'" comment
        jr      z,tokenise_single_quote_comment;{{e184:2836}}  (+$36)
        jp      write_token_data_to_memory;{{e186:c308e0}} 

_tokenise_any_other_ascii_char_25:;{{Addr=$e189 Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{e189:3d}} 
        ret     z                 ;{{e18a:c8}} 

        xor     $22               ;{{e18b:ee22}}  '"'
        ret     z                 ;{{e18d:c8}} 

        ld      a,(flag_used_with_Trace_);{{e18e:3a20ae}} 
        inc     a                 ;{{e191:3c}} 
        ret     z                 ;{{e192:c8}} 

        dec     a                 ;{{e193:3d}} 
        ret                       ;{{e194:c9}} 

;;=============================================
;; tokenise string
;; Called after a double quote
tokenise_string:                  ;{{Addr=$e195 Code Calls/jump count: 3 Data use count: 0}}
        call    write_token_data_to_memory;{{e195:cd08e0}} 
        ld      a,(hl)            ;{{e198:7e}} 
        or      a                 ;{{e199:b7}} 
        ret     z                 ;{{e19a:c8}} 

        inc     hl                ;{{e19b:23}} 
        cp      $22               ;{{e19c:fe22}}  '"'
        jr      nz,tokenise_string;{{e19e:20f5}}  (-$0b)
        jp      write_token_data_to_memory;{{e1a0:c308e0}} 

;;=============================
;;tokenise bar command

tokenise_bar_command:             ;{{Addr=$e1a3 Code Calls/jump count: 1 Data use count: 0}}
        call    write_token_data_to_memory;{{e1a3:cd08e0}} 
        xor     a                 ;{{e1a6:af}} 
        ld      (flag_used_with_Trace_),a;{{e1a7:3220ae}} 
_tokenise_bar_command_3:          ;{{Addr=$e1aa Code Calls/jump count: 1 Data use count: 0}}
        call    write_token_data_to_memory;{{e1aa:cd08e0}} 
        ld      a,(hl)            ;{{e1ad:7e}} 
        inc     hl                ;{{e1ae:23}} 
        call    test_if_letter_period_or_digit;{{e1af:cd9cff}} 
        jr      c,_tokenise_bar_command_3;{{e1b2:38f6}}  (-$0a)
        dec     hl                ;{{e1b4:2b}} 
_tokenise_bar_command_9:          ;{{Addr=$e1b5 Code Calls/jump count: 1 Data use count: 0}}
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
        call    write_token_data_to_memory;{{e1be:cd08e0}} 
        ld      a,$c0             ;{{e1c1:3ec0}} "'"
;;=copy until end of buffer
copy_until_end_of_buffer:         ;{{Addr=$e1c3 Code Calls/jump count: 2 Data use count: 0}}
        call    write_token_data_to_memory;{{e1c3:cd08e0}} 
        ld      a,(hl)            ;{{e1c6:7e}} 
        inc     hl                ;{{e1c7:23}} 
        or      a                 ;{{e1c8:b7}} 
        jr      nz,copy_until_end_of_buffer;{{e1c9:20f8}}  (-$08)
        dec     hl                ;{{e1cb:2b}} 
        ret                       ;{{e1cc:c9}} 




