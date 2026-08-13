
;
; 0000-001F - HD6303 internal registers
;
    SEG.U IO
    ORG $0
P1DDR: ds.b 1
P2DDR: ds.b 1
PORT1: ds.b 1
PORT2: ds.b 1

;
; 0020-003F - NOT USED
;

;
; 0040-00FF - HD6303 internal RAM
;

    SEG.U INT_RAM_DRIVERS
    ORG $0040

KEYBUF_PREV: ds.b 9
KEYBUF_NEXT: ds.b 9

CURPOS_RC:
CURPOS_ROW:  ds.b 1
CURPOS_COL:  ds.b 1

SCROLL_LINES: ds.b 1

SCRATCH: ds.b 1

    IF * > $0060
        ECHO "INT_RAM_DRIVERS section overflowed"
        ERR
    ENDIF
    SEG.U INT_RAM_MIKBUG
    ORG $0060

; MIKBUG application RAM
SP      ds.b    1         ;S-HIGH
        ds.b    1         ;S-LOW

XHI     ds.b    1         ;XREG HIGH
XLOW    ds.b    1         ;XREG LOW
        ds.b    46
STACK   ds.b    1         ;STACK POINTER

;	Registers used by the FORTH virtual machine:
;	Starting at $00E0:
    IF * > $00E0
        ECHO "INT_RAM_MIKBUG section overflowed"
        ERR
    ENDIF
    SEG.U INT_RAM_FORTH
    ORG $00E0
W	DS.B	2	;the instruction register points to 6800 code
IP	DS.B	2	;the instruction pointer points to pointer to 6800 code
RP	DS.B	2	;the return stack pointer
UP	DS.B	2	;the pointer to base of current user's 'USER' table
;           		 (altered during multi-tasking)

N	DS.B	10	;used as scratch by (FIND),ENCLOSE,CMOVE,EMIT,KEY,
;                              SP@,SWAP,DOES>,COLD

    IF * > $0100
        ECHO "INT_RAM_FORTH section overflowed"
        ERR
    ENDIF
;
; 0100-03FF - NOT USED
;

;
; 0400-09FF - Gate Array I/O
;
    SEG.U KEYSCAN
    ORG $0400
KEYSCAN: ds.b 1

    SEG.U KEYMATRIX
    ORG $0410
KEYMATRIX: ds.b 1

;
; 0A00-0BFF - LCD Display
;
    SEG.U LCD
    ORG $0A00
LCD00: ds.b 16
LCD10: ds.b 16

;
; 0C00-0FFF - FDD Controller
;

;
; 1000-1FFF - NOT USED
;

;
; 2000-2FFF - IC3 - 4K battery-backed RAM
;

;
; 3000-3FFF - IC4/5 - 4K RAM window
;
    SEG.U RAM_IC4_5
    ORG $3000

;	These locations are used by the TRACE routine :

TRLIM	DS.B	1	;the count for tracing without user intervention
TRACEM	DS.B	1	;non-zero = trace mode
BRKPT	DS.B	2	;the breakpoint address at which
;               	 the program will go into trace mode
VECT	DS.B	2	;vector to machine code
;               	 (only needed if the TRACE routine is resident)


;	This system is shown with one user, but additional users
;	may be added by allocating additional user tables:
;	UORIG2 DS.B 64 data table for user #2
;
;	Some of this stuff gets initialized during
;	COLD Start and WARM Start:
; 	[ names correspond to FORTH words of similar (no X) name ]

UORIG	DS.B	6	;3 reserved variables
XSPZER	DS.B	2	;initial top of data stack for this user
XRZERO	DS.B	2	;initial top of return stack
XTIB	DS.B	2	;Start of terminal input buffer
XWIDTH	DS.B	2	;name field width
XWARN	DS.B	2	;warning message mode (0 = no disc)
XFENCE	DS.B	2	;fence for FORGET
XDP	DS.B	2	;dictionary pointer
XVOCL	DS.B	2	;vocabulary linking
XBLK	DS.B	2	;disc block being accessed
XIN	DS.B	2	;scan pointer into the block
XOUT	DS.B	2	;cursor position
XSCR	DS.B	2	;disc screen being accessed (O=terminal)
XOFSET	DS.B	2	;disc sector offset for multi-disc
XCONT	DS.B	2	;last word in primary search vocabulary
XCURR	DS.B	2	;last word in extensible vocabulary
XSTATE	DS.B	2	;flag for 'interpret' or 'COMPILE' modes
XBASE	DS.B	2	;number base for I/O numeric conversion
XDPL	DS.B	2	;DECIMAl point place
XFLD	DS.B	2
XCSP	DS.B	2	;current stack position, for COMPILE checks
XRNUM	DS.B	2
XHLD	DS.B	2
XCOLUM	DS.B	2	;carriage width

;
;   end of user table, Start of common system variables
;

;  These things, up through the lable 'REND', are overwritten
;  at time of cold load and should have the same contents
;  as shown here:
; (other than the variables at the beginning, which don't have values here.)

XUSE	DS.B	2
XPREV	DS.B	2
	DS.B	4	;(spares)

	DC	$C5	;immediate
	DC	"FORT"	;DC	4,FORTH
	DC	$C8
	DC.W	NOOP-7
FORTH	DC.W	DODOES,DOVOC,$81A0,TASK-7
	DC.W	0

	DC	"(C) Forth Interest Group, 1979"

	DC	$84
	DC	"TAS"	;DC	3,TASK
	DC	$CB
	DC.W	FORTH-8
TASK	DC.W	DOCOL,SEMIS

REND	equ	*	;(first empty location in dictionary)

; 4000-7FFF - BANK0 16K window
;

;
; 8000-BFFF - BANK1 16K window
;

;
; C000-FFFF - 16K ROM: Location 1C000-1FFFF in IC7
;

    SEG TEXT
    ORG $0
    ds.b 1,$ff

