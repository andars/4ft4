!rand
!ram
/ select ram 0
LDM 0
DCL
/ load value into accumulator
LDM 7
/ load address into {0,1}
FIM 0P 0
/ set address
SRC 0
/ write value to ram
WRM

!expect accumulator: 0x7
!expect ram 0 reg 0: 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
