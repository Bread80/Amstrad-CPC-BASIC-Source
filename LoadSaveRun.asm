;;<< FILE HANDLING
;;< RUN, LOAD, CHAIN, MERGE, SAVE
;;==========================================================================
;; command RUN
;RUN <filename>
;Loads and runs a file

;RUN [<line number>]
;Runs the current program from the specified line number

command_RUN:                      ;{{Addr=$ea78 Code Calls/jump count: 0 Data use count: 1}}
        call    is_next_02        ;{{ea78:cd3dde}} 
        ld      de,(address_of_end_of_ROM_lower_reserved_are);{{ea7b:ed5b64ae}} 
        jr      c,RUN_from_line_number;{{ea7f:381d}}  (+$1d) No parameters
        cp      $1e               ;{{ea81:fe1e}}  16-bit line number
        jr      z,RUN_from_line_ptr;{{ea83:2815}}  (+$15)
        cp      $1d               ;{{ea85:fe1d}} Line pointer
        jr      z,RUN_from_line_ptr;{{ea87:2811}}  (+$11)

        call    eval_filename_and_open_for_input;{{ea89:cdd1ea}} Otherwise we're running a file
        ld      hl,callback_to_load_a_binary;{{ea8c:21f1ea}} If machine code program, call if via a firmware reset ###LABEL##
        jp      nc,MC_BOOT_PROGRAM;{{ea8f:d213bd}}  firmware function: mc boot program

        call    validate_and_LOAD_BASIC;{{ea92:cd6dec}} Load BASIC program...
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ea95:2a64ae}} ...get execution address...
        jr      RUN_from_HL       ;{{ea98:1812}}  (+$12) ...and RUN it


;;=RUN from line ptr
RUN_from_line_ptr:                ;{{Addr=$ea9a Code Calls/jump count: 2 Data use count: 0}}
        call    eval_and_convert_line_number_to_line_address;{{ea9a:cd27e8}} 
        ret     nz                ;{{ea9d:c0}} 
;;=RUN from line number
RUN_from_line_number:             ;{{Addr=$ea9e Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ea9e:d5}} 
        call    close_input_and_output_streams;{{ea9f:cd00d3}}  close input and output streams
        call    reset_variable_data;{{eaa2:cd78c1}} 
        call    reset_exec_data   ;{{eaa5:cd8fc1}} 
        call    reset_angle_mode_string_stack_and_fn_params;{{eaa8:cd62c1}} 
        pop     hl                ;{{eaab:e1}} 
;;=RUN from HL
RUN_from_HL:                      ;{{Addr=$eaac Code Calls/jump count: 1 Data use count: 0}}
        ex      (sp),hl           ;{{eaac:e3}} 
        call    GRA_DEFAULT       ;{{eaad:cd43bd}} 
        pop     hl                ;{{eab0:e1}} 
        inc     hl                ;{{eab1:23}} 
        jp      execute_line_atHL ;{{eab2:c377de}} 

;;========================================================================
;; command LOAD
;LOAD <filename>[,<address expression>]
;Loads the given file. If the file is binary, it will be loaded to memory at the 
;address is was written from unless address expression is given.
;If the file name is empty, loads the first file found on cassette
;If the first character of filename is ! it is removed and any messages suppressed.
;Binary files can only be loaded outside the BASIC program area - i.e above HIMEM

command_LOAD:                     ;{{Addr=$eab5 Code Calls/jump count: 0 Data use count: 1}}
        call    eval_filename_and_open_for_input;{{eab5:cdd1ea}} 
        jr      nc,do_LOAD_binary ;{{eab8:3006}}  (+$06)
        call    validate_and_LOAD_BASIC;{{eaba:cd6dec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eabd:c358c0}} 

;;=do LOAD binary
do_LOAD_binary:                   ;{{Addr=$eac0 Code Calls/jump count: 1 Data use count: 0}}
        push    hl                ;{{eac0:e5}} 
        call    prepare_memory_for_loading_binary;{{eac1:cdabf5}} 
        ld      hl,(address_to_load_binary_file_to);{{eac4:2a26ae}} 
        call    CAS_IN_DIRECT     ;{{eac7:cd83bc}}  firmware function: cas in direct
        jp      z,raise_file_not_open_error_C;{{eaca:ca37cc}} 
        pop     hl                ;{{eacd:e1}} 
        jp      command_CLOSEIN   ;{{eace:c3edd2}}  CLOSEIN

;;--------------------------------------------
;;=eval filename and open for input
eval_filename_and_open_for_input: ;{{Addr=$ead1 Code Calls/jump count: 2 Data use count: 0}}
        call    read_filename_and_open_for_input;{{ead1:cd54ec}} 
        and     $0e               ;{{ead4:e60e}} 
        xor     $02               ;{{ead6:ee02}} 
        jr      z,eval_binary_file_load_addr;{{ead8:2808}}  (+$08)
        call    error_if_not_end_of_statement_or_eoln;{{eada:cd37de}} 
        call    clear_program_and_variables_etc;{{eadd:cd6fc1}} 
        scf                       ;{{eae0:37}} 
        ret                       ;{{eae1:c9}} 

;;=eval binary file load addr
eval_binary_file_load_addr:       ;{{Addr=$eae2 Code Calls/jump count: 1 Data use count: 0}}
        call    next_token_if_prev_is_comma;{{eae2:cd41de}} If we have another parameter...
        call    c,eval_expr_as_uint;{{eae5:dcf5ce}} ...then it's the binary file load address. (If not retain the value from the file header)
        ld      (address_to_load_binary_file_to),de;{{eae8:ed5326ae}} 
        call    error_if_not_end_of_statement_or_eoln;{{eaec:cd37de}} 
        or      a                 ;{{eaef:b7}} 
        ret                       ;{{eaf0:c9}} 

;;==========================================================================
;;=callback to load a binary
;Called from MC_BOOT_PROGRAM when running a binary

callback_to_load_a_binary:        ;{{Addr=$eaf1 Code Calls/jump count: 0 Data use count: 1}}
        ld      hl,(address_to_load_binary_file_to);{{eaf1:2a26ae}}  load address
        call    CAS_IN_DIRECT     ;{{eaf4:cd83bc}}  firmware function: cas in direct
        push    hl                ;{{eaf7:e5}}  execution address
        call    c,CAS_IN_CLOSE    ;{{eaf8:dc7abc}}  firmware function: cas in close
        pop     hl                ;{{eafb:e1}}  execution address passed into firmare function "mc boot program"
        ret                       ;{{eafc:c9}} 

;;==========================================================================
;; command CHAIN
;CHAIN <filename>[,<line number expression>]
;CHAIN MERGE <filename>[,[<line number expression>][,DELETE <line number range>]]
;Load and runs the given file, starting at the given line number, and retaining all current variables.
;If no line number is given execution starts at the first line.
;CHAIN deletes the current program and runs the new one
;CHAIN MERGE merges the new program with the existing one, optionally deleting 
;any lines in the current program within the specified range.

command_CHAIN:                    ;{{Addr=$eafd Code Calls/jump count: 0 Data use count: 1}}
        xor     $ab               ;{{eafd:eeab}} Token for MERGE, e.e CHAIN MERGE. Not sure how we get here though.
        ld      (CHAIN_MERGE_flag),a;{{eaff:3228ae}} $00=(CHAIN) MERGE, other = CHAIN?
        call    z,get_next_token_skipping_space;{{eb02:cc2cde}}  step over MERGE token?

        call    read_filename_and_open_for_input;{{eb05:cd54ec}} 

        ld      de,$0000          ;{{eb08:110000}} DE=default line number ###LIT###
        call    next_token_if_prev_is_comma;{{eb0b:cd41de}} 
        jr      nc,_command_chain_10;{{eb0e:3006}}  (+$06) No parameter
        ld      a,(hl)            ;{{eb10:7e}} If parameter is blank use default
        cp      $2c               ;{{eb11:fe2c}} ","
        call    nz,eval_expr_as_uint;{{eb13:c4f5ce}} Otherwise read line number

_command_chain_10:                ;{{Addr=$eb16 Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{eb16:d5}} 
        call    next_token_if_prev_is_comma;{{eb17:cd41de}} 
        jr      nc,_command_chain_17;{{eb1a:3008}}  (+$08) No more parameters

        call    next_token_if_equals_inline_data_byte;{{eb1c:cd25de}} Next parameter must start with DELETE
        defb $92                  ;Inline token to test for "DELETE"
        call    do_DELETE_find_byte_range;{{eb20:cd00e8}} DELETE specified line number range
        scf                       ;{{eb23:37}} 

;Parameters read, now do the CHAIN (MERGE)
_command_chain_17:                ;{{Addr=$eb24 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{eb24:f5}} 
;Do some memory clean-up
        call    error_if_not_end_of_statement_or_eoln;{{eb25:cd37de}} 
        call    copy_all_strings_vars_to_strings_area_if_not_in_strings_area;{{eb28:cd4dfb}} 
        call    strings_area_garbage_collection;{{eb2b:cd64fc}} 
        call    clear_DEFFN_list_and_reset_variable_types_and_pointers;{{eb2e:cd0ed6}} 
        pop     af                ;{{eb31:f1}} 

        call    c,do_DELETE_delete_lines;{{eb32:dc1ae8}} DELETE line range

        call    do_CHAIN_and_CHAIN_MERGE_load;{{eb35:cd47eb}} Load and (if needed) MERGE the file

        pop     de                ;{{eb38:d1}} 
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{eb39:2a64ae}} Execution address...
        ld      a,d               ;{{eb3c:7a}} 
        or      e                 ;{{eb3d:b3}} 
        ret     z                 ;{{eb3e:c8}} if running from start of program

        call    zero_current_line_address;{{eb3f:cdaade}} otherwise continue from where we left off...
        call    find_line_or_error;{{eb42:cd5ce8}} ...after verifying the line still exists
        dec     hl                ;{{eb45:2b}} 
        ret                       ;{{eb46:c9}} 

;;=do CHAIN and CHAIN MERGE load
do_CHAIN_and_CHAIN_MERGE_load:    ;{{Addr=$eb47 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(CHAIN_MERGE_flag);{{eb47:3a28ae}} 
        or      a                 ;{{eb4a:b7}} 
        jp      z,validate_and_MERGE;{{eb4b:ca62ec}} 
        call    reset_zone_and_clear_program;{{eb4e:cd89c1}} 
        jp      validate_and_LOAD_BASIC;{{eb51:c36dec}} 

;;========================================================================
;; command MERGE
;MERGE <filename>
;Merges a second program with the current one

command_MERGE:                    ;{{Addr=$eb54 Code Calls/jump count: 0 Data use count: 1}}
        call    read_filename_and_open_for_input;{{eb54:cd54ec}} 
        call    error_if_not_end_of_statement_or_eoln;{{eb57:cd37de}} 
        call    reset_variable_data;{{eb5a:cd78c1}} 
        call    validate_and_MERGE;{{eb5d:cd62ec}} 
        jp      REPL_Read_Eval_Print_Loop;{{eb60:c358c0}} 

;;========================================================================
;;do MERGE
;The entire program is moved to the end of memory,
;During merge lines will be moved down or read into the bottom of
;memory after any lines already merged.
;As the file is read line numbers are compared,
;file line number < memory line number: insert file line
;file line number > memory line number: move memory line down
;file line number = memory line number: insert file line, skip over memory line
do_MERGE:                         ;{{Addr=$eb63 Code Calls/jump count: 1 Data use count: 0}}
        call    reset_exec_data   ;{{eb63:cd8fc1}} 
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
        call    get_end_of_free_space;{{eb7c:cd07f7}} 
        ex      de,hl             ;{{eb7f:eb}} 
        dec     hl                ;{{eb80:2b}} 
        lddr                      ;{{eb81:edb8}} 
        inc     de                ;{{eb83:13}} 
        ex      de,hl             ;{{eb84:eb}} 

;;=merge file line loop
;Loop for each line in file
merge_file_line_loop:             ;{{Addr=$eb85 Code Calls/jump count: 1 Data use count: 0}}
        call    merge_read_word_to_DE;{{eb85:cd4bec}} Read file line length
        jr      nc,merge_file_error;{{eb88:304a}}  (+$4a)
        or      e                 ;{{eb8a:b3}} 
        jr      z,merge_error_cleanup;{{eb8b:284c}}  (+$4c) Line length = 0? EOF?
        push    de                ;{{eb8d:d5}} 

        call    merge_read_word_to_DE;{{eb8e:cd4bec}} Read file line number
        jr      nc,merge_file_error;{{eb91:3041}}  (+$41)

;;=merge move memory lines loop
;Loop over lines in memory moving each down in turn until we find a 
;line to insert or replace
merge_move_memory_lines_loop:     ;{{Addr=$eb93 Code Calls/jump count: 1 Data use count: 0}}
        ld      a,(hl)            ;{{eb93:7e}} Memory line length zero = end of program
        inc     hl                ;{{eb94:23}} 
        or      (hl)              ;{{eb95:b6}} 
        dec     hl                ;{{eb96:2b}} 
        jr      z,merge_insert_line;{{eb97:281b}}  (+$1b)
        push    hl                ;{{eb99:e5}} 
        inc     hl                ;{{eb9a:23}} 
        inc     hl                ;{{eb9b:23}} 
        ld      a,(hl)            ;{{eb9c:7e}} HL=memory line number
        inc     hl                ;{{eb9d:23}} 
        ld      h,(hl)            ;{{eb9e:66}} 
        ld      l,a               ;{{eb9f:6f}} 
        call    compare_HL_DE     ;{{eba0:cdd8ff}}  HL=DE? Compare file line number to memory line number
        pop     hl                ;{{eba3:e1}} 
        jr      z,merge_replace_line;{{eba4:2807}}  (+$07)
        jr      nc,merge_insert_line;{{eba6:300c}}  (+$0c)
        call    merge_move_line   ;{{eba8:cd19ec}} 
        jr      merge_move_memory_lines_loop;{{ebab:18e6}}  (-$1a)

;;=merge replace line
;Found a line with the same number so overwrite it
merge_replace_line:               ;{{Addr=$ebad Code Calls/jump count: 1 Data use count: 0}}
        push    de                ;{{ebad:d5}} 
        ld      e,(hl)            ;{{ebae:5e}} DE=memory line length
        inc     hl                ;{{ebaf:23}} 
        ld      d,(hl)            ;{{ebb0:56}} 
        dec     hl                ;{{ebb1:2b}} 
        add     hl,de             ;{{ebb2:19}} Add length to current pointer - i.e. addr of next line
        pop     de                ;{{ebb3:d1}} 
;;=merge insert line
merge_insert_line:                ;{{Addr=$ebb4 Code Calls/jump count: 2 Data use count: 0}}
        push    hl                ;{{ebb4:e5}} 
        ld      hl,(address_after_end_of_program);{{ebb5:2a66ae}} HL=addr to write to
        inc     hl                ;{{ebb8:23}} 
        inc     hl                ;{{ebb9:23}} 
        ld      (hl),e            ;{{ebba:73}} Write file line number
        inc     hl                ;{{ebbb:23}} 
        ld      (hl),d            ;{{ebbc:72}} 
        ld      de,$001d          ;{{ebbd:111d00}} 
        add     hl,de             ;{{ebc0:19}} HL=curr + 1d
        ex      de,hl             ;{{ebc1:eb}} DE=curr + 1d
        pop     hl                ;{{ebc2:e1}} HL=memory curr
        ex      (sp),hl           ;{{ebc3:e3}} TOS=memory curr, HL=mem line length
        ex      de,hl             ;{{ebc4:eb}} DE=mem line length, HL=curr + 1d
        add     hl,de             ;{{ebc5:19}} HL=curr + mem line length + 1d
        ex      de,hl             ;{{ebc6:eb}} DE=curr + mem line length + 1d, HL=mem line length
        ex      (sp),hl           ;{{ebc7:e3}} TOS=mem line length, HL=memory curr
        call    compare_HL_DE     ;{{ebc8:cdd8ff}}  HL=DE? Is new end-of-line > start of memory line at top of memory
        jr      c,merge_out_of_memory;{{ebcb:3825}}  (+$25) If so we're out of memory
        ex      (sp),hl           ;{{ebcd:e3}} TOS=memory curr, HL=mem line length
        call    merge_do_read_line;{{ebce:cd2cec}} 
        pop     hl                ;{{ebd1:e1}} 
        jr      c,merge_file_line_loop;{{ebd2:38b1}}  (-$4f) Loop if no errors

;;=merge file error
merge_file_error:                 ;{{Addr=$ebd4 Code Calls/jump count: 2 Data use count: 0}}
        call    merge_error_cleanup;{{ebd4:cdd9eb}} 
        jr      raise_EOF_error   ;{{ebd7:1836}}  (+$36)

;;=merge error cleanup
;Move remaining lines down in memory
merge_error_cleanup:              ;{{Addr=$ebd9 Code Calls/jump count: 4 Data use count: 0}}
        ld      a,(hl)            ;{{ebd9:7e}} Test for end of program
        inc     hl                ;{{ebda:23}} 
        or      (hl)              ;{{ebdb:b6}} 
        dec     hl                ;{{ebdc:2b}} 
        jr      z,_merge_error_cleanup_7;{{ebdd:2805}}  (+$05)
        call    merge_move_line   ;{{ebdf:cd19ec}} 
        jr      merge_error_cleanup;{{ebe2:18f5}}  (-$0b)

_merge_error_cleanup_7:           ;{{Addr=$ebe4 Code Calls/jump count: 1 Data use count: 0}}
        ld      hl,(address_after_end_of_program);{{ebe4:2a66ae}} 
        xor     a                 ;{{ebe7:af}} 
        ld      (hl),a            ;{{ebe8:77}} Write end of program marker
        inc     hl                ;{{ebe9:23}} 
        ld      (hl),a            ;{{ebea:77}} 
        inc     hl                ;{{ebeb:23}} 
        ld      (address_after_end_of_program),hl;{{ebec:2266ae}} 
        jp      move_vars_and_arrays_down_and_close_input_file;{{ebef:c3b0ec}} 

;;=merge out of memory
merge_out_of_memory:              ;{{Addr=$ebf2 Code Calls/jump count: 1 Data use count: 0}}
        call    merge_error_cleanup;{{ebf2:cdd9eb}} 
_merge_out_of_memory_1:           ;{{Addr=$ebf5 Code Calls/jump count: 1 Data use count: 0}}
        call    zero_current_line_address;{{ebf5:cdaade}} 
        ld      a,$07             ;{{ebf8:3e07}} Memory full error
        jr      raise_error_B     ;{{ebfa:1815}}  (+$15)

;;=merge read char
;Returns carry true if no error
merge_read_char:                  ;{{Addr=$ebfc Code Calls/jump count: 3 Data use count: 0}}
        call    CAS_IN_CHAR       ;{{ebfc:cd80bc}}  firmware function: cas in char
        ret     c                 ;{{ebff:d8}} 

        cp      $1a               ;{{ec00:fe1a}} Disc error: CP/M end of file
        scf                       ;{{ec02:37}} 
        ret     z                 ;{{ec03:c8}} 

        ld      (DERR__Disc_Error_No),a;{{ec04:3291ad}} 
        ccf                       ;{{ec07:3f}} 
        ret                       ;{{ec08:c9}} 

;;=raise disc error
raise_disc_error:                 ;{{Addr=$ec09 Code Calls/jump count: 1 Data use count: 0}}
        ld      (DERR__Disc_Error_No),a;{{ec09:3291ad}} 
        call    clear_program_and_variables_etc;{{ec0c:cd6fc1}} 
;;=raise EOF error
raise_EOF_error:                  ;{{Addr=$ec0f Code Calls/jump count: 1 Data use count: 0}}
        ld      a,$18             ;{{ec0f:3e18}} EOF met error
;;=raise error
;Error code in A
raise_error_B:                    ;{{Addr=$ec11 Code Calls/jump count: 1 Data use count: 0}}
        push    af                ;{{ec11:f5}} 
        call    close_input_and_output_streams;{{ec12:cd00d3}}  close input and output streams
        pop     af                ;{{ec15:f1}} 
        jp      raise_error       ;{{ec16:c355cb}} 

;;=merge move line
;Move memory line to end of merged program
merge_move_line:                  ;{{Addr=$ec19 Code Calls/jump count: 2 Data use count: 0}}
        push    bc                ;{{ec19:c5}} 
        push    de                ;{{ec1a:d5}} 
        ld      c,(hl)            ;{{ec1b:4e}} BC=line length
        inc     hl                ;{{ec1c:23}} 
        ld      b,(hl)            ;{{ec1d:46}} 
        dec     hl                ;{{ec1e:2b}} 
        ld      de,(address_after_end_of_program);{{ec1f:ed5b66ae}} 
        ldir                      ;{{ec23:edb0}} Move line
        ld      (address_after_end_of_program),de;{{ec25:ed5366ae}} 
        pop     de                ;{{ec29:d1}} 
        pop     bc                ;{{ec2a:c1}} 
        ret                       ;{{ec2b:c9}} 

;;=merge do read line
;Line number has already been written by merg_insert_line
merge_do_read_line:               ;{{Addr=$ec2c Code Calls/jump count: 1 Data use count: 0}}
        ex      de,hl             ;{{ec2c:eb}} DE=mem line length
        ld      hl,(address_after_end_of_program);{{ec2d:2a66ae}} 
        ld      (hl),e            ;{{ec30:73}} Write line length
        inc     hl                ;{{ec31:23}} 
        ld      (hl),d            ;{{ec32:72}} 
        inc     hl                ;{{ec33:23}} 
        inc     hl                ;{{ec34:23}} 
        inc     hl                ;{{ec35:23}} HL=write addr addr
        dec     de                ;{{ec36:1b}} 
        dec     de                ;{{ec37:1b}} 
        dec     de                ;{{ec38:1b}} 

;;=merge read line loop
merge_read_line_loop:             ;{{Addr=$ec39 Code Calls/jump count: 1 Data use count: 0}}
        dec     de                ;{{ec39:1b}} DE=remaining bytes counter
        ld      a,d               ;{{ec3a:7a}} 
        or      e                 ;{{ec3b:b3}} Test if DE=0
        jr      z,_merge_read_line_loop_9;{{ec3c:2808}}  (+$08)

        call    merge_read_char   ;{{ec3e:cdfceb}} Copy byte from char to memory
        ld      (hl),a            ;{{ec41:77}} 
        inc     hl                ;{{ec42:23}} 
        jr      c,merge_read_line_loop;{{ec43:38f4}}  (-$0c) Loop unless file error

        ret                       ;{{ec45:c9}} 

_merge_read_line_loop_9:          ;{{Addr=$ec46 Code Calls/jump count: 1 Data use count: 0}}
        ld      (address_after_end_of_program),hl;{{ec46:2266ae}} Line copied
        scf                       ;{{ec49:37}} 
        ret                       ;{{ec4a:c9}} 

;;=merge read word to DE
merge_read_word_to_DE:            ;{{Addr=$ec4b Code Calls/jump count: 2 Data use count: 0}}
        call    merge_read_char   ;{{ec4b:cdfceb}} 
        ld      e,a               ;{{ec4e:5f}} 
        call    c,merge_read_char ;{{ec4f:dcfceb}} 
        ld      d,a               ;{{ec52:57}} 
        ret                       ;{{ec53:c9}} 

;;=read filename and open for input
read_filename_and_open_for_input: ;{{Addr=$ec54 Code Calls/jump count: 3 Data use count: 0}}
        call    close_input_and_output_streams;{{ec54:cd00d3}}  close input and output streams
        call    read_filename_and_open_in;{{ec57:cdbed2}} 
        ld      (file_type_from_file_header),a;{{ec5a:3229ae}} 
        ld      (file_length_from_file_header),bc;{{ec5d:ed432aae}} 
        ret                       ;{{ec61:c9}} 

;;=========
;;=validate and MERGE
validate_and_MERGE:               ;{{Addr=$ec62 Code Calls/jump count: 2 Data use count: 0}}
        ld      a,(file_type_from_file_header);{{ec62:3a29ae}} 
        or      a                 ;{{ec65:b7}} 
        jp      z,do_MERGE        ;{{ec66:ca63eb}} Type 0 = tokenised, unprotected
        cp      $16               ;{{ec69:fe16}} ASCII file?
        jr      nz,raise_File_type_error;{{ec6b:200b}}  (+$0b)

;;=validate and LOAD BASIC
validate_and_LOAD_BASIC:          ;{{Addr=$ec6d Code Calls/jump count: 3 Data use count: 0}}
        ld      a,(file_type_from_file_header);{{ec6d:3a29ae}} 
        cp      $16               ;{{ec70:fe16}} ASCII file?
        jr      z,load_ASCII_file ;{{ec72:2842}}  (+$42)
        and     $fe               ;{{ec74:e6fe}} Bit 0 set = protected
        jr      z,load_tokenised_file;{{ec76:2804}}  (+$04)

;;=raise File type error
raise_File_type_error:            ;{{Addr=$ec78 Code Calls/jump count: 1 Data use count: 0}}
        call    byte_following_call_is_error_code;{{ec78:cd45cb}} 
        defb $19                  ;Inline error code: File type error

;;=============================================
;;=load tokenised file
load_tokenised_file:              ;{{Addr=$ec7c Code Calls/jump count: 1 Data use count: 0}}
        call    reset_exec_data   ;{{ec7c:cd8fc1}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ec7f:cd29f6}} 

;Validate we have enough free space
        ld      bc,(address_of_end_of_ROM_lower_reserved_are);{{ec82:ed4b64ae}} BC=size of lower memory
        inc     bc                ;{{ec86:03}} 
        call    get_end_of_free_space;{{ec87:cd07f7}} HL=upper memory?
        ld      de,$ff80          ;{{ec8a:1180ff}} DE=buffer space? ###LIT###;WARNING: Code area used as literal
        add     hl,de             ;{{ec8d:19}} 
        or      a                 ;{{ec8e:b7}} 
        sbc     hl,bc             ;{{ec8f:ed42}} HL=free space
        ld      de,(file_length_from_file_header);{{ec91:ed5b2aae}} DE=file length
        call    nc,compare_HL_DE  ;{{ec95:d4d8ff}}  HL=DE?
        jp      c,_merge_out_of_memory_1;{{ec98:daf5eb}} Error if not enough memory

        ex      de,hl             ;{{ec9b:eb}} DE=file length
        add     hl,bc             ;{{ec9c:09}} HL=last available addr?
        ld      (address_after_end_of_program),hl;{{ec9d:2266ae}} 

        ld      a,(file_type_from_file_header);{{eca0:3a29ae}} 
        rra                       ;{{eca3:1f}} 
        sbc     a,a               ;{{eca4:9f}} 
        ld      (program_protection_flag_),a;{{eca5:322cae}} 

        ld      h,b               ;{{eca8:60}} HL=start of program space
        ld      l,c               ;{{eca9:69}} 
        call    CAS_IN_DIRECT     ;{{ecaa:cd83bc}}  firmware function: CAS IN DIRECT - load file
        jp      z,raise_disc_error;{{ecad:ca09ec}} 

;;=move vars and arrays down and close input file
move_vars_and_arrays_down_and_close_input_file:;{{Addr=$ecb0 Code Calls/jump count: 2 Data use count: 0}}
        call    prob_move_vars_and_arrays_back_from_end_of_memory;{{ecb0:cd3cf6}} 
        jp      command_CLOSEIN   ;{{ecb3:c3edd2}}  CLOSEIN

;;=load ASCII file
load_ASCII_file:                  ;{{Addr=$ecb6 Code Calls/jump count: 1 Data use count: 0}}
        call    reset_exec_data   ;{{ecb6:cd8fc1}} 
        call    zero_current_line_address;{{ecb9:cdaade}} 
        call    prob_move_vars_and_arrays_to_end_of_memory;{{ecbc:cd29f6}} 

;;=load ASCII line loop
load_ASCII_line_loop:             ;{{Addr=$ecbf Code Calls/jump count: 1 Data use count: 0}}
        call    read_line_from_cassette_or_disc;{{ecbf:cd0acb}} Read line into buffer
        jr      nc,move_vars_and_arrays_down_and_close_input_file;{{ecc2:30ec}}  (-$14) Error or end of file
        call    skip_space_tab_or_line_feed;{{ecc4:cd4dde}}  skip loading whitespace
        or      a                 ;{{ecc7:b7}} Empty buffer?
        call    nz,load_ASCII_tokenise_line;{{ecc8:c4cdec}} Tokise line (and append to program)
        jr      load_ASCII_line_loop;{{eccb:18f2}}  (-$0e) Loop for more

;;=load ASCII tokenise line
load_ASCII_tokenise_line:         ;{{Addr=$eccd Code Calls/jump count: 1 Data use count: 0}}
        call    parse_line_number ;{{eccd:cdcfee}} Convert line number?
        jp      c,prob_tokenise_and_insert_line;{{ecd0:daa5e7}} 

        ld      a,$15             ;{{ecd3:3e15}} Direct command found error
        jr      z,_load_ascii_tokenise_line_5;{{ecd5:2802}}  (+$02) Line with no line number?
        ld      a,$06             ;{{ecd7:3e06}} Overflow error
_load_ascii_tokenise_line_5:      ;{{Addr=$ecd9 Code Calls/jump count: 1 Data use count: 0}}
        jp      raise_error       ;{{ecd9:c355cb}} 

;;========================================================================
;; command SAVE
;SAVE <file name>[,<file type>[,<binary parameters>]]
;Saves a file
;File type:
;   None:   Tokenised BASIC
;   A:      ASCII BASIC
;   P:      Protected BASIC
;   B:      Binary file
;Binary parameters (only for binary files):
;<start address>,<length>[,<entry point>]
;Entry point is used if the file is loaded with RUN

command_SAVE:                     ;{{Addr=$ecdc Code Calls/jump count: 0 Data use count: 1}}
        call    close_input_and_output_streams;{{ecdc:cd00d3}} ; close input and output streams
        call    command_OPENOUT   ;{{ecdf:cda8d2}} ; OPENOUT - reads filename parameter and opens the file
        ld      b,$00             ;{{ece2:0600}} File type for unprotected tokenised BASIC
        call    next_token_if_prev_is_comma;{{ece4:cd41de}} Is there a file type parameter?
        jr      nc,save_BASIC_tokenised;{{ece7:3025}}  (+$25)

        call    next_token_if_equals_inline_data_byte;{{ece9:cd25de}} read file type letter
        defb $0d                  ;inline token to test CR
        inc     hl                ;{{eced:23}} 
        inc     hl                ;{{ecee:23}} 
        ld      a,(hl)            ;{{ecef:7e}}  parameter (,A ,B ,P)
        and     $df               ;{{ecf0:e6df}} 
        jp      p,Error_Syntax_Error;{{ecf2:f249cb}}  Error: Syntax Error - invalid file type parameter

        push    hl                ;{{ecf5:e5}} 
        ld      hl,save_parameters_list;{{ecf6:2100ed}} 
        call    get_address_from_table;{{ecf9:cdb4ff}} Lookup parameter in table
        ex      (sp),hl           ;{{ecfc:e3}} Put result (code address) onto TOS so next line RETurns into it
        jp      get_next_token_skipping_space;{{ecfd:c32cde}}  get next token skipping space

;;=save parameters list
save_parameters_list:             ;{{Addr=$ed00 Data Calls/jump count: 0 Data use count: 1}}
        defb $03                  ;Number of parameter options
        defw Error_Syntax_Error   ; Error if not found: Syntax Error   ##LABEL##

        defb $c1                  ; ,A
        defw save_ASCII           ;  ##LABEL##
        defb $c2                  ; ,B
        defw save_binary          ;  ##LABEL##
        defb $d0                  ; ,P
        defw save_BASIC_protected ;  ##LABEL##

;;---------------------------------------------------
;; SAVE ,P
;;=save BASIC protected
save_BASIC_protected:             ;{{Addr=$ed0c Code Calls/jump count: 0 Data use count: 1}}
        ld      b,$01             ;{{ed0c:0601}} File type for protected tokenised BASIC

;;=save BASIC tokenised
save_BASIC_tokenised:             ;{{Addr=$ed0e Code Calls/jump count: 1 Data use count: 0}}
        call    error_if_not_end_of_statement_or_eoln;{{ed0e:cd37de}} 
        push hl                   ;{{ed11:e5}} 
        push    bc                ;{{ed12:c5}} 
;Prepare code for saving
        call    convert_all_line_addresses_to_line_numbers;{{ed13:cd70e7}}  line address to line number
        call    reset_variable_types_and_pointers;{{ed16:cd4dea}} 
;Calc file (program) size
        ld      hl,(address_of_end_of_ROM_lower_reserved_are);{{ed19:2a64ae}} 
        inc     hl                ;{{ed1c:23}} HL=first byte of program
        ex      de,hl             ;{{ed1d:eb}} 
        ld      hl,(address_after_end_of_program);{{ed1e:2a66ae}} HL=end of program
        or      a                 ;{{ed21:b7}} Clear carry
        sbc     hl,de             ;{{ed22:ed52}} HL=length of program
        ex      de,hl             ;{{ed24:eb}} 
        pop     af                ;{{ed25:f1}} A=file type
        ld      bc,$0000          ;{{ed26:010000}} Execution address (not valid for BASIC) ##LIT##
        jr      do_binary_file_save;{{ed29:1820}}  (+$20)

;; SAVE ,B
;;=save binary
save_binary:                      ;{{Addr=$ed2b Code Calls/jump count: 0 Data use count: 1}}
        call    next_token_if_comma;{{ed2b:cd15de}}  check for comma			; start
        call    eval_expr_as_uint ;{{ed2e:cdf5ce}} Read start addr parameter
        push    de                ;{{ed31:d5}} 
        call    next_token_if_comma;{{ed32:cd15de}}  check for comma			; length
        call    eval_expr_as_uint ;{{ed35:cdf5ce}} Read length parameter
        push    de                ;{{ed38:d5}} 
        call    next_token_if_prev_is_comma;{{ed39:cd41de}}  execution
        ld      de,$0000          ;{{ed3c:110000}} Default execution address ##LIT##
        call    c,eval_expr_as_uint;{{ed3f:dcf5ce}} Read execution address parameter, if present
        push    de                ;{{ed42:d5}} 
        call    error_if_not_end_of_statement_or_eoln;{{ed43:cd37de}} Error if more parameters

        ld      a,$02             ;{{ed46:3e02}} ; File type binary
        pop     bc                ;{{ed48:c1}} Execution address
        pop     de                ;{{ed49:d1}} File length
        ex      (sp),hl           ;{{ed4a:e3}} HL=start addr

;;=do binary file save
do_binary_file_save:              ;{{Addr=$ed4b Code Calls/jump count: 1 Data use count: 0}}
        call    CAS_OUT_DIRECT    ;{{ed4b:cd98bc}} ; firmware function: cas out direct - write the file
        jp      nc,raise_file_not_open_error_C;{{ed4e:d237cc}} abort if error
        jr      save_close_file   ;{{ed51:1817}}  (+$17)

;; SAVE ,A
;;=save ASCII
save_ASCII:                       ;{{Addr=$ed53 Code Calls/jump count: 0 Data use count: 1}}
        call    error_if_not_end_of_statement_or_eoln;{{ed53:cd37de}} 
        push    hl                ;{{ed56:e5}} 
        ld      a,$09             ;{{ed57:3e09}} Select file as output stream
        call    select_txt_stream ;{{ed59:cda6c1}} 
        push    af                ;{{ed5c:f5}} Save previous stream

        ld      bc,$0001          ;{{ed5d:010100}} starting line number
        ld      de,$ffff          ;{{ed60:11ffff}} ending line number ##LIT##;WARNING: Code area used as literal

        call    do_LIST           ;{{ed63:cde3e1}} LIST (to file stream)

        pop     af                ;{{ed66:f1}} Restore previous stream
        call    select_txt_stream ;{{ed67:cda6c1}} 

;;=save close file
save_close_file:                  ;{{Addr=$ed6a Code Calls/jump count: 1 Data use count: 0}}
        call    command_CLOSEOUT  ;{{ed6a:cdf5d2}}  CLOSEOUT
        pop     hl                ;{{ed6d:e1}} 
        ret                       ;{{ed6e:c9}} 




