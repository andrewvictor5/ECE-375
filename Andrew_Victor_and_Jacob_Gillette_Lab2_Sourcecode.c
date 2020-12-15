 /*
 * Andrew_Victor_and_Jacob_Gillette_Lab2_Sourcecode.c
 *
 * Created: 1/14/2020 1:23:04 PM
 * Author : Andrew Victor and Jacob Gillette
 */
 
 /*
 This code will cause a TekBot connected to the AVR board to
 move forward and when it touches an obstacle, it will reverse
 and turn away from the obstacle and resume forward motion.

 PORT MAP
 Port B, Pin 4 -> Output -> Right Motor Enable
 Port B, Pin 5 -> Output -> Right Motor Direction
 Port B, Pin 7 -> Output -> Left Motor Enable
 Port B, Pin 6 -> Output -> Left Motor Direction
 Port D, Pin 1 -> Input -> Left Whisker
 Port D, Pin 0 -> Input -> Right Whisker
 */

 #define F_CPU 16000000
 #include <avr/io.h>
 #include <util/delay.h>
 #include <stdio.h>

 int main(void)
 {
	 DDRB = 0b11111111;		//Set DDRB as outputs
	 PORTB = 0b11110000;	//Set initial value for PORTB outputs
	 DDRD = 0b00000000;		//Set DDRD as inputs 
	 PIND = 0b11111111;		//Set initial value for PIND inputs 

	 while (1) // loop forever
	 {
		 PORTB = 0b01100000;		//Move forward 
		 if(PIND == 0b11111101) {	//Conditional for left whisker 
			PORTB = 0b00000000;		//Move backwards 
			_delay_ms(1000);		//Delay for one second
			PORTB = 0b01000000;		//Turn right 
			_delay_ms(1000);		//Delay for one second 
			PORTB = 0b01100000;		//Move forward once again  
		 }
		 if(PIND == 0b11111110) {	//Conditional for right whisker 
			PORTB = 0b00000000;		//Move backwards 
			_delay_ms(1000);		//Delay for one second 
			PORTB = 0b00100000;		//Turn left 
			_delay_ms(1000);		//Delay for one second 
			PORTB = 0b01100000;		//Move forward once again 
		 }
		 if(PIND == 0b11111100) {	//Conditional for both whiskers
			PORTB = 0b00000000;		//Move backwards
			 _delay_ms(1000);		//Delay for one second
			PORTB = 0b01000000;		//Turn right
			 _delay_ms(1000);		//Delay for one second
			PORTB = 0b01100000;		//Move forward once again
		 }
	 }
 }