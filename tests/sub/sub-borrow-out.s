!rand
CLC
/load 8 into register 12
LDM 8
XCH 12
/load 4 into the accumulator
LDM 4

SUB 12

!expect accumulator: 0xc
/ carry should be set to zero to indicate borrow
!expect carry: 0
