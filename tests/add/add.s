!rand
CLC
/load 10 into register 12
LDM 10
XCH 12
/load 4 into the accumulator
LDM 4

ADD 12

!expect accumulator: 0xe
!expect carry: 0
