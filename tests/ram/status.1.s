!rand
!ram

/ select ram bank 0
LDM 0
DCL

/ write out a value to the first 8 status characters of the first ram
FIM 7P 0
SRC 7P
LDM 1
WR0
LDM 2
WR1
LDM 3
WR2
LDM 4
WR3

FIM 7P 16
SRC 7P
LDM 5
WR0
LDM 6
WR1
LDM 7
WR2
LDM 8
WR3

/ read them back into registers
FIM 7P 0
SRC 7P
RD0
XCH 0
RD1
XCH 1
RD2
XCH 2
RD3
XCH 3

FIM 7P 16
SRC 7P
RD0
XCH 4
RD1
XCH 5
RD2
XCH 6
RD3
XCH 7

/ increment the values and write them back into ram 1's status characters

FIM 7P 64
SRC 7P
LD 0
IAC
WR0
LD 1
IAC
WR1
LD 2
IAC
WR2
LD 3
IAC
WR3

FIM 7P 80
SRC 7P
LD 4
IAC
WR0
LD 5
IAC
WR1
LD 6
IAC
WR2
LD 7
IAC
WR3

!expect accumulator: 0x9
!expect register  0: 0x1
!expect register  1: 0x2
!expect register  2: 0x3
!expect register  3: 0x4
!expect register  4: 0x5
!expect register  5: 0x6
!expect register  6: 0x7
!expect register  7: 0x8
!expect ram 0 reg 0 status: 1 2 3 4
!expect ram 0 reg 1 status: 5 6 7 8
!expect ram 1 reg 0 status: 2 3 4 5 
!expect ram 1 reg 1 status: 6 7 8 9
