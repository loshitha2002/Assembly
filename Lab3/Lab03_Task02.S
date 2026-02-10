#define __SFR_OFFSET 0
#include <avr/io.h>

.section .text
.global main

; Interrupt Vector Table
.org 0x0000
    jmp setup
.org 0x0004
    jmp isr_into

; Register Definitions
#define cross r19
#define iloopRl r24
#define iloopRh r25
#define oLoopR  r21

setup:
    ldi r16, (1<<ISC00)      ; set IS10 high
    sts EICRA, r16           ; set interrupt when any logical change is there
    ldi r16, 0x01            ; enable INT0
    out EIMSK, r16           ; enable external interrupt

    sei                      ; enable global interrupts

    ldi r16, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)   ; enable outputs
    out DDRB, r16

    ldi r16, (1<<4)|(1<<5)
    out DDRD, r16

    ldi cross, 0x00

main:
loop:
    ldi r16, (1<<2)|(1<<3)          ; let A pass
    out PORTB, r16           ; Green light on in A

    ldi r16, (1<<4)
    out PORTD, r16

    sbrc cross, 0
    rjmp red

    ldi oLoopR, 0x8B
    rcall oLoop              ; Set green light for 3s and Red in B

    ldi r16, (1<<1)|(1<<4)|(1<<3)
    out PORTB, r16           ; yellow in A, red and yellow in B

    ldi oLoopR, 0x6B
    rcall oLoop

    ldi r16, (1<<0)|(1<<5)
    out PORTB, r16           ; red in A, green in B

    ldi oLoopR, 0x8B
    rcall oLoop              ; delay 3s

    ldi r16, (1<<4)|(1<<1)|(1<<0) ;yellow in A, red in A, yellow in B
    out PORTB, r16

    ldi oLoopR, 0x6B
    rcall oLoop

    ldi r16, (1<<2)|(1<<3)          ; let A pass
    out PORTB, r16           ; Green light on in A
    ldi oLoopR, 0x6B
    rcall oLoop
    rjmp loop


red:
    ldi r16, (1<<5)
    out PORTD, r16

    ldi r16, (1<<0)|(1<<3)          ;red for both
    out PORTB, r16

    ldi oLoopR, 0xFF
    rcall oLoop

    ldi cross, 0x00              ; set cross back to 0

    rjmp loop

isr_into:
    in r16, PIND
    sbrs r16, 2
    reti

    ldi cross, 0x01
    reti

oLoop:
    ldi iloopRl, 0xFF               ;initialize inner loop count LOW

oLoopOuter:
    ldi iloopRh, 0xFF

iLoop:
    sbiw iloopRl, 1                  ;decrement inner loop register
    brne iLoop                      ;branch to iLoop if iLoop register!=0

outLoop:
    dec iloopRh
    brne outLoop

    dec oLoopR                      ;decrement outer loop register
    brne oLoop                      ;branch to oLoop if oLoopR !=0
    ret                             ;call back main