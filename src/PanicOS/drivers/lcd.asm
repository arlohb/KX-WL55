/cls
init_lcd:
    LDAA #$40
    STAA LCD10
    ; LDAA #$15
    LDAA #$14   ; internal CG ROM
    STAA LCD00
    LDAA #$85
    STAA LCD00
    LDAA #$08
    STAA LCD00
    LDAA #$4F
    STAA LCD00
    LDAA #$59
    STAA LCD00
    LDAA #$81
    STAA LCD00
    LDAA #$50
    STAA LCD00
    LDAA #$00
    STAA LCD00

    LDAA #$5C
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$F0
    STAA LCD00

    LDAA #$44   ; SCROLL
    STAA LCD10
    LDAA #$00   ; SAD1L
    STAA LCD00
    LDAA #$00   ; SAD1H
    STAA LCD00
    LDAA #$80   ; SL1
    STAA LCD00
    LDAA #$00   ; SAD2L
    STAA LCD00
    LDAA #$10   ; SAD2H
    STAA LCD00
    LDAA #$80   ; SL2
    STAA LCD00

    LDAA #$5A
    STAA LCD10
    LDAA #$00
    STAA LCD00

    LDAA #$5B   ; OVLAY
    STAA LCD10
    ; LDAA #$01
    LDAA #$03   ; Prioritised-OR overlay
    STAA LCD00

    LDAA #$58
    STAA LCD10
    LDAA #$16
    STAA LCD00

    LDAA #$46
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$00
    STAA LCD00

    LDAA #$5D
    STAA LCD10
    LDAA #$05
    STAA LCD00
    LDAA #$87
    STAA LCD00

    LDAA #$4C
    STAA LCD10

    LDAA #$59
    STAA LCD10

    LDAA #$46
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$00
    STAA LCD00

    LDAA #$42
    STAA LCD10
    JSR cls
    LDAA #$46
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$00
    STAA LCD00
    LDAA #$42
    STAA LCD10
    RTS

    SUBROUTINE
set_scroll_reg:
    PSHA
    LDAA #$44
    STAA LCD10
    PULA
    STD SCROLL_REG
    STAB LCD00
    STAA LCD00
    LDAA #$42
    STAA LCD10
    RTS

    SUBROUTINE
scroll_lcd_up:
    LDD SCROLL_REG
    ADDD #80
    JSR set_scroll_reg
    JSR get_cursor_pos
    CLRB
    JSR set_cursor_pos
    LDX #$160
    JSR lcd_spaces
    JSR restore_cursor_pos
    RTS

    SUBROUTINE
inc_cur_pos:
    LDAA CURPOS_COL
    INCA
    CMPA #80
    BLT .done
    ; new line
    INC CURPOS_ROW
    CLRA
.done
    STAA CURPOS_COL
    RTS

; Params: X - number of spaces to output
    SUBROUTINE
lcd_spaces:
    LDAA #$20
.loop:
    STAA LCD00
    DEX
    BNE .loop
    RTS

    SUBROUTINE
cls:
    LDD #0
    JSR set_scroll_reg
    LDD #0
    JSR set_cursor_pos
    LDX #1200       ;15 lines * 80 chars per line
    JSR lcd_spaces

    LDAA #$46
    STAA LCD10
    LDAA #0
    STAA LCD00
    LDAA #$10
    STAA LCD00

    LDAA #$42
    STAA LCD10
    LDAA #$00
    LDX #10480       ;131 lines * 80 bytes per line
.clg_loop:
    STAA LCD00
    DEX
    BNE .clg_loop

    LDD #0
    JSR set_cursor_pos
    RTS


; Params: A - row num
;         B - col num
; Return: D - cursor addr
    SUBROUTINE
calc_cursor_addr:
    PSHB
    LDAB #80
    MUL
    XGDX
    PULB
    ABX
    XGDX
    ADDD SCROLL_REG

    RTS

; Params: A - row num
;         B - col num
set_cursor_pos:
    STD CURPOS_RC
    JSR calc_cursor_addr

    PSHA
    LDAA #$46
    STAA LCD10
    PULA

    STAB LCD00
    STAA LCD00

    LDAA #$42
    STAA LCD10
    RTS

; Returns:  A - row num
;           B - col num
    SUBROUTINE
get_cursor_pos:
    LDD  CURPOS_RC
    RTS

    SUBROUTINE
restore_cursor_pos:
    JSR get_cursor_pos
    JSR set_cursor_pos
    RTS

    SUBROUTINE
enable_lcd:
    LDAA #$59
    STAA LCD10
    LDAA #$42
    STAA LCD10
    RTS

disable_lcd:
    LDAA #$58
    STAA LCD10
    LDAA #$42
    STAA LCD10
    RTS

