;**********************************************************************
;                                                                     *
;    Filename:	    MSSP_I2C		                                  *
;    Date:          10/06/2020                                        *
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
		;Mise a zero de mes deux variables (adr_EEPROM)
		banksel		adr_EEPROM
		clrf		adr_EEPROM
		clrf		ptr
		;Config	(PORTC input)
		banksel		TRISC
		movlw		0xff
		movwf		TRISC
		banksel		PORTC
		
		;Config MSSP for I2C
		banksel		SSPSTAT		
		
		bsf			SSPSTAT,SMP	;In I2C Master or Slave mode:
								 ;=> 1 = Slew rate control disabled for standard speed mode (100 kHz and 1 MHz) <=
							 	 ;0 = Slew rate control enabled for high speed mode (400 kHz)
		
		bcf			SSPSTAT,CKE	;I2C Master or Slave mode:
								 ;1 = Input levels conform to SMBus spec
								 ;=> 0 = Input levels conform to I2C specs <=
		banksel		SSPADD
		movlw		0x09		; Datasheet 16F877 page 87 (9.2.8 BAUD RATE GENERATOR)
		movwf		SSPADD		;Note:Baud Rate = FOSC / (4 * (SSPADD + 1) )
		
		banksel		SSPCON
		movlw		0x28		; Datasheet page 69 (REGISTER 9-2: SSPCON: SYNC SERIAL PORT CONTROL REGISTER (ADDRESS 14h))
								; 0010 1000
		movwf		SSPCON		;
		
		
		
		banksel		PORTC
begin
		btfss		PORTC,RC0
		goto		begin
infloop
		call		I2C_start		;Lancer une condition Start
		movlw		b'10100000'		;Mettre l'adresse de l'esclave dans W suivi du bit R/W
		call		I2C_write		;Ecrire le contenu de W dans le bus I2C
		call		I2C_ACK_slave_to_master	;Attendre l'ACK de l'esclave
		banksel		adr_EEPROM
		movf		adr_EEPROM,W	;Adresse interne de l'EEPROM	
		call		I2C_write		;Envoyer cette adresse pour informer l'EEPROM qu'on veut ecire sur cette adresse
		call		I2C_ACK_slave_to_master	;Attende l'ACK de l'esclave  
		call		TABLE			;Aller cherchez une donnee de notre TABLE
		call		I2C_write		;Envoyer cette donnee a l'EEPROM
		call		I2C_ACK_slave_to_master	;Attendre l'ACK de l'esclave
		call		I2C_stop	 	;Lancer uen condition Stop pour terminer la communication	
		banksel		adr_EEPROM
		incf		adr_EEPROM,F 	;incrementer l'adresse de l'EEPROM
		incf		ptr		
		call 		delay
		banksel		adr_EEPROM
		movlw		.13
		subwf		ptr,W
		btfsc		STATUS,Z
		goto		begin
		goto infloop

;************************************************************************
;I2C sous-fontions
I2C_idle	;Verifie si aucune operation n'est en cours
			;;Utiliser avant chaque etape pour laisser le temps
			;;a l'etape precedente de se terminer
		banksel		SSPCON2
I2C_idle_label
		btfsc 		SSPCON2,ACKEN	;Si = 0 => sequence ACK termine
		goto 		I2C_idle_label	
		btfsc 		SSPCON2,RCEN	;Si = 0 => sequence Repeated Start termine
		goto 		I2C_idle_label
		btfsc 		SSPCON2,PEN		;Si = 0 => sequence Stop termine
		goto 		I2C_idle_label
		btfsc 		SSPCON2,RSEN	;Si = 0 => sequence Receive termine
		goto 		I2C_idle_label
		btfsc 		SSPCON2,SEN		;Si = 0 => sequence Start termine
		goto 		I2C_idle_label
		banksel		SSPSTAT
		btfsc 		SSPSTAT,R_W		;Si = 0 => aucune transmission en cours
		goto 		I2C_idle_label
		return
;**************
I2C_start	;Lancer une sequence Start
		call 		I2C_idle
		banksel		SSPCON2 
		bsf 		SSPCON2,SEN
		return
;**************
I2C_write	;Ecrire le contenue de W dans le bus I2C
		call 		I2C_idle
		banksel		SSPBUF
		movwf 		SSPBUF
		return
;**************
I2C_ACK_slave_to_master	;Attendre l'ACK de l'esclave
		call 		I2C_idle 
		banksel		SSPCON2
I2C_ACK_slave_to_master_label
		btfsc 		SSPCON2,ACKSTAT	;I2C ACKSTAT: Acknowledge Status bit (InMaster mode only)
									;In Master Transmit mode:
									 ;1 = Acknowledge was not received from slave
									 ;0 = Acknowledge was received from slave

		goto 		I2C_ACK_slave_to_master_label
		return
;**************
I2C_Repeated_Start	;Lancer une sequence Repeated Start
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2,RSEN
		return
;**************		
I2C_read		;Lire le contenue du bus I2C est le mettre dans W
		call 		I2C_idle 
		banksel		SSPCON2
		bsf 		SSPCON2,RCEN 
I2C_read_label
		btfsc 		SSPCON2,RCEN
		goto 		I2C_read_label
		banksel		SSPBUF
		movf 		SSPBUF,W
		return
;**************
I2C_ACK_master_to_slave	;Lancer une sequence ACK
		call 		I2C_idle
		banksel		SSPCON2
		bcf 		SSPCON2 , ACKDT	;ACKDT = 0 pour ACK
		bsf 		SSPCON2 , ACKEN	;Lancer une sequence ACK
		return
;**************
I2C_NOACK	;Lancer une sequence NOACK
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2 , ACKDT	;ACKDT = 1 pour NOACK
		bsf 		SSPCON2 , ACKEN ;Lancer une sequence NOACK
		return
;**************
I2C_stop	;Lancer une sequence Stop
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2,PEN
		return
;**************
;************************************************************************
delay		;Routine de delai (1s)
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
		addwf		PCL
char	dt		"Mohamed-Fares" ;c'est l'equivalent de: RELTW "M"
								;					   	RETLW "o"	
								;						RETLW "h"
								;						RETLW "a"
								;						RETLW "m"
								;							.
								;							.
								;							.
								;						   etc
;************************************************************************
		end                       