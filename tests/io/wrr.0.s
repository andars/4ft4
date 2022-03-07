!rand
!ram

/ select rom 0
FIM 0P 0
SRC 0P

/ write 11 to the output port
LDM 11
WRR

!expect accumulator: 0xb
!expect rom 0 port: 0xb

