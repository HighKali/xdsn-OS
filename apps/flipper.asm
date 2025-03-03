; Costanti
UART_DATA  equ 0x00   ; Indirizzo del registro dati UART (es. 8250)
UART_STAT  equ 0x05   ; Indirizzo del registro stato UART
TX_READY   equ 0x20   ; Bit che indica che TX è pronto
RX_READY   equ 0x01   ; Bit che indica che RX ha dati

; Punto di ingresso
    org 0x8000        ; Posizione in memoria (modificabile)

start:
    call init_uart    ; Inizializza UART
    call send_cmd     ; Invia comando
    call recv_resp    ; Ricevi risposta
    jp $              ; Loop infinito

init_uart:
    ; Inizializzazione base UART (9600 baud, 8N1)
    ; Dipende dal chip UART, qui un esempio semplificato
    ret               ; Personalizza in base al tuo hardware

send_cmd:
    ld hl, cmd_text   ; Punta alla stringa del comando
send_loop:
    ld a, (hl)        ; Carica il prossimo byte
    or a              ; Controlla se è 0 (fine stringa)
    ret z             ; Esci se finito
    call uart_send    ; Invia il byte
    inc hl            ; Prossimo byte
    jr send_loop

uart_send:
    push af           ; Salva il byte da inviare
wait_tx:
    in a, (UART_STAT) ; Leggi lo stato UART
    and TX_READY      ; Controlla se TX è pronto
    jr z, wait_tx     ; Aspetta se non pronto
    pop af            ; Ripristina il byte
    out (UART_DATA), a; Invia il byte
    ret

recv_resp:
    ld b, 2           ; Aspetta 2 byte ("OK")
recv_loop:
    in a, (UART_STAT) ; Leggi lo stato UART
    and RX_READY      ; Controlla se ci sono dati
    jr z, recv_loop   ; Aspetta dati
    in a, (UART_DATA) ; Leggi il byte ricevuto
    dec b             ; Decrementa contatore
    jr nz, recv_loop  ; Continua finché non finiti
    ret

cmd_text:
    db "SUBGHZ_TX", 0 ; Comando per il Flipper Zero

    end
