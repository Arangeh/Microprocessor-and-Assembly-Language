/*
* AssemblerHW8Q1b.asm
*
*  Created: 5/23/2019 9:23:57 PM
*   Author: Alireza
*/ 

.def index = r22
.def rownum = r23
.def four = r24
.def cnt = r25
.org 0x000
rjmp reset

.org 0x002
rjmp EXT_INT0

.org 0x02A 

reset:
ldi four, 4
cbi ddrd, pd2;INT0 is defined as input port
sbi portd, pd2;pull up INT0
ldi r16, 0xFF
out DDRA, r16
clr r16
rcall SETUP_INT;interrupt configurations
rcall USART_Init;USART initial configurations

;pc7:4 => output, all are set to 0
;pc3:0 => input, pulled up
ldi r16, 0xF0
out ddrc, r16
com r16
out portc, r16
sei
rjmp main

EXT_INT0:
cli
;PARTb external interrupt caused by pressing one of the keyboard buttons 
clr r16
out gicr, r16

rcall KEYFIND
ldi r16, (1 << INTF0)
out gifr, r16;ignore interrupt requests possible during the execution of KEYFIND method.
ldi r16,  (1 << INT0);enable INT0, INT1 bit on GICR register
out gicr, r16;roll back gicr to its previous status

ldi r19,0x0f
out portc, r19;recover the outputs in their previous format

mov r20, r0

cpi r20, 10
brge GTEQ
;if we reach here, r20 will have a value between 0 through 9. I'ts corresponding ASCII code is obtained by adding a 48.
;note that '0' =  48 and 0 = 0
subi r20, -48
rjmp AFTER_ASCII

GTEQ:;r20 is between 0x0A and 0x0F. for converting to it's corresponding ASCII code, we add it to 55. Note that 'A' =65 and A = 10 
subi r20, -55

AFTER_ASCII:

FINISH_EXT_INT:
mov r0, r20
;now r0 and r20 have the ASCII code of the pressed key from the
;keyboard
rcall USART_Transmit


reti

main:
rjmp loop2

loop2:
rjmp loop2

USART_Transmit:
ldi r17, 0
;Wait for empty transmit buffer
sbis UCSRA, UDRE
rjmp USART_Transmit
;Copy 9th bit from r17 to TXB8
cbi UCSRB, TXB8
sbrc r17, 0
sbi UCSRB, TXB8
;Put data(r20) into buffer, sends the data;out UDR, r16 
out UDR, r20
;out PORTA, r20
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

USART_Init:

;Set operational mode: asynchronous, double mode
;double mode has been selected due to having less errror
;than the normal mode
ldi r16, (1 << U2X)
;ldi r16, (0 << U2X)
out UCSRA, r16

;Enable receiver and transmitter
;Set frame format: 9 bit characters, 1 stop bit, enabled, even parity
ldi r16, (1 << RXEN) | (1 << TXEN) | (1 << UCSZ2)
;andi r16, ~(1 << UCSZ2)
out UCSRB, r16

ldi r16, ((1 << URSEL) | (1 << UCSZ0) | (1 << UCSZ1) | (1 << UPM1))
andi r16, ((~(1 << USBS)) & (~(1 << UPM0)) & (~(1 << UMSEL)))
out UCSRC, r16

;Set BAUD RATE for double mode
;UBRR = 416 = 256 + 151
ldi r16, 1;256
out UBRRH, r16
ldi r16, 160
out UBRRL, r16
clr r16
ret

SETUP_INT:
nop
ldi r16,  (1 << INT0); enable INT0, bit on GICR register
out gicr, r16
clr r16
;interrupt request occurs on the low level of INT1, falling edge of INT0
andi r16, ~(1 << ISC00) ;& ~(1 << ISC10) & ~(1 << ISC11) 
ori r16, (1 << ISC01)  
out mcucr, r16
sei;global interrupt flag is set
ret

KEYFIND:

;row1=pc4
rcall ROW1
rcall FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row2=pc5
rcall ROW2
rcall FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row3=pc6
rcall ROW3
rcall FIND_ROW
cpi index, 4
brne AFTER_KEYFIND

;row4=pc7
rcall ROW4
rcall FIND_ROW
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

