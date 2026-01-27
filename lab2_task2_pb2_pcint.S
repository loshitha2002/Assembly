// Task 2 (Steps 5-7): Interrupt from Port B2 (PB2 / D10) using PCINT2
// MCU: ATmega328P (Arduino Uno)
// LED: PD0 (D0) active-high
// Switch: PB2 (D10) with internal pull-up, pressed -> GND (0)
// Behavior: pressed -> LED ON, released -> LED OFF

#include <avr/io.h>
#include <avr/interrupt.h>

.section .vectors, "ax", @progbits
.global __vectors
.global RESET
.global main

// Minimal vector table: we place entries up to PCINT0 (vector #3).
// Vector order: 0 RESET, 1 INT0, 2 INT1, 3 PCINT0
__vectors:
    rjmp RESET            // 0x0000 RESET
    rjmp DEFAULT          // 0x0002 INT0
    rjmp DEFAULT          // 0x0004 INT1
    rjmp PCINT0_ISR       // 0x0006 PCINT0

.section .text

RESET:
main:
    cli

    // Init stack pointer (required before any push/pop in ISRs)
    ldi r16, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), r16
    ldi r16, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), r16

    // LED PD0 output, start OFF
    sbi _SFR_IO_ADDR(DDRD), 0
    cbi _SFR_IO_ADDR(PORTD), 0

    // Switch PB2 input with pull-up
    cbi _SFR_IO_ADDR(DDRB), 2
    sbi _SFR_IO_ADDR(PORTB), 2

    // Enable pin-change interrupt group 0 (PCIE0) and mask PCINT2
    ldi r16, (1<<PCIE0)
    sts PCICR, r16

    ldi r16, (1<<PCINT2)
    sts PCMSK0, r16

    // Clear pending flag
    ldi r16, (1<<PCIF0)
    sts PCIFR, r16

    sei

LOOP:
    rjmp LOOP

PCINT0_ISR:
    // Save minimal context
    push r16
    in   r16, _SFR_IO_ADDR(SREG)
    push r16

    // If PB2 is low -> pressed -> LED ON
    sbic _SFR_IO_ADDR(PINB), 2
    rjmp RELEASED

PRESSED:
    sbi _SFR_IO_ADDR(PORTD), 0
    rjmp ISR_DONE

RELEASED:
    cbi _SFR_IO_ADDR(PORTD), 0

ISR_DONE:
    pop  r16
    out  _SFR_IO_ADDR(SREG), r16
    pop  r16
    reti

DEFAULT:
    reti
