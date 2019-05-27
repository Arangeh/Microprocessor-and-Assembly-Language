/*
 * AssemblerHW3Q2.asm
 *
 *  Created: 3/19/2019 11:03:20 PM
 *   Author: Alireza
 */ 

;Array 1
.def ADRH1 = r21;low byte of address to be written on EEARL
.def ADRL1 = r20;high byte of address to be written on EEARH

;Array 2
.def ADRH2 = r23;low byte of address to be written on EEARL
.def ADRL2 = r22;high byte of address to be written on EEARH

.def loopCNT = r19;


.def temp1 = r17
.def data = r25;data to be placed on EEPROM

.org 0x00
jmp reset_isr

reset_isr:
    ;clr temp1

    ;The return value of R16 which is either 0 or 1, will be transfered to portB
	ldi temp1, 0xFF
    clr data
	;out ddrB, temp1
    
jmp main


main:
	LDI ADRL1, 0x60 
	CLR ADRH1
	CLR loopCNT
	LDI ADRL2, 0x80
	CLR ADRH2
	
	CALL write_arr1
	
	clr loopCNT
	
	;clearing register 'data' causes the content of these 2 arrays to be equal
	;comment the following line in order for 2 arrays to have different content

	clr data
	
	CALL write_arr2
	
	CALL init_read
	jmp compare_arrays
	jmp loop
				
write_ARR1:
	SBIC EECR, EEWE
	JMP write_ARR1
	OUT EEARL, ADRL1;
	OUT EEARH, ADRH1 ;
	OUT EEDR, data ;
	SBI EECR, EEMWE
	SBI EECR, EEWE
	INC data
	INC ADRL1
	INC loopCNT
	CPI loopCNT,10
	BRNE write_ARR1
	RET;RJMP EEWrite_ARR2

write_ARR2:
	SBIC EECR, EEWE
	JMP write_ARR2
	OUT EEARL, ADRL2;
	OUT EEARH, ADRH2 ;
	OUT EEDR, data ;
	SBI EECR, EEMWE
	SBI EECR, EEWE
	INC data
	INC ADRL2
	INC loopCNT
	CPI loopCNT,10
	BRNE write_ARR2
	RET;RJMP EEWrite_ARR2


init_read:
	LDI ADRL1, 0x60
	CLR ADRH1
	LDI ADRL2, 0x80
	CLR ADRH2
	CLR loopCNT	 
	RET
	
compare_arrays:
	SBIC EECR, EEWE
	JMP compare_arrays
	OUT EEARL,ADRL1
	OUT EEARH,ADRH1
	SBI EECR,EERE
	IN r28,EEDR ; res arr1
	
	OUT EEARL,ADRL2
	OUT EEARH,ADRH2
	SBI EECR,EERE
	IN R27,EEDR ; res arr2

	cpse r27,r28
	jmp l0

	inc ADRL1
	inc ADRL2

	INC loopCNT 
	cpi loopCNT,10
	brne compare_arrays
	jmp l1
	
l0:
	LDI R16,0
	;SBI portB, 0x00
	jmp loop
	
l1:
	LDI R16,1
	;SBI portB, 0x01
	jmp loop
LOOP: 
JMP LOOP		