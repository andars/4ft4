!rand
!cycles 5
/ 0x00
LDM 1
XCH 0
LDM 7
XCH 1
/ 0x04
FIN 3P

/ 0x17
= 23
42 / 0x2a
/ 0x18
!expect register  6: 0x2
!expect register  7: 0xa


