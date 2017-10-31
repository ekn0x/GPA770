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
            	INCLUDE     'D_BUG12M.mac'

ROMStart    	EQU  		$4000  			; absolute address to place my code/constant data
Simulateur		EQU			1				; Si le code est compiler pour le simulateur
CAPTEUR1        EQU         $0091
CAPTEUR2        EQU         $0093
CAPTEUR3        EQU         $0095

; variable/data section

            	ORG 		RAMStart
            	
Urgence:                DC.B    1

; code section
            	ORG   		ROMStart
Entry:
            ;************************************************************************
            ;*                          Prep Interruption                           *
            ;************************************************************************
            
            
            CLI
            LDS #$1000
            ;MOVB #$20,SCICR2


            ;*************************************************************************
            ;
            ;Init portb en sortie

             LDAB #$ff ; 1 = sortie
             STAB DDRB
             
            ;*************************************************************************
            ;
            ; Init du SCI (transmetteur et récepteur de caractères sériel)
             CLR SCIBDH
             LDAB #$34 ; si bus clk est à 8MHz
             STAB SCIBDL ; 9600 BAUDS
             CLR SCICR1 ; M BIT = 0 POUR 8 BITS
             LDAB #$2C
             STAB SCICR2 ; TE , RE
			 jsr			initPort
			 
				
				
mainLoop:

    IF Simulateur = 0
                BRCLR		PTP,$01,Action
    ELSE
    			BRSET		PTP,$01,Action
    ENDIF
	            BRA   		mainLoop        ; restart.
	            
DONE:           WAI
                BRA         DONE

; Functions
; Connection diagram
;	5V ---- PPSP ---- 470Ohm ---- PERP ---- PORTP --+-- PushButton ---- Gnd
initPort:	; initialisation du registre PTP, pour le polling du push-button
		BCLR	DDRP,$00		; mode 0 - mode read
		BSET	PERP,$01		; mode 1 - either pullup or pulldown
		MOVB	#$00,PPSP		; mode 0 - mode pull up
		NOP
		NOP
		NOP
		rts

Action:
		printf	#msg
		BRA     DONE

msg:	DC.B    'Vous avez poussé le boutton', $0D, $00


KeyInter:
        STAA SCISR1
        STAA SCIDRL
        MOVB #$00, Urgence
        MOVB #$0C, SCICR2   
        printf	#msg
        RTI
        


;**************************************************************
;*                          DEBUG                             *
;**************************************************************

                INCLUDE     'D_BUG12M.ASM'
		
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
	            ORG   		$FFFE
	            DC.W  		Entry           ; Reset Vector
	            ORG         $FFD6
	            DC.W        KeyInter
