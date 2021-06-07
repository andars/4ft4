!rand
CLC
/load 4 into register 12
LDM 4 
XCH 12
/load 10 into the accumulator
LDM 10 

SUB 12

!expect accumulator: 0x6
!expect carry: 1
