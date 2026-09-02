
; | Row | 7 | 6 | 5         | 4     | 3   | 2     | 1           | 0    |
; |-----|---|---|-----------|-------|-----|-------|-------------|------|
; | 0   | M |   | ↑         | space | R󰘶  | code  | quick erase | <->  |
; | 1   | - | B | print     | →     | ←   | reloc | ↓           | tab  |
; | 2   | N | V | next page | ,     | .   | alt   | /           | caps |
; | 3   | J | G | help      | 󰌑     | ÷   |       | @           | L󰘶   |
; | 4   | H | F | menu      | K     | L   |       | ;           | 1    |
; | 5   | U | T | C         | 󰁮     | 󱦒   | X     | []          | Z    |
; | 6   | Y | R | D         | I     | O   | S     | P           | A    |
; | 7   | 7 | 5 | E         | =     | <-- | W     | -->         | Q    |
; | 8   | 6 | 4 | 3         | 8     | 9   | 2     | 0           |      |

;Special keycodes
;$80 - invalid key
;$81 - shift (but we don't use this to recognise if we're shifted)
KEYCHARS:
    BYTE  'M,$80,$80, ' ,$81,$80,$80,$0C
    BYTE  '-, 'B,$80,$80,$80,$80,$80,$80
    BYTE  'N, 'V,$80, ',, '.,$80, '/,$80
    BYTE  'J, 'G,$80,$0D,$80,$80, '@,$81
    BYTE  'H, 'F,$80, 'K, 'L,$80, ';, '1
    BYTE  'U, 'T, 'C,$7F,$80, 'X, '], 'Z
    BYTE  'Y, 'R, 'D, 'I, 'O, 'S, 'P, 'A
    BYTE  '7, '5, 'E, '=,$80, 'W,$80, 'Q
    BYTE  '6, '4, '3, '8, '9, '2, '0,$80

;Shifted
KEYCHARS_S:
    BYTE  'm,$80,$80, ' ,$81,$80,$80,$0C
    BYTE  '#, 'b,$80,$80,$80,$80,$80,$80
    BYTE  'n, 'v,$80, '<, '>,$80, '?,$80
    BYTE  'j, 'g,$80,$0D,$80,$80, '%,$81
    BYTE  'h, 'f,$80, 'k, 'l,$80, ':, '!
    BYTE  'u, 't, 'c,$7F,$80, 'x, '[, 'z
    BYTE  'y, 'r, 'd, 'i, 'o, 's, 'p, 'a
    BYTE  '&, '^, 'e, '+,$80, 'w,$80, 'q
    BYTE  '_, '$, '*, '', '(, '", '),$80

; Function: keyb_shifted
; We're shifted if bit 3 of row 0 is pressed, or bit 0 or row 3
; Returns: Z flag not set if we're shifted (so BNE after for shifted)
;
; Internal _shifted version doesn't update keybuf, because the caller does
keyb_shifted:
    PSHX
    JSR _update_keybuf
    PULX
_shifted:
    PSHA
    PSHB
    LDAA KEYBUF_NEXT
    COMA
    ANDA #$08
    LDAB KEYBUF_NEXT+3
    COMB
    ANDB #$01
    ABA
    PULB
    PULA
    RTS

; Function: keyb_escape
; Escape is pressed if bit 5 of row 4 is pressed
; Returns: Z flag not set if escape pressed (do BNE after for escape pressed)
keyb_escape:
    PSHX
    PSHA
    JSR _update_keybuf
    LDAA KEYBUF_NEXT+4
    COMA
    ANDA #$20
    PULA
    PULX
    RTS

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

    JSR _shifted
    BNE .shifted
    LDX #KEYCHARS
    BRA .cont
.shifted
    LDX #KEYCHARS_S
.cont
    ABX
    LDAA 0,X

    ; Invalid or control key
    PSHA
    ANDA #$80
    PULA
    BNE .loop

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

