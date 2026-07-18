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
    LDAA #$FF   ; 2 cycles
    STAA P2DDR   ; 4 cycles
    LDS #$FF
; CPU clock is 1.75MHz (7MHz, internally divided by 4)
; loop total is 15 cycles, at 1.75MHz that's >110kHz, so inaudible
; with delay on mark and space, 2058+15=2073 ~844Hz
loop:
    LDAA #$40   ; 2 cycles
    STAA PORT2   ; 4 cycles
    JSR delay
    LDAA #$00   ; 2 cycles
    STAA PORT2   ; 4 cycles
    JSR delay
    JMP loop    ; 3 cycles

; total is 7 + (256*4) cycles = 1029 cycles, ~588uS at 7MHz
delay:
    LDX #256   ; 2 cycles
.delay_loop:
    DEX             ;   1 cycle
    BNE .delay_loop  ;   3 cycles
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
