/*
 * AssemblerHW5Q2c.asm
 *
 *  Created: 4/22/2019 6:32:47 PM
 *   Author: Alireza
 */ 

.dseg 
.equ	LCD_RS	= 1
.equ	LCD_RW	= 2
.equ	LCD_E	= 3

.def temp = r16
.def argument = r17		;argument for calling subroutines
.def return	= r18		;return value from subroutines
.def flag = r21
.def index = r22
.def rownum = r23
.def four = r24
.def cnt = r19
.cseg
.org 0x000
jmp RESET
.org 0x002
jmp EXT_INT0
;.org 0x004
;jmp EXT_INT1

.org 0x02A
LCDTABLE: .db 11,"Hello World"
;.def fifty_five=r25
;.def 

RESET:
	ldi	temp, low(RAMEND)
	out	SPL, temp
	ldi	temp, high(RAMEND)
	out	SPH, temp
;LCD after power-up: ("*" means black bar)
;|****************|
;|		  |

	rcall	LCD_init
	
;LCD now:
;|&		  | (&: cursor, blinking)
;|		  |

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

;just writing "Hello World" to the lcd screen		
PART_C:
ldi zl, low(LCDTABLE * 2)
ldi zh, high(LCDTABLE * 2)
;uncomment the following line in order to do partB
;call LCD
jmp main

main:
jmp main	


write_char:
	
	rcall	LCD_wait
	;ldi	argument, 'H'	;write 'A' to the LCD char data RAM
	rcall	LCD_putchar
	
;|A&		  |
;|		  |
	
	rcall	LCD_wait
	;ldi argument, 'e'
	;rcall LCD_putchar 
	;ldi	argument, 0x80	;now let the cursor go to line 0, col 0 (address 0)
	;rcall	LCD_command	;for setting a cursor address, bit 7 of the commands has to be set
	
;|A		  | (cursor and A are at the same position!)
;|		  |
	
;	rcall	LCD_wait
;	rcall	LCD_getchar	;now read from address 0
	
;|A&		  | (cursor is also incremented after read operations!!!)
;|		  |
	
;	push	return		;save the return value (the character we just read!)
	
;	rcall	LCD_delay
;	pop	argument	;restore the character
;	rcall	LCD_putchar	;and print it again

;|AA&		  | (A has been read from position 0 and has then been written to the next pos.)
;|		  |
ret

lcd_command8:	;used for init (we need some 8-bit commands to switch to 4-bit mode!)
	in	temp, DDRA		;we need to set the high nibble of DDRA while leaving
					;the other bits untouched. Using temp for that.
	sbr	temp, 0b11110000	;set high nibble in temp
	out	DDRA, temp		;write value to DDRA again
	in	temp, PortA		;then get the port value
	cbr	temp, 0b11110000	;and clear the data bits
	cbr	argument, 0b00001111	;then clear the low nibble of the argument
					;so that no control line bits are overwritten
	or	temp, argument		;then set the data bits (from the argument) in the
					;Port value
	out	PortA, temp		;and write the port value.
	sbi	PortA, LCD_E		;now strobe E
	nop
	nop
	nop
	cbi	PortA, LCD_E
	in	temp, DDRA		;get DDRA to make the data lines input again
	cbr	temp, 0b11110000	;clear data line direction bits
	out	DDRA, temp		;and write to DDRA
ret

lcd_putchar:
	push	argument		;save the argmuent (it's destroyed in between)
	in	temp, DDRA		;get data direction bits
	sbr	temp, 0b11110000	;set the data lines to output
	out	DDRA, temp		;write value to DDRA
	in	temp, PortA		;then get the data from PortA
	cbr	temp, 0b11111110	;clear ALL LCD lines (data and control!)
	cbr	argument, 0b00001111	;we have to write the high nibble of our argument first
					;so mask off the low nibble
	or	temp, argument		;now set the argument bits in the Port value
	out	PortA, temp		;and write the port value
	sbi	PortA, LCD_RS		;now take RS high for LCD char data register access
	sbi	PortA, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortA, LCD_E
	pop	argument		;restore the argument, we need the low nibble now...
	cbr	temp, 0b11110000	;clear the data bits of our port value
	swap	argument		;we want to write the LOW nibble of the argument to
					;the LCD data lines, which are the HIGH port nibble!
	cbr	argument, 0b00001111	;clear unused bits in argument
	or	temp, argument		;and set the required argument bits in the port value
	out	PortA, temp		;write data to port
	sbi	PortA, LCD_RS		;again, set RS
	sbi	PortA, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortA, LCD_E
	cbi	PortA, LCD_RS
	in	temp, DDRA
	cbr	temp, 0b11110000	;data lines are input again
	out	DDRA, temp
ret

lcd_command:	;same as LCD_putchar, but with RS low!
	push	argument
	in	temp, DDRA
	sbr	temp, 0b11110000
	out	DDRA, temp
	in	temp, PortA
	cbr	temp, 0b11111110
	cbr	argument, 0b00001111
	or	temp, argument

	out	PortA, temp
	sbi	PortA, LCD_E
	nop
	nop
	nop
	cbi	PortA, LCD_E
	pop	argument
	cbr	temp, 0b11110000
	swap	argument
	cbr	argument, 0b00001111
	or	temp, argument
	out	PortA, temp
	sbi	PortA, LCD_E
	nop
	nop
	nop
	cbi	PortA, LCD_E
	in	temp, DDRA
	cbr	temp, 0b11110000
	out	DDRA, temp
ret

LCD_getchar:
	in	temp, DDRA		;make sure the data lines are inputs
	andi	temp, 0b00001111	;so clear their DDR bits
	out	DDRA, temp
	sbi	PortA, LCD_RS		;we want to access the char data register, so RS high
	sbi	PortA, LCD_RW		;we also want to read from the LCD -> RW high
	sbi	PortA, LCD_E		;while E is high
	nop
	in	temp, PinA		;we need to fetch the HIGH nibble
	andi	temp, 0b11110000	;mask off the control line data
	mov	return, temp		;and copy the HIGH nibble to return
	cbi	PortA, LCD_E		;now take E low again
	nop				;wait a bit before strobing E again
	nop	
	sbi	PortA, LCD_E		;same as above, now we're reading the low nibble
	nop
	in	temp, PinA		;get the data
	andi	temp, 0b11110000	;and again mask off the control line bits
	swap	temp			;temp HIGH nibble contains data LOW nibble! so swap
	or	return, temp		;and combine with previously read high nibble
	cbi	PortA, LCD_E		;take all control lines low again
	cbi	PortA, LCD_RS
	cbi	PortA, LCD_RW
ret					;the character read from the LCD is now in return

LCD_getaddr:	;works just like LCD_getchar, but with RS low, return.7 is the busy flag
	in	temp, DDRA
	andi	temp, 0b00001111
	out	DDRA, temp
	cbi	PortA, LCD_RS
	sbi	PortA, LCD_RW
	sbi	PortA, LCD_E
	nop
	in	temp, PinA
	andi	temp, 0b11110000
	mov	return, temp
	cbi	PortA, LCD_E
	nop
	nop
	sbi	PortA, LCD_E
	nop
	in	temp, PinA
	andi	temp, 0b11110000
	swap	temp
	or	return, temp
	cbi	PortA, LCD_E
	cbi	PortA, LCD_RW
ret

LCD_wait:				;read address and busy flag until busy flag cleared
	rcall	LCD_getaddr
	andi	return, 0x80
	brne	LCD_wait
	ret


LCD_delay:
	clr	r2
	LCD_delay_outer:
	clr	r3
		LCD_delay_inner:
		dec	r3
		brne	LCD_delay_inner
	dec	r2
	brne	LCD_delay_outer
ret

LCD_init:
	
	ldi	temp, 0b00001110	;control lines are output, rest is input
	out	DDRA, temp
	
	rcall	LCD_delay		;first, we'll tell the LCD that we want to use it
	ldi	argument, 0x20		;in 4-bit mode.
	rcall	LCD_command8		;LCD is still in 8-BIT MODE while writing this command!!!

	rcall	LCD_wait
	ldi	argument, 0x28		;NOW: 2 lines, 5*7 font, 4-BIT MODE!
	rcall	LCD_command		;
	
	rcall	LCD_wait
	ldi	argument, 0x0F		;now proceed as usual: Display on, cursor on, blinking
	rcall	LCD_command
	
	rcall	LCD_wait
	ldi	argument, 0x01		;clear display, cursor -> home
	rcall	LCD_command
	
	rcall	LCD_wait
	ldi	argument, 0x06		;auto-inc cursor
	rcall	LCD_command
ret
;PARTC
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
/*
ldi zh, high(BCDTO7_SEG)
ldi zl, low(BCDTO7_SEG)
add zl, r0;
lpm r2, z
out portb, r2
*/
;sei;roll back I flag to its previous status, done by executing reti

mov r20, r0
cpi r20, 10
brge GTEQ
;if we reach here, r20 will have a value between 0 through 9. I'ts corresponding ASCII code is obtained by adding a 48.
;note that '0' =  48 and 0 = 0
subi r20, -48
jmp AFTER_ASCII

GTEQ:;r20 is between 0x0A and 0x0F. for converting to it's corresponding ASCII code, we add it to 55. Note that 'A' =65 and A = 10 
subi r20, -55

AFTER_ASCII:

FINISH_EXT_INT:
mov argument, r20
call write_char
out portb, r20
reti

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
;interrupt request occurs on the falling edge of int1, low level int0
andi r16, ~(1 << ISC00) & ~(1 << ISC10) 
ori r16, (1 << ISC01) | (1 << ISC11)
out mcucr, r16

sei;global interrupt flag is set
ret
LCD:
;adiw z, 1
lpm cnt, z
;out portb, cnt
adiw z,1
LOOPLCD:

lpm argument, z + 1
call write_char
dec cnt
cpi cnt, 0
breq AFTER
rjmp LOOPLCD
AFTER:
ret