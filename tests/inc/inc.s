!rand
/ load 7 into register 4, then increment register 4
LDM 7
XCH 4
INC 4

/ load 15 into register 0, then increment register 0
LDM 15
XCH 0
INC 0

!expect register  4: 0x8

!expect register  0: 0x0
