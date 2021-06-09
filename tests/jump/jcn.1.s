!rand
!cycles 4
LDM 1
/ not taken
JCN 4 0x10
LDM 0
/ taken
JCN 4 0x20

!expect pc: 0x20
