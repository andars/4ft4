!rand
!cycles 5
/ 0x00
LDM 1
XCH 0
LDM 7
XCH 1
/ 0x04
FIN 3P
NOP
NOP
NOP
/ 0x08
NOP
NOP
NOP
NOP
/ 0x0c
NOP
NOP
NOP
NOP
/ 0x10
NOP
NOP
NOP
NOP
/ 0x14
NOP
NOP
NOP
42
/ 0x18
!expect register  6: 0x2
!expect register  7: 0xa


