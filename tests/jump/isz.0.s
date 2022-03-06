!rand
LDM 0
XCH 5
LDM 7
ISZ 5 L0

/ should not execute
LDM 0

L0,
NOP

!expect accumulator: 0x7
