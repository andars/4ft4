!rand
!ram
/ select ram bank 0
LDM 0
DCL

LDM 1
FIM 0P 0
SRC 0
WRM

LDM 2
FIM 0P 1
SRC 0
WRM

LDM 3
FIM 0P 2
SRC 0
WRM

LDM 4
FIM 0P 3
SRC 0
WRM

LDM 5
FIM 1P 16
SRC 1P
WRM

LDM 6
FIM 1P 17
SRC 1P
WRM

LDM 7
FIM 1P 18
SRC 1P
WRM

LDM 8
FIM 1P 19
SRC 1P
WRM

/ clear accumulator
CLB

/ reload values from ram into registers
FIM 7P 0
SRC 7P
RDM
XCH 0

FIM 7P 1
SRC 7P
RDM
XCH 1

FIM 7P 2
SRC 7P
RDM
XCH 2

FIM 7P 3
SRC 7P
RDM
XCH 3

FIM 7P 16
SRC 7P
RDM
XCH 4

FIM 7P 17
SRC 7P
RDM
XCH 5

FIM 7P 18
SRC 7P
RDM
XCH 6

FIM 7P 19
SRC 7P
RDM
XCH 7

!expect register  0: 0x1
!expect register  1: 0x2
!expect register  2: 0x3
!expect register  3: 0x4
!expect register  4: 0x5
!expect register  5: 0x6
!expect register  6: 0x7
!expect register  7: 0x8
!expect ram 0 reg 0: 1 2 3 4 0 0 0 0 0 0 0 0 0 0 0 0
!expect ram 0 reg 1: 5 6 7 8 0 0 0 0 0 0 0 0 0 0 0 0
