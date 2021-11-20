1 'Program to walk the variables, DEF FNs and arrays linked lists
2 'From github.com/Bread80/Amstrad-CPC-BASIC-Source
3 'For data structure etc detail see www.cpcwiki.eu/index.php/Technical_information_about_Locomotive_BASIC
4 'Coded for BASIC 1.1. For BASIC 1.0 update the assignments to v.membase and v.head in lines 100-300
5 'BEWARE: Creating variables moves array data. Ensure all variables are created /before/ reading array data
6 MODE 2
7 GOSUB 900
8 DEF FNpeekw(addr)=PEEK(addr)+PEEK(addr+1)*256
9 PRINT "Base+Offs=Addr Typ @    Name","Data"
10 REM Walk variables list
20 v.headbase=&ADB7:'Start of headers list in data area. &ADD0 on 464
25 v.membase=FNpeekw(&AE68) - 1:'Start of variables area less one. &AE85 on 464
30 FOR v.firstchar=ASC("A") TO ASC("Z"):'List for each letter (first char of var name)
40 v.head=v.headbase+(v.firstchar-ASC("A"))*2:'Head of list
50 v.listtype=1:'Variables
55 'PRINT "List for ";CHR$(v.firstchar);" at &";HEX$(v.head,4)
60 GOSUB 1000:'Walk list
70 NEXT
100 'DEF FNs
110 v.membase=FNpeekw(&AE68) - 1:'Start of variables area less one
120 v.head=&ADEB:'DEF FN list head ptr. &AE04 on 464
130 PRINT "List for DEF FNs"
140 v.listtype=2:'DEF FNs
150 GOSUB 1000:'Walk list
200 'Arrays
205 v.dims=-1:v.dim=1:'Alloc vars so arrays data doesn't move!!
210 v.membase=FNpeekw(&AE6A)-1:'Start of arrays area less one. &AE87 on 464
220 v.listtype=3:'Arrays
230 v.head=&ADED:'&AE06 ON 464
240 PRINT "List for real arrays"
250 GOSUB 1000
260 v.head=&ADEF:'&AE08 on 464
270 PRINT "List for integer arrays"
280 GOSUB 1000
290 v.head=&ADF1:'&AE0A on 464
300 PRINT "List for string arrays"
310 GOSUB 1000
800 END
890 'Test variables
900 anint%=12
905 a12345=12345
910 astr$="Test string"
920 areal!=1.9
930 DEF FNtext$="Done"
950 DIM aa%(1000)
955 DIM r1!(10)
957 r1!(0)=PI
960 DIM ab%(100)
965 DIM sa$(5,6,7)
968 sa$(0,0,0)="An array!!!"
970 aa%(0)=-1
980 ab%(0)=-2
990 RETURN
991 'v.membase = base of memory area (variables/DEFFNs area or arrays area)
992 'v.head = address of list head pointer (in data area)
994 'v.listtype 1=variables, 2=DEF FNs, 3=Arrays
1000 v.offset=FNpeekw(v.head):'Offset from v.base
1020 WHILE v.offset <> 0
1021 'PRINT HEX$(v.offset);v.offset
1025 v.cur = v.membase+v.offset:'From offset to absolute
1027 PRINT HEX$(v.membase,4);"+";HEX$(v.offset,4);"=";
1030 PRINT HEX$(v.cur,4);
1040 v.str =v.cur+2:'address of name
1050 GOSUB 2000:'Get name in v.name$
1070 v.vtype=PEEK(v.str)
1080 PRINT v.vtype;
1081 v.vtype=v.vtype AND 63:'Mask out flags, Bit 5=DEF FN
1082 IF v.vtype=1 THEN PRINT "%"; ELSE IF v.vtype=2 THEN PRINT "$"; ELSE IF v.vtype=4 THEN PRINT "!"; ELSE PRINT "UNKNOWN";
1085 v.str=v.str+1:'Point to value
1088 PRINT " ";HEX$(v.str,4);" ";
1089 PRINT v.name$,
1090 ON v.listtype GOSUB 1300, 1400, 1500
1170 v.offset=FNpeekw(v.cur):'Next list item
1180 'IF v.listtype=3 THEN v.offset=v.offset-v.asize-6 ELSE v.offset=FNpeekw(v.cur):'Next list item
1185 WEND
1190 RETURN
1290 'Print variable data
1291 'v.vtype=variable type from list data
1292 'v.str=ptr TO variable DATA
1300 IF v.vtype=1 THEN PRINT "Value ";FNpeekw(v.str):'Integer
1310 IF v.vtype=2 THEN GOSUB 2200:PRINT "Len";v.slen;"Addr ";HEX$(v.saddr,4);" ";CHR$(&22);v.str$;CHR$(&22):'String
1320 IF v.vtype=4 THEN GOSUB 2100:PRINT "Value ";v.real!
1330 RETURN
1390 'Print DEF FN data
1391 'Params as above
1400 PRINT "DEF FN code addr ";HEX$(FNpeekw(v.str),4)
1410 RETURN
1490 'Print array data
1500 PRINT "Bytes";FNpeekw(v.str);:'Size in bytes
1510 v.str=v.str+2
1520 v.dims=PEEK(v.str):'Array dimensions
1530 PRINT "Dims";v.dims;
1540 v.str=v.str+1
1542 'Remember DIM v(10) creates elements 0..10, so an 11 element array. So bounds numbers will be one more than the DIM value
1545 PRINT "Bounds";
1550 FOR v.dim=1 TO v.dims
1560   PRINT FNpeekw(v.str);
1570   v.str=v.str+2
1580 NEXT
1590 'PRINT "First ";:GOTO 1300:'Uncomment to print first element
1600 PRINT
1610 RETURN
1990 'Read an ASCIIZ string
1991 'v.str = addr of first char
1992 'Returns the string in v.name$
1993 'and v.str = addr of byte after string
2000 v.name$=""
2010 v.char=0
2020 WHILE v.char<128
2030 v.char=PEEK(v.str)
2031 IF (v.char AND 127)<32 THEN v.char=v.char OR 32:'BASIC clears but 5 to convert to upper case which means numbers and periods ne
ed fixing
2040 v.name$=v.name$+CHR$(v.char AND 127)
2050 v.str =v.str+1
2060 WEND
2070 RETURN
2090 'Read a real value
2091 'v.str is addr of the value
2092 'Returns the value in v.real!
2100 v.real!=1:'Alloc our value
2110 FOR v.i=0 TO 4
2120   POKE v.i+@v.real!,PEEK(v.str+v.i)
2130 NEXT
2140 RETURN
2190 'Read a string pointer
2191 'v.str=String pointer
2192 'Returns: v.slen=str length, v.saddr=addr of char data, v.str$=string data
2200 v.slen=PEEK(v.str):'Length byte
2210 v.saddr=FNpeekw(v.str+1):'String addr
2215 v.str$=""
2220 FOR v.sptr=v.saddr TO v.saddr+v.slen-1
2230   v.str$=v.str$+CHR$(PEEK(v.sptr))
2240 NEXT
2250 RETURN
