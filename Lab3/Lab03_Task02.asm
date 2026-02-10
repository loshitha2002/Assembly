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

.def		cross = r19			;register to check crossings
setup:
	ldi		r16, (1<<0)			; set IS10 high
	sts		EICRA, r16			; set interrupt when any logical change is there
	ldi		r16, 0x01			; enable INT0
	out		EIMSK, r16			; enable external interrupt

	sei							; enable global interrupts

	ldi		r16, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)	; enable outputs
	out		DDRB, r16

	ldi		r16, (1<<4)|(1<<5)
	out		DDRD, r16

	ldi		cross,	0x00

.def		iloopRl	 = r24		; temp reg to function delay
.def		iloopRh  = r25
.def		oLoopR   = r21


loop:
	ldi		r16, (1<<2)|(1<<3)			; let A pass
	out		PORTB, r16					; Green light on in A

	ldi		r16, (1<<4)
	out		PORTD, r16

	sbrc	cross,0
	rjmp	red

	ldi		oLoopR, 0x8B
	rcall	oLoop						; Set green light for 3s and Red in B

	ldi		r16, (1<<1)|(1<<4)|(1<<3)
	out		PORTB, r16					; yellow in A, red and yellow in B


	ldi		oLoopR, 0x6B
	rcall	oLoop

	ldi		r16, (1<<0)|(1<<5)
	out		PORTB, r16					; red in A, green in B

	ldi		oLoopR, 0x8B
	rcall	oLoop						; delay 3s

	ldi		r16, (1<<4)|(1<<1)|(1<<0)	;yellow in A, red in A, yellow in B
	out		PORTB, r16

	ldi		oLoopR,0x6B
	rcall	oLoop

	ldi		r16, (1<<2)|(1<<3)			; let A pass
	out		PORTB, r16					; Green light on in A
	ldi		oLoopR,0x6B
	rcall	oLoop
	rjmp	loop


red:
	ldi		r16, (1<<5)
	out		PORTD, r16

	ldi		r16, (1<<0)|(1<<3)			;red for both
	out		PORTB, r16

	ldi		oLoopR,0xFF
	rcall	oLoop

	ldi		cross, 0x00				; set cross back to 0

	rjmp	loop

isr_into:
	in		r16, PIND
	sbrs	r16, 2
	reti

	ldi		cross, 0x01
	reti

oLoop:
	ldi			iLoopRl, 0xFF				;initialize inner loop count LOW

oLoopOuter:
	ldi			iLoopRh, 0xFF

iLoop:
	sbiw		iLoopRl, 1					;decrement inner loop register
	brne		iLoop						;branch to iLoop if iLoop register!=0

outLoop:
	dec			iLoopRh
	brne		outLoop

	dec			oLoopR						;decrement outer loop register
	brne		oLoop						;branch to oLoop if oLoopR !=0
	ret									;call back main