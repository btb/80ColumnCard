; Videoterm Interface                                                          *
; Firmware v. 2.4                                                              *
;
; Written by Darrel Aldrich                                                    *
; (c) 1981 Videx

; da65 V2.18 - Git ece63f0
; Created:    2023-06-23 01:41:26

.setcpu    "6502"
.org       $C800
.listbytes unlimited

CH              := $0024
CV              := $0025
BASL            := $0028        ; base address for text output (lo)
XSAVE           := $0035
CSWL            := $0036
CSWH            := $0037
KSWL            := $0038
KSWH            := $0039
RNDL            := $004E
RNDH            := $004F
IN              := $0200
CRFLAG          := $0478
BASEL           := $047B
ASAV1           := $04F8
BASEH           := $04FB
XSAV1           := $0578
CHORZ           := $057B        ; cursor horizontal displacement
TEMPX           := $05F8
CVERT           := $05FB        ; cursor vertical displacement
OLDCHAR         := $0678
BYTE            := $067B
N0              := $06F8
START           := $06FB
MSLOT           := $0778
POFF            := $077B
FLAGS           := $07FB
KBD             := $C000
KBDSTRB         := $C010
SPKR            := $C030
SETAN0          := $C058
BUTN2           := $C063
DEV0            := $C0B0
DEV1            := $C0B1
DISP0           := $CC00
DISP1           := $CD00
MON_VTAB        := $FC22
MON_SETKBD      := $FE89
MON_SETVID      := $FE93
IORTS           := $FFCB

; Set up CRTC and clear screen

SETUP:  lda     POFF            ; Get power off flag
        and     #$F8            ; Strip off lead in counters
        cmp     #$30            ; Has power been turned off?
        beq     LC82A
RESTART:lda     #$30
        sta     POFF            ; Set defaults for flags
        sta     FLAGS
        lda     #$00
        sta     START
        jsr     CLSCRN
        ldx     #$00
LOOP:   txa
        sta     DEV0            ; For the CRTC address
        lda     TABLE,x         ; Get parameter
        sta     DEV1            ; Store into CRTC
        inx
        cpx     #$10
        bne     LOOP            ; Continue loop until done
LC82A:  sta     $C059
        rts

EXIT:   lda     FLAGS
        and     #$08
        beq     NORMOUT
        jsr     MON_SETVID
        jsr     MON_VTAB
        jsr     MON_SETKBD
NORMOUT:pla                     ; Recover registers
        tay
        pla
        tax
        pla
        rts

; Get character from keyboard

RDKEY:  jsr     CSRMOB          ; Position cursor
KEYIN:  inc     RNDL            ; Update basic random number
        bne     KEYIN2
        inc     RNDH
KEYIN2: lda     KBD             ; Poll keyboard
        bpl     KEYIN           ; Loop until key is struck
        jsr     KEYSTAT
        bcc     KEYIN
NOKEY:  bit     KBDSTRB         ; Clear keyboard stroke
        clc
        rts

KEYSTAT:cmp     #$8B            ; Check for control X
        bne     NOTK            ; Skip if not
        lda     #$DB            ; Substitute a right bracket
NOTK:   cmp     #$81            ; Check for control A
        bne     NTSHFT          ; Skip if not
        lda     FLAGS
        eor     #$40
        sta     FLAGS           ; Toggle upr/lwr case flag
        bcs     NOKEY           ; Get next key
NTSHFT: pha                     ; Save character
        lda     FLAGS
        asl     a
        asl     a               ; Check upr/lwr case conversion flag
        pla                     ; Restore character
        bcc     INDONE          ; Don't convert if flag clear
        cmp     #$B0
        bcc     INDONE          ; Don't convert special characters
        bit     BUTN2
        bmi     NOSHIFT
        cmp     #$B0
        beq     ZERO
        cmp     #$C0
        bne     NOT_AT
        lda     #$D0
NOT_AT: cmp     #$DB
        bcc     INDONE
        and     #$CF
        bne     INDONE
ZERO:   lda     #$DD
NOSHIFT:ora     #$20
INDONE: pha                     ; Duplicate character
        and     #$7F            ; Strip off high bit
        sta     BYTE            ; Save for Pascal
        pla                     ; Recover for Basic
        sec
        rts

; CRTC timing tables
TABLE:  
    ; this is per listing in Videx docs
    .byte   123     ; R0 - Horizontal Total Register
    .byte   80      ; R1 - Horizontal Displayed Register (80 columns)
    .byte   94      ; R2 - Horizontal Sync Position Register
    .byte   41      ; R3 - Horizontal Sync Width Register (clone has 47)

    .byte   27      ; R4 - Vertical Total Register
    .byte   08      ; R5 - Vertical Total Adjust Register
    .byte   24      ; R6 - Vertical Displayed Register (24 lines)
    .byte   25      ; R7 - Vertical Sync Position Register

    .byte   $00     ; R8 - Interlace Mode Register (normal sync mode)
    .byte   $08     ; R9 - Maximum Scan Line Register
    .byte   $e0     ; R10 - Cursor End Register
    .byte   $08     ; R11 - Cursor End Register
    .byte   $00     ; R12 - Start Address Register (H)
    .byte   $00     ; R13 - Start Address Register (L)
    .byte   $00     ; R14 - Cursor Register (H)
    .byte   $00     ; R15 - Cursor Register (L)

; Secondary basic output routine

BASOUT1:
        sta     BYTE            ; Save character
        lda     CV              ; Perform VTab
        cmp     CVERT
        beq     CVOK
        sta     CVERT
        jsr     VTAB
CVOK:   lda     CH              ; Perform HTab
        cmp     CHORZ
        bcc     PSCLOUT
        sta     CHORZ
PSCLOUT:lda     BYTE            ; Get character
        jsr     OUTPT1          ; Output character
CSRMOB: lda     #$0F            ; Set up CRTC address
        sta     DEV0            ; for cursor low address
        lda     CHORZ           ; Calculate address
        cmp     #$50
        bcs     LC8F0
        adc     BASEL
        sta     DEV1            ; Save address
        lda     #$0E            ; Set up CRTC address
        sta     DEV0            ; for cursor high address
        lda     #$00            ; Calculate address
        adc     BASEH
        sta     DEV1            ; Save address
LC8F0:  rts

; Perform escape functions

ESC1:   eor     #$C0
        cmp     #$08
        bcs     RTS3
        tay
        lda     #$C9
        pha
        lda     ESCTBL,y
        pha
        rts
        nop

CLREOL: ldy     CHORZ           ; Put cursor horizontal into Y
CLEOLZ: lda     #$A0            ; Use a space
CLEOL2: jsr     CHRPUT          ; Put character on screen
        iny
        cpy     #80             ; Continue until
        bcc     CLEOL2          ; Y >= 80
        rts

LEADIN: lda     #$34            ; Set lead in bit
PSAVE:  sta     POFF
RTS3:   rts

GOXY1:  lda     #$32            ; Set lead in count to 2
        bne     PSAVE

BELL:   ldy     #$C0            ; Beep the speaker
BELL1:  ldx     #$80
BELL2:  dex
        bne     BELL2
        lda     SPKR
        dey
        bne     BELL1
        rts

; Store character on screen and advance cursor

STOADV: ldy     CHORZ
        cpy     #$50
        bcc     NOTB1
        pha
        jsr     CRLF
        pla
NOTB1:  ldy     CHORZ
        jsr     CHRPUT          ; Place character on screen
ADVANCE:inc     CHORZ           ; Increment cursor horizontal index
        bit     CRFLAG
        bpl     RTS8
        lda     CHORZ
        cmp     #$50
        bcs     CRLF
RTS8:   rts

; Clear to end of page

CLREOP: ldy     CHORZ           ; Get cursor horizontal into Y
        lda     CVERT           ; Get cursor vertical into A
CLEOP1: pha                     ; Save current line on stack
        jsr     VTABZ           ; Calculate base address
        jsr     CLEOLZ          ; Clear to end of line, set carry
        ldy     #$00            ; Clear from horizontal index 0
        pla
        adc     #$00            ; Increment current line (C=1)
        cmp     #24             ; Done to bottom of window?
        bcc     CLEOP1          ; If not keep clearing lines
        bcs     JVTAB           ; Vertical tab to cursor position

; Clear screen

CLSCRN: jsr     HOME            ; Home cursor
        tya
        beq     CLEOP1          ; Clear to end of page

; Home cursor

HOME:   lda     #$00            ; Set cursor position to 0,0
        sta     CHORZ
        sta     CVERT
        tay
        beq     JVTAB           ; Vertical tab to cursor position
BS:     dec     CHORZ           ; Decrement cursor horizontal index
        bpl     RTS3            ; If pos, OK. Else move up
        lda     #79             ; Set cursor horizontal to
        sta     CHORZ           ; rightmost screen position

; Move cursor up

UP:     lda     CVERT           ; Get cursor vertical index
        beq     RTS3            ; If top line then return
        dec     CVERT           ; Decrement cursor vertical index
JVTAB:  jmp     VTAB            ; Vertical tab to cursor position

NOTGOXY:lda     #$30            ; Clear lead in bits
        sta     POFF
        pla                     ; Recover character
        ora     #$80
        cmp     #$B1
        bne     NOT0
        lda     #$08
        sta     SETAN0
        bne     FLGSET
NOT1:   cmp     #$B2
        bne     NOT2
LOLITE: lda     #$FE
FLGCLR: and     FLAGS
FLGSAV: sta     FLAGS
        rts

; Pascal output entry point

PSOUT:  sta     BYTE
        lsr     CRFLAG
        jmp     PSCLOUT         ; Jump for Pascal entry

; CR/LF routine

CRLF:   jsr     CR
LF:     inc     CVERT           ; Increment cursor vertical
        lda     CVERT
LC9B9:  cmp     #24             ; Off screen?
        bcc     VTABZ           ; If not move cursor
        dec     CVERT           ; If so decrement cursor vertical
        lda     START           ; Increment the start address
        adc     #$04            ; by one line
        and     #$7F
        sta     START
        jsr     BASCLC1         ; Calculate the start address
        lda     #$0D            ; Set up CRTC address
        sta     DEV0            ; for start low address
        lda     BASEL           ; Get start low
        sta     DEV1            ; Save start low
        lda     #$0C            ; Set up CRTC address
        sta     DEV0            ; for start high address
        lda     BASEH           ; Get start high
        sta     DEV1            ; Save start high
        lda     #23             ; Put window bottom-1 into A
        jsr     VTABZ           ; Calculate base address
        ldy     #$00
        jsr     CLEOLZ          ; Clear bottom line
        bcs     JVTAB           ; Move cursor back
NOT2:   cmp     #$B3
        bne     JSTOADV
HILITE: lda     #$01
FLGSET: ora     FLAGS
        bne     FLGSAV

; Basic initial I/O entry point

NOT0:   cmp     #$B0
        bne     NOT1
        jmp     RESTART

JSTOADV:jmp     STOADV

VTAB:   lda     CVERT           ; Get cursor vertical
VTABZ:  sta     ASAV1           ; Multiply A by 5
        asl     a
        asl     a
        adc     ASAV1
        adc     START           ; Add start
BASCLC1:pha                     ; Save A
        lsr     a               ; Calculate BASEH
        lsr     a
        lsr     a
        lsr     a
        sta     BASEH
        pla                     ; Recover A
        asl     a               ; Calculate BASEL
        asl     a
        asl     a
        asl     a
        sta     BASEL
RTS2:   rts

VIDOUT: cmp     #$0D
        bne     VDOUT1
CR:     lda     #$00
        sta     CHORZ
        rts

VDOUT1: ora     #$80            ; Set high bit
        cmp     #$A0
        bcs     JSTOADV         ; If not control print it
        cmp     #$87
        bcc     RTS4            ; CTRL @ - F
        tay
        lda     #>BELL
        pha
        lda     LC9B9,y
        pha
RTS4:   rts

CTLTBL:
    .byte <BELL - 1
    .byte <BS - 1
    .byte <RTS3 - 1
    .byte <LF - 1
    .byte <CLREOP - 1
    .byte <CLSCRN - 1
    .byte <CRLF - 1
    .byte <LOLITE - 1
    .byte <HILITE - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <RTS3 - 1
    .byte <HOME - 1
    .byte <LEADIN - 1
    .byte <RTS3 - 1
    .byte <ADVANCE - 1
    .byte <CLREOL - 1
    .byte <GOXY1 - 1
    .byte <UP - 1

; Calculate screen address and switch in correct page

PSNCALC:clc
        tya
        adc     BASEL
        pha
        lda     #$00            ; Calculate screen address high
        adc     BASEH
        pha
        asl     a
        and     #$0C            ; Use bit 0 and 1 for paging
        tax
        lda     DEV0,x          ; Set correct screen page
        pla
        lsr     a
        pla
        tax
        rts

; Put a character at CVERT, CHORZ

CHRPUT: asl     a
        pha                     ; Save shifted character
        lda     FLAGS           ; Get character set flag
        lsr     a               ; Shift it into carry
        pla                     ; Recover shifted character
        ror     a               ; Rotate carry into character
        pha                     ; Save character
        jsr     PSNCALC         ; Set up screen address
        pla                     ; Recover character
        bcs     WRITE1          ; Select memory range
        sta     DISP0,x         ; Store character on screen
        bcc     WSKIP           ; Skip
WRITE1: sta     DISP1,x         ; Store character on screen
WSKIP:  rts                     ; Recover X register

; General output routine

OUTPT1: pha                     ; Save character
        lda     #$F7
        jsr     FLGCLR
        sta     $C059
        lda     POFF
        and     #$07            ; Check for lead in
        bne     LEAD            ; Branch for lead in
        pla                     ; Recover character
        jmp     VIDOUT          ; Output character

LEAD:   and     #$04            ; Check for go to XY
        beq     GOXY3           ; If not skip
        jmp     NOTGOXY

GOXY3:  pla                     ; Recover character
        sec
        sbc     #32             ; Subtract 32
GOTOXY: and     #$7F            ; Strip off unneeded bits
        pha                     ; Save A
        dec     POFF            ; Decrement lead in counter
        lda     POFF
        and     #$03            ; Get count
        bne     GOXY2           ; Skip if count not zero
        pla                     ; Recover A
        cmp     #24             ; If A > window bottom
        bcs     BADY            ; Then don't move cursor vertical
        sta     CVERT
BADY:   lda     TEMPX           ; Get cursor horizontal parameter
        cmp     #80             ; If A > 80 then
        bcs     BADX            ; don't move cursor horizontal
        sta     CHORZ
BADX:   jmp     VTAB            ; Vertical tab to cursor position
GOXY2:  pla                     ; Recover A
        sta     TEMPX           ; Save cursor horizontal parameter
        rts

; Stop list routine

STPLST: lda     KBD
        cmp     #$93
        bne     STPDONE
        bit     KBDSTRB
STPLOOP:lda     KBD
        bpl     STPLOOP
        cmp     #$83
        beq     STPDONE
        bit     KBDSTRB
STPDONE:rts

ESCNOW: tay
        lda     LCB31,y
        jsr     ESC1
ESCNEW: jsr     RDKEY
        cmp     #$CE
        bcs     ESC2
        cmp     #$C9
        bcc     ESC2
        cmp     #$CC
        bne     ESCNOW
ESC2:   jmp     ESC1
        nop

; Basic initial I/O entry point ($C300, ROM offset $0300)

        bit     IORTS           ; Set VFlag on initial entry
        bvs     ENTR
INFAKE: sec                     ; Fake input entry C=0
        .byte   $90
OUTENTR:clc                     ; Output entry C=1
        clv
        bvc     ENTR
        .byte   $01, $82
        .byte   <INIT
        .byte   <READ
        .byte   <WRITE
        .byte   <STATUS

INIT:   jmp     SETUP

READ:   jsr     RDKEY
        and     #$7F
        ldx     #$00
        rts

WRITE:  jsr     PSOUT
        ldx     #$00
        rts

STATUS: cmp     #$00
        beq     STEXIT
        lda     KBD
        asl     a
        bcc     STEXIT
        jsr     KEYSTAT
STEXIT: ldx     #$00
LCB31:  rts

; Basic input entry point

INENTR: sta     (BASL),y        ; Replace flashing cursor
        sec
        clv
ENTR:   sta     $CFFF           ; Turn off co-resident memory

; Save registers, set up N0 and CN

WHERE:  pha                     ; Save registers on stack
        sta     XSAVE
        txa
        pha
        tya
        pha
        lda     XSAVE           ; Save character
        stx     XSAVE           ; Save input buffer index
        ldx     #$C3
        stx     CRFLAG
        pha
        bvc     IO              ; Go to IO if not initial entry

; Basic initialize

        lda     #<INENTR        ; Set up input and output hooks
        sta     KSWL
        stx     KSWH
        lda     #<OUTENTR
        sta     CSWL
        stx     CSWH
        jsr     SETUP           ; Set up CRTC
        clc
IO:     bcc     LCBCD

; Basic input routine

BASINP: pla                     ; Pop stack
        ldy     XSAVE           ; Get input buffer index
        beq     GETLN           ; If zero assume GETLN
        dey
        lda     OLDCHAR         ; Get last character from GETLN
        cmp     #$88            ; If BS assume GETLN
        beq     GETLN
        cmp     IN,y
        beq     GETLN
        eor     #$20
SKIP:   cmp     IN,y            ; If same as character in input
        bne     NTGETLN         ; buffer then assume GETLN
        lda     OLDCHAR         ; Get last character from GETLN
        sta     IN,y            ; Fix input buffer
        bcs     GETLN           ; Go to GETLN
ESC:    jsr     ESCNEW          ; Perform escape function
GETLN:  lda     #$80            ; Set GETLN flag
        jsr     FLGSET
        jsr     RDKEY           ; Get character from keyboard
        cmp     #$9B            ; Check for escape
        beq     ESC
        cmp     #$8D            ; Check for CR
        bne     NOTCR           ; If not skip
        pha                     ; Save character
        jsr     CLREOL          ; Clear to end of line
        pla                     ; Recover character
NOTCR:  cmp     #$95            ; Check for pick
        bne     NOTPICK         ; If not skip
CHRGET: ldy     CHORZ           ; Get cursor horizontal position
        jsr     PSNCALC         ; Set up screen address
        bcs     READ1           ; Read character from screen
        lda     DISP0,x
        bcc     RSKIP
READ1:  lda     DISP1,x
RSKIP:  ora     #$80            ; Set high bit
NOTPICK:sta     OLDCHAR         ; Save character in OLDCHAR
        bne     DONE            ; Exit
NTGETLN:jsr     RDKEY           ; Get character from keyboard
        ldy     #$00            ; Clear OLDCHARacter
        sty     OLDCHAR
DONE:   tsx                     ; Put character into stack
        inx
        inx
        inx
        sta     $0100,x
OUTDONE1:
        lda     #$00            ; Set CH = 00
OUTDONE:sta     CH
        lda     CVERT           ; Set CV = CVERT
        sta     CV
        jmp     EXIT

; Primary basic output routine

LCBCD:  pla                     ; Recover character
        ldy     FLAGS           ; Check GETLN flags
        bpl     BOUT            ; If clear then skip
        ldy     OLDCHAR         ; Get last character from GETLN
        cpy     #$E0            ; If it is lower case then use it
        bcc     BOUT
        tya
BOUT:   jsr     BASOUT1         ; Output character
        jsr     STPLST
        lda     #$7F            ; Clear the GETLN flag
        jsr     FLGCLR
        lda     CHORZ           ; Get cursor horizontal
        sbc     #$47
        bcc     OUTDONE1
        adc     #$1F
FIXCH:  clc
RTS6:   bcc     OUTDONE

ESCTBL:
        .byte   <CLSCRN - 1
        .byte   <ADVANCE - 1
        .byte   <BS - 1
        .byte   <LF - 1
        .byte   <UP - 1
        .byte   <CLREOL - 1
        .byte   <CLREOP - 1
        .byte   <HOME - 1
XLTBL:  .byte $c4, $c2, $c1, $ff, $c3
        nop
