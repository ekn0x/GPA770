;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point

; include derivative specific macros
            INCLUDE 'mc9s12c32.inc'
            INCLUDE 'D_BUG12M.mac'

            list

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
MARKER      EQU  $FE            
ENDRO       EQU  $FF 

; code section
            ORG   ROMStart


Entry:
            CLI                   	; enable interrupts
            LDS #$1000 ; initialisation de la pileau haut
                       ; de ls RAM ($0800-$0FFF)
                       
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
             LDAB #$0C
             STAB SCICR2 ; TE , RE

            ;*************************************************************************
            
             ; Preparation pour evalution des fonctions membres
             LDX  #D_LOIN
             LDY  #D_L
             LDAA Vcapt_droit 
             LDAB #$09
             ; Evaluation des fonction membres
ENCORE:      MEM
             DBNE B,ENCORE
             
             ; Preparation pour evalution regles
             LDY  #D_L
             LDX  #RULESTART
             LDAA #ENDRO
             ; Evaluation des regles          
             REV
             
             ; Preparation du calcul de sortie
             LDX  #SINGLETON
             LDY  #AGAUCHE
             LDAB #$05
             ; Evaluation de la sortie
             WAV
             EDIV
             TFR Y,D
             
             STAB COMMANDE
             
              

FIN:		BRA		FIN
			
		
			
;**************************************************************
;*                      Variable RAM                          *
;* NAME:        DS.B                                          *
;**************************************************************	
; Voltage capteur
Vcapt_droit:     DS.W    1
Vcapt_centre:    DS.W    1
Vcapt_gauche:    DS.W    1

; Valeur d'appartenance
D_L:             DS.W    1
D_M:             DS.W    1
D_P:             DS.W    1
C_L:             DS.W    1
C_M:             DS.W    1
C_P:             DS.W    1
G_L:             DS.W    1
G_M:             DS.W    1
G_P:             DS.W    1             

; Valeur des regles
SF_AVANT:        DS.W    1
SF_AGAUCHE:      DS.W    1
SF_ADROITE:      DS.W    1

; Valeur de sortie
AGAUCHE:         DS.W    1
AVANT:           DS.W    1
ADROITE:         DS.W    1

; Commande
COMMANDE:         DS.W    1
			
;**************************************************************
;*                    Function Membre                         *
;* NAME:        DC.B    Pts1, Pts2, Pent2, Pente2             *
;**************************************************************
; Right
D_LOIN:       DC.B    $00, $30, $00, $10
D_MIDI:       DC.B    $20, $60, $10, $10
D_PRES:       DC.B    $50, $FF, $10, $00
; Center
C_LOIN:       DC.B    $00, $30, $00, $10
C_MIDI:       DC.B    $20, $60, $10, $10
C_PRES:       DC.B    $50, $FF, $10, $00
; Left
G_LOIN:       DC.B    $00, $30, $00, $10
G_MIDI:       DC.B    $20, $60, $10, $10
G_PRES:       DC.B    $50, $FF, $10, $00


;**************************************************************
;*                          Rules                             *
;* NAME:        DC.B                                          *
;**************************************************************
RULESTART: DC.W     G_L, C_L, D_L, MARKER, SF_AVANT,   MARKER ;1
           DC.W     G_L, C_L, D_M, MARKER, SF_AGAUCHE, MARKER ;2
           DC.W     G_L, C_L, D_P, MARKER, SF_AGAUCHE, MARKER ;3
           DC.W     G_L, C_M, D_L, MARKER, SF_ADROITE, MARKER ;4
           DC.W     G_L, C_M, D_M, MARKER, SF_AGAUCHE, MARKER ;5 
           DC.W     G_L, C_M, D_P, MARKER, SF_AGAUCHE, MARKER ;6 
           DC.W     G_L, C_P, D_L, MARKER, SF_ADROITE, MARKER ;7 
           DC.W     G_L, C_P, D_M, MARKER, SF_AGAUCHE, MARKER ;8 
           DC.W     G_L, C_P, D_P, MARKER, SF_AGAUCHE, MARKER ;9 
           DC.W     G_M, C_L, D_L, MARKER, SF_ADROITE, MARKER ;10
           DC.W     G_M, C_L, D_M, MARKER, SF_ADROITE, MARKER ;11 
           DC.W     G_M, C_L, D_P, MARKER, SF_AGAUCHE, MARKER ;12 
           DC.W     G_M, C_M, D_L, MARKER, SF_ADROITE, MARKER ;13 
           DC.W     G_M, C_M, D_M, MARKER, SF_ADROITE, MARKER ;14 
           DC.W     G_M, C_M, D_P, MARKER, SF_AGAUCHE, MARKER ;15 
           DC.W     G_M, C_P, D_L, MARKER, SF_ADROITE, MARKER ;16 
           DC.W     G_M, C_P, D_M, MARKER, SF_ADROITE, MARKER ;17 
           DC.W     G_M, C_P, D_P, MARKER, SF_AGAUCHE, MARKER ;18 
           DC.W     G_P, C_L, D_L, MARKER, SF_ADROITE, MARKER ;19 
           DC.W     G_P, C_L, D_M, MARKER, SF_ADROITE, MARKER ;20 
           DC.W     G_P, C_L, D_P, MARKER, SF_ADROITE, MARKER ;21 
           DC.W     G_P, C_M, D_L, MARKER, SF_ADROITE, MARKER ;22 
           DC.W     G_P, C_M, D_M, MARKER, SF_ADROITE, MARKER ;23 
           DC.W     G_P, C_M, D_P, MARKER, SF_ADROITE, MARKER ;24 
           DC.W     G_P, C_P, D_L, MARKER, SF_ADROITE, MARKER ;25 
           DC.W     G_P, C_P, D_M, MARKER, SF_ADROITE, MARKER ;26 
           DC.W     G_P, C_P, D_P, MARKER, SF_ADROITE, ENDRO  ;27 
  

;**************************************************************
;*                       Singleton                            *
;* NAME:        DC.B    Liste de valeur                       *
;**************************************************************
SINGLETON: DC.B $10, $80, $F0

;*************************************************************************
;* 																		 *
;* Inclusion du fichier D_BUG12M.ASM 									 *
;* 																		 *
;*************************************************************************
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
											; fonctions D_BUG12

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
