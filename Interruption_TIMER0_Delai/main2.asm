;**********************************************************************
;                                                                     *
;    Filename:	    inttmr0delai.asm                                  *
;    Date:          09/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;**********************************************************************
;                                                                     *
;    Notes: On utilise une diviseur de fréquence de 1/256 et notre	  *
;			quartz est de 4Mhz alors notre cycle d'instruction est    *
;			de 1µs on en déduit que le timer0 s'incrémente chaque     *
;			256µs(a cause du diviseur de fréquence) pour obtenir un   *
;			délai de 10ms il faut que le timer0 s'incrémente 39 fois  *
;			alors je fais 256-39 pour trouver la valeur initial du 	  *
;			timer0  0x27
;                                                                     *
;**********************************************************************


;************************************************************************************************************************
	list r=dec
	list      p=16f877            
	#include <p16f877.inc>        
	__CONFIG _CP_OFF & _WDT_ON & _BODEN_ON & _PWRTE_ON & _RC_OSC & _WRT_ENABLE_ON & _LVP_ON & _DEBUG_OFF & _CPD_OFF 
;************************************************************************************************************************		

;***** VARIABLE DEFINITIONS
CBLOCK 20h
	w_temp        :1
	status_temp   :1
	compteur	  :1
ENDC

mask_option 	  	EQU B'10000111'	
mask_interruption 	EQU B'10100000'
;-----------------------------------
#define LED PORTB,.0
;-----------------------------------
LED_ON  macro
		BANKSEL PORTB
		BSF LED
		ENDM

LED_OFF macro
		BANKSEL PORTB
		BCF LED
		ENDM
		
WRITE_REG macro register,value 
		BANKSEL register
		MOVLW value
		MOVWF register
		ENDM
		
TMR0_START macro
		BANKSEL INTCON
		MOVLW mask_interruption
		MOVWF INTCON
		ENDM
;********************************************************************************
		ORG     0x000             ; processor reset vector					
  		GOTO    main              ; go to beginning of program				
																		
;********************************************************************************
		ORG     0x004             ; interrupt vector location				
		MOVWF   w_temp            ; save off current W register contents	
		MOVF	STATUS,w          ; move status register into W register	
		MOVWF	status_temp       ; save off contents of STATUS register	
;********************************************************************************
		BTFSC	INTCON,T0IE		  ; test if Timer0 interrupt is active									   
		BTFSS	INTCON,T0IF		  ; test if the flag is set									   	
		BCF     INTCON,T0IF		  ; set the flag to 0
		;After the ISR
		MOVF    status_temp,w     ; retrieve copy of STATUS register
		MOVWF	STATUS            ; restore pre-isr STATUS register contents
		SWAPF   w_temp,f
		SWAPF   w_temp,w          ; restore pre-isr W register contents
		RETFIE                    ; return from interrupt
;********************************************************************************


main
		BANKSEL OPTION_REG
		MOVLW	mask_option
		MOVWF	OPTION_REG
		BANKSEL TRISB
		CLRF TRISB
		LED_ON
		TMR0_START
		while1
			if compteur == .100
				CALL TOGGLE_LED
				WRITE_REG 
			ENDIF
		GOTO while1
;********************************************************************************
		TMR0_ISR
			INCF compteur
		RETURN
;********************************************************************************		
		TOGGLE_LED
			BANKSEL PORTB
			if LED == .1
				LED_OFF
			else
				LED_ON
			ENDIF
		RETURN
END