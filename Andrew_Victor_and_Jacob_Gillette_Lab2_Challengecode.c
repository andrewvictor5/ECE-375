/*
 * Andrew_Victor_and_Jacob_Gillette_Lab2_Challengecode.c
 *
 * Created: 1/18/2020 1:23:04 PM
 * Author : Andrew Victor and Jacob Gillette
 */
 
 /*
 The Challenge Code will be a modification of the original C program that will
 enable the TekBot to attempt to "push" any objects that it encounters. 
 The pseudo-code for the "push" operation is as follows: 
 1. TekBot moves forward indefinitely until it hits an object
 2. TekBot continues forward for a short period of time after hitting the object
 3. TekBot backs up slightly 
 4. TekBot turns slightly toward the object
 5. TekBot returns to step 1
 */ 
 
 /*
 PORT MAP (Same as Source Code/Provided Skeleton Code) 
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
	DDRB = 0b11111111;				//Set DDRB as outputs
	PORTB = 0b11110000;				//Set initial value for PORTB outputs
	DDRD = 0b00000000;				//Set DDRD as inputs
	PIND = 0b11111111;				//Set initial value for PIND inputs
	
	while (1)						//loop forever 
	{
		PORTB = 0b01100000;			//Move forward until an interrupt occurs 
		
		if(PIND == 0b11111101) {	//Condition for left whisker 
			PORTB = 0b01100000;		//Continue moving forward
			_delay_ms(2000);		//Push for 2 seconds 
			PORTB = 0b00000000;		//Move backwards 
			_delay_ms(1000);		//Delay for one second 
			PORTB = 0b00100000;		//Turn left towards the object
			_delay_ms(1000);		//Delay for one second 
			PORTB = 0b01100000;		//Move forward once again 
		}
		if(PIND == 0b11111110) {	//Condition for right whisker
			PORTB = 0b01100000;		//Continue moving forward
			_delay_ms(2000);		//Push for 2 seconds
			PORTB = 0b00000000;		//Move backwards
			_delay_ms(1000);		//Delay for one second
			PORTB = 0b01000000;		//Turn right towards the object
			_delay_ms(1000);		//Delay for one second
			PORTB = 0b01100000;		//Move forward once again
		}
		if(PIND == 0b11111100) {	//Condition for both whiskers
			PORTB = 0b01100000;		//Continue moving forward indefinitely
			
		}
	}
} 
