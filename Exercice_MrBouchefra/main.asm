;**********************************************************************
;                                                                     *
;    Filename:	    xxxxxxxxxxxx.asm                                  *
;    Date:          xx/xx/2020                                        *
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

	list      p=16f877            
	#include <p16f877.inc>        
	
	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_OFF & _LVP_OFF & _DEBUG_OFF & _CPD_OFF 


;***** VARIABLE DEFINITIONS
w_temp        	equ     0x7E        ; variable used for context saving 
status_temp   	equ     0x7F        ; variable used for context saving
variable1 		equ 	0x20
variable2 		equ 	0x21
variable3 		equ 	0x22

;***** MACRO DEFINITIONS


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
	bsf 	STATUS,RP0
	clrf	TRISB
	movlw	0x06
	movwf	ADCON1
	movlw	0x1F
	movwf	TRISA
	bcf		STATUS,RP0
	clrf	PORTB
infloop
	btfsc	PORTA,RA0
	call 	incremente
	btfsc	PORTA,RA1
	call 	mise_a_zero
	goto infloop

;************************************************************************
incremente
	incf	PORTB,F
	call	delay
	return
	
mise_a_zero
	clrf	PORTB
	call	delay
	return
	
	
delay
	MOVLW 0xFF
	MOVWF variable1
	MOVWF variable2
	MOVLW 0x05
	MOVWF variable3
B1
	DECFSZ variable1
	GOTO B1
	MOVLW 0xFF
	MOVWF variable1
	DECFSZ variable2
	GOTO B1
	MOVLW 0xFF
	MOVWF variable2
	DECFSZ variable3
	GOTO B1
	MOVLW 0x05
	MOVWF variable3
	RETURN
;************************************************************************

		END                       

