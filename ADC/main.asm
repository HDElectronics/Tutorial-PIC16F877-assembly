;**********************************************************************
;                                                                     *
;    Filename:	    ADC				                                  *
;    Date:          16/06/2020                                        *
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


;******* VARIABLE DEFINITIONS
	cblock 0x20
variable1 		:1
variable2 		:1
variable3 		:1
wait			:1

adr_EEPROM		:1

w_temp        	:1
status_temp   	:1
ptr				:1
	endc
;**********************************************************************
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
		movf    status_temp,w     ; retrieve copy of STATUS register
		movwf	STATUS            ; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w          ; restore pre-isr W register contents
		retfie                    ; return from interrupt
;**********************************************************************
;**********************************************************************


main
		;Configurations des Port(E/S):
		banksel		TRISA
		movlw		0xff
		movwf		TRISA	;PORTA en Entree
		clrf		TRISB	;PORTB en Sortie
		clrf		TRISC	;PORTC en Sortie
					
		
		banksel		ADCON1
		clrf		ADCON1		 ;Mettre tous les bits à 0
								 ;PCFG3:PCFG0 = 0000 => tous les pin du PORTA
								 ;sont en mode analogique et les deux references
								 ;Vref+ et Vref- sont connecte a VCC et GND
		bsf			ADCON1,ADFM	 ;Mettre à 1 le bit ADFM => Right Justified
		
		
		banksel		ADCON0		 ;AD Conversion Clock:
		bcf			ADCON0,ADCS1 ;Mettre à 0 le bit ADCS1
		bsf			ADCON0,ADCS0 ;Mettre à 1 le bit ADCS0 => 01 => Fosc/8 		
		

begin
		banksel		ADCON0
		bsf			ADCON0,ADON  ;Mettre en mode le module en marche
		
		banksel		wait	;Attendre le temps d'acquisition
		movlw		.40
		movwf		wait
		decfsz		wait
		goto		$-1
		
		banksel		ADCON0		;Demmarer la conversion
		bsf			ADCON0,GO
		
		btfsc		ADCON0,GO	;Attendre la fin de la conversion 
		goto		$-1
		
		banksel		ADRESL		;Lecture des valeurs converties
		movf		ADRESL,W	;et les afficher sur le PORTB
		banksel		PORTB		;et le PORTC
		movwf		PORTB		; ADRESL => PORTB et ARESH => PORTC
		banksel		ADRESH		
		movf		ADRESH,W
		banksel     PORTC
		movwf		PORTC
		movlw		4
		movwf		wait
		decfsz		wait
		goto		$-1
		
		goto begin

;************************************************************************

;************************************************************************

;************************************************************************	
		end                       