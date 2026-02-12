#define __SFR_OFFSET 0
#include <avr/io.h>

.section .text
.global main

; Interrupt Vector Table
.org 0x0000
    jmp setup
.org 0x0004  ; Byte Address 4 (Word Address 2) for INT0
    jmp isr_into

; Register Definitions
#define iloopRl r24
#define iloopRh r25
#define oLoopR  r21

setup:
    ldi r16, (1<<ISC00)      ; set IS10 high
    sts EICRA, r16           ; set interrupt when any logical change is there
    ldi r16, 0x01            ; enable INT0
    out EIMSK, r16           ; enable external interrupt

    sei                      ; enable global interrupts

    ldi r16, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)   ; enable outputs (PB0-PB4)
    out DDRB, r16

main: ; map loop to main label just in case, but code enters loop below
loop:
    ldi r16, (1<<2)|(1<<3)          ; set green light on
    out PORTB, r16           ; set output
    
    rjmp loop

isr_into:
    in r16, PIND
    sbrs r16, 2
    reti

    ldi oLoopR, 0x6D
    rcall oLoop

    ldi r16, (1<<1)|(1<<3)
    out PORTB, r16

    ldi oLoopR, 0x6D
    rcall oLoop

    ldi r16,(1<<0)|(1<<4)
    out PORTB, r16

    ldi oLoopR, 0x8B
    rcall oLoop


    ldi r16, (1<<1)|(1<<3)
    out PORTB, r16

    ldi oLoopR, 0x6D
    rcall oLoop

    reti

oLoop:
    ldi iloopRl, 0xFF               ;initialize inner loop count LOW

oLoopOuter:
    ldi iloopRh, 0xF0

iLoop:
    sbiw iloopRl, 1                  ;decrement inner loop register
    brne iLoop                      ;branch to iLoop if iLoop register!=0

outLoop:
    dec iloopRh
    brne outLoop

    dec oLoopR                      ;decrement outer loop register
    brne oLoop                      ;branch to oLoop if oLoopR !=0
    ret                             ;call back main
