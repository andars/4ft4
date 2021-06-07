!rand
STC
/load 8 into register 12
LDM 8
XCH 12
/load r into the accumulator
LDM 4

SUB 12

!expect accumulator: 0xb
!expect carry: 0
