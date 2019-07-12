/*
 * AssemblerHW6Q1a.asm
 *
 *  Created: 4/29/2019 5:28:53 PM
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
;CS02:00 = '011' devides CLOCK_IO by a factor of 64 in prescaler
;That's in the TCCRn register. Here n = 0
;ldi r16, 0x00
ldi r16, (1 << cs01) | (1 << cs00)
andi r16, ~(1 << cs02)
out tccr0, r16
;both of the cnt1,2 should be cleared at first
clr cnt1
clr cnt2
ldi cmp, 1
jmp main


ovf:
inc cnt1
;cp cnt1, cmp
;brne DO_NOT_SET_cnt2
cpi cnt1, 32
brne DO_NOT_SET_cnt2
;modify cnt2 if cnt = 128
inc cnt2
;ldi cnt1, 0
clr cnt1
DO_NOT_SET_cnt2:

cpi cnt2, 13
brlt TURN_ON_PLAN_A
rjmp TURN_ON_PLAN_B


TURN_ON_PLAN_A:
sbi portd, pd5;turn on led1
cbi portd, pd4;turn off led2
rjmp AFTER

TURN_ON_PLAN_B:
cbi portd, pd5;turn off led1
sbi portd, pd4;turn on led2
cpi cnt2, 24
brne AFTER
clr cnt2
AFTER:
reti

main:
jmp main

