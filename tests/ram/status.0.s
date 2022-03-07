!rand
!ram

/ select ram bank 0
LDM 0
DCL

/ write out a value to a the first status character
FIM 0P 0
SRC 0P
LDM 11
WR0

!expect accumulator: 0xb
!expect ram 0 reg 0 status: b 0 0 0
