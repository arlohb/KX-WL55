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
; Missing: WHERE, #LOCATE, #LEAD, #LAG,
;
dmove
        DC      $85
        DC      "-MOV"
        DC      $C5
        DC.W    line
DMOVE   DC.W    DOCOL,LINE,CL,CMOVE,UPDATE
        DC.W    SEMIS

;
; ######>> screen 89 <<
;
; Note: to prevent clashes with hex values, etc., these commands have a / prepended
; In the original forth, they're H, E, etc., here /H, /E etc.
;
; Missing: /S, /D
;
slh
        DC      $82
        DC      "/"
        DC      $C8
        DC.W    dmove
SLH     DC.W    DOCOL,LINE,PAD,ONEP,CL,DUP,PAD,CSTORE,CMOVE
        DC.W    SEMIS

sle
        DC      $82
        DC      "/"
        DC      $C5
        DC.W    slh
SLE     DC.W    DOCOL,LINE,CL,BLANKS,UPDATE
        DC.W    SEMIS

;
; ######>> screen 90 <<
;
; Missing: /M, /T
; /L is incomplete due to lack of /M
;

sll
        DC      $82
        DC      "/"
        DC      $CC
        DC.W    sle
SLL     DC.W    DOCOL,SCR,AT,LIST
        DC.W    SEMIS

;
; ######>> screen 91 <<
;
; Missing: /I, TOP
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

;
; ######>> screen 92 <<<
;

clear
        DC      $85
        DC      "CLEA"
        DC      $D2
        DC.W    slp
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

last_editor             ; *** MUST BE AT THE BEGINNING OF THE *LAST* WORD IN THIS FILE!
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


