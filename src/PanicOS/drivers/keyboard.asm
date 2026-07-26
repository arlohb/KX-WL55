
; | Row | 7 | 6 | 5         | 4     | 3   | 2     | 1           | 0    |
; |-----|---|---|-----------|-------|-----|-------|-------------|------|
; | 1   | M |   | ↑         | space | R󰘶  | code  | quick erase | <->  |
; | 2   | - | B | print     | →     | ←   | reloc | ↓           | tab  |
; | 3   | N | V | next page | ,     | .   | alt   | /           | caps |
; | 4   | J | G | help      | 󰌑     | ÷   |       | @           | L󰘶   |
; | 5   | H | F | menu      | K     | L   |       | ;           | 1    |
; | 6   | U | T | C         | 󰁮     | 󱦒   | X     | []          | Z    |
; | 7   | Y | R | D         | I     | O   | S     | P           | A    |
; | 8   | 7 | 5 | E         | =     | <-- | W     | -->         | Q    |
; | 9   | 6 | 4 | 3         | 8     | 9   | 2     | 0           |      |

KEYCHARS:
    BYTE 'M,'_,'_,' ,'_,'_,'_,$C
    BYTE '_,'B,'_,'_,'_,'_,'_,'_
    BYTE 'N,'V,'_,',,'.,'_,'/,'_
    BYTE 'J,'G,'_,$D,'_,'_,'@,'_
    BYTE 'H,'F,'_,'K,'L,'_,';,'1
    BYTE 'U,'T,'C,'_,'_,'X,'[,'Z
    BYTE 'Y,'R,'D,'I,'O,'S,'P,'A
    BYTE '7,'5,'E,'=,'_,'W,'_,'Q
    BYTE '6,'4,'3,'8,'9,'2,'0,'_

; Function: keyb_getch
; Loop until a key is released, return the ASCII value
; Parameters: None
; Returns: A - ASCII char
; Locals: X - Row
;         B - Col
;         A - Col mask
;         SCRATCH - Keybuf output row
    SUBROUTINE
keyb_getch:
    PSHB
    PSHX

.loop
    JSR _update_keybuf

    LDX #0

.loop_row
    LDAB #0

    LDAA KEYBUF_PREV,X
    COMA
    ANDA KEYBUF_NEXT,X
    STAA SCRATCH

    LDAA #$80

.loop_col
    PSHA
    ANDA SCRATCH
    BNE .got_key
    PULA

    LSRA
    INCB
    CMPB #8
    BNE .loop_col

    INX
    CPX #9
    BNE .loop_row

    BRA .loop

.got_key
    ; Pop stack, but we don't use this value
    PULA
    ; At this point, X is row, B is col

    XGDX
    LDAA #8
    MUL
    PSHX
    PULA
    PULA
    ABA
    TAB

    LDX #KEYCHARS
    ABX
    LDAA 0,X

    PULX
    PULB
    RTS

; Function: keyb_init
; Initialises the keyboard driver by setting up the buffer
; Parameters: None
; Returns: None
    SUBROUTINE
keyb_init:
    PSHA
    PSHX

    LDAA #$ff
    LDX #18

.loop
    DEX
    STAA KEYBUF_PREV,X

    CPX #$01
    BNE .loop

    PULX
    PULA
    RTS

; Function: _update_keybuf
; Maintains two copies of the keyboard hardware state.
; Copies the old values into KEYBUF_PREV and reads the
; latest state into KEYBUF_NEXT.
; Parameters: None
; Returns: None
; NOTE: Assumes caller saves A,B,X regs
    SUBROUTINE
_update_keybuf:
    JSR _keybuf_copy_next_prev
    JSR _read_keybuf_next
    RTS

; Function: _keybuf_copy_next_prev
; Copies the old values from KEYBUF_NEXT to KEYBUF_PREV
; Parameters: None
; Returns: None
; NOTE: Assumes caller saves A,X regs
    SUBROUTINE
_keybuf_copy_next_prev:
    LDX #0

.loop:
    LDAA KEYBUF_NEXT,X
    STAA KEYBUF_PREV,X

    INX
    CPX #9
    BNE .loop

    RTS

; Function: _read_keybuf_next
; Reads the current keyboard hardware state into KEYBUF_NEXT
; Parameters: None
; Returns: None
; NOTE: Assumes caller saves A,B,X regs
    SUBROUTINE
_read_keybuf_next:
    LDX #0

.loop
    PSHX
    PSHX
    PULA
    PULA
    JSR _read_keybuf_row
    PULX

    INX
    CPX #9
    BNE .loop

    RTS

; Function: _read_keybuf_row
; Reads a keyboard scan row and stores it in appropriate byte
; of the KEYBUF_NEXT buffer
; Params: A - row to scan, 0-8
; NOTE: Assumes caller saves B,X regs
_read_keybuf_row:
    PSHA
    LDAB #0
    PSHB

    INCA
    STAA KEYSCAN

    LDX #10
    JSR delay_100_us

    LDAA KEYMATRIX
    PULX
    STAA KEYBUF_NEXT,x

    RTS

