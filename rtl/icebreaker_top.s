S,
/ select ram 0
FIM 0P 0
SRC 0P

/ write 11 to the output port
LDM 11
WMP

/ delay loop
LDM 0
XCH 5
L5,
LDM 14
XCH 4
L4,
LDM 0
XCH 3
L3,
LDM 0
XCH 2
L2,
LDM 0
XCH 1
L1,
LDM 0
XCH 0
L0,
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
ISZ 0 L0
ISZ 1 L1
ISZ 2 L2
ISZ 3 L3
ISZ 4 L4

/ write R5 to the output port
LD 5
WMP

ISZ 5 L5

JUN S

= 511
NOP
