/*
 * AssemblerHW7Q2.asm
 *
 *  Created: 5/11/2019 11:33:54 PM
 *   Author: Alireza
 */ 

 .dseg
.equ	LCD_RS	= 1
.equ	LCD_RW	= 2
.equ	LCD_E	= 3

.def maximum = r0
.def	temp = r16
.def	argument= r17		;argument for calling subroutines
.def	return	= r18		;return value from subroutines
.def cnt = r19
.def factor = r20;factor of 13
.def humidity = r21
.def adclow = r22
.def units = r23
.def tens = r24
.def hundreds = r25
.def flag = r29

.cseg
 .org 0x000
 jmp reset

 .org 0x01c
 jmp adc_int;handling ADC interrupt

 .org 0x02A
 reset:
 ;clr flag
 ;PA1, PB2 should be set as input
 cbi ddrb, pb2
 cbi ddra, pa1
 ;PD5 should be set as output
 sbi ddrd, pd5
 ;PD4 should be set as output, too
 sbi ddrd, pd4

 ;PORT C is output for working with LCD
 ori r16, 0xff
 mov maximum, r16
 out ddrC, r16
 rcall lcd_init

 ldi r16, (1 << ADEN) | (1 << ADATE) | (1 << ADIE)
 andi r16, ~(1 << ADATE);disable Auto Trigger mode, only setting ADSC will start the conversion logic
 ;prescaler settings
 andi r16, (~(1 << ADPS2)) & (~(1 << ADPS1)) & (~(1 << ADPS0))
 out ADCSRA, r16
 
 ;Trigger Source has been set to be free-running mode
 clr r16
 andi r16, (~(1 << ADTS2))&(~(1 << ADTS1))&(~(1 << ADTS0))
 out SFIOR, r16

 ;in order to have AVCC as the reference voltage, we should have REFS1:0 = 01
 ;we don't want the ADC register to be left-aligned, so ADLAR should be cleared
 ;in order to get digital equivalent of ADC1 in single-ended mode, we should have MUX4:0 = 00001
 clr r16
 
 ;for questions about single-ended channel, uncomment the following three lines and 'jmp main', comment 'jmp check_boundaries'
 ;also change the commetn/uncomment status of code snippets mentioned at interrupt 'adc_int' 
 ldi r16, (1 << REFS0) | (1 << MUX0) 
 andi r16, (~(1 << REFS1))&(~(1 << ADLAR))&(~(1 << MUX4))&(~(1 << MUX3))&(~(1 << MUX2))&(~(1 << MUX1))
 out ADMUX, r16
 

 sei
 ;experimental
 ldi r16,0xFF
 out DDRD, r16
 clr r16
 jmp main
 ;jmp check_boundaries
 
 
 adc_int:
 ;for questions about single-ended channel, uncomment the following till 'Single_Ended_Termination' label, comment everything from there down to 
 ;the end of ISR
 ;/*
 rcall LCD_init 
 clr factor
 clr humidity

 ;we need the value of ADCH because ADC is between 155 and 790 approximately, for which 2 bits from ADCH would be envolved
 in adclow, ADCL
 in temp, ADCH
 
 ;mov r31, adclow

 ;out portd, r31

 rcall handle_ADCH;computes initial humidity
 rcall determine_factor;computes factor
 add humidity, factor;computes final humidity
 
 rcall BCD_convert
 
 ;rcall LCD_clear
 rcall show_on_lcd
 ;*/
 ;for questions about differential channel, do exactly in opposition to whatever mentioned about single-ended channel in this ISR
 Single_Ended_Termination:
 /*
 in adclow, ADCL
 in temp, ADCH
 ldi flag, 1
 sbrc temp, 1;skip if temp(1) = 0, equivalently if conversion result is positive
 ldi flag, 0
 ;mov r31, temp
 out portd, temp
 ;out portd, adclow
 ;rcall LED_control
 */
 reti
 ;3rd part. ghesmate jijm
 main:
 
 
 sbic ADCSRA, ADSC
 rjmp main
 sbi ADCSRA, ADSC
 

 rjmp main
 
 ;6th part. ghesmate vav
 check_boundaries:
 ;upperbound: ADC3 = + and ADC1 = -
 
 ldi r16,  (1 << MUX4) | (1 << MUX1) | (1 << MUX0) | (1 << REFS0) 
 andi r16, (~(1 << REFS1))&(~(1 << ADLAR))&(~(1 << MUX3))&(~(1 << MUX2)); & (~(1 << REFS0))
 out ADMUX, r16
 rcall check_upperbound
 
 cli 
 ;lowerbound: ADC1 = + and ADC2 = -
 ldi r16, (1 << MUX4) | (1 << MUX3) | (1 << MUX0) | (1 << REFS0) 
 andi r16, (~(1 << REFS1))&(~(1 << ADLAR))&(~(1 << MUX2))&(~(1 << MUX1)); & (~(1 << REFS0))
 out ADMUX, r16
 rcall check_lowerbound
 
 cli
 rjmp check_boundaries 
 


 check_upperbound:
 sbic ADCSRA, ADSC
 rjmp check_upperbound
 sbi ADCSRA, ADSC
 sei
 ret

 check_lowerbound:
 sbic ADCSRA, ADSC
 rjmp check_lowerbound
 sbi ADCSRA, ADSC
 sei
 ret

 LED_control:
 cpi flag, 0
 brne turn_on
 breq turn_off
 turn_on:;turns on LED2
 sbi portd, pd4
 rjmp LED_done
 turn_off:;turns off LED2
 cbi portd, pd4
 LED_done:
 ret

 show_on_lcd:
  subi hundreds, -48;get the ASCII code of hundreds digit
 mov argument, hundreds
 rcall write_char
 subi tens, -48;get the ASCII code of tens digit
 mov argument, tens
 rcall write_char
 subi units, -48;get the ASCII code of units digit
 mov argument, units
 rcall write_char
 ret
 
 loop:
 rjmp loop

handle_ADCH:
 
 cpi temp, 0;0
 breq EQZero
 cpi temp, 1;256 
 breq EQOne
 cpi temp, 2;512
 breq EQTwo
 cpi temp, 3;256 + 512 = 768 
 breq EQThree
 
 EQZero:
 ldi humidity, 0
 subi adclow, 154;acdlow is absolutely greater than or equal to 154 in this case. So there'll be no problem subtracting 154 from it
 ;we do so because we want to know how many multiples of 13 are there between 154 and acdlow.
 rjmp after
 EQOne:
 ldi humidity, 16
 rjmp after
 EQTwo:
 ldi humidity, 56
 rjmp after
 EQThree:
 ldi humidity, 96
 after: 	
ret

determine_factor:
;the MSB prevents some compare methods from working correctly. It's been handled seperately
sbrs adclow, 7
jmp aftermath
cbr adclow, 0x8f;clear the 7th bit, equivalently subtracts 128 from adclow
subi factor, -20;128 is approximately 6.5 * 20. so add 10 to factor
aftermath:
cpi adclow, 13;approximately every 6.5 unit increase in adclow register corresponds to a unit increase in humidity percentage. In order to be somewhat
;more precise, we can add 2 units to factor every time we subtract adclow by 13 = 6.5 * 2
;We keep subtracting till adclow stays positive
brlt determining_finished
subi factor, -2;add with 2
subi adclow, 13
rjmp aftermath

determining_finished:
ret
;The following procedure will compute the units digit and the tens digit of a BCD number equivalent to humidity register
;for example, having factor = 45, the 
BCD_convert:

clr units
clr tens
clr hundreds

mov r27, humidity
mov r26, r27
clr r28
;determining hundreds digit
compute_hundreds:
subi r27, 100
cp r27, r28
brlt compute_hundreds_finished
inc hundreds
mov r26, r27
rjmp compute_hundreds
compute_hundreds_finished:
mov r27, r26
;determining tens digit
compute_tens:
subi r27, 10
cp r27, r28
brlt compute_tens_finished
inc tens
mov r26, r27
rjmp compute_tens
compute_tens_finished:
mov r27, r26
;determining units digit
compute_units:
subi r27, 1
cp r27, r28
brlt compute_units_finished
inc units
mov r26, r27
rjmp compute_units
compute_units_finished:
ret

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
	in	temp, DDRC		;we need to set the high nibble of DDRA while leaving
					;the other bits untouched. Using temp for that.
	sbr	temp, 0b11110000	;set high nibble in temp
	out	DDRC, temp		;write value to DDRA again
	in	temp, PortC		;then get the port value
	cbr	temp, 0b11110000	;and clear the data bits
	cbr	argument, 0b00001111	;then clear the low nibble of the argument
					;so that no control line bits are overwritten
	or	temp, argument		;then set the data bits (from the argument) in the
					;Port value
	out	PortC, temp		;and write the port value.
	sbi	PortC, LCD_E		;now strobe E
	nop
	nop
	nop
	cbi	PortC, LCD_E
	in	temp, DDRC		;get DDRA to make the data lines input again
	cbr	temp, 0b11110000	;clear data line direction bits
	out	DDRC, temp		;and write to DDRA
ret

lcd_putchar:
	push	argument		;save the argmuent (it's destroyed in between)
	in	temp, DDRC		;get data direction bits
	sbr	temp, 0b11110000	;set the data lines to output
	out	DDRC, temp		;write value to DDRA
	in	temp, PortC		;then get the data from PortA
	cbr	temp, 0b11111110	;clear ALL LCD lines (data and control!)
	cbr	argument, 0b00001111	;we have to write the high nibble of our argument first
					;so mask off the low nibble
	or	temp, argument		;now set the argument bits in the Port value
	out	PortC, temp		;and write the port value
	sbi	PortC, LCD_RS		;now take RS high for LCD char data register access
	sbi	PortC, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortC, LCD_E
	pop	argument		;restore the argument, we need the low nibble now...
	cbr	temp, 0b11110000	;clear the data bits of our port value
	swap	argument		;we want to write the LOW nibble of the argument to
					;the LCD data lines, which are the HIGH port nibble!
	cbr	argument, 0b00001111	;clear unused bits in argument
	or	temp, argument		;and set the required argument bits in the port value
	out	PortC, temp		;write data to port
	sbi	PortC, LCD_RS		;again, set RS
	sbi	PortC, LCD_E		;strobe Enable
	nop
	nop
	nop
	cbi	PortC, LCD_E
	cbi	PortC, LCD_RS
	in	temp, DDRC
	cbr	temp, 0b11110000	;data lines are input again
	out	DDRC, temp
ret

lcd_command:	;same as LCD_putchar, but with RS low!
	push	argument
	in	temp, DDRC
	sbr	temp, 0b11110000
	out	DDRC, temp
	in	temp, PortC
	cbr	temp, 0b11111110
	cbr	argument, 0b00001111
	or	temp, argument

	out	PortC, temp
	sbi	PortC, LCD_E
	nop
	nop
	nop
	cbi	PortC, LCD_E
	pop	argument
	cbr	temp, 0b11110000
	swap	argument
	cbr	argument, 0b00001111
	or	temp, argument
	out	PortC, temp
	sbi	PortC, LCD_E
	nop
	nop
	nop
	cbi	PortC, LCD_E
	in	temp, DDRC
	cbr	temp, 0b11110000
	out	DDRC, temp
ret

LCD_getchar:
	in	temp, DDRC		;make sure the data lines are inputs
	andi	temp, 0b00001111	;so clear their DDR bits
	out	DDRC, temp
	sbi	PortC, LCD_RS		;we want to access the char data register, so RS high
	sbi	PortC, LCD_RW		;we also want to read from the LCD -> RW high
	sbi	PortC, LCD_E		;while E is high
	nop
	in	temp, PinC		;we need to fetch the HIGH nibble
	andi	temp, 0b11110000	;mask off the control line data
	mov	return, temp		;and copy the HIGH nibble to return
	cbi	PortC, LCD_E		;now take E low again
	nop				;wait a bit before strobing E again
	nop	
	sbi	PortC, LCD_E		;same as above, now we're reading the low nibble
	nop
	in	temp, PinC		;get the data
	andi	temp, 0b11110000	;and again mask off the control line bits
	swap	temp			;temp HIGH nibble contains data LOW nibble! so swap
	or	return, temp		;and combine with previously read high nibble
	cbi	PortC, LCD_E		;take all control lines low again
	cbi	PortC, LCD_RS
	cbi	PortC, LCD_RW
ret					;the character read from the LCD is now in return

LCD_getaddr:	;works just like LCD_getchar, but with RS low, return.7 is the busy flag
	in	temp, DDRC
	andi	temp, 0b00001111
	out	DDRC, temp
	cbi	PortC, LCD_RS
	sbi	PortC, LCD_RW
	sbi	PortC, LCD_E
	nop
	in	temp, PinC
	andi	temp, 0b11110000
	mov	return, temp
	cbi	PortC, LCD_E
	nop
	nop
	sbi	PortC, LCD_E
	nop
	in	temp, PinC
	andi	temp, 0b11110000
	swap	temp
	or	return, temp
	cbi	PortC, LCD_E
	cbi	PortC, LCD_RW
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

LCD_clear:
	rcall	LCD_wait
	ldi	argument, 0x01		;clear display, cursor -> home
	rcall	LCD_command
ret

LCD_init:
	
	ldi	temp, 0b00001110	;control lines are output, rest is input
	out	DDRC, temp
	
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