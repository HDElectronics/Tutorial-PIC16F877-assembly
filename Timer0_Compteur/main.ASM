;**********************************************************************
;                                                                     *
;    Filename:	    timer0counter.asm                                 *
;    Date:          09/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
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
	cblock 	20h
		w_temp        :1
		status_temp   :1
		compteur	  :1
	endc
;
mask_option 	  	equ 	b'10111000'	
mask_interruption 	equ 	b'10100000'
;-----------------------------------
	#define led PORTB,RB0

;-----------------------------------
;***** macros definitions
write_reg macro register,value 
		banksel register
		movlw value
		movwf register
		endm
;-----------------------------------		
				
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
		call 	tmr0_isr		  
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
			banksel 	OPTION_REG
			movlw		mask_option
			movwf		OPTION_REG
			banksel 	TRISB
			bcf 		TRISB,RB0
			bsf			TRISA,RA4
			write_reg 	TMR0,0xfb
			banksel 	INTCON
			movlw 		mask_interruption
			movwf 		INTCON
while1
			
		goto while1
;********************************************************************************
tmr0_isr
			write_reg 	TMR0,0xfb	
			call 		toggle_led	
			return
;********************************************************************************		
toggle_led
			banksel 	PORTB
			movlw 		1
			xorwf 		PORTB
			return
;********************************************************************************	
		end