;Auto-created by Bread80 Reassembler
program_line_redundant_spaces_flag_ EQU $ac00
AUTO_active_flag_    EQU $ac01
AUTO_line_number     EQU $ac02
AUTO_increment_step  EQU $ac04
current_output_stream_ EQU $ac06
current_input_stream_ EQU $ac07
printer_stream_current_x_position_ EQU $ac08
WIDTH_               EQU $ac09
file_output_stream_current_line_position EQU $ac0a
ON_BREAK_flag_       EQU $ac0b
FORNEXT_flag_        EQU $ac0c
FOR_start_value_     EQU $ac0d
address_of_colon_or_line_end_byte_after_ EQU $ac12
address_of_LB_of_the_line_number_contain EQU $ac14
unknown_event_handler_data EQU $ac16
RAM_ac17             EQU $ac17
prob_cache_of_current_execution_addr_dur EQU $ac18
ON_BREAK_GOSUB_handler_line_address_ EQU $ac1a
address_of_location_holding_ROM_routine_ EQU $ac1c
CEvent_Block_for_ON_SQ EQU $ac1e
chain_address_to_next_event_block_0000 EQU $ac1e
count                EQU $ac20
class_Far_address_highest_ EQU $ac21
routine_address_     EQU $ac22
ROM_select_number_   EQU $ac24
RAM_ac25             EQU $ac25
address_of_the_end_of_program_line_byte_ EQU $ac26
address_of_the_end_of_program_line_byte__B EQU $ac28
cevent_block_for_on_sq_B EQU $ac2a
cevent_block_for_on_sq_C EQU $ac36
Ticker_and_Event_Block_for_AFTEREVERY_T EQU $ac42
chain_address_to_next_event_block_ EQU $ac42
count_down_count     EQU $ac44
recharge_count_      EQU $ac46
chain_address_to_next_ticker_block EQU $ac48
count_B              EQU $ac4a
class_Far_address_lowest_ EQU $ac4b
routine_address__B   EQU $ac4c
rom_select_number__B EQU $ac4e
RAM_ac4f             EQU $ac4f
address_of_the_end_of_program_line_byte__C EQU $ac50
address_of_tbe_end_of_program_line_byte_ EQU $ac52
ticker_and_event_block_for_afterevery_t_B EQU $ac54
ticker_and_event_block_for_afterevery_t_C EQU $ac66
ticker_and_event_block_for_afterevery_t_D EQU $ac78
BASIC_input_area_for_lines_ EQU $ac8a
address_of_line_number_LB_in_line_contai EQU $ad8c
address_of_byte_before_statement_contain EQU $ad8e
ERR__Error_No        EQU $ad90
DERR__Disc_Error_No  EQU $ad91
last_RUN_error_address EQU $ad92
last_RUN_error_line_number EQU $ad94
address_line_specified_by_the_ON_ERROR_ EQU $ad96
RESUME_flag_         EQU $ad98
Current_SOUND_parameter_block_ EQU $ad99
channel_andrendezvous_status EQU $ad99
amplitude_envelope_  EQU $ad9a
tone_envelope_       EQU $ad9b
tone_period          EQU $ad9c
noise_period         EQU $ad9e
initial_amplitude    EQU $ad9f
duration_or_envelope_repeat_count EQU $ada0
Current_Amplitude_or_Tone_Envelope_param EQU $ada2
number_of_sections_  EQU $ada2
first_section_of_the_envelope EQU $ada3
step_count_          EQU $ada3
step_size_           EQU $ada4
pause_time_          EQU $ada5
second_section_of_the_envelope_as_ADA3 EQU $ada6
third_section_of_the_envelope_as_ADA3 EQU $ada9
fourth_section_of_the_envelope_as_ADA3 EQU $adac
fifth_section_of_the_envelope_as_ADA3 EQU $adaf
power_operator_parameter EQU $adb2
linked_list_headers_for_variables EQU $adb7
DEFFN_linked_list_head EQU $adeb
real_array_linked_list_head EQU $aded
int_array_linked_list_head EQU $adef
string_array_linked_list_head EQU $adf1
table_of_DEFINT_     EQU $adf3
RAM_ae0d             EQU $ae0d
poss_cached_addrvariable_name_address_o EQU $ae0e
FN_param_start       EQU $ae10
FN_param_end         EQU $ae12
input_prompt_separator EQU $ae14
address_of_line_number_LB_of_last_BASIC_ EQU $ae15
READ_pointer         EQU $ae17
cache_of_execution_stack_next_free_ptr EQU $ae19
address_of_byte_before_current_statement EQU $ae1b
address_of_line_number_LB_of_line_of_cur EQU $ae1d
trace_flag           EQU $ae1f
tokenisation_state_flag EQU $ae20
line_address_vs_line_number_flag EQU $ae21
unknown_DELETE_temp_1 EQU $ae22
unknown_DELETE_temp_2 EQU $ae24
address_to_load_cassette_file_to EQU $ae26
unknown_CHAIN_flag_  EQU $ae28
file_type_from_cassette_header EQU $ae29
file_length_from_cassette_header EQU $ae2a
program_protection_flag_ EQU $ae2c
buffer_used_to_form_binary_or_hexadecima EQU $ae2d
start_of_buffer_used_to_form_hexadecimal EQU $ae3a
last_byte_           EQU $ae3e
RAM_ae4c             EQU $ae4c
last_byte__B         EQU $ae4e
RAM_ae50             EQU $ae50
RAM_ae51             EQU $ae51
RAM_ae52             EQU $ae52
RAM_ae53             EQU $ae53
RAM_ae54             EQU $ae54
Machine_code_address_to_CALL_ EQU $ae55
ROM_select_number_for_the_above_CALLRSX EQU $ae57
BASIC_Parser_position_moved_on_to__ EQU $ae58
saved_address_for_SP_during_a_CALL_or_an EQU $ae5a
ZONE_value           EQU $ae5c
HIMEM_               EQU $ae5e
address_of_highest_byte_of_free_RAM_ EQU $ae60
address_of_start_of_ROM_lower_reserved_a EQU $ae62
address_of_end_of_ROM_lower_reserved_are EQU $ae64
address_after_end_of_program EQU $ae66
address_of_start_of_Variables_and_DEF_FN EQU $ae68
address_of_start_of_Arrays_area_ EQU $ae6a
address_of_start_of_free_space_ EQU $ae6c
vars_and_data_at_end_of_memory_flag EQU $ae6e
FFexecution_stack    EQU $ae70
execution_stack_next_free_ptr EQU $b06f
address_of_end_of_free_space_ EQU $b071
address_of_end_of_Strings_area_ EQU $b073
poss_file_buffer_flag EQU $b075
poss_file_buffer_address EQU $b076
address_of_the_highest_byte_of_free_RAM_ EQU $b078
RAM_b07a             EQU $b07a
string_stack_first_free_ptr EQU $b07c
string_stack_first   EQU $b07e
string_stack_last    EQU $b09b
length_of_last_String_used EQU $b09c
address_of_last_String_used EQU $b09d
accumulator_data_type EQU $b09f
accumulator          EQU $b0a0
accumulator_plus_1   EQU $b0a1
accumulator_plus_2   EQU $b0a2
accumulator_plus_3   EQU $b0a3
B                    EQU $b0a5
