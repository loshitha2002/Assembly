;======================================================
; Task 3: ADC Reading (Polling Method)
; Input:  Potentiometer on ADC0 (PC0)
; Output: 8 LEDs on PORTD
; Ref:    AVcc (5V)
; Logic:  Read ADC0 -> Display MSB on PORTD
;======================================================

.include "m328pdef.inc"

.org 0x0000
    rjmp main

main:
    ; --- 1. STACK SETUP ---
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16

    ; --- 2. PORT SETUP ---
    ; Set PORTD as Output (LEDs)
    ldi r16, 0xFF       ; All 8 bits high
    out DDRD, r16       ; PORTD = Output

    ; --- 3. ADC CONFIGURATION ---
    ; ADMUX Register Setup:
    ; REFS1:0 = 01 (AVcc with external capacitor at AREF)
    ; ADLAR   = 1  (Left Adjust Result for 8-bit precision)
    ; MUX3:0  = 0000 (ADC0 pin)
    ; Value: 0b01100000 = 0x60
    ldi r16, 0x60
    sts ADMUX, r16

    ; ADCSRA Register Setup:
    ; ADEN    = 1   (Enable ADC)
    ; ADSC    = 0   (Don't start yet)
    ; ADATE   = 0   (Manual trigger)
    ; ADIF    = 0   (Flag)
    ; ADIE    = 0   (No interrupt)
    ; ADPS2:0 = 111 (Prescaler 128 -> 16MHz/128 = 125kHz, good for ADC)
    ; Value: 0b10000111 = 0x87
    ldi r16, 0x87
    sts ADCSRA, r16

loop:
    ; --- START CONVERSION ---
    lds r16, ADCSRA
    ori r16, 0x40       ; Set ADSC bit (bit 6) to start
    sts ADCSRA, r16

wait_adc:
    ; --- POLLING (WAIT) ---
    lds r16, ADCSRA     ; Read Status
    sbrc r16, 6         ; Skip next instruction if ADSC is Cleared (0)
    rjmp wait_adc       ; Jump back if ADSC is still 1 (busy)

    ; --- READ & DISPLAY ---
    ; Since ADLAR=1, the top 8 bits are in ADCH
    lds r16, ADCH       ; Read ADC High Byte
    out PORTD, r16      ; Show on LEDs

    rjmp loop           ; Repeat forever
