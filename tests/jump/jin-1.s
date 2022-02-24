!rand
/ prepare targets in 0P and 1P
FIM 0P L00
FIM 1P L11
/ clear flag registers
LDM 0
XCH 10
LDM 0
XCH 11

/ go to the first trial jump
JUN J0

/ fake target for J0 (incorrect page crossing behavior)
= 100
L00,
    LDM 1
    XCH 10
    JUN J1

/ fake target for J1
= 244
L10,
    LDM 1
    XCH 11
    JUN FIN

/ first trial jump (should go to next page)
= 255
J0,
    JIN 0P
/ 256

/ true target for J0
= 356
L01,
    LDM 7
    XCH 10
    JUN J1

/ true target for J1
= 500
L11,
    LDM 7
    XCH 11
    JUN FIN

/ second trial jump (should stay on same page)
= 510
J1,
    JIN 1P
/ 511

/ fake target for J1 (incorrect page crossing behavior)
= 1012
L12,
    LDM 2
    XCH 11
    JUN FIN

= 1024
FIN,
    NOP

!expect register 10: 0x7
!expect register 11: 0x7
