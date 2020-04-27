;**********************************************************************
;                                                                     *
;    Filename:	    Interruption.asm                                  *
;    Date:          27/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;**********************************************************************
;                                                                     *
;    Notes: Clingote une led lors d'un appui sur le bouton-pussoir    *
;			branché sur la pin RB0 en utilisant l'interruption		  * 
;								RB0/INT								  *
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
		btfsc	INTCON,INTE		  ; test si l'interruption est active
		btfss	INTCON,INTF		  ; test le flag d'interruption
		goto	restauration	  ; si le flag est a 0 ne pas appeler la sous-fonction d'interruption
		call    isr				  ; sous-fonction d'interruption isr (interrupt sub routine)
		bcf		INTCON,INTF		  ; effacement du flag de l'interruption RB0/INT
;****************
restauration
		movf    status_temp,w     ; retrieve copy of STATUS register
		movwf	STATUS            ; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w          ; restore pre-isr W register contents
		bcf 	INTCON,INTF
		retfie                    ; return from interrupt



main
		;Config (PORTB=>Input / PORTC=>Output)
		banksel	 TRISB
		movlw	 0xff
		movwf    TRISB
		clrf	 TRISC
		banksel	 PORTC
		clrf	 PORTC
		;Config interruption (RB0/INT) sur front descendant
		banksel	 OPTION_REG
		bcf		 OPTION_REG,INTEDG	  ; selection sur front descendant
		bcf		 OPTION_REG,NOT_RBPU  ; activation resistances pull-up PORTB
		banksel	 INTCON
		bsf		 INTCON,GIE			  ; activation global des interruptions
		bsf		 INTCON,INTE		  ; activation de l'interruption RB0/INT
infloop
		; Boucle infinie vide on clignote la led 
		; juste avec la fonction d'interruption
	goto infloop


;************************************************************************
isr
	banksel		PORTC
	bsf			PORTC,RC0
	call		delay
	bcf			PORTC,RC0
	call		delay
	return


;************************
delay
	movlw 0xff
	movwf variable1
	movwf variable2
	movlw 0x05
	movwf variable3
b1
	decfsz variable1
	goto b1
	movlw 0xff
	movwf variable1
	decfsz variable2
	goto b1
	movlw 0xff
	movwf variable2
	decfsz variable3
	goto b1
	movlw 0x05
	movwf variable3
	return
;************************************************************************

		end                       

