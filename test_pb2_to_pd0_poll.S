// test_pb2_to_pd0_poll.S
// Verifies switch wiring on Arduino D10 (PB2) with internal pull-up,
// and LED on Arduino D0 (PD0). No interrupts; just polling.
// PB2 LOW (pressed) -> LED ON

#include <avr/io.h>

.section .text

.org 0x0000
    rjmp RESET

RESET:
    // Init stack pointer
    ldi r16, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), r16
    ldi r16, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), r16

    // LED PD0 output
    sbi _SFR_IO_ADDR(DDRD), 0
    cbi _SFR_IO_ADDR(PORTD), 0

    // Switch PB2 input + pull-up
    cbi _SFR_IO_ADDR(DDRB), 2
    sbi _SFR_IO_ADDR(PORTB), 2

MAIN:
    // If PB2 HIGH -> released -> LED OFF
    sbic _SFR_IO_ADDR(PINB), 2
    rjmp RELEASED

PRESSED:
    sbi _SFR_IO_ADDR(PORTD), 0
    rjmp MAIN

RELEASED:
    cbi _SFR_IO_ADDR(PORTD), 0
    rjmp MAIN
