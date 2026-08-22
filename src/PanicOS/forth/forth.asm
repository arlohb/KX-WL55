    .processor HD6303
; fig-FORTH for 6303 in ROM on Panasonic KXP-WL55 Word Processor
; Adapted from fig-FORTH FOR 6800 in ROM on 6800 Multicomp by Arlo Blythe and Stephen Blythe
;
; Assemble using DASM
;
; Uses keyboard and LCD rather than ACIA for I/O
;
; Brief Memory Map (see memory_map.asm for detail)
;	0x0040-0x00FF - HD6303 internal RAM     - some critical Forth registers here
;       0x2000-0x2FFF - 4KB battery-backed RAM  - not currently used by Forth
;	0x3000-0x3FFF - 4KB SRAM window         - Forth's workspace
;	0x4000-0xBFFF - Paged ROM banks         - not currently used by Forth
;       0xC000-0xFFFF - ROM                     - Forth code is in here
;
; ASSEMBLY SOURCE LISTING
;
; http://www.forth.org/fig-forth/fig-forth_6800.pdf
;
; RELEASE 1
; MAY 1979
; WITH COMPILER SECURITY
; AND VARIABLE LENGTH NAMES
;
; This public domain publication is provided
; through the courtesy of:
; FORTH INTEREST GROUP (fig)
;
; P.O. Box 8231 - San Jose, CA 95155 - (408) 277-0668
; Further distribution must include this notice.
;
; Copyright:FORTH Interest Group
;
; === FORTH-6800 06-06-79 21:OO
;
; This listing is in the PUBLIC DOMAIN and
; may be freely copied or published with the
; restriction that a credit line is printed
; with the material, crediting the
; authors and the FORTH INTEREST GROUP.
;
; === by Dave Lion,
; ===  with help from
; === Bob Smith,
; === LaFarr Stuart,
; === The Forth Interest Group
; === PO Box 1105
; === San Carlos, CA 94070
; ===  and
; === Unbounded computing
; === 1134-K Aster Ave.
; === Sunnyvale, CA 94086
;
;  All terminal I/O is done in three subroutines:
;   PEMIT  ( word # 182 )
;   PKEY   (        183 )
;   PQTERM (        184 )
;
;  The FORTH words for disc related I/O follow the model
;  of the FORTH Interest Group, but have not been
;  tested using a real disc.
;
;  Code from location $1000 to lable ZZZZ are in ROM.
;  Minor deviations from the model were made in the
;  initialization and words ?STACK and FORGET
;  in order to do this.
;
; smp, June 2018
; Modified to assemble properly with the AS02 6800 cross-assembler
; Modified to operate on Corsham Technologies 6800 system (SWTPC replica)
;
; DGG, APR 2022
; Ported to A68 Assembler
; Running on MULTICOMP 6800
; Runs from ROM
;  MEMORY MAP for this 32K system:
;  (positioned so that systems with 4k byte write-
;   protected segments can write protect FORTH)
;
; Arlo Blythe, August 2026
; Ported to DASM Assembler
; Changed memory map and IO to run on Panasonic KX-WL55
;
; addr		contents		pointer	init by
; ****	*******************************	*******	*******
; FFFF  The rest of ROM (non-Forth)
;
; 	6k of romable "FORTH"		<== IP	ABORT
;					<== W
;	the VIRTUAL FORTH MACHINE
;
; C004 <<< WARM START ENTRY >>>
; C000 <<< COLD START ENTRY >>>
;
; 4000-BFFF - BANK0/1 - unused by Forth
;
; 3000-3FFF - FORTH RAM WORKSPACE

; 4000                                          MEMEND
; 	4 buffer sectors of VIRTUAL MEMORY
; 3DF0						FIRST,RAMEND
; 3DEE	RETURN STACK base		<== RP	RINIT
;
; 3DA4
;	INPUT LINE BUFFER
;	holds up to 132 characters
;	and is scanned upward by IN
;	starting at TIB
; 3D20					<== IN	TIB
; 3D1F	DATA STACK			<== SP	SP0,SINIT
;    |	grows downward from 3D1F
;    v
;    ^
;    |
;    I	DICTIONARY grows upward
;
; 3083	end of ram-dictionary.		<== DP	DPINIT
;	"TASK"
;
; 3050	"FORTH" (a word)		<=, <== CONTEXT
;					  `==== CURRENT
; 3048	start of ram-dictionary.
;
; 3000	user #l table of variables	<= UP	DPINIT
;
; 2000-2FFF - Battery backed RAM
; 2FFF						HI
;	substitute for disc mass memory
; 2000						LO
;
; 0100-1FFF - HD6303 I/O SPACE
;
;   F0	registers & pointers for the virtual machine
; 	scratch area used by various words
;   E0	lowest address used by FORTH
; 0000
;
;**
;
; CONVENTIONS USED IN THIS PROGRAM ARE AS FOLLOWS :
;
; IP points to the current instruction (pre-increment mode)
; RP points to second free byte (first free word) in return stack
; SP (hardware SP) points to first free byte in data stack
;
;	when A and B hold one 16 bit FORTH data word,
;	A contains the high byte, B, the low byte.
;**

NBLK	equ	4		;# of disc buffer blocks for virtual memory
MEMEND	equ	$4000	        ;end of ram

;  each block is 132 bytes in size,
;  holding 128 characters
BLKSIZE equ     132

; Address of first vmem buffer
FIRSTV  equ     MEMEND-BLKSIZE*NBLK

VDISK_HI    equ $2FFF
VDISK_LO    equ $2000

; RAM was here in origin in source file, now in memory_map.asm

;    The FORTH program (address $C000 to $D7FF) is written
;    so that it can be in a ROM, or write-protected if desired

; This section was previously located at $1000,
; now it's just wherever it's included

; ######>> screen 3 <<
;
;**************************
;*  C O L D   E N T R Y  **
;**************************
ORIG	nop
	jmp	CENT
;**************************
;*  W A R M   E N T R Y  **
;**************************
	nop
	jmp	WENT	;warm-start code, keeps current dictionary intact

; Since we have put the virtual buffers above this
; RAMEND = FIRST
RAMEND  equ FIRSTV

;
;*************** startup parmeters *****************
;
	DC.W	$6303,0000	;cpu & revision
	DC.W	0	;topmost word in FORTH vocabulary
BACKSP	DC.W	$7F	;backspace character for editing
UPINIT	DC.W	UORIG	;initial user area
SINIT	DC.W	RAMEND-$D0	;initial top of data stack
RINIT	DC.W	RAMEND-2	;initial top of return stack
	DC.W	RAMEND-$D0	;terminal input buffer
	DC.W	31	;initial name field width
	DC.W	0	;initial warning mode (0 = no disc)
FENCIN	DC.W	REND	;initial fence
DPINIT	DC.W	REND	;cold start value for DP
VOCINT	DC.W	FORTH+8
COLINT	DC.W	80	;initial terminal carriage width
;
;***************************************************
;

;
; ######>> screen 13 <<
PULABX	pula		;24 cycles until 'NEXT'
	pulb
STABX	STAA 0,x	;16 cycles until 'NEXT'
	STAB	1,x
	bra	NEXT
GETX	LDAA	0,x	;18 cycles until 'NEXT'
	LDAB	1,x
PUSHBA	pshb		;8 cycles until 'NEXT'
	psha
;
; "NEXT" takes 38 cycles if TRACE is removed,
; and 95 cycles if NOT tracing.
;

; = = = = t h e   v i r t u a l  m a c h i n e = = = =
;
NEXT	ldx	IP
	inx		;pre-increment mode
	inx
	stx	IP
NEXT2	ldx	0,x	;get W which points to CFA of word to be done
NEXT3	stx	W
	ldx	0,x	;get VECT which points to executable code
;
; The next instruction could be patched to jmp TRACE
; if a TRACE routine is available:
;
	jmp	0,x
	nop
;	jmp	TRACE	;(an alternate for the above)
;
; = = = = = = = = = = = = = = = = = = = = = = = = = = =

;
; ======>>  1  <<
	DC	$83
	DC	"LI"	;DC	2,LIT	;NOTE: this is different from LITERAL
	DC	$D4
	DC.W	0	;link of zero to terminate dictionary scan
LIT	DC.W	*+2
	ldx	IP
	inx
	inx
	stx	IP
	LDAA	0,x
	LDAB	1,x
	jmp	PUSHBA
	nop		;to compensate for assembler substituting BRA
;
; ######>> screen 14 <<
; ======>>  2  <<
CLITER	DC.W	*+2	;(this is an invisible word, with no header)
	ldx	IP
	inx
	stx	IP
	clra
	LDAB	1,x
	jmp	PUSHBA
	nop		;to compensate for assembler substituting BRA
;
; ======>>  3  <<
	DC	$87
	DC	"EXECUT"	;DC	6,EXECUTE
	DC	$C5
	DC.W	LIT-6
EXEC	DC.W	*+2
	tsx
	ldx	0,x	;get code field address (CFA)
	ins		;pop stack
	ins
	jmp	NEXT3
	nop		;to compensate for assembler substituting BRA
;
; ######>> screen 15 <<
; ======>>  4  <<
	DC	$86
	DC	"BRANC"	;DC	5,BRANCH
	DC	$C8
	DC.W	EXEC-10
BRAN	DC.W	ZBYES	;Go steal code in ZBRANCH
;
; ======>>  5  <<
	DC	$87
	DC	"0BRANC"	;DC	6,0BRANCH
	DC	$C8
	DC.W	BRAN-9
ZBRAN	DC.W	*+2
	pula
	pulb
	aba
	bne	ZBNO
	bcs	ZBNO
ZBYES	ldx	IP	;Note: code is shared with BRANCH, (+LOOP), (LOOP)
	LDAB	3,x
	LDAA 2,x
	addb	IP+1
	adca	IP
	STAB	IP+1
	STAA 	IP
	jmp	NEXT
	nop		;to compensate for assembler substituting BRA
ZBNO	ldx	IP	;no branch. This code is shared with (+LOOP), (LOOP).
	inx		;jump over branch delta
	inx
	stx	IP
	jmp	NEXT
	nop		;to compensate for assembler substituting BRA
;
; ######>> screen 16 <<
; ======>>  6  <<
	DC	$86
	DC	"(LOOP"	;DC	5,(LOOP)
	DC	$A9
	DC.W	ZBRAN-10
XLOOP	DC.W	*+2
	clra
	LDAB	#1	;get set to increment counter by 1
	bra	XPLOP2	;go steal other guy's code!
;
; ======>>  7  <<
	DC	$87
	DC	"(+LOOP"	;DC	6,(+LOOP)
	DC	$A9
	DC.W	XLOOP-9
XPLOOP	DC.W *+2		;Note: +LOOP has an un-signed loop counter
	pula		;get increment
	pulb
XPLOP2	TSTA
	bpl	XPLOF	;forward looping
	bsr	XPLOPS
	sec
	sbcb	5,x
	sbca	4,x
	bpl	ZBYES
	bra	XPLONO	;fall through
;
; the subroutine :
XPLOPS	ldx	RP
	addb	3,x	;add it to counter
	adca	2,x
	STAB	3,x	;store new counter value
	STAA 	2,x
	rts
;
XPLOF	bsr	XPLOPS
	subb	5,x
	sbca	4,x
	bmi	ZBYES
;
XPLONO	inx		;done, don't branch back
	inx
	inx
	inx
	stx	RP
	bra	ZBNO	;use ZBRAN to skip over unused delta
;
; ######>> screen 17 <<
; ======>>  8  <<
	DC	$84
	DC	"(DO"	;DC	3,(DO)
	DC	$A9
	DC.W	XPLOOP-10
XDO	DC.W	*+2	;This is the RUNTIME DO, not the COMPILING DO
	ldx	RP
	dex
	dex
	dex
	dex
	stx	RP
	pula
	pulb
	STAA 	2,x
	STAB	3,x
	pula
	pulb
	STAA 	4,x
	STAB	5,x
	jmp	NEXT
;
; ======>>  9  <<
	DC	$81	; I
	DC	$C9
	DC.W	XDO-7
I	DC.W	*+2
	ldx	RP
	inx
	inx
	jmp	GETX
;
; ######>> screen 18 <<
; ======>>  10  <<
	DC	$85
	DC	"DIGI"	;DC	4,DIGIT
	DC	$D4
	DC.W	I-4
DIGIT	DC.W	*+2	;NOTE: legal input range is 0-9, A-Z
	tsx
	LDAA 3,x
	suba	#$30	;ascii zero
	bmi	DIGIT2	;IF LESS THAN '0', ILLEGAL
	cmpa	#$A
	bmi	DIGIT0	;IF '9' OR LESS
	cmpa	#$11
	bmi	DIGIT2	;if less than 'A'
	cmpa	#$2B
	bpl	DIGIT2	;if greater than 'Z'
	suba	#7	;translate 'A' thru 'F'
DIGIT0	cmpa	1,x
	bpl	DIGIT2	;if not less than the base
	LDAB	#1	;set flag
	STAA 	3,x	;store digit
DIGIT1	STAB	1,x	;store the flag
	jmp	NEXT
DIGIT2	clrb
	ins
	ins		;pop bottom number
	tsx
	STAB	0,x	;make sure both bytes are 00
	bra	DIGIT1
;
; ######>> screen 19 <<
;
; The word format in the dictionary is:
;
; char-count + $80	;lowest address
; char 1
; char 2
;
; char n  + $80
; link high byte \___point to previous word
; link low  byte /
; CFA  high byte \___point to 6800 code
; CFA  low  byte /
; parameter fields
;    "
;    "
;    "
;
; ======>>  11  <<
	DC	$86
	DC	"(FIND"	;DC	5,(FIND)
	DC	$A9
	DC.W	DIGIT-8
PFIND	DC.W	*+2
	nop
	nop
PD	equ	N	;ptr to dict word being checked
PA0	equ	N+2
PA	equ	N+4
PC	equ	N+6
	ldx	#PD
	LDAB	#4
PFIND0	pula		;loop to get arguments
	STAA 	0,x
	inx
	decb
	bne	PFIND0
;
	ldx	PD
PFIND1	LDAB	0,x	;get count dict count
	STAB	PC
	andb	#$3F
	inx
	stx	PD	;update PD
	ldx	PA0
	LDAA 0,x	;get count from arg
	inx
	stx	PA	;initialize PA
	cba		;compare lengths
	bne	PFIND4
PFIND2	ldx	PA
	LDAA	0,x
	inx
	stx	PA
	ldx	PD
	LDAB	0,x
	inx
	stx	PD
	TSTB		;is dict entry neg. ?
	bpl	PFIND8
	andb	#$7F	;clear sign
	cba
	beq	FOUND
PFIND3	ldx	0,x	;get new link
	bne	PFIND1	;continue if link not=0
;
;	not found :
;
	clra
	clrb
	jmp	PUSHBA
PFIND8	cba
	beq	PFIND2
PFIND4	ldx	PD
PFIND9	LDAB	0,x	;scan forward to end of this name
	inx
	bpl	PFIND9
	bra	PFIND3
;
;	found :
;
FOUND	LDAA	PD	;compute CFA
	LDAB	PD+1
	addb	#4
	adca	#0
	pshb
	psha
	LDAA	PC
	psha
	clra
	psha
	LDAB	#1
	jmp	PUSHBA
;
	psha
	clra
	psha
	LDAB	#1
	jmp	PUSHBA
;
; ######>> screen 20 <<
; ======>>  12  <<
	DC	$87
	DC	"ENCLOS"	;DC	6,ENCLOSE
	DC 	$C5
	DC.W	PFIND-9
; NOTE :
; FC means offset (bytes) to First Character of next word
; EW  "     "   to End of Word
; NC  "     "   to Next Character to start next enclose at
ENCLOS	DC.W	*+2
	ins
	pulb		;now, get the low byte, for an 8-bit delimiter
	tsx
	ldx	0,x
	clr	N
;	wait for a non-delimiter or a NUL
ENCL2	LDAA 0,x
	beq	ENCL6
	cba		;CHECK FOR DELIM
	bne	ENCL3
	inx
	inc	N
	bra	ENCL2
;	found first character. Push FC
ENCL3	LDAA	N	;found first char.
	psha
	clra
	psha
;	wait for a delimiter or a NUL
ENCL4	LDAA 0,x
	beq	ENCL7
	cba		;check for delim.
	beq	ENCL5
	inx
	inc	N
	bra	ENCL4
;	found EW. Push it
ENCL5	LDAB	N
	clra
	pshb
	psha
;	advance and push NC
	incb
	jmp	PUSHBA
;	found NUL before non-delimiter, therefore there is no word
ENCL6	LDAB	N	;found NUL
	pshb
	psha
	incb
	bra	ENCL7+2
;	found NUL following the word instead of SPACE
ENCL7	LDAB	N
	pshb		;save EW
	psha
ENCL8	LDAB	N	;save NC
	jmp	PUSHBA
;
; ######>> screen 21 <<
; The next 4 words call system dependant I/O routines
; which are listed after word "-->" ( lable: "arrow" )
; in the dictionary.
;
; ======>>  13  <<
	DC	$84
	DC	"EMI"	;DC	3,EMIT
	DC	$D4
	DC.W	ENCLOS-10
EMIT	DC.W	*+2
	pula
	pula
	jsr	PEMIT
	ldx	UP
	inc	XOUT+1-UORIG,x
	bne	*+4
	inc	XOUT-UORIG,x
	jmp	NEXT
;
; ======>>  14  <<
	DC	$83
	DC	"KE"	;DC	2,KEY
	DC	$D9
	DC.W	EMIT-7
KEY	DC.W	*+2
	jsr	PKEY
	psha
	clra
	psha
	jmp	NEXT
;
; ======>>  15  <<
	DC	$89
	DC	"?TERMINA"	;DC	8,?TERMINAL
	DC	$CC
	DC.W	KEY-6
QTERM	DC.W	*+2
	jsr	PQTER
	clrb
	jmp	PUSHBA	;stack the flag
;
; ======>>  16  <<
	DC	$82
	DC	"C"	;DC	1,CR
	DC	$D2
	DC.W	QTERM-12
CR	DC.W	*+2
	jsr	PCR
	jmp	NEXT
;
; ######>> screen 22 <<
; ======>>  17  <<
	DC	$85
	DC	"CMOV"	;DC	4,CMOVE	;source, destination, count
	DC	$C5
	DC.W	CR-5
CMOVE	DC.W	*+2	;takes ( 43+47*count cycles )
	ldx	#N
	LDAB	#6
CMOV1	pula
	STAA 	0,x	;move parameters to scratch area
	inx
	decb
	bne	CMOV1
CMOV2	LDAA N
	LDAB	N+1
	subb	#1
	sbca	#0
	STAA 	N
	STAB	N+1
	bcs	CMOV3
	ldx	N+4
	LDAA 0,x
	inx
	stx	N+4
	ldx	N+2
	STAA 	0,x
	inx
	stx	N+2
	bra	CMOV2
CMOV3	jmp	NEXT
;
; ######>> screen 23 <<
; ======>>  18  <<
	DC	$82
	DC	"U"	;DC	1,U*
	DC	$AA
	DC.W	CMOVE-8
USTAR	DC.W	*+2
	bsr	USTARS
	ins
	ins
	jmp	PUSHBA
;
; The following is a subroutine which
; multiplies top 2 words on stack,
; leaving 32-bit result:  high order word in A,B
; low order word in 2nd word of stack.
;
USTARS	LDAA #16	;bits/word counter
	psha
	clra
	clrb
	tsx
USTAR2	ror	5,x	;shift multiplier
	ror	6,x
	dec	0,x	;done?
	bmi	USTAR4
	bcc	USTAR3
	addb	4,x
	adca	3,x
USTAR3	rora
	rorb		;shift result
	bra	USTAR2
USTAR4	ins		;dump counter
	rts
;
; ######>> screen 24 <<
; ======>>  19  <<
	DC	$82
	DC	"U"	;DC	1,U/
	DC	$AF
	DC.W	USTAR-5
USLASH	DC.W	*+2
	LDAA #17
	psha
	tsx
	LDAA	3,x
	LDAB	4,x
USL1	cmpa	1,x
	bhi	USL3
	bcs	USL2
	cmpb	2,x
	bcc	USL3
USL2	clc
	bra	USL4
USL3	subb	2,x
	sbca	1,x
	sec
USL4	rol	6,x
	rol	5,x
	dec	0,x
	beq	USL5
	rolb
	rola
	bcc	USL1
	bra	USL3
USL5	ins
	ins
	ins
	ins
	ins
	jmp	SWAP+4	;reverse quotient & remainder
;
; ######>> screen 25 <<
; ======>>  20  <<
	DC	$83
	DC	"AN"	;DC	2,ANDLAB
	DC	$C4
	DC.W	USLASH-5
ANDLAB	DC.W	*+2
	pula
	pulb
	tsx
	andb	1,x
	anda	0,x
	jmp	STABX
;
; ======>>  21  <<
	DC	$82
	DC	"O"	;DC	1,ORLAB
	DC	$D2
	DC.W	ANDLAB-6
ORLAB	DC.W	*+2
	pula
	pulb
	tsx
	orab	1,x
	oraa	0,x
	jmp	STABX
;
; ======>>  22  <<
	DC	$83
	DC	"XO"	;DC	2,XORLAB
	DC	$D2
	DC.W	ORLAB-5
XORLAB	DC.W	*+2
	pula
	pulb
	tsx
	eorb	1,x
	eora	0,x
	jmp	STABX
;
; ######>> screen 26 <<
; ======>>  23  <<
	DC	$83
	DC	"SP"	;DC	2,SP@
	DC	$C0
	DC.W	XORLAB-6
SPAT	DC.W	*+2
	tsx
	stx	N	;scratch area
	ldx	#N
	jmp	GETX
;
; ======>>  24  <<
	DC	$83
	DC	"SP"	;DC	2,SP!
	DC	$A1
	DC.W	SPAT-6
SPSTOR	DC.W	*+2
	ldx	UP
	ldx	XSPZER-UORIG,x
	txs		;watch it ! X and S are not EQUAL.
	jmp	NEXT
;
; ======>>  25  <<
	DC	$83
	DC	"RP"	;DC	2,RP!
	DC	$A1
	DC.W	SPSTOR-6
RPSTOR	DC.W	*+2
	ldx	RINIT	;initialize from rom constant
	stx	RP
	jmp	NEXT
;
; ======>>  26  <<
	DC	$82
	DC	";"	;DC	1,;S
	DC	$D3
	DC.W	RPSTOR-6
SEMIS	DC.W	*+2
	ldx	RP
	inx
	inx
	stx	RP
	ldx	0,x	;get address we have just finished.
	jmp	NEXT+2	;increment the return address & do next word
;
; ######>> screen 27 <<
; ======>>  27  <<
	DC	$85
	DC	"LEAV"	;DC	4,LEAVE
	DC	$C5
	DC.W	SEMIS-5
LEAVE	DC.W	*+2
	ldx	RP
	LDAA 2,x
	LDAB	3,x
	STAA 	4,x
	STAB	5,x
	jmp	NEXT
;
; ======>>  28  <<
	DC	$82
	DC	">"	;DC	1,>R
	DC	$D2
	DC.W	LEAVE-8
TOR	DC.W	*+2
	ldx	RP
	dex
	dex
	stx	RP
	pula
	pulb
	STAA 	2,x
	STAB	3,x
	jmp	NEXT
;
; ======>>  29  <<
	DC	$82
	DC	"R"	;DC	1,R>
	DC	$BE
	DC.W	TOR-5
FROMR	DC.W	*+2
	ldx	RP
	LDAA 2,x
	LDAB	3,x
	inx
	inx
	stx	RP
	jmp	PUSHBA
;
; ======>>  30  <<
	DC	$81	; R
	DC	$D2
	DC.W	FROMR-5
R	DC.W	*+2
	ldx	RP
	inx
	inx
	jmp	GETX
;
; ######>> screen 28 <<
; ======>>  31  <<
	DC	$82
	DC	"0"	;DC	1,0=
	DC	$BD
	DC.W	R-4
ZEQU	DC.W	*+2
	tsx
	clra
	clrb
	ldx	0,x
	bne	ZEQU2
	incb
ZEQU2	tsx
	jmp	STABX
;
; ======>>  32  <<
	DC	$82
	DC	"0"	;DC	1,0<
	DC	$BC
	DC.W	ZEQU-5
ZLESS	DC.W	*+2
	tsx
	LDAA #$80	;check the sign bit
	anda	0,x
	beq	ZLESS2
	clra		;if neg.
	LDAB	#1
	jmp	STABX
ZLESS2	clrb
	jmp	STABX
;
; ######>> screen 29 <<
; ======>>  33  <<
	DC	$81	;'+'
	DC	$AB
	DC.W	ZLESS-5
PLUS	DC.W	*+2
	pula
	pulb
	tsx
	addb	1,x
	adca	0,x
	jmp	STABX
;
; ======>>  34  <<
	DC	$82
	DC	"D"	;DC	1,D+
	DC	$AB
	DC.W	PLUS-4
DPLUS	DC.W	*+2
	tsx
	clc
	LDAB	#4
DPLUS2	LDAA	3,x
	adca	7,x
	STAA 	7,x
	dex
	decb
	bne	DPLUS2
	ins
	ins
	ins
	ins
	jmp	NEXT
;
; ======>>  35  <<
	DC	$85
	DC	"MINU"	;DC	4,MINUS
	DC	$D3
	DC.W	DPLUS-5
MINUS	DC.W	*+2
	tsx
	neg	1,x
	bcs	MINUS2	;BCS to match original 1979 listing
	neg	0,x
	bra	MINUS3
MINUS2	com	0,x
MINUS3	jmp	NEXT
;
; ======>>  36  <<
	DC	$86
	DC	"DMINU"	;DC	5,DMINUS
	DC	$D3
	DC.W	MINUS-8
DMINUS	DC.W	*+2
	tsx
	com	0,x
	com	1,x
	com	2,x
	neg	3,x
	bne	DMINX
	inc	2,x
	bne	DMINX
	inc	1,x
	bne	DMINX
	inc	0,x
DMINX	jmp	NEXT
;
; ######>> screen 30 <<
; ======>>  37  <<
	DC	$84
	DC	"OVE"	;DC	3,OVER
	DC	$D2
	DC.W	DMINUS-9
OVER	DC.W	*+2
	tsx
	LDAA 2,x
	LDAB	3,x
	jmp	PUSHBA
;
; ======>>  38  <<
	DC	$84
	DC	"DRO"	;DC	3,DROP
	DC	$D0
	DC.W	OVER-7
DROP	DC.W	*+2
	ins
	ins
	jmp	NEXT
;
; ======>>  39  <<
	DC	$84
	DC	"SWA"	;DC	3,SWAP
	DC	$D0
	DC.W	DROP-7
SWAP	DC.W	*+2
	pula
	pulb
	tsx
	ldx	0,x
	ins
	ins
	pshb
	psha
	stx	N
	ldx	#N
	jmp	GETX
;
; ======>>  40  <<
	DC	$83
	DC	"DU"	;DC	2,DUP
	DC	$D0
	DC.W	SWAP-7
DUP	DC.W	*+2
	pula
	pulb
	pshb
	psha
	jmp PUSHBA
;
; ######>> screen 31 <<
; ======>>  41  <<
	DC	$82
	DC	"+"	;DC	1,+!
	DC	$A1
	DC.W	DUP-6
PSTORE	DC.W	*+2
	tsx
	ldx	0,x
	ins
	ins
	pula		;get stack data
	pulb
	addb	1,x	;add & store low byte
	STAB	1,x
	adca	0,x	;add & store hi byte
	STAA 	0,x
	jmp	NEXT
;
; ======>>  42  <<
	DC	$86
	DC	"TOGGL"	;DC	5,TOGGLE
	DC	$C5
	DC.W	PSTORE-5
TOGGLE	DC.W	DOCOL,OVER,CAT,XORLAB,SWAP,CSTORE
	DC.W	SEMIS
;
; ######>> screen 32 <<
; ======>>  43  <<
	DC	$81	; @
	DC	$C0
	DC.W	TOGGLE-9
AT	DC.W	*+2
	tsx
	ldx	0,x	;get address
	ins
	ins
	jmp	GETX
;
; ======>>  44  <<
	DC	$82
	DC	"C"	;DC	1,C@
	DC	$C0
	DC.W	AT-4
CAT	DC.W	*+2
	tsx
	ldx	0,x
	clra
	LDAB	0,x
	ins
	ins
	jmp	PUSHBA
;
; ======>>  45  <<
	DC	$81
	DC	$A1
	DC.W	CAT-5
STORE	DC.W	*+2
	tsx
	ldx	0,x	;get address
	ins
	ins
	jmp	PULABX
;
; ======>>  46  <<
	DC	$82
	DC	"C"	;DC	1,C!
	DC	$A1
	DC.W	STORE-4
CSTORE	DC.W	*+2
	tsx
	ldx	0,x	;get address
	ins
	ins
	ins
	pulb
	STAB	0,x
	jmp	NEXT
;
; ######>> screen 33 <<
; ======>>  47  <<
	DC	$C1	;immediate
	DC	$BA
	DC.W	CSTORE-5
COLON	DC.W	DOCOL,QEXEC,SCSP,CURENT,AT,CONTXT,STORE
	DC.W	CREATE,RBRAK
	DC.W	PSCODE

; Here is the IP pusher for allowing
; nested words in the virtual machine:
; ( ;S is the equivalent un-nester )

DOCOL	ldx	RP	;make room in the stack
	dex
	dex
	stx	RP
	LDAA IP
	LDAB	IP+1
	STAA 	2,x	;Store address of the high level word
	STAB	3,x	;that we are starting to execute
	ldx	W	;Get first sub-word of that definition
	jmp	NEXT+2	;and execute it
;
; ======>>  48  <<
	DC	$C1	;imnediate code
	DC	$BB
	DC.W	COLON-4
SEMI	DC.W	DOCOL,QCSP,COMPIL,SEMIS,SMUDGE,LBRAK
	DC.W	SEMIS
;
; ######>> screen 34 <<
; ======>>  49  <<
	DC	$88
	DC	"CONSTAN"	;DC	7,CONSTANT
	DC	$D4
	DC.W	SEMI-4
CON	DC.W	DOCOL,CREATE,SMUDGE,COMMA,PSCODE
DOCON	ldx	W
	LDAA 2,x
	LDAB	3,x	;A & B now contain the conSTAA nt
	jmp	PUSHBA
;
; ======>>  50  <<
	DC	$88
	DC	"VARIABL"	;DC	7,VARIABLE
	DC	$C5
	DC.W	CON-11
VAR	DC.W	DOCOL,CON,PSCODE
DOVAR	LDAA W
	LDAB	W+1
	addb	#2
	adca	#0	;A,B now contain the address of the variable
	jmp	PUSHBA
;
; ======>>  51  <<
	DC	$84
	DC	"USE"	;DC	3,USER
	DC	$D2
	DC.W	VAR-11
USER	DC.W	DOCOL,CON,PSCODE
DOUSER	ldx	W	;get offset  into user's table
	LDAA 2,x
	LDAB	3,x
	addb	UP+1	;add to users base address
	adca	UP
	jmp	PUSHBA	;push address of user's variable
;
; ######>> screen 35 <<
; ======>>  52  <<
	DC	$81
	DC	$B0	; 0
	DC.W	USER-7
ZERO	DC.W	DOCON
	DC.W	0000
;
; ======>>  53  <<
	DC	$81
	DC	$B1	; 1
	DC.W	ZERO-4
ONE	DC.W	DOCON
	DC.W	1
;
; ======>>  54  <<
	DC	$81
	DC	$B2	; 2
	DC.W	ONE-4
TWO	DC.W	DOCON
	DC.W	2
;
; ======>>  55  <<
	DC	$81
	DC	$B3	; 3
	DC.W	TWO-4
THREE	DC.W	DOCON
	DC.W	3
;
; ======>>  56  <<
	DC	$82
	DC	"B"	;DC	1,BL
	DC	$CC
	DC.W	THREE-4
BL	DC.W	DOCON	;ascii blank
	DC.W	$20
;
; ======>>  57  <<
	DC	$85
	DC	"FIRS"	;DC	4,FIRST
	DC	$D4
	DC.W	BL-5
FIRST	DC.W	DOCON
	DC.W	FIRSTV
;
; ======>>  58  <<
	DC	$85
	DC	"LIMI"	;DC	4,LIMIT	;(the end of memory +1)
	DC	$D4
	DC.W	FIRST-8
LIMIT	DC.W	DOCON
	DC.W	MEMEND
;
; ======>>  59  <<
	DC	$85
	DC	"B/BU"	;DC	4,B/BUF	;(bytes/buffer)
	DC	$C6
	DC.W	LIMIT-8
BBUF	DC.W	DOCON
	DC.W	128
;
; ======>>  60  <<
	DC	$85
	DC	"B/SC"	;DC	4,B/SCR	;(blocks/screen)
	DC	$D2
	DC.W	BBUF-8
BSCR	DC.W	DOCON
	DC.W	8
;	blocks/screen = 1024 / "B/BUF" = 8
;
; ======>>  61  <<
	DC	$87
	DC	"+ORIGI"	;DC	6,+ORIGIN
	DC	$CE
	DC.W	BSCR-8
PORIG	DC.W	DOCOL,LIT,ORIG,PLUS
	DC.W	SEMIS
;
; ######>> screen 36 <<
; ======>>  62  <<
	DC	$82
	DC	"S"	;DC	1,S0
	DC	$B0
	DC.W	PORIG-10
SZERO	DC.W	DOUSER
	DC.W	XSPZER-UORIG
;
; ======>>  63  <<
	DC	$82
	DC	"R"	;DC	1,R0
	DC	$B0
	DC.W	SZERO-5
RZERO	DC.W	DOUSER
	DC.W	XRZERO-UORIG
;
; ======>>  64  <<
	DC	$83
	DC	"TI"	;DC	2,TIB
	DC	$C2
	DC.W	RZERO-5
TIB	DC.W	DOUSER
	DC.W	XTIB-UORIG
;
; ======>>  65  <<
	DC	$85
	DC	"WIDT"	;DC	4,WIDTH
	DC	$C8
	DC.W	TIB-6
WIDTH	DC.W	DOUSER
	DC.W	XWIDTH-UORIG
;
; ======>>  66  <<
	DC	$87
	DC	"WARNIN"	;DC	6,WARNING
	DC	$C7
	DC.W	WIDTH-8
WARN	DC.W	DOUSER
	DC.W	XWARN-UORIG
;
; ======>>  67  <<
	DC	$85
	DC	"FENC"	;DC	4,FENCE
	DC	$C5
	DC.W	WARN-10
FENCE	DC.W	DOUSER
	DC.W	XFENCE-UORIG
;
; ======>>  68  <<
	DC	$82
	DC	"D"	;DC	1,DP	;points to first free byte at end of dictionary
	DC	$D0
	DC.W	FENCE-8
DP	DC.W	DOUSER
	DC.W	XDP-UORIG
;
; ======>>  68.5  <<
	DC	$88
	DC	"VOC-LIN"	;DC	7,VOC-LINK
	DC	$CB
	DC.W	DP-5
VOCLIN	DC.W	DOUSER
	DC.W	XVOCL-UORIG
;
; ======>>  69  <<
	DC	$83
	DC	"BL"	;DC	2,BLK
	DC	$CB
	DC.W	VOCLIN-11
BLK	DC.W	DOUSER
	DC.W	XBLK-UORIG
;
; ======>>  70  <<
	DC	$82
	DC	"I"	;DC	1,IN	;scan pointer for input line buffer
	DC	$CE
	DC.W	BLK-6
IN	DC.W	DOUSER
	DC.W	XIN-UORIG
;
; ======>>  71  <<
	DC	$83
	DC	"OU"	;DC	2,OUT
	DC	$D4
	DC.W	IN-5
OUT	DC.W	DOUSER
	DC.W	XOUT-UORIG
;
; ======>>  72  <<
	DC	$83
	DC	"SC"	;DC	2,SCR
	DC	$D2
	DC.W	OUT-6
SCR	DC.W	DOUSER
	DC.W	XSCR-UORIG
;
; ######>> screen 37 <<
; ======>>  73  <<
	DC	$86
	DC	"OFFSE"	;DC	5,OFFSET
	DC	$D4
	DC.W	SCR-6
OFSET	DC.W	DOUSER
	DC.W	XOFSET-UORIG
;
; ======>>  74  <<
	DC	$87
	DC	"CONTEX"	;DC	6,CONTEXT	;points to pointer to vocab to search first
	DC	$D4
	DC.W	OFSET-9
CONTXT	DC.W	DOUSER
	DC.W	XCONT-UORIG
;
; ======>>  75  <<
	DC	$87
	DC	"CURREN"	;DC	6,CURRENT	;points to pointer to vocab being extended
	DC	$D4
	DC.W	CONTXT-10
CURENT	DC.W	DOUSER
	DC.W	XCURR-UORIG
;
; ======>>  76  <<
	DC	$85
	DC	"STAT"	;DC	4,STATE	;1 if COMPILing, 0 if not
	DC	$C5
	DC.W	CURENT-10
STATE	DC.W	DOUSER
	DC.W	XSTATE-UORIG
;
; ======>>  77  <<
	DC	$84
	DC	"BAS"	;DC	3,BASE	;number base for all input & output
	DC	$C5
	DC.W	STATE-8
BASE	DC.W	DOUSER
	DC.W	XBASE-UORIG
;
; ======>>  78  <<
	DC	$83
	DC	"DP"	;DC	2,DPL
	DC	$CC
	DC.W	BASE-7
DPL	DC.W	DOUSER
	DC.W	XDPL-UORIG
;
; ======>>  79  <<
	DC	$83
	DC	"FL"	;DC	2,FLD
	DC	$C4
	DC.W	DPL-6
FLD	DC.W	DOUSER
	DC.W	XFLD-UORIG
;
; ======>>  80  <<
	DC	$83
	DC	"CS"	;DC	2,CSP
	DC	$D0
	DC.W	FLD-6
CSP	DC.W	DOUSER
	DC.W	XCSP-UORIG
;
; ======>>  81  <<
	DC	$82
	DC	"R"	;DC	1,R#
	DC	$A3
	DC.W	CSP-6
RNUM	DC.W	DOUSER
	DC.W	XRNUM-UORIG
;
; ======>>  82  <<
	DC	$83
	DC	"HL"	;DC	2,HLD
	DC	$C4
	DC.W	RNUM-5
HLD	DC.W	DOCON
	DC.W	XHLD
;
; ======>>  82.5  <<== SPECIAL
	DC	$87
	DC	"COLUMN"	;DC	6,COLUMNS	;line width of terminal
	DC	$D3
	DC.W	HLD-6
COLUMS	DC.W	DOUSER
	DC.W	XCOLUM-UORIG
;
; ######>> screen 38 <<
; ======>>  83  <<
	DC	$82
	DC	"1"	;DC	1,1+
	DC	$AB
	DC.W	COLUMS-10
ONEP	DC.W	DOCOL,ONE,PLUS
	DC.W	SEMIS
;
; ======>>  84  <<
	DC	$82
	DC	"2"	;DC	1,2+
	DC	$AB
	DC.W	ONEP-5
TWOP	DC.W	DOCOL,TWO,PLUS
	DC.W	SEMIS
;
; ======>>  85  <<
	DC	$84
	DC	"HER"	;DC	3,HERE
	DC	$C5
	DC.W	TWOP-5
HERE	DC.W	DOCOL,DP,AT
	DC.W	SEMIS
;
; ======>>  86  <<
	DC	$85
	DC	"ALLO"	;DC	4,ALLOT
	DC	$D4
	DC.W	HERE-7
ALLOT	DC.W	DOCOL,DP,PSTORE
	DC.W	SEMIS
;
; ======>>  87  <<
	DC	$81	; , (comma)
	DC	$AC
	DC.W	ALLOT-8
COMMA	DC.W	DOCOL,HERE,STORE,TWO,ALLOT
	DC.W	SEMIS
;
; ======>>  88  <<
	DC	$82
	DC	"C"	;DC	1,C,
	DC	$AC
	DC.W	COMMA-4
CCOMM	DC.W	DOCOL,HERE,CSTORE,ONE,ALLOT
	DC.W	SEMIS
;
; ======>>  89  <<
	DC	$81	; -
	DC	$AD
	DC.W	CCOMM-5
SUB	DC.W	DOCOL,MINUS,PLUS
	DC.W	SEMIS
;
; ======>>  90  <<
	DC	$81	; =
	DC	$BD
	DC.W	SUB-4
EQUAL	DC.W	DOCOL,SUB,ZEQU
	DC.W	SEMIS
;
; ======>>  91  <<
	DC	$81	; <
	DC	$BC
	DC.W	EQUAL-4
LESS	DC.W	*+2
	pula
	pulb
	tsx
	cmpa	0,x
	ins
	bgt	LESST
	bne	LESSF
	cmpb	1,x
	bhi	LESST
LESSF	clrb
	bra	LESSX
LESST	LDAB	#1
LESSX	clra
	ins
	jmp	PUSHBA
;
; ======>>  92  <<
	DC	$81	; >
	DC	$BE
	DC.W	LESS-4
GREAT	DC.W	DOCOL,SWAP,LESS
	DC.W	SEMIS
;
; ======>>  93  <<
	DC	$83
	DC	"RO"	;DC	2,ROT
	DC	$D4
	DC.W	GREAT-4
ROT	DC.W	DOCOL,TOR,SWAP,FROMR,SWAP
	DC.W	SEMIS
;
; ======>>  94  <<
	DC	$85
	DC	"SPAC"	;DC	4,SPACE
	DC	$C5
	DC.W	ROT-6
SPACE	DC.W	DOCOL,BL,EMIT
	DC.W	SEMIS
;
; ======>>  95  <<
	DC	$83
	DC	"MI"	;DC	2,MIN
	DC	$CE
	DC.W	SPACE-8
MIN	DC.W	DOCOL,OVER,OVER,GREAT,ZBRAN
	DC.W	MIN2-*
	DC.W	SWAP
MIN2	DC.W	DROP
	DC.W	SEMIS
;
; ======>>  96  <<
	DC	$83
	DC	"MA"	;DC	2,MAX
	DC	$D8
	DC.W	MIN-6
MAX	DC.W	DOCOL,OVER,OVER,LESS,ZBRAN
	DC.W	MAX2-*
	DC.W	SWAP
MAX2	DC.W	DROP
	DC.W	SEMIS
;
; ======>>  97  <<
	DC	$84
	DC	"-DU"	;DC	3,-DUP
	DC	$D0
	DC.W	MAX-6
DDUP	DC.W	DOCOL,DUP,ZBRAN
	DC.W	DDUP2-*
	DC.W	DUP
DDUP2	DC.W	SEMIS
;
; ######>> screen 39 <<
; ======>>  98  <<
	DC	$88
	DC	"TRAVERS"	;DC	7,TRAVERSE
	DC	$C5
	DC.W	DDUP-7
TRAV	DC.W	DOCOL,SWAP
TRAV2	DC.W	OVER,PLUS,CLITER
	DC	$7F
	DC.W	OVER,CAT,LESS,ZBRAN
	DC.W	TRAV2-*
	DC.W	SWAP,DROP
	DC.W	SEMIS
;
; ======>>  99  <<
	DC	$86
	DC	"LATES"	;DC	5,LATEST
	DC	$D4
	DC.W	TRAV-11
LATEST	DC.W	DOCOL,CURENT,AT,AT
	DC.W	SEMIS
;
; ======>>  100  <<
	DC	$83
	DC	"LF"	;DC	2,LFA
	DC	$C1
	DC.W	LATEST-9
LFA	DC.W	DOCOL,CLITER
	DC	4
	DC.W	SUB
	DC.W	SEMIS
;
; ======>>  101  <<
	DC	$83
	DC	"CF"	;DC	2,CFA
	DC	$C1
	DC.W	LFA-6
CFA	DC.W	DOCOL,TWO,SUB
	DC.W	SEMIS
;
; ======>>  102  <<
	DC	$83
	DC	"NF"	;DC	2,NFA
	DC	$C1
	DC.W	CFA-6
NFA	DC.W	DOCOL,CLITER
	DC	5
	DC.W	SUB,ONE,MINUS,TRAV
	DC.W	SEMIS
;
; ======>>  103  <<
	DC	$83
	DC	"PF"	;DC	2,PFA
	DC	$C1
	DC.W	NFA-6
PFA	DC.W	DOCOL,ONE,TRAV,CLITER
	DC	5
	DC.W	PLUS
	DC.W	SEMIS
;
; ######>> screen 40 <<
; ======>>  104  <<
	DC	$84
	DC	"!CS"	;DC	3,!CSP
	DC	$D0
	DC.W	PFA-6
SCSP	DC.W	DOCOL,SPAT,CSP,STORE
	DC.W	SEMIS
;
; ======>>  105  <<
	DC	$86
	DC	"?ERRO"	;DC	5,?ERROR
	DC	$D2
	DC.W	SCSP-7
QERR	DC.W	DOCOL,SWAP,ZBRAN
	DC.W	QERR2-*
	DC.W	ERROR,BRAN
	DC.W	QERR3-*
QERR2	DC.W	DROP
QERR3	DC.W	SEMIS
;
; ======>>  106  <<
	DC	$85
	DC	"?COM"	;DC	4,?COMP
	DC	$D0
	DC.W	QERR-9
QCOMP	DC.W	DOCOL,STATE,AT,ZEQU,CLITER
	DC	$11
	DC.W	QERR
	DC.W	SEMIS
;
; ======>>  107  <<
	DC	$85
	DC	"?EXE"	;DC	4,?EXEC
	DC	$C3
	DC.W	QCOMP-8
QEXEC	DC.W	DOCOL,STATE,AT,CLITER
	DC	$12
	DC.W	QERR
	DC.W	SEMIS
;
; ======>>  108  <<
	DC	$86
	DC	"?PAIR"	;DC	5,?PAIRS
	DC	$D3
	DC.W	QEXEC-8
QPAIRS	DC.W	DOCOL,SUB,CLITER
	DC	$13
	DC.W	QERR
	DC.W	SEMIS
;
; ======>>  109  <<
	DC	$84
	DC	"?CS"	;DC	3,?CSP
	DC	$D0
	DC.W	QPAIRS-9
QCSP	DC.W	DOCOL,SPAT,CSP,AT,SUB,CLITER
	DC	$14
	DC.W	QERR
	DC.W	SEMIS
;
; ======>>  110  <<
	DC	$88
	DC	"?LOADIN"	;DC	7,?LOADING
	DC	$C7
	DC.W	QCSP-7
QLOAD	DC.W	DOCOL,BLK,AT,ZEQU,CLITER
	DC	$16
	DC.W	QERR
	DC.W	SEMIS
;
; ######>> screen 41 <<
; ======>>  111  <<
	DC	$87
	DC	"COMPIL"	;DC	6,COMPILE
	DC	$C5
	DC.W	QLOAD-11
COMPIL	DC.W	DOCOL,QCOMP,FROMR,TWOP,DUP,TOR,AT,COMMA
	DC.W	SEMIS
;
; ======>>  112  <<
	DC	$C1	; [	immediate
	DC	$DB
	DC.W	COMPIL-10
LBRAK	DC.W	DOCOL,ZERO,STATE,STORE
	DC.W	SEMIS
;
; ======>>  113  <<
	DC	$81	; ]
	DC	$DD
	DC.W	LBRAK-4
RBRAK	DC.W	DOCOL,CLITER
	DC	$C0
	DC.W	STATE,STORE
	DC.W	SEMIS
;
; ======>>  114  <<
	DC	$86
	DC	"SMUDG"	;DC	5,SMUDGE
	DC	$C5
	DC.W	RBRAK-4
SMUDGE	DC.W	DOCOL,LATEST,CLITER
	DC	$20
	DC.W	TOGGLE
	DC.W	SEMIS
;
; ======>>  115  <<
	DC	$83
	DC	"HE"	;DC	2,HEX
	DC	$D8
	DC.W	SMUDGE-9
HEX	DC.W	DOCOL
	DC.W	CLITER
	DC	16
	DC.W	BASE,STORE
	DC.W	SEMIS
;
; ======>>  116  <<
	DC	$87
	DC	"DECIMA"	;DC	6,DECIMAL
	DC	$CC
	DC.W	HEX-6
DEC	DC.W	DOCOL
	DC.W	CLITER
	DC	10	;note: hex "A"
	DC.W	BASE,STORE
	DC.W	SEMIS
;
; ######>> screen 42 <<
; ======>>  117  <<
	DC	$87
	DC	"(:CODE"	;DC	6,(;CODE)
	DC	$A9
	DC.W	DEC-10
PSCODE	DC.W	DOCOL,FROMR,TWOP,LATEST,PFA,CFA,STORE
	DC.W	SEMIS
;
; ======>>  118  <<
	DC	$C5	;immediate
	DC	";COD"	;DC	4,;CODE
	DC	$C5
	DC.W	PSCODE-10
SEMIC	DC.W	DOCOL,QCSP,COMPIL,PSCODE,SMUDGE,LBRAK,QSTACK
	DC.W	SEMIS
; note: "QSTACK" will be replaced by "ASSEMBLER" later
;
; ######>> screen 43 <<
; ======>>  119  <<
	DC	$87
	DC	"<BUILD"	;DC	6,<BUILDS
	DC	$D3
	DC.W	SEMIC-8
BUILDS	DC.W	DOCOL,ZERO,CON
	DC.W	SEMIS
;
; ======>>  120  <<
	DC	$85
	DC	"DOES"	;DC	4,DOES>
	DC	$BE
	DC.W	BUILDS-10
DOES	DC.W	DOCOL,FROMR,TWOP,LATEST,PFA,STORE
	DC.W	PSCODE
DODOES	LDAA IP
	LDAB	IP+1
	ldx	RP	;make room on return stack
	dex
	dex
	stx	RP
	STAA  	2,x	;push return address
	STAB	3,x
	ldx	W	;get addr of pointer to run-time code
	inx
	inx
	stx	N	;STAA sh it in scratch area
	ldx	0,x	;get new IP
	stx	IP
	clra		;get address of parameter
	LDAB	#2
	addb	N+1
	adca	N
	pshb		;and push it on data stack
	psha
	jmp	NEXT2
;
; ######>> screen 44 <<
; ======>>  121  <<
	DC	$85
	DC	"COUN"	;DC	4,COUNT
	DC	$D4
	DC.W	DOES-8
COUNT	DC.W	DOCOL,DUP,ONEP,SWAP,CAT
	DC.W	SEMIS
;
; ======>>  122  <<
	DC	$84
	DC	"TYP"	;DC	3,TYPE
	DC	$C5
	DC.W	COUNT-8
TYPE	DC.W	DOCOL,DDUP,ZBRAN
	DC.W	TYPE3-*
	DC.W	OVER,PLUS,SWAP,XDO
;
;TYPE2	DC.W	I,CAT,EMIT,XLOOP
;
TYPE2	DC.W	I,CAT,CLITER	;fix to make VLIST
	DC	$7F		;type all the characters
	DC.W	ANDLAB,EMIT,XLOOP	;in the words
;
	DC.W	TYPE2-*
	DC.W	BRAN
	DC.W	TYPE4-*
TYPE3	DC.W	DROP
TYPE4	DC.W	SEMIS
;
; ======>>  123  <<
	DC	$89
	DC	"-TRAILIN"	;DC	8,-TRAILING
	DC	$C7
	DC.W	TYPE-7
DTRAIL	DC.W	DOCOL,DUP,ZERO,XDO
DTRAL2	DC.W	OVER,OVER,PLUS,ONE,SUB,CAT,BL
	DC.W	SUB,ZBRAN
	DC.W	DTRAL3-*
	DC.W	LEAVE,BRAN
	DC.W	DTRAL4-*
DTRAL3	DC.W	ONE,SUB
DTRAL4	DC.W	XLOOP
	DC.W	DTRAL2-*
	DC.W	SEMIS
;
; ======>>  124  <<
	DC	$84
	DC	$28,$2E,$22	;DC	3,(.")
	DC	$A9
	DC.W	DTRAIL-12
PDOTQ	DC.W	DOCOL,R,TWOP,COUNT,DUP,ONEP
	DC.W	FROMR,PLUS,TOR,TYPE
	DC.W	SEMIS
;
; ======>>  125  <<
	DC	$C2	;immediate
	DC	"."	;DC	1,."
	DC	$A2
	DC.W	PDOTQ-7
DOTQ	DC.W	DOCOL
	DC.W	CLITER
	DC	$22	;ascii quote
	DC.W	STATE,AT,ZBRAN
	DC.W	DOTQ1-*
	DC.W	COMPIL,PDOTQ,WORD
	DC.W	HERE,CAT,ONEP,ALLOT,BRAN
	DC.W	DOTQ2-*
DOTQ1	DC.W	WORD,HERE,COUNT,TYPE
DOTQ2	DC.W	SEMIS
;
; ######>> screen 45 <<
; ======>>  126  <<== MACHINE DEPENDENT
	DC	$86
	DC	"?STAC"	;DC	5,?STACK
	DC	$CB
	DC.W	DOTQ-5
QSTACK	DC.W	DOCOL,CLITER
	DC	$12
	DC.W	PORIG,AT,TWO,SUB,SPAT,LESS,ONE
	DC.W	QERR
; prints 'empty stack'
;
QSTAC2	DC.W	SPAT
; Here, we compare with a value at least 128
; higher than dict. ptr. (DP)
	DC.W	HERE,CLITER
	DC	$80
	DC.W	PLUS,LESS,ZBRAN
	DC.W	QSTAC3-*
	DC.W	TWO
	DC.W	QERR
; prints 'full stack'
;
QSTAC3	DC.W	SEMIS
;
; ======>>  127  <<	this word's function
;	    		is done by ?STACK in this version
;	DC	$85
;	DC	"?FRE"	;DC	4,?FREE
;	DC	$C5
;	DC.W	QSTACK-9
;QFREE	DC.W	DOCOL,SPAT,HERE,CLITER
;	DC	$80
;	DC.W	PLUS,LESS,TWO,QERR,SEMIS
;
; ######>> screen 46 <<
; ======>>  128  <<
	DC	$86
	DC	"EXPEC"	;DC	5,EXPECT
	DC	$D4
	DC.W	QSTACK-9
EXPECT	DC.W	DOCOL,OVER,PLUS,OVER,XDO
EXPEC2	DC.W	KEY,DUP,CLITER
	DC	$0E
	DC.W	PORIG,AT,EQUAL,ZBRAN
	DC.W	EXPEC3-*
	DC.W	DROP,CLITER
	DC	8	;(backspace character to emit)
	DC.W	OVER,I,EQUAL,DUP,FROMR,TWO,SUB,PLUS
	DC.W	TOR,SUB,BRAN
	DC.W	EXPEC6-*
EXPEC3	DC.W	DUP,CLITER
	DC	$D	;(carriage return)
	DC.W	EQUAL,ZBRAN
	DC.W	EXPEC4-*
	DC.W	LEAVE,DROP,BL,ZERO,BRAN
	DC.W	EXPEC5-*
EXPEC4	DC.W	DUP
EXPEC5	DC.W	I,CSTORE,ZERO,I,ONEP,STORE
EXPEC6	DC.W	EMIT,XLOOP
	DC.W	EXPEC2-*
	DC.W	DROP
	DC.W	SEMIS
;
; ======>>  129  <<
	DC	$85
	DC	"QUER"	;DC	4,FQUERY
	DC	$D9
	DC.W	EXPECT-9
FQUERY	DC.W	DOCOL,TIB,AT,COLUMS
	DC.W	AT,EXPECT,ZERO,IN,STORE
	DC.W	SEMIS
;
; ======>>  130  <<
	DC	$C1	;immediate	< carriage return >
	DC	$80
	DC.W	FQUERY-8
NULL	DC.W	DOCOL,BLK,AT,ZBRAN
	DC.W	NULL2-*
	DC.W	ONE,BLK,PSTORE
	DC.W	ZERO,IN,STORE,BLK,AT,BSCR,MODLAB
	DC.W	ZEQU
;     check for end of screen
	DC.W	ZBRAN
	DC.W	NULL1-*
	DC.W	QEXEC,FROMR,DROP
NULL1	DC.W	BRAN
	DC.W	NULL3-*
NULL2	DC.W	FROMR,DROP
NULL3	DC.W	SEMIS
;
; ######>> screen 47 <<
; ======>>  133  <<
	DC	$84
	DC	"FIL"	;DC	3,FILL
	DC	$CC
	DC.W	NULL-4
FILL	DC.W	DOCOL,SWAP,TOR,OVER,CSTORE,DUP,ONEP
	DC.W	FROMR,ONE,SUB,CMOVE
	DC.W	SEMIS
;
; ======>>  134  <<
	DC	$85
	DC	"ERAS"	;DC	4,ERASE
	DC	$C5
	DC.W	FILL-7
ERASE	DC.W	DOCOL,ZERO,FILL
	DC.W	SEMIS
;
; ======>>  135  <<
	DC	$86
	DC	"BLANK"	;DC	5,BLANKS
	DC	$D3
	DC.W	ERASE-8
BLANKS	DC.W	DOCOL,BL,FILL
	DC.W	SEMIS
;
; ======>>  136  <<
	DC	$84
	DC	"HOL"	;DC	3,HOLD
	DC	$C4
	DC.W	BLANKS-9
HOLD	DC.W	DOCOL,LIT,$FFFF,HLD,PSTORE,HLD,AT,CSTORE
	DC.W	SEMIS
;
; ======>>  137  <<
	DC	$83
	DC	"PA"	;DC	2,PAD
	DC	$C4
	DC.W	HOLD-7
PAD	DC.W	DOCOL,HERE,CLITER
	DC	$44
	DC.W	PLUS
	DC.W	SEMIS
;
; ######>> screen 48 <<
; ======>>  138  <<
	DC	$84
	DC	"WOR"	;DC	3,WORD
	DC	$C4
	DC.W	PAD-6
WORD	DC.W	DOCOL,BLK,AT,ZBRAN
	DC.W	WORD2-*
	DC.W	BLK,AT,BLOCK,BRAN
	DC.W	WORD3-*
WORD2	DC.W	TIB,AT
WORD3	DC.W	IN,AT,PLUS,SWAP,ENCLOS,HERE,CLITER
	DC	34
	DC.W	BLANKS,IN,PSTORE,OVER,SUB,TOR,R,HERE
	DC.W	CSTORE,PLUS,HERE,ONEP,FROMR,CMOVE
	DC.W	SEMIS
;
; ######>> screen 49 <<
; ======>>  139  <<
	DC	$88
	DC	"(NUMBER"	;DC	7,(NUMBER)
	DC	$A9
	DC.W	WORD-7
PNUMB	DC.W	DOCOL
PNUMB2	DC.W	ONEP,DUP,TOR,CAT,BASE,AT,DIGIT,ZBRAN
	DC.W	PNUMB4-*
	DC.W	SWAP,BASE,AT,USTAR,DROP,ROT,BASE
	DC.W	AT,USTAR,DPLUS,DPL,AT,ONEP,ZBRAN
	DC.W	PNUMB3-*
	DC.W	ONE,DPL,PSTORE
PNUMB3	DC.W	FROMR,BRAN
	DC.W	PNUMB2-*
PNUMB4	DC.W	FROMR
	DC.W	SEMIS
;
; ======>>  140  <<
	DC	$86
	DC	"NUMBE"	;DC	5,NUMBER
	DC	$D2
	DC.W	PNUMB-11
NUMB	DC.W	DOCOL,ZERO,ZERO,ROT,DUP,ONEP,CAT,CLITER
	DC	"-"	;minus sign
	DC.W	EQUAL,DUP,TOR,PLUS,LIT,$FFFF
NUMB1	DC.W	DPL,STORE,PNUMB,DUP,CAT,BL,SUB
	DC.W	ZBRAN
	DC.W	NUMB2-*
	DC.W	DUP,CAT,CLITER
	DC	"."
	DC.W	SUB,ZERO,QERR,ZERO,BRAN
	DC.W	NUMB1-*
NUMB2	DC.W	DROP,FROMR,ZBRAN
	DC.W	NUMB3-*
	DC.W	DMINUS
NUMB3	DC.W	SEMIS
;
; ======>>  141  <<
	DC	$85
	DC	"-FIN"	;DC	4,-FIND
	DC	$C4
	DC.W	NUMB-9
DFIND	DC.W	DOCOL,BL,WORD,HERE,CONTXT,AT,AT
	DC.W	PFIND,DUP,ZEQU,ZBRAN
	DC.W	DFIND2-*
	DC.W	DROP,HERE,LATEST,PFIND
DFIND2	DC.W	SEMIS
;
; ######>> screen 50 <<
; ======>>  142  <<
	DC	$87
	DC	"(ABORT"	;DC	6,(ABORT)
	DC	$A9
	DC.W	DFIND-8
PABORT	DC.W	DOCOL,ABORT
	DC.W	SEMIS
;
; ======>>  143  <<
	DC	$85
	DC	"ERRO"	;DC	4,ERROR
	DC	$D2
	DC.W	PABORT-10
ERROR	DC.W	DOCOL,WARN,AT,ZLESS
	DC.W	ZBRAN
; note: WARNING is -1 to abort, 0 to print ERROR #
; and 1 to print ERROR message from disc
	DC.W	ERROR2-*
	DC.W	PABORT
ERROR2	DC.W	HERE,COUNT,TYPE,PDOTQ
	DC	4,7	;(bell)
	DC	" ? "
	DC.W	MESS,SPSTOR,IN,AT,BLK,AT,QUIT
	DC.W	SEMIS
;
; ======>>  144  <<
	DC	$83
	DC	"ID"	;DC	2,ID.
	DC	$AE
	DC.W	ERROR-8
IDDOT	DC.W	DOCOL,PAD,CLITER
	DC	32
	DC.W	CLITER
	DC	$5F	;(underline)
	DC.W	FILL,DUP,PFA,LFA,OVER,SUB,PAD
	DC.W	SWAP,CMOVE,PAD,COUNT,CLITER
	DC	31
	DC.W	ANDLAB,TYPE,SPACE
	DC.W	SEMIS
;
; ######>> screen 51 <<
; ======>>  145  <<
	DC	$86
	DC	"CREAT"	;DC	5,CREATE
	DC	$C5
	DC.W	IDDOT-6
CREATE	DC.W	DOCOL,DFIND,ZBRAN
	DC.W	CREAT2-*
	DC.W	DROP,PDOTQ
	DC	8
	DC	7	;(bel)
	DC	"redef: "
	DC.W	NFA,IDDOT,CLITER
	DC	4
	DC.W	MESS,SPACE
CREAT2	DC.W	HERE,DUP,CAT,WIDTH,AT,MIN
	DC.W	ONEP,ALLOT,DUP,CLITER
	DC	$A0
	DC.W	TOGGLE,HERE,ONE,SUB,CLITER
	DC	$80
	DC.W	TOGGLE,LATEST,COMMA,CURENT,AT,STORE
	DC.W	HERE,TWOP,COMMA
	DC.W	SEMIS
;
; ######>> screen 52 <<
; ======>>  146  <<
	DC	$C9	;immediate
	DC	"[COMPILE"	;DC	8,[COMPILE]
	DC	$DD
	DC.W	CREATE-9
BcomP	DC.W	DOCOL,DFIND,ZEQU,ZERO,QERR,DROP,CFA,COMMA
	DC.W	SEMIS
;
; ======>>  147  <<
	DC	$C7	;immediate
	DC	"LITERA"	;DC	6,LITERAL
	DC	$CC
	DC.W	BcomP-12
LITER	DC.W	DOCOL,STATE,AT,ZBRAN
	DC.W	LITER2-*
	DC.W	COMPIL,LIT,COMMA
LITER2	DC.W	SEMIS
;
; ======>>  148  <<
	DC	$C8	;immediate
	DC	"DLITERA"	;DC	7,DLITERAL
	DC	$CC
	DC.W	LITER-10
DLITER	DC.W	DOCOL,STATE,AT,ZBRAN
	DC.W	DLITE2-*
	DC.W	SWAP,LITER,LITER
DLITE2	DC.W	SEMIS
;
; ######>> screen 53 <<
; ======>>  149  <<
	DC	$89
	DC	"INTERPRE"	;DC	8,INTERPRET
	DC	$D4
	DC.W	DLITER-11
INTERP	DC.W	DOCOL
INTER2	DC.W	DFIND,ZBRAN
	DC.W	INTER5-*
	DC.W	STATE,AT,LESS
	DC.W	ZBRAN
	DC.W	INTER3-*
	DC.W	CFA,COMMA,BRAN
	DC.W	INTER4-*
INTER3	DC.W	CFA,EXEC
INTER4	DC.W	BRAN
	DC.W	INTER7-*
INTER5	DC.W	HERE,NUMB,DPL,AT,ONEP,ZBRAN
	DC.W	INTER6-*
	DC.W	DLITER,BRAN
	DC.W	INTER7-*
INTER6	DC.W	DROP,LITER
INTER7	DC.W	QSTACK,BRAN
	DC.W	INTER2-*
;	DC.W	SEMIS	;never executed
;
; ######>> screen 54 <<
; ======>>  150  <<
	DC	$89
	DC	"IMMEDIAT"	;DC	8,IMMEDIATE
	DC	$C5
	DC.W	INTERP-12
IMMED	DC.W	DOCOL,LATEST,CLITER
	DC	$40
	DC.W	TOGGLE
	DC.W	SEMIS
;
; ======>>  151  <<
	DC	$8A
	DC	"VOCABULAR"	;DC	9,VOCABULARY
	DC	$D9
	DC.W	IMMED-12
VOCAB	DC.W	DOCOL,BUILDS,LIT,$81A0,COMMA,CURENT,AT,CFA
	DC.W	COMMA,HERE,VOCLIN,AT,COMMA,VOCLIN,STORE,DOES
DOVOC	DC.W	TWOP,CONTXT,STORE
	DC.W	SEMIS
;
; ======>>  152  <<
;
; Note: FORTH does not go here in the rom-able dictionary,
;       since FORTH is a type of variable.
;
;
; ======>>  153  <<
	DC	$8B
	DC	"DEFINITION"	;DC	10,DEFINITIONS
	DC	$D3
	DC.W	VOCAB-13
DEFIN	DC.W	DOCOL,CONTXT,AT,CURENT,STORE
	DC.W	SEMIS
;
; ======>>  154  <<
	DC	$C1	;immediate	(
	DC	$A8
	DC.W	DEFIN-14
PAREN	DC.W	DOCOL,CLITER
	DC	")"
	DC.W	WORD
	DC.W	SEMIS
;
; ######>> screen 55 <<
; ======>>  155  <<
	DC	$84
	DC	"QUI"	;DC	3,QUIT
	DC	$D4
	DC.W	PAREN-4
QUIT	DC.W	DOCOL,ZERO,BLK,STORE
	DC.W	LBRAK
;
;  Here is the outer interpreter
;  which gets a line of input, does it, prints " OK"
;  then repeats :
;
QUIT2	DC.W	RPSTOR,CR,FQUERY,INTERP,STATE,AT,ZEQU
	DC.W	ZBRAN
	DC.W	QUIT3-*
	DC.W	PDOTQ
	DC	3
	DC	" OK"	;DC	3, OK
QUIT3	DC.W	BRAN
	DC.W	QUIT2-*
;	DC.W	SEMIS	;(never executed)
;
; ======>>  156  <<
	DC	$85
	DC	"ABOR"	;DC	4,ABORT
	DC	$D4
	DC.W	QUIT-7
ABORT	DC.W	DOCOL,SPSTOR,DEC,QSTACK,DRZERO,CR,PDOTQ
	DC	14
	DC	"fig-Forth 6303"
	DC.W	FORTH,DEFIN
        DC.W    MTBUF
	DC.W	QUIT
;	DC.W	SEMIS	;never executed
;
; ######>> screen 56 <<
; bootstrap code... moves rom contents to ram :
; ======>>  157  <<
	DC	$84
	DC	"COL"	;DC	3,COLD
	DC	$C4
	DC.W	ABORT-8
COLD	DC.W	*+2
CENT	lds	#REND-1	;top of destination
	ldx	#ERAM	;top of stuff to move
COLD2	dex
	LDAA 0,x
	psha		;move TASK & FORTH to ram
	cpx	#RAM
	bne	COLD2
;
	lds	#XFENCE-1	;put stack at a safe place for now
	ldx	COLINT
	stx	XCOLUM
	ldx	VOCINT
	stx	XVOCL
	ldx	DPINIT
	stx	XDP
	ldx	FENCIN
	stx	XFENCE
;
WENT	lds	#XFENCE-1	;top of destination
	ldx	#FENCIN		;top of stuff to move
WARM2	dex
	LDAA 0,x
	psha
	cpx	#SINIT
	bne	WARM2
;
	lds	SINIT
	ldx	UPINIT
	stx	UP		;init user ram pointer
	ldx	#ABORT
	stx	IP
	nop		;Here is a place to jump to special user
	nop		;initializations such as I/0 interrups
	nop
;
; For systems with TRACE:
	ldx	#00
	stx	TRLIM	;clear trace mode
	ldx	#0
	stx	BRKPT	;clear breakpoint address
	jmp	RPSTOR+2 ;start the virtual machine running !
;
; Here is the stuff that gets copied to ram :
; above the user variables at $3000
; These first two initialise the values of USE and PREV which
; are important when using BLOCK etc.!
;
RAM	DC.W	FIRSTV,FIRSTV,0,0
;
; ======>>  (152)  <<
	DC	$C5	;immediate
	DC	"FORT"	;DC	4,FORTH
	DC	$C8
	DC.W	NOOP-7
RFORTH	DC.W	DODOES,DOVOC,$81A0,TASK-7
	DC.W	0
	DC	"(C) Forth Interest Group, 1979"
	DC	$84
	DC	"TAS"	;DC	3,TASK
	DC	$CB
	DC.W	FORTH-8
RTASK	DC.W	DOCOL,SEMIS
ERAM	DC	"David Lion"
;
; ######>> screen 57 <<
; ======>>  158  <<
	DC	$84
	DC	"S->"	;DC	3,S->D
	DC	$C4
	DC.W	COLD-7
STOD	DC.W	DOCOL,DUP,ZLESS,MINUS
	DC.W	SEMIS
;
; ======>>  159  <<
	DC	$81	; *
	DC	$AA
	DC.W	STOD-7
STAR	DC.W	*+2
	jsr	USTARS
	ins
	ins
	jmp	NEXT
;
; ======>>  160  <<
	DC	$84
	DC	"/MO"	;DC	3,/MODLAB
	DC	$C4
	DC.W	STAR-4
SLMOD	DC.W	DOCOL,TOR,STOD,FROMR,USLASH
	DC.W	SEMIS
;
; ======>>  161  <<
	DC	$81	; /
	DC	$AF
	DC.W	SLMOD-7
SLASH	DC.W	DOCOL,SLMOD,SWAP,DROP
	DC.W	SEMIS
;
; ======>>  162  <<
	DC	$83
	DC	"MO"	;DC	2,MODLAB
	DC	$C4
	DC.W	SLASH-4
MODLAB	DC.W	DOCOL,SLMOD,DROP
	DC.W	SEMIS
;
; ======>>  163  <<
	DC	$85
	DC	"//MO"	;DC	4,//MODLAB
	DC	$C4
	DC.W	MODLAB-6
SSMOD	DC.W	DOCOL,TOR,USTAR,FROMR,USLASH
	DC.W	SEMIS
;
; ======>>  164  <<
	DC	$82
	DC	"*"	;DC	1,*/
	DC	$AF
	DC.W	SSMOD-8
SSLASH	DC.W	DOCOL,SSMOD,SWAP,DROP
	DC.W	SEMIS
;
; ======>>  165  <<
	DC	$85
	DC	"M/MO"	;DC	4,M/MODLAB
	DC	$C4
	DC.W	SSLASH-5
MSMOD	DC.W	DOCOL,TOR,ZERO,R,USLASH
	DC.W	FROMR,SWAP,TOR,USLASH,FROMR
	DC.W	SEMIS
;
; ======>>  166  <<
	DC	$83
	DC	"AB"	;DC	2,ABS
	DC	$D3
	DC.W	MSMOD-8
ABS	DC.W	DOCOL,DUP,ZLESS,ZBRAN
	DC.W	ABS2-*
	DC.W	MINUS
ABS2	DC.W	SEMIS
;
; ======>>  167  <<
	DC	$84
	DC	"DAB"	;DC	3,DABS
	DC	$D3
	DC.W	ABS-6
DABS	DC.W	DOCOL,DUP,ZLESS,ZBRAN
	DC.W	DABS2-*
	DC.W	DMINUS
DABS2	DC.W	SEMIS
;
; ######>> screen 58 <<
; Disc primatives :
; ======>>  168  <<
	DC	$83
	DC	"US"	;DC	2,USE
	DC	$C5
	DC.W	DABS-7
USE	DC.W	DOCON
	DC.W	XUSE
;
; ======>>  169  <<
	DC	$84
	DC	"PRE"	;DC	3,PREV
	DC	$D6
	DC.W	USE-6
PREV	DC.W	DOCON
	DC.W	XPREV
;
; ======>>  170  <<
	DC	$84
	DC	"+BU"	;DC	3,+BUF
	DC	$C6
	DC.W	PREV-7
PBUF	DC.W	DOCOL,CLITER
	DC	$84
	DC.W	PLUS,DUP,LIMIT,EQUAL,ZBRAN
	DC.W	PBUF2-*
	DC.W	DROP,FIRST
PBUF2	DC.W	DUP,PREV,AT,SUB
	DC.W	SEMIS
;
; ======>>  171  <<
	DC	$86
	DC	"UPDAT"	;DC	5,UPDATE
	DC	$C5
	DC.W	PBUF-7
UPDATE	DC.W	DOCOL,PREV,AT,AT,LIT,$8000,ORLAB,PREV,AT,STORE
	DC.W	SEMIS
;
; ======>>  172  <<
	DC	$8D
	DC	"EMPTY-BUFFER"	;DC	12,EMPTY-BUFFERS
	DC	$D3
	DC.W	UPDATE-9
MTBUF	DC.W	DOCOL,FIRST,LIMIT,OVER,SUB,ERASE
	DC.W	SEMIS
;
; ======>>  173  <<
	DC	$83
	DC	"DR"	;DC	2,DR0
	DC	$B0
	DC.W	MTBUF-16
DRZERO	DC.W	DOCOL,ZERO,OFSET,STORE
	DC.W	SEMIS
;
; ======>>  174  <<== system dependant word
	DC	$83
	DC	"DR"	;DC	2,DR1
	DC	$B1
	DC.W	DRZERO-6
DRONE	DC.W	DOCOL,LIT,$07D0,OFSET,STORE
	DC.W	SEMIS
;
; ######>> screen 59 <<
; ======>>  175  <<
	DC	$86
	DC	"BUFFE"	;DC	5,BUFFER
	DC	$D2
	DC.W	DRONE-6
BUFFER	DC.W	DOCOL,USE,AT,DUP,TOR
BUFFR2	DC.W	PBUF,ZBRAN
	DC.W	BUFFR2-*
	DC.W	USE,STORE,R,AT,ZLESS
	DC.W	ZBRAN
	DC.W	BUFFR3-*
	DC.W	R,TWOP,R,AT,LIT,$7FFF,ANDLAB,ZERO,RW
BUFFR3	DC.W	R,STORE,R,PREV,STORE,FROMR,TWOP
	DC.W	SEMIS
;
; ######>> screen 60 <<
; ======>>  176  <<
	DC	$85
	DC	"BLOC"	;DC	4,BLOCK
	DC	$CB
	DC.W	BUFFER-9
BLOCK	DC.W	DOCOL,OFSET,AT,PLUS,TOR
	DC.W	PREV,AT,DUP,AT,R,SUB,DUP,PLUS,ZBRAN
	DC.W	BLOCK5-*
BLOCK3	DC.W	PBUF,ZEQU,ZBRAN
	DC.W	BLOCK4-*
	DC.W	DROP,R,BUFFER,DUP,R,ONE,RW,TWO,SUB
BLOCK4	DC.W	DUP,AT,R,SUB,DUP,PLUS,ZEQU,ZBRAN
	DC.W	BLOCK3-*
	DC.W	DUP,PREV,STORE
BLOCK5	DC.W	FROMR,DROP,TWOP
	DC.W	SEMIS
;
; ######>> screen 61 <<
; ======>>  177  <<
	DC	$86
	DC	"(LINE"	;DC	5,(LINE)
	DC	$A9
	DC.W	BLOCK-8
PLINE	DC.W	DOCOL,TOR,CLITER
	DC	$40
	DC.W	BBUF,SSMOD,FROMR,BSCR,STAR,PLUS,BLOCK,PLUS,CLITER
	DC	$40
	DC.W	SEMIS
;
; ======>>  178  <<
	DC	$85
	DC	".LIN"	;DC	4,.LINE
	DC	$C5
	DC.W	PLINE-9
DLINE	DC.W	DOCOL,PLINE,DTRAIL,TYPE
	DC.W	SEMIS
;
; ======>>  179  <<
	DC	$87
	DC	"MESSAG"	;DC	6,MESSAGE
	DC	$C5
	DC.W	DLINE-8
MESS	DC.W	DOCOL,WARN,AT,ZBRAN
	DC.W	MESS3-*
	DC.W	DDUP,ZBRAN
	DC.W	MESS3-*
	DC.W	CLITER
	DC	4
	DC.W	OFSET,AT,BSCR,SLASH,SUB,DLINE,BRAN
	DC.W	MESS4-*
MESS3	DC.W	PDOTQ
	DC	6
	DC	"err # "	;DC	6,err #
	DC.W	DOT
MESS4	DC.W	SEMIS
;
; ======>>  180  <<
	DC	$84
	DC	"LOA"	;DC	3,LOAD	;input:scr #
	DC	$C4
	DC.W	MESS-10
LOAD	DC.W	DOCOL,BLK,AT,TOR,IN,AT,TOR,ZERO,IN,STORE
	DC.W	BSCR,STAR,BLK,STORE
	DC.W	INTERP,FROMR,IN,STORE,FROMR,BLK,STORE
	DC.W	SEMIS
;
; ======>>  181  <<
	DC	$C3
	DC	"--"	;DC	2,-->
	DC	$BE
	DC.W	LOAD-7
ARROW	DC.W	DOCOL,QLOAD,ZERO,IN,STORE,BSCR
	DC.W	BLK,AT,OVER,MODLAB,SUB,BLK,PSTORE
	DC.W	SEMIS
;
;
; ######>> screen 63 <<
;    The next 4 subroutines are machine dependent, and are
;    called by words 13 through 16 in the dictionary.
;
;
; ======>>  182  << code for EMIT
PEMIT	JSR	lcd_putch
	RTS		;only A register may change

; ======>>  183  << code for KEY
PKEY	JSR	keyb_getch
	RTS

;
; ######>> screen 64 <<
; ======>>  184  << code for ?TERMINAL
; We'll just use this to pause output while SHIFT is held.
PQTER   JSR lcd_shifted
        BNE PQTER
        LDAA #0 ;don't break
PQTER2	rts
;
; ======>>  185  << code for CR
PCR	LDAA #$D	;carriage return
	bsr	PEMIT
	LDAA #$A	;line feed
	bra	PEMIT
;
; ######>> screen 66 <<
; ======>>  187  <<
	DC	$85
	DC	"?DIS"	;DC	4,?DISC
	DC	$C3
	DC.W	ARROW-6
QDISC	DC.W	*+2
	jmp	NEXT
;
; ######>> screen 67 <<
; ======>>  189  <<
	DC	$8B
	DC	"BLOCK_WRIT"	;DC	10,BLOCK-WRITE
	DC	$C5
	DC.W	QDISC-8
BWRITE	DC.W	*+2
	jmp	NEXT
;
; ######>> screen 68 <<
; ======>>  190  <<
	DC	$8A
	DC	"BLOCK_REA"	;DC	9,BLOCK-READ
	DC	$C4
	DC.W	BWRITE-14
BREAD	DC.W	*+2
	jmp	NEXT
;
; The next 3 words are written to create a substitute for disc
; mass memory,located between $2000 & $2FFF in ram.
; The logic in R/W has been adjusted to that the first screen
; is screen 1, rather than screen 0, as there is other logic
; elsewhere which says that block 0 indicates terminal I/O.
;
; ======>>  190.1  <<
	DC	$82
	DC	"L"	;DC	1,LO
	DC	$CF
	DC.W	BREAD-13
LO	DC.W	DOCON
	DC.W	VDISK_LO
;
; ======>>  190.2  <<
	DC	$82
	DC	"H"	;DC	1,HI
	DC	$C9
	DC.W	LO-5
HI	DC.W	DOCON
	DC.W	VDISK_HI
;
; ######>> screen 69 <<
; ======>>  191  <<
	DC	$83
	DC	"R/"	;DC	2,R/W
	DC	$D7
	DC.W	HI-5
RW	DC.W	DOCOL,TOR,BSCR,SUB,BBUF,STAR,LO,PLUS
        DC.W    DUP,HI,GREAT,OVER,LO,LESS,ORLAB,ZBRAN
	DC.W	RW2-*
	DC.W	PDOTQ
	DC	8
	DC	" Range ;"	;DC	8, Range ;?
	DC.W	QUIT
RW2	DC.W	FROMR,ZBRAN
	DC.W	RW3-*
	DC.W	SWAP
RW3	DC.W	BBUF,CMOVE
	DC.W	SEMIS
;
; ######>> screen 72 <<
; ======>>  192  <<
	DC	$C1	;immediate
	DC	$A7	; ' (tick)
	DC.W	RW-6
TICK	DC.W	DOCOL,DFIND,ZEQU,ZERO,QERR,DROP,LITER
	DC.W	SEMIS
;
; ======>>  193  <<
	DC	$86
	DC	"FORGE"	;DC	5,FORGET
	DC	$D4
	DC.W	TICK-4
FORGET	DC.W	DOCOL,CURENT,AT,CONTXT,AT,SUB,CLITER
	DC	$18
	DC.W	QERR,TICK,DUP,FENCE,AT,LESS,CLITER
	DC	$15
	DC.W	QERR,DUP,ZERO,PORIG,GREAT,CLITER
	DC	$15
	DC.W	QERR,DUP,NFA,DP,STORE,LFA,AT,CONTXT,AT,STORE
	DC.W	SEMIS
;
; ######>> screen 73 <<
; ======>>  194  <<
	DC	$84
	DC	"BAC"	;DC	3,BACK
	DC	$CB
	DC.W	FORGET-9
BACK	DC.W	DOCOL,HERE,SUB,COMMA
	DC.W	SEMIS
;
; ======>>  195  <<
	DC	$C5
	DC	"BEGI"	;DC	4,BEGIN
	DC	$CE
	DC.W	BACK-7
BEGIN	DC.W	DOCOL,QCOMP,HERE,ONE
	DC.W	SEMIS
;
; ======>>  196  <<
	DC	$C5
	DC	"ENDI"	;DC	4,ENDIF
	DC	$C6
	DC.W	BEGIN-8
ENDIF	DC.W	DOCOL,QCOMP,TWO,QPAIRS,HERE
	DC.W	OVER,SUB,SWAP,STORE
	DC.W	SEMIS
;
; ======>>  197  <<
	DC	$C4
	DC	"THE"	;DC	3,THEN
	DC	$CE
	DC.W	ENDIF-8
THEN	DC.W	DOCOL,ENDIF
	DC.W	SEMIS
;
; ======>>  198  <<
	DC	$C2
	DC	"D"	;DC	1,DO
	DC	$CF
	DC.W	THEN-7
DO	DC.W	DOCOL,COMPIL,XDO,HERE,THREE
	DC.W	SEMIS
;
; ======>>  199  <<
	DC	$C4
	DC	"LOO"	;DC	3,LOOP
	DC	$D0
	DC.W	DO-5
LOOP	DC.W	DOCOL,THREE,QPAIRS,COMPIL,XLOOP,BACK
	DC.W	SEMIS
;
; ======>>  200  <<
	DC	$C5
	DC	"+LOO"	;DC	4,+LOOP
	DC	$D0
	DC.W	LOOP-7
PLOOP	DC.W	DOCOL,THREE,QPAIRS,COMPIL,XPLOOP,BACK
	DC.W	SEMIS
;
; ======>>  201  <<
	DC	$C5
	DC	"UNTI"	;DC	4,UNTIL	;(same as END)
	DC	$CC
	DC.W	PLOOP-8
UNTIL	DC.W	DOCOL,ONE,QPAIRS,COMPIL,ZBRAN,BACK
	DC.W	SEMIS
;
; ######>> screen 74 <<
; ======>>  202  <<
	DC	$C3
	DC	"EN"	;DC	2,END
	DC	$C4
	DC.W	UNTIL-8
END	DC.W	DOCOL,UNTIL
	DC.W	SEMIS
;
; ======>>  203  <<
	DC	$C5
	DC	"AGAI"	;DC	4,AGAIN
	DC	$CE
	DC.W	END-6
AGAIN	DC.W	DOCOL,ONE,QPAIRS,COMPIL,BRAN,BACK
	DC.W	SEMIS
;
; ======>>  204  <<
	DC	$C6
	DC	"REPEA"	;DC	5,REPEAT
	DC	$D4
	DC.W	AGAIN-8
REPEAT	DC.W	DOCOL,TOR,TOR,AGAIN,FROMR,FROMR
	DC.W	TWO,SUB,ENDIF
	DC.W	SEMIS
;
; ======>>  205  <<
	DC	$C2
	DC	"I"	;DC	1,IF
	DC	$C6
	DC.W	REPEAT-9
IF	DC.W	DOCOL,COMPIL,ZBRAN,HERE,ZERO,COMMA,TWO
	DC.W	SEMIS
;
; ======>>  206  <<
	DC	$C4
	DC	"ELS"	;DC	3,ELSE
	DC	$C5
	DC.W	IF-5
ELSE	DC.W	DOCOL,TWO,QPAIRS,COMPIL,BRAN,HERE
	DC.W	ZERO,COMMA,SWAP,TWO,ENDIF,TWO
	DC.W	SEMIS
;
; ======>>  207  <<
	DC	$C5
	DC	"WHIL"	;DC	4,WHILE
	DC	$C5
	DC.W	ELSE-7
WHILE	DC.W	DOCOL,IF,TWOP
	DC.W	SEMIS
;
; ######>> screen 75 <<
; ======>>  208  <<
	DC	$86
	DC	"SPACE"	;DC	5,SPACES
	DC	$D3
	DC.W	WHILE-8
SPACES	DC.W	DOCOL,ZERO,MAX,DDUP,ZBRAN
	DC.W	SPACE3-*
	DC.W	ZERO,XDO
SPACE2	DC.W	SPACE,XLOOP
	DC.W	SPACE2-*
SPACE3	DC.W	SEMIS
;
; ======>>  209  <<
	DC	$82
	DC	"<"	;DC	1,<#
	DC	$A3
	DC.W	SPACES-9
BDIGS	DC.W	DOCOL,PAD,HLD,STORE
	DC.W	SEMIS
;
; ======>>  210  <<
	DC	$82
	DC	"#"	;DC	1,#>
	DC	$BE
	DC.W	BDIGS-5
EDIGS	DC.W	DOCOL,DROP,DROP,HLD,AT,PAD,OVER,SUB
	DC.W	SEMIS
;
; ======>>  211  <<
	DC	$84
	DC	"SIG"	;DC	3,SIGN
	DC	$CE
	DC.W	EDIGS-5
SIGN	DC.W	DOCOL,ROT,ZLESS,ZBRAN
 	DC.W	SIGN2-*
 	DC.W	CLITER
 	DC	"-"
 	DC.W	HOLD
SIGN2	DC.W	SEMIS
;
; ======>>  212  <<
	DC	$81	; #
	DC	$A3
	DC.W	SIGN-7
DIG	DC.W	DOCOL,BASE,AT,MSMOD,ROT,CLITER
	DC	9
	DC.W	OVER,LESS,ZBRAN
	DC.W	DIG2-*
	DC.W	CLITER
	DC	7
	DC.W	PLUS
DIG2	DC.W	CLITER
	DC	"0"	;ascii zero
	DC.W	PLUS,HOLD
	DC.W	SEMIS
;
; ======>>  213  <<
	DC	$82
	DC	"#"	;DC	1,#S
	DC	$D3
	DC.W	DIG-4
DIGS	DC.W	DOCOL
DIGS2	DC.W	DIG,OVER,OVER,ORLAB,ZEQU,ZBRAN
	DC.W	DIGS2-*
	DC.W	SEMIS
;
; ######>> screen 76 <<
; ======>>  214  <<
	DC	$82
	DC	"."	;DC	1,.R
	DC	$D2
	DC.W	DIGS-5
DOTR	DC.W	DOCOL,TOR,STOD,FROMR,DDOTR
	DC.W	SEMIS
;
; ======>>  215  <<
	DC	$83
	DC	"D."	;DC	2,D.R
	DC	$D2
	DC.W	DOTR-5
DDOTR	DC.W	DOCOL,TOR,SWAP,OVER,DABS,BDIGS,DIGS,SIGN
	DC.W	EDIGS,FROMR,OVER,SUB,SPACES,TYPE
	DC.W	SEMIS
;
; ======>>  216  <<
	DC	$82
	DC	"D"	;DC	1,D.
	DC	$AE
	DC.W	DDOTR-6
DDOT	DC.W	DOCOL,ZERO,DDOTR,SPACE
	DC.W	SEMIS
;
; ======>>  217  <<
	DC	$81	; .
	DC	$AE
	DC.W	DDOT-5
DOT	DC.W	DOCOL,STOD,DDOT
	DC.W	SEMIS
;
; ======>>  218  <<
	DC	$81	; ?
	DC	$BF
	DC.W	DOT-4
QUEST	DC.W	DOCOL,AT,DOT
	DC.W	SEMIS
;
; ######>> screen 77 <<
; ======>>  219  <<
	DC	$84
	DC	"LIS"	;DC	3,LIST
	DC	$D4
	DC.W	QUEST-4
LIST	DC.W	DOCOL,DEC,CR,DUP,SCR,STORE,PDOTQ
	DC	6
	DC	"SCR # "
	DC.W	DOT,CLITER
	DC	$10
	DC.W	ZERO,XDO
LIST2	DC.W	CR,I,THREE,QTERM,DROP
	DC.W	DOTR,SPACE,I,SCR,AT,DLINE,XLOOP
	DC.W	LIST2-*
	DC.W	CR
	DC.W	SEMIS
;
; ======>>  220  <<
	DC	$85
	DC	"INDE"	;DC	4,INDEX
	DC	$D8
	DC.W	LIST-7
INDEX	DC.W	DOCOL,CR,ONEP,SWAP,XDO
INDEX2	DC.W	CR,I,THREE
	DC.W	DOTR,SPACE,ZERO,I,DLINE
	DC.W	QTERM,ZBRAN
	DC.W	INDEX3-*
	DC.W	LEAVE
INDEX3	DC.W	XLOOP
	DC.W	INDEX2-*
	DC.W	SEMIS
;
; ======>>  221  <<
	DC	$85
	DC	"TRIA"	;DC	4,TRIAD
	DC	$C4
	DC.W	INDEX-8
TRIAD	DC.W	DOCOL,THREE,SLASH,THREE,STAR
	DC.W	THREE,OVER,PLUS,SWAP,XDO
TRIAD2	DC.W	CR,I
	DC.W	LIST,QTERM,ZBRAN
	DC.W	TRIAD3-*
	DC.W	LEAVE
TRIAD3	DC.W	XLOOP
	DC.W	TRIAD2-*
	DC.W	CR,CLITER
	DC	$0F
	DC.W	MESS,CR
	DC.W	SEMIS
;
; ######>> screen 78 <<
; ======>>  222  <<
	DC	$85
	DC	"VLIS"	;DC	4,VLIST
	DC	$D4
	DC.W	TRIAD-8
VLIST	DC.W	DOCOL,CLITER
	DC	$80
	DC.W	OUT,STORE,CONTXT,AT,AT
VLIST1	DC.W	OUT,AT,COLUMS,AT,CLITER
	DC	32
	DC.W	SUB,GREAT,ZBRAN
	DC.W	VLIST2-*
	DC.W	CR,ZERO,OUT,STORE
VLIST2	DC.W	DUP,IDDOT,SPACE,SPACE,PFA,LFA,AT
	DC.W	DUP,ZEQU,QTERM,ORLAB,ZBRAN
	DC.W	VLIST1-*
	DC.W	DROP
	DC.W	SEMIS
;
; ======>>  XX  <<
	DC	$84
	DC	"NOO"	;DC	3,NOOP
	DC	$D0
	DC.W	VLIST-8
NOOP	DC.W	NEXT	;a useful no-op
ZZZZ	DC.W	0,0,0,0,0,0,0,0	;end of rom program

	END
