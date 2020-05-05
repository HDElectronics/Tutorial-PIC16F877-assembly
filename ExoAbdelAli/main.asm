;**********************************************************************
;                                                                     *
;    Filename:	    ExoIsli.asm   		                              *
;    Date:          17/04/2020                                        *
;                                                                     *
;    Author:		KHADRAOUI Ibrahim                                 *
;    Company:		USTHB FEI                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;****************************************************************
;Exo propos� par Abdelali:										*
;	Deux LEDs une sur RC0 et l'autre sur RC1					*
;	Deux Bouttons un sur RB0 et l'autre sur RB4					*
;	Ecrire un programme en utilisant les interruptions sur		*
;	RB0 et RB4.													*
;		RB0 : clignote une fois la LED branch�e sur RC0			*
;		RB1 : clignote une fois la LED branch�e sur RC1			*
;	Conseills : Utilisez l'interruption RB0/INT et RB Change	*
;				INTCON = 0b10011000								*
;****************************************************************
	
;*********************************	
	list p=16f877				;*
	#include <p16f877.inc>		;*
	__config 0x3F3A				;*
;*********************************
		
;************************************
;	DECLARATION DES VARIABLES		*
;************************************************************************************************
w_temp			equ	20h	;variable pour enregistrer accumulateur W lors des interruptions		*
status_temp		equ 21h ;variable pour enregistrer le registre STATUS lors des interruptions	*
variable1 		equ 22h ;variable utiliser dans la fonction de temporisation					*
variable2 		equ 23h ;variable utiliser dans la fonction de temporisation					*
variable3 		equ 24h ;variable utiliser dans la fonction de temporisation					*
;************************************************************************************************

	org 	0x00
	goto 	main

	
;****************************************
;	L'adresse 0x04 de l'interruption	*
;************************************************	
;	si une interruption surviens le programme	*
; 	sautera � la ligne "org 0x04" juste			*
;	en dessous									*
;************************************************************************************************************
	org 	0x04		;																					*
;																											*
	;Sauvegard de W et STATUS																				*
	movwf 	w_temp		;mettre W dans la variable w_temp													*
	movf	STATUS,W	;mettre STATUS dans W																*
	movwf	status_temp	;mettre W(STATUS) dans la variable status_temp										*
;																											*
	;Test des flags pour savoir quelle interruptions s'est d�clanch�e										*
	btfsc	INTCON,INTF		;Test du flag de RB0/INT														*
	call	fonction_INTF	;Si le flag est � 1 executer la sous fonction de cette interruption				*
	btfsc	INTCON,RBIF		;Test du flag de RB Change														*
	call	fonction_RBIF	;Si le flag est � 1 executer la sous fonction de cette interruption				*
;																											*
	;Remise � z�ro des flags																				*
	bcf		INTCON,INTF ;																					*
	movf	PORTB,W ;lire le PORTB pour raz le flag															*
					;voir datasheet page 31 (PORTB)															*
	bcf 	INTCON,RBIF	;																					*
;																											*
	;R�cup�ration de W et du Registre STATUS																*
	movf	status_temp,W	;mettre status_temp dans W														*
	movwf	STATUS			;puis le mettre dans STATUS														*
	swapf	w_temp,F		;inverser les quartets de w_temp												*
	swapf	w_temp,W		;r�-inverser les quartets de w_temp et mettre le r�sultat dans W				*
	;Remarque : on a utilis� le swapf parce qu'il n'affecte aucun bit du registre STATUS					*
;																											*
	retfie	;Retoure au programme principal et remise � 1 de INTCON,GIE										*
;************************************************************************************************************

;****************************************
;		Programme Principal				*
;********************************************************
main	;												*
	banksel	TRISC	;									*
	clrf	TRISC	;mettre le PORTC en sortie			*
	movlw	0xff	;									*
	movwf	TRISB	;mettre	le PORTB en entr�e 			*
	bcf		OPTION_REG,NOT_RBPU	;activer r�sistances PU *
	banksel	PORTC	;									*
	clrf 	PORTC	;mise � z�ro du PORTC				*
	movf	PORTB,W ;lire le PORTB pour raz le flag		*
					;voir datasheet page 31 (PORTB)		*
	movlw	98h		; W = 0b10011000					*
	movwf 	INTCON	; mise � 1 de GIE et INTE et RBIE	*
	;Remarque GIE permet d'utiliser les interruptions	*
	;INTE active l'interruption de RB0/INT				*
	;RBIE active l'interruption de RB Change			*
;														*
	;Boucle infinie										*
while1			;										*
				;										*
	goto while1 ;										*
;********************************************************	

;****************************************
;		Les sous-programmes				*
;************************************************************
fonction_RBIF	;sous-programme de l'interruption RB Change	*
				;Il fait clignoter la LED branch�e sur RC1	*
	banksel	PORTC	;										*
	bsf 	PORTC,1 ;										*
	call 	delay	;										*
	bcf		PORTC,1 ;										*
	call	delay	;										*
	return			;										*
;************************************************************
fonction_INTF	;sous-programme de l'interruption RB0/INT	*
				;Il fait clignoter la LED branch�e sur RC0	*	
	banksel	PORTC	;										*
	bsf 	PORTC,0 ;										*
	call 	delay	;										*
	bcf		PORTC,0 ;										*
	return			;										*
;************************************************************	
delay			;sous-programme de temporisation			*
;															*
	movlw 		0xff		;								*
	movwf 		variable1 	;								*
	movwf 		variable2 	;								*
	movlw 		0x0b		;								*
	movwf 		variable3	;								*
b1							;								*
	decfsz 		variable1	;								*
	goto 		b1			;								*
	movlw 		0xff		;								*
	movwf 		variable1	;								*
	decfsz 		variable2	;								*
	goto 		b1			;								*
	movlw 		0xff		;								*
	movwf 		variable2	;								*
	decfsz 		variable3	;								*
	goto 		b1			;								*
	movlw 		0x0b		;								*
	movwf 		variable3	;								*
	return					;								*
;************************************************************
	end		