!ram
CLC

/ register 0,1 -> address
/ register 2,3 -> x
/ register 4,5 -> y

FIM 0P 0
FIM 1P 0
FIM 2P 1


/ write F_0
SRC 0P
LD 3
WRM
INC 1
SRC 0P
LD 2
WRM
INC 1

/ write F_1
SRC 0P
LD 5
WRM
INC 1
SRC 0P
LD 4
WRM
INC 1

LDM 14
XCH 14

/ load index
LDM 10
XCH 15
L0,

/ write F_{2..15}
LP,
SRC 0P

CLC
/ add low word, put it in reg 7 and current ram location
LD 3
ADD 5
WRM
XCH 7
INC 1
SRC 0P

/ add high word (with carry), put it in reg 6
LD 2
ADD 4
WRM
XCH 6
INC 1
SRC 0P

/ put {4, 5} into {2,3}
LD 5
XCH 3
LD 4
XCH 2

/ put {6, 7} into {4,5}
LD 7
XCH 5
LD 6
XCH 4

ISZ 15 LP

/ reset inner index for 8 iterations
LDM 8
XCH 15

INC 0

ISZ 14 L0

!expect ram 0 reg 0: 0 0 1 0 1 0 2 0 3 0 5 0 8 0 d 0
!expect ram 0 reg 1: 5 1 2 2 7 3 9 5 0 9 9 e 9 7 2 6

/LI,
/JUN LI
/
/F(0) = 0
/F(1) = 1
/F(i) = F(i-1) + F(i-2)
/
/int x = 0;
/int y = 0;
/int buf[N];
/buf[0] = 0;
/buf[1] = 1;
/for (int i = 2; i < N; i++) {
/    buf[i] = buf[i-1] + buf[i-2];
/}
/
/
/int x = 0;
/int y = 1;
/int buf[N];
/buf[0] = x;
/buf[1] = y;
/
/for (int i = 2; i < N; i++) {
/    next = x + y;
/    write next to buf[i]
/    x = y;
/    y = next;
/}
