;Jumblock symbols for the low kernel jumblock area on the Amstrad CPC464/664/6128

;Auto-created from work by Dave Cantrell
;http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/

RESET_ENTRY          EQU $0000
LOW_JUMP             EQU $0008
KL_LOW_PCHL          EQU $000B
PCBC_INSTRUCTION     EQU $000E
SIDE_CALL            EQU $0010
KL_SIDE_PCHL         EQU $0013
PCDE_INSTRUCTION     EQU $0016
FAR_CALL             EQU $0018
KL_FAR_PCHL          EQU $001B
PCHL_INSTRUCTION     EQU $001E
RAM_LAM              EQU $0020
KL_FAR_CALL          EQU $0023
FIRM_JUMP            EQU $0028
USER_RESTART         EQU $0030
INTERRUPT_ENTRY      EQU $0038
EXT_INTERRUPT        EQU $003B
