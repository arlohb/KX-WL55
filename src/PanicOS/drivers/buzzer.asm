
; Function: buzz
; Runs the buzzer for X cycles
; Takes ~1ms per loop,
; making this ~1000Hz, but actually it is lower as not all instructions are counted
; Parameters: X - num of cycles
; Returns: None
buzz:
    PSHA
    PSHB

.loop
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
    BNE .loop

    PULB
    PULA
    RTS

