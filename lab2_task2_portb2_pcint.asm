; lab2_task2_portb2_pcint.asm
;
; Task 2: Move switch to PB2 (Arduino D10)
; Interrupt source: Pin Change Interrupt PCINT2 (Port B group PCIE0)
; Logic: PB2 LOW (pressed) -> LED ON (PD0). PB2 HIGH (released) -> LED OFF.
;

.include "m328pdef.inc"

.cseg
.org 0x0000
    jmp start

.org INT0addr
    jmp default_isr

.org INT1addr
    jmp default_isr

.org PCINT0addr
    jmp isr_pcint0

start:
    ; Initialize stack pointer (required for interrupts)
    ldi r16, LOW(RAMEND)
    out SPL, r16
    ldi r16, HIGH(RAMEND)
    out SPH, r16

    ; --- SETUP I/O ---
    sbi DDRD, 0          ; PD0 as Output (LED)
    cbi PORTD, 0         ; LED initially OFF

    cbi DDRB, 2          ; PB2 as Input (Switch)
    sbi PORTB, 2         ; Enable internal pull-up on PB2

    ; --- SETUP PIN CHANGE INTERRUPT ---
    ; Enable Pin Change Interrupt group 0 (Port B)
    ldi r16, (1<<PCIE0)
    sts PCICR, r16

    ; Enable mask for PB2 = PCINT2
    ldi r16, (1<<PCINT2)
    sts PCMSK0, r16

    ; Clear any pending flag
    ldi r16, (1<<PCIF0)
    sts PCIFR, r16

    sei

loop:
    rjmp loop

; --- INTERRUPT SERVICE ROUTINE ---
isr_pcint0:
    ; Save minimal context (r16 + SREG)
    push r16
    in   r16, SREG
    push r16

    in  r16, PINB
    sbrs r16, 2          ; Skip next if PB2 is HIGH (released)
    rjmp pressed         ; PB2 LOW -> pressed

released:
    cbi PORTD, 0
    rjmp isr_done

pressed:
    sbi PORTD, 0

isr_done:
    pop  r16
    out  SREG, r16
    pop  r16
    reti

default_isr:
    reti
