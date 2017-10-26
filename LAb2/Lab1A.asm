;*******************************************************************************
;	Authors:	Alex H.Lamarche
;				Antoine Dozois
;	Description:
;		Polling d'un bouton poussoir
;		Commutateur PTP0
;		Le commutateur est banche en pull-up avec le processeur
;		
;	Pour simulation:
;		OPEN Push_Buttons Module des boutons poussoirs
;		PBPORT $0258 Adresse du port P (PTP)
;*******************************************************************************

; export symbols
           		XDEF 		Entry          	; export 'Entry' symbol
            	ABSENTRY 	Entry        	; for absolute assembly: mark this as application entry point

; include derivative specific macros
            	INCLUDE 	'mc9s12c32.inc'

ROMStart    	EQU  		$4000  			; absolute address to place my code/constant data
Simulateur		EQU			1				; Si le code est compiler pour le simulateur

; variable/data section

            	ORG 		RAMStart

; code section
            	ORG   		ROMStart
Entry:
            	LDS   		#RAMEnd+1       ; initialize the stack pointer
            	CLI                   		; enable interrupts
				jsr			initRegistre
mainLoop:

if Simulateur = 0
				BRSET		PORTP,$01,Action
else
				BRCLR		PORTP,$01,Action
endif
	            BRA   		mainLoop        ; restart.

; Functions
; Connection diagram
;	5V ---- PPSP ---- 470Ohm ---- PERP ---- PORTD --+-- PushButton ---- Gnd
initPort:	; initialisation du registre PTP, pour le polling du push-button
		BCLR	DDRP,$01		; connect DDRP
		BSET	PERP,$01		; connect PERP
		MOVB	#$01,PPSP		; mode pull up
		NOP
		NOP
		NOP
		BSET	DDRB,$20
		rts

Action:
		printf	msg
		rts

msg:	'Vous avez pousse le boutton', CR, LF
		
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
	            ORG   		$FFFE
	            DC.W  		Entry           ; Reset Vector
