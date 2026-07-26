    SEG.U IO
    ORG $0
P1DDR: ds.b 1
P2DDR: ds.b 1
PORT1: ds.b 1
PORT2: ds.b 1

    SEG.U INT_RAM
    ORG $0040
KEYBUF_PREV: ds.b 9
KEYBUF_NEXT: ds.b 9

CURPOS_RC:
CURPOS_ROW:  ds.b 1
CURPOS_COL:  ds.b 1

SCROLL_REG: ds.w 1

SCRATCH: ds.b 1

; MIKBUG application RAM
SP      ds.b    1         ;S-HIGH
        ds.b    1         ;S-LOW

XHI     ds.b    1         ;XREG HIGH
XLOW    ds.b    1         ;XREG LOW
        ds.b    46
STACK   ds.b    1         ;STACK POINTER


;       OPT    MEMORY
        ORG    $E000
    SEG.U KEYSCAN
    ORG $0400
KEYSCAN: ds.b 1

    SEG.U KEYMATRIX
    ORG $0410
KEYMATRIX: ds.b 1

    SEG.U LCD
    ORG $0A00
LCD00: ds.b 16
LCD10: ds.b 16

    SEG TEXT
    ORG $0
    ds.b 1,$ff
