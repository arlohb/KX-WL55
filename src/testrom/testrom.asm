; Test ROM to exercise some hardware and prove we can run code
    .processor HD6303

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

SCRATCH: ds.b 1

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

    ORG $1C000
    RORG $C000

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
    BYTE 'M,'_,'_,' ,'_,'_,'_,'_
    BYTE '_,'B,'_,'_,'_,'_,'_,'_
    BYTE 'N,'V,'_,',,'.,'_,'/,'_
    BYTE 'J,'G,'_,'_,'_,'_,'@,'_
    BYTE 'H,'F,'_,'K,'L,'_,';,'1
    BYTE 'U,'T,'C,'_,'_,'X,'[,'Z
    BYTE 'Y,'R,'D,'I,'O,'S,'P,'A
    BYTE '7,'5,'E,'=,'_,'W,'_,'Q
    BYTE '6,'4,'3,'8,'9,'2,'0,'_

reset:
    LDS #$FF

    LDX #500
    JSR delay_100_us
    LDAA #$FF
    STAA P2DDR
    LDAA #$00
    STAA PORT2

    JSR init_lcd

    JSR setup_keybuf

    ; JSR write_text

    PSHB
    LDAA #0
    LDAB #0
    JSR set_cursor_pos
    PULB

loop:
    JSR getch
    JSR putch

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
    JSR putch
    RTS

; Params: A - byte to print as hex
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
        JSR putch
        PULA
V   SET V/2
U   SET U-1
    REPEND

    RTS

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
    LDAA #' 
    JSR putch
    LDAA KEYBUF_NEXT,x
    JSR put_bin
    LDAA #' 
    JSR putch

    LDAA KEYBUF_PREV,x
    COMA
    ANDA KEYBUF_NEXT,x
    JSR put_bin

    INX
    CPX #9
    BNE .print_keybuf_loop

    RTS

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
    LDAA #$20
    LDX #1200       ;15 lines * 80 chars per line
.cls_loop:
    STAA LCD00
    DEX
    BNE .cls_loop

    LDAA #$46
    STAA LCD10
    LDAA #$00
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

    LDAA #$46
    STAA LCD10
    LDAA #$00
    STAA LCD00
    LDAA #$00
    STAA LCD00
    LDAA #$42
    STAA LCD10
    RTS

; Params: A
putch:
    STAA LCD00
    RTS

write_text:
    LDAA #'R
    STAA LCD00
    LDAA #'E
    STAA LCD00
    LDAA #'A
    STAA LCD00
    LDAA #'D
    STAA LCD00
    LDAA #'Y
    STAA LCD00
    LDAA #$0D
    STAA LCD00

    RTS

; Params: A - row num
;         B - col num
; Return: D - cursor addr
calc_cursor_addr:
    PSHB
    LDAB #80
    MUL
    XGDX
    PULB
    ABX
    XGDX

    RTS

; Params: A - row num
;         B - col num
set_cursor_pos:
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
