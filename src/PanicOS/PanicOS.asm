; Test ROM to exercise some hardware and prove we can run code
    .processor HD6303

    INCLUDE "memory_map.asm"

    ORG $1C000
    RORG $C000

    INCLUDE "drivers/keyboard.asm"
    INCLUDE "drivers/lcd.asm"
    INCLUDE "drivers/buzzer.asm"
    INCLUDE "time/delay.asm"

    INCLUDE "applications/mikbug.asm"
    INCLUDE "forth/forth.asm"

START_MENU
    DC #13
    DC  "        (F) Forth        (M) Mikbug        (D) Display Loop"
    DC 0

reset:
    LDS #$FF

    LDX #500
    JSR delay_100_us
    LDAA #$FF
    STAA P2DDR
    LDAA #$00
    STAA PORT2

    JSR lcd_init

    JSR keyb_init

    PSHB
    LDAA #0
    LDAB #0
    JSR lcd_set_cursor_pos
    PULB

    LDX #START_MENU
    JSR lcd_println

menu_loop:
    JSR keyb_getch

    CMPA #70 ; F
    BEQ menu_forth
    CMPA #77 ; M
    BEQ menu_mikbug
    CMPA #68 ; D
    BEQ display_loop

    BRA menu_loop

menu_mikbug:
    JMP mikbug_start

menu_forth:
    JMP ORIG

display_loop:
    JSR keyb_getch
    JSR lcd_putch

    LDX #10
    JSR delay_ms

    JMP display_loop

; Params: A - prints lower 4 bits as hex char
put_hex_nibble:
    CMPA #9
    BGT .letter
    ADDA #48
    BRA .print
.letter
    ADDA #55
.print
    JSR lcd_putch
    RTS

; Params: A - byte to print as hex
    SUBROUTINE
put_hex:
    PSHA
    ANDA #$f0
    LSRA
    LSRA
    LSRA
    LSRA
    JSR put_hex_nibble
    PULA

    ANDA #$0f
    JSR put_hex_nibble
    RTS

; Params: D - word to print as hex
    SUBROUTINE
put_hex_word:
    JSR put_hex
    TBA
    JSR put_hex
    RTS

; Params: A - byte to print as binary
put_bin:
V   SET $80
U   SET 7
    REPEAT 8
        PSHA
        ANDA #V
        REPEAT U
            LSRA
        REPEND
        ADDA #48
        JSR lcd_putch
        PULA
V   SET V/2
U   SET U-1
    REPEND

    RTS

print_keybuf:
    LDAA #0
    LDAB #0
    JSR lcd_set_cursor_pos

    LDX #0

.print_keybuf_loop
    PSHX
    PSHX
    PULA
    PULA
    LDAB #0
    JSR lcd_set_cursor_pos
    PULX

    LDAA KEYBUF_PREV,x
    JSR put_bin
    LDAA #'     ; space
    JSR lcd_putch
    LDAA KEYBUF_NEXT,x
    JSR put_bin
    LDAA #'     ; space
    JSR lcd_putch

    LDAA KEYBUF_PREV,x
    COMA
    ANDA KEYBUF_NEXT,x
    JSR put_bin

    INX
    CPX #9
    BNE .print_keybuf_loop

    RTS

stub_irq:
    RTI

    ORG $1FFEA
    RORG $FFEA

; vector table
IRQ2:   ds.w 1,stub_irq ; FFEA
CMI:    ds.w 1,stub_irq ; FFEC
TRAP:   ds.w 1,mikbug_trap    ; FFEE
SIO:    ds.w 1,stub_irq ; FFF0
TOI:    ds.w 1,stub_irq ; FFF2
OCI:    ds.w 1,stub_irq ; FFF4
ICI:    ds.w 1,stub_irq ; FFF6
IRQ1:   ds.w 1,stub_irq ; FFF8
SWI:    ds.w 1,mikbug_swi ; FFFA
NMI:    ds.w 1,stub_irq ; FFFC
RESET:  ds.w 1,reset    ; FFFE
