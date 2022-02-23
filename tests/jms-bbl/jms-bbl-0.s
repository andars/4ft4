!rand

JMS FN0
XCH 3
LD 3
JUN L0

FN0,
    NOP
    BBL 7

L0,
    NOP

!expect accumulator: 0x7
!expect register  3: 0x7
