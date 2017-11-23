;*****************************************************************
;* This is a tempplate for our labs
;*****************************************************************
; export symbols
            XDEF Entry            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point

;**************************************************************
;	include derivative specific macros
;**************************************************************    
            INCLUDE 'mc9s12c32.inc'
            INCLUDE 'D_BUG12M.mac'

            list
;**************************************************************
;	MACROs and DEFINEs
;**************************************************************    
ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; Masque d'etats
ACC		EQU		$01	; Acceleration
ARR		EQU	    $02	; Arret
MAV		EQU		$04 ; Marche avant
MAR		EQU		$06	; Marche Arriere
BDR		EQU		$08	; Braquage a droite
BGA		EQU		$10	; Braquage a Gauche
ETAL	EQU		$20 ; Etallonnage 

; variable/data section

;**************************************************************
;	RAM
;**************************************************************    
            ORG RAMStart

;**************************************************************
;	ROM
;**************************************************************    
            ORG   ROMStart
Entry:
            CLI             ; enable interrupts
            LDS     #$1000  ; initialisation de la pileau haut
                            ; de ls RAM ($0800-$0FFF)
                            ; Initialisation communication
            jsr     initProcedure
			
			jsr		initTimer
			
            
			BRN		Entry

;**************************************************************
;	Functions
;**************************************************************    
initProcedure:
            ;Init portb en sortie
            LDAB    #$ff ; 1 = sortie
            STAB    DDRB
             
            ; Init du SCI (transmetteur et récepteur de caractères sériel)
            CLR     SCIBDH
            LDAB    #$34 ; si bus clk est à 8MHz
            STAB    SCIBDL ; 9600 BAUDS
            CLR     SCICR1 ; M BIT = 0 POUR 8 BITS
            LDAB    #$0C
            STAB    SCICR2 ; TE , RE
            rts

;**************************************************************
;	initTimer
;	type:	function
;	Author:	Alex H.Lamarche
;	Initialiser le timer 	
;**************************************************************    
initTimer:
            MOVB    #$0A,TSCR2          ; Diviser la clock de 8MHz par 4
                                        ; et activation du reset (TCRE)
            MOVB    #$8C,TIOS           ; Pin 0 et 1 => Entree, 2 et 3 => Sortie
            MOVW    #ComptReset,TC7     ; On place le reset a 40000 
             
            IF Simulateur = 0           
                MOVB    #$03,TIE        ; Si en reel interrupt port Entree
            ELSE
                MOVB    #$0C,TIE        ; Si en sim interrupt port Sortie
            ENDIF                                        
            
            MOVW    #Neutre,TC2         ; Valeur initiale pour que les moteurs
            MOVW    #Neutre,TC3         ; ne bouge pas au demarrage du robot
            
            MOVB    #$0C,OC7M           ; Mask des reset de sortie
            MOVB    #$0C,OC7D           ; Activation des sortie lors du reset
            
            MOVB    #$A0,TCTL2
            
            MOVB    #$0A,TCTL4          ; Activation de la detection des rising edge
            
            MOVB    #$80,TSCR1          ; Activer le module TIM 
            RTS

;**************************************************************
;* Messages textes
;**************************************************************

;**************************************************************
;* Inclusion du fichier D_BUG12M.ASM
;**************************************************************
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
                                            			; fonctions D_BUG12
			INCLUDE     'LCDhex.asm'		; Fonction du LCD
 

;**************************************************************
;* Interrupt Vectors
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
