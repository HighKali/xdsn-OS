processor 6502
include "vcs.h"       ; Definizioni TIA (VSYNC, WSYNC, ecc.)
org $F000             ; Inizio ROM (4 KB)

; Costanti
KALI_HEIGHT = 16          ; Altezza sprite Kali
ZARA_HEIGHT = 8           ; Altezza sprite Zara
SCREEN_HEIGHT = 192       ; Righe visibili

; Variabili in RAM ($80-$FF, 128 byte disponibili)
    seg.u Variables
    org $80
KaliX       .byte         ; Posizione X di Kali
KaliY       .byte         ; Posizione Y di Kali
ZaraX       .byte         ; Posizione X di Zara
ZaraY       .byte         ; Posizione Y di Zara
EnemyX      .byte         ; Posizione X Medusa
EnemyY      .byte         ; Posizione Y Medusa
FrameCount  .byte         ; Contatore frame per animazioni
SwordActive .byte         ; Stato spada (0=off, 1=on)
SwordX      .byte         ; Posizione X spada
SwordY      .byte         ; Posizione Y spada

; Inizio programma
    seg Code
    org $F000

Start:
    sei                   ; Disabilita interrupt
    cld                   ; Modalità decimale off
    ldx #$FF
    txs                   ; Inizializza stack
    lda #0
    ldx #$FF              ; Pulisci RAM
ClearRam:
    sta $0,X
    dex
    bne ClearRam

    ; Inizializzazione
    lda #40
    sta KaliX             ; Kali parte a X=40
    lda #100
    sta KaliY             ; Kali a mezza altezza
    lda #80
    sta ZaraX             ; Zara a X=80
    lda #110
    sta ZaraY             ; Zara vicino a Kali
    lda #120
    sta EnemyX            ; Medusa a X=120
    lda #50
    sta EnemyY            ; Medusa in alto

MainLoop:
    ; --- VSYNC ---
    lda #2
    sta VSYNC
    sta WSYNC             ; 3 righe di VSYNC
    sta WSYNC
    sta WSYNC
    lda #0
    sta VSYNC

    ; --- VBlank (logica) ---
    inc FrameCount        ; Aggiorna frame

    ; Movimento Kali (joystick)
    lda SWCHA             ; Leggi joystick
    and #%00010000        ; Destra
    bne NoRight
    inc KaliX
NoRight:
    and #%00100000        ; Sinistra
    bne NoLeft
    dec KaliX
NoLeft:
    and #%01000000        ; Su
    bne NoUp
    inc KaliY
NoUp:
    and #%10000000        ; Giù
    bne NoDown
    dec KaliY
NoDown:

    ; Fuoco spada (tasto fuoco)
    lda INPT4             ; Leggi pulsante
    bmi NoFire
    lda #1
    sta SwordActive
    lda KaliX
    clc
    adc #8                ; Spada a destra di Kali
    sta SwordX
    lda KaliY
    sta SwordY
NoFire:

    ; Movimento Zara (segue Kali lentamente)
    lda KaliX
    cmp ZaraX
    beq NoZaraX
    bcs ZaraRight
    dec ZaraX
    jmp NoZaraX
ZaraRight:
    inc ZaraX
NoZaraX:
    lda KaliY
    cmp ZaraY
    beq NoZaraY
    bcs ZaraUp
    dec ZaraY
    jmp NoZaraY
ZaraUp:
    inc ZaraY
NoZaraY:

    ; Movimento Medusa (oscilla)
    lda FrameCount
    and #31               ; Ogni 32 frame
    bne NoEnemyMove
    inc EnemyX
    lda EnemyX
    cmp #150              ; Limite destro
    bne NoResetEnemy
    lda #20               ; Torna a sinistra
    sta EnemyX
NoResetEnemy:
NoEnemyMove:

    ; --- Kernel (disegno) ---
    lda #$08              ; Grigio per muri
    sta COLUPF            ; Colore playfield
    lda #$44              ; Rosso per Kali
    sta COLUP0
    lda #$06              ; Nero per Zara
    sta COLUP1
    lda #$1E              ; Giallo per spada/Medusa
    sta COLUPF

    ldx #SCREEN_HEIGHT    ; 192 righe
Kernel:
    sta WSYNC             ; Sincronizza riga
    cpx KaliY             ; Kali visibile?
    bcs NoKali
    cpx #(KaliY-KALI_HEIGHT)
    bcc NoKali
    lda KaliShape-KALI_HEIGHT,x  ; Carica sprite Kali
    sta GRP0
    lda KaliX
    sta HMP0
NoKali:
    cpx ZaraY             ; Zara visibile?
    bcs NoZara
    cpx #(ZaraY-ZARA_HEIGHT)
    bcc NoZara
    lda ZaraShape-ZARA_HEIGHT,x  ; Carica sprite Zara
    sta GRP1
    lda ZaraX
    sta HMP1
NoZara:
    cpx EnemyY            ; Medusa visibile?
    bcs NoEnemy
    cpx #(EnemyY-8)
    bcc NoEnemy
    lda EnemyShape-8,x    ; Carica sprite Medusa
    sta GRP1              ; Usa P1 per flickering
    lda EnemyX
    sta HMP1
NoEnemy:
    cpx SwordY            ; Spada visibile?
    bne NoSword
    lda SwordActive
    beq NoSword
    lda #%00000010        ; Missile per spada
    sta ENAM0
    lda SwordX
    sta HMM0
NoSword:
    ; Labirinto semplice (playfield)
    lda #%11110000        ; Muro sinistro
    sta PF0
    lda #%11111111        ; Muro centrale
    sta PF1
    lda #%00001111        ; Muro destro
    sta PF2

    dex
    bne Kernel

    ; Pulisci sprite dopo il kernel
    lda #0
    sta GRP0
    sta GRP1
    sta ENAM0
    sta PF0
    sta PF1
    sta PF2

    ; --- Overscan ---
    ldx #30
Overscan:
    sta WSYNC
    dex
    bne Overscan

    jmp MainLoop

; Dati sprite
KaliShape:
    .byte #%01100110      ; Armatura scheletro
    .byte #%01000010
    .byte #%01100110
    .byte #%00111100
    .byte #%00011000
    .byte #%00011000
    .byte #%00111100
    .byte #%01000010
    .byte #%01000010
    .byte #%01100110
    .byte #%00111100
    .byte #%00011000
    .byte #%00011000
    .byte #%00100100
    .byte #%00100100
    .byte #%00011000

ZaraShape:
    .byte #%01111000      ; Pantera
    .byte #%11111100
    .byte #%11111110
    .byte #%01111110
    .byte #%00111100
    .byte #%00011000
    .byte #%00011000
    .byte #%00111100

EnemyShape:
    .byte #%00111100      ; Medusa volante
    .byte #%01111110
    .byte #%11100111
    .byte #%11000011
    .byte #%01111110
    .byte #%00111100
    .byte #%00011000
    .byte #%00100100

; Vettore reset
    org $FFFC
    .word Start
    .word Start
