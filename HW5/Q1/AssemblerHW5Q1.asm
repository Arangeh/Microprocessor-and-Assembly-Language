/*
 * AssemblerHW5Q1.asm
 *
 *  Created: 4/20/2019 7:32:11 PM
 *   Author: Alireza
 */ 
.org 0x000
jmp RESET
.org 0x002
jmp EXT_INT0
.org 0x004
jmp EXT_INT1
.def flag = r21
.def index = r22
.def rownum = r23
.def four = r24
.org 0x02A
.dseg 

.cseg
BCDTO7_SEG: .db 0x3f, 0x06, 0x5d, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x61, 0x5e, 0x79, 0x71
RESET:
;on closing sw1, a falling edge should be triggered because we had pulled up PD3 which is in turn connected to sw1
;sw1 is connected to pd3, int1
ldi four, 4
andi r27, (0 << pd3) | (0 << pd6);input
ori r27, (1 << pd4) | (1 << pd5);output
out ddrd, r27
ori r28, (1 << pd3) | (1 << pd6);pull up
out portd, r28
cbi ddrd, pd2;INT0 is defined as input port
sbi portd, pd2;pull up INT0

;pc7:4 => output, all are set to 0
;pc3:0 => input, pulled up
ldi r19, 0xF0
out ddrc, r19
com r19
out portc, r19

ldi r19, 0xff
out ddrb, r19


call SETUP_INT

clr flag
jmp main

;PART a ISR of external interrupt 1 caused by pressing the sw1 on pd3
EXT_INT1:
cpi flag, 0
breq TURN_ON
TURN_OFF:
ldi flag, 0
cbi portd, pd5;turn off LED1
jmp AFTER
TURN_ON:
ldi flag, 1
sbi portd, pd5;turn on LED1 
AFTER:

reti;



EXT_INT0:
;PARTb external interrupt caused by pressing one of the keyboard buttons
cli 
clr r16
out gicr, r16

call KEYFIND

ldi r16, (1 << INTF0) | (1 << INTF1) | (1 << INTF2)
out gifr, r16;ignore interrupt requests possible during the execution of KEYFIND method.
ldi r16,  (1 << INT0) | (1 << INT1);enable INT0, INT1 bit on GICR register
out gicr, r16;roll back gicr to its previous status

ldi r19,0x0f
out portc, r19;recover the outputs in their previous format

;PARTc showing the pressed button on the 7_segment
///*
ldi zh, high(BCDTO7_SEG << 1)
ldi zl, low(BCDTO7_SEG << 1)
add zl, r0;
lpm r20, z
out portb, r20
//*/
;sei;roll back I flag to its previous status, done by executing reti

;mov r20, r0

;FINISH_EXT_INT:
;out portb, r20
reti

main:
jmp main

KEYFIND:

;row1=pc4
call ROW1
call FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row2=pc5
call ROW2
call FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row3=pc6
call ROW3
call FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row4=pc7
call ROW4
call FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

AFTER_KEYFIND:


;calculate the value of the pressed key and store it in r0
clr r0
LOOP:

cpi rownum, 0
breq FINISH
add r0, four
dec rownum
jmp LOOP 
FINISH:
add r0, index
ret

FIND_ROW:;returns the index in the column (between 0 through 3) if the correct row has been identified and 4 otherwise 
ldi index, 4
sbis pinc, pc0
ldi index, 0
sbis pinc, pc1
ldi index, 1
sbis pinc, pc2
ldi index, 2
sbis pinc, pc3
ldi index, 3
ret

ROW1:;pc4
ldi rownum, 0
cbi portc, pc4
sbi portc, pc5
sbi portc, pc6
sbi portc, pc7
ret

ROW2:;pc5
ldi rownum, 1
sbi portc, pc4
cbi portc, pc5
sbi portc, pc6
sbi portc, pc7
ret

ROW3:;pc6
ldi rownum, 2
sbi portc, pc4
sbi portc, pc5
cbi portc, pc6
sbi portc, pc7
ret

ROW4:;pc7
ldi rownum, 3
sbi portc, pc4
sbi portc, pc5
sbi portc, pc6
cbi portc, pc7
ret

SETUP_INT:
clr r16
nop
ldi r16,  (1 << INT0) | (1 << INT1);enable INT0, INT1 bit on GICR register
out gicr, r16

clr r16

;we have CASE1 AND CASE2 as the following. Each of them followed by two othre lines as its block.
;Comment one and uncomment the other.
;Their only difference is in the way INT1 is sensed.

;CASE1:;interrupt request occurs on the falling edge of INT1, INT0
;andi r16, ~(1 << ISC00) & ~(1 << ISC10) 
;ori r16, (1 << ISC01) | (1 << ISC11)

CASE2:;interrupt request occurs on the low level of INT1, falling edge of INT0
andi r16, ~(1 << ISC00) & ~(1 << ISC10) & ~(1 << ISC11) 
ori r16, (1 << ISC01)  

out mcucr, r16

sei;global interrupt flag is set
ret
