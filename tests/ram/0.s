!rand
!ram
LDM 5

FIM 0P 0
SRC 0P
WRM

/ load into accumulator
SRC 0
RDM

/ write back out at several places
FIM 0P 1
SRC 0
WRM

FIM 0P 16
SRC 0
WRM
FIM 0P 31
SRC 0
WRM
FIM 0P 32
SRC 0
WRM
FIM 0P 64
SRC 0
WRM

!expect accumulator: 0x5
!expect ram 0 reg 0: 5 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0
!expect ram 0 reg 1: 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5
!expect ram 0 reg 2: 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
!expect ram 1 reg 0: 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
