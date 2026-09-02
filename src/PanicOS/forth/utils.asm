; Utility words


;       .S ( --- )
;       Non-destructive stack emit
;       : .S SP@ S0 @ = IF ." EMPTY" ELSE
;         SP@ 2 - S0 @ 2 - DO
;           I @ . 2 MINUS
;         +LOOP THEN ;
dots
        DC      $82
        DC      "."
        DC      $D3
        DC.W    last_editor
DOTS    DC.W    DOCOL
        DC.W    SPAT,SZERO,AT,EQUAL,ZBRAN
        DC.W    DOTS2-*
        DC.W    PDOTQ
        DC      5,"EMPTY"
        DC.W    BRAN
        DC.W    DOTS4-*
DOTS2   DC.W    SPAT,LIT,$2,SUB,SZERO,AT,LIT,$2,SUB,XDO
DOTS3   DC.W    I,AT,DOT,LIT,$2,MINUS,XPLOOP
        DC.W    DOTS3-*
DOTS4   DC.W    SEMIS

;       DUMP ( addr count --- )
;       Hex/ascii memory dump to screen
;       : DUMP BASE @ >R HEX 0 DO
;           CR DUP I + DUP 0 4 D.R
;           ." :" 8 0 DO
;               DUP I + C@ 2 .R SPACE
;           LOOP
;           2 SPACES 8 0 DO
;               DUP I + C@
;               DUP 20 < OVER 7E > OR IF
;                   DROP 2E
;               THEN EMIT
;           LOOP
;           ?TERMINAL IF LEAVE THEN
;           DROP
;         8 +LOOP DROP CR R> BASE ! ;
last_utils             ; *** MUST BE AT THE BEGINNING OF THE *LAST* WORD IN THIS FILE!
dump
        DC      $84
        DC      "DUM"
        DC      $D0
        DC.W    dots
DUMP    DC.W    DOCOL
        DC.W    BASE,AT,TOR,HEX,ZERO,XDO
DUMP2   DC.W    CR,DUP,I,PLUS,DUP,ZERO,LIT,$4,DDOTR
        DC.W    PDOTQ
        DC      1,":"
        DC.W    LIT,$8,ZERO,XDO
DUMP3   DC.W    DUP,I,PLUS,CAT,TWO,DOTR,SPACE,XLOOP
        DC.W    DUMP3-*
        DC.W    TWO,SPACES,LIT,$8,ZERO,XDO
DUMP4   DC.W    DUP,I,PLUS,CAT
        DC.W    DUP,LIT,$20,LESS,OVER,LIT,$7E,GREAT,ORLAB,ZBRAN
        DC.W    DUMP5-*
        DC.W    DROP,LIT,$2E
DUMP5   DC.W    EMIT,XLOOP
        DC.W    DUMP4-*
        DC.W    QTERM,ZBRAN
        DC.W    DUMP6-*
        DC.W    LEAVE
DUMP6   DC.W    DROP,LIT,$8,XPLOOP
        DC.W    DUMP2-*
        DC.W    DROP,CR,FROMR,BASE,STORE
        DC.W    SEMIS


