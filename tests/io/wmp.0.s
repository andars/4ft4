!rand
!ram
/ select ram bank 0
LDM 0
DCL

/ write 7 to ram 0's output port
FIM 0P 0
SRC 0P
LDM 7
WMP

/ write 9 to ram 1's output port
FIM 0P 64
SRC 0P
LDM 9
WMP

!expect accumulator: 0x9
!expect ram 0 port: 0x7
!expect ram 1 port: 0x9

