;;<< FILE HANDLING
;;< RUN, LOAD, CHAIN, MERGE, SAVE
;;==========================================================================
;; command RUN

command_RUN:                      ;{{Addr=$ea78 Code Calls/jump count: 0 Data use count: 1}}
        call    is_next_02        ;{{ea78:cd3dde}} 
        ld      de,(address_of_end_of_ROM_lower_reserved_are);{{ea7b:ed5b64ae}} 
        jr      c,_command_run_15 ;{{ea7f:381d}}  (+$1d)
        cp      $1e               ;{{ea81:fe1e}}  16-bit line number
        jr      z,_command_run_13 ;{{ea83:2815}}  (+$15)
        cp      $1d               ;{{ea85:fe1d}} 
        jr      z,_command_run_13 ;{{ea87:2811}}  (+$11)
        call    LOAD_read_parameters;{{ea89:cdd1ea}} 
        ld      hl,RUN_a_program_after_loading;{{ea8c:21f1ea}} ##LABEL##
        jp      nc,MC_BOOT_PROGRAM;{{ea8f:d213bd}}  firmware function: mc boot program

        call    validate_and_LOAD_BASIC;{{ea92:cd6dec}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ea95:2a64ae}} 
        jr      _command_run_21   ;{{ea98:1812}}  (+$12)


_command_run_13:                  ;{{Addr=$ea9a Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_convert_line_number_to_line_address;{{ea9a:cd27e8}} 
        ret     nz                ;{{ea9d:c0}} 
_command_run_15:                  ;{{Addr=$ea9e Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ea9e:d5}} 
        call    close_input_and_output_streams;{{ea9f:cd00d3}}  close input and output streams
        call    _reset_basic_22   ;{{eaa2:cd78c1}} 
        call    _reset_basic_33   ;{{eaa5:cd8fc1}} 
        call    _reset_basic_14   ;{{eaa8:cd62c1}} 
        pop     hl                ;{{eaab:e1}} 
_command_run_21:                  ;{{Addr=$eaac Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{eaac:e3}} 
        call    GRA_DEFAULT       ;{{eaad:cd43bd}} 
        pop     hl                ;{{eab0:e1}} 
        inc     hl                ;{{eab1:23}} 
        jp      execute_end_of_line;{{eab2:c377de}} 

;;========================================================================
;; command LOAD

command_LOAD:                     ;{{Addr=$eab5 Code Calls/jump count: 0 Data use count: 1}}
        call    LOAD_read_parameters;{{eab5:cdd1ea}} 
        jr      nc,do_LOAD_binary ;{{eab8:3006}}  (+$06)
        call    validate_and_LOAD_BASIC;{{eaba:cd6dec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eabd:c358c0}} 

;;=do LOAD binary
do_LOAD_binary:                   ;{{Addr=$eac0 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{eac0:e5}} 
        call    _raise_memory_full_error_1;{{eac1:cdabf5}} 
        ld      hl,(address_to_load_cassette_file_to);{{eac4:2a26ae}} 
        call    CAS_IN_DIRECT     ;{{eac7:cd83bc}}  firmware function: cas in direct
        jp      z,raise_file_not_open_error_C;{{eaca:ca37cc}} 
        pop     hl                ;{{eacd:e1}} 
        jp      command_CLOSEIN   ;{{eace:c3edd2}}  CLOSEIN

;;=LOAD read parameters
LOAD_read_parameters:             ;{{Addr=$ead1 Code Calls/jump count: 2 Data use count: 0}}
        call    read_filename_and_open_for_input;{{ead1:cd54ec}} 
        and     $0e               ;{{ead4:e60e}} 
        xor     $02               ;{{ead6:ee02}} 
        jr      z,LOAD_read_dest_addr;{{ead8:2808}}  (+$08)
        call    syntax_error_if_not_02;{{eada:cd37de}} 
        call    _reset_basic_19   ;{{eadd:cd6fc1}} 
        scf                       ;{{eae0:37}} 
        ret                       ;{{eae1:c9}} 

;;=LOAD read dest addr
LOAD_read_dest_addr:              ;{{Addr=$eae2 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{eae2:cd41de}} 
        call    c,eval_expr_as_uint;{{eae5:dcf5ce}} 
        ld      (address_to_load_cassette_file_to),de;{{eae8:ed5326ae}} 
        call    syntax_error_if_not_02;{{eaec:cd37de}} 
        or      a                 ;{{eaef:b7}} 
        ret                       ;{{eaf0:c9}} 

;;==========================================================================
;; RUN a program after loading

RUN_a_program_after_loading:      ;{{Addr=$eaf1 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_to_load_cassette_file_to);{{eaf1:2a26ae}}  load address
        call    CAS_IN_DIRECT     ;{{eaf4:cd83bc}}  firmware function: cas in direct
        push    hl                ;{{eaf7:e5}}  execution address
        call    c,CAS_IN_CLOSE    ;{{eaf8:dc7abc}}  firmware function: cas in close
        pop     hl                ;{{eafb:e1}}  execution address passed into firmare function "mc boot program"
        ret                       ;{{eafc:c9}} 

;;==========================================================================
;; command CHAIN
command_CHAIN:                    ;{{Addr=$eafd Code Calls/jump count: 0 Data use count: 1}}
        xor     $ab               ;{{eafd:eeab}} 
        ld      (RAM_ae28),a      ;{{eaff:3228ae}} 
        call    z,get_next_token_skipping_space;{{eb02:cc2cde}}  get next token skipping space
        call    read_filename_and_open_for_input;{{eb05:cd54ec}} 
        ld      de,RESET_ENTRY    ;{{eb08:110000}} 
        call    next_token_if_prev_is_comma;{{eb0b:cd41de}} 
        jr      nc,_command_chain_10;{{eb0e:3006}}  (+$06)
        ld      a,(hl)            ;{{eb10:7e}} 
        cp      $2c               ;{{eb11:fe2c}} 
        call    nz,eval_expr_as_uint;{{eb13:c4f5ce}} 
_command_chain_10:                ;{{Addr=$eb16 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{eb16:d5}} 
        call    next_token_if_prev_is_comma;{{eb17:cd41de}} 
        jr      nc,_command_chain_17;{{eb1a:3008}}  (+$08)
        call    next_token_if_equals_inline_data_byte;{{eb1c:cd25de}} 
        defb $92                  ;Inline token to test for "DELETE"
        call    do_DELETE_find_first_line;{{eb20:cd00e8}} 
        scf                       ;{{eb23:37}} 
_command_chain_17:                ;{{Addr=$eb24 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{eb24:f5}} 
        call    syntax_error_if_not_02;{{eb25:cd37de}} 
        call    _function_instr_70;{{eb28:cd4dfb}} 
        call    _function_fre_6   ;{{eb2b:cd64fc}} 
        call    _zero_6_bytes_at_aded_7;{{eb2e:cd0ed6}} 
        pop     af                ;{{eb31:f1}} 
        call    c,do_DELETE_find_last_line;{{eb32:dc1ae8}} 
        call    _command_chain_34 ;{{eb35:cd47eb}} 
        pop     de                ;{{eb38:d1}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{eb39:2a64ae}} 
        ld      a,d               ;{{eb3c:7a}} 
        or      e                 ;{{eb3d:b3}} 
        ret     z                 ;{{eb3e:c8}} 

        call    zero_current_line_address;{{eb3f:cdaade}} 
        call    find_address_of_line_or_error;{{eb42:cd5ce8}} 
        dec     hl                ;{{eb45:2b}} 
        ret                       ;{{eb46:c9}} 

_command_chain_34:                ;{{Addr=$eb47 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(RAM_ae28)      ;{{eb47:3a28ae}} 
        or      a                 ;{{eb4a:b7}} 
        jp      z,validate_and_MERGE;{{eb4b:ca62ec}} 
        call    _reset_basic_31   ;{{eb4e:cd89c1}} 
        jp      validate_and_LOAD_BASIC;{{eb51:c36dec}} 

;;========================================================================
;; command MERGE

command_MERGE:                    ;{{Addr=$eb54 Code Calls/jump count: 0 Data use count: 1}}
        call    read_filename_and_open_for_input;{{eb54:cd54ec}} 
        call    syntax_error_if_not_02;{{eb57:cd37de}} 
        call    _reset_basic_22   ;{{eb5a:cd78c1}} 
        call    validate_and_MERGE;{{eb5d:cd62ec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eb60:c358c0}} 

;;========================================================================
;;do MERGE
do_MERGE:                         ;{{Addr=$eb63 Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{eb63:cd8fc1}} 
        call    convert_all_line_addresses_to_line_numbers;{{eb66:cd70e7}}  line address to line number
        call    prob_move_vars_and_arrays_to_end_of_memory;{{eb69:cd29f6}} 
        ld      hl,(address_after_end_of_program);{{eb6c:2a66ae}} 
        ex      de,hl             ;{{eb6f:eb}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{eb70:2a64ae}} 
        inc     hl                ;{{eb73:23}} 
        ld      (address_after_end_of_program),hl;{{eb74:2266ae}} 
        ex      de,hl             ;{{eb77:eb}} 
        call    BC_equal_HL_minus_DE;{{eb78:cde4ff}}  BC = HL-DE
        ex      de,hl             ;{{eb7b:eb}} 
        call    get_end_of_free_space_or_start_of_variables;{{eb7c:cd07f7}} 
        ex      de,hl             ;{{eb7f:eb}} 
        dec     hl                ;{{eb80:2b}} 
        lddr                      ;{{eb81:edb8}} 
        inc     de                ;{{eb83:13}} 
        ex      de,hl             ;{{eb84:eb}} 
_do_merge_17:                     ;{{Addr=$eb85 Code Calls/jump count: 1 Data use count: 0}}
        call    _do_merge_142     ;{{eb85:cd4bec}} 
        jr      nc,_do_merge_71   ;{{eb88:304a}}  (+$4a)
        or      e                 ;{{eb8a:b3}} 
        jr      z,_do_merge_73    ;{{eb8b:284c}}  (+$4c)
        push    de                ;{{eb8d:d5}} 
        call    _do_merge_142     ;{{eb8e:cd4bec}} 
        jr      nc,_do_merge_71   ;{{eb91:3041}}  (+$41)
_do_merge_24:                     ;{{Addr=$eb93 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{eb93:7e}} 
        inc     hl                ;{{eb94:23}} 
        or      (hl)              ;{{eb95:b6}} 
        dec     hl                ;{{eb96:2b}} 
        jr      z,_do_merge_49    ;{{eb97:281b}}  (+$1b)
        push    hl                ;{{eb99:e5}} 
        inc     hl                ;{{eb9a:23}} 
        inc     hl                ;{{eb9b:23}} 
        ld      a,(hl)            ;{{eb9c:7e}} 
        inc     hl                ;{{eb9d:23}} 
        ld      h,(hl)            ;{{eb9e:66}} 
        ld      l,a               ;{{eb9f:6f}} 
        call    compare_HL_DE     ;{{eba0:cdd8ff}}  HL=DE?
        pop     hl                ;{{eba3:e1}} 
        jr      z,_do_merge_42    ;{{eba4:2807}}  (+$07)
        jr      nc,_do_merge_49   ;{{eba6:300c}}  (+$0c)
        call    _do_merge_107     ;{{eba8:cd19ec}} 
        jr      _do_merge_24      ;{{ebab:18e6}}  (-$1a)

_do_merge_42:                     ;{{Addr=$ebad Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ebad:d5}} 
        ld      e,(hl)            ;{{ebae:5e}} 
        inc     hl                ;{{ebaf:23}} 
        ld      d,(hl)            ;{{ebb0:56}} 
        dec     hl                ;{{ebb1:2b}} 
        add     hl,de             ;{{ebb2:19}} 
        pop     de                ;{{ebb3:d1}} 
_do_merge_49:                     ;{{Addr=$ebb4 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ebb4:e5}} 
        ld      hl,(address_after_end_of_program);{{ebb5:2a66ae}} 
        inc     hl                ;{{ebb8:23}} 
        inc     hl                ;{{ebb9:23}} 
        ld      (hl),e            ;{{ebba:73}} 
        inc     hl                ;{{ebbb:23}} 
        ld      (hl),d            ;{{ebbc:72}} 
        ld      de,$001d          ;{{ebbd:111d00}} 
        add     hl,de             ;{{ebc0:19}} 
        ex      de,hl             ;{{ebc1:eb}} 
        pop     hl                ;{{ebc2:e1}} 
        ex      (sp),hl           ;{{ebc3:e3}} 
        ex      de,hl             ;{{ebc4:eb}} 
        add     hl,de             ;{{ebc5:19}} 
        ex      de,hl             ;{{ebc6:eb}} 
        ex      (sp),hl           ;{{ebc7:e3}} 
        call    compare_HL_DE     ;{{ebc8:cdd8ff}}  HL=DE?
        jr      c,_do_merge_88    ;{{ebcb:3825}}  (+$25)
        ex      (sp),hl           ;{{ebcd:e3}} 
        call    _do_merge_119     ;{{ebce:cd2cec}} 
        pop     hl                ;{{ebd1:e1}} 
        jr      c,_do_merge_17    ;{{ebd2:38b1}}  (-$4f)
_do_merge_71:                     ;{{Addr=$ebd4 Code Calls/jump count: 2 Data use count: 0}}
        call    _do_merge_73      ;{{ebd4:cdd9eb}} 
        jr      _do_merge_102     ;{{ebd7:1836}}  (+$36)

_do_merge_73:                     ;{{Addr=$ebd9 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{ebd9:7e}} 
        inc     hl                ;{{ebda:23}} 
        or      (hl)              ;{{ebdb:b6}} 
        dec     hl                ;{{ebdc:2b}} 
        jr      z,_do_merge_80    ;{{ebdd:2805}}  (+$05)
        call    _do_merge_107     ;{{ebdf:cd19ec}} 
        jr      _do_merge_73      ;{{ebe2:18f5}}  (-$0b)

_do_merge_80:                     ;{{Addr=$ebe4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_after_end_of_program);{{ebe4:2a66ae}} 
        xor     a                 ;{{ebe7:af}} 
        ld      (hl),a            ;{{ebe8:77}} 
        inc     hl                ;{{ebe9:23}} 
        ld      (hl),a            ;{{ebea:77}} 
        inc     hl                ;{{ebeb:23}} 
        ld      (address_after_end_of_program),hl;{{ebec:2266ae}} 
        jp      _load_tokenised_23;{{ebef:c3b0ec}} 

_do_merge_88:                     ;{{Addr=$ebf2 Code Calls/jump count: 1 Data use count: 0}}
        call    _do_merge_73      ;{{ebf2:cdd9eb}} 
_do_merge_89:                     ;{{Addr=$ebf5 Code Calls/jump count: 1 Data use count: 0}}
        call    zero_current_line_address;{{ebf5:cdaade}} 
        ld      a,$07             ;{{ebf8:3e07}} 
        jr      _do_merge_103     ;{{ebfa:1815}}  (+$15)

_do_merge_92:                     ;{{Addr=$ebfc Code Calls/jump count: 3 Data use count: 0}}
        call    CAS_IN_CHAR       ;{{ebfc:cd80bc}}  firmware function: cas in char
        ret     c                 ;{{ebff:d8}} 

        cp      $1a               ;{{ec00:fe1a}} 
        scf                       ;{{ec02:37}} 
        ret     z                 ;{{ec03:c8}} 

        ld      (DERR__Disc_Error_No),a;{{ec04:3291ad}} 
        ccf                       ;{{ec07:3f}} 
        ret                       ;{{ec08:c9}} 

_do_merge_100:                    ;{{Addr=$ec09 Code Calls/jump count: 1 Data use count: 0}}
        ld      (DERR__Disc_Error_No),a;{{ec09:3291ad}} 
        call    _reset_basic_19   ;{{ec0c:cd6fc1}} 
_do_merge_102:                    ;{{Addr=$ec0f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$18             ;{{ec0f:3e18}} EOF met error
_do_merge_103:                    ;{{Addr=$ec11 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{ec11:f5}} 
        call    close_input_and_output_streams;{{ec12:cd00d3}}  close input and output streams
        pop     af                ;{{ec15:f1}} 
        jp      raise_error       ;{{ec16:c355cb}} 

_do_merge_107:                    ;{{Addr=$ec19 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{ec19:c5}} 
        push    de                ;{{ec1a:d5}} 
        ld      c,(hl)            ;{{ec1b:4e}} 
        inc     hl                ;{{ec1c:23}} 
        ld      b,(hl)            ;{{ec1d:46}} 
        dec     hl                ;{{ec1e:2b}} 
        ld      de,(address_after_end_of_program);{{ec1f:ed5b66ae}} 
        ldir                      ;{{ec23:edb0}} 
        ld      (address_after_end_of_program),de;{{ec25:ed5366ae}} 
        pop     de                ;{{ec29:d1}} 
        pop     bc                ;{{ec2a:c1}} 
        ret                       ;{{ec2b:c9}} 

_do_merge_119:                    ;{{Addr=$ec2c Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ec2c:eb}} 
        ld      hl,(address_after_end_of_program);{{ec2d:2a66ae}} 
        ld      (hl),e            ;{{ec30:73}} 
        inc     hl                ;{{ec31:23}} 
        ld      (hl),d            ;{{ec32:72}} 
        inc     hl                ;{{ec33:23}} 
        inc     hl                ;{{ec34:23}} 
        inc     hl                ;{{ec35:23}} 
        dec     de                ;{{ec36:1b}} 
        dec     de                ;{{ec37:1b}} 
        dec     de                ;{{ec38:1b}} 
_do_merge_130:                    ;{{Addr=$ec39 Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{ec39:1b}} 
        ld      a,d               ;{{ec3a:7a}} 
        or      e                 ;{{ec3b:b3}} 
        jr      z,_do_merge_139   ;{{ec3c:2808}}  (+$08)
        call    _do_merge_92      ;{{ec3e:cdfceb}} 
        ld      (hl),a            ;{{ec41:77}} 
        inc     hl                ;{{ec42:23}} 
        jr      c,_do_merge_130   ;{{ec43:38f4}}  (-$0c)
        ret                       ;{{ec45:c9}} 

_do_merge_139:                    ;{{Addr=$ec46 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_after_end_of_program),hl;{{ec46:2266ae}} 
        scf                       ;{{ec49:37}} 
        ret                       ;{{ec4a:c9}} 

_do_merge_142:                    ;{{Addr=$ec4b Code Calls/jump count: 2 Data use count: 0}}
        call    _do_merge_92      ;{{ec4b:cdfceb}} 
        ld      e,a               ;{{ec4e:5f}} 
        call    c,_do_merge_92    ;{{ec4f:dcfceb}} 
        ld      d,a               ;{{ec52:57}} 
        ret                       ;{{ec53:c9}} 

;;=read filename and open for input
read_filename_and_open_for_input: ;{{Addr=$ec54 Code Calls/jump count: 3 Data use count: 0}}
        call    close_input_and_output_streams;{{ec54:cd00d3}}  close input and output streams
        call    read_filename_and_open_in;{{ec57:cdbed2}} 
        ld      (file_type_from_cassette_header),a;{{ec5a:3229ae}} 
        ld      (file_length_from_cassette_header),bc;{{ec5d:ed432aae}} 
        ret                       ;{{ec61:c9}} 

;;=========
;;=validate and MERGE
validate_and_MERGE:               ;{{Addr=$ec62 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(file_type_from_cassette_header);{{ec62:3a29ae}} 
        or      a                 ;{{ec65:b7}} 
        jp      z,do_MERGE        ;{{ec66:ca63eb}} Type 0 = tokenised, unprotected
        cp      $16               ;{{ec69:fe16}} 
        jr      nz,raise_File_type_error;{{ec6b:200b}}  (+$0b)
;;=validate and LOAD BASIC
validate_and_LOAD_BASIC:          ;{{Addr=$ec6d Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(file_type_from_cassette_header);{{ec6d:3a29ae}} 
        cp      $16               ;{{ec70:fe16}} 
        jr      z,load_ASCII      ;{{ec72:2842}}  (+$42)
        and     $fe               ;{{ec74:e6fe}} Bit 0 set = protected
        jr      z,load_tokenised  ;{{ec76:2804}}  (+$04)
;;=raise File type error
raise_File_type_error:            ;{{Addr=$ec78 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{ec78:cd45cb}} 
        defb $19                  ;Inline error code: File type error

;;===
;;=load tokenised
load_tokenised:                   ;{{Addr=$ec7c Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{ec7c:cd8fc1}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ec7f:cd29f6}} 
        ld      bc,(address_of_end_of_ROM_lower_reserved_are);{{ec82:ed4b64ae}} 
        inc     bc                ;{{ec86:03}} 
        call    get_end_of_free_space_or_start_of_variables;{{ec87:cd07f7}} 
        ld      de,$ff80          ;{{ec8a:1180ff}} ##LIT##;WARNING: Code area used as literal
        add     hl,de             ;{{ec8d:19}} 
        or      a                 ;{{ec8e:b7}} 
        sbc     hl,bc             ;{{ec8f:ed42}} 
        ld      de,(file_length_from_cassette_header);{{ec91:ed5b2aae}} 
        call    nc,compare_HL_DE  ;{{ec95:d4d8ff}}  HL=DE?
        jp      c,_do_merge_89    ;{{ec98:daf5eb}} 
        ex      de,hl             ;{{ec9b:eb}} 
        add     hl,bc             ;{{ec9c:09}} 
        ld      (address_after_end_of_program),hl;{{ec9d:2266ae}} 
        ld      a,(file_type_from_cassette_header);{{eca0:3a29ae}} 
        rra                       ;{{eca3:1f}} 
        sbc     a,a               ;{{eca4:9f}} 
        ld      (program_protection_flag_),a;{{eca5:322cae}} 
        ld      h,b               ;{{eca8:60}} 
        ld      l,c               ;{{eca9:69}} 
        call    CAS_IN_DIRECT     ;{{ecaa:cd83bc}}  firmware function: CAS IN DIRECT
        jp      z,_do_merge_100   ;{{ecad:ca09ec}} 
_load_tokenised_23:               ;{{Addr=$ecb0 Code Calls/jump count: 2 Data use count: 0}}
        call    prob_move_vars_and_arrays_back_from_end_of_memory;{{ecb0:cd3cf6}} 
        jp      command_CLOSEIN   ;{{ecb3:c3edd2}}  CLOSEIN

;;=load ASCII
load_ASCII:                       ;{{Addr=$ecb6 Code Calls/jump count: 1 Data use count: 0}}
        call    _reset_basic_33   ;{{ecb6:cd8fc1}} 
        call    zero_current_line_address;{{ecb9:cdaade}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ecbc:cd29f6}} 
_load_ascii_3:                    ;{{Addr=$ecbf Code Calls/jump count: 1 Data use count: 0}}
        call    read_line_from_cassette_or_disc;{{ecbf:cd0acb}} 
        jr      nc,_load_tokenised_23;{{ecc2:30ec}}  (-$14)
        call    skip_space_tab_or_line_feed;{{ecc4:cd4dde}}  skip space, lf or tab
        or      a                 ;{{ecc7:b7}} 
        call    nz,_load_ascii_9  ;{{ecc8:c4cdec}} 
        jr      _load_ascii_3     ;{{eccb:18f2}}  (-$0e)

_load_ascii_9:                    ;{{Addr=$eccd Code Calls/jump count: 1 Data use count: 0}}
        call    convert_number_a  ;{{eccd:cdcfee}} 
        jp      c,_convert_line_addresses_to_line_numbers_24;{{ecd0:daa5e7}} 
        ld      a,$15             ;{{ecd3:3e15}} 
        jr      z,_load_ascii_14  ;{{ecd5:2802}}  (+$02)
        ld      a,$06             ;{{ecd7:3e06}} Overflow error
_load_ascii_14:                   ;{{Addr=$ecd9 Code Calls/jump count: 1 Data use count: 0}}
        jp      raise_error       ;{{ecd9:c355cb}} 

;;========================================================================
;; command SAVE

command_SAVE:                     ;{{Addr=$ecdc Code Calls/jump count: 0 Data use count: 1}}
        call    close_input_and_output_streams;{{ecdc:cd00d3}} ; close input and output streams
        call    command_OPENOUT   ;{{ecdf:cda8d2}} ; OPENOUT
        ld      b,$00             ;{{ece2:0600}} 
        call    next_token_if_prev_is_comma;{{ece4:cd41de}} 
        jr      nc,save_BASIC_normal;{{ece7:3025}}  (+$25)
        call    next_token_if_equals_inline_data_byte;{{ece9:cd25de}}  read string
        defb $0d                  ;inline token to test CR
        inc     hl                ;{{eced:23}} 
        inc     hl                ;{{ecee:23}} 
        ld      a,(hl)            ;{{ecef:7e}}  parameter (,A ,B ,P)
        and     $df               ;{{ecf0:e6df}} 
        jp      p,Error_Syntax_Error;{{ecf2:f249cb}}  Error: Syntax Error
        push    hl                ;{{ecf5:e5}} 
        ld      hl,save_parameters_list;{{ecf6:2100ed}} 
        call    get_address_from_table;{{ecf9:cdb4ff}} 
        ex      (sp),hl           ;{{ecfc:e3}} 
        jp      get_next_token_skipping_space;{{ecfd:c32cde}}  get next token skipping space

;;=save parameters list
save_parameters_list:             ;{{Addr=$ed00 Data Calls/jump count: 0 Data use count: 1}}
        defb $03                  ;Number of parameter options
        defw Error_Syntax_Error   ; Error if not found: Syntax Error   ##LABEL##

        defb $c1                  ; ,A
        defw ASCII_save           ;  ##LABEL##
        defb $c2                  ; ,B
        defw Binary_save          ;  ##LABEL##
        defb $d0                  ; ,P
        defw Protected_BASIC_save ;  ##LABEL##

;;---------------------------------------------------
;; SAVE ,P
;;=Protected BASIC save
Protected_BASIC_save:             ;{{Addr=$ed0c Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$01             ;{{ed0c:0601}} 
;;=save BASIC normal
save_BASIC_normal:                ;{{Addr=$ed0e Code Calls/jump count: 1 Data use count: 0}}
        call    syntax_error_if_not_02;{{ed0e:cd37de}} 
        push hl                   ;{{ed11:e5}} 
        push    bc                ;{{ed12:c5}} 
        call    convert_all_line_addresses_to_line_numbers;{{ed13:cd70e7}}  line address to line number
        call    prob_reset_links_to_variables_data;{{ed16:cd4dea}} 
;; save basic?
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ed19:2a64ae}} 
        inc     hl                ;{{ed1c:23}} 
        ex      de,hl             ;{{ed1d:eb}} 
        ld      hl,(address_after_end_of_program);{{ed1e:2a66ae}} 
        or      a                 ;{{ed21:b7}} 
        sbc     hl,de             ;{{ed22:ed52}} 
        ex      de,hl             ;{{ed24:eb}} 
        pop     af                ;{{ed25:f1}} 
        ld      bc,RESET_ENTRY    ;{{ed26:010000}} 
        jr      _binary_save_15   ;{{ed29:1820}}  (+$20)

;; SAVE ,B
;;=Binary save
Binary_save:                      ;{{Addr=$ed2b Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_comma;{{ed2b:cd15de}}  check for comma			; start
        call    eval_expr_as_uint ;{{ed2e:cdf5ce}} 
        push    de                ;{{ed31:d5}} 
        call    next_token_if_comma;{{ed32:cd15de}}  check for comma			; length
        call    eval_expr_as_uint ;{{ed35:cdf5ce}} 
        push    de                ;{{ed38:d5}} 
        call    next_token_if_prev_is_comma;{{ed39:cd41de}}  execution
        ld      de,RESET_ENTRY    ;{{ed3c:110000}} 
        call    c,eval_expr_as_uint;{{ed3f:dcf5ce}} 
        push    de                ;{{ed42:d5}} 
        call    syntax_error_if_not_02;{{ed43:cd37de}} 
        ld      a,$02             ;{{ed46:3e02}} ; binary
        pop     bc                ;{{ed48:c1}} 
        pop     de                ;{{ed49:d1}} 
        ex      (sp),hl           ;{{ed4a:e3}} 
_binary_save_15:                  ;{{Addr=$ed4b Code Calls/jump count: 1 Data use count: 0}}
        call    CAS_OUT_DIRECT    ;{{ed4b:cd98bc}} ; firmware function: cas out direct
        jp      nc,raise_file_not_open_error_C;{{ed4e:d237cc}} 
        jr      _ascii_save_10    ;{{ed51:1817}}  (+$17)

;; SAVE ,A
;;=ASCII save
ASCII_save:                       ;{{Addr=$ed53 Code Calls/jump count: 0 Data use count: 1}}
        call    syntax_error_if_not_02;{{ed53:cd37de}} 
        push    hl                ;{{ed56:e5}} 
        ld      a,$09             ;{{ed57:3e09}} 
        call    select_txt_stream ;{{ed59:cda6c1}} 
        push    af                ;{{ed5c:f5}} 
        ld      bc,$0001          ;{{ed5d:010100}} starting line number
        ld      de,$ffff          ;{{ed60:11ffff}} ending line number ##LIT##;WARNING: Code area used as literal
        call    do_LIST           ;{{ed63:cde3e1}} 
        pop     af                ;{{ed66:f1}} 
        call    select_txt_stream ;{{ed67:cda6c1}} 
_ascii_save_10:                   ;{{Addr=$ed6a Code Calls/jump count: 1 Data use count: 0}}
        call    command_CLOSEOUT  ;{{ed6a:cdf5d2}}  CLOSEOUT
        pop     hl                ;{{ed6d:e1}} 
        ret                       ;{{ed6e:c9}} 





