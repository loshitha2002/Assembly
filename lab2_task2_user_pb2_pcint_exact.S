// lab2_task2_user_pb2_pcint_exact.S
// GNU assembler buildable equivalent of the provided ASM snippet.
// Behavior (matches snippet): PB2 HIGH -> LED ON, PB2 LOW -> LED OFF.

#include <avr/io.h>
#include <avr/interrupt.h>

.section .text

// Place RESET at 0x0000, PCINT0 at 0x0006 (vector #3)
.org 0x0000
    rjmp RESET

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

    // -------- Enable Pin Change Interrupt --------
    ldi r16, (1<<PCIE0)
    sts PCICR, r16

    ldi r16, (1<<PCINT2)
    sts PCMSK0, r16

    ldi r16, (1<<PCIF0)
    sts PCIFR, r16

    sei

MAIN:
    rjmp MAIN

PCINT0_ISR:
    push r16
    in   r16, _SFR_IO_ADDR(SREG)
    push r16

    // sbis PINB,2  => if PB2 is HIGH, skip next instruction
    sbis _SFR_IO_ADDR(PINB), 2
    rjmp SWITCH_LOW

    // PB2 HIGH -> LED ON
    sbi _SFR_IO_ADDR(PORTD), 0
    rjmp ISR_DONE

SWITCH_LOW:
    // PB2 LOW -> LED OFF
    cbi _SFR_IO_ADDR(PORTD), 0

ISR_DONE:
    pop r16
    out _SFR_IO_ADDR(SREG), r16
    pop r16
    reti
