; Test ROM to exercise some hardware and prove we can run code

    .processor HD6303

    SEG.U IO
    ORG $0
P1DDR: ds.b 1
P2DDR: ds.b 1
PORT1: ds.b 1
PORT2: ds.b 1

    SEG TEXT
    ORG $0
    ds.b 1,$ff

    ORG $1C000
    RORG $C000

reset:
    LDAA #$FF
    STAA P2DDR
    LDS #$FF
loop:
    LDX #500
    JSR delayMs

    LDX #500
    JSR buzz_loop

    JMP loop

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
    JSR delay100Us
    PULX

    ; Buzzer off
    LDAA #$00
    STAA PORT2

    ; Delay
    PSHX
    LDX #5
    JSR delay100Us
    PULX

    DEX
    BNE buzz_loop
    RTS

; Param: X is num of ms
delayMs:
    PSHX
    LDX #436
    JSR delayX
    PULX

    DEX
    BNE delayMs
    RTS

; Param: X is num of 100 us
delay100Us:
    PSHX
    LDX #43
    JSR delayX
    PULX

    DEX
    BNE delay100Us
    RTS

; Param: X is num of loops
; CPU clock is 1.75MHz (7MHz, internally divided by 4)
; Delay is 5 + 4X cycles at 1.75MHz, so ~ 2.86 + 2.29X us
delayX:
    DEX             ;   1 cycle
    BNE delayX      ;   3 cycles
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
