;Jumblock symbols for the Amstrad CPC464/664/6128

;Auto-created from work by Dave Cantrell
;http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/

;High kernel jumblock
KL_U_ROM_ENABLE      EQU $B900
KL_U_ROM_DISABLE     EQU $B903
KL_L_ROM_ENABLE      EQU $B906
KL_L_ROM_DISABLE     EQU $B909
KL_ROM_RESTORE       EQU $B90C
KL_ROM_SELECT        EQU $B90F
KL_CURR_SELECTION    EQU $B912
KL_PROBE_ROM         EQU $B915
KL_ROM_DESELECT      EQU $B918
KL_LDIR              EQU $B91B
KL_LDDR              EQU $B91E
KL_POLL_SYNCHRONOUS  EQU $B921
KL_SCAN_NEEDED       EQU $B92A
