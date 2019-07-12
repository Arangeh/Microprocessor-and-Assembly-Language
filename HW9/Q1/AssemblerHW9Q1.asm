/*
 * AssemblerHW9Q1.asm
 *
 *  Created: 5/31/2019 1:03:49 AM
 *   Author: Alireza
 */ 

.def BytetoWrite = r20
.def BytetoRead = r21 
.org 0x000
jmp reset

reset:
ldi r16, 0xff
out DDRA, r16;PORT A is always an output port
out DDRB, r16;PORT B is always an output port
out DDRC, r16;PORT C is an output port in order to test

;setting low and high address bytes for reading

;setting low and high address bytes for writing
ldi r18, 0x00;low
ldi r17, 0x25;high
ldi BytetoWrite, 0x90


jmp main
;clock frequency = 8Mhz
main:


;ldi r18, 0x00;low
;ldi r17, 0x15;high
;call MemRead_EEPROM1


ldi r18, 0x00;low
ldi r17, 0x25;high
call MemWrite_SRAM1
;To test whether the write operation has done successfully or not

ldi r18, 0x00;low
ldi r17, 0x25;high
call MemRead_SRAM1
;if BytetoRead = BytetoWrite the write has done successfully. Otherwise we should forage for possible mistakes
out PORTC, BytetoRead
jmp loop


loop:

jmp loop 



;Write data to SRAM M48T02, with tWLWH = 120ns (Write Pulse Width), tDVWH = 60ns (Data Valid to End of Write),
; tWHDX = 5ns (Data Hold Time)
;Propagation delay of 74138 decoder: tpd (74ls138)=0ns.
MemWrite_SRAM1:
out PORTA, r18

andi r17, 0x3F;mask the corresponding address range
ori r17, (1 << PB6);Output is disabled because D0-7 are used as input ports here
out PORTB, r17
ldi r16, 0xFF;PORT D is used as an output port
out DDRD, r16
out PORTD, BytetoWrite

nop;1 nop = 125ns > 120ns = tWLWH
;It can be shown easily that tDVWH and tWHDX requirements will be met, too
sbi PORTB, PB7;Write port is set again because the writing process takes place at the rising edge of the Write port
nop
ret

;Read Data from Address 0500H, SRAM with tAVQV =200ns, Result in R0
;Propagation delay of 74138 decoder: tpd (74ls138)=0ns.
MemRead_SRAM1:
out PORTA, r18

andi r17, 0x3F;mask the corresponding address range
out PORTB, r17
sbi PORTB, PB7;Write port is set because we want to read
ldi r16, 0x00;PORT D is used as an input port
out DDRD, r16
nop
nop
nop
nop;4 nop = 4 * 125ns = 500ns > 387.5ns = tAVQV + 1.5 * 125 = 200 + 1.5 * 125
in BytetoRead, PIND
nop
ret

;Read Data from EPROM M27C64A with tAVQV=tACC=300ns (Access time); Result in BytetoRead
;Propagation delay of 74138 decoder: tpd (74ls138)=0ns.
MemRead_EEPROM1:

out PORTA, r18
andi r17, 0x1F;mask the corresponding address range
out PORTB, r17
ldi r16, 0x00;PORT D is used as an input port
out DDRD, r16
nop
nop
nop
nop;4 nop = 4 * 125ns = 500ns > 487.5ns = tAVQV + 1.5 * 125 = 300 + 1.5 * 125 
in BytetoRead, PIND
ret