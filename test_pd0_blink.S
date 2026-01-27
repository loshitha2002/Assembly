// test_pd0_blink.S
// Verifies LED wiring on Arduino D0 (PD0) by blinking it.

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

    // PD0 output
    sbi _SFR_IO_ADDR(DDRD), 0

LOOP:
    sbi _SFR_IO_ADDR(PORTD), 0
    rcall DELAY
    cbi _SFR_IO_ADDR(PORTD), 0
    rcall DELAY
    rjmp LOOP

DELAY:
    // crude delay loop (adjust if needed)
    ldi r19, 0x30
D2:
    ldi r18, 0xFF
D1:
    dec r18
    brne D1
    dec r19
    brne D2
    ret
