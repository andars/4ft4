!rand
!cycles 4
CLC
/ not taken
JCN 2 0x10
STC
/ taken
JCN 2 0x20

!expect pc: 0x20
