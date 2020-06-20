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
		;Mettre la variable ptr a zero
		banksel		ptr
		clrf		ptr
		
		;PORC en entree
		banksel		TRISC
		movlw		0xff
		movwf		TRISC
		
		
		;Charger SPBRH par la valeur decimale 25
		;;;Datasheet page 100 TABLE 10-4
		;;;;;;Avec une frequence d'horloge de Fosc=4Mhz et un Baud-Rates=9600bit/s
		;;;;;;et avec BRGH = 1
		banksel		SPBRG
		movlw		.25
		movwf		SPBRG
		banksel		TXSTA
		bsf			TXSTA,BRGH
		bcf			TXSTA,SYNC
		
		
		;Activer le port serie
		banksel		RCSTA
		bsf			RCSTA,SPEN

loop
		;Activer la transmission
		banksel		TXSTA
		bsf			TXSTA,TXEN
		
		;Aller cherchez le charctere a envoyer
		call		TABLE
		;Mettre le charactere dans TXREG pour l'envoyer
		banksel		TXREG
		movwf		TXREG
		;Attendre que le regsitre a decalage se vide
		banksel		TXSTA
		btfsc		TXSTA,TRMT
		goto		$-1
		
		;Attendre que le premier est envoyer
		banksel		PIR1
		btfss		PIR1,TXIF
		goto		$-1
		bcf			PIR1,TXIF
		
		;Incrementer la valeur ptr
		banksel		ptr
		incf		ptr
		;Verifier si ptr est egale a 11
		;;;Si non => revenir au label loop	
		;;;Si oui => remmetre a zero et attendre 1s
		movlw		.11
		subwf		ptr,W
		banksel		STATUS
		btfss		STATUS,Z
		goto		loop
		
		call		delay
		banksel		ptr
		clrf		ptr
		goto		loop

;************************************************************************
delay		;Routine de delai (1s)
		banksel		variable1
		movlw 		0xff
		movwf 		variable1
		movwf 		variable2
		movlw 		0x05
		movwf 		variable3
b1
		decfsz 		variable1
		goto 		b1
		movlw 		0xff
		movwf 		variable1
		decfsz 		variable2
		goto 		b1
		movlw 		0xff
		movwf 		variable2
		decfsz 		variable3
		goto 		b1
		movlw 		0x05
		movwf 		variable3
		return
;************************************************************************
TABLE
		banksel		ptr
		movf		ptr,W
		banksel		PCL
		addwf		PCL,F
mon_message		dt		"PIC16F877\r\n"
;************************************************************************	
		end                       