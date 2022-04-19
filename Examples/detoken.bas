1 'Program to detokenise an Amstrad BASIC program
2 'By Mike Sutton, 2022. http://bread80.com
3 'https://github.com/Bread80/Amstrad-CPC-BASIC-Source
4 'Config vars at lines 1000 onwards enable display of 
5 'various meta info
10 goto 1000


90 'Put some code to test in here
100 |bar,1,2,3,@g$
110 f=1.234
120 x=&x01001
130 x=&habcd
140 y=-100

990 'Detokenise a basic program
995 'Config variables. 1=show info, 0=don't show
997 'Info is shown within square brackets
1000 dolineaddr=0:'Show line address and length?
1010 dotokenid=0:'Show token IDs?
1020 dovaraddr=0:'Show variable addresses?
1030 dogotoaddr=0:'Show goto/gosub pointer addresses?
1040 doextracolon=0:'Show extra (hidden) statement separators (colons)
1050 dolinedata=0:'Show data bytes for the line
1060 gosub 1100
1070 gosub 2000
1080 goto 1070

1090 'Setup
1100 def fnnum$(num)=mid$(str$(num),2+min(sgn(num),0)):'Number to decimal string with no leading space
1110 def fnpeekw(addr)=peek(addr+1)*256+peek(addr)
1120 cur=fnpeekw(&ae64)+1:'&AE81 for BASIC 1.0
1130 dim token$[256]
1140 for i=0 to 255
1150  read t$
1170  if t$="" then token$[i]="<<Unknown token>>" else token$[i]=t$
1180 next
1190 return

1500 'Tokens
1510 data "ABS","ASC","ATN","CHR$","CINT","COS","CREAL","EXP":'&00-&07
1520 data "FIX","FRE","INKEY","INP","INT","JOY","LEN","LOG":'&08-&0f
1530 data "LOG10","LOWER$","PEEK","REMAIN","SGN","SIN","SPACE$","SQ":'&10-&17
1540 data "SQR","STR$","TAN","UNT","UPPER$","VAL","","":'&18-&1f
1550 data "","","","","","","","","","","","","","","","":'&20-2f
1560 data "","","","","","","","","","","","","","","","":'&30-3f
1570 data "EOF","ERR","HIMEM","INKEY$","PI","RND","TIME","XPOS":'&40-&47
1580 data "YPOS","DERR","","","","","","":'&48-&4f
1590 data "","","","","","","","","","","","","","","","":'&50-5f
1600 data "","","","","","","","","","","","","","","","":'&60-6f
1610 data "","BIN$","DEC$","HEX$","INSTR","LEFT$","MAX","MIN":'&70-&77
1620 data "POS","RIGHT$","ROUND","STRING$","TEST","TESTR","COPYCHR$","VPOS":'&78-&7f
1630 data "AFTER","AUTO","BORDER","CALL","CAT","CHAIN","CLEAR","CLG":'&80-&87
1640 data "CLOSEIN","CLOSEOUT","CLS","CONT","DATA","DEF","DEFINT","DEFREAL":'&88-&8f
1650 data "DEFSTR","DEG","DELETE","DIM","DRAW","DRAWR","EDIT","ELSE":'&90-&97
1660 data "END","ENT","ENV","ERASE","ERROR","EVERY","FOR","GOSUB":'&98-&9f
1670 data "GOTO","IF","INK","INPUT","KEY","LET","LINE","LIST":'&a0-&a7
1680 data "LOAD","LOCATE","MEMORY","MERGE","MID$","MODE","MOVE","MOVER":'&a8-&af
1690 data "NEXT","NEW","ON","ON BREAK","ON ERROR GOTO 0","ON SQ","OPENIN","OPENOUT":'&b0-&b7
1700 data "ORIGIN","OUT","PAPER","PEN","PLOT","PLOTR","POKE","PRINT":'&b8-&bf
1710 data "'","RAD","RANDOMIZE","READ","RELEASE","REM","RENUM","RESTORE":'&c0-&c7
1720 data "RESUME","RETURN","RUN","SAVE","SOUND","SPEED","STOP","SYMBOL":'&c8-&cf
1730 data "TAG","TAGOFF","TROFF","TRON","WAIT","WEND","WHILE","WIDTH":'&d0-&d7
1740 data "WINDOW","WRITE","ZONE","DI","EI","FILL","GRAPHICS","MASK":'&d8-&df
1750 data "FRAME","CURSOR","","ERL","FN","SPC","STEP","SWAP":'&e0-&e7
1760 data "","","TAB","THEN","TO","USING",">","=":'&e8-&ef
1770 data ">=","<","<>","<=","+","-","*","/":'&f0-&f7
1780 data "^","\","AND","MOD","OR","XOR","NOT","":'&f8-&7f

1990 'Line
2000 linelen=fnpeekw(cur):'Line length
2005 lineno=fnpeekw(cur+2):'Line number
2010 if lineno=0 then end:'End of program
2011 if dolineaddr then print "[";hex$(cur,4);linelen;"]";
2012 if dolinedata then for addr=cur to cur+linelen-1:print " ";hex$(peek(addr),2);:next:print
2015 print fnnum$(lineno);" ";
2020 cur=cur+4
2030 gosub 2100
2040 print
2050 return

2090 'Statements
2100 gosub 2200
2105 if token > 1 goto 2100
2110 if token=0 then return:'End of line
2120 nexttok=peek(cur)
2130 'Tick comments and ELSE have a hidden end-of-statement (semi-colon) preceding them
2140 if nexttok=&c0 or nexttok=&97 then if doextracolon then print "[:]"; else else print ":";:'End of statement
2150 goto 2100

2190 'Token
2200 token=peek(cur)
2210 cur=cur+1
2220 if token <= 1 then return:'End of line/statement
2230 if token <= &0d then gosub 3000:return:'Variable
2240 if token <= &18 then print fnnum$(token-&0e);:return:'Constants 0-10
2250 if token = &19 then print fnnum$(peek(cur));:cur=cur+1:return:'Byte constant
2260 if token = &1a then print fnnum$(fnpeekw(cur));:cur=cur+2:return:'Word constant
2270 if token = &1b then print "&X";bin$(fnpeekw(cur));:cur=cur+2:return:'Binary constant
2280 if token = &1c then print "&";hex$(fnpeekw(cur));:cur=cur+2:return:'Hex constant
2290 if token = &1d then lineptr=fnpeekw(cur):print left$("["+hex$(lineptr,4)+"]",dogotoptr*255);fnnum$(fnpeekw(lineptr+3));:cur=cur+2:return:'Line number pointer
2300 if token = &1e then print fnnum$(peek(cur));:cur=cur+2:return:'Line number
2310 if token = &1f then gosub 3900:print float!;:cur=cur+5:return:'Float constant
2320 if token = &20 then print " ";:return:'Space
2330 if token = &22 then gosub 3800:print chr$(&22);s$;chr$(&22);:return:'String constant
2340 if token < &7c then print chr$(token);:return:'ASCII/Tokenised as themselves: ( ) , @ [ ]
2350 if token = &7c then gosub 3700:print "|";varname$;:return:'Bar command
2360 if token = &ff then token=peek(cur):cur=cur+1:'Extended token
2365 if dotokenid then print "[";hex$(token,2);"]";
2370 print token$[token];
2380 if (token = &c0) or (token = &c5) then gosub 3600:print using "&";comment$;:'Comment (' and REM)
2390 return

2990 'Variable
3000 varaddr=fnpeekw(cur):'Address of variable data
3005 cur=cur+2:'Step over pointer
3010 gosub 3700:'Read name
3015 if dovaraddr then print "[";hex$(varaddr,4);"]";
3020 print varname$;
3030 if token = 2 then print "%";:'With explicit type specifier
3040 if token = 3 then print "$";
3050 if token = 4 then print "!";
3060 return

3590 'Comment to comment$
3600 comment$=""
3610  c=peek(cur)
3620  if c<=0 then return
3630  cur=cur+1
3640  comment$=comment$+chr$(c)
3650 goto 3610

3690 'ASCII7 string (variable name) to varname$
3700 varname$=""
3720  c=peek(cur)
3730  cur=cur+1
3740  varname$=varname$+chr$(c and &7f)
3750 if c < &80 goto 3720
3760 return

3790 'Copy string constant to s$
3800 s$=""
3820  c=peek(cur)
3830  cur=cur+1
3840  if c=&22 then return
3850  s$=s$+chr$(c)
3860 goto 3820

3890 'Copy float to float!
3900 float!=0
3905 dest=@float!
3910 for i=1 to 5
3920  poke dest+i,peek(cur+i)
3930 next
3940 return
