!rand
CLC
/ load 9 into register 11
LDM 9
XCH 11
/ load 11 into the accumulator
LDM 11

ADD 11

!expect accumulator: 0x4
!expect carry: 1

