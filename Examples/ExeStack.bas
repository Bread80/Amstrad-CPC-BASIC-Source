1 'Walk execution stack
2 '
3 'Reads data structures for FOR..NEXT, WHILE..WEND and GOUSB..RETURN data only
4 'The execution stack is also used to store temporary variables when calling a DEF FN
5 'and in many places for temporary data during expression evaluation etc.
20 gosub 100
30 for real!=0.1 to 0.3 step 0.15
40 for integer%=2 to 1 step -10
50 while wh=0
60 gosub 1000
70 wh=1
75 wend
80 next integer%,real!
81 on break gosub 1000
82 print "Testing event and ON BREAK GOSUB types"
83 print "Press x to escape"
85 after 100 gosub 1000
90 while inkey$ <> "x":wend
95 end

99 'Init
100 def fnpeekw(addr)=peek(addr+1)*256+peek(addr)
105 def fnpeekwbe(addr)=peek(addr)*256+peek(addr+1)
110 dim gtypes$[2]
120 gtypes$[0]="Normal"
130 gtypes$[1]="ON Event"
140 gtypes$[2]="ON Break"
150 return

1000 print "===Execution Stack Dump"
1005 addr=fnpeekw(&ae19):'Cache of next free byte on stack (&ae32 for BASIC 1.0)
1010 while addr > (&ae70+65536):'&ae8c on BASIC 1.0
1020  type=peek(addr-1)
1030  addr=addr-type
1035  print "&";hex$(addr,4);
1037  gosub 2000
1040  if type=6 then gosub 1200:goto 1100:'GOSUB
1050  if type=&16 then gosub 1300:goto 1100:'FOR with real control variable
1060  if type=&10 then gosub 1400:goto 1100:'FOR with int control variable
1070  if type=7 then gosub 1600:goto 1100:'WHILE loop
1090  print "Unknown item type:";typeli
1095 addr=addr+type-1
1100 wend
1120 print "---End of stack"
1130 return

1190 'GOSUB
1200 print "---GOSUB ";
1210 gtype=peek(addr)
1220 print "type";gtype;
1230 if gtype>=0 and gtype<=2 then print gtypes$[gtype] else print "<Unknown>"
1240 print "Execution return address: &";hex$(fnpeekw(addr+1),4)
1245 laddr=fnpeekw(addr+3)
1247 print "Calling line address: &";hex$(laddr,4)
1250 print "Calling line number: ";fnpeekw(laddr)
1260 return

1290 'Real FOR
1300 print "---FOR with real control variable"
1310 vaddr=fnpeekw(addr)
1320 gosub 2100
1330 print "Control variable @";hex$(vaddr,4);" value: ";v!
1340 vaddr=addr+2
1350 gosub 2100
1360 print "TO value: ";v!
1370 vaddr=addr+7
1380 gosub 2100
1390 print "STEP value: ";v!
1395 vaddr=addr+12
1397 goto 1500

1399 'Int FOR
1400 print "---FOR with int control variable"
1410 vaddr=fnpeekw(addr)
1430 print "Control variable @";hex$(vaddr,4);" value: ";fnpeekw(vaddr)
1440 vaddr=addr+2
1460 print "TO value: ";fnpeekw(vaddr)
1470 vaddr=addr+4
1490 print "STEP value: ";fnpeekw(vaddr)
1495 vaddr=addr+6

1499 'FOR loop common data
1500 sign=peek(vaddr)
1510 if sign=1 then print "STEP positive" else if sign=&ff then print "STEP negative" else print "Invalid STEP direction"
1520 print "Execution address after FOR statement: &";hex$(fnpeekw(vaddr+1),4)
1530 laddr=fnpeekw(vaddr+3)
1540 print "Address of FOR statement line: &";hex$(laddr,4)
1550 print "FOR statement line number: ";fnpeekw(laddr)
1560 print "Address of byte after control var in NEXT: ";hex$(fnpeekw(vaddr+5),4)
1570 print "Address of control var in NEXT: ";hex$(fnpeekw(vaddr+7),4)
1580 return

1590 'WHILE
1600 print "---WHILE"
1610 laddr=fnpeekw(addr)
1620 print "WHILE line address: &";hex$(laddr,4)
1630 print "WHILE line number: ";fnpeekw(laddr)
1640 print "Execution address after WEND: &";hex$(fnpeekw(addr+2),4)
1650 print "Address of condition after WHILE: &";hex$(fnpeekw(addr+4),4)
1660 return

1990 'Dump Step bytes beginning at address Addr
2000 for i=addr to addr+type
2010 print " ";hex$(peek(i),2);
2020 next
2025 print
2030 return

2090 'Copy Real value pointed to by vaddr to V! variable
2100 v!=0
2110 for i=0 to 4
2120  poke @v!+i,peek(vaddr+i)
2130 next
2140 return


10 if 65535 > 10 then print "Larger" else print "Smaller"
20 if &ffff > 10 then print "Larger" else print "Smaller"
30 x=&ffff
40 print hex$(x),x

10 addr=&ae19
20 v=peek(addr+1)*256+peek(addr)
30 print v,hex$(v)

40 v=((peek(addr+1) > 127) * 65535) + peek(addr+1)*256+peek(addr)
50 print v,hex$(v)



