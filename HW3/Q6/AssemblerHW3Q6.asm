/*
 * AssemblerHW3Q5.asm
 *
 *  Created: 3/24/2019 10:09:21 AM
 *   Author: Alireza
 */ 

.def FIB_PREV=R16
.def FIB_NEXT=R17
.def LOOPCNT=R18
.def TEMP=R19
RESET:
 SER TEMP
 ;OUT DDRB, TEMP
 LDI ZH, 0X00
 LDI ZL, 0X70
MAIN:
 LDI FIB_PREV, 1
 LDI FIB_NEXT, 1
 ST Z+, FIB_PREV
 ST Z+, FIB_NEXT
STORE:;STORES THE NEXT FIBONACCI NUMBER IN SRAM
 MOV TEMP,FIB_NEXT
 ADD FIB_NEXT, FIB_PREV
 MOV FIB_PREV, TEMP
 ST Z+, FIB_NEXT
 INC LOOPCNT
 CPI LOOPCNT, 10
 BRNE STORE
 ;OUT PORTB, FIB_NEXT
 JMP LOOP
LOOP:
 JMP LOOP