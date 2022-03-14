!rand
!romport 0,5
!romport 1,7

/ select rom 0
FIM 7P 0
SRC 7P

/ read the io port into register 0
RDR
XCH 0

/ select rom 1
FIM 7P 16
SRC 7P

/ read the io port into register 1
RDR
XCH 1

!expect rom 0 port: 0x5
!expect register  0: 0x5
!expect rom 1 port: 0x7
!expect register  1: 0x7
