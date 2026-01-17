; Task 2: Interrupt Toggle Test
; Wiring: Switch on PD2 (INT0), LED on PD0
.include "m328def.inc"

.org 0x0000
    rjmp main
.org 0x0002
    rjmp INT0_ISR

main:
    ; 1. Stack Setup
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16

    ; 2. Pin Setup
    sbi DDRD, 0         ; PD0 is Output (LED)
    cbi DDRD, 2         ; PD2 is Input (Switch)
    ; Note: No internal pull-up needed because you have external resistors.

    ; 3. Interrupt Setup
    ; Trigger on FALLING EDGE (High to Low) to toggle only once per press
    ; ISC01=1, ISC00=0 -> Falling Edge
    ldi r16, (1 << ISC01)
    sts EICRA, r16

    ldi r16, (1 << INT0)
    out EIMSK, r16

    sei                 ; Enable Interrupts

loop:
    rjmp loop           ; Wait here forever

; --- Interrupt Service Routine ---
INT0_ISR:
    ; Toggle the LED on PD0
    ; We read PORTD, flip bit 0, and write it back.
    in r16, PORTD       ; Read current LED state
    ldi r17, 1          ; Load mask for Bit 0
    eor r16, r17        ; XOR toggles the bit
    out PORTD, r16      ; Write back result

    reti
