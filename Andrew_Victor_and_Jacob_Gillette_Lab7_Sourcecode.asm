;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab7_Sourcecode
;*
;*	This program uses four buttons on the board to represent four different types of behavior. 
;*	The functions that will be used in this program are SpeedUp, SpeedDown, SpeedMax, and SpeedMin.
;*	Each function will generate different behavior on the LED's of the board. 
;*
;***********************************************************
;*
;*	 Author: Andrew Victor and Jacob Gillette
;*	   Date: February 18th, 2020 
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16								; Multipurpose register
.def	waitcnt = r17							; Wait loop counter
.def	ilcnt = r18								; Inner loop counter
.def	olcnt = r19								; Outer loop counter 
.def	LED = r20								; Register to turn on/off LED's 

.equ	WTime = 20								; Time to wait after button press, 0.2 seconds 

.equ	LED0 = 0								; Bit representation of LED 0
.equ	LED1 = 1								; Bit representation of LED 1
.equ	LED2 = 2								; Bit representation of LED 2
.equ	LED3 = 3								; Bit representation of LED 3
.equ	LED4 = 4								; Bit representation of LED 4
.equ	LED5 = 5								; Bit representation of LED 5
.equ	LED6 = 6								; Bit representation of LED 6
.equ	LED7 = 7								; Bit representation of LED 7
.equ	EngEnR = 4								; right Engine Enable Bit
.equ	EngEnL = 7								; left Engine Enable Bit
.equ	EngDirR = 5								; right Engine Direction Bit
.equ	EngDirL = 6								; left Engine Direction Bit
.equ	MovFwd = (1<<EngDirR|1<<EngDirL)		; Move forward command 
.equ	ChangeSpeed = 17						; Used to increment/decrement speed per button push 

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		RJMP	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed
.org	$0002					; INT0 Interrupt Vector
		RCALL	SpeedUp			; Call SpeedUp function 
		RETI					; Return from interrupt 

.org	$0004					; INT1 Interrupt Vector 
		RCALL	SpeedDown		; Call SpeedDown function 
		RETI					; Return from interrupt 

.org	$0006					; INT2 Interrupt Vector 
		RCALL	SpeedMax		; Call SpeedMax function 
		RETI					; Return from interrupt 

.org	$0008					; INT3 Interrupt Vector
		RCALL	SpeedMin		; Call  SpeedMin function 
		RETI					; Return from interrupt 

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		LDI		mpr, LOW(RAMEND)
		OUT		SPL, mpr			; Load SPL with the low byte of RAMEND 
		LDI		mpr, HIGH(RAMEND) 
		OUT		SPH, mpr			; Load SPH with high byte of RAMEND
		
		; Configure I/O ports
		; Initialize Port D for input (Referenced from Lab1 Sourcecode)  
		LDI		mpr, 0b11110000		; ; Initialize 7:4 to output, 3:0 for input
		OUT		DDRD, mpr			; Use DDRD for input    
		LDI		mpr, 0b00001111		; Initialize 7:4 with no pull-up resistors, 3:0 with pull-up resistors
		OUT		PORTD, mpr			; Set Port D inputs to Tri-State

		; Initialize Port B for output (Referenced from Lab1 Sourcecode)
		LDI		mpr, 0b11111111		; Set all LED's on DDR to be outputs 
		OUT		DDRB, mpr			; Use DDRB for output 
		LDI		mpr, MovFwd			; Load Move Forward command 
		OUT		PORTB, mpr			; Send command to Port B 
		
		; Configure External Interrupts, if needed
		; Set the Interrupt Sense Control to falling edge (Referenced from ECE375 Textbook)
		LDI		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC21)|(0<<ISC20)|(1<<ISC31)|(0<<ISC30) 
		STS		EICRA, mpr			; Set INT0, INT1, INT2, & INT3 to trigger on falling edge 

		; Configure the External Interrupt Mask (Referenced from ECE375 Textbook)
		LDI		mpr, (1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3) 
		OUT		EIMSK, mpr			; Mask all interrupts except for INT0-INT3
		
		; Configure 8-bit Timer/Counters
		; Configure Timer/Counter0
		LDI		mpr, 0b01101001		; Fast PWM mode with toggle 
		OUT		TCCR0, mpr			; Non-inverting, NO prescale
		LDI		mpr, 255			; Load 255 into mpr 
		OUT		OCR0, mpr			; Give 255 to OCR0 (start at max duty cycle) 

		; Configure Timer/Counter2
		LDI		mpr, 0b01101001		; Fast PWM mode with toggle 
		OUT		TCCR2, mpr			; Non-inverting, NO prescale
		LDI		mpr, 255			; Load 255 into mpr 
		OUT		OCR2, mpr			; Give 255 to OCR2 (start at max duty cycle) 

		; Load initial speed into LED register
		LDI		LED, (1<<LED6)|(1<<LED5)|(0<<LED3)|(0<<LED2)|(0<<LED1)|(0<<LED0)		; Set LED's

		LDI		waitcnt, WTime		; Load WTime into waitcnt register 

		; Set up register for incrementing/decremeting speed 
		LDI		r21, ChangeSpeed

		; Enable global interrupts (if any are used)
		SEI							; Enable interrupts 

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)

								; if pressed, adjust speed
								; also, adjust speed indication
	
		RJMP	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SpeedUp:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack
		RCALL	Wait					; Execute wait function after button press
		IN		mpr, OCR0				; Read OCR0
		CPI		mpr, 0					; Check if min value has been reached for PWM duty cycle
		BREQ	SkipSub
		SUB		mpr, r21				; Decrement PWM by 17 
		OUT		OCR0, mpr				; Write MPR back to OCR0
		OUT		OCR2, mpr				; Write MPR back to OCR2 
		INC		LED						; Increment LED's
		OUT		PORTB, LED				; Write back to PortB
		LDI		mpr, 0b00001111			; Load MPR with 1's to clear interrupts 0-3
		OUT		EIFR, mpr				; Send MPR to EIFR to clear interrupts 
		SkipSub:						; Just clear EIFR because maximum OCR0 value has been reached 
			LDI		mpr, 0b00001111		; Load MPR with 1's to clear interrupts 0-3
			OUT		EIFR, mpr			; Send MPR to EIFR to clear interrupts 

		ret								; End a function with RET
			
;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SpeedDown:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack
		RCALL	Wait					; Execute wait function after button press
		IN		mpr, OCR0				; Read OCR0
		CPI		mpr, 255				; Check if max value has been reached for PWM duty cycle 
		BREQ	SkipAdd				
		ADD		mpr, r21				; Increment by 17
		OUT		OCR0, mpr				; Write back to OCR0
		OUT		OCR2, mpr				; Write back to OCR2
		DEC		LED						; Decrement LED's 
		OUT		PORTB, LED				; Write back to PortB
		LDI		mpr, 0b00001111			; Load MPR with 1's to clear interrupts 0-3
		OUT		EIFR, mpr				; Send MPR to EIFR to clear interrupts 
		SkipAdd:						; Just clear EIFR because minimum OCR0 value has been reached 
			LDI		mpr, 0b00001111		; Load MPR with 1's to clear interrupts 0-3
			OUT		EIFR, mpr			; Send MPR to EIFR to clear interrupts 
		ret								; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SpeedMax:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack
		RCALL	Wait				; Execute wait function after button press 
		IN		mpr, OCR0			; Read OCR0 into MPR 
		LDI		mpr, 0				; Write the min value to mpr (0% duty cycle)
		OUT		OCR0, mpr			; Write mpr back to OCR0
		OUT		OCR2, mpr			; Write mpr back to OCR2 
		LDI		LED, (1<<LED6)|(1<<LED5)|(1<<LED3)|(1<<LED2)|(1<<LED1)|(1<<LED0)	; Write LED's to display max speed 
		OUT		PORTB, LED			; Write output to PORT B
		LDI		mpr, 0b00001111		; Load MPR with 1's to clear interrupts 0-3
		OUT		EIFR, mpr			; Send MPR to EIFR to clear interrupts 
		ret							; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SpeedMin:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack 
		RCALL	Wait				; Execute wait function after button press		
		IN		mpr, OCR0			; Read OCR0 intio MPR
		LDI		mpr, 255			; Load the max value into MPR (100% duty cycle) 
		OUT		OCR0, mpr			; Write MPR back to OCR0
		OUT		OCR2, mpr			; Write MPR back to OCR2
		LDI		LED, (1<<LED5)|(1<<LED6)|(0<<LED3)|(0<<LED2)|(0<<LED1)|(0<<LED0)	; Write the LED's to display min speed
		OUT		PORTB, LED			; Write output to PORT B
		LDI		mpr, 0b00001111		; Load MPR with 1's to clear interrupts 0-3
		OUT		EIFR, mpr			; Send MPR to EIFR to clear interrupts 
		ret							; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait (Referenced from Lab1 Sourcecode) 
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register
		ret						; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program