!rand
!ram
/ select ram 0
LDM 0
DCL
STC
/ load value into accumulator
LDM 5
/ load address in {0, 1}
FIM 0P 0
/ set address
SRC 0
/ write value to ram
WRM

LDM 10
SBM

!expect accumulator: 0x4
!expect ram 0 reg 0: 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
!expect carry: 1

