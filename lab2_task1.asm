; Task 1: Monitor switch on PB0 and display status on LED connected to PD0

.include "m328def.inc" ; Include definitions for ATmega328P

.org 0x0000            ; Reset vector
    rjmp main          ; Jump to main program

main:
    ; --- Setup Ports ---
    
    ; Configure PB0 as Input
    cbi DDRB, 0        ; Clear bit 0 of Data Direction Register B (Input)
    
    ; Configure PD0 as Output
    sbi DDRD, 0        ; Set bit 0 of Data Direction Register D (Output)

loop:
    ; --- Read Switch ---
    sbis PINB, 0       ; Skip next instruction if bit 0 of Port B is Set (High)
    rjmp switch_low    ; Jump if switch is Low

switch_high:
    ; If switch reads HIGH
    sbi PORTD, 0       ; Turn ON LED (Set PD0 High)
    rjmp loop          ; Go back to start of loop

switch_low:
    ; If switch reads LOW
    cbi PORTD, 0       ; Turn OFF LED (Clear PD0 Low)
    rjmp loop          ; Go back to start of loop
