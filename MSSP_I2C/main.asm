;**********************************************************************
;                                                                     *
;    Filename:	    MSSP_I2C		                                  *
;    Date:          01/05/2020                                        *
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

adr				equ		0x23
dat				equ		0x24

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
		bcf 	INTCON,INTF
		retfie                    ; return from interrupt
;**********************************************************************
;**********************************************************************


main
		;Mise a zero de mes deux variables (adr, dat)
		banksel		adr
		clrf		adr
		clrf		dat
		;Config	(PORTA input; PORTB output; PORTC input)
		banksel		TRISA
		movlw		0x1f
		movwf		TRISA
		clrf		TRISB
		movlw		0xff
		movwf		TRISC
		banksel		PORTA
		clrf		PORTA
		
		;Config MSSP for I2C
		banksel		SSPSTAT
		bsf			SSPSTAT,SMP
		bcf			SSPSTAT,CKE
		banksel		SSPADD
		movlw		0x09
		movwf		SSPADD
		banksel		SSPCON
		movlw		0x28
		movwf		SSPCON
		
infloop
		call 		delay
		call		I2C_start
		movlw		b'10100000'
		call		I2C_write
		call		I2C_ACK_slave_to_master
		banksel		adr
		movf		adr,w
		call		I2C_write
		call		I2C_ACK_slave_to_master
		movf		dat,f
		call		I2C_write
		call		I2C_ACK_slave_to_master
		call		I2C_stop
		banksel		adr
		incf		adr,f
		incf		dat,f		
		call 		delay
		goto infloop

;************************************************************************
;I2C sous-fontions
I2C_idle
		banksel		SSPCON2
I2C_idle_label
		btfsc 		SSPCON2,ACKEN
		goto 		I2C_idle_label
		btfsc 		SSPCON2,RCEN
		goto 		I2C_idle_label
		btfsc 		SSPCON2,PEN
		goto 		I2C_idle_label
		btfsc 		SSPCON2,RSEN
		goto 		I2C_idle_label
		btfsc 		SSPCON2,SEN
		goto 		I2C_idle_label
		btfsc 		SSPSTAT,R_W
		goto 		I2C_idle_label 
		return
;**************
I2C_start
		call 		I2C_idle
		banksel		SSPCON2 
		bsf 		SSPCON2,SEN
		return
;**************
I2C_write
		call 		I2C_idle
		banksel		SSPBUF
		movwf 		SSPBUF
		return
;**************
I2C_ACK_slave_to_master
		call 		I2C_idle 
		banksel		SSPCON2
I2C_ACK_slave_to_master_label
		btfsc 		SSPCON2,ACKSTAT
		goto 		I2C_ACK_slave_to_master_label
		return
;**************
I2C_Repeated_Start
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2,RSEN
		return
;**************		
I2C_read
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
I2C_ACK_master_to_slave
		call 		I2C_idle
		banksel		SSPCON2
		bcf 		SSPCON2 , ACKDT
		bsf 		SSPCON2 , ACKEN
		return
;**************
I2C_NOACK
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2 , ACKDT
		bsf 		SSPCON2 , ACKEN 
		return
;**************
I2C_stop
		call 		I2C_idle
		banksel		SSPCON2
		bsf 		SSPCON2,PEN
		return
;**************
;************************************************************************
delay
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
		end                       