!rand
CLC

LDM 0
DAA
XCH 0

LDM 2
DAA
XCH 1

LDM 5
DAA
XCH 2

LDM 9
DAA
XCH 3

LDM 10
DAA
XCH 4

LDM 15
DAA
XCH 5

STC

LDM 0
DAA
XCH 6

LDM 3
DAA
XCH 7

LDM 9
DAA
XCH 8

LDM 10
DAA
XCH 9

!expect register  0: 0x0
!expect register  1: 0x2
!expect register  2: 0x5
!expect register  3: 0x9
!expect register  4: 0x0
!expect register  5: 0x5

!expect register  6: 0x6
!expect register  7: 0x9
!expect register  8: 0xf
!expect register  9: 0x0

