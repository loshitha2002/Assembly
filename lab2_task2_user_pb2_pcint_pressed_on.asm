.include "m328pdef.inc"

.org 0x0000
rjmp RESET

; Pin Change Interrupt 0 vector (PB0–PB7)
.org 0x0006
rjmp PCINT0_ISR

RESET:
    ; -------- Stack Pointer --------
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; -------- LED on PD0 --------
    sbi DDRD, 0
    cbi PORTD, 0

    ; -------- Switch on PB2 --------
    cbi DDRB, 2          ; PB2 input
    sbi PORTB, 2         ; enable internal pull-up

    ; Set initial LED state immediately:
    ; pressed (PB2 LOW) -> LED ON, released (PB2 HIGH) -> LED OFF
    sbic PINB, 2         ; skip next if bit is clear (LOW)
    rjmp INIT_RELEASED
INIT_PRESSED:
    sbi PORTD, 0
    rjmp INIT_DONE
INIT_RELEASED:
    cbi PORTD, 0
INIT_DONE:

    ; -------- Enable Pin Change Interrupt --------
    ldi r16, (1<<PCIE0)
    sts PCICR, r16

    ldi r16, (1<<PCINT2)
    sts PCMSK0, r16

    ; Clear any pending interrupt
    ldi r16, (1<<PCIF0)
    sts PCIFR, r16

    sei

MAIN:
    rjmp MAIN

; -------- ISR --------
PCINT0_ISR:
    push r16
    in   r16, SREG
    push r16

    ; pressed (LOW) -> LED ON
    sbic PINB, 2
    rjmp RELEASED

PRESSED:
    sbi PORTD, 0
    rjmp ISR_DONE

RELEASED:
    cbi PORTD, 0

ISR_DONE:
    pop r16
    out SREG, r16
    pop r16
    reti
