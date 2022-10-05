;;<< STRING FUNCTIONS
;;<including the string iterator
;;===================================================================
;String parsing routines
;They returns with HL at end of string and B=length of string
;Each uses the iterator at string_getter which takes the following code section as a callback

;;=get quoted string
;String wrapped in double quotes
get_quoted_string:                ;{{Addr=$f879 Code Calls/jump count: 3 Data use count: 0}}
        inc     hl                ;{{f879:23}} 
        call    string_getter     ;{{f87a:cda7f8}}  Uses the following code as a callback (doesn't return to it)

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
        call    string_getter     ;{{f88a:cda7f8}}  Uses the following code as a callback (doesn't return to it)

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
        call    string_getter     ;{{f894:cda7f8}}  Uses the following code as a callback (doesn't return to it)

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
        pop     de                ;{{f8aa:d1}}  Get address of callback code
        ld      b,$00             ;{{f8ab:0600}}  B = string length
        call    JP_DE             ;{{f8ad:cdfeff}}  JP (DE) call get string subroutine
        ld      a,b               ;{{f8b0:78}}  Only the ASCIIZ variant returns here
        ld      (length_of_last_String_used),a;{{f8b1:329cb0}} 
        jp      push_last_string_descriptor_on_string_stack;{{f8b4:c3d6fb}} $b09d = start of string. 
                                  ;$b09c, A and B equal length 
                                  ;HL = next byte after string (and after whitespace)
                                        
;;===================================================
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

;;=================================================
;;=prob output first C chars of accumulator string
prob_output_first_C_chars_of_accumulator_string:;{{Addr=$f8dc Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{f8dc:cdf5fb}} 
        ret     z                 ;{{f8df:c8}} 

        ld      a,c               ;{{f8e0:79}} 
        sub     b                 ;{{f8e1:90}} 
        jr      nc,_prob_output_first_c_chars_of_accumulator_string_9;{{f8e2:3005}}  (+$05)
        add     a,b               ;{{f8e4:80}} 
        jr      z,_prob_output_first_c_chars_of_accumulator_string_9;{{f8e5:2802}}  (+$02)
        ld      b,a               ;{{f8e7:47}} 
        xor     a                 ;{{f8e8:af}} 
_prob_output_first_c_chars_of_accumulator_string_9:;{{Addr=$f8e9 Code Calls/jump count: 2 Data use count: 0}}
        ld      c,a               ;{{f8e9:4f}} 
        jr      output_string_atDE_length_B;{{f8ea:18e8}}  (-$18)

;;========================================================
;; function LOWER$
;LOWER$(<string expression>)
;Returns a lowercase copy of the parameter.

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
;UPPER$(<string expression>)
;Returns an upper case copy of the string

function_UPPER:                   ;{{Addr=$f8fa Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,convert_character_to_upper_case;{{f8fa:01abff}} ##LABEL##

;;=string iterator
;Copies the string in the accumulator,
;calls the iterator routine for each character,
;thens add the new string back to the accumulator/string stack
;BC = routine to call for each character
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
        jp      z,push_last_string_descriptor_on_string_stack;{{f90f:cad6fb}} 
        push    af                ;{{f912:f5}} 
        ld      a,(hl)            ;{{f913:7e}} 
        inc     hl                ;{{f914:23}} 
        call    JP_BC             ;{{f915:cdfcff}}  JP (BC) call callback function
        ld      (de),a            ;{{f918:12}} 
        inc     de                ;{{f919:13}} 
        pop     af                ;{{f91a:f1}} 
        jr      _string_iterator_11;{{f91b:18f1}}  (-$0f)

;;====================================================
;;=concat two strings
;HL=address of a string descriptor
;Appends the string in the accumulator to the string at HL,
;returns it in the accumulator/string stack
concat_two_strings:               ;{{Addr=$f91d Code Calls/jump count: 1 Data use count: 0}}
        ld      de,(accumulator)  ;{{f91d:ed5ba0b0}} 
        ld      a,(de)            ;{{f921:1a}} 
        add     a,(hl)            ;{{f922:86}} 
        jr      nc,_concat_two_strings_6;{{f923:3004}}  (+$04)
        call    byte_following_call_is_error_code;{{f925:cd45cb}} 
        defb $0f                  ;Inline error code: String too long
    
_concat_two_strings_6:            ;{{Addr=$f929 Code Calls/jump count: 1 Data use count: 0}}
        call    alloc_space_in_strings_area;{{f929:cd41fc}} 
        call    get_string_stack_TOS;{{f92c:cd59f9}} 
        push    de                ;{{f92f:d5}} 
        push    bc                ;{{f930:c5}} 
        ld      c,b               ;{{f931:48}} 
        call    push_last_string_descriptor_on_string_stack;{{f932:cdd6fb}} 
        ld      a,c               ;{{f935:79}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f936:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     bc                ;{{f939:c1}} 
        pop     hl                ;{{f93a:e1}} 
        ld      a,c               ;{{f93b:79}} 
        jp      copy_bytes_LDIR__Acount_HLsource_DEdest;{{f93c:c3ecff}} ; copy bytes (A=count, HL=source, DE=dest)

;;================================================
;;string comparison

string_comparison:                ;{{Addr=$f93f Code Calls/jump count: 1 Data use count: 0}}
        call    get_string_stack_TOS;{{f93f:cd59f9}} 
        xor     a                 ;{{f942:af}} 
_string_comparison_2:             ;{{Addr=$f943 Code Calls/jump count: 1 Data use count: 0}}
        cp      c                 ;{{f943:b9}} 
        jr      z,_string_comparison_17;{{f944:280f}}  (+$0f)
        cp      b                 ;{{f946:b8}} 
        jr      z,_string_comparison_15;{{f947:280a}}  (+$0a)
        dec     b                 ;{{f949:05}} 
        dec     c                 ;{{f94a:0d}} 
        ld      a,(de)            ;{{f94b:1a}} 
        inc     de                ;{{f94c:13}} 
        sub     (hl)              ;{{f94d:96}} 
        inc     hl                ;{{f94e:23}} 
        jr      z,_string_comparison_2;{{f94f:28f2}}  (-$0e)
        sbc     a,a               ;{{f951:9f}} 
        ret     nz                ;{{f952:c0}} 

_string_comparison_15:            ;{{Addr=$f953 Code Calls/jump count: 1 Data use count: 0}}
        inc     a                 ;{{f953:3c}} 
        ret                       ;{{f954:c9}} 

_string_comparison_17:            ;{{Addr=$f955 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{f955:b8}} 
        ret     z                 ;{{f956:c8}} 

        sbc     a,a               ;{{f957:9f}} 
        ret                       ;{{f958:c9}} 

;;=get string stack TOS
get_string_stack_TOS:             ;{{Addr=$f959 Code Calls/jump count: 2 Data use count: 0}}
        call    get_accumulator_string_length;{{f959:cdf5fb}} 
        ld      c,b               ;{{f95c:48}} 
        push    de                ;{{f95d:d5}} 
        call    pop_TOS_from_string_stack_and_strings_area;{{f95e:cd03fc}} 
        ex      de,hl             ;{{f961:eb}} 
        pop     de                ;{{f962:d1}} 
        ret                       ;{{f963:c9}} 

;;========================================================================
;; function BIN$
;BIN$(<unsigned integer expression>[,<field width>]
;Convert the expression to a binary ASCII string padded to the given width with leading zeros
;Expression can be -32767..65535
;Field width can be 0..16

function_BIN:                     ;{{Addr=$f964 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$0101          ;{{f964:010101}} One bit per digit and mask for one digit
        jr      _function_hex_1   ;{{f967:1803}}  (+$03)

;;========================================================================
;; function HEX$
;HEX$(<unsigned integer expression>[,<field width>]
;Convert the expression to a hexadecimal ASCII string padded to the given width with leading zeros
;Expression can be -32767..65535
;Field width can be 0..16

function_HEX:                     ;{{Addr=$f969 Code Calls/jump count: 0 Data use count: 1}}
        ld      bc,$040f          ;{{f969:010f04}} Four bits per digit and mask for one digit

_function_hex_1:                  ;{{Addr=$f96c Code Calls/jump count: 1 Data use count: 0}}
        push    bc                ;{{f96c:c5}} 
        call    eval_expression   ;{{f96d:cd62cf}} Read value
        push    hl                ;{{f970:e5}} 
        call    function_UNT      ;{{f971:cdebfe}} Convert to unsigned integer
        ex      (sp),hl           ;{{f974:e3}} 
        call    next_token_if_prev_is_comma;{{f975:cd41de}} Comma?
        sbc     a,a               ;{{f978:9f}} Calc default width and flag
        call    c,eval_expr_as_byte_or_error;{{f979:dcb8ce}} If so read width parameter
        cp      $11               ;{{f97c:fe11}} Width must be <= 16
        jp      nc,Error_Improper_Argument;{{f97e:d24dcb}} Error: Improper Argument
        ld      b,a               ;{{f981:47}} Preserve width
        call    next_token_if_close_bracket;{{f982:cd1dde}} Check for close bracket
        ld      a,b               ;{{f985:78}} Restore width
        ex      de,hl             ;{{f986:eb}} 
        pop     hl                ;{{f987:e1}} 
        pop     bc                ;{{f988:c1}} 
        push    de                ;{{f989:d5}} 
        call    convert_based_number_to_string;{{f98a:cddff1}} Convert to ASCIIZ string
        jr      copy_ASCIIZ_string_to_stack_and_accumulator;{{f98d:1831}}  (+$31)

;;========================================================================
;; function DEC$
;DEC$(<numeric expression>,<format template>)
;Generate a formatted string representation of a number.
;Format templates are as per PRINT USING but only the following characters are allowed:
;   + - $ * # , . ^

function_DEC:                     ;{{Addr=$f98f Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{f98f:cd62cf}} 
        call    next_token_if_comma;{{f992:cd15de}}  check for comma
        call    push_numeric_accumulator_on_execution_stack;{{f995:cd74ff}} 
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
        call    nz,parse_number_format_template;{{f9ab:c448f4}} 
        jp      nc,Error_Improper_Argument;{{f9ae:d24dcb}}  Error: Improper Argument
        ld      a,b               ;{{f9b1:78}} 
        or      a                 ;{{f9b2:b7}} 
        jp      nz,Error_Improper_Argument;{{f9b3:c24dcb}}  Error: Improper Argument
        ld      a,c               ;{{f9b6:79}} 
        call    convert_number_to_string_by_format;{{f9b7:cd6aef}} 
        jr      copy_ASCIIZ_string_to_stack_and_accumulator;{{f9ba:1804}}  (+$04)

;;========================================================
;; function STR$
;STR$(<numeric expression>)
;Converts a number to it's string representation

function_STR:                     ;{{Addr=$f9bc Code Calls/jump count: 0 Data use count: 1}}
        push    hl                ;{{f9bc:e5}} 
        call    conv_number_to_decimal_string;{{f9bd:cd68ef}} 

;;=copy ASCIIZ string to stack and accumulator
copy_ASCIIZ_string_to_stack_and_accumulator:;{{Addr=$f9c0 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{f9c0:e5}} 
        ld      c,$ff             ;{{f9c1:0eff}} 
        xor     a                 ;{{f9c3:af}} 

_copy_asciiz_string_to_stack_and_accumulator_3:;{{Addr=$f9c4 Code Calls/jump count: 1 Data use count: 0}}
        inc     c                 ;{{f9c4:0c}} Count string length (ASCIIZ)
        cp      (hl)              ;{{f9c5:be}} 
        inc     hl                ;{{f9c6:23}} 
        jr      nz,_copy_asciiz_string_to_stack_and_accumulator_3;{{f9c7:20fb}}  (-$05)

        pop     hl                ;{{f9c9:e1}} 
        ld      a,c               ;{{f9ca:79}} 
        call    alloc_string_push_on_stack_and_accumulator;{{f9cb:cdd3fb}} 
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{f9ce:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{f9d1:e1}} 
        ret                       ;{{f9d2:c9}} 

;;========================================================================
;; function LEFT$
;LEFT$(<string expression>,<required length>)
;Returns the given number of characters from the left of the string.
;Length can be 0..255

function_LEFT:                    ;{{Addr=$f9d3 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_string_then_byte_parameters;{{f9d3:cd43fa}} 
        jr      do_extract_substring;{{f9d6:1818}}  (+$18)

;;========================================================================
;; function RIGHT$
;RIGHT$(<string expression>,<required length>)
;Returns the given number of characters from the right of a string.
;Length is 0..255

function_RIGHT:                   ;{{Addr=$f9d8 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_string_then_byte_parameters;{{f9d8:cd43fa}} 
        ld      a,(de)            ;{{f9db:1a}} 
        sub     b                 ;{{f9dc:90}} 
        jr      c,do_extract_substring;{{f9dd:3811}}  (+$11)
        ld      c,a               ;{{f9df:4f}} 
        jr      do_extract_substring;{{f9e0:180e}}  (+$0e)

;;=======================================================================
;; prefix MID$
;MID$(<string expression>,<start position>[,<sub-string length>])
;Extract substring. (See also command MID$)
;Position and length can be 1..255

prefix_MID:                       ;{{Addr=$f9e2 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{f9e2:cd19de}}  check for open bracket
        call    eval_string_then_byte_parameters;{{f9e5:cd43fa}} 
        jp      z,Error_Improper_Argument;{{f9e8:ca4dcb}}  Error: Improper Argument
        dec     b                 ;{{f9eb:05}} 
        ld      c,b               ;{{f9ec:48}} 
        call    eval_byte_param_or_ff;{{f9ed:cd4ffa}} 
;;------------------------------------------------------------------------
;;=do extract substring
do_extract_substring:             ;{{Addr=$f9f0 Code Calls/jump count: 3 Data use count: 0}}
        call    next_token_if_close_bracket;{{f9f0:cd1dde}}  check for close bracket
        push    hl                ;{{f9f3:e5}} 
        ex      de,hl             ;{{f9f4:eb}} 
        call    calc_substring_length;{{f9f5:cd60fa}} 
        call    alloc_space_in_strings_area;{{f9f8:cd41fc}} 
        call    pop_TOS_from_string_stack_and_strings_area;{{f9fb:cd03fc}} 
        ex      de,hl             ;{{f9fe:eb}} 
        call    push_last_string_descriptor_on_string_stack;{{f9ff:cdd6fb}} 
        ld      b,$00             ;{{fa02:0600}} 
        add     hl,bc             ;{{fa04:09}} 
        jr      do_copy_substring ;{{fa05:1837}}  (+$37)

;;========================================================================
;; command MID$
;MID$(<string variable>,<start position>[,sub-string length])=<string expression>
;Replaces the specified characters within the first string variable with the second string variable.
;See also function MID$

command_MID:                      ;{{Addr=$fa07 Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_open_bracket;{{fa07:cd19de}}  check for open bracket
        call    parse_and_find_or_create_a_var;{{fa0a:cdbfd6}} 
        call    error_if_accumulator_is_not_a_string;{{fa0d:cd5eff}} 
        push    hl                ;{{fa10:e5}} 
        ex      de,hl             ;{{fa11:eb}} 
        call    copy_string_to_strings_area_if_not_in_strings_area;{{fa12:cd58fb}} 
        ex      (sp),hl           ;{{fa15:e3}} 
        call    _eval_byte_param_or_ff_4;{{fa16:cd55fa}} 
        jp      z,Error_Improper_Argument;{{fa19:ca4dcb}}  Error: Improper Argument
        dec     a                 ;{{fa1c:3d}} 
        ld      c,a               ;{{fa1d:4f}} 
        call    eval_byte_param_or_ff;{{fa1e:cd4ffa}} 
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
        call    calc_substring_length;{{fa32:cd60fa}} 
        inc     hl                ;{{fa35:23}} 
        ld      b,(hl)            ;{{fa36:46}} 
        inc     hl                ;{{fa37:23}} 
        ld      h,(hl)            ;{{fa38:66}} 
        ld      l,b               ;{{fa39:68}} 
        ld      b,$00             ;{{fa3a:0600}} 
        add     hl,bc             ;{{fa3c:09}} 
        ex      de,hl             ;{{fa3d:eb}} 
;;=do copy substring
do_copy_substring:                ;{{Addr=$fa3e Code Calls/jump count: 1 Data use count: 0}}
        call    copy_bytes_LDIR__Acount_HLsource_DEdest;{{fa3e:cdecff}} ; copy bytes (A=count, HL=source, DE=dest)
        pop     hl                ;{{fa41:e1}} 
        ret                       ;{{fa42:c9}} 

;;=eval string then byte parameters
;Returns the string in the accumulator,
;and the byte in B
;Zero flag set if the byte is zero.
eval_string_then_byte_parameters: ;{{Addr=$fa43 Code Calls/jump count: 3 Data use count: 0}}
        call    eval_expr_and_error_if_not_string;{{fa43:cd09cf}} 
        ex      de,hl             ;{{fa46:eb}} 
        ld      hl,(accumulator)  ;{{fa47:2aa0b0}} 
        ex      de,hl             ;{{fa4a:eb}} 
        ld      c,$00             ;{{fa4b:0e00}} 
        jr      _eval_byte_param_or_ff_4;{{fa4d:1806}}  (+$06)

;;=eval byte param or ff
;If we have another parameter, return it in B. If no more params return B=$ff
eval_byte_param_or_ff:            ;{{Addr=$fa4f Code Calls/jump count: 2 Data use count: 0}}
        ld      b,$ff             ;{{fa4f:06ff}} 
        ld      a,(hl)            ;{{fa51:7e}} 
        cp      $29               ;{{fa52:fe29}} ')'
        ret     z                 ;{{fa54:c8}} 

_eval_byte_param_or_ff_4:         ;{{Addr=$fa55 Code Calls/jump count: 2 Data use count: 0}}
        push    de                ;{{fa55:d5}} 
        call    next_token_if_comma;{{fa56:cd15de}}  check for comma
        call    eval_expr_as_byte_or_error;{{fa59:cdb8ce}}  get number and check it's less than 255 
        ld      b,a               ;{{fa5c:47}} 
        pop     de                ;{{fa5d:d1}} 
        or      a                 ;{{fa5e:b7}} 
        ret                       ;{{fa5f:c9}} 

;;=calc substring length
calc_substring_length:            ;{{Addr=$fa60 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(hl)            ;{{fa60:7e}} 
        sub     c                 ;{{fa61:91}} 
        jr      nc,_calc_substring_length_4;{{fa62:3001}}  (+$01)
        xor     a                 ;{{fa64:af}} 
_calc_substring_length_4:         ;{{Addr=$fa65 Code Calls/jump count: 1 Data use count: 0}}
        cp      b                 ;{{fa65:b8}} 
        ret     c                 ;{{fa66:d8}} 

        ld      a,b               ;{{fa67:78}} 
        ret                       ;{{fa68:c9}} 

;;========================================================
;; function LEN
;LEN(<string expression>)
;Returns the length of the string, or zero if the string is empty.

function_LEN:                     ;{{Addr=$fa69 Code Calls/jump count: 0 Data use count: 1}}
        call    get_accumulator_string_length;{{fa69:cdf5fb}} 
        jr      _function_asc_1   ;{{fa6c:1803}}  (+$03)

;;========================================================
;; function ASC
;ASC(<string expression>)
;Returns the ASCII value of a character (first character of the supplied string)

function_ASC:                     ;{{Addr=$fa6e Code Calls/jump count: 0 Data use count: 1}}
        call    get_first_char_of_string_or_error;{{fa6e:cda6fa}} 
_function_asc_1:                  ;{{Addr=$fa71 Code Calls/jump count: 1 Data use count: 0}}
        jp      store_A_in_accumulator_as_INT;{{fa71:c332ff}} 

;;========================================================
;; function CHR$
;CHR$(<integer expression>)
;Returns the ASCII character with the given value

function_CHR:                     ;{{Addr=$fa74 Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{fa74:cdd9fa}} 

;;=create single char string
;Creates a string with a single character.
;A=the character
create_single_char_string:        ;{{Addr=$fa77 Code Calls/jump count: 1 Data use count: 0}}
        scf                       ;{{fa77:37}} 

;;=create single char or null string
;If carry set, creates a single character string,
;if carry clear creates an empty string
;A=character
create_single_char_or_null_string:;{{Addr=$fa78 Code Calls/jump count: 4 Data use count: 0}}
        ld      c,a               ;{{fa78:4f}} 
        sbc     a,a               ;{{fa79:9f}} 
        and     $01               ;{{fa7a:e601}} 
        jr      create_filled_string;{{fa7c:1834}}  (+$34)

;;=========================================================
;; variable INKEY$
;INKEY$
;Returns the next key, if any, from the keyboard
;If no key is available returns an empty string.

variable_INKEY:                   ;{{Addr=$fa7e Code Calls/jump count: 0 Data use count: 1}}
        call    jp_km_read_char   ;{{fa7e:cd6fc4}}  call to firmware function: km read key			
        jr      nc,create_single_char_or_null_string;{{fa81:30f5}}  
        cp      $fc               ;{{fa83:fefc}} 
        jr      z,create_single_char_or_null_string;{{fa85:28f1}} 
        cp      $ef               ;{{fa87:feef}} token for '='
        jr      z,create_single_char_or_null_string;{{fa89:28ed}}  (-$13)
        jr      create_single_char_string;{{fa8b:18ea}}  (-$16)

;;=========================================================
;; function STRING$
;STRING$(<length>,<character specifier>)
;Creates a string of a specified character.
;Length must be 0..255
;The character specifier may be an integer value or a string.
;Only the first character of the string is repeated

function_STRING:                  ;{{Addr=$fa8d Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expr_as_byte_or_error;{{fa8d:cdb8ce}}  get number and check it's less than 255 
        push    af                ;{{fa90:f5}} 
        call    next_token_if_comma;{{fa91:cd15de}}  check for comma
        call    eval_expression   ;{{fa94:cd62cf}} 
        call    next_token_if_close_bracket;{{fa97:cd1dde}}  check for close bracket
        call    get_first_char_from_accumulator_or_error;{{fa9a:cda1fa}} 
        ld      c,a               ;{{fa9d:4f}} 
        pop     af                ;{{fa9e:f1}} 
        jr      create_filled_string;{{fa9f:1811}}  (+$11)

;;=get first char from accumulator or error
;If the accumulator is a string returns the first character,
;otherwise raises an error
get_first_char_from_accumulator_or_error:;{{Addr=$faa1 Code Calls/jump count: 1 Data use count: 0}}
        call    is_accumulator_a_string;{{faa1:cd66ff}} 
        jr      nz,param_less_than_256_or_error;{{faa4:2033}}  (+$33)
;;=get first char of string or error
get_first_char_of_string_or_error:;{{Addr=$faa6 Code Calls/jump count: 1 Data use count: 0}}
        call    get_accumulator_string_length;{{faa6:cdf5fb}} 
        jr      z,raise_improper_argument_error_G;{{faa9:2837}}  (+$37)
        ld      a,(de)            ;{{faab:1a}} 
        ret                       ;{{faac:c9}} 

;;========================================================
;; function SPACE$

function_SPACE:                   ;{{Addr=$faad Code Calls/jump count: 0 Data use count: 1}}
        call    param_less_than_256_or_error;{{faad:cdd9fa}} 
        ld      c,$20             ;{{fab0:0e20}} 

;;=create filled string
;Create a string of length A filled with char/byte C
create_filled_string:             ;{{Addr=$fab2 Code Calls/jump count: 2 Data use count: 0}}
        ld      b,a               ;{{fab2:47}} 
        call    alloc_string_push_on_stack_and_accumulator;{{fab3:cdd3fb}} 
        ld      a,c               ;{{fab6:79}} 
        inc     b                 ;{{fab7:04}} 
_create_filled_string_4:          ;{{Addr=$fab8 Code Calls/jump count: 1 Data use count: 0}}
        dec     b                 ;{{fab8:05}} 
        ret     z                 ;{{fab9:c8}} 

        ld      (de),a            ;{{faba:12}} 
        inc     de                ;{{fabb:13}} 
        jr      _create_filled_string_4;{{fabc:18fa}}  (-$06)

;;========================================================
;; function VAL
;VAL(<string expression>)
;Converts a string to a number

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
        call    convert_string_to_number;{{face:cd6fed}} 
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
raise_improper_argument_error_G:  ;{{Addr=$fae2 Code Calls/jump count: 1 Data use count: 0}}
        jp      Error_Improper_Argument;{{fae2:c34dcb}}  Error: Improper Argument

;;========================================================================
;; function INSTR
;INSTR([<start position>,]<searched string>,<searched for string>])
;Searches for a substring within another and returns it's position, or zero if not found.
;Valid start position is 1..255
;If the searched string is empty always returns zero

function_INSTR:                   ;{{Addr=$fae5 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_expression   ;{{fae5:cd62cf}} 
        call    is_accumulator_a_string;{{fae8:cd66ff}} 
        ld      c,$01             ;{{faeb:0e01}} 
        jr      z,instr_no_start_pos_parameter;{{faed:280e}}  (+$0e)

        call    param_less_than_256_or_error;{{faef:cdd9fa}} 
        or      a                 ;{{faf2:b7}} 
        jp      z,Error_Improper_Argument;{{faf3:ca4dcb}}  Error: Improper Argument
        ld      c,a               ;{{faf6:4f}} 
        call    next_token_if_comma;{{faf7:cd15de}}  check for comma
        call    eval_expr_and_error_if_not_string;{{fafa:cd09cf}} 

;;=instr no start pos parameter
instr_no_start_pos_parameter:     ;{{Addr=$fafd Code Calls/jump count: 1 Data use count: 0}}
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
        call    pop_TOS_from_string_stack_and_strings_area;{{fb10:cd03fc}} 
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
        jr      c,instr_return_zero;{{fb20:3825}}  (+$25)
        inc     c                 ;{{fb22:0c}} 
        dec     c                 ;{{fb23:0d}} 
        jr      z,instr_return_A  ;{{fb24:2822}}  (+$22)

;;=instr find first loop
;Loop until we find a char which matches the first in the search string
instr_find_first_loop:            ;{{Addr=$fb26 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{fb26:f5}} 
        ld      a,b               ;{{fb27:78}} 
        cp      c                 ;{{fb28:b9}} 
        jr      c,instr_pop_and_return_zero;{{fb29:381b}}  (+$1b)
        push    hl                ;{{fb2b:e5}} Save current position in case this is only partial match
        push    de                ;{{fb2c:d5}} 
        push    bc                ;{{fb2d:c5}} 

;;=instr match loop
;Loop while chars match
instr_match_loop:                 ;{{Addr=$fb2e Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(de)            ;{{fb2e:1a}} 
        cp      (hl)              ;{{fb2f:be}} 
        jr      nz,instr_chars_differ;{{fb30:200b}}  (+$0b)
        inc     hl                ;{{fb32:23}} 
        inc     de                ;{{fb33:13}} 
        dec     c                 ;{{fb34:0d}} 
        jr      nz,instr_match_loop;{{fb35:20f7}}  (-$09)

        pop     bc                ;{{fb37:c1}} 
        pop     de                ;{{fb38:d1}} 
        pop     hl                ;{{fb39:e1}} 
        pop     af                ;{{fb3a:f1}} 
        jr      instr_return_A    ;{{fb3b:180b}}  (+$0b)

;;=instr chars differ
;Pick up from position after where the first char did match
instr_chars_differ:               ;{{Addr=$fb3d Code Calls/jump count: 1 Data use count: 0}}
        pop     bc                ;{{fb3d:c1}} 
        pop     de                ;{{fb3e:d1}} 
        pop     hl                ;{{fb3f:e1}} 
        pop     af                ;{{fb40:f1}} 
        inc     a                 ;{{fb41:3c}} 
        inc     hl                ;{{fb42:23}} 
        dec     b                 ;{{fb43:05}} 
        jr      instr_find_first_loop;{{fb44:18e0}}  (-$20)

;;=instr pop and return zero
instr_pop_and_return_zero:        ;{{Addr=$fb46 Code Calls/jump count: 1 Data use count: 0}}
        pop     af                ;{{fb46:f1}} 
;;=instr return zero
instr_return_zero:                ;{{Addr=$fb47 Code Calls/jump count: 1 Data use count: 0}}
        xor     a                 ;{{fb47:af}} 
;;=instr return A
instr_return_A:                   ;{{Addr=$fb48 Code Calls/jump count: 2 Data use count: 0}}
        call    store_A_in_accumulator_as_INT;{{fb48:cd32ff}} 
        pop     hl                ;{{fb4b:e1}} 
        ret                       ;{{fb4c:c9}} 




