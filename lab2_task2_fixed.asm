; Task2_fixed.asm
;
; Button press drives INT0 (PD2) LOW -> LED ON (PD0)
;

.include	"m328pdef.inc"
	.cseg
	.org	0x00	
		jmp		start
	.org	INT0addr 
		jmp	isr_into

start:
	ldi		r20, 0x00
	ldi		r16, 0x01
	sts		EICRA, r16
	ldi		r16, 0x01
	out		EIMSK, r16
	sei

	ldi		r17, 0x01
	out		DDRD, r17

loop:
	
	rjmp	loop

isr_into:
	in		r16, PIND
	sbrs	r16,2
	rjmp	on
	rjmp	off
	reti
	

on:
	ldi		r16, 0x01
	out		PORTD, r16
	reti

off:
	ldi		r16, 0x00
	out		PORTD, r16
	reti
