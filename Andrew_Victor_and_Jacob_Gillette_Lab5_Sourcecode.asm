;***********************************************************
;*
;*	Andrew_Victor_and_Jacob_Gillette_Lab5_Sourcecode.asm
;*
;* Implemeted add and subtract functions which take two 16-bit inputs
;* Add produces a 24-bit output and sub produces a 16-bit output
;*
;*	Implemented multiply function which multiples two 24-bit numbers
;* and produces a 48-bit output
;***********************************************************
;*
;*	 Author: Andrew Victor and Jacob Gillette
;*	   Date: February 4th, 2020
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:								; The initialization routine
		; Initialize Stack Pointer
		LDI		mpr, LOW(RAMEND)	; Load LOW end of RAM to MPR
		OUT		SPL, mpr			; Set output of LOW end of MPR to SPL (stack pointer low)
		LDI		mpr, HIGH(RAMEND)	; Load the HIGH end of RAM to MPR
		OUT		SPH, mpr			; Set output of the HIGH end of MPR to SPH (stack pointer high) 

		CLR		zero				; Set the zero register to zero, maintain
									; these semantics, meaning, don't
									; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the ADD16 function direct test

		; Move values 0xFCBA and 0xFFFF in program memory to data memory
		; memory locations where ADD16 will get its inputs from
		; (see "Data Memory Allocation" section below)

		LDI		ZL, LOW(ADD16_P1<<1) ;store low-bit of operand one from program memory to Z low
		LDI		ZH,	HIGH(ADD16_P1<<1) ;store high-bit of operand one from program memory to Z high

		LDI		XL, low(ADD16_OP1)	; Load low byte of address
		LDI		XH, high(ADD16_OP1)	; Load high byte of address

		LPM		mpr, Z+ ;load low-bit of operand one to data memory
		ST		X+, mpr  ;store low-bit of operand one in X low

		LPM		mpr, Z ;load high-bit of operand one to data memory
		ST		X, mpr  ;store high-bit of operand one in X high

		LDI		ZL, LOW(ADD16_P2<<1) ;store low-bit of operand one from program memory to Z low
		LDI		ZH, HIGH(ADD16_P2<<1) ;store high-bit of operand one from program memory to Z high

		LDI		YL, low(ADD16_OP2)	; Load low byte of address
		LDI		YH, high(ADD16_OP2)	; Load high byte of address

		LPM		mpr, Z+ ;load low-bit of operand one to data memory
		ST		Y+, mpr  ;store low-bit of operand one in X low

		LPM		mpr, Z ;load high-bit of operand one to data memory
		ST		Y, mpr  ;store high-bit of operand one in X high

                nop ; Check load ADD16 operands (Set Break point here #1)  
		CALL	ADD16
		; Call ADD16 function to test its correctness
		; (calculate FCBA + FFFF)

                nop ; Check ADD16 result (Set Break point here #2)
		; Observe result in Memory window

		; Setup the SUB16 function direct test

		; Move values 0xFCB9 and 0xE420 in program memory to data memory
		; memory locations where SUB16 will get its inputs from
		LDI		ZL, LOW(SUB16_P1<<1) ;store low-bit of operand one from program memory to Z low
		LDI		ZH, HIGH(SUB16_P1<<1) ;store high-bit of operand one from program memory to Z high

		LDI		XL, low(SUB16_OP1)	; Load low byte of address
		LDI		XH, high(SUB16_OP1)	; Load high byte of address

		LPM		mpr, Z+ ;load low-bit of operand one to data memory
		ST		X+, mpr  ;store low-bit of operand one in X low

		LPM		mpr, Z ;load high-bit of operand one to data memory
		ST		X, mpr  ;store high-bit of operand one in X high

		LDI		ZL, LOW(SUB16_P2<<1) ;store low-bit of operand one from program memory to Z low
		LDI		ZH, HIGH(SUB16_P2<<1) ;store high-bit of operand one from program memory to Z high

		LDI		YL, low(SUB16_OP2)	; Load low byte of address
		LDI		YH, high(SUB16_OP2)	; Load high byte of address

		LPM		mpr, Z+	;load low-bit of operand one to data memory
		ST		Y+, mpr  ;store low-bit of operand one in X low

		LPM		mpr, Z ;load high-bit of operand one to data memory
		ST		Y, mpr  ;store high-bit of operand one in X high

                nop ; Check load SUB16 operands (Set Break point here #3)  
		; Call SUB16 function to test its correctness
		CALL	SUB16
		; (calculate FCB9 - E420)

                nop ; Check SUB16 result (Set Break point here #4)
		; Observe result in Memory window

		; Setup the MUL24 function direct test
		; Move values 0xFFFFFF and 0xFFFFFF in program memory to data memory  
		; memory locations where MUL24 will get its inputs from
		LDI		ZL, LOW(MUL24_P1<<1)	; Store the low bit of the first operand for MUL24 in ZL
		LDI		ZH,	HIGH(MUL24_P1<<1)	; Store the high bit of the first operand for MUL24 in ZH

		LDI		XL, LOW(MUL24_OP1)		; Load the low byte of the first MUL24 operand to X
		LDI		XH, HIGH(MUL24_OP1)		; Load the high byte of the first MUL24 operand to X

		LPM		mpr, Z					; Load the first bit of the first operand to data memory 
		ST		X+, mpr					; Store the first bit of the first operand in X 

		LPM		mpr, Z					; Load the second bit of the first operand to data memory 
		ST		X+, MPR					; Store the second bit of the first operand in X 

		LPM		mpr, Z					; Load the third bit of the first operand to data memory 
		ST		X, mpr					; Store the third bit of the first operand in X

		LDI		ZL, LOW(MUL24_P2<<1)	; Store the low bit of the second operand for MUL24 in ZL
		LDI		ZH, HIGH(MUL24_P2<<1)	; Store the high bit of the second operand for MUL24 in ZH

		LDI		YL, LOW(MUL24_OP2)		; Load the low byte of the second MUL24 operand to Y 
		LDI		YH, HIGH(MUL24_OP2)		; Load the high byte of the second MUL24 operand to Y 

		LPM		mpr, Z					; Load the first bit of the second operand to data memory 
		ST		Y+, mpr					; Store the first bit of the second operand in Y 

		LPM		mpr, Z					; Load the second bit of the second operand to data memory 
		ST		Y+, mpr					; Store the second bit of the second operand in Y 

		LPM		mpr, Z					; Load the third bit of the second operand to data memory 
		ST		Y, mpr					; Store the third bit of the second operand in Y 

                nop ; Check load MUL24 operands (Set Break point here #5)  
		;CALL	MUL24	; Call MUL24 function to test its correctness
						; (calculate FFFFFF * FFFFFF)

                nop ; Check MUL24 result (Set Break point here #6)
				; Observe result in Memory window
		LDI		ZL, LOW(OperandD<<1)	; Store the low bit of the D operand for Compound in ZL
		LDI		ZH, HIGH(OperandD<<1)	; Store the high bit of the D operand for Compund in ZH
	
		LDI		XL, LOW(ComOpD)			; Load the low bit of operand D to XL
		LDI		XH, HIGH(ComOpD)		; Load the HIGH bit of operand D to XH
	
		LPM		mpr, Z+					; Load the first bit of operand D to data memory 
		ST		X+, mpr					; Store the first bit of operand D to X 

		LPM		mpr, Z					; Load the second bit of operand D to data memory 
		ST		X, mpr					; Store the second bit of operand D to x 

		LDI		ZL, LOW(OperandE<<1)	; Store the low bit of the E operand for Compound in ZL
		LDI		ZH, HIGH(OperandE<<1)	; Store the high bit of the E operand for Compund in ZH

		LDI		XL, LOW(ComOpE)			; Load the low bit of operand E to XL
		LDI		XH, HIGH(ComOpE)		; Load the HIGH bit of operand E to XH

		LPM		mpr, Z+					; Load the first bit of operand E to data memory 
		ST		X+, mpr					; Store the first bit of operand E to X 

		LPM		mpr, Z					; Load the second bit of operand E to data memory 
		ST		X, mpr					; Store the second bit of operand E to x 

		LDI		ZL, LOW(OperandF<<1)	; Store the low bit of the F operand for Compound in ZL
		LDI		ZH, HIGH(OperandF<<1)	; Store the high bit of the F operand for Compund in ZH
	
		LDI		XL, LOW(ComOpF)			; Load the low bit of operand F to XL
		LDI		XH, HIGH(ComOpF)		; Load the HIGH bit of operand F to XH

		LPM		mpr, Z+					; Load the first bit of operand F to data memory 
		ST		X+, mpr					; Store the first bit of operand F to X 

		LPM		mpr, Z					; Load the second bit of operand F to data memory 
		ST		X, mpr					; Store the second bit of operand F to x 

                 nop ; Check load COMPOUND operands (Set Break point here #7)  

		CALL	COMPOUND
                nop ; Check COMPOUND result (Set Break point here #8)
				; Observe final result in Memory window

DONE:	RJMP	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		; Load beginning address of result into Z
		LDI		ZL, low(ADD16_Result)	; Load the low byte of the ADD16_Result address to ZL
		LDI		ZH, high(ADD16_Result)	; Load the high byte of the ADD16_Result address to ZH

		; Execute the function
		LD		R12, -X					; Load the low byte of the first ADD operand to R12
		LD		R13, -Y					; Load the low byte of the second ADD operand to R13
		ADD		R12, R13				; Add R13 to R12 without carry (low bytes)
		ST		Z+, R12					; Store the result of the low byte addition in Z+
		LD		R12, X+					; Load X to R12 with post increment 
		LD		R13, Y+					; Load Y to R13 with post increment 
		LD		R12, X					; Load the high byte of the first ADD operand to R12
		LD		R13, Y					; Load the high byte of the second ADD operand to R13
		ADC		R12, R13				; Add R13 to R12 with carry (high bytes) 
		ST		Z+, R12					; Store the result of the high byte addition in Z+
		BRCC	EXIT					; Condition for carry flag 
		ST		Z, XH					; Store the carry flag in Z 
		EXIT:
		RET								; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;		result.
;-----------------------------------------------------------
SUB16:
		; Load beginning address of first operand into X
		; Load beginning address of second operand into Y
		; Load beginning address of result into Z
		LDI		ZL, low(SUB16_Result)	; Load the low byte of the SUB16_Result to ZL
		LDI		ZH, high(SUB16_Result)	; Load the high byte of the SUB16_Result to ZH 

		; Execute the function
		LD		R12, -X					; Load the low byte of the first SUB operand to R12
		LD		R13, -Y					; Load the low byte of the second SUB operand to R13
		SUB		R12, R13				; Subtract R13 from R12 (low bytes) 
		ST		Z+, R12					; Store the result of the low byte subtraction in Z+
		LD		R12, X+					; Load X to R12 with post increment 
		LD		R13, Y+					; Load Y to R13 with post increment 
		LD		R12, X					; Load the high byte of the first SUB operand to R12
		LD		R13, Y					; Load the high byte of the second SUB operand to R13 
		SUB		R12, R13				; Subtract R13 from R12 (high bytes)	
		ST		Z+, R12					; Store the result of the high byte subtraction in Z+ 
		RET								; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Execute the function here
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(MUL24_OP1)	; Load low byte
		ldi		YH, high(MUL24_OP1)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MUL24_Result)	; Load low byte
		ldi		ZH, high(MUL24_Result)	; Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load outer counter to three
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(MUL24_OP2)	; Load low byte
		ldi		XH, high(MUL24_OP2)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load inner counter to three
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		RET						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((D - E) + F)^2
;		by making use of SUB16, ADD16, and MUL24.
;
;		D, E, and F are declared in program memory, and must
;		be moved into data memory for use as input operands.
;
;		All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:

		; Setup SUB16 with operands D and E
		; Perform subtraction to calculate D - E

		LDI		ZL, LOW(OperandD<<1) ;Load Z-low with low-byte of operand D
		LDI		ZH, HIGH(OperandD<<1) ;Load Z-high with high-bute of opernad D

		LDI		XL, LOW(SUB16_OP1) ;Load X-Low with the low-byte of subtract operand 1
		LDI		XH, HIGH(SUB16_OP1) ;Load X-high with the high-byte of subtract operand 1

		LPM		mpr, Z+ ;Load low byte of operand D into mpr, post increment Z
		ST		X+, mpr ;Store low byte of operand D into subtract operand 1, post increment X

		LPM		mpr, Z ;Load high byte of operand D into mpr
		ST		X, mpr ;store high byte of operand D into subtract operand 1

		LDI		ZL, LOW(OperandE<<1) ;Load Z-low with low-byte of operand E
		LDI		ZH, HIGH(OperandE<<1) ;Load Z-high with high-bute of opernad E

		LDI		YL, LOW(SUB16_OP2) ;Load Y-Low with the low-byte of subtract operand 2
		LDI		YH, HIGH(SUB16_OP2) ;Load Y-high with the high-byte of subtract operand 2

		LPM		mpr, Z+ ;Load low byte of operand E into mpr, post increment Z
		ST		Y+, mpr ;Store low byte of operand E into subtract operand 2, post increment Y

		LPM		mpr, Z ;Load high byte of operand E into mpr
		ST		Y, mpr ;store high byte of operand E into subtract operand 2

		CALL	SUB16
		
		LDI		ZL, LOW(SUB16_Result) ;Load Z-low with low byte of subtraction result
		LDI		ZH, HIGH(SUB16_Result) ;Load Z-high with high byte of subtraction result

		LD			mpr, Z+ ;Load low-byte of sub result into mpr, post increment Z
		ST			X+, mpr ;Store low-byte of sub result into low-byte of addOP1, post increment X

		LD			mpr, Z ;Load high-byte of sub result into mpr
		ST			X, mpr ;Store high-byte of sub result into high-byte of addOP1

		LDI		ZL, LOW(OperandF<<1) ;Load Z-low with low byte of operand F
		LDI		ZH, HIGH(OperandF<<1) ;Load Z-high with high byte of operand F

		LPM		mpr, Z+ ;Load low-byte of operand F into mpr, post increment Z
		ST		Y+,	mpr ;Store low-byte of operand F into low-byte of addOP2, post increment Y-low

		LPM		mpr, Z ;Load high-bute of operand F into mpr
		ST		Y, mpr	;Store high-byte of operand F into high-byte of addOP2

		; Setup the ADD16 function with SUB16 result and operand F
		; Perform addition next to calculate (D - E) + F
		CALL	ADD16

		LDI ZL, LOW(ADD16_Result) ;Load Z-low with low-byte of add16 result
		LDI ZH, HIGH(ADD16_Result) ;Load Z-high with high-byte of add16 result

		LDI XL, LOW(MUL24_OP1) ;Load X-low with low-byte of mul24 OP1
		LDI XH, HIGH(MUL24_OP1) ;Load X-high with high-byte of mul24 OP1

		LDI YL, LOW(MUL24_OP2) ;Load Y-low with low-byte of mul24 OP2
		LDI YH, HIGH(MUL24_OP2) ;Load Y-high with high-byte of mul24 OP2

		LD mpr, Z+ ;Load mpr with low-byte of add16 result
		ST X+, mpr ;store low-byte of add16 result in X, post increment X
		ST Y+, mpr ;store low-byte of add16 result in Y, post increment Y

		LD mpr, Z+ ;Load mpr with middle-byte of add16 result
		ST X+, mpr ;store middle-byte of add16 result in X, post increment X
		ST Y+, mpr ;Store middle-byte of add16 result in Y, Post increment Y

		LD mpr, Z ;Load mpr with high-bute of add16 result
		ST X, mpr ;store high-byte of add16 result in X
		ST Y, mpr ;store high-byte of add16 result in Y

		; Setup the MUL24 function with ADD16 result as both operands
		; Perform multiplication to calculate ((D - E) + F)^2

		CALL MUL24

		LDI ZL, LOW(ComResult) ;Load Z-low with low-byte of compound result
		LDI ZH, HIGH(ComResult) ;Load Z-high with high-byte of compound result

		LDI XL, LOW(MUL24_Result) ;Load X-low with low byte of mul24 result
		LDI XH, HIGH(MUL24_Result) ;load X-high with high byte of mul24 result

		LD mpr, X+ ;The rest of the function here down stores the mul24 result from
		ST Z+, mpr ; X into Z using mpr as the intermindete register
				   ; Since the result is 6 bytes, the code is repeated 6 times
		LD mpr, X+ ;while post incrementing X and Z to point to the next byte when appropriate
		ST Z+, mpr
		
		LD mpr, X+
		ST Z+, mpr
		
		LD mpr, X+
		ST Z+, mpr

		LD mpr, X+
		ST Z+, mpr
		
		LD mpr, X
		ST Z, mpr

		RET						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************


; ADD16 operands - Move values 0xFCBA and 0xFFFF in program memory to data memory
ADD16_P1:
	.DW 0xFCBA
ADD16_P2:
	.DW 0xFFFF
; SUB16 operands - Move values 0xFCB9 and 0xE420 in program memory to data memory
SUB16_P1:
	.DW 0xFCB9
SUB16_P2:
	.DW 0xE420

; MUL24 operands - Move values 0xFFFFFF and 0xFFFFFF in program memory to data memory 
MUL24_P1:
	.DW 0xFFFFFF
MUL24_P2:
	.DW 0xFFFFFF

; Compoud operands
OperandD:
	.DW	0xFCBA				; test value for operand D
OperandE:
	.DW	0x2019				; test value for operand E
OperandF:
	.DW	0x21BB				; test value for operand F

;***********************************************************
;*	Data Memory Allocation
;***********************************************************

.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.

.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

; data memory allocation for SUB16
.org	$0130				; data memory allocation for operands 
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for the second operand of SUB16

.org	$0140				; data memory allocation for result
SUB16_Result:
		.byte 2				; allocate two bytes for the result of SUB16

; data memory allocation for MUL24 
.org	$0150				; data memory allocation for operands 
MUL24_OP1: 
		.byte 3				; allocate three bytes for the first operand of MUL24 
MUL24_OP2: 
		.byte 3				; allocate three bytes for the second operand of MUL24

.org	$0160				; data memory allocation for result  
MUL24_Result: 
		.byte 6				; allocate six bytes for the result of MUL24 

; data memory allocation for COMPOUND
.org	$0170				; data memory allocation for operands 
ComOpD: 
		.byte 2				; allocate two bytes for operand D
ComOpE:
		.byte 2				; allocate two bytes for operand E 
ComOpF:
		.byte 2				; allocate two bytes for operand E 

.org	$0180				; data memory allocation for result 
ComResult:
		.byte 6				; allocate six bytes for result of COMPOUND
