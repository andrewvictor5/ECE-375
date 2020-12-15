;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab6_Sourcecode
;*
;*	This program Is nearly identical to the BumpBot code from Lab 1
;*	Except this time we have implemented external interrupts and the 
;*	LCD screen to display values of each count iterator. 
;*
;***********************************************************
;*
;*	 Author: Andrew Victor and Jacob Gillette
;*	   Date: February 11th, 2020
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r23			; Wait loop counter
.def	ilcnt = r24				; Inner loop counter
.def	olcnt = r25				; Outer loop counter 
.def	temp = r15				; Temp register used to clear interrupt queue 
.def	rcount = r1				; Register to hold right count
.def	lcount = r2				; Register to hold left count

.equ	WTime = 100				; Time to wait in wait loop

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	clearR = 2
.equ	clearL = 3
.equ	EngEnR = 4				; Right Engine Enable Bit 
.equ	EngEnL = 7				; Left Engine Enable Bit 
.equ	EngDirR = 5				; Right Engine Direction Bit 
.equ	EngDirL = 6				; Left Engine Direction Bit 

; Macro values that make the TekBot move (Referenced from Lab1 Sourcecode) 
.equ	MovFwd = (1<<EngDirR|1<<EngDirL)		; Move forward command 
.equ	MovBck = $00							; Move Backward command 
.equ	TurnR = (1<<EngDirL)					; Turn right command 
.equ	TurnL = (1<<EngDirR)					; Turn left command 
.equ	Halt = (1<<EngEnR|1<<EngEnL)			; Halt command 

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

.org	$0002					; INTO Interrupt Vector
		RCALL	HitRight		; Call function HitRight to handle interrupt 
		RETI					; Return from interrupt 

.org	$0004					; INT1 Interrupt Vector 
		RCALL	HitLeft			; Call function HitLeft to handle interrupt 
		RETI					; Return from interrupt 

.org	$0006					; INT2 Interrupt Vector	
		RCALL	ClearRightCount	; Call function ClearRight to handle interrupt 
		RETI					; Return from interrupt 

.org	$0008					; INT3 Interrupt vector 
		RCALL	ClearLeftCount	; Call function ClearLeft to handle interrupt 
		RETI					; Return from interrupt 

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine

		; Initialize Stack Pointer (Referenced from Lab1 Sourcecode)
		LDI		mpr, LOW(RAMEND)
		OUT		SPL, mpr			; Load SPL with the low byte of RAMEND 
		LDI		mpr, HIGH(RAMEND) 
		OUT		SPH, mpr			; Load SPH with high byte of RAMEND
		
		; Initialize Port B for output (Referenced from Lab1 Sourcecode)
		LDI		mpr, $FF			; Set Port B DDR 
		OUT		DDRB, mpr			; Use DDRB for output 
		LDI		mpr, $00			; Initialize Port B Data Register
		OUT		PORTB, mpr			; Set Port B so all outputs are LOW 
		
		; Initialize Port D for input (Referenced from Lab1 Sourcecode)
		LDI		mpr, $00			; Set Port D DDR 
		OUT		DDRD, mpr			; Use DDRD for input 
		LDI		mpr, $FF			; Initialize Port D Data Register 
		OUT		PORTD, mpr			; Set Port D inputs to Tri-State

		; Initialize Forward Movement (Referenced from Lab1 Sourcecode) 
		;LDI		mpr, MovFwd			; Load move forward command 
		;OUT		PORTB, mpr			; Send command to motors 

		; Initialize the LCD Display 
		RCALL	LCDInit				; Initialize LCD Display

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge (Referenced from ECE375 Textbook)
		LDI		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC21)|(0<<ISC20)|(1<<ISC31)|(0<<ISC30) 
		STS		EICRA, mpr			; Set INT0, INT1, INT2, & INT3 to trigger on falling edge 

		; Configure the External Interrupt Mask (Referenced from ECE375 Textbook)
		LDI		mpr, (1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3) 
		OUT		EIMSK, mpr

		; Initialze TekBot forward movement 
		LDI		mpr, MovFwd			; Load Move Forward Command 
		OUT		PORTB, mpr			; Send command to motors 

		; Write ASCII value to the LCD
		CLR		lcount				; Initialize the left count variable to zero
		LDI		YL, $10				; Load the LOW byte of Y with the address of LCD line 2
		LDI		YH, $01				; Load the HIGH byte of Y with the address of LCD line 2
		MOV		mpr, lcount			; Move left count into mpr
		LDI		XL, low(left)		; Load low-byte X with low-byte of left variable (which is where the ascii conversion will be stored)
		LDI		XH, high(left)		; Load high-byte X with high-byte of left variable
		RCALL	Bin2ASCII			; Convert left-count to ascii value, will be stored at left which X points to
		LD		mpr, X				; Load X into mpr
		ST		Y+, mpr				; store mpr to Y (LCD)
		LD		mpr, X				; Load mpr with X
		ST		Y, mpr				; Store mpr to Y (LCD)

		; Write ASCII value to the LCD 
		RCALL	LCDWrLn2			; Write out left count to lcd line 2

		CLR		rcount				; Initialize right count variable to zero
		LDI		YL, $00				; Load the LOW byte of Y with the address of LCD line 1
		LDI		YH, $01				; Load the HIGH byte of Y with the address of LCD line 1
		MOV		mpr, rcount			; Move right count into mpr

		LDI		XL, low(right)		; Load low-byte X with low-byte of right variable (which is where the ascii conversion will be stored)
		LDI		XH, high(right)		; Load high-byte X with high-byte of right variable
		RCALL	Bin2ASCII			; Convert right-count to ascii value, will be stored at right which X points to
		LD		mpr, X				; Load X into mpr
		ST		Y+, mpr				; Store mpr to Y (LCD)
		LD		mpr, X				; load mpr with X
		ST		Y, mpr				; Store mpr to Y (LCD)
		;write ascii value to LCD
		RCALL	LCDWrLn1			; Write out right count to lcd line 1

		; Turn on interrupts
		; NOTE: This must be the last thing to do in the INIT function
		SEI						; Enable interrupt 

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		
		LDI		mpr, MovFwd		; Load move forward
		OUT		PORTB, mpr		; Send the PORT input to the motors
		RJMP	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;----------------------------------------------------------------
; Sub:	HitRight (Referenced from Lab1 Sourcecode) 
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		PUSH	mpr					; Save mpr register
		PUSH	waitcnt				; Save wait register
		IN		mpr, SREG			; Save program state
		PUSH	mpr				

		; Move Backwards for a second
		LDI		mpr, MovBck			; Load Move Backward command
		OUT		PORTB, mpr			; Send command to port
		LDI		waitcnt, WTime		; Wait for 1 second
		RCALL	WaitFunc			; Call wait function

		; Turn left for a second
		LDI		mpr, TurnL			; Load Turn Left Command
		OUT		PORTB, mpr			; Send command to port
		LDI		waitcnt, WTime		; Wait for 1 second
		RCALL	WaitFunc			; Call wait function

		IN		mpr, EIFR			; Load EIFR into mpr
		SBR		mpr, (1<<WskrR)|(1<<WskrL) ; Set bits based on which button was pressed 
		OUT		EIFR, mpr			; Load mpr back into EIFR 

		INC		rcount				; Increment the right counter
		LDI		YL, $00				; Load the LOW bit of Y with the address of LCD line 1
		LDI		YH, $01				; Load the HIGH bit of Y with the address of LCD line 1
		MOV		mpr, rcount			; Copy right count into mpr
		LDI		XL, low(right)		; Load low-byte of X with low-right
		LDI		XH, high(right)		; Load high-byte of X with high-right
		RCALL	Bin2ASCII			; Convert right count into ascci value
		LD		mpr, X+				; Load X into mpr, post increment X
		ST		Y+, mpr				; Store mpr into Y (LCD), post increment Y
		LD		mpr, X				; Load X into mpr
		ST		Y, mpr				; Store mpr into Y (LCD)
		;write ascii value to LCD
		RCALL LCDWrLn1				; Write LCD line 1

		; Move Forward again	
		LDI		mpr, MovFwd			; Load Move Forward command
		OUT		PORTB, mpr			; Send command to port
		POP		mpr					; Restore program state
		OUT		SREG, mpr			; 
		POP		waitcnt				; Restore wait register
		POP		mpr					; Restore mpr
		RET							; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft (Referenced from Lab1 Sourcecode) 
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		PUSH	mpr					; Save mpr register
		PUSH	waitcnt				; Save wait register
		IN		mpr, SREG			; Save program state
		PUSH	mpr		

		; Move Backwards for a second
		LDI		mpr, MovBck			; Load Move Backward command
		OUT		PORTB, mpr			; Send command to port
		LDI		waitcnt, WTime		; Wait for 1 second
		RCALL	WaitFunc			; Call wait function

		; Turn right for a second
		LDI		mpr, TurnR			; Load Turn Left Command
		OUT		PORTB, mpr			; Send command to port
		LDI		waitcnt, WTime		; Wait for 1 second
		RCALL	WaitFunc			; Call wait function

		IN		mpr, EIFR			; Load EIFR into mpr
		SBR		mpr, (1<<WskrR)|(1<<WskrL) ; Set bits based on which button was pressed 
		OUT		EIFR, mpr			; Load mpr back into EIFR 

		INC		lcount				; Increment the left counter
		LDI		YL, $10				; Load the LOW bit of Y with the address of LCD line 2
		LDI		YH, $01				; Load the HIGH bit of Y with the address of LCD line 2
		MOV		mpr, lcount			; Copy left count into mpr
		LDI		XL, low(left)		; Load low-byte of X with low-left
		LDI		XH, high(left)		; Load high-byte of X with high-left
		RCALL	Bin2ASCII			; Convert Left count into ascci value
		LD		mpr, X+				; Load X into mpr, post increment X
		ST		Y+, mpr				; Store mpr into Y (LCD), post increment Y
		LD		mpr, X				; Load X into mpr
		ST		Y, mpr				; Store mpr to Y (LCD)

		;write ascii value to LCD
		RCALL	LCDWrLn2			; Write LCD line 2

		; Move Forward again	
		LDI		mpr, MovFwd			; Load Move Forward command
		OUT		PORTB, mpr			; Send command to port
		POP		mpr					; Restore program state
		OUT		SREG, mpr			;
		POP		waitcnt				; Restore wait register
		POP		mpr					; Restore mpr
		RET							; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait (Referenced from Lab1 Sourcecode) 
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
WaitFunc:
		PUSH	waitcnt			; Save wait register
		PUSH	ilcnt			; Save ilcnt register
		PUSH	olcnt			; Save olcnt register

Loop:	LDI		olcnt, 224		; load olcnt register
OLoop:	LDI		ilcnt, 237		; load ilcnt register
ILoop:	DEC		ilcnt			; decrement ilcnt
		BRNE	ILoop			; Continue Inner Loop
		DEC		olcnt			; decrement olcnt
		BRNE	OLoop			; Continue Outer Loop
		DEC		waitcnt			; Decrement wait 
		BRNE	Loop			; Continue Wait loop	

		POP		olcnt			; Restore olcnt register
		POP		ilcnt			; Restore ilcnt register
		POP		waitcnt			; Restore wait register
		RET						; Return from subroutine

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
ClearRightCount:					; Begin a function with a label

		; Save variable by pushing them to the stack
		PUSH	mpr					; Save mpr register
		PUSH	waitcnt				; Save wait register
		IN		mpr, SREG			; Save program state
		PUSH	mpr					;

		; Execute the function here
		CLR		rcount				; Increment the right counter
		LDI		YL, $00				; Load the LOW bit of Y with the address of LCD line 1
		LDI		YH, $01				; Load the HIGH bit of Y with the address of LCD line 1
		MOV		mpr, rcount			; Copy right count into mpr
		LDI		XL, low(right)		; Load low-byte of X with low-right
		LDI		XH, high(right)		; Load high-byte of X with high-right
		RCALL	Bin2ASCII			; Convert right count into ascci value
		LD		mpr, X				; Load X into mpr
		ST		Y+, mpr				; Store mpr into Y (LCD), post increment Y
		LD		mpr, X				; Load X into mpr
		ST		Y, mpr				; Store mpr into Y (LCD)
		;write ascii value to LCD
		RCALL	LCDWrLn1			; Write LCD line 1
		
		; Restore variable by popping them from the stack in reverse order
		POP		mpr					; Restore program state
		OUT		SREG, mpr			;
		POP		waitcnt				; Restore wait register
		POP		mpr					; Restore mpr

		RET							; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
ClearLeftCount:						; Begin a function with a label

		; Save variable by pushing them to the stack
		PUSH	mpr					; Save mpr register
		PUSH	waitcnt				; Save wait register
		IN		mpr, SREG			; Save program state
		PUSH	mpr					;
		; Execute the function here
		CLR		lcount				; clear the left count
		LDI		YL, $10				; Load the LOW bit of Y with the address of LCD line 2
		LDI		YH, $01				; Load the HIGH bit of Y with the address of LCD line 2
		MOV		mpr, lcount			; Copy left count into mpr
		LDI		XL, low(left)		; Load low-byte of X with low-left
		LDI		XH, high(left)		; Load high-byte of X with high-left
		RCALL	Bin2ASCII			; Convert Left count into ascci value
		LD		mpr, X				; Load X into mpr
		ST		Y+, mpr				; Store mpr into Y (LCD), post increment Y
		LD		mpr, X				; Load X into mpr
		ST		Y, mpr				; Store mpr to Y (LCD)
		;write ascii value to LCD
		RCALL	LCDWrLn2			; Write LCD line 2
		
		; Restore variable by popping them from the stack in reverse order
		POP		mpr					; Restore program state
		OUT		SREG, mpr			;
		POP		waitcnt				; Restore wait register
		POP		mpr					; Restore mpr

		RET							; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

.dseg

.org $0300
right: .byte 2	; allocate two bytes for right memory space (result from ascii conversion)

.org $0400
left: .byte 2	; allocate two bytes for left memory space (result from ascii conversion)