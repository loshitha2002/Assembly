; AssemblerApplication1.asm
;
; Created: 13/12/2023 1:02:27 PM
; Author : Buddhi Wijenayake
;

.include "m328pdef.inc"
	.cseg	
	.org	0x00
		jmp		setup
	.org	INT0addr
		jmp		isr_into

setup:
	ldi		r16, (1<<0)			; set IS10 high
	sts		EICRA, r16			; set interrupt when any logical change is there
	ldi		r16, 0x01			; enable INT0
	out		EIMSK, r16			; enable external interrupt

	sei							; enable global interrupts

	ldi		r16, (1<<0)|(1<<1)|(1<<2)	; enable outputs
	out		DDRB, r16

.def		iloopRl	 = r24		; temp reg to function delay
.def		iloopRh  = r25
.def		oLoopR   = r21

loop:
	ldi		r16, (1<<2)|(1<<3)			; set green light on
	out		PORTB, r16			; set output
	
	rjmp	loop

isr_into:
	in		r16, PIND
	sbrs	r16, 2
	reti

	ldi		oLoopR, 0x4B
	rcall	oLoop

	ldi		r16, (1<<1)|(1<<3)
	out		PORTB, r16

	ldi		oLoopR, 0x4B
	rcall	oLoop

	ldi		r16,(1<<0)|(1<<4)
	out		PORTB, r16

	ldi		oLoopR, 0x8B
	rcall	oLoop


	ldi		r16, (1<<1)|(1<<3)
	out		PORTB, r16

	ldi		oLoopR, 0x4B
	rcall	oLoop

	reti

oLoop:
	ldi			iLoopRl, 0xFF				;initialize inner loop count LOW

oLoopOuter:
	ldi			iLoopRh, 0xF0

iLoop:
	sbiw		iLoopRl, 1					;decrement inner loop register
	brne		iLoop						;branch to iLoop if iLoop register!=0

outLoop:
	dec			iLoopRh
	brne		outLoop

	dec			oLoopR						;decrement outer loop register
	brne		oLoop						;branch to oLoop if oLoopR !=0
	ret									;call back main