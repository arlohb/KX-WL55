; Line editor words

;
; ######>> screen 87 <<
;
        ; HEX
        ; 40 CONSTANT C/L
cl
        DC      $83     ; Name length + $80
        DC      "C/"    ; All but last char of name
        DC      $CC     ; last char + $80
        DC.W    last_forth
CL      DC.W    DOCON
        DC.W    $40
;       chars/per line in a page = 64

text
        DC      $84     ; Name length + $80
        DC      "TEX"   ; All but last char of name
        DC      $D4     ; last char + $80
        DC.W    cl
TEXT    DC.W    DOCOL,HERE,CL,ONEP,BLANKS,WORD,HERE,PAD,CL,ONEP,CMOVE
        DC.W    SEMIS

line
        DC      $84
        DC      "LIN"
        DC      $C5
        DC.W    text
LINE    DC.W    DOCOL,DUP,LIT,$FFF0,ANDLAB,CLITER
        DC      $17
        DC.W    QERR,SCR,AT,PLINE,DROP
        DC.W    SEMIS

;
; ######>> screen 88 <<
;
; Missing: WHERE
;
dmove
        DC      $85
        DC      "-MOV"
        DC      $C5
        DC.W    line
DMOVE   DC.W    DOCOL,LINE,CL,CMOVE,UPDATE
        DC.W    SEMIS

hlocate
        DC      $87
        DC      "#LOCAT"
        DC      $C5
        DC.W    dmove
HLOCATE DC.W    DOCOL
        DC.W    RNUM,AT,CL,SLMOD
        DC.W    SEMIS

hlead   DC      $85
        DC      "#LEA"
        DC      $C4
        DC.W    hlocate
HLEAD   DC.W    DOCOL
        DC.W    HLOCATE,LINE,SWAP
        DC.W    SEMIS

hlag    DC      $84
        DC      "#LA"
        DC      $C7
        DC.W    hlead
HLAG    DC.W    DOCOL
        DC.W    HLEAD,DUP,TOR,PLUS,CL,FROMR,SUB
        DC.W    SEMIS

;
; ######>> screen 89 <<
;
; Note: to prevent clashes with hex values, etc., these commands have a / prepended
; In the original forth, they're H, E, etc., here /H, /E etc.
;
slh
        DC      $82
        DC      "/"
        DC      $C8
        DC.W    hlag
SLH     DC.W    DOCOL,LINE,PAD,ONEP,CL,DUP,PAD,CSTORE,CMOVE
        DC.W    SEMIS

sle
        DC      $82
        DC      "/"
        DC      $C5
        DC.W    slh
SLE     DC.W    DOCOL,LINE,CL,BLANKS,UPDATE
        DC.W    SEMIS

sls
        DC      $82
        DC      "/"
        DC      $D3
        DC.W    sle
SLS     DC.W    DOCOL
        DC.W    DUP,ONE,SUB,LIT,$0E,XDO
SLS2    DC.W    I,LINE,I,ONEP,DMOVE,LIT,$FFFF,XPLOOP
        DC.W    SLS2-*
        DC.W    SLE
        DC.W    SEMIS

sld
        DC      $82
        DC      "/"
        DC      $C4
        DC.W    sls
SLD     DC.W    DOCOL
        DC.W    DUP,SLH,LIT,$F,DUP,ROT,XDO
SLD2    DC.W    I,ONEP,LINE,I,DMOVE,XLOOP
        DC.W    SLD2-*
        DC.W    SLE
        DC.W    SEMIS
;
; ######>> screen 90 <<
;

slm     DC      $82
        DC      "/"
        DC      $CD
        DC.W    sld
SLM     DC.W    DOCOL
        DC.W    RNUM,PSTORE,CR,SPACE,HLEAD,TYPE,CLITER
        DC      "_"
        DC.W    EMIT,HLAG,TYPE,HLOCATE,DOT,DROP
        DC.W    SEMIS

slt     DC      $82
        DC      "/"
        DC      $D4
        DC.W    slm
SLT     DC.W    DOCOL
        DC.W    DUP,CL,STAR,RNUM,STORE,DUP,SLH,LIT,$0,SLM
        DC.W    SEMIS

sll     DC      $82
        DC      "/"
        DC      $CC
        DC.W    slt
SLL     DC.W    DOCOL
        DC.W    SCR,AT,LIST,LIT,$0,SLM
        DC.W    SEMIS

;
; ######>> screen 91 <<
;

slr
        DC      $82
        DC      "/"
        DC      $D2
        DC.W    sll
SLR     DC.W    DOCOL,PAD,ONEP,SWAP,DMOVE
        DC.W    SEMIS

slp
        DC      $82
        DC      "/"
        DC      $D0
        DC.W    slr
SLP     DC.W    DOCOL,ONE,TEXT,SLR
        DC.W    SEMIS

sli
        DC      $82
        DC      "/"
        DC      $C9
        DC.W    slp
SLI     DC.W    DOCOL
        DC.W    DUP,SLS,SLR
        DC.W    SEMIS

top
        DC      $83
        DC      "TO"
        DC      $D0
        DC.W    sli
TOP     DC.W    DOCOL
        DC.W    LIT,$0,RNUM,STORE
        DC.W    SEMIS

;
; ######>> screen 92 <<<
;

clear
        DC      $85
        DC      "CLEA"
        DC      $D2
        DC.W    top
CLEAR   DC.W    DOCOL,SCR,STORE,CLITER
        DC      $10
        DC.W    ZERO,XDO
CLEAR2  DC.W    I,SLE
        DC.W    XLOOP
        DC.W    CLEAR2-*
        DC.W    SEMIS

flush
        DC      $85
        DC      "FLUS"
        DC      $C8
        DC.W    clear
FLUSH   DC.W    DOCOL,LIT,(MEMEND-FIRSTV)/132   ; (LIMIT-FIRST)/(BBUF+4)
        DC.W    ZERO,XDO
FLUSH2  DC.W    LIT,$7FFF,BUFFER,DROP
        DC.W    XLOOP
        DC.W    FLUSH2-*
        DC.W    SEMIS

copy
        DC      $84
        DC      "COP"
        DC      $D9
        DC.W    flush
COPY    DC.W    DOCOL,BSCR,STAR,OFSET,AT,PLUS,SWAP,BSCR,STAR,BSCR,OVER,PLUS,SWAP
        DC.W    XDO
COPY2   DC.W    DUP,I,BLOCK,TWO,SUB,STORE,ONEP,UPDATE
        DC.W    XLOOP
        DC.W    COPY2-*
        DC.W    DROP,FLUSH
        DC.W    SEMIS

;
; ######>> screen 93 <<<
; (really Forth definitions)
;
twodrop
        DC      $85
        DC      "2DRO"
        DC      $D0
        DC.W    copy
TWODROP DC.W    DOCOL
        DC.W    DROP,DROP
        DC.W    SEMIS

twodup
        DC      $84
        DC      "2DU"
        DC      $D0
        DC.W    twodrop
TWODUP  DC.W    DOCOL
        DC.W    OVER,OVER
        DC.W    SEMIS

twoswap
        DC      $85
        DC      "2SWA"
        DC      $D0
        DC.W    twodup
TWOSWAP DC.W    DOCOL
        DC.W    ROT,TOR,ROT,FROMR
        DC.W    SEMIS

;
; ######>> screen 94 <<
;
dtext
        DC      $85
        DC      "-TEX"
        DC      $D4
        DC.W    twoswap
DTEXT   DC.W    DOCOL
        DC.W    SWAP,DDUP,ZBRAN
        DC.W    DTEXT5-*
        DC.W    OVER,PLUS,SWAP,XDO
DTEXT2  DC.W    DUP,CAT,I,CAT,SUB,ZBRAN
        DC.W    DTEXT3-*
        DC.W    ZEQU,LEAVE,BRAN
        DC.W    DTEXT4-*
DTEXT3  DC.W    ONEP
DTEXT4  DC.W    XLOOP
        DC.W    DTEXT2-*
        DC.W    BRAN
        DC.W    DTEXT6-*
DTEXT5  DC.W    DROP,ZEQU
DTEXT6  DC.W    SEMIS

match
        DC      $85
        DC      "MATC"
        DC      $C8
        DC.W    dtext
MATCH   DC.W    DOCOL
        DC.W    TOR,TOR,TWODUP,FROMR,FROMR,TWOSWAP,OVER,PLUS,SWAP,XDO
MATCH2  DC.W    TWODUP,I,DTEXT,ZBRAN
        DC.W    MATCH3-*
        DC.W    TOR,TWODROP,FROMR,SUB,I,SWAP,SUB,ZERO,SWAP,ZERO,ZERO,LEAVE
MATCH3  DC.W    XLOOP
        DC.W    MATCH2-*
        DC.W    TWODROP,SWAP,ZEQU,SWAP
        DC.W    SEMIS

;
; ######>> screen 95 <<
;
oneline
        DC      $85
        DC      "1LIN"
        DC      $C5
        DC.W    match
ONELINE DC.W    DOCOL
        DC.W    HLAG,PAD,COUNT,MATCH,RNUM,PSTORE
        DC.W    SEMIS

find
        DC      $84
        DC      "FIN"
        DC      $C4
        DC.W    oneline
FIND    DC.W    DOCOL
FIND2   DC.W    LIT,$3FF,RNUM,AT,LESS,ZBRAN
        DC.W    FIND3-*
        DC.W    TOP,PAD,HERE,CL,ONEP,CMOVE,ZERO,ERROR
FIND3   DC.W    ONELINE,ZBRAN
        DC.W    FIND2-*
        DC.W    SEMIS

delete
        DC      $86
        DC      "DELET"
        DC      $C5
        DC.W    oneline
DELETE  DC.W    DOCOL
        DC.W    TOR,HLAG,PLUS,R,SUB,HLAG,R,MINUS,RNUM,PSTORE,HLEAD,PLUS,SWAP,CMOVE,FROMR,BLANKS,UPDATE
        DC.W    SEMIS

;
; ######>> screen 96 <<
;
sln
        DC      $82
        DC      "/"
        DC      $CE
        DC.W    delete
SLN     DC.W    DOCOL
        DC.W    FIND,ZERO,SLM
        DC.W    SEMIS

slf     DC      $82
        DC      "/"
        DC      $C6
        DC.W    sln
SLF     DC.W    DOCOL
        DC.W    ONE,TEXT,SLN
        DC.W    SEMIS

slb     DC      $82
        DC      "/"
        DC      $C2
        DC.W    slf
SLB     DC.W    DOCOL
        DC.W    PAD,CAT,MINUS,SLM
        DC.W    SEMIS

slx     DC      $82
        DC      "/"
        DC      $D8
        DC.W    slb
SLX     DC.W    DOCOL
        DC.W    ONE,TEXT,FIND,PAD,CAT,DELETE,ZERO,SLM
        DC.W    SEMIS

till    DC      $84
        DC      "TIL"
        DC      $CC
        DC.W    slx
TILL    DC.W    DOCOL
        DC.W    HLEAD,PLUS,ONE,TEXT,ONELINE,ZEQU,ZERO,QERR,HLEAD,PLUS,SWAP,SUB,DELETE,ZERO,SLM
        DC.W    SEMIS

;
; ######>> screen 97 <<
;
last_editor             ; *** MUST BE AT THE BEGINNING OF THE *LAST* WORD IN THIS FILE!
slc
        DC      $82
        DC      "/"
        DC      $C3
        DC.W    till
SLC     DC.W    DOCOL
        DC.W    ONE,TEXT,PAD,COUNT,HLAG,ROT,OVER,MIN,TOR,R,RNUM,PSTORE
        DC.W    R,SUB,TOR,DUP,HERE,R,CMOVE,HERE,HLEAD,PLUS,FROMR,CMOVE
        DC.W    FROMR,CMOVE,UPDATE,ZERO,SLM
        DC.W    SEMIS


