;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab8_Tx_Sourcecode.asm
;*
;*	This program will transmit commands to the receiver via USART 
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
.def	mpr = r16										; Multi-Purpose Register
.def	PrevCommand = r17								; Register to hold the previous action code command that was sent 
.def	NextCommand = r18								; Register to hold the next action code command to be sent 

.equ	WskrR = 0										; Right whisker input bit
.equ	WskrL = 1										; Left whisker input bit 
.equ	EngEnR = 4										; Right Engine Enable Bit
.equ	EngEnL = 7										; Left Engine Enable Bit
.equ	EngDirR = 5										; Right Engine Direction Bit
.equ	EngDirL = 6										; Left Engine Direction Bit

;.equ	BotAddress = 0b01010101							; 8-bit robot address
.equ	BotAddress = $21								; CHANGE BEFORE CHECKOFF
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze =  0b11111000							; Freeze Attack action code 
.equ	Freeze2 = 0b01010101

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		RJMP 	INIT			; Reset interrupt

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
	LDI		mpr, 0b11110011		; Set Port D Data Register (pins 2-3 are reserved) 
	OUT		PORTD, mpr			; So inputs have pull-up resisters 
	;USART1
	LDI		mpr, (1<<U2X1)		; Enable double USART transmission speed 
	STS		UCSR1A, mpr			; Store UCSR1A in extended I/O space
	;Set baudrate at 2400bps
	LDI		mpr, HIGH(832)		; Load high byte of 832 (0x340)
	STS		UBRR1H, mpr			; Store UBBR1H in extended I/O space
	LDI		mpr, LOW(832)		; Load low byte of 832 (0x340)
	STS		UBRR1L, mpr			; Store UBBR1L in extended I/O space 
	;Enable transmitter
	LDI		mpr, (1<<TXEN1)|(0<<UCSZ12)		; Enable transmitter bit, UCSZ = 8 bits
	STS		UCSR1B, mpr			; Store UCSR1B in extended I/O space 
	;Set frame format: 8 data bits, 2 stop bits
	LDI		mpr, (0<<UMSEL1)|(0<<UPM11)|(0<<UPM10)|(1<<USBS1)|(1<<UCSZ11)|(1<<UCSz10)	; UMSEL = asynchronous, UPM = disabled, USBS = 2 stop bits, UCSZ = 8 bits
	STS		UCSR1C, mpr			; Store UCSR1C in extended I/O space

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		IN		mpr, PIND			; Receive input from Pin D 
		CPI		mpr, 0b11111110		; Check if Button0 was pressed
		BRNE	NEXT				; Continue with next check 
		RCALL	SendAddress			; Send the robot address to the receiver
		RCALL	SendFwd				; Send move forward command 
		RJMP	MAIN				; Jump back to MAIN for next input
NEXT:	CPI		mpr, 0b11111101		; Check if Button1 was pressed 
		BRNE	NEXT2				; Continue with next check
		RCALL	SendAddress			;  Send the robot address to the receiver
		RCALL	SendBack			; Send Move backward command 
		RJMP	MAIN				; Jump back to MAIN for next input 
NEXT2:	CPI		mpr, 0b11101111		; Check if Button4 was pressed 
		BRNE	NEXT3				; Continue with next check 
		RCALL	SendAddress			; Send the robot address to the receiver
		RCALL	SendRight			; Send Turn Right command 
		RJMP	MAIN				; Jump back to MAIN for next input 
NEXT3:	CPI		mpr, 0b11011111		; Check uf Button5 was pressed 
		BRNE	NEXT4				; Continue with next check 
		RCALL	SendAddress			; Send the robot address to the receiver
		RCALL	SendLeft			; Send Turn Left command
		RJMP	MAIN				; Jump back to MAIN for next input 
NEXT4:	CPI		mpr, 0b10111111		; Check if Button6 was pressed 
		BRNE	NEXT5				; Continue with next check 
		RCALL	SendAddress			; Send the robot address to the receiver
		RCALL	SendHalt			; Send Halt command 
		RJMP	MAIN				; Jump back to MAIN for next input 
NEXT5:	CPI		mpr, 0b01111111		; Check if Button7 was pressed 
		BRNE	MAIN				; Jump back to MAIN for next input 
		RCALL	SendAddress			; Send the robot address to theh receiver 
		RCALL	SendFreeze			; Send Freeze Attack command 
		RJMP	MAIN				; Jump back to MAIN for next input 

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: SendAddress
; Desc: This function will send the BotAddress to the receiver to make sure that the receiver is communicating to the correct transmitter
;-----------------------------------------------------------
SendAddress: 
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1 			; Loop until UDRE1 is empty
		RJMP	SendAddress			;
		LDI		mpr, BotAddress		; Load mpr with the BotAddress variable
		STS		UDR1, mpr			; Store BotAddress in data space for the Transmit Data Buffer
		RET 

;-----------------------------------------------------------
; Func: SendFwd
; Desc: This function will send the Move Forward command to the receiver 
;-----------------------------------------------------------
SendFwd:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendFwd				; 
		LDI		mpr, MovFwd			; Load mpr with the MovFwd action code
		STS		UDR1, mpr			; Store MovFwd in data space for the Transmit Data Buffer
		RET

;-----------------------------------------------------------
; Func: SendBack
; Desc: This function will send the Move Back command to the receiver 
;-----------------------------------------------------------
SendBack:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendBack			; 
		LDI		mpr, MovBck			; Load mpr with the MovBck action code 
		STS		UDR1, mpr			; Store MovBack in data space for the Transmit Data Buffer
		RET

;-----------------------------------------------------------
; Func: SendRight
; Desc: This function will send the Turn Right command to the receiver 
;-----------------------------------------------------------
SendRight:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendRight			; 
		LDI		mpr, TurnR			; Load mpr with the TurnRight action code 
		STS		UDR1, mpr			; Store TurnRight in data space for the Transmit Data Buffer
		RET

;-----------------------------------------------------------
; Func: SendLeft
; Desc: This function will send the Turn Left command to the receiver 
;-----------------------------------------------------------
SendLeft:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendLeft			; 
		LDI		mpr, TurnL			; Load mpr with the TurnLeft action code 
		STS		UDR1, mpr			; Store TurnLeft in data space for the Transmit Data Buffer
		RET

;-----------------------------------------------------------
; Func: SendHalt
; Desc: This function will send the Halt Command to the receiver
;-----------------------------------------------------------
SendHalt:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendHalt			; 
		LDI		mpr, Halt			; Load mpr with the Halt action code 
		STS		UDR1, mpr			; Store Halt in data space for the Transmit Data Buffer
		RET

;-----------------------------------------------------------
; Func: SendFreeze
; Desc: This function will send the Freeze Attack command to the receiver
;-----------------------------------------------------------
SendFreeze:
		LDS		mpr, UCSR1A			; Load mpr with UCSR1A from data space
		SBRS	mpr, UDRE1			; Loop until UDRE1 is empty
		RJMP	SendFreeze			; 
		LDI		mpr, Freeze			; Load mpr with the Freeze action code 
		STS		UDR1, mpr			; Store Freeze in data space for the Transmit Data Buffer
		RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************