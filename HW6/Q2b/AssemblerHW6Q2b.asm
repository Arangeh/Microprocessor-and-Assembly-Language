/*
 * AssemblerHW6Q2b.asm
 *
 *  Created: 5/2/2019 9:32:07 PM
 *   Author: Alireza
 */ 

;To turn on LED1,2 each of them glows for 3 seconds and then we turn each of them off, again for duration of 3 seconds
.def cnt1 = r17
.def cnt2 = r18
.def cmp = r19
.dseg
.cseg
.org 0x000
jmp reset
.org 0x012;Timer/Counter0 overflow
jmp ovf
.org 0x026
jmp cmp0


reset:
sei 
;Timer Overflow Interrupt Enable bit should be set
;in order for Timer/Counter0 to work as questioned
ldi r16, (1 << toie0)
out timsk, r16
;make pd3, pd4, pd5 as output
;make pd6, pd7 as input 
ldi r16, (1 << pd3) | (1 << pd4) | (1 << pd5)

andi r16, (~(1 << pd6)) & (~(1 << pd7))
out ddrd, r16
;ldi r16, 0x00;
ldi r16, (1 << pd6) | (1 << pd7)
out portd, r16

;make pb3 as output
ldi r16, (1 << pb3)
out ddrb, r16


;CS02:00 = '101' devides CLOCK_IO by a factor of 1024 in prescaler
;That's in the TCCRn register. Here n = 0
;ldi r16, 0x00
ldi r16, (1 << cs02) | (1 << cs00)
andi r16, ~(1 << cs01)
;we have determined Phase Correct PWM mode by 
;altering WGM01, WGM00 bits
ori r16, (1 << wgm00)
andi r16, ~(1 << wgm01)
;in WGM mode, COM01:00 should be set as 1 and 0 respectively
;OC0 is cleared on BOTTOM and set on compare match in Timer/Counter0
;inverting mode
ori r16, (1 << com00) | (1 << com01)

out tccr0, r16;constant high 
ldi r16, 255;its initial value clears OC0 constantly
out ocr0, r16


jmp main

cmp0:

reti

ovf:

reti

main:
sbis pind, pd7 ; skip if sw1 released
call sw1_pressed
sbis pind, pd6 ; skip if sw2 released
call sw2_pressed
jmp main

sw1_pressed:
ldi r16, 255 - 120
out ocr0, r16
ret

sw2_pressed:
ldi r16, 255-240
out ocr0, r16
ret