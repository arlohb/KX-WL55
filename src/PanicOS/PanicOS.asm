; Test ROM to exercise some hardware and prove we can run code
    .processor HD6303

    INCLUDE "memory_map.asm"

    ORG $1C000
    RORG $C000

    INCLUDE "drivers/keyboard.asm"
    INCLUDE "drivers/lcd.asm"

reset:
    LDS #$FF

    LDX #500
    JSR delay_100_us
    LDAA #$FF
    STAA P2DDR
    LDAA #$00
    STAA PORT2

    JSR lcd_init

    JSR setup_keybuf

    PSHB
    LDAA #0
    LDAB #0
    JSR lcd_set_cursor_pos
    PULB

loop:
    JSR getch
    JSR lcd_putch

    LDX #10
    JSR delay_ms

    JMP loop

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

; Param: X is num of loops
; Takes ~1ms per loop,
; making this ~1000Hz, but actually it is lower as not all instructions are counted
buzz_loop:
    ; Buzzer on
    LDAA #$40
    STAA PORT2

    ; Delay
    PSHX
    LDX #5
    JSR delay_100_us
    PULX

    ; Buzzer off
    LDAA #$00
    STAA PORT2

    ; Delay
    PSHX
    LDX #5
    JSR delay_100_us
    PULX

    DEX
    BNE buzz_loop
    RTS

; Param: X is num of ms
delay_ms:
    PSHX
    LDX #436
    JSR delay_x
    PULX

    DEX
    BNE delay_ms
    RTS

; Param: X is num of 100 us
delay_100_us:
    PSHX
    LDX #43
    JSR delay_x
    PULX

    DEX
    BNE delay_100_us
    RTS

; Param: X is num of loops
; CPU clock is 1.75MHz (7MHz, internally divided by 4)
; Delay is 5 + 4X cycles at 1.75MHz, so ~ 2.86 + 2.29X us
delay_x:
    DEX             ;   1 cycle
    BNE delay_x     ;   3 cycles
    RTS             ;   5 cycles

stub_irq:
    RTI

    ORG $1FFEA
    RORG $FFEA

; vector table
IRQ2:   ds.w 1,stub_irq ; FFEA
CMI:    ds.w 1,stub_irq ; FFEC
TRAP:   ds.w 1,reset    ; FFEE
SIO:    ds.w 1,stub_irq ; FFF0
TOI:    ds.w 1,stub_irq ; FFF2
OCI:    ds.w 1,stub_irq ; FFF4
ICI:    ds.w 1,stub_irq ; FFF6
IRQ1:   ds.w 1,stub_irq ; FFF8
SWI:    ds.w 1,stub_irq ; FFFA
NMI:    ds.w 1,stub_irq ; FFFC
RESET:  ds.w 1,reset    ; FFFE
