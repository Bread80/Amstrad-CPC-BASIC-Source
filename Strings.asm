;;<< STRING MANIPULATION
;;< and string$ and string related functions (LEN, ASC etc)
;;< also FRE and some (unexplored) memory management stuff
;;===================================================================
;; get quoted string
;; returns with HL at end of string and B=length
get_quoted_string:                ;{{Addr=$f879 Code Calls/jump count: 3 Data use count: 0}}
        inc     hl                ;{{f879:23}} 
        call    string_getter     ;{{f87a:cda7f8}} 

_get_quoted_string_2:             ;{{Addr=$f87d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f87d:7e}}  read character
        cp      $22               ;{{f87e:fe22}}  double quote
        jp      z,get_next_token_skipping_space;{{f880:ca2cde}}  get next token skipping space
        or      a                 ;{{f883:b7}}  end of line marker
        jr      z,right_trim_and_return;{{f884:2831}} 
        inc     b                 ;{{f886:04}}  increment number of characters
        inc     hl                ;{{f887:23}}  increment pointer
        jr      _get_quoted_string_2;{{f888:18f3}}  

;;+---------------------------------------------------------------------------
;;get ASCIIZ string
get_ASCIIZ_string:                ;{{Addr=$f88a Code Calls/jump count: 3 Data use count: 0}}
        call    string_getter     ;{{f88a:cda7f8}} 

_get_asciiz_string_1:             ;{{Addr=$f88d Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f88d:7e}} 
        or      a                 ;{{f88e:b7}} 
        ret     z                 ;{{f88f:c8}} return directly to string getter

        inc     hl                ;{{f890:23}} 
        inc     b                 ;{{f891:04}} 
        jr      _get_asciiz_string_1;{{f892:18f9}}  (-$07)

;;+-------------------------------------------------------------
;;get string until $00, comma or value in A
;; returns with HL at end of string and B=length
get_string_until_00_comma_or_value_in_A:;{{Addr=$f894 Code Calls/jump count: 1 Data use count: 0}}
        call    string_getter     ;{{f894:cda7f8}} 

        ld      c,a               ;{{f897:4f}} 
_get_string_until_00_comma_or_value_in_a_2:;{{Addr=$f898 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{f898:7e}} 
        or      a                 ;{{f899:b7}} 
        jr      z,right_trim_and_return;{{f89a:281b}}  (+$1b)
        cp      c                 ;{{f89c:b9}} 
        jr      z,right_trim_and_return;{{f89d:2818}}  (+$18)
        cp      $2c               ;{{f89f:fe2c}} ","
        jr      z,right_trim_and_return;{{f8a1:2814}}  (+$14)
        inc     hl                ;{{f8a3:23}} 
        inc     b                 ;{{f8a4:04}} 
        jr      _get_string_until_00_comma_or_value_in_a_2;{{f8a5:18f1}}  (-$0f)

;;=string getter
;;get string using following code segment as subroutine
;;HL points to data (string)
string_getter:                    ;{{Addr=$f8a7 Code Calls/jump count: 3 Data use count: 0}}
        ld      (address_of_last_String_used),hl;{{f8a7:229db0}} 
        pop     de                ;{{f8aa:d1}} 
        ld      b,$00             ;{{f8ab:0600}}  B = string length
        call    JP_DE             ;{{f8ad:cdfeff}}  JP (DE) call get string subroutine
        ld      a,b               ;{{f8b0:78}}  Only the ASCIIZ variant returns here
        ld      (length_of_last_String_used),a;{{f8b1:329cb0}} 
        jp      push_last_string_on_string_stack;{{f8b4:c3d6fb}} $b09d = start of string. 
                                  ;$b09c, A and B equal length 
                                  ;HL = next byte after string (and after whitespace)
                                        

;;=right trim and return
;;remove whitespace from end of string
right_trim_and_return:            ;{{Addr=$f8b7 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{f8b7:e5}} 
        inc     b                 ;{{f8b8:04}} 
;;=right trim loop
right_trim_loop:                  ;{{Addr=$f8b9 Code Calls/jump count: 4 Data use count: 0}}
        dec     b                 ;{{f8b9:05}} remove character from end of string
        jr      z,_right_trim_loop_12;{{f8ba:2812}}  (+$12) length = zero?
        dec     hl                ;{{f8bc:2b}} 
        ld      a,(hl)            ;{{f8bd:7e}} 
        cp      $20               ;{{f8be:fe20}} " "
        jr      z,right_trim_loop ;{{f8c0:28f7}}  (-$09)
        cp      $09               ;{{f8c2:fe09}} TAB
        jr      z,right_trim_loop ;{{f8c4:28f3}}  (-$0d)
        cp      $0d               ;{{f8c6:fe0d}}  carriage return
        jr      z,right_trim_loop ;{{f8c8:28ef}}  (-$11)
        cp      $0a               ;{{f8ca:fe0a}}  new line
        jr      z,right_trim_loop ;{{f8cc:28eb}}  (-$15)
_right_trim_loop_12:              ;{{Addr=$f8ce Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{f8ce:e1}} 
        ret                       ;{{f8cf:c9}}  return to string getter

;;=============================================
;; output accumulator string
output_accumulator_string:        ;{{Addr=$f8d0 Code Calls/jump count: 3 Data use count: 0}}
        call    get_accumulator_string_length;{{f8d0:cdf5fb}} 
        ret     z                 ;{{f8d3:c8}} 

;;=output string atDE length B
output_string_atDE_length_B:      ;{{Addr=$f8d4 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(de)            ;{{f8d4:1a}} 
        inc     de                ;{{f8d5:13}} 
        call    output_raw_char   ;{{f8d6:cdb8c3}} 
        djnz    output_string_atDE_length_B;{{f8d9:10f9}}  (-$07)
        ret                       ;{{f8db:c9}} 

;;=unknown output accumulator string
unknown_output_accumulator_string:;{{Addr=$f8dc Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{f8dc:cdf5fb}} 
        ret     z                 ;{{f8df:c8}} 

        ld      a,c               ;{{f8e0:79}} 
        sub     b                 ;{{f8e1:90}} 
        jr      nc,_unknown_output_accumulator_string_9;{{f8e2:3005}}  (+$05)
        add     a,b               ;{{f8e4:80}} 
        jr      z,_unknown_output_accumulator_string_9;{{f8e5:2802}}  (+$02)
        ld      b,a               ;{{f8e7:47}} 
        xor     a                 ;{{f8e8:af}} 
_unknown_output_accumulator_string_9:;{{Addr=$f8e9 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{f8e9:4f}} 
        jr      output_string_atDE_length_B;{{f8ea:18e8}}  (-$18)

;;========================================================
;; function LOWER$
function_LOWER:                   ;{{Addr=$f8ec Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,convert_character_to_lower_case;{{f8ec:01f1f8}} ##LABEL##
        jr      string_iterator   ;{{f8ef:180c}}  (+$0c)

;;=convert character to lower case
convert_character_to_lower_case:  ;{{Addr=$f8f1 Code Calls/jump count: 0 Data use count: 1}}
        cp      $41               ;{{f8f1:fe41}} 
        ret     c                 ;{{f8f3:d8}} 

        cp      $5b               ;{{f8f4:fe5b}} 
        ret     nc                ;{{f8f6:d0}} 

        add     a,$20             ;{{f8f7:c620}} 
        ret                       ;{{f8f9:c9}} 

;;========================================================
;; function UPPER$

function_UPPER:                   ;{{Addr=$f8fa Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,convert_character_to_upper_case;{{f8fa:01abff}} ##LABEL##

;;=string iterator
;; BC = routine to call for each character
string_iterator:                  ;{{Addr=$f8fd Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f8fd:c5}} 
        ld      hl,(accumulator)  ;{{f8fe:2aa0b0}} 
        call    get_accumulator_string_length;{{f901:cdf5fb}} 
        call    alloc_space_in_strings_area;{{f904:cd41fc}} 
        inc     hl                ;{{f907:23}} 
        ld      c,(hl)            ;{{f908:4e}} 
        inc     hl                ;{{f909:23}} 
        ld      h,(hl)            ;{{f90a:66}} 
        ld      l,c               ;{{f90b:69}} 
        pop     bc                ;{{f90c:c1}} 
        inc     a                 ;{{f90d:3c}} 
_string_iterator_11:              ;{{Addr=$f90e Code Calls/jump count: 1 Data use count: 0}}
        dec     a                 ;{{f90e:3d}} 
        jp      z,push_last_string_on_string_stack;{{f90f:cad6fb}} 
        push    af                ;{{f912:f5}} 
        ld      a,(hl)            ;{{f913:7e}} 
        inc     hl                ;{{f914:23}} 
        call    JP_BC             ;{{f915:cdfcff}}  JP (BC) call callback function
        ld      (de),a            ;{{f918:12}} 
        inc     de                ;{{f919:13}} 
        pop     af                ;{{f91a:f1}} 
        jr      _string_iterator_11;{{f91b:18f1}}  (-$0f)

;;=concat two strings
concat_two_strings:               ;{{Addr=$f91d Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(accumulator)  ;{{f91d:ed5ba0b0}} 
        ld      a,(de)            ;{{f921:1a}} 
        add     a,(hl)            ;{{f922:86}} 
        jr      nc,_concat_two_strings_6;{{f923:3004}}  (+$04)
        call    byte_following_call_is_error_code;{{f925:cd45cb}} 
        defb $0f                  ;Inline error code: String too long
    
_concat_two_strings_6:            ;{{Addr=$f929 Code Calls/jump count: 1 Data use count: 0}}
        call    alloc_space_in_strings_area;{{f929:cd41fc}} 
        call    xf959_code        ;{{f92c:cd59f9}} 
        push    de                ;{{f92f:d5}} 
        push    bc                ;{{f930:c5}} 
        ld      c,b               ;{{f931:48}} 
        call    push_last_string_on_string_stack;{{f932:cdd6fb}} 
        ld      a,c               ;{{f935:79}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f936:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     bc                ;{{f939:c1}} 
        pop     hl                ;{{f93a:e1}} 
        ld      a,c               ;{{f93b:79}} 
        jp      copy_bytes_LDIR__Acount_HLsource_DEdest;{{f93c:c3ecff}} ; copy bytes (A=count, HL=source, DE=dest)

;;================================================
;;probably string comparison

probably_string_comparison:       ;{{Addr=$f93f Code Calls/jump count: 1 Data use count: 0}}
        call    xf959_code        ;{{f93f:cd59f9}} 
        xor     a                 ;{{f942:af}} 
_probably_string_comparison_2:    ;{{Addr=$f943 Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{f943:b9}} 
        jr      z,_probably_string_comparison_17;{{f944:280f}}  (+$0f)
        cp      b                 ;{{f946:b8}} 
        jr      z,_probably_string_comparison_15;{{f947:280a}}  (+$0a)
        dec     b                 ;{{f949:05}} 
        dec     c                 ;{{f94a:0d}} 
        ld      a,(de)            ;{{f94b:1a}} 
        inc     de                ;{{f94c:13}} 
        sub     (hl)              ;{{f94d:96}} 
        inc     hl                ;{{f94e:23}} 
        jr      z,_probably_string_comparison_2;{{f94f:28f2}}  (-$0e)
        sbc     a,a               ;{{f951:9f}} 
        ret     nz                ;{{f952:c0}} 

_probably_string_comparison_15:   ;{{Addr=$f953 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{f953:3c}} 
        ret                       ;{{f954:c9}} 

_probably_string_comparison_17:   ;{{Addr=$f955 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{f955:b8}} 
        ret     z                 ;{{f956:c8}} 

        sbc     a,a               ;{{f957:9f}} 
        ret                       ;{{f958:c9}} 

;;=================================================
xf959_code:                       ;{{Addr=$f959 Code Calls/jump count: 2 Data use count: 0}}
        call    get_accumulator_string_length;{{f959:cdf5fb}} 
        ld      c,b               ;{{f95c:48}} 
        push    de                ;{{f95d:d5}} 
        call    various_get_string_from_stack_stuff;{{f95e:cd03fc}} 
        ex      de,hl             ;{{f961:eb}} 
        pop     de                ;{{f962:d1}} 
        ret                       ;{{f963:c9}} 
;;========================================================================
;; function BIN$
function_BIN:                     ;{{Addr=$f964 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$0101          ;{{f964:010101}} 
        jr      _function_hex_1   ;{{f967:1803}}  (+$03)

;;========================================================================
;; function HEX$
function_HEX:                     ;{{Addr=$f969 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$040f          ;{{f969:010f04}} 
_function_hex_1:                  ;{{Addr=$f96c Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f96c:c5}} 
        call    eval_expression   ;{{f96d:cd62cf}} 
        push    hl                ;{{f970:e5}} 
        call    function_UNT      ;{{f971:cdebfe}} 
        ex      (sp),hl           ;{{f974:e3}} 
        call    next_token_if_prev_is_comma;{{f975:cd41de}} 
        sbc     a,a               ;{{f978:9f}} 
        call    c,eval_expr_as_byte_or_error;{{f979:dcb8ce}}  get number and check it's less than 255 
        cp      $11               ;{{f97c:fe11}} 
        jp      nc,Error_Improper_Argument;{{f97e:d24dcb}}  Error: Improper Argument
        ld      b,a               ;{{f981:47}} 
        call    next_token_if_close_bracket;{{f982:cd1dde}}  check for close bracket
        ld      a,b               ;{{f985:78}} 
        ex      de,hl             ;{{f986:eb}} 
        pop     hl                ;{{f987:e1}} 
        pop     bc                ;{{f988:c1}} 
        push    de                ;{{f989:d5}} 
        call    convert_based_number_to_string;{{f98a:cddff1}} 
        jr      _function_str_2   ;{{f98d:1831}}  (+$31)

;;========================================================================
;; function DEC$
function_DEC:                     ;{{Addr=$f98f Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{f98f:cd62cf}} 
        call    next_token_if_comma;{{f992:cd15de}}  check for comma
        call    probably_push_accumulator_on_execution_stack;{{f995:cd74ff}} 
        call    eval_expr_as_string_and_get_length;{{f998:cd03cf}} 
        call    next_token_if_close_bracket;{{f99b:cd1dde}}  check for close bracket
        push    hl                ;{{f99e:e5}} 
        ld      a,c               ;{{f99f:79}} 
        call    probably_remove_A_bytes_off_execution_stack_and_get_address;{{f9a0:cd62f6}} 
        push    de                ;{{f9a3:d5}} 
        ld      a,c               ;{{f9a4:79}} 
        call    copy_atHL_to_accumulator_type_A;{{f9a5:cd6cff}} 
        pop     de                ;{{f9a8:d1}} 
        ld      a,b               ;{{f9a9:78}} 
        or      a                 ;{{f9aa:b7}} 
        call    nz,_print_using_121;{{f9ab:c448f4}} 
        jp      nc,Error_Improper_Argument;{{f9ae:d24dcb}}  Error: Improper Argument
        ld      a,b               ;{{f9b1:78}} 
        or      a                 ;{{f9b2:b7}} 
        jp      nz,Error_Improper_Argument;{{f9b3:c24dcb}}  Error: Improper Argument
        ld      a,c               ;{{f9b6:79}} 
        call    convert_number_to_string_by_format;{{f9b7:cd6aef}} 
        jr      _function_str_2   ;{{f9ba:1804}}  (+$04)

;;========================================================
;; function STR$

function_STR:                     ;{{Addr=$f9bc Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{f9bc:e5}} 
        call    prob_eval_number_to_decimal_string;{{f9bd:cd68ef}} 
_function_str_2:                  ;{{Addr=$f9c0 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{f9c0:e5}} 
        ld      c,$ff             ;{{f9c1:0eff}} 
        xor     a                 ;{{f9c3:af}} 
_function_str_5:                  ;{{Addr=$f9c4 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{f9c4:0c}} 
        cp      (hl)              ;{{f9c5:be}} 
        inc     hl                ;{{f9c6:23}} 
        jr      nz,_function_str_5;{{f9c7:20fb}}  (-$05)
        pop     hl                ;{{f9c9:e1}} 
        ld      a,c               ;{{f9ca:79}} 
        call    _get_string_stack_first_free_ptr_3;{{f9cb:cdd3fb}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f9ce:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{f9d1:e1}} 
        ret                       ;{{f9d2:c9}} 

;;========================================================================
;; function LEFT$
function_LEFT:                    ;{{Addr=$f9d3 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_mid_34   ;{{f9d3:cd43fa}} 
        jr      _prefix_mid_6     ;{{f9d6:1818}}  (+$18)

;;========================================================================
;; function RIGHT$
function_RIGHT:                   ;{{Addr=$f9d8 Code Calls/jump count: 0 Data use count: 1}}
        call    _command_mid_34   ;{{f9d8:cd43fa}} 
        ld      a,(de)            ;{{f9db:1a}} 
        sub     b                 ;{{f9dc:90}} 
        jr      c,_prefix_mid_6   ;{{f9dd:3811}}  (+$11)
        ld      c,a               ;{{f9df:4f}} 
        jr      _prefix_mid_6     ;{{f9e0:180e}}  (+$0e)

;;=======================================================================
;; prefix MID$

prefix_MID:                       ;{{Addr=$f9e2 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{f9e2:cd19de}}  check for open bracket
        call    _command_mid_34   ;{{f9e5:cd43fa}} 
        jp      z,Error_Improper_Argument;{{f9e8:ca4dcb}}  Error: Improper Argument
        dec     b                 ;{{f9eb:05}} 
        ld      c,b               ;{{f9ec:48}} 
        call    _command_mid_40   ;{{f9ed:cd4ffa}} 
;;------------------------------------------------------------------------
_prefix_mid_6:                    ;{{Addr=$f9f0 Code Calls/jump count: 3 Data use count: 0}}
        call    next_token_if_close_bracket;{{f9f0:cd1dde}}  check for close bracket
        push    hl                ;{{f9f3:e5}} 
        ex      de,hl             ;{{f9f4:eb}} 
        call    _command_mid_51   ;{{f9f5:cd60fa}} 
        call    alloc_space_in_strings_area;{{f9f8:cd41fc}} 
        call    various_get_string_from_stack_stuff;{{f9fb:cd03fc}} 
        ex      de,hl             ;{{f9fe:eb}} 
        call    push_last_string_on_string_stack;{{f9ff:cdd6fb}} 
        ld      b,$00             ;{{fa02:0600}} 
        add     hl,bc             ;{{fa04:09}} 
        jr      _command_mid_31   ;{{fa05:1837}}  (+$37)

;;========================================================================
;; command MID$

command_MID:                      ;{{Addr=$fa07 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{fa07:cd19de}}  check for open bracket
        call    parse_and_find_or_create_a_var;{{fa0a:cdbfd6}} 
        call    error_if_accumulator_is_not_a_string;{{fa0d:cd5eff}} 
        push    hl                ;{{fa10:e5}} 
        ex      de,hl             ;{{fa11:eb}} 
        call    prob_copy_string_to_strings_area;{{fa12:cd58fb}} 
        ex      (sp),hl           ;{{fa15:e3}} 
        call    _command_mid_44   ;{{fa16:cd55fa}} 
        jp      z,Error_Improper_Argument;{{fa19:ca4dcb}}  Error: Improper Argument
        dec     a                 ;{{fa1c:3d}} 
        ld      c,a               ;{{fa1d:4f}} 
        call    _command_mid_40   ;{{fa1e:cd4ffa}} 
        call    next_token_if_close_bracket;{{fa21:cd1dde}}  check for close bracket
        call    next_token_if_equals_sign;{{fa24:cd21de}} 
        push    bc                ;{{fa27:c5}} 
        call    eval_expr_as_string_and_get_length;{{fa28:cd03cf}} 
        ld      a,b               ;{{fa2b:78}} 
        pop     bc                ;{{fa2c:c1}} 
        ex      (sp),hl           ;{{fa2d:e3}} 
        cp      b                 ;{{fa2e:b8}} 
        jr      nc,_command_mid_22;{{fa2f:3001}}  (+$01)
        ld      b,a               ;{{fa31:47}} 
_command_mid_22:                  ;{{Addr=$fa32 Code Calls/jump count: 1 Data use count: 0}}
        call    _command_mid_51   ;{{fa32:cd60fa}} 
        inc     hl                ;{{fa35:23}} 
        ld      b,(hl)            ;{{fa36:46}} 
        inc     hl                ;{{fa37:23}} 
        ld      h,(hl)            ;{{fa38:66}} 
        ld      l,b               ;{{fa39:68}} 
        ld      b,$00             ;{{fa3a:0600}} 
        add     hl,bc             ;{{fa3c:09}} 
        ex      de,hl             ;{{fa3d:eb}} 
_command_mid_31:                  ;{{Addr=$fa3e Code Calls/jump count: 1 Data use count: 0}}
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{fa3e:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{fa41:e1}} 
        ret                       ;{{fa42:c9}} 

_command_mid_34:                  ;{{Addr=$fa43 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expr_and_error_if_not_string;{{fa43:cd09cf}} 
        ex      de,hl             ;{{fa46:eb}} 
        ld      hl,(accumulator)  ;{{fa47:2aa0b0}} 
        ex      de,hl             ;{{fa4a:eb}} 
        ld      c,$00             ;{{fa4b:0e00}} 
        jr      _command_mid_44   ;{{fa4d:1806}}  (+$06)

_command_mid_40:                  ;{{Addr=$fa4f Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$ff             ;{{fa4f:06ff}} 
        ld      a,(hl)            ;{{fa51:7e}} 
        cp      $29               ;{{fa52:fe29}} 
        ret     z                 ;{{fa54:c8}} 

_command_mid_44:                  ;{{Addr=$fa55 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{fa55:d5}} 
        call    next_token_if_comma;{{fa56:cd15de}}  check for comma
        call    eval_expr_as_byte_or_error;{{fa59:cdb8ce}}  get number and check it's less than 255 
        ld      b,a               ;{{fa5c:47}} 
        pop     de                ;{{fa5d:d1}} 
        or      a                 ;{{fa5e:b7}} 
        ret                       ;{{fa5f:c9}} 

_command_mid_51:                  ;{{Addr=$fa60 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{fa60:7e}} 
        sub     c                 ;{{fa61:91}} 
        jr      nc,_command_mid_55;{{fa62:3001}}  (+$01)
        xor     a                 ;{{fa64:af}} 
_command_mid_55:                  ;{{Addr=$fa65 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{fa65:b8}} 
        ret     c                 ;{{fa66:d8}} 

        ld      a,b               ;{{fa67:78}} 
        ret                       ;{{fa68:c9}} 

;;========================================================
;; function LEN

function_LEN:                     ;{{Addr=$fa69 Code Calls/jump count: 0 Data use count: 1}}
        call    get_accumulator_string_length;{{fa69:cdf5fb}} 
        jr      _function_asc_1   ;{{fa6c:1803}}  (+$03)

;;========================================================
;; function ASC

function_ASC:                     ;{{Addr=$fa6e Code Calls/jump count: 0 Data use count: 1}}
        call    get_first_char_of_string_or_error;{{fa6e:cda6fa}} 
_function_asc_1:                  ;{{Addr=$fa71 Code Calls/jump count: 1 Data use count: 0}}
        jp      store_A_in_accumulator_as_INT;{{fa71:c332ff}} 

;;========================================================
;; function CHR$

function_CHR:                     ;{{Addr=$fa74 Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{fa74:cdd9fa}} 
_function_chr_1:                  ;{{Addr=$fa77 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{fa77:37}} 

_function_chr_2:                  ;{{Addr=$fa78 Code Calls/jump count: 4 Data use count: 0}}
        ld      c,a               ;{{fa78:4f}} 
        sbc     a,a               ;{{fa79:9f}} 
        and     $01               ;{{fa7a:e601}} 
        jr      _function_space_2 ;{{fa7c:1834}}  (+$34)

;;=========================================================
;; variable INKEY$

variable_INKEY:                   ;{{Addr=$fa7e Code Calls/jump count: 0 Data use count: 1}}
        call    jp_km_read_char   ;{{fa7e:cd6fc4}}  call to firmware function: km read key			
        jr      nc,_function_chr_2;{{fa81:30f5}}  
        cp      $fc               ;{{fa83:fefc}} 
        jr      z,_function_chr_2 ;{{fa85:28f1}} 
        cp      $ef               ;{{fa87:feef}} token for '='
        jr      z,_function_chr_2 ;{{fa89:28ed}}  (-$13)
        jr      _function_chr_1   ;{{fa8b:18ea}}  (-$16)

;;=========================================================
;; function STRING$

function_STRING:                  ;{{Addr=$fa8d Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_byte_or_error;{{fa8d:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{fa90:f5}} 
        call    next_token_if_comma;{{fa91:cd15de}}  check for comma
        call    eval_expression   ;{{fa94:cd62cf}} 
        call    next_token_if_close_bracket;{{fa97:cd1dde}}  check for close bracket
        call    get_first_char_from_accumulator_or_error;{{fa9a:cda1fa}} 
        ld      c,a               ;{{fa9d:4f}} 
        pop     af                ;{{fa9e:f1}} 
        jr      _function_space_2 ;{{fa9f:1811}}  (+$11)

;;=get first char from accumulator or error
get_first_char_from_accumulator_or_error:;{{Addr=$faa1 Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_a_string;{{faa1:cd66ff}} 
        jr      nz,param_less_than_256_or_error;{{faa4:2033}}  (+$33)
;;=get first char of string or error
get_first_char_of_string_or_error:;{{Addr=$faa6 Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{faa6:cdf5fb}} 
        jr      z,raise_improper_argument_error_E;{{faa9:2837}}  (+$37)
        ld      a,(de)            ;{{faab:1a}} 
        ret                       ;{{faac:c9}} 

;;========================================================
;; function SPACE$

function_SPACE:                   ;{{Addr=$faad Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{faad:cdd9fa}} 
        ld      c,$20             ;{{fab0:0e20}} 
_function_space_2:                ;{{Addr=$fab2 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,a               ;{{fab2:47}} 
        call    _get_string_stack_first_free_ptr_3;{{fab3:cdd3fb}} 
        ld      a,c               ;{{fab6:79}} 
        inc     b                 ;{{fab7:04}} 
_function_space_6:                ;{{Addr=$fab8 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{fab8:05}} 
        ret     z                 ;{{fab9:c8}} 

        ld      (de),a            ;{{faba:12}} 
        inc     de                ;{{fabb:13}} 
        jr      _function_space_6 ;{{fabc:18fa}}  (-$06)

;;========================================================
;; function VAL
;convert string to number

function_VAL:                     ;{{Addr=$fabe Code Calls/jump count: 0 Data use count: 1}}
        call    get_accumulator_string_length;{{fabe:cdf5fb}} 
        jp      z,store_A_in_accumulator_as_INT;{{fac1:ca32ff}} 
        ex      de,hl             ;{{fac4:eb}} 
        push    hl                ;{{fac5:e5}} 
        ld      e,a               ;{{fac6:5f}} 
        ld      d,$00             ;{{fac7:1600}} 
        add     hl,de             ;{{fac9:19}} 
        ld      e,(hl)            ;{{faca:5e}} 
        ld      (hl),d            ;{{facb:72}} 
        ex      (sp),hl           ;{{facc:e3}} 
        push    de                ;{{facd:d5}} 
        call    possibly_validate_input_buffer_is_a_number;{{face:cd6fed}} 
        pop     de                ;{{fad1:d1}} 
        pop     hl                ;{{fad2:e1}} 
        ld      (hl),e            ;{{fad3:73}} 
        ret     c                 ;{{fad4:d8}} 

        call    byte_following_call_is_error_code;{{fad5:cd45cb}} 
        defb $0d                  ;Inline error code: Type Mismatch

;;=============================
;;param less than 256 or error
param_less_than_256_or_error:     ;{{Addr=$fad9 Code Calls/jump count: 4 Data use count: 0}}
        push    hl                ;{{fad9:e5}} 
        call    function_CINT     ;{{fada:cdb6fe}} 
        ld      a,h               ;{{fadd:7c}} 
        or      a                 ;{{fade:b7}} 
        ld      a,l               ;{{fadf:7d}} 
        pop     hl                ;{{fae0:e1}} 
        ret     z                 ;{{fae1:c8}} 

;;=raise Improper argument error
raise_improper_argument_error_E:  ;{{Addr=$fae2 Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{fae2:c34dcb}}  Error: Improper Argument

;;========================================================================
;; function INSTR$
;find string within string
function_INSTR:                   ;{{Addr=$fae5 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{fae5:cd62cf}} 
        call    is_accumulator_a_string;{{fae8:cd66ff}} 
        ld      c,$01             ;{{faeb:0e01}} 
        jr      z,_function_instr_10;{{faed:280e}}  (+$0e)
        call    param_less_than_256_or_error;{{faef:cdd9fa}} 
        or      a                 ;{{faf2:b7}} 
        jp      z,Error_Improper_Argument;{{faf3:ca4dcb}}  Error: Improper Argument
        ld      c,a               ;{{faf6:4f}} 
        call    next_token_if_comma;{{faf7:cd15de}}  check for comma
        call    eval_expr_and_error_if_not_string;{{fafa:cd09cf}} 
_function_instr_10:               ;{{Addr=$fafd Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_comma;{{fafd:cd15de}}  check for comma
        push    hl                ;{{fb00:e5}} 
        ld      hl,(accumulator)  ;{{fb01:2aa0b0}} 
        ex      (sp),hl           ;{{fb04:e3}} 
        call    eval_expr_as_string_and_get_length;{{fb05:cd03cf}} 
        call    next_token_if_close_bracket;{{fb08:cd1dde}}  check for close bracket
        ex      (sp),hl           ;{{fb0b:e3}} 
        ld      a,c               ;{{fb0c:79}} 
        ld      c,b               ;{{fb0d:48}} 
        push    de                ;{{fb0e:d5}} 
        push    af                ;{{fb0f:f5}} 
        call    various_get_string_from_stack_stuff;{{fb10:cd03fc}} 
        ex      de,hl             ;{{fb13:eb}} 
        pop     af                ;{{fb14:f1}} 
        ld      e,a               ;{{fb15:5f}} 
        ld      d,$00             ;{{fb16:1600}} 
        add     hl,de             ;{{fb18:19}} 
        dec     hl                ;{{fb19:2b}} 
        ld      a,b               ;{{fb1a:78}} 
        sub     e                 ;{{fb1b:93}} 
        inc     a                 ;{{fb1c:3c}} 
        ld      b,a               ;{{fb1d:47}} 
        ld      a,e               ;{{fb1e:7b}} 
        pop     de                ;{{fb1f:d1}} 
        jr      c,_function_instr_66;{{fb20:3825}}  (+$25)
        inc     c                 ;{{fb22:0c}} 
        dec     c                 ;{{fb23:0d}} 
        jr      z,_function_instr_67;{{fb24:2822}}  (+$22)
_function_instr_38:               ;{{Addr=$fb26 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{fb26:f5}} 
        ld      a,b               ;{{fb27:78}} 
        cp      c                 ;{{fb28:b9}} 
        jr      c,_function_instr_65;{{fb29:381b}}  (+$1b)
        push    hl                ;{{fb2b:e5}} 
        push    de                ;{{fb2c:d5}} 
        push    bc                ;{{fb2d:c5}} 
_function_instr_45:               ;{{Addr=$fb2e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{fb2e:1a}} 
        cp      (hl)              ;{{fb2f:be}} 
        jr      nz,_function_instr_57;{{fb30:200b}}  (+$0b)
        inc     hl                ;{{fb32:23}} 
        inc     de                ;{{fb33:13}} 
        dec     c                 ;{{fb34:0d}} 
        jr      nz,_function_instr_45;{{fb35:20f7}}  (-$09)
        pop     bc                ;{{fb37:c1}} 
        pop     de                ;{{fb38:d1}} 
        pop     hl                ;{{fb39:e1}} 
        pop     af                ;{{fb3a:f1}} 
        jr      _function_instr_67;{{fb3b:180b}}  (+$0b)

_function_instr_57:               ;{{Addr=$fb3d Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{fb3d:c1}} 
        pop     de                ;{{fb3e:d1}} 
        pop     hl                ;{{fb3f:e1}} 
        pop     af                ;{{fb40:f1}} 
        inc     a                 ;{{fb41:3c}} 
        inc     hl                ;{{fb42:23}} 
        dec     b                 ;{{fb43:05}} 
        jr      _function_instr_38;{{fb44:18e0}}  (-$20)

_function_instr_65:               ;{{Addr=$fb46 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{fb46:f1}} 
_function_instr_66:               ;{{Addr=$fb47 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{fb47:af}} 
_function_instr_67:               ;{{Addr=$fb48 Code Calls/jump count: 2 Data use count: 0}}
        call    store_A_in_accumulator_as_INT;{{fb48:cd32ff}} 
        pop     hl                ;{{fb4b:e1}} 
        ret                       ;{{fb4c:c9}} 

_function_instr_70:               ;{{Addr=$fb4d Code Calls/jump count: 3 Data use count: 0}}
        push    de                ;{{fb4d:d5}} 
        push    hl                ;{{fb4e:e5}} 
        ld      de,_prob_copy_string_to_strings_area_11;{{fb4f:1165fb}}   ##LABEL##
        call    iterate_all_string_variables;{{fb52:cd93da}} 
        pop     hl                ;{{fb55:e1}} 
        pop     de                ;{{fb56:d1}} 
        ret                       ;{{fb57:c9}} 

;;==========================
;;prob copy string to strings area
prob_copy_string_to_strings_area: ;{{Addr=$fb58 Code Calls/jump count: 3 Data use count: 0}}
        push    hl                ;{{fb58:e5}} 
        ld      a,(hl)            ;{{fb59:7e}} 
        inc     hl                ;{{fb5a:23}} 
        ld      c,(hl)            ;{{fb5b:4e}} 
        inc     hl                ;{{fb5c:23}} 
        ld      b,(hl)            ;{{fb5d:46}} 
        ex      de,hl             ;{{fb5e:eb}} 
        or      a                 ;{{fb5f:b7}} 
        call    nz,_prob_copy_string_to_strings_area_11;{{fb60:c465fb}} 
        pop     hl                ;{{fb63:e1}} 
        ret                       ;{{fb64:c9}} 

_prob_copy_string_to_strings_area_11:;{{Addr=$fb65 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_end_of_free_space_);{{fb65:2a71b0}} 
        call    compare_HL_BC     ;{{fb68:cddeff}}  HL=BC?
        jr      nc,_prob_copy_string_to_strings_area_17;{{fb6b:3007}}  (+$07)
        ld      hl,(address_of_end_of_Strings_area_);{{fb6d:2a73b0}} 
        call    compare_HL_BC     ;{{fb70:cddeff}}  HL=BC?
        ret     nc                ;{{fb73:d0}} 

_prob_copy_string_to_strings_area_17:;{{Addr=$fb74 Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{fb74:eb}} 
        dec     hl                ;{{fb75:2b}} 
        dec     hl                ;{{fb76:2b}} 
        push    hl                ;{{fb77:e5}} 
        call    copy_last_string_used_to_strings_area;{{fb78:cdb9fb}} 
        pop     hl                ;{{fb7b:e1}} 

;;=store last string used (descriptor) to HL
store_last_string_used_descriptor_to_HL:;{{Addr=$fb7c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(length_of_last_String_used);{{fb7c:3a9cb0}} 
        ld      (hl),a            ;{{fb7f:77}} 
        inc     hl                ;{{fb80:23}} 
        ld      de,(address_of_last_String_used);{{fb81:ed5b9db0}} 
        ld      (hl),e            ;{{fb85:73}} 
        inc     hl                ;{{fb86:23}} 
        ld      (hl),d            ;{{fb87:72}} 
        inc     hl                ;{{fb88:23}} 
        ret                       ;{{fb89:c9}} 

;;=copy accumulator to strings area
copy_accumulator_to_strings_area: ;{{Addr=$fb8a Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_string_concat_area_minus_1;{{fb8a:cd37fc}} 
        ret     c                 ;{{fb8d:d8}} 

        call    copy_last_string_used_to_strings_area;{{fb8e:cdb9fb}} 
        jp      push_last_string_on_string_stack;{{fb91:c3d6fb}} 

_copy_accumulator_to_strings_area_4:;{{Addr=$fb94 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fb94:2aa0b0}} 
        call    get_addr_and_len_of_last_string_in_concat_area;{{fb97:cd1ffc}} 
        ld      a,b               ;{{fb9a:78}} 
        or      a                 ;{{fb9b:b7}} 
        ret     z                 ;{{fb9c:c8}} 

        push    hl                ;{{fb9d:e5}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{fb9e:2a64ae}} 
        call    compare_HL_DE     ;{{fba1:cdd8ff}}  HL=DE?
        ld      hl,(address_of_end_of_Strings_area_);{{fba4:2a73b0}} 
        ex      de,hl             ;{{fba7:eb}} 
        call    c,compare_HL_DE   ;{{fba8:dcd8ff}}  HL=DE?
        jr      nc,_copy_accumulator_to_strings_area_19;{{fbab:300a}}  (+$0a)
        ld      de,(address_after_end_of_program);{{fbad:ed5b66ae}} 
        call    compare_HL_DE     ;{{fbb1:cdd8ff}}  HL=DE?
        call    nc,is_accumulator_string_concat_area_minus_1;{{fbb4:d437fc}} 
_copy_accumulator_to_strings_area_19:;{{Addr=$fbb7 Code Calls/jump count: 1 Data use count: 0}}
        pop     hl                ;{{fbb7:e1}} 
        ret     c                 ;{{fbb8:d8}} 

;;=copy last string used to strings area
copy_last_string_used_to_strings_area:;{{Addr=$fbb9 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{fbb9:7e}} 
        call    alloc_space_in_strings_area;{{fbba:cd41fc}} 
        push    de                ;{{fbbd:d5}} 
        ld      a,(hl)            ;{{fbbe:7e}} 
        inc     hl                ;{{fbbf:23}} 
        ld      c,(hl)            ;{{fbc0:4e}} 
        inc     hl                ;{{fbc1:23}} 
        ld      h,(hl)            ;{{fbc2:66}} 
        ld      l,c               ;{{fbc3:69}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{fbc4:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     de                ;{{fbc7:d1}} 
        ld      hl,length_of_last_String_used;{{fbc8:219cb0}} 
        ret                       ;{{fbcb:c9}} 

;;=================
;;get string stack first free ptr
get_string_stack_first_free_ptr:  ;{{Addr=$fbcc Code Calls/jump count: 3 Data use count: 0}}
        ld      hl,string_stack_first;{{fbcc:217eb0}} 
        ld      (string_stack_first_free_ptr),hl;{{fbcf:227cb0}} 
        ret                       ;{{fbd2:c9}} 

_get_string_stack_first_free_ptr_3:;{{Addr=$fbd3 Code Calls/jump count: 2 Data use count: 0}}
        call    alloc_space_in_strings_area;{{fbd3:cd41fc}} 

;;=push last string on string stack
push_last_string_on_string_stack: ;{{Addr=$fbd6 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{fbd6:e5}} 
        ld      a,$03             ;{{fbd7:3e03}} accumulator is a string
        ld      (accumulator_data_type),a;{{fbd9:329fb0}} 
        ld      hl,(string_stack_first_free_ptr);{{fbdc:2a7cb0}} 
        ld      (accumulator),hl  ;{{fbdf:22a0b0}} 
        ld      de,string_stack_last + 1;{{fbe2:119cb0}} also next byte after end of string stack
        call    compare_HL_DE     ;{{fbe5:cdd8ff}}  HL=DE?       ;is string stack full
        ld      a,$10             ;{{fbe8:3e10}} String expression too complex error
        jp      z,raise_error     ;{{fbea:ca55cb}} 
        call    store_last_string_used_descriptor_to_HL;{{fbed:cd7cfb}} 
        ld      (string_stack_first_free_ptr),hl;{{fbf0:227cb0}} 
        pop     hl                ;{{fbf3:e1}} 
        ret                       ;{{fbf4:c9}} 

;;===================================
;;get accumulator string length
get_accumulator_string_length:    ;{{Addr=$fbf5 Code Calls/jump count: 11 Data use count: 0}}
        push    hl                ;{{fbf5:e5}} 
        call    error_if_accumulator_is_not_a_string;{{fbf6:cd5eff}} 
        ld      hl,(accumulator)  ;{{fbf9:2aa0b0}} 
        call    various_get_string_from_stack_stuff;{{fbfc:cd03fc}} 
        pop     hl                ;{{fbff:e1}} 
        ld      a,b               ;{{fc00:78}} 
        or      a                 ;{{fc01:b7}} 
        ret                       ;{{fc02:c9}} 

;;===================================
;;various get string from stack stuff
;get top string on stack
;or move top to string stack to variables area???
; (or preserve TOS string in data area?)
various_get_string_from_stack_stuff:;{{Addr=$fc03 Code Calls/jump count: 5 Data use count: 0}}
        call    get_addr_and_len_of_last_string_in_concat_area;{{fc03:cd1ffc}} 
        ret     nz                ;{{fc06:c0}} string addr <> HL

        ld      a,b               ;{{fc07:78}} 
        or      a                 ;{{fc08:b7}} 
        ret     z                 ;{{fc09:c8}} empty string

        ld      hl,(address_of_end_of_free_space_);{{fc0a:2a71b0}} we've popped a string off the stack
        inc     hl                ;{{fc0d:23}} 
        inc     hl                ;{{fc0e:23}} 
        inc     hl                ;{{fc0f:23}} 
        call    compare_HL_DE     ;{{fc10:cdd8ff}}  HL=DE? (DE = address of popped string)
        ret     nz                ;{{fc13:c0}} 

        dec     hl                ;{{fc14:2b}} 
        dec     hl                ;{{fc15:2b}} 
        ld      l,(hl)            ;{{fc16:6e}} length of last item?
        ld      h,$00             ;{{fc17:2600}} 
        add     hl,de             ;{{fc19:19}} move to free space?
        dec     hl                ;{{fc1a:2b}} 
        ld      (address_of_end_of_free_space_),hl;{{fc1b:2271b0}} 
        ret                       ;{{fc1e:c9}} 

;;=get addr and len of last string in concat area
;returns HL=addr, B=length
;if HL=address of last item then 'pops' it off the concat stack
get_addr_and_len_of_last_string_in_concat_area:;{{Addr=$fc1f Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{fc1f:e5}} 
        ld      de,(string_stack_first_free_ptr);{{fc20:ed5b7cb0}} 
        dec     de                ;{{fc24:1b}} 
        dec     de                ;{{fc25:1b}} 
        dec     de                ;{{fc26:1b}} 
        call    compare_HL_DE     ;{{fc27:cdd8ff}}  HL=DE?
        jr      nz,_get_addr_and_len_of_last_string_in_concat_area_8;{{fc2a:2004}}  (+$04)
        ld      (string_stack_first_free_ptr),de;{{fc2c:ed537cb0}} 
_get_addr_and_len_of_last_string_in_concat_area_8:;{{Addr=$fc30 Code Calls/jump count: 1 Data use count: 0}}
        ld      b,(hl)            ;{{fc30:46}} 
        inc     hl                ;{{fc31:23}} 
        ld      e,(hl)            ;{{fc32:5e}} 
        inc     hl                ;{{fc33:23}} 
        ld      d,(hl)            ;{{fc34:56}} 
        pop     hl                ;{{fc35:e1}} 
        ret                       ;{{fc36:c9}} 

;;============================
;;is accumulator string concat area minus 1
;are we testing for empty string concat area?
is_accumulator_string_concat_area_minus_1:;{{Addr=$fc37 Code Calls/jump count: 2 Data use count: 0}}
        ld      hl,(accumulator)  ;{{fc37:2aa0b0}} 
        ld      a,string_stack_first - 1 and $ff;{{fc3a:3e7d}}  $7d  string stack start - 1 (low byte)
        sub     l                 ;{{fc3c:95}} 
        ld      a,string_stack_first - 1 >> 8;{{fc3d:3eb0}}  $b0  string stack start - 1 (high byte)
        sbc     a,h               ;{{fc3f:9c}} 
        ret                       ;{{fc40:c9}} 

;;==============================
;;alloc space in strings area
alloc_space_in_strings_area:      ;{{Addr=$fc41 Code Calls/jump count: 5 Data use count: 0}}
        push    hl                ;{{fc41:e5}} 
        push    bc                ;{{fc42:c5}} 
        ld      c,a               ;{{fc43:4f}} 
        or      a                 ;{{fc44:b7}} 
        call    nz,alloc_C_bytes_in_string_space;{{fc45:c493f6}} 
        ld      a,c               ;{{fc48:79}} 
        ld      (length_of_last_String_used),a;{{fc49:329cb0}} 
        ld      (address_of_last_String_used),hl;{{fc4c:229db0}} 
        ex      de,hl             ;{{fc4f:eb}} 
        pop     bc                ;{{fc50:c1}} 
        pop     hl                ;{{fc51:e1}} 
        ret                       ;{{fc52:c9}} 

;;========================================================
;; function FRE
;count free memory (and do garbage collection)
function_FRE:                     ;{{Addr=$fc53 Code Calls/jump count: 0 Data use count: 1}}
        call    is_accumulator_a_string;{{fc53:cd66ff}} 
        jr      nz,_function_fre_4;{{fc56:2006}}  (+$06)
        call    get_accumulator_string_length;{{fc58:cdf5fb}} 
        call    _function_fre_6   ;{{fc5b:cd64fc}} 
_function_fre_4:                  ;{{Addr=$fc5e Code Calls/jump count: 1 Data use count: 0}}
        call    get_free_space_byte_count_in_HL_addr_in_DE;{{fc5e:cdfcf6}} 
        jp      set_accumulator_as_REAL_from_unsigned_INT;{{fc61:c389fe}} 

_function_fre_6:                  ;{{Addr=$fc64 Code Calls/jump count: 6 Data use count: 0}}
        push    hl                ;{{fc64:e5}} 
        push    de                ;{{fc65:d5}} 
        push    bc                ;{{fc66:c5}} 
        ld      hl,string_stack_first;{{fc67:217eb0}} 
        jr      _function_fre_21  ;{{fc6a:180c}}  (+$0c)

_function_fre_11:                 ;{{Addr=$fc6c Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{fc6c:7e}} 
        inc     hl                ;{{fc6d:23}} 
        ld      c,(hl)            ;{{fc6e:4e}} 
        inc     hl                ;{{fc6f:23}} 
        ld      b,(hl)            ;{{fc70:46}} 
        ex      de,hl             ;{{fc71:eb}} 
        or      a                 ;{{fc72:b7}} 
        call    nz,poss_free_string_at_BC_length_A;{{fc73:c4e3fc}} 
        ex      de,hl             ;{{fc76:eb}} 
        inc     hl                ;{{fc77:23}} 
_function_fre_21:                 ;{{Addr=$fc78 Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(string_stack_first_free_ptr);{{fc78:ed5b7cb0}} 
        call    compare_HL_DE     ;{{fc7c:cdd8ff}}  HL=DE?
        jr      nz,_function_fre_11;{{fc7f:20eb}}  (-$15) 
        ld      de,poss_free_string_at_BC_length_A;{{fc81:11e3fc}}   ##LABEL##
        call    iterate_all_string_variables;{{fc84:cd93da}} 
        ld      hl,(address_of_end_of_Strings_area_);{{fc87:2a73b0}} 
        push    hl                ;{{fc8a:e5}} 
        ld      hl,(address_of_end_of_free_space_);{{fc8b:2a71b0}} 
        inc     hl                ;{{fc8e:23}} 
        ld      e,l               ;{{fc8f:5d}} 
        ld      d,h               ;{{fc90:54}} 
        jr      _function_fre_49  ;{{fc91:1814}}  (+$14)

_function_fre_33:                 ;{{Addr=$fc93 Code Calls/jump count: 1 Data use count: 0}}
        ld      c,(hl)            ;{{fc93:4e}} 
        inc     hl                ;{{fc94:23}} 
        ld      b,(hl)            ;{{fc95:46}} 
        inc     b                 ;{{fc96:04}} 
        dec     b                 ;{{fc97:05}} 
        jr      z,_function_fre_47;{{fc98:280b}}  (+$0b)
        dec     hl                ;{{fc9a:2b}} 
        ld      a,(bc)            ;{{fc9b:0a}} 
        ld      c,a               ;{{fc9c:4f}} 
        ld      b,$00             ;{{fc9d:0600}} 
        inc     bc                ;{{fc9f:03}} 
        inc     bc                ;{{fca0:03}} 
        ldir                      ;{{fca1:edb0}} 
        jr      _function_fre_49  ;{{fca3:1802}}  (+$02)

_function_fre_47:                 ;{{Addr=$fca5 Code Calls/jump count: 1 Data use count: 0}}
        inc     hl                ;{{fca5:23}} 
        add     hl,bc             ;{{fca6:09}} 
_function_fre_49:                 ;{{Addr=$fca7 Code Calls/jump count: 2 Data use count: 0}}
        pop     bc                ;{{fca7:c1}} 
        push    bc                ;{{fca8:c5}} 
        call    compare_HL_BC     ;{{fca9:cddeff}}  HL=BC?
        jr      c,_function_fre_33;{{fcac:38e5}}  (-$1b)
        dec     de                ;{{fcae:1b}} 
        ld      hl,(address_of_end_of_free_space_);{{fcaf:2a71b0}} 
        ex      de,hl             ;{{fcb2:eb}} 
        call    BC_equal_HL_minus_DE;{{fcb3:cde4ff}}  BC = HL-DE
        pop     de                ;{{fcb6:d1}} 
        call    compare_HL_DE     ;{{fcb7:cdd8ff}}  HL=DE?
        push    af                ;{{fcba:f5}} 
        push    de                ;{{fcbb:d5}} 
        call    copy_bytes_LDDR_BCcount_HLsource_DEdest;{{fcbc:cdf5ff}}  copy bytes LDDR (BC = count)
        ex      de,hl             ;{{fcbf:eb}} 
        ld      (address_of_end_of_free_space_),hl;{{fcc0:2271b0}} 
        pop     bc                ;{{fcc3:c1}} 
        inc     hl                ;{{fcc4:23}} 
        jr      _function_fre_83  ;{{fcc5:1812}}  (+$12)

_function_fre_67:                 ;{{Addr=$fcc7 Code Calls/jump count: 1 Data use count: 0}}
        ld      e,(hl)            ;{{fcc7:5e}} 
        inc     hl                ;{{fcc8:23}} 
        ld      d,(hl)            ;{{fcc9:56}} 
        dec     hl                ;{{fcca:2b}} 
        ld      a,(de)            ;{{fccb:1a}} 
        ld      (hl),a            ;{{fccc:77}} 
        inc     hl                ;{{fccd:23}} 
        ld      (hl),$00          ;{{fcce:3600}} 
        inc     hl                ;{{fcd0:23}} 
        ex      de,hl             ;{{fcd1:eb}} 
        ld      (hl),d            ;{{fcd2:72}} 
        dec     hl                ;{{fcd3:2b}} 
        ld      (hl),e            ;{{fcd4:73}} 
        ld      l,a               ;{{fcd5:6f}} 
        ld      h,$00             ;{{fcd6:2600}} 
        add     hl,de             ;{{fcd8:19}} 
_function_fre_83:                 ;{{Addr=$fcd9 Code Calls/jump count: 1 Data use count: 0}}
        call    compare_HL_BC     ;{{fcd9:cddeff}}  HL=BC?
        jr      c,_function_fre_67;{{fcdc:38e9}}  (-$17)
        pop     af                ;{{fcde:f1}} 
        pop     bc                ;{{fcdf:c1}} 
        pop     de                ;{{fce0:d1}} 
        pop     hl                ;{{fce1:e1}} 
        ret                       ;{{fce2:c9}} 

;;=================================
;;poss free string at BC length A
poss_free_string_at_BC_length_A:  ;{{Addr=$fce3 Code Calls/jump count: 1 Data use count: 1}}
        ld      hl,(address_of_start_of_free_space_);{{fce3:2a6cae}} 
        call    compare_HL_BC     ;{{fce6:cddeff}}  HL=BC?
        ret     nc                ;{{fce9:d0}} 

        dec     bc                ;{{fcea:0b}} 
        ld      a,d               ;{{fceb:7a}} 
        ld      (bc),a            ;{{fcec:02}} 
        dec     bc                ;{{fced:0b}} 
        ld      a,(bc)            ;{{fcee:0a}} 
        ld      (de),a            ;{{fcef:12}} 
        ld      a,e               ;{{fcf0:7b}} 
        ld      (bc),a            ;{{fcf1:02}} 
        ret                       ;{{fcf2:c9}} 

_poss_free_string_at_bc_length_a_12:;{{Addr=$fcf3 Code Calls/jump count: 1 Data use count: 0}}
        call    return_accumulator_value_if_int_or_address_if_real;{{fcf3:cd4fff}} 
        jp      nc,REAL_prepare_for_decimal;{{fcf6:d276bd}}  firmware maths??
        call    unknown_maths_fixup;{{fcf9:cd2add}} 
        ld      (accumulator),hl  ;{{fcfc:22a0b0}} 
        ld      hl,accumulator_plus_1;{{fcff:21a1b0}} 
        ret                       ;{{fd02:c9}} 

_poss_free_string_at_bc_length_a_18:;{{Addr=$fd03 Code Calls/jump count: 1 Data use count: 0}}
        call    function_UNT      ;{{fd03:cdebfe}} 
        ld      hl,accumulator_plus_1;{{fd06:21a1b0}} 
        jp      set_B_zero_E_zero_C_to_2_int_type;{{fd09:c330dd}} 




