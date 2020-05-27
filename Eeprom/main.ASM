;**********************************************************************
;                                                                     *
;    Filename:	    eeprom.asm		                                  *
;    Date:          09/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;**********************************************************************
;                                                                     *
;    Notes: 														  *
;                                                                     *
;**********************************************************************
;
;
;************************************************************************************************************************
	list 	  r=dec
	list      p=16f877            
	#include <p16f877.inc>        
	__config 0x3f3a 
;************************************************************************************************************************		
;
;***** variable&constants definitions
valeur	set		20
	cblock 	20h
		w_temp        :1
		status_temp   :1
		compteur	  :1
		_compteur	  :1
	endc
;
;-----------------------------------
	#define bouton1 PORTB,RB0
	#define bouton2 PORTB,RB1
;-----------------------------------
;***** macros definitions
eeprom_write_macro macro adress,mydata ;la donnée se trouve dans W
	LOCAL loop
	banksel	mydata
	movf	mydata,W
	banksel	EEDATA
	movwf 	EEDATA 		;placer data dans registre
	banksel	adress
	movf 	adress,W 	;charger adresse d'écriture
	banksel	EEADR
	movwf 	EEADR 		;placer dans registre
	banksel	EECON1
	bcf 	EECON1,EEPGD;pointer sur mémoire data
	bsf 	EECON1,WREN ;autoriser accès écriture
	bcf 	INTCON,GIE 	;interdire interruptions
	movlw 	0x55 		;charger 0x55
	movwf 	EECON2 		;envoyer commande
	movlw 	0xAA 		;charger 0xAA
	movwf 	EECON2 		;envoyer commande
	bsf 	EECON1,WR 	;lancer cycle d'écriture
	bsf 	INTCON,GIE 	;réautoriser interruptions *
loop
	btfsc 	EECON1,WR 	;tester si écriture terminée
	goto 	loop 		;non, attendre
	bcf 	EECON1,WREN ;verrouiller prochaine écriture
	banksel	PORTB
	endm
		
				
;********************************************************************************
		org     0x000             ; processor reset vector					
  		goto    main              ; go to beginning of program				
;*******************************************************************************																		

;********************************************************************************
		org     0x004             ; interrupt vector location				
		movwf   w_temp            ; save off current w register contents	
		movf	STATUS,W          ; move status register into w register	
		movwf	status_temp       ; save off contents of status register	
;********************************************************************************		  
		bcf     INTCON,T0IF		  ; set the flag to 0
;********************************************************************************
		movf    status_temp,w     ; retrieve copy of status register
		movwf	STATUS            ; restore pre-isr status register contents
		swapf   w_temp,f
		swapf   w_temp,w          ; restore pre-isr w register contents
		retfie                    ; return from interrupt
;********************************************************************************
;
;
main
		clrf		compteur
		clrf		_compteur
		banksel 	OPTION_REG
		bcf			OPTION_REG,NOT_RBPU
		banksel		TRISB
		movlw		0xff
		movwf		TRISB
		banksel		PORTB
while1
		btfss		bouton1			
		call		eeprom_write
		btfss		bouton2
		call 		eeprom_erase
		goto while1
;********************************************************************************
eeprom_write	
		;eeprom_write_macro compteur,compteur
__loop
		banksel	compteur
		movf	compteur,W
		banksel	EEDATA
		movwf 	EEDATA
		banksel	compteur 	;placer data dans registre
		movf 	compteur,W 	;charger adresse d'écriture
		banksel	EEADR
		movwf 	EEADR 		;placer dans registre
		banksel	EECON1
		bcf 	EECON1,EEPGD;pointer sur mémoire data
		bsf 	EECON1,WREN ;autoriser accès écriture
		bcf 	INTCON,GIE 	;interdire interruptions
		movlw 	0x55 		;charger 0x55
		movwf 	EECON2 		;envoyer commande
		movlw 	0xAA 		;charger 0xAA
		movwf 	EECON2 		;envoyer commande
		bsf 	EECON1,WR 	;lancer cycle d'écriture
		bsf 	INTCON,GIE 	;réautoriser interruptions *
loop
		btfsc 	EECON1,WR 	;tester si écriture terminée
		goto 	loop 		;non, attendre
		bcf 	EECON1,WREN ;verrouiller prochaine écriture
		banksel	PORTB
		
		incfsz		compteur
		goto		__loop
		return
;********************************
eeprom_erase
		banksel		_compteur
		clrf		_compteur
_loop
		eeprom_write_macro _compteur,0
		incfsz		_compteur
		goto		_loop
		return
;********************************		
		end