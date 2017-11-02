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
REEL            EQU         $FF8E
SIM             EQU         $FFD6


affLCD:     MACRO
			MOVB    #\3, PORTB
			MOVB    #\1, PORTA
			BCLR     PORTB, $04
			LDY     #\2
			JSR     DELAI
			BSET    PORTB, $04
            ENDM


; variable/data section

            	ORG 		RAMStart
            	
Urgence:        DC.B        1

; code section
            	ORG   		ROMStart
Entry:
        ;************************************************************************
        ;*                          Prep Interruption                           *
        ;************************************************************************
        CLI
        LDS     #$1000

        ;************************************************************************
        ;
        ;Init portb en sortie
        LDAB    #$FF ; 1 = sortie
        STAB    DDRB
         
        ;************************************************************************
        ;
        ; Init du SCI (transmetteur et récepteur de caractères sériel)
        CLR     SCIBDH
        LDAB    #$34 ; si bus clk est à 8MHz
        STAB    SCIBDL ; 9600 BAUDS
        CLR     SCICR1 ; M BIT = 0 POUR 8 BITS
        LDAB    #$2C
        STAB    SCICR2 ; TE , RE
        jsr		initPushButton
        jsr     initPortLCD       
			 
mainLoop:
        MOVB    #$00, Urgence

    IF Simulateur = 0
        BRCLR   PTP,$01,Action
    ELSE
        BRSET   PTP,$01,Action
    ENDIF
        BRA     mainLoop        ; restart.
        
SUITE:  LDY #400
        JSR DELAI
        LDAA #$00
        SUBA Urgence
        LBMI affCAPT 
	            
DONE:   BRA     DONE
        
Action:
		printf	#msg
		BRA     SUITE


; Functions
; Diagramme de connection push button
;	5V ---- PPSP ---- 470Ohm ---- PERP ---- PORTP --+-- PushButton ---- Gnd
initPushButton:	; initialisation du registre PTP, pour le polling du push-button
		BCLR	DDRP,$00		; mode 0 - mode read
		BSET	PERP,$03		; mode 1 - either pullup or pulldown
		MOVB	#$00,PPSP		; mode 0 - mode pull up
		MOVB    #$02,PIFP       ; set the flag for the interrup on PP1
		MOVB    #$02,PIEP       ; enable the interrupt on PP1
		NOP
		NOP
		NOP
		rts

; Diagramme de connection ecran LCD
; PORTA : Data
; PORTB : $04 - Enable                                              
;       : $02 - Read/Write
;       : $01 - Select Register
; 1. Reset procedure ($30, $30, $30)
; 2. 1/2 lignes (Options: $30)
; 3. display off ($08)
; 4. Clr Display ($01)
; 5. type curseur (option: $06)
; 6. Display on ($0E)
initPortLCD:
		BSET    DDRB, #$07      ; Set la direction du portB
		BSET    DDRA, #$FF      ; Set la direction du portA
		
		; 
		affLCD  $30, $01, $04   ; reset1
		affLCD  $30, $01, $04   ; reset2			  
		affLCD  $30, $01, $04   ; reset3
		affLCD  $30, $01, $04   ; 1/2 ligne
		affLCD  $08, $01, $04   ; DisplayOff
		affLCD  $01, $01, $04   ; Clear Display
		affLCD  $06, $01, $04   ; Type Curseur
		affLCD  $0E, $01, $04   ; DisplayOn
		
        rts


msg:	DC.B    'Vous avez poussé le boutton', $0D, $00


RS_REEL:
        LDAA    SCISR1	        ; lecture du SCI Status Register 1
        LDAA    SCIDRL          ; lecture du SCI Status Register 1
        MOVB    #$01, Urgence
        MOVB    #$0C, SCICR2 
        MOVB    #$02,PIFP       ; Aquitter l'interruption
        RTI
        
RS_SIM:
        LDAA    SCISR1	        ; lecture du SCI Status Register 1
        LDAA    SCIDRL          ; lecture du SCI Status Register 1
        MOVB    #$01, Urgence
        MOVB    #$0C, SCICR2 
        RTI

affCAPT:
        LDAB    CAPTEUR1 
        JSR     LCD2hex

        LDAB    #$3A 
        JSR     lsuitehex2      ; Ici on trick pour afficher directement du text

        LDAB    CAPTEUR2
        JSR     LCD2hex

        LDAB    #$3A 
        JSR     lsuitehex2      ; Ici on trick pour afficher directement du text

        LDAB    CAPTEUR3  
        JSR     LCD2hex
        LBRA     DONE
        
DELAI: 
Boucle2:LDX 	#50000 	; 50,000 fois en boucle interne=25 msec
Boucle1:DEX 		    ; décrémente X
		BNE 	Boucle1	; boucle interne
		DEY 		    ; décrémente Y
		BNE 	Boucle2	; boucle externe
		RTS 		    ; retour de la sous-routine

;**************************************************************
;*                          DEBUG                             *
;**************************************************************

                INCLUDE     'D_BUG12M.ASM'
                INCLUDE     'LCDhex.asm'
		
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
	            ORG   		$FFFE
	            DC.W  		Entry           ; Reset Vector
	            ORG         SIM
	            DC.W        RS_SIM
	            ORG         REEL
	            DC.W        RS_REEL
