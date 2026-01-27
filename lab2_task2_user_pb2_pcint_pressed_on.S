// lab2_task2_user_pb2_pcint_pressed_on.S
// PB2 (D10) pin-change interrupt, pressed (LOW) -> LED ON (PD0).
// Also sets initial LED state at RESET.

#include <avr/io.h>
#include <avr/interrupt.h>

.section .text

.org 0x0000
    rjmp RESET

// PCINT0 vector (#3) at 0x0006
.org 0x0006
    rjmp PCINT0_ISR

RESET:
    // -------- Stack Pointer --------
    ldi r16, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), r16
    ldi r16, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), r16

    // -------- LED on PD0 --------
    sbi _SFR_IO_ADDR(DDRD), 0
    cbi _SFR_IO_ADDR(PORTD), 0

    // -------- Switch on PB2 --------
    cbi _SFR_IO_ADDR(DDRB), 2
    sbi _SFR_IO_ADDR(PORTB), 2

    // Initial LED state: PB2 LOW -> ON, PB2 HIGH -> OFF
    sbic _SFR_IO_ADDR(PINB), 2
    rjmp INIT_RELEASED
INIT_PRESSED:
    sbi _SFR_IO_ADDR(PORTD), 0
    rjmp INIT_DONE
INIT_RELEASED:
    cbi _SFR_IO_ADDR(PORTD), 0
INIT_DONE:

    // Enable pin-change interrupt group 0 and mask PCINT2
    ldi r16, (1<<PCIE0)
    sts PCICR, r16

    ldi r16, (1<<PCINT2)
    sts PCMSK0, r16

    // Clear pending flag
    ldi r16, (1<<PCIF0)
    sts PCIFR, r16

    sei

MAIN:
    rjmp MAIN

PCINT0_ISR:
    push r16
    in   r16, _SFR_IO_ADDR(SREG)
    push r16

    // If PB2 HIGH -> released -> LED OFF
    sbic _SFR_IO_ADDR(PINB), 2
    rjmp RELEASED

PRESSED:
    sbi _SFR_IO_ADDR(PORTD), 0
    rjmp ISR_DONE

RELEASED:
    cbi _SFR_IO_ADDR(PORTD), 0

ISR_DONE:
    pop r16
    out _SFR_IO_ADDR(SREG), r16
    pop r16
    reti
