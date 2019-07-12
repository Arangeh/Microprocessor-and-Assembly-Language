/*
 * AssemblerHW7Q1.asm
 *
 *  Created: 5/11/2019 7:09:09 PM
 *   Author: Alireza
 */ 

 .def input = r17
 .org 0x000
 jmp reset

 .org 0x02A
 reset:
 ;PA1, PB2 should be set as input
 cbi ddrb, pb2
 cbi ddra, pa1
 ;PD5 should be set as output
 sbi ddrd, pd5


 andi r16,~(1 << ACD);enable Analog Comparator module by clearing Analog Comparator Disable bit
 out ACSR, r16
 clr r16
 ;clearing ADEN and setting ACME will allow one of ADCs to appear as the negative input of comparator
 andi r16, ~(1 << ADEN);clear ADEN
 out ADCSRA, r16
 clr r16
 ori r16, (1 << ACME);set ACME
 out SFIOR, r16
 clr r16
 ori r16, (1 << MUX0)
 andi r16, ~(1 << MUX1) & ~(1 << MUX2)
 out ADMUX, r16


 jmp main

 main:
 ;polling method is adopted
 in input, ACSR
 sbrc input, ACO;don't turn on the LED if the voltage hasn't gone beyond the threshold
 cbi PORTD, PD5
 sbrs input, ACO;turn on the LED because the voltage has gone beyond the threshold
 sbi PORTD, PD5
 ;sbi portd, pd5
 jmp main