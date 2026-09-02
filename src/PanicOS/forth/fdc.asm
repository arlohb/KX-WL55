; FDC words

        ; HEX
        ; C00 CONSTANT FDC_SR
fdc_sr
        DC      $86     ; Name length + $80
        DC      "FDC_S"    ; All but last char of name
        DC      $D2     ; last char + $80
        DC.W    last_editor
FDC_SR  DC.W    DOCON
        DC.W    FDCSR

        ; C01 CONSTANT FDC_DR
fdc_dr  DC      $86
        DC      "FDC_D"
        DC      $D2
        DC.W    fdc_sr
FDC_DR  DC.W    DOCON
        DC.W    FDCDR

        ; C02 CONSTANT FDC_AR
fdc_ar  DC      $86
        DC      "FDC_A"
        DC      $D2
        DC.W    fdc_dr
FDC_AR  DC.W    DOCON
        DC.W    FDCAR

        ; AWAIT_TXR ( --- )
        ; Wait until TXR is set
await_txr
        DC      $89
        DC      "AWAIT_TX"
        DC      $D2
        DC.W    fdc_ar
AWAIT_TXR
        DC.W    DOCOL
AWAIT_TXR2
        DC.W    FDC_SR,CAT,LIT,$80,ANDLAB,LIT,$80,EQUAL,ZBRAN
        DC.W    AWAIT_TXR2-*
        DC.W    SEMIS

        ; AWAIT_TXR_NOT_BUSY ( --- )
        ; Wait until TXR is set, and busy (bits 5/6) aren't
await_txr_not_busy
        DC      $92
        DC      "AWAIT_TXR_NOT_BUS"
        DC      $D9
        DC.W    await_txr
AWAIT_TXR_NOT_BUSY
        DC.W    DOCOL
AWAIT_TXR_NOT_BUSY2
        DC.W    FDC_SR,CAT,LIT,$F0,ANDLAB,LIT,$80,EQUAL,ZBRAN
        DC.W    AWAIT_TXR_NOT_BUSY2-*
        DC.W    SEMIS

        ; SEND_CMD ( -1 PARAMn ... PARAM1 CMD --- )
        ; Sends a command to the FDC
        ; -1 indicates the end of the command
send_cmd
        DC      $88
        DC      "SEND_CM"
        DC      $C4
        DC.W    await_txr_not_busy
SEND_CMD
        DC.W    DOCOL
        DC.W    AWAIT_TXR_NOT_BUSY
SEND_CMD2
        DC.W    FDC_DR,CSTORE,AWAIT_TXR,DUP,ZLESS,ZBRAN
        DC.W    SEND_CMD2-*
        DC.W    DROP
        DC.W    SEMIS

        ; READ_RESULTS ( --- RESULT1 ... RESULTn )
        ; Reads the results from a command
        ; (Caller is expected to know number of expected results and pop them)
read_results
        DC      $8C
        DC      "READ_RESULT"
        DC      $D3
        DC.W    send_cmd
READ_RESULTS
        DC.W    DOCOL
        DC.W    AWAIT_TXR
READ_RESULTS2
        DC.W    FDC_DR,CAT,FDC_SR,CAT,LIT,$40,ANDLAB,ZEQU,ZBRAN
        DC.W    READ_RESULTS2-*
        DC.W    SEMIS

        ; SEND_SPECIFY ( --- )
        ; Send the `SPECIFY` command to the FDC
send_specify
        DC      $8C
        DC      "SEND_SPECIF"
        DC      $D9
        DC.W    read_results
SEND_SPECIFY
        DC.W    DOCOL
        DC.W    LIT,$FFFF,LIT,$1B,LIT,$C1,LIT,$03,SEND_CMD
        DC.W    SEMIS

        ; READY_DRIVE ( --- )
        ; Readies the drive!
ready_drive
        DC      $8B
        DC      "READY_DRIV"
        DC      $C5
        DC.W    send_specify
READY_DRIVE
        DC.W    DOCOL
        DC.W    LIT,$FF,FDC_AR,CSTORE,AWAIT_TXR,LIT,$DF,FDC_AR,CSTORE
        DC.W    AWAIT_TXR,LIT,$D1,FDC_AR,CSTORE
        DC.W    SEND_SPECIFY,AWAIT_TXR,LIT,$E1,FDC_AR,CSTORE
        DC.W    SEMIS

ser_irq_dis
        ; SER_IRQ_DIS ( --- )
        ; Disables serial interrupts
        DC      $8B
        DC      "SER_IRQ_DI"
        DC      $D3
        DC.W    ready_drive
SER_IRQ_DIS
        DC.W    DOCOL
        DC.W    LIT,TRCSR,CAT,LIT,$EF,ANDLAB,LIT,TRCSR,CSTORE
        DC.W    SEMIS

        ; SET_P21 ( --- )
        ; Sets b1 or Port 2 high - note that it will clobber other high bit values!
set_p21
        DC      $87
        DC      "SET_P2"
        DC      $B1
        DC.W    ser_irq_dis
SET_P21
        DC.W    DOCOL
        DC.W    LIT,$02,LIT,PORT2,CSTORE
        DC.W    SEMIS

        ; LOOP_DELAY ( loops --- )
        ; Delays for `loops` number of goes round the loop of 3 NOPs
loop_delay
        DC      $8A
        DC      "LOOP_DELA"
        DC      $D9
        DC.W    set_p21
LOOP_DELAY
        DC.W    *+2
        pulx
.loop_delay
        NOP
        NOP
        NOP
        dex
        bne .loop_delay
        jmp NEXT

        ; CHK_DEV_STATUS ( --- SSB3 )
        ; Sends the `CHECK DEVICE STATUS` command and returns SSB3 on the stack
chk_dev_status
        DC      $8E
        DC      "CHK_DEV_STATU"
        DC      $D3
        DC.W    loop_delay
CHK_DEV_STATUS
        DC.W    DOCOL
        DC.W    LIT,$FFFF,ZERO,LIT,$4,SEND_CMD,READ_RESULTS
        DC.W    SEMIS

        ; AWAIT_DRV_RDY ( --- f )
        ; Waits until the drive on which `READY_DRIVE` has been called is ready.
        ; On exit f=true indicates success.
await_drv_rdy
        DC      $8D
        DC      "AWAIT_DRV_RD"
        DC      $D9
        DC.W    chk_dev_status
AWAIT_DRV_RDY
        DC.W    DOCOL
        DC.W    LIT,$7FFF,LOOP_DELAY,ZERO,LIT,$300,ZERO,XDO
AWAIT_DRV_RDY2
        DC.W    CHK_DEV_STATUS,LIT,$20,ANDLAB,LIT,$20,EQUAL,ZBRAN
        DC.W    AWAIT_DRV_RDY3-*
        DC.W    DROP,ONE,LEAVE
AWAIT_DRV_RDY3
        DC.W    XLOOP
        DC.W    AWAIT_DRV_RDY2-*
        DC.W    SEMIS

        ; AWAIT_IRQ ( --- f )
        ; Waits for an IRQ from the FDC
        ; On exit f=true indicates success.
await_irq
        DC      $89
        DC      "AWAIT_IR"
        DC      $D1
        DC.W    await_drv_rdy
AWAIT_IRQ
        DC.W    DOCOL
        DC.W    ZERO,LIT,$7FFF,ZERO,XDO
AWAIT_IRQ2
        DC.W    LIT,PORT5,CAT,ONE,ANDLAB,ZEQU,ZBRAN
        DC.W    AWAIT_IRQ3-*
        DC.W    DROP,ONE,LEAVE
AWAIT_IRQ3
        DC.W    XLOOP
        DC.W    AWAIT_IRQ2-*
        DC.W    SEMIS

        ; CHK_INT_STATUS ( --- SSB0 PCN )
        ; Checks the status of the last IRQ received.
        ; Returns the SSB0 and PCN (track number) values.
chk_int_status
        DC      $8E
        DC      "CHK_INT_STATU"
        DC      $D3
        DC.W    await_irq
CHK_INT_STATUS
        DC.W    DOCOL
        DC.W    LIT,$FFFF,LIT,$8,SEND_CMD,READ_RESULTS
        DC.W    SEMIS

        ; DO_SEEK_CMD ( -1 PARAMn ... PARAM1 CMD --- f )
        ; An invisible word, only called by SEND_RECAL and SEND_SEEK.
        ; Completes both command executions.
DO_SEEK_CMD
        DC.W    DOCOL
        DC.W    SEND_CMD,AWAIT_IRQ,ZBRAN
        DC.W    DO_SEEK_CMD_ELSE-*
        DC.W    CHK_INT_STATUS,DROP
        DC.W    BRAN
        DC.W    DO_SEEK_CMD_THEN-*
DO_SEEK_CMD_ELSE
        DC.W    LIT,$C0
DO_SEEK_CMD_THEN
        DC.W    SEMIS

        ; SEND_RECAL ( --- SSB0 )
        ; Sends the FDC `RECAL` command and returns SSB0
send_recal
        DC      $8A
        DC      "SEND_RECA"
        DC      $CC
        DC.W    chk_int_status
SEND_RECAL
        DC.W    DOCOL
        DC.W    LIT,$FFFF,ZERO,LIT,$7,DO_SEEK_CMD
        DC.W    SEMIS

        ; SEND_SEEK ( NCN --- SSB0 )
        ; Sends the FDC `SEEK` command and returns SSB0
        ; Put the required track number on the stack.
send_seek
        DC      $89
        DC      "SEND_SEE"
        DC      $CB
        DC.W    send_recal
SEND_SEEK
        DC.W    DOCOL
        DC.W    LIT,$FFFF,SWAP,ZERO,LIT,$F,DO_SEEK_CMD
        DC.W    SEMIS

        ; RECAL ( --- f )
        ; Sends the FDC `RECAL` command.
        ; On exit f=true indicates success.
recal
        DC      $85
        DC      "RECA"
        DC      $CC
        DC.W    send_seek
RECAL
        DC.W    DOCOL
        DC.W    SEND_RECAL,LIT,$C0,ANDLAB,ZEQU
        DC.W    SEMIS

        ; SEEK ( NCN --- f )
        ; Sends the FDC `SEEK` command for the specified track.
        ; On exit f=true indicates success.
seek
        DC      $84
        DC      "SEE"
        DC      $CB
        DC.W    recal
SEEK
        DC.W    DOCOL
        DC.W    SEND_SEEK,LIT,$C0,ANDLAB,ZEQU
        DC.W    SEMIS

        ; SEEK5_AND_RECAL ( --- f )
        ; Performs part of the initialisation routine, which checks
        ; it can see successfully by performing recal, seek 5, recal.
        ; On exit f=true indicates success.
seek5_and_recal
        DC      $8F
        DC      "SEEK5_AND_RECA"
        DC      $CC
        DC.W    seek
SEEK5_AND_RECAL
        DC.W    DOCOL
        DC.W    RECAL,DUP,ZBRAN
        DC.W    SEEK5_AND_RECAL_DONE
        DC.W    DROP,LIT,5,SEEK,DUP,ZBRAN
        DC.W    SEEK5_AND_RECAL_DONE
        DC.W    DROP,RECAL
SEEK5_AND_RECAL_DONE
        DC.W    SEMIS

        ; FDC_INIT ( --- f )
        ; Initialises the FDC, ready for read/write/format.
        ; On exit f=true indicates success.
fdc_init
        DC      $88
        DC      "FDC_INI"
        DC      $D4
        DC.W    seek5_and_recal
FDC_INIT
        DC.W    DOCOL
        DC.W    SER_IRQ_DIS,SET_P21,LIT,$3000,LOOP_DELAY,READY_DRIVE
        DC.W    AWAIT_DRV_RDY,DUP,ZBRAN
        DC.W    FDC_INIT_DONE-*
        DC.W    DROP,SEEK5_AND_RECAL,LIT,$3000,LOOP_DELAY
FDC_INIT_DONE
        DC.W    SEMIS

        ; DO_READ
        SUBROUTINE
do_read
        DC      $87
        DC      "DO_REA"
        DC      $C4
        DC.W    fdc_init
DO_READ ; (Invisible word to send the command and do the read loop)
        DC.W    *+2

        ldx     #$0
.wait_rdy_cmd
        pula    ;hi byte (ignore)
        pulb    ;lo byte (cmd)
        ldaa    FDCSR
        anda    #$F0
        cmpa    #$80
        beq     .fdc_rdy
        inx
        bne     .wait_rdy_cmd
        swi
        bra     .done
.fdc_rdy
        stab    FDCDR
        pula    ;hi byte (ignore)
        pulb    ;lo byte (param)
        cmpa    #$ff
        beq     .op_complete
.wait_rdy_param
        ldaa    FDCSR
        anda    #$e0
        cmpa    #$80
        beq     .fdc_rdy

.op_complete
        pulx
.read_loop
        pshx
        ldx     #0
.wait_txr_loop
        ldab    FDCSR
        bmi     .txr_ok
        inx
        bne     .wait_txr_loop
        bra     .read_time_out
.txr_ok
        pulx
        bitb    #$20
        beq     .done
        ldab    FDCDR
        stab    0,x
        inx
        bra     .read_loop

.read_time_out
        pulx
.done
        jmp NEXT
        nop

last_fdc
        ; FDC_SECTOR_READ ( MADDR CA HA SA --- f )
        ; Reads a sector from the FDC to the space at MADDR
        ; On exit f=true indicates success.
fdc_read
        DC      $8F
        DC      "FDC_SECTOR_REA"
        DC      $C4
        DC.W    do_read
FDC_READ
        DC.W    DOCOL
        ; Ready the stack for SEND_CMD
        DC.W    DUP,TOR,SWAP,TOR,SWAP,TOR,LIT,$FFFF,SWAP; --- MADDR -1 SA
        DC.W    ZERO,LIT,$1B,ROT                        ; --- MADDR -1 MNL=0 GSL=$1B ESN=SA
        DC.W    TWO,FROMR                               ; --- MADDR -1 MNL GSL ESN RL=2 CA
        DC.W    FROMR,SWAP,FROMR,ROT,ROT                ; --- MADDR -1 MNL GSL ESN RL SA HA CA
        DC.W    OVER,LIT,$4,STAR                        ; --- MADDR -1 MNL GSL ESN RL SA HA CA HSL/US
        DC.W    LIT,$46
        DC.W    DO_READ
        DC.W    READ_RESULTS,DROP,DROP,DROP,DROP        ; --- SSB0 SSB1 SSB2
        DC.W    ROT,LIT,$40,ANDLAB,$40,EQUAL,ZBRAN
        DC.W    FDC_READ1-*                             ; SSB0 OK - success
        DC.W    OVER,LIT,$100,STAR,PLUS,$8000,EQUAL,ZBRAN
        DC.W    FDC_READ2-*                             ; SSB1/2 OK - success
        DC.W    ZERO,BRAN
        DC.W    FDC_READ3-*                             ; Failed
FDC_READ1
        DC.W    DROP,DROP                               ; Drop SSB1/2, not checking
FDC_READ2
        DC.W    ONE                                     ; Indicate success
FDC_READ3
        DC.W    SEMIS

