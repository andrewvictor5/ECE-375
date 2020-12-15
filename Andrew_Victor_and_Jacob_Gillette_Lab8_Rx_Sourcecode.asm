;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab8_Rx_Sourcecode.asm
;*
;*	This program will receive commands via USART and output the commands on the board
;*
;***********************************************************
;*
;*	 Author: Andrew Victor and Jacob Gillette
;*	   Date: February 29th, 2020 
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17			; Wait loop counter
.def	ilcnt = r18				; Inner loop counter
.def	olcnt = r19				; Outer loop counter
.def	last = r20				; Register to hold last command
.def	FreezeCount = r21		; Counter for number of freeze commands recieved

.equ	WTime = 100				; Time to wait in wait loop 
.equ	WTimeFreeze = 500		; Time to wait in freeze (5 seconds)

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = $21		; 8-bit robot address

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		RJMP 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
;- Right whisker
.org	$0002					; INT0 interrupt 
		RCALL	HitRight
		RETI	
;- Left whisker
.org	$0004					; INT1 interrupt 
		RCALL	HitLeft
		RETI
;- USART receive
.org	$003C					; USART1 Rx interrupt 
		RCALL	Receive
		RETI

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	LDI		mpr, LOW(RAMEND)
	OUT		SPL, mpr			; Load SPL with the low byte of RAMEND
	LDI		mpr, HIGH(RAMEND)
	OUT		SPH, mpr			; Load SPH with the high byte of RAMEND 
	;I/O Ports
	;Initialize Port B for output 
	LDI		mpr, $FF			; Set Port B DDR
	OUT		DDRB, mpr			; For output 
	LDI		mpr, $00			; Set Port B Data Register 
	OUT		PORTB, mpr			; So all outputs are low initially 
	;Initialize Port D for input 
	LDI		mpr, $00			; Set Port D DDR
	OUT		DDRD, mpr			; For input 
	LDI		mpr, $FF			; Set Port D Data Register 
	OUT		PORTD, mpr			; So inputs have pull-up resistors 
	;USART1
	LDI		mpr, (1<<U2X1)		; Enable double USART transmission speed 
	STS		UCSR1A, mpr			; Store UCSR1A in extended I/O space
	;Set baudrate at 2400bps
	LDI		mpr, HIGH(832)		; Load high byte of 832 (0x340)
	STS		UBRR1H, mpr			; Store UBRR1H in extended I/O space
	LDI		mpr, LOW(832)		; Load the low byte of 832 (0x340)
	STS		UBRR1L, mpr			; Store UBBR1L in extended I/O space
	;Enable receiver and enable receive interrupts
	LDI		mpr, (1<<RXCIE1)|(1<<RXEN1)|(0<<UCSZ12)|(1<<TXEN1) ; Enable receiver interrupt, receiver, UCSZ = 8 bits 
	STS		UCSR1B, mpr			; Store UCSR1B in extended I/O space
	;Set frame format: 8 data bits, 2 stop bits
	LDI		mpr, (0<<UMSEL1)|(0<<UPM11)|(0<<UPM10)|(1<<USBS1)|(1<<UCSZ11)|(1<<UCSz10)	; UMSEL = asynchronous, UPM = disabled, USBS = 2 stop bits, UCSZ = 8 bits
	STS		UCSR1C, mpr			; Store UCSR1C in extended I/O space
	;External Interrupts
	;Set the Interrupt Sense Control to falling edge detection
	LDI		mpr, (1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00)
	STS		EICRA, mpr			; Set INT1 & INT0 to trigger on falling edge
	;Set the External Interrupt Mask
	LDI		mpr, (1<<INT1)|(1<<INT0) 
	OUT		EIMSK, mpr			; Mask all interrupts except for INT0 & INT1
	;Other

	LDI		last, 0				; Initialize last command to nothing
	CLR		FreezeCount			; Clear register 
	LDI		FreezeCount, 0		; Initialize freeze count to zero

	; Last thing: enable global interrupts 
	SEI							; Enable interrupts 

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		;READ IN FROM PORT B AND WRITE BACK OUT AT END OF FUNCTION
		PUSH	mpr				; Save mpr register
		PUSH	waitcnt			; Save wait register
		IN		mpr, SREG		; Save program state
		PUSH	mpr				;

		; Move Backwards for a second
		LDI		mpr, MovBck		; Load Move Backward command
		OUT		PORTB, mpr		; Send command to port
		LDI		waitcnt, WTime	; Wait for 1 second
		RCALL	Wait			; Call wait function

		; Turn left for a second
		LDI		mpr, TurnL		; Load Turn Left Command
		OUT		PORTB, mpr		; Send command to port
		LDI		waitcnt, WTime	; Wait for 1 second
		RCALL	Wait			; Call wait function

		; Handle interrupts 
		IN		mpr, EIFR	
		SBR		mpr, (1<<WskrR)|(1<<WskrL)
		OUT		EIFR, mpr

		POP		mpr				; Restore program state
		OUT		SREG, mpr		;
		POP		waitcnt			; Restore wait register
		POP		mpr				; Restore mpr

		OUT		PORTB, last		; Return to last received command 

		RET						; Return from subroutine


;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		PUSH	mpr				; Save mpr register
		PUSH	waitcnt			; Save wait register
		IN		mpr, SREG		; Save program state
		PUSH	mpr				;

		; Move Backwards for a second
		LDI		mpr, MovBck		; Load Move Backward command
		OUT		PORTB, mpr		; Send command to port
		LDI		waitcnt, WTime	; Wait for 1 second
		RCALL	Wait			; Call wait function

		; Turn right for a second
		LDI		mpr, TurnR		; Load Turn Left Command
		OUT		PORTB, mpr		; Send command to port
		LDI		waitcnt, WTime	; Wait for 1 second
		RCALL	Wait			; Call wait function

		; Handle interrupts 
		IN		mpr, EIFR
		SBR		mpr, (1<<WskrR)|(1<<WskrL)
		OUT		EIFR, mpr

		POP		mpr				; Restore program state
		OUT		SREG, mpr		;
		POP		waitcnt			; Restore wait register
		POP		mpr				; Restore mpr
		
		OUT		PORTB, last		; Return to last received command 

		RET						; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
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
; Func: Receive
; Desc: This function will perform the necessary actions when a signal has been received from the transmitter 
;-----------------------------------------------------------
Receive: 
		PUSH	mpr				; Save mpr register
		PUSH	waitcnt			; Save wait register
		IN		mpr, SREG		; Save program state
		PUSH	mpr				;
		RJMP	FreezeCheck

FreezeCheck:
		LDS		mpr, UDR1		; Get data from the Receive Data Buffer
		CPI		mpr, 0b01010101	; Check to see if a Freeze command was received (from another receiver)
		BREQ	Freeze			; Continue to Freeze
		RJMP	AddressCheck	; Jump to see if the correct BotAddress was received

AddressCheck:
		;LDS		mpr, UDR1
		CPI		mpr, BotAddress	; Check to see if the correct BotAddress was received
		BREQ	ACTION			; Continue to next check 
		RJMP	EXIT
		
ACTION:
		LDS		mpr, UDR1		; Get data from the Receive Data Buffer 
		
		CPI		mpr, 0b10110000	; Check to see if MoveForward action code was received
		BRNE	CheckBack		; Continue to next check 
		LDI		last, MovFwd	; Load MoveForward command 
		OUT		PORTB, last		; Output MoveForward to Port B
		RJMP	EXIT


CheckBack:
		CPI		mpr, 0b10000000	; Check to see if the MoveBack action code was received 
		BRNE	CheckRight		; Jump to next check 
		LDI		last, MovBck	; Load MoveBack command 
		OUT		PORTB, last		; Output MoveBack to Port B 
		RJMP	EXIT

CheckRight:
		CPI		mpr, 0b10100000	; Check to see if TurnRight action code was received 
		BRNE	CheckLeft		; Jump to next check 
		LDI		last, TurnR		; Load TurnRight command 
		OUT		PORTB, last		; Output TurnRIght to Port B
		RJMP	EXIT

CheckLeft:
		CPI		mpr, 0b10010000	; Check to see if TurnLeft action code was received
		BRNE	CheckHalt		; Jump to next check 
		LDI		last, TurnL		; Load TurnLeft command 
		OUT		PORTB, last		; Output TurnLeft to Port B 
		RJMP	EXIT

CheckHalt:
		CPI		mpr, 0b11001000	; Check to see if Halt action code was received 
		BRNE	CheckFreeze		; Jump to next check 
		LDI		last, Halt		; Load Halt command
		OUT		PORTB, last		; Output Halt to Port B
		RJMP	EXIT

CheckFreeze:
		CPI		mpr, 0b11111000	; Check to see if Freeze action code was received 
		BRNE	EXIT			; maybe recieve if problems
		LDI		mpr, (0<<RXCIE1)|(0<<RXEN1)
		STS		UCSR1B, mpr							; 
		RJMP	SendFreeze		; Jump to SendFreeze
		RJMP	EXIT

EXIT:
		POP		mpr				; Restore program state
		OUT		SREG, mpr		;
		POP		waitcnt			; Restore wait register
		POP		mpr				; Restore mpr

		RET						; Return from subroutine

;-----------------------------------------------------------
; Func: Freeze
; Desc: This function will perform the necessary actions when the Freeze command has been received 
;-----------------------------------------------------------
Freeze:
		LDI		mpr, Halt		; Load mpr with halt code
		OUT		PORTB, mpr		; Send Halt out to portb
		INC		FreezeCount		; Increment Freeze count
		CPI		FreezeCount, 3	;If freeze has occured 3 times branch to freeze forever
		BREQ	FreezeForever
		CLI						; Disable global interrupts
		RCALL	Wait			; Wait for 5 seconds
		RCALL	Wait

		ldi		mpr, $FF		; Clear external interrupts by setting to 1
		OUT		EIFR, mpr
			
		SEI						; Re-enable gloabl interrupts  
		OUT		PORTB, last		; Output last command to port B
		RJMP	EXIT

;-----------------------------------------------------------
; Func: FreezeForever
; Desc: This function will freeze the receiver forever once the limit of 3 Freezes has been received 
;-----------------------------------------------------------
FreezeForever:
		LDI		mpr, Halt		; Load mpr with halt code
		OUT		PORTB, mpr		; Send Halt out to portb
		CLI
		RJMP	FreezeForever
;-----------------------------------------------------------
; Func: SendFreeze
; Desc: This function will send the Freeze command to other receivers in the area 
;-----------------------------------------------------------
SendFreeze:
		;change to transmitter mode
		;send freeze command alone
		;change back to reciever
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty 
		RJMP	SendFreeze			; 
		LDI		mpr, 0b01010101		; Load mpr with the SendFreeze action code 
		STS		UDR1, mpr			; Store SendFreeze in data space for the Transmit Data Buffer
		RCALL	Wait	
		LDI		mpr, (1<<RXCIE1)|(1<<RXEN1)
		STS		UCSR1B, mpr		
		RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
