;#dialect=RASM

;Current progress:
;(Mostly) fully reverse engineered as far as **TK

;'Unassembled'[1] Amstrad CPC6128 BASIC 1.1 Source Code

;[1] 'Unassembled' meaning that this code can be modified and reassembled.
;(As far as I can tell) all links etc have been converted to labels etc in
;such a way that the code can be assembled at a different target address
;and still function correctly (excepting code which must run at a specific
;address).

;Based on the riginal commented disassembly at:
; http://cpctech.cpc-live.com/docs/basic.asm

;There are two versions of this file: a single monolithic version and
;one which has been broken out into separate 'includes'. The latter may
;prove better for modification, assembly and re-use. The former for 
;exploration and reverse engineering.

;For more details see: https://github.com/Bread80/Amstrad-CPC-BASIC-Source
;and http://Bread80.com


include "Initialisation.asm"

;;<< PROGRAM ENTRY ROUTINES
;;< REPL loop, EDIT, AUTO, NEW, CLEAR (INPUT)
include "ProgramEntry.asm"

;;<< (TEXT) STREAM MANAGEMENT
include "Streams.asm"

;;<< SCREEN HANDLING FUNCTIONS
include "Screen.asm"

;;<< STREAM I/O
;;< Low level I/O via streams, WIDTH and EOF
include "StreamIO.asm"

;;<< LOW LEVEL KEYBOARD HANDLING
;;< including BREAK key handler
include "Keyboard.asm"

;;<< GRAPHICS FUNCTIONS
include "Graphics.asm"

;;<< CONTROL FLOW
;;< FOR, IF, GOTO, GOSUB, WHILE
include "ControlFlow.asm"

;;<< ERROR AND EVENT HANDLERS
;;< ON xx, DI, EI, AFTER, EVERY, REMAIN
include "EventsExceptions.asm"

;;<< FIND ENDS OF CONTROL LOOPS
;;< Don't have a good phrase for this :(
include "ControlFlowUtils.asm"

;;<< BASIC INPUT BUFFER
;;< As used by EDIT and INPUT etc.
include "BasicInput.asm"

;;<< EXCEPTION HANDLING
;;< Includes ERROR, STOP, END, ON ERROR GOTO 0 (not ON ERROR GOTO n!), RESUME and error messages
include "Errors.asm"

;;<< EXPRESSION EVALUATION
;;< Includes prefix operators and various lookup tables (operators, system vars etc.)
include "ExprEvaluator.asm"

;;<< SYSTEM VARIABLES
;;< (most of them). And the @ prefix operator.
include "SystemVars.asm"

;;<< DEF and DEF FN
include "DEFFN.asm"

;;<< FUNCTION LOOK UP TABLE
include "FunctionTable.asm"

;;<< MATHS FUNCTIONS MIN, MAX and ROUND
include "MathsAgain.asm"

;;<< FILE I/O COMMANDS
;;< CAT, OPENIN, OPENOUT, CLOSEIN, CLOSEOUT
include "FileIO.asm"

;;<< SOUND FUNCTIONS
include "Sound.asm"

;;<< INPUT FUNCTIONS
;;< INKEY, JOY, KEY (DEF). Also SPEED (WRITE/KEY/INK)
include "Input.asm"

;;<< (REAL) MATHS FUNCTIONS
;;< Including ^ and random numbers
include "MathsFunctions.asm"

;;<< VARIABLE ALLOCATION AND ASSIGNMENT
;;< DEFINT/REAL/STR, LET, DIM, ERASE
;;< (Lots more work to do here)
include "VariableArrayFN.asm"

;;<< (TEXT) DATA INPUT
;;< (LINE) INPUT, RESTORE, READ (not DATA)
include "DataInput.asm"

;;<< INTEGER MATHS
;;< (used both internally and by functions)
include "IntegerMaths.asm"

;;<< PROGRAM EXECUTION
;;< Execute tokenised code (except expressions)
;;< Includes token handling utilities, TRON, TROFF, 
;;< and the command/statement look up table.
include "Execution.asm"

;;<< TOKENISING SOURCE CODE
include "Tokenising.asm"

;;<< LIST AND DETOKENISING BACK TO ASCII
include "Detokenising.asm"

;;<< KEYWORD LOOK UP TABLES
;;< And associated functions
include "KeywordLUTs.asm"

;;<< PROGRAM EDITING AND MANIPULATION
;;< DELETE, RENUM, DATA, REM, ', ELSE and
;;< a bunch of related utility stuff
include "ProgramManipulation.asm"

;;<< FILE HANDLING
;;< RUN, LOAD, CHAIN, MERGE, SAVE
include "LoadSaveRun.asm"

;;<< STRINGS TO NUMBERS
include "StringsToNumbers.asm"

;;<< NUMBERS TO STRINGS
include "NumbersToStrings.asm"

;;<< PEEK, POKE, INP, OUT, WAIT, |BAR commands, CALL
include "PeekPokeIOBarCall.asm"

;;<< TEXT OUTPUT (ZONE, PRINT, WRITE)
include "TextOutput.asm"

;;<< MEMORY ALLOCATION FUNCTIONS
;;< Includes MEMORY, SYMBOL (AFTER)
include "MemoryAllocation.asm"

;;<< STRING FUNCTIONS
;;<including the string iterator
include "StringFunctions.asm"

;;<<STRINGS AREA
;;<Including the string stack, FRE and the garbage collector
include "StringsArea.asm"

;;<< INFIX OPERATORS
;;< Infix +, -, *, / etc. including boolean operators
include "InfixOperators.asm"

;;<< TYPE CONVERSIONS AND ROUNDING
;;< (from numbers to numbers)
include "TypeConversions.asm"

;;<< ACCUMULATOR UTILITIES
;;< Store values to accumulator, get values from accumulator,
;;< and accumulator type conversions
include "Accumulator.asm"

;;<< UTILITY ROUTINES
;;< Assorted memory copies, table lookups etc.
include "Utilities.asm"
