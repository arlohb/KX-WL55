; Function: delay_ms
; Delay some number of ms.
; Parameters: X is number of ms to delay
; Returns: None
    SUBROUTINE
delay_ms:
    PSHX
    LDX #436
    JSR _delay_x
    PULX

    DEX
    BNE delay_ms
    RTS

; Function: delay_100_us
; Delay some multiple of 100us
; Parameters: X is num of 100us, e.g. 3 for 300us delay
; Returns: None
    SUBROUTINE
delay_100_us:
    PSHX
    LDX #43
    JSR _delay_x
    PULX

    DEX
    BNE delay_100_us
    RTS

; Function: delay_x
; Delay a specific number of cycles of this loop.
; CPU clock is 1.75MHz (7MHz, internally divided by 4)
; Delay is 5 + 4X cycles at 1.75MHz, so ~ 2.86 + 2.29X us
; Parameters: X - num of loops
; Returns: None
    SUBROUTINE
_delay_x:
    DEX             ;   1 cycle
    BNE _delay_x    ;   3 cycles
    RTS             ;   5 cycles
