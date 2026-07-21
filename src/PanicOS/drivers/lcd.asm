
lcd_init:
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
    JSR _cls
    LDAA #$46
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$00
    STAA LCD00
    LDAA #$42
    STAA LCD10
    RTS

; Params: A - character to print
    SUBROUTINE
lcd_putch:
    CMPA #$D
    BEQ _new_line
    CMPA #$C
    BEQ .cls
    ; printable character
    STAA LCD00
    JSR _inc_cur_pos
    RTS
.cls
    JMP _cls

    SUBROUTINE
_new_line:
    JSR _get_cursor_pos
    CMPA #13
    BLT .no_scroll
    JSR _lcd_scroll_up
    BRA .done
.no_scroll
    INCA
    CLRB
    JSR lcd_set_cursor_pos
.done
    RTS

; Params: A - row num
;         B - col num
lcd_set_cursor_pos:
    STD CURPOS_RC
    JSR _calc_cursor_addr

    PSHA
    LDAA #$46
    STAA LCD10
    PULA

    STAB LCD00
    STAA LCD00

    LDAA #$42
    STAA LCD10
    RTS

    SUBROUTINE
lcd_enable:
    LDAA #$59
    STAA LCD10
    LDAA #$42
    STAA LCD10
    RTS

lcd_disable:
    LDAA #$58
    STAA LCD10
    LDAA #$42
    STAA LCD10
    RTS

    SUBROUTINE
_lcd_scroll_up:
    LDD SCROLL_REG
    ADDD #80
    JSR _set_scroll_reg
    JSR _get_cursor_pos
    CLRB
    JSR lcd_set_cursor_pos
    LDX #$160
    JSR _lcd_spaces
    JSR _restore_cursor_pos
    RTS

    SUBROUTINE
_set_scroll_reg:
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
_inc_cur_pos:
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
_lcd_spaces:
    LDAA #$20
.loop:
    STAA LCD00
    DEX
    BNE .loop
    RTS

    SUBROUTINE
_cls:
    LDD #0
    JSR _set_scroll_reg
    LDD #0
    JSR lcd_set_cursor_pos
    LDX #1200       ;15 lines * 80 chars per line
    JSR _lcd_spaces

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
    JSR lcd_set_cursor_pos
    RTS


; Params: A - row num
;         B - col num
; Return: D - cursor addr
    SUBROUTINE
_calc_cursor_addr:
    PSHB
    LDAB #80
    MUL
    XGDX
    PULB
    ABX
    XGDX
    ADDD SCROLL_REG

    RTS

; Returns:  A - row num
;           B - col num
    SUBROUTINE
_get_cursor_pos:
    LDD  CURPOS_RC
    RTS

    SUBROUTINE
_restore_cursor_pos:
    JSR _get_cursor_pos
    JSR lcd_set_cursor_pos
    RTS

