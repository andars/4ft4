!rand
!ram
/ select ram 0
LDM 0
DCL

/ load value into accumulator
LDM 14

/ write value to ram
FIM 0P 0
SRC 0
WRM

/ clear accumulator
CLB

/ reload value from ram into accumulator
RDM

!expect accumulator: 0xe
!expect ram 0 reg 0: e 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
