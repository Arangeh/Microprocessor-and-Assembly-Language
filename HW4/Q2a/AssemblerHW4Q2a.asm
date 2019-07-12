/*
 * AssemblerHW4Q2a.asm
 *
 *  Created: 4/11/2019 5:07:48 PM
 *   Author: Alireza
 */ 

 RESET:
 ;THE FOLLOWING 3 LINES SET THE WDT TIMOUT TO BE 2.1 MS AT VCC = 5V
 LDI R16, 0X07
 OUT WDTCR, R16


 JMP MAIN
 MAIN:
 JMP MAIN