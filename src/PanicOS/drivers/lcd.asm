; Function: lcd_init
; Initialised the LCD hardware module
; Parameters: None
; Returns: None
    SUBROUTINE
lcd_init:
    PSHA
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
    PULA
    RTS

; Function: lcd_putch
; Outputs an ASCII character to the LCD, including control chars
; Parameters: A - character to print
; Returns: None
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
    PSHB
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
    PULB
    RTS

; Function: lcd_set_cursor_pos
; Sets the LCD module cursor position in text mode,
; then returns to MWRITE mode.
; Parameters: A - row num, B - col num
; Returns: None
    SUBROUTINE
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

; Function: lcd_enable
; Enables an already-initialised LCD module
; Parameters: None
; Returns: None
    SUBROUTINE
lcd_enable:
    PSHA
    LDAA #$59
    STAA LCD10
    LDAA #$42
    STAA LCD10
    PULA
    RTS

; Function: lcd_disable
; Disables the LCD module
; Parameters: None
; Returns: None
    SUBROUTINE
lcd_disable:
    PSHA
    LDAA #$58
    STAA LCD10
    LDAA #$42
    STAA LCD10
    PULA
    RTS

; Function: _lcd_scroll_up
; Scroll the LCD text layer up one line
; Parameters: None
; Returns: None
; NOTE: Assumes that caller saves A,B regs
    SUBROUTINE
_lcd_scroll_up:
    PSHX
    LDD SCROLL_REG
    ADDD #80
    JSR _set_scroll_reg
    JSR _get_cursor_pos
    CLRB
    JSR lcd_set_cursor_pos
    LDX #$160
    JSR _lcd_spaces
    JSR _restore_cursor_pos
    PULX
    RTS

; Function: _set_scroll_reg
; Sets and stores the scroll register for LCD text layer
; Parameters: D - scroll register value
; Returns: None
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

; Function: _inc_cur_pos
; Increments and stores the text layer cursor position, moving
; to new line if necessary.
; Parameters: None
; Returns: None
; NOTE: Assumes caller saves A reg
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

; Function: _lcd_spaces
; Outputs a number of spaces to the LCD text layer
; Parameters: X - number of spaces to output
; Returns: None
; NOTE: Assumes caller saves A reg
    SUBROUTINE
_lcd_spaces:
    LDAA #$20
.loop:
    STAA LCD00
    DEX
    BNE .loop
    RTS

; Function: cls
; Clears both the text and graphics layers
; Parameters: None
; Returns: None
    SUBROUTINE
_cls:
    PSHA
    PSHB
    PSHX
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
    PULX
    PULB
    PULA
    RTS

; Function: _calc_cursor_addr
; Calculates the text layer cursor address given the row and col
; Parameters: A - row num, B - col num
; Returns: D - cursor addr
    SUBROUTINE
_calc_cursor_addr:
    PSHX
    PSHB
    LDAB #80
    MUL
    XGDX
    PULB
    ABX
    XGDX
    ADDD SCROLL_REG
    PULX
    RTS

; Function: _get_cursor_pos
; Get the current cursor position of the LCD text layer
; We can't get this from the LCD module, so we store it whenever
; we change it.
; Parameters: None
; Returns:  A - row num, B - col num
    SUBROUTINE
_get_cursor_pos:
    LDD  CURPOS_RC
    RTS

; Function: _restore_cursor_pos
; Reset the text layer cursor so it matches what we have stored
; Parameters: None
; Returns: None
; NOTE: Assumes that caller saves A,B regs
    SUBROUTINE
_restore_cursor_pos:
    JSR _get_cursor_pos
    JSR lcd_set_cursor_pos
    RTS

