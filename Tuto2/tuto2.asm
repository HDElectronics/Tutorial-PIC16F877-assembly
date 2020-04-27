;**********************************************************************
;                                                                     *
;    Filename:	    Tuto2.asm		                                  *
;    Date:          24/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;**********************************************************************
	list	  r=dec
	list      p=16f877            
	#include <p16f877.inc>        
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_OFF & _LVP_OFF & _DEBUG_OFF & _CPD_OFF 

;***** DEFINITIONS
	#define		Button1		PORTA,RA0
	#define		Button2		PORTA,RA1
	#define		Button3		PORTB,RB0
	#define		LED1		PORTC,RC0
	#define		LED2		PORTC,RC1
	#define		LED3		PORTC,RC2

;***** MACRO DEFINITIONS

	
;***** VARIABLE DEFINITIONS
w_temp        	equ     0x7E        ; variable used for context saving 
status_temp   	equ     0x7F        ; variable used for context saving
variable1 		equ 	0x20
variable2 		equ 	0x21
variable3 		equ 	0x22


;**********************************************************************
		ORG     0x000             ; processor reset vector
  		goto    main              ; go to beginning of program
		
;**********************************************************************
;**********************************************************************
		ORG     0x004             ; interrupt vector location
		movwf   w_temp            ; save off current W register contents
		movf	STATUS,w          ; move status register into W register
		movwf	status_temp       ; save off contents of STATUS register
;****************

;****************
		movf    status_temp,w     ; retrieve copy of STATUS register
		movwf	STATUS            ; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w          ; restore pre-isr W register contents
		bcf 	INTCON,INTF
		retfie                    ; return from interrupt
;**********************************************************************
;**********************************************************************

main
	;Config (PORTA Input, PORTB Input, PORTC Output)
	banksel 	ADCON1
	MOVLW 0x06 					; Configure all pins(PORTA)
	MOVWF ADCON1 				; as digital inputs
	banksel 	OPTION_REG		;directive pour changer de bank
	BCF			OPTION_REG,7	;activer pull-up PORTB
	movlw		0x1F
	movwf		TRISA
	movlw		0xFF
	movwf		TRISB
	clrf		TRISC
	
	banksel		PORTC
	clrf		PORTC

infloop
	
	btfss		Button1
	call		Toggle_LED1		
	
	btfsc		Button2
	call		Toggle_LED2
	
	btfss		Button3
	call		Toggle_LED3
	
	goto infloop

;************************************************************************
delay
	movlw 0xFF
	movwf variable1
	movwf variable2
	movlw 0x04
	movwf variable3
b1
	decfsz variable1
	goto b1
	movlw 0xFF
	movwf variable1
	decfsz variable2
	goto b1
	movlw 0xFF
	movwf variable2
	decfsz variable3
	goto b1
	movlw 0x04
	movwf variable3	
	return
;************************************************************************
Toggle_LED1
	banksel		PORTC
	movlw		0x01
	xorwf		PORTC,F
	call		delay
	return
	
Toggle_LED2
	banksel		PORTC
	movlw		0x02
	xorwf		PORTC,F
	call		delay
	return
	
Toggle_LED3
	banksel		PORTC
	movlw		0x04
	xorwf		PORTC,F
	call		delay
	return
;************************************************************************

		END                       