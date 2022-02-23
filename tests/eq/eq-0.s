!rand
a = 7
b = 9
c = 1
d = 11
LDM a 
XCH 0
LDM b
XCH 1
LDM c
XCH 2
LDM d

!expect register  0: 0x7
!expect register  1: 0x9
!expect register  2: 0x1
!expect accumulator: 0xb

