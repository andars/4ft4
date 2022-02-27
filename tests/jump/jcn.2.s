!rand
STC
/ not taken
JCN 10 0x10 / 2 (carry) + 8 (invert)
CLC
/ taken
JCN 10 0x20

!expect pc: 0x20
