    processor 6502
    include "vcs.h"       ; Definizioni TIA (es. VSYNC, WSYNC)
    org $F000             ; Inizio ROM

Start:
    sei                   ; Disabilita interrupt
    cld                   ; Modalità decimale off
    ldx #$FF              ; Inizializza stack
    txs                   ; Stack pointer a $FF

Frame:
    lda #2                ; Attiva VSYNC
    sta VSYNC
    sta WSYNC             ; Aspetta 3 righe
    sta WSYNC
    sta WSYNC
    lda #0
    sta VSYNC             ; Spegni VSYNC

    ; Logica qui (VBlank)

Kernel:
    ldx #192              ; 192 righe visibili
ScanLoop:
    sta WSYNC             ; Sincronizza riga
    dex
    bne ScanLoop

    ; Overscan e loop
    jmp Frame

    org $FFFC             ; Vettore reset
    .word Start           ; Punto d'inizio
    .word Start
