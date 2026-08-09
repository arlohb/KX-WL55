; Driver for SED1330 LCD dot-matrix display controller

; Screen characteristics
SCREEN_PIXELS_X = 480
SCREEN_PIXELS_Y = 128
CHAR_PIXELS_X = 6  ; 5x7 font, one horiz pixel spacing
CHAR_PIXELS_Y = 8 ; 5x7 font, one vert pixel spacing
SCREEN_TEXT_COLS = SCREEN_PIXELS_X/CHAR_PIXELS_X
SCREEN_TEXT_ROWS = SCREEN_PIXELS_Y/CHAR_PIXELS_Y

; LCD controller commands
LCD_SYSTEM_SET  = $40
LCD_SLEEP_IN    = $53
LCD_DISP_ON     = $59
LCD_DISP_OFF    = $58
LCD_SCROLL      = $44
LCD_CSRFORM     = $5D
LCD_CGRAM_ADR   = $5C
LCD_CSRDIR_RIGHT= $4C
LCD_HDOT_SCR    = $5A
LCD_OVLAY       = $5B
LCD_CSRW        = $46
LCD_MWRITE      = $42

; Function: lcd_init
; Initialised the LCD hardware module
; Parameters: None
; Returns: None
    SUBROUTINE
lcd_init:
    PSHA
    PSHB
    LDAA #LCD_SYSTEM_SET
    STAA LCD10
    LDAA #$14   ; DR=0, T/L=0, IV=0, W/S=0, M2=1, M1=0,
                ; M0=0 (Internal CG ROM)
    STAA LCD00
    LDAA #$80+(CHAR_PIXELS_X-1)  ; WF=1, FX=5 (Char field width 6)
    STAA LCD00
    LDAA #(CHAR_PIXELS_Y-1)      ; FY=7 (Char field height 8)
    STAA LCD00
    LDAA #(SCREEN_TEXT_COLS-1)   ; C/R (80 character bytes per line)
    STAA LCD00
    LDAA #$59                    ; TC/R (line length incl. blanking)
    STAA LCD00
    LDAA #(SCREEN_PIXELS_Y-1)    ; L/F (128 pixel lines per frame)
    STAA LCD00
    LDAA #(SCREEN_TEXT_COLS)     ; APL (Horizontal address range: 80 addresses per line)
    STAA LCD00
    LDAA #$00                    ; APH
    STAA LCD00

    LDAA #LCD_CGRAM_ADR   ; (not sure we're using currently)
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$F0   ; Reserve $F000 upwards
    STAA LCD00

    JSR _lcd_scroll_init

    LDAA #LCD_HDOT_SCR
    STAA LCD10
    LDAA #$00
    STAA LCD00

    LDAA #LCD_OVLAY
    STAA LCD10
    ; LDAA #$01
    LDAA #$03   ; OV=0 two-layer composition, DM2=0: screen block 3 is text, DM1=0: screen block 1 is text, MX10=3 Prioritised-OR overlay
    STAA LCD00

    LDAA #LCD_DISP_OFF
    STAA LCD10
    LDAA #$56   ; FP54=1 - screen block 3 on, FP32=1 - screen block 2 on, FP10=1 - screen block 1 on, FC10=0b10 - flash cursor at ~2Hz
    STAA LCD00

    LDAA #LCD_CSRFORM
    STAA LCD10
    LDAA #$05   ; CRX: width 6 pixels
    STAA LCD00
    LDAA #$06   ; CM=0 line cursor, CRY=6: at 7th line from top (level with bottom of char)
    STAA LCD00

    LDAA #LCD_CSRDIR_RIGHT
    STAA LCD10

    LDAA #LCD_DISP_ON
    STAA LCD10

    LDAA #LCD_MWRITE
    STAA LCD10
    JSR _cls
    LDD  #0
    JSR lcd_set_cursor_pos
    PULB
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
    CMPA #(SCREEN_TEXT_ROWS-1)
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
    LDAA #LCD_CSRW
    STAA LCD10
    PULA

    STAB LCD00
    STAA LCD00

    LDAA #LCD_MWRITE
    STAA LCD10
    RTS

; Function: lcd_enable
; Enables an already-initialised LCD module
; Parameters: None
; Returns: None
    SUBROUTINE
lcd_enable:
    PSHA
    LDAA #LCD_DISP_ON
    STAA LCD10
    LDAA #LCD_MWRITE
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
    LDAA #LCD_DISP_OFF
    STAA LCD10
    LDAA #LCD_MWRITE
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
    INC SCROLL_LINES
    LDAA SCROLL_LINES
    CMPA #SCREEN_TEXT_ROWS
    BLT .no_reset
    JSR _lcd_scroll_init
    BRA .reset_done
.no_reset
    JSR _set_scroll_regs
.reset_done
    JSR _get_cursor_pos
    CLRB
    JSR lcd_set_cursor_pos
    LDX #SCREEN_TEXT_COLS
    JSR _lcd_spaces
    JSR _restore_cursor_pos
    PULX
    RTS

; Function: _lcd_scroll_init
; Set initial values for screen scroll addresses
; Parameters: None
; Returns: None
; NOTE: Assumes caller saves A
    SUBROUTINE
_lcd_scroll_init:
    LDAA #0
    STAA SCROLL_LINES
    LDAA #LCD_SCROLL
    STAA LCD10
    LDAA #$00   ; SAD1L
    STAA LCD00
    LDAA #$00   ; SAD1H
    STAA LCD00
    LDAA #(SCREEN_PIXELS_Y-1)   ; SL1
    STAA LCD00
    LDAA #$00   ; SAD2L
    STAA LCD00
    LDAA #$10   ; SAD2H
    STAA LCD00
    LDAA #(SCREEN_PIXELS_Y-1)   ; SL2
    STAA LCD00
    LDAA #$00   ; SAD3L
    STAA LCD00
    LDAA #$00   ; SAD3H
    STAA LCD00
    RTS

; Function: _set_scroll_regs
; Sets and stores the scroll register for LCD text layer
; Parameters: A - scroll lines value, 0 if not scrolled, +1 for each line, up to 13
; Returns: None
    SUBROUTINE
_set_scroll_regs:
    STAA SCROLL_LINES
    LDAA #LCD_SCROLL
    STAA LCD10
    LDAA SCROLL_LINES
    LDAB #(SCREEN_TEXT_COLS)
    MUL
    STAB LCD00  ;SAD1L
    STAA LCD00  ;SAD1H
    LDAA #(SCREEN_TEXT_ROWS)
    SUBA SCROLL_LINES
    LDAB #(CHAR_PIXELS_Y)
    MUL
    STAB LCD00
    LDAA #LCD_MWRITE
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
    CMPA #SCREEN_TEXT_COLS
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
    JSR _lcd_scroll_init
    LDD #0
    JSR lcd_set_cursor_pos
    LDX #(SCREEN_TEXT_COLS*SCREEN_TEXT_ROWS)
    JSR _lcd_spaces

    LDAA #LCD_CSRW  ; Graphics at address $1000
    STAA LCD10
    LDAA #0
    STAA LCD00
    LDAA #$10
    STAA LCD00

    LDAA #LCD_MWRITE
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
    ADDA SCROLL_LINES
    CMPA #16
    BLT .not_scrolled
    SUBA #16
.not_scrolled
    LDAB #80
    MUL
    XGDX
    PULB
    ABX
    XGDX
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

; Function: lcd_print
; Print a null-terminated string to the screen
; Parameters: X - string addr
; Returns: None
    SUBROUTINE
lcd_print:
    PSHA
.print
    LDAA 0,X
    BEQ .end
    JSR lcd_putch
    INX
    JMP .print
.end
    PULA
    RTS

; Function: lcd_println
; Print a null-terminated string to the screen with a newline
; Parameters: X - string addr
; Returns: None
    SUBROUTINE
lcd_println:
    PSHA
    JSR lcd_print
    LDAA #13
    JSR lcd_putch
    PULA
    RTS

