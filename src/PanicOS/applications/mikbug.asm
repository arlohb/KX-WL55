; Obtained from https://deramp.com/swtpc.com/MP_A/mikbug.txt
; Modified to work in our project
    .processor HD6303
;        NAM    MIKBUG
;      REV 009
;      COPYRIGHT 1974 BY MOTOROLA INC
;
;      MIKBUG (TM)
;
;      G  GO TO TARGET PROGRAM
;      M  MEMORY CHANGE
;      R  DISPLAY CONTENTS OF TARGET STACK
;            CC   B   A   X   P   S



QUERY   LDAA  #'?       ;PRINT QUESTION MARK
        BSR    OUTCH
C1      JMP    CONTRL

; BUILD ADDRESS
BADDR   BSR    BYTE      ;READ 2 FRAMES
        STAA   XHI
        BSR    BYTE
        STAA   XLOW
        LDX    XHI       ;(X) ADDRESS WE BUILT
        RTS

;INPUT BYTE (TWO FRAMES)
BYTE    BSR    INHEX     ;GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR    INHEX
        ABA
        RTS

OUTHL   LSRA           ;OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA

OUTHR   ANDA  #$F       ;OUT HEX RIGHT BCD DIGIT
        ADDA  #$30
        CMPA  #$39
        BLS    OUTCH
        ADDA  #$7

; OUTPUT ONE CHAR
OUTCH   JMP     lcd_putch
INCH    JSR     keyb_getch
        CMPA    #$D
        BEQ     .no_echo
        PSHA
        JSR     lcd_putch
        PULA
.no_echo
        RTS

; PRINT DATA POINTED AT BY X-REG
PDATA2  BSR    OUTCH
        INX
PDATA1  LDAA   0,X
        CMPA   #4
        BNE    PDATA2
        RTS              ;STOP ON EOT

; CHANGE MEMORY (M AAAA DD NN)
CHANGE  BSR    BADDR     ;BUILD ADDRESS
CHA51   LDX    #MCL
        BSR    PDATA1    ;C/R L/F
        LDX    #XHI
        BSR    OUT4HS    ;PRINT ADDRESS
        LDX    XHI
        BSR    OUT2HS    ;PRINT DATA (OLD)
        STX    XHI       ;SAYE DATA ADDRESS
        BSR    INCH      ;INPUT ONE CHAR
        CMPA  #$20
        BNE    CHA51     ;NOT SPACE
        BSR    BYTE      ;INPUT NEW DATA
        DEX
        STAA   0,X         ;CHANGE MEMORY
        CMPA   0,X
        BEQ    CHA51     ;DID CHANGE
        BRA    QUERY     ;NOT CHANGED

; INPUT HEX CHAR
INHEX   BSR    INCH
        SUBA  #$30
        BMI    C1        ;NOT HEX
        CMPA  #$09
        BLE    IN1HG
        CMPA  #$11
        BMI    C1        ;NOT HEX
        CMPA  #$16
        BGT    C1        ;NOT HEX
        SUBA  #7
IN1HG   RTS

OUT2H   LDAA  0,X       ;OUTPUT 2 HEX CHAR
OUT2HA  BSR    OUTHL     ;OUT LEFT HEX CHAR
        LDAA  0,X
        INX
        BRA    OUTHR     ;OUTPUT RIGHT HEX CHAR AND R

OUT4HS  BSR    OUT2H     ;OUTPUT 4 HEX CHAR + SPACE
OUT2HS  BSR    OUT2H     ;OUTPUT 2 HEX CHAR + SPACE

OUTS    LDAA  #$20      ;SPACE
        BRA    OUTCH     ;(BSR & RTS)

; ENTER POWER  ON SEQUENCE
START   EQU    *
mikbug_start
        LDS    #STACK
        STS    SP        ;INZ TARGET'S STACK PNTR
CONTRL
        LDS    #STACK    ;SET CONTRL STACK POINTER
        LDX    #MCLOFF

        BSR    PDATA1    ;PRINT DATA STRING

        BSR    INCH      ;READ CHARACTER
        TAB
        BSR    OUTS      ;PRINT SPACE
        CMPB  #'M
        BEQ    CHANGE
        CMPB  #'R
        BEQ    PRINT     ;STACK
        CMPB  #'G
        BNE    CONTRL
        LDS    SP        ;RESTORE PGM'S STACK PTR
        RTI              ;GO

; ABNORMAL ENTRY FROM TRAP
; Attempt to initialise with register values at trap
mikbug_trap
        STS     SP
        LDS     #STACK
        BRA     PRINT

; ENTER FROM SOFTWARE INTERRUPT
SFE     EQU    *
mikbug_swi
        STS    SP        ;SAVE TARGET'S STACK POINTER
; DECREMENT P-COUNTER
        TSX
        TST    6,X
        BNE    *+4
        DEC    5,X
        DEC    6,X

; PRINT STACK FIELD NAME
OUTFNAM JSR    OUTCH
        LDAA   #':
        JMP    OUTCH

; PRINT CONTENTS OF STACK
PRINT   PSHA
        LDX    SP
        INX
        LDAA   #'C
        BSR    OUTFNAM
        BSR    OUT2HS    ;CONDITION CODES
        LDAA   #'B
        BSR    OUTFNAM
        BSR    OUT2HS    ;ACC-B
        LDAA   #'A
        BSR    OUTFNAM
        BSR    OUT2HS    ;ACC-A
        LDAA   #'X
        BSR    OUTFNAM
        BSR    OUT4HS    ;X-REG
        LDAA   #'P
        BSR    OUTFNAM
        BSR    OUT4HS    ;P-COUNTER
        LDAA   #'S
        BSR    OUTFNAM
        LDX    #SP
        BSR    OUT4HS    ;STACK POINTER
        PULA
C2      BRA    CONTRL

MCLOFF
MCL     dc    $D,$A,'*,4 ;C/R,L/F

        END
