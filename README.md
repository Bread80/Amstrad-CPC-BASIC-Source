Amstrad CPC464/CPC664/CPC672/CPC6128 BASIC 1.1 'Unassembly'
===

This repository is the end result of a project to 'unassemble' the Amstrad CPC BASIC ROM. I use the word 'unassemble' to mean creating a version of the firmware source code which can be modified and reassembled. This differs from 'disassembly' in that 'unassembling' involves adding (meaningful) labels to the code and converting the targets of calls, jumps, loads etc to use those labels. It's impossible to verify that the end result is 100% correct but I've taken numerous steps to try and ensure these listings are as correct as possible. For more details of the 'unassembly' process see the About Unassembly section below.

This project builds on previous disassembly and reverse engineering work which can be found at http://cpctech.cpc-live.com/docs/basic.asm

What's in This Repository
---
In the associated files you will find:
* BASIC1.1.asm is the unassembled code as a single file
* Other asm files are the same but broken out into separate files to make exploration, modification and re-use easier. Main.asm is the .. erm ... main file which 'includes' all the others.
* BASIC1.1.disasm is the 'marked up' disassembly which serves as the input to my unassembly utility (see below)
* Amstrad CPC 6128 BASIC (1986).rom is a ROM image taken from a CPC6128 and used to verify (diff) the output of the unassembly process.
* rasmoutput.bin is the output of running the source files (Main.asm or BASIC1.1.asm) through the RASM assembler which should be identical to the original ROM image.
* The includes folder contains various include files needed to assemble the source code. This includes lists of firmware jumpblock addresses and memory addresses used by the code.
* The Examples folder contains Amstrad BASIC programs to explore, test or demonstrate features.

Project Status
---
I now consider the project to be complete. There are still a few areas where commenting is limited, such as the the code around arrays, but there are sufficient 'high level' comments about what each section is doing in total that anyone skilled enough to modify the code will also be skilled enough to understand it. I'd also like to factor out a few 'magic numbers' such as token values and some numeric constants to make the code easier to parse, although such work does introduce the risks of misunderstanding a values purpose and introducing bugs.

I also want to make it easy to extend the BASIC. As it stands there is not a single byte spare in the 16k ROM, so extending BASIC will mean either removing features or splitting it into multiple ROMs. The Amstrad firmware has built in support for the multiple ROM option so I'd rather go that route. However, there is no quick and easy way to split the code. There's an obvious split between command line/program editing and run-time but each mode uses features of the other. For example code entry uses the same routines to parse numbers as used by the INPUT etc routines at run time. It will probably require some form to static analysis tool to assess which sections are used by each mode (and which are used by both).

Finding Your Way Around
===

This is a large project with over 12k lines of code so a few pointers will help you find your way around the code base. There are two versions of the code, BASIC1.1.asm is the entire source in a single, monolithic file. The second version is split into modules with 'Main.asm' as the core file which 'includes' the others. If you want to search for something specific the monolithic file will suit you best. If you want to explore or modify a single set of features then the modular version will prove easier to manage.

When splitting the code into modules I've tried not to make modules too large, whilst also trying to keep the module count to a reasonable figure. In general the code is easy to split in this way, but there are a few sections where a small piece of code would be better placed elsewhere. And the occasional grouping of several functionalities which aren't related to anything else. An example of the latter is the PEEK, POKE, INP, OUT, WAIT, bar command, CALL routines. They're all somewhat related in function, they're all grouped in the source, but they don't fall into any easily labeled category. I've chosen to leave them in a single module and use the clumsy title 'PeekPokeIOBarCall.asm'.

Initialisation
---
Initialisation.asm contain the ROM header, startup message and initialisation code before jumping to the command line.

At the Command Line
---
In the source I've used the acronym REPL to describe the command line interpreter. (REPL = Read, Execute, Print, Loop) This is based around the EDIT statement which you'll find it in the ProgramEntry.asm file. This is probably better termed EDIT.asm but it also includes AUTO, NEW and CLEAR statements so there's more than just line editing happening here!

You might be tempted to look for a single module containing the edit-time only statements. In practice such statements are normally grouped with any other related code. Thus RENUM is grouped with code manipulation utilities, LIST with detokenisation routines etc.

Anyway, here's a list of the main statements you'll want to use at the command line and which modules to find them in:
AUTO    ProgramEntry.asm
CLEAR   ProgramEntry.asm
CONT    Errors.asm
DELETE  ProgramManipulation.asm
EDIT    ProgramEntry.asm
LIST    Detokenising.asm
LOAD    LoadSaveRun.asm
MEMORY  MemoryAllocation.asm
NEW     ProgramEntry.asm
RENUM   ProgramManipulation.asm
RESUME  Errors.asm
RUN     LoadSaveRun.asm
SAVE    LoadSaveRun.asm

If you're looking for the BASIC line editor itself then it's actually located in the lower, firmware ROM. The BasicInput.asm module contains the code to call it (see Data Input/Output section below).

Tokenisation and Detokenisation
---
After commands or program lines have been entered at the command line they need to be turned into runnable code. The code is 'tokenised' to make it faster to run than plain text. (Ie. keywords are turned into a one or two byte code, numbers are converted to binary formats and variables act as pointers to data storage areas).

This is handled within the Tokenisation.asm module along with KeywordLUTs.asm which includes both data and code to convert keywords into tokens and vice versa. (And also includes various non-words such as mathematical and comparison operators). (LUT = Look Up Table - a list of values (often pointers) that we can reference with an index).

The reverse procedure, turned tokenised code back to text, is handled in Detokenising.asm. You'll also find the LIST command in this module.

And it's worth mentioning that the LOAD, SAVE and MERGE commands will use this code when loading and saving ASCII files - see LoadSaveRun.asm. (Although the default options load and save the tokenised files directly).

Execution
---
After entering some code you'll want to run it. This can be either running a program, or running a direct command entered at the command line. (It's interesting to realise that the command line editor is basically the EDIT command. If you type the EDIT command it gets tokenised and executed. And that execution calls the EDIT command (and if you're worried about stack overflows - the stack simply gets reset to &c000 when running code or returning to the command line)).

Either way we'll find ourselves in Execution.asm.

At this point it's worth describing the execution process. The code in Execution.asm executes 'statements'. Statements are things you can have at the start of a line and which do useful things on their own. Things like PRINT, LIST and POKE. Contrast that with 'functions' such as PEEK, ROUND and CHR$. While functions may have useful side effects on their own they're more usually used to return some kind of data. As such they form part of an 'expression'. An equation is a kind of mathematical formula which can contain constants, operators ('+', '<>', 'AND' etc) and function calls. And expressions can also use parenthesis to indicate the correct sequence of evaluation.

So a statement such as
LIST 100,1000
is a statement which contains two expressions separated by a comma.

The code in Execution.asm will parse the token for LIST then look up and call it's execution address. The code for LIST will parse (and validate) any parameters it can handle. In this case it will see two expressions and it calls the 'expression evaluator' to to get the value of each expression.

The Expression Evaluator
---
Which brings us to the expression evaluator itself in ExprEvaluator.asm. This is a complex piece of code which will recursively call itself to evaluate sub-expressions within parenthesis. It can handle infix operators (which are in the middle of two expressions - think of '*', '<=', and 'OR'), prefix operators (such as the '+', '-' or 'NOT' before a constant or expression) and function calls. It also deals with 'operator precedence' - multiplication before addition and so on.

Function calls involve looking up the code address for the function (as we did for statements) (FunctionTable.asm) and calling the function. The function will recursively call the expression evaluator to handle it's parameters (if any) and return to a value so the expression evaluator can continue where it left off.

There are also a number of 'system variables' (mostly in SysVars.asm) which are essentially functions with no parameters. These include HIMEM, TIME and XPOS.

To do all this BASIC maintains an 'accumulator' (sometimes termed the 'virtual accumulator')(see Accumulator.asm) which functions in the same way as the accumulator in a processor, storing the result of previous operations and being used as one of the operands in the next. There is also an 'execution stack' which can be used to 'push' and 'pop' values between steps. (The execution stack is also used by control flow statements which will be described shortly). I'd suggest looking at the MemoryBASIC.txt file in the includes folder for more practical details on the accumulator and execution stack.

Within ExprEvaluation.asm you'll find look up tables for both infix operators (InfixOperators.asm) and prefix operators (handled by the expression evaluator). There's also a table here for system variables. Comparisons are handle by a single entry in the infix operator table. This calls the correct routine for the type of the expression (int, real, string) to do the comparison. (And consider here that '=' is just the inversion of '<>', '<=' is inverted '>' and '>=' is inverted '<'. Separate routines would be wasteful when a single comparison can set multiple flags). (The actual comparison routines are in Strings.asm and InfixOperators.asm (which calls code the firmware's real library or IntegerMaths.asm depending on the operator types).

The main look up table for functions is in FunctionTable.asm. It's worth noting that this is divided into two parts, one for functions which take a single numerical parameter, the other for ones wich don't.

For functions in the first group the expression evaluator parses and evaluates the parameter and passes it to the function. Functions in the latter group have to do all the parameter parsing themselves. This saves code for the simple functions but makes extending the table (to add new functions) needs to be done with some caution. And converting a function token to an address uses some clever maths. (Search references to function_table in ExprEvaluator.asm to see what I mean). I've used labels and formulas so adding functions /should/ be possible, but this is currently untested. See also notes in the sources for details.

Control Flow
---
Statements which influence control flow are somewhat specialised - IF, THEN, ELSE, WHILE, WEND, FOR, NEXT, GOTO, GOSUB and RETURN. With the exception of ELSE these are all handled in the ControlFlow.asm module. Many of them make use of the 'execution stack' to store data structures.

IF, NEXT, WHILE and WEND and FOR also all necessitate scanning ahead through the code to find the matching ELSE, WEND or NEXT (if there is one in the case of ELSE). This is done for WHILE and FOR in the ControlFlowUtils.asm module. For the IF statement this is handled by code within the ProgramManipulation.asm module. This is also where you'll find the ELSE statement and subroutines used to skip over and scan through code (including subroutines called from ControlFlowUtils.asm for handling WHILE and FOR).

You'll also find the comments (REM and tick), DATA statements and the DELETE and RENUM commands here since they too need to scan over and ignore code.

Events, Errors and Exception Handling
---
Commands which control error handling such as many of the ON... and ON ERROR... and their corresponding RETURN handlers are in the EventsExceptions.asm module.

This module also contains the event related functions (which the CPC is well provisioned with) and that includes a small amount of sound processing, since that's done via events.

The commands here which perform GOSUBs will use the execution stack, as does a normal GOSUB.

Error and exception handling (as we'd say these days) is handled in the Errors.asm module. There's also code here for the closely related STOP and END commands (which BASIC needs when it encounters an error) plus CONT(inue) and RESUME and ON ERROR GOTO 0. 

(Interesting factoid: ON ERROR GOTO 0 (which turns off the error handler) is an entirely separate command to ON ERROR GOTO n (which turns it on). The latter is handled by a 'generalised' ON command - but which also doesn't process ON SQ or ON BREAK. Trust me, I did a double take and some serious investigation when I noticed this, but it's there in black and white in the tables in the KeywordLUTs.asm module).

Keyboard related event handling (ie the BREAK key) is handled within Keyboard.asm (see Data Input and Output below).

You might think that RUN would be included with this lot, but it's actually with the file handling stuff in LoadSaveRun.asm where it can deal with running a newly loaded file if needed.

Finally in Errors.asm is the (highly compressed - go and look) error messages and the code to display them.

Variables, arrays, DEF FN and Memory Management
---
This is an area of the source which I haven't explored much yet. Most of it is in the VariableArrayFN.asm module with the code for DEF FN and FN being in DEFFN.asm.

As I find out how it works I may find a convenient way to split it into smaller modules (at 55kb it's currently the largest single module). It contains DEFINT, DEFSTR, DEFREAL, DIM, LET and ERASE plus (probably) all the eye-wateringly ugly memory management code that that entails.

And speaking of ugly memory management code, we have the MemoryAllocation.asm module. This handles various memory allocation and memory movement tasks such as the MEMORY command, allocating and de-allocating file buffers and the SYMBOL (AFTER) commands. (But the strings area (heap) is handled in the separate StringsArea.asm module).

Data Input and Output
---
I want to include the DATA statement in this group but, as we've already seen, that's in ProgramManipulation.asm (see Control Flow above). But then DATA doesn't actually read data. That is, of course, done by the READ command (aided by RESTORE). And those are in the DataInput.asm module where they're accompanied by (LINE) INPUT.

The rest of this stuff is somewhat scattered, so lets have a browse.

There's the Input.asm file which contains INKEY, JOY, KEY, KEY DEF and SPEED WRITE/SPEED KEY/SPEED INK. 

The Keyboard.asm module houses some low level keyboard stuff including the break key (pause/stop) handler and the ON BREAK CONT(inue) and ON BREAK STOP commands. (For other ON and ON BREAK stuff see the EventsExceptions.asm file as described above).

BasicInput.asm is where you'll find the BASIC line editor used by EDIT but also called by other input commands. There's also some code in here to read into the edit buffer from cassette/disc and which is used when reading text files.

On the subject of file handling, CAT and file stream handling (OPENIN, CLOSEOUT etc) are in FileIO.asm. The file level stuff (RUN, LOAD, SAVE, CHAIN, MERGE) is in LoadSaveRun.asm

There's some stream management stuff in Streams.asm for both input and output (remember that the CPC can use streams for writing to the screen (including user defined windows), printer or files and for reading from keyboard or files).

For reading from and writing to streams look in StreamIO.asm which also includes the EOF system variable and the WIDTH command.

Everybody's favourite, the PRINT statement is in TextOutput.asm along with it's little brother WRITE.

If you're writing to the the display then you'll probably be interested in the Display.asm and Graphics.asm modules which do what they say on the can.

Miscellaneous
---
A few random bits before we get to all the maths and string handling stuff.

PEEK, POKE, INP, OUT, WAIT, bar commands and CALL are in the imaginatively named PeekPokBarCall.asm module.

Sound functions are in Sound.asm

The Strings Area and String Stack
---
The strings area should probably be called the string heap. It's an area of memory below HIMEM which grows downwards as new strings are allocated. BASIC includes a garbage collector which 'compresses' the strings area to remove any wasted space. This garbage collector can be trigger manually with the FRE function, or will run automatically if BASIC runs out of memory.

There is also a 'string stack' This is a block of space within the system variables area which can store a list of string descriptors. This is used during expression parsing, with the descriptors referring to intermediate values in the expression. The strings themselves are allocated on the bottom of the strings area/heap and removed after processing (possibly with a final string value added to the bottom of the previous strings area).

All of this is handled in StringsArea.asm.

Maths, Strings and System Utilities
---
This is the bulk of the functions available in BASIC, many of which are also used by the system when necessary:

IntegerMaths.asm is used by the system, or called from functions elsewhere (Note that floating point maths code is in the lower/firmware ROM and called via the REAL_xxxx jumpblocks).
Maths.asm contains most of the maths functions with a couple for unknown reasons located in MathsAgain.asm (MAX, MIN and ROUND).
Infix operators are in InfixOperators.asm (Prefix operators - '+','-' and 'NOT' are processed within the expression parser itself).
SystemVars.asm contains (most of) the system variables (HIMEM, TIME etc).
Conversion between numerical types is handled by TypeConversions.asm. Strings to number and number to strings conversions are handled by StringsToNumbers.asm and NumbersToStrings.asm respectively.
String handling functions (and related) (concatenation, substrings) are is the responsibility of StringFunctions.asm.

Finally (if I'm not mistaken) is Utilities.asm. A random bunch of routines tucked at the very end of the ROM and doing boring but essential things like memory copies, table lookups and jumps to registers.

Modules Index
---
To see an index of modules see the Main.asm module

Functional Description
===

Virtual Accumulator
---
Explanation to follow

Execution Stack
---
Exlanation to follow

String Stack
---
Explanation to follow

Tokens and code format
---
Explanation to follow but see https://www.cpcwiki.eu/index.php/Technical_information_about_Locomotive_BASIC

Extending BASIC
---
Details to follow

About 'Unassembly'
===

Disassembly listings of the CPC ROMs have been available for a while. However these listings are not suitable for being assembled or for being modified and assembled. To turn them into assemble-able source code a number of steps where necessary. A simple re-arrangement of the columns and adding labels isn't sufficient.

First of all, some areas are code and some are data. Disassembled data areas will contain jumps and calls. A simple reasssembly could result in the targets of these jumps being different. So it's necessary to find all data areas and turn them ito DEFB, DEFW etc directives.

It's also necessary to identify memory addresses being used a constants in the code. Addresses in calls and jumps are, pretty obviously, jumps to code but data loads are harder to resolve. As an example, if we have a ROM for addresses $0000 to $3fff, and an instruction LD HL,$01FF the value $01FF could be a numeric constant but it could also be a reference to an address containing data. Or it could be the address of a subroutine to be called later (e.g. to be passed as a parameter into another routine). There are also situations where only the high or low byte of an address is loaded into a register. In order to be able to modify and reassemble the code it is necessary to find all such constants and determine which point to addresses and which are constants, and convert those to labels.

A lot of this work had already been done in the aforementioned disassembly listings, for which a huge amount of credit is given here.

As part of this project utility software was developed perform to certain steps to massively cut the workload. The project has also involved a large amount of manual work to determine the function of various areas of code and add comments, labels and tags.

As a summary of the work undertaken to get these source files:

* Rearrange the column order to move data such as the object code into the comments.

* Determine which addresses are used as the targets of calls, jumps and data loads (since we're talking ROMs here, data writes are obviously not targetting the code!)

* Add labels as targets for calls, jumps and data reads and also use those labels where they are referenced.

* Extract and parse comments to use as meaningful labels.

* Note calls and jumps which target data areas and references to data within code areas and mark such uses for manual checking (shown as WARNINGS in the output).

* Handle manually specified ##LABEL## and ##LIT## specifiers to clarify the use of constants and remove warnings.

* Assemble the output code and diff against original ROM data.

Licence
===
The object code in this repository is the copyright of Amstrad Consumer Electronics Plc and Locomotive Software Ltd. I understand that the code is freely available for non-commercial use provided the original copyright notices are retained.

This repository is built on the work of those who did the original disassembly and reverse engineering. I don't know the names of those individuals or their licencing terms.

My own work is covered by the Unlicence - https://opensource.org/licenses/unlicense