;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab4_Sourcecode.asm
;*
;*	This lab will use the LCD and its associated driver to move data from the program
;*	memory into the data memory and display the data as characters on the LCD
;*
;***********************************************************
;*
;*	 Author: Andrew Victor and Jacob Gillette
;*	   Date: January 26th, 2020
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:	; The initialization routine
	; Initialize Stack Pointer
		LDI		mpr, LOW(RAMEND)	; Load LOW end of RAM to MPR 
		OUT		SPL, mpr			; Set output of LOW end of MPR to SPL (stack pointer low)
		LDI		mpr, HIGH(RAMEND)	; Load HIGH end of RAM to MPR
		OUT		SPH, mpr			; Set output of HIGH end of MPR to SPH (stack pointer high) 
	
	; Initialize the LCD Display and clear initially
		RCALL	LCDInit				; Initialize LCD Display
		RCALL	LCDClr				; Clear both lines of the LCD to start
		
	; Initialize PORT D for Input (Referenced from Lab1 Sourcecode)
		LDI		mpr, $00			; Set PORT D DDR
		OUT		DDRD, mpr			; For Input 
		LDI		mpr, $FF			; Initialize PORT D DDR
		OUT		PORTD, mpr			; Set all PORT D inputs to Tri-State
		
		
	; NOTE that there is no RET or RJMP from INIT, this
	; is because the next instruction executed is the
	; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:								; The Main program
		; Display the strings on the LCD Display
		IN		mpr, PIND					; Get input from Port D 
		CPI		mpr, 0b11111110				; Check Button0 for input
		BRNE	NEXT						; Continue with next check 
		RCALL	LoadString1					; Call LoadString1 Function and print String1 to the 1st line of the LCD
		RCALL	LoadString2					; Call LoadString2 Function and print String2 to the 2nd line of the LCD
		RJMP	MAIN						; Jump back to MAIN
NEXT:	CPI		mpr, 0b11111101				; Check Button1 for input
		BRNE	NEXT2						; Continue with next check 
		RCALL	LoadString3					; Call LoadString3 Function and print String2 to the 1st line of the LCD
		RCALL	LoadString4					; Call LoadString4 Function and print String1 to the 2nd line of the LCD
		RJMP	MAIN						; Jump back to MAIN
NEXT2:	CPI		mpr, 0b01111111				; Check Button7 for input 
		BRNE	MAIN						; Continue back to MAIN
		RCALL	ClearScreen					; Call ClearScreen function to get rid of data on the LCD 
		RJMP	MAIN						; Jump back to MAIN 

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: LoadString1
; Desc: This function will load the first string from Program Memory to Data Memory and write it to the LCD 
;-----------------------------------------------------------
LoadString1:								; Begin a function with a label
		; Execute the function here
		LDI		ZL, LOW(STRING1_BEG<<1)		; Set Z pointer LOW bit to point to the beginning of String1 (shift is to account selecting for low/high byte)
		LDI		ZH, HIGH(STRING1_BEG<<1)	; Set Z pointer HIGH bit to point to the end of String1 (shift is to account selecting for low/high byte)
		LDI		XL, $00						; Load the LOW bit of X with the address of LCD line 1
		LDI		XH, $01						; Load the HIGH bit of X with the address of LCD line 1
		LDI		R17, 14						; Load 14 into R17 to be the iterator for the loop (14 = length of String1) 
		Loop:								; Iterate through the string to get all letters 
			TST		R17						; Test if R17 = 0
			BREQ	EXIT					; If R17 = 0, exit the loop
			LPM		mpr, Z+					; Load Z pointer to mpr with post increment to point to the next letter
			ST		X+, mpr					; Store mpr at X (LCD display) with post increment 
			DEC		R17						; Decrement iterator R17 
			RJMP	Loop					; Return to the top of the loop 
		Exit:								; Exit the loop 
		RCALL	LCDWrite					; Write to the LCD (String1 to Line1, String2 to Line2) 
		RET									; End a function with RET

;-----------------------------------------------------------
; Func: LoadString2
; Desc: This function will load the second string from Program Memory to Data Memory and write it to the LCD 
;-----------------------------------------------------------
LoadString2:								; Begin a function with a label		
		; Execute the function here
		LDI		ZL, LOW(STRING2_BEG<<1)		; Set Z pointer LOW bit to point to the beginning of String2 (shift is to account selecting for low/high byte)
		LDI		ZH, HIGH(STRING2_BEG<<1)	; Set Z pointer HIGH bit to point to the end of String2 (shift is to account selecting for low/high byte)
		LDI		XL, $10						; Load the LOW bit of X with the address of LCD line 2
		LDI		XH, $01						; Load the HIGH bit of X with the address of LCD line 2
		LDI		R18, 14						; Load 14 into R18 to be the iterator for the loop (14 = length of String2)
		Loop2:								; Iterate through the string to get all letters 
			TST		R18						; Test if R18 = 0
			BREQ	EXIT					; If R18 = 0, exit the loop
			LPM		mpr, Z+					; Load Z pointer to mpr with post increment to point to the next letter
			ST		X+, mpr					; Store mpr at X (LCD display) with post increment 
			DEC		R18						; Decrement iterator R18 
			RJMP	Loop2					; Return to the top of the loop 
		Exit2:								; Exit the loop 
		RCALL	LCDWrite					; Write to the LCD (String1 to Line1, String2 to Line2) 
		RET									; End a function with RET
;-----------------------------------------------------------
; Func: LoadString3
; Desc: This function will load the second string from Program Memory to Data Memory and write it to the LCD 
;-----------------------------------------------------------
LoadString3:								; Begin a function with a label
		; Execute the function here
		LDI		ZL, LOW(STRING2_BEG<<1)		; Set Z pointer LOW bit to point to the beginning of String2 (shift is to account selecting for low/high byte)
		LDI		ZH, HIGH(STRING2_BEG<<1)	; Set Z pointer HIGH bit to point to the end of String2 (shift is to account selecting for low/high byte)
		LDI		XL, $00						; Load the LOW bit of X with the address of LCD line 1
		LDI		XH, $01						; Load the HIGH bit of X with the address of LCD line 1
		LDI		R17, 14						; Load 14 into R17 to be the iterator for the loop (14 = length of String2)
		Loop3:								; Iterate through the string to get all letters 
			TST		R17						; Test if R17 = 0
			BREQ	EXIT					; If R17 = 0, exit the loop
			LPM		mpr, Z+					; Load Z pointer to mpr with post increment to point to the next letter
			ST		X+, mpr					; Store mpr at X (LCD display) with post increment 
			DEC		R17						; Decrement iterator R17 
			RJMP	Loop3					; Return to the top of the loop 
		Exit3:								; Exit the loop 
		; Restore variables by popping them from the stack,
		; in reverse order
		RCALL	LCDWrite					; Write to the LCD (String2 on Line1, String1 on Line2) 
		RET									; End a function with RET
;-----------------------------------------------------------
; Func: LoadString4
; Desc: This function will load the second string from Program Memory to Data Memory and write it to the LCD 
;-----------------------------------------------------------
LoadString4:								; Begin a function with a label
		; Execute the function here
		LDI		ZL, LOW(STRING1_BEG<<1)		; Set Z pointer LOW bit to point to the beginning of String1 (shift is to account selecting for low/high byte)
		LDI		ZH, HIGH(STRING1_BEG<<1)	; Set Z pointer HIGH bit to point to the end of String1 (shift is to account selecting for low/high byte)
		LDI		XL, $10						; Load the LOW bit of X with the address of LCD line 2
		LDI		XH, $01						; Load the HIGH bit of X with the address of LCD line 2
		LDI		R18, 14						; Load 14 into R18 to be the iterator for the loop (14 = length of String1)
		Loop4:								; Iterate through the string to get all letters 
			TST		R18						; Test if R18 = 0
			BREQ	EXIT					; If R18 = 0, exit the loop
			LPM		mpr, Z+					; Load Z pointer to mpr with post increment to point to the next letter
			ST		X+, mpr					; Store mpr at X (LCD display) with post increment 
			DEC		R18						; Decrement iterator R18 
			RJMP	Loop4					; Return to the top of the loop 
		Exit4:								; Exit the loop  
		RCALL	LCDWrite					; Write to the LCD (String1 to Line1, String2 to Line2) 
		RET									; End a function with RET
;-----------------------------------------------------------
; Func: ClearScreen
; Desc: This function will clear the LCD screen of any data  
;-----------------------------------------------------------
ClearScreen:								; Begin a function with a label 
		; Execute the function here 
		RCALL LCDClr						; Clear both lines of the LCD screen 
		RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING1_BEG:
.DB		"Andrew Victor_"		; Declaring data in Program Memory
STRING1_END:
STRING2_BEG:
.DB		"Jacob Gillette"		; Declaring data in Program Memory
STRING2_END: 

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

