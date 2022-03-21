!rand
!romport 0,5

/ select rom 0
FIM 0P 0
SRC 0P

/ read from the io port
RDR

!expect accumulator: 0x5

/ ignore for now because the rtl testbench for rom io currently
/ will always show the output register for this
/ expect rom 0 port: 0x5
