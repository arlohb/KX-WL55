
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

; Loop until a key is released
; Return: A - ASCII char
; Locals: X - Row
;         B - Col
;         A - Col mask
;         SCRATCH - Keybuf output row
getch:
    JSR update_keybuf

    LDX #0

.getch_loop
    LDAB #0

    LDAA KEYBUF_PREV,X
    COMA
    ANDA KEYBUF_NEXT,X
    STAA SCRATCH

    LDAA #$80

.getch_loop_col
    PSHA
    ANDA SCRATCH
    BNE .getch_key
    PULA

    LSRA
    INCB
    CMPB #8
    BNE .getch_loop_col

    INX
    CPX #9
    BNE .getch_loop

    BRA getch

.getch_key
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

    RTS

setup_keybuf:
    LDAA #$ff
    LDX #18

.keybuf_loop
    DEX
    STAA KEYBUF_PREV,X

    CPX #$01
    BNE .keybuf_loop

    RTS

update_keybuf:
    JSR keybuf_copy_next_prev
    JSR read_keybuf_next
    RTS

keybuf_copy_next_prev:
    LDX #0

.keybuf_copy_loop:
    LDAA KEYBUF_NEXT,X
    STAA KEYBUF_PREV,X

    INX
    CPX #9
    BNE .keybuf_copy_loop

    RTS

read_keybuf_next:
    LDX #0

.read_keybuf_next_loop
    PSHX
    PSHX
    PULA
    PULA
    JSR read_keybuf_row
    PULX

    INX
    CPX #9
    BNE .read_keybuf_next_loop

    RTS

; Params: A - row to scan, 0-8
read_keybuf_row:
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

print_keybuf:
    LDAA #0
    LDAB #0
    JSR set_cursor_pos

    LDX #0

.print_keybuf_loop
    PSHX
    PSHX
    PULA
    PULA
    LDAB #0
    JSR set_cursor_pos
    PULX

    LDAA KEYBUF_PREV,x
    JSR put_bin
    LDAA #'     ; space
    JSR putch
    LDAA KEYBUF_NEXT,x
    JSR put_bin
    LDAA #'     ; space
    JSR putch

    LDAA KEYBUF_PREV,x
    COMA
    ANDA KEYBUF_NEXT,x
    JSR put_bin

    INX
    CPX #9
    BNE .print_keybuf_loop

    RTS

