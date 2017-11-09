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
ROMStart    EQU  $4000  ; Absolute address to place my code/constant data
Compteur    EQU  $0044  ; Adresse du compteur 16 bits du TIM
ComptReset  EQU  40000  ; Valeur a laquelle le compteur est remis a zero
Simulateur  EQU	 1


; variable/data section

;**************************************************************
;	RAM
;**************************************************************    
            ORG RAMStart

VCst:	DS.W	1
TTotal:	DS.W	1
TA:		DS.W	1
TC:		DS.W	1
DeltaV:	DS.W	1			; 
VMD:	DS.W	30			; Vitesse moteur droit
VMG:	DS.W	30			; Vitesse moteur gauche

COMPT	DS.B	1			; Compteur 


VDiff	DS.W	1			; Variable custom 

Avance:	EQU		3200		; Vitesse maximale d'avancement
Neutre:	EQU		3000		; Valeurs d'arrêt
Recule:	EQU		2800		; Vitesse maximale de recule



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
            MOVW    #Neutre,TTotal
            MOVW    #Avance,VCst
            LDD     TTotal
            LDY     VCst
            jsr     Calcul
            LDY		#VMD
			LDX		#DeltaV
			JSR		Profil
            
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
            
initTimer:
            MOVB    #$0A,TSCR2          ; Diviser la clock de 8MHz par 4
                                        ; et activation du reset (TCRE)
            MOVB    #$80,TFLG2          ; Activer le bit pour le débordement
            MOVB    #$0C,TIOS           ; Pin 0 et 1 => Entree, 2 et 3 => Sortie
            MOVW    #ComptReset,TC7     ; On place le reset a 40000 
             
            IF Simulateur = 0           
                MOVB    $03,TIE         ; Si en reel interrupt port Entree
            ELSE
                MOVB    $0C,TIE         ; Si en sim interrupt port Sortie
            ENDIF                                        
            
            MOVW    #Neutre,TC2         ; Valeur initiale pour que les moteurs
            MOVW    #Neutre,TC3         ; ne bouge pas au demarrage du robot
            
            MOVB    #0C,OC7M            ; Mask des reset de sortie
            MOVB    #0C,OC7D            ; Activation des sortie lors du reset
            
            MOVB    #$80,TSCR1          ; Activer le module TIM 
            RTS

;**************************************************************
;* Messages textes
;**************************************************************

;**************************************************************
;* Inclusion du fichier D_BUG12M.ASM
;**************************************************************
			INCLUDE		'Lab2C_speedProfile.asm' ; Fonction de calcule de vitesse et de profile de vitesse
			
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
                                            ; fonctions D_BUG12
 

;**************************************************************
;* Interrupt Vectors
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
