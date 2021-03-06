/*
 * AssemblerHW4Q1b.asm
 *
 *  Created: 4/10/2019 6:49:12 PM
 *   Author: Alireza
 */ 
.DEF OUTER=R19
.DEF INNER=R20
.DEF CNT=R21
.DEF FLAG=R22

RESET:
;SETTING INPUT/OUTPUT PORTS
ANDI R17, (0 << PD3) | (0 << PD6);INPUT
ORI R17, (1 << PD4) | (1 << PD5);OUTPUT
OUT DDRD, R17
ORI R18, (1 << PD3) | (1 << PD6);PULL UP
OUT PORTD, R18
LDI CNT, 0

JMP MAIN
 
MAIN:
CPI CNT, 1
BREQ AFTER
SBIS PIND, PD6;SKIP IF SW2 RELEASED
CALL BLINK_5_TIMES


AFTER:
SBIC PIND, PD6;SKIP IF SW2 PRESSED
LDI CNT, 0

JMP MAIN

DELAY_HALF_SEC:
LDI OUTER, 230;OUTER LOOP VARIABLE
LDI INNER, 230;INNER LOOP VARIABLE
OUTER_LOOP:
 DEC OUTER
 CPI OUTER, 0
 BREQ CONTINUE
 LDI INNER, 200
 INNER_LOOP:
   NOP
   NOP
   NOP
   NOP
   NOP
   NOP   
   DEC INNER
   CPI INNER, 0
   BREQ OUTER_LOOP 
 JMP INNER_LOOP
 
JMP OUTER_LOOP
CONTINUE:
RET

BLINK_5_TIMES:
LDI CNT, 5
BLINK_5_TIMES_LOOP:
;TURN LED ON
SBI PORTD, PD4
CALL DELAY_HALF_SEC
;TURN LED OFF 
CBI PORTD, PD4
CALL DELAY_HALF_SEC
DEC CNT
CPI CNT,0
BRNE BLINK_5_TIMES_LOOP
LDI CNT, 1
RET

