!rand

/ select rom 0
FIM 0P 0
SRC 0P

/ write 3 to rom 0's output port
LDM 3
WRR

/ select rom 1
FIM 0P 16
SRC 0P

/ write 4 to rom 1's output port
LDM 4
WRR

!expect accumulator: 0x4
!expect rom 0 port: 0x3
!expect rom 1 port: 0x4
