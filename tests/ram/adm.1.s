!rand
!ram
/ select ram 0
LDM 0
DCL
STC
/ load value into accumulator
LDM 4
/ load address in {0, 1}
FIM 0P 0
/ set address
SRC 0
/ write value to ram
WRM

LDM 9
ADM

!expect accumulator: 0xe
!expect ram 0 reg 0: 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
!expect carry: 0

