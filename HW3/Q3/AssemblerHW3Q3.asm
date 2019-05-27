/*
 * AssemblerHW3Q3.asm
 *
 *  Created: 3/23/2019 12:08:18 PM
 *   Author: Alireza
 */ 

.org 0x00
.def temp1 = R29
.def temp2 = R30
jmp reset_isr

reset_isr:
    ;clr temp1
    ;out ddrA, temp1

    ;SREG will be transfered to portB
	ldi	temp1, 0xFF
    
	out ddrB, temp1
    ldi temp2, 0x80
jmp main


main:
LDI R17, 0x48
LSL R17
BST R17, 4
ADD R17, temp2
SEI
IN R16, SREG
OUT PORTB, R16
jmp loop

loop:
jmp loop