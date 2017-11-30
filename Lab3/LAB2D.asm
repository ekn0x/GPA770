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

ROMStart        EQU  $4000  ; absolute address to place my code/constant data
MARKER          EQU  $FE            
ENDRO           EQU  $FF
O_D_L           EQU  $00
O_D_M           EQU  $01
O_D_P           EQU  $02
O_C_L           EQU  $03
O_C_M           EQU  $04
O_C_P           EQU  $05
O_G_L           EQU  $06
O_G_M           EQU  $07
O_G_P           EQU  $08
O_SF_ADROITE    EQU  $09
O_SF_AVANT      EQU  $0A
O_SF_AGAUCHE    EQU  $0B

; Definition RAM
                ORG   RAMStart
;**************************************************************
;*                      Variable RAM                          *
;* NAME:        DS.B                                          *
;**************************************************************	
; Voltage capteur
Vcapt_droit:     DS.B    1
Vcapt_centre:    DS.B    1
Vcapt_gauche:    DS.B    1

; Valeur d'appartenance
D_L:             DS.B    1
D_M:             DS.B    1
D_P:             DS.B    1
C_L:             DS.B    1
C_M:             DS.B    1
C_P:             DS.B    1
G_L:             DS.B    1
G_M:             DS.B    1
G_P:             DS.B    1             


; Valeur des regles
SF_ADROITE:      DS.B    1
SF_AVANT:        DS.B    1
SF_AGAUCHE:      DS.B    1

; Commande
COMMANDE:        DS.B    1

; code section
            ORG   ROMStart


Entry:
            CLI                   	; enable interrupts
            LDS #$1000 ; initialisation de la pileau haut
                       ; de ls RAM ($0800-$0FFF)
            ;*************************************************************************
            ;   Initialisation du convertisseur N/A
            ;   	Mode 8 bits non signés à droite
            ;   	Multiple numérisations. Canal 1, 2 et 3
            ;  	Vitesse du ‘sample and hold’ à 2 coups d'horloge
            ;   	Vitesse de l'horloge de conversion à 2MHz

          	movb    	#$C0,ATDCTL2            	; mise en marche du convertisseur et du AFFC
            movb   	#$18,ATDCTL3            	; 3 conversions à la fois
            movb    	#$81,ATDCTL4            	; 8 bits, 2 clocks S/H, 2MHz           
            ;*************************************************************************
            ;
            ;Init portb en sortie

             LDAB #$FF ; 1 = sortie
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
            ;?
            ;MOVB #$28,Vcapt_gauche
            ;MOVB #$28,Vcapt_centre
            ;MOVB #$00,Vcapt_droit
            MOVB #$00,SF_ADROITE
            MOVB #$00,SF_AVANT
            MOVB #$00,SF_AGAUCHE
            
            ;***************************************************************************************
            ;	 DÉBUT LECTURE
            ;  Conversion des trois voltages des trois capteurs IRs (la vitesse maximum de chaque lecture des capteurs est de 40ms)

FINAL:           	MOVB	#$91,ATDCTL5            	; début de conversion justifiée à droite, multiple, à partir du 
                                            	; canal 1
                                            	
Attendre:  	brclr    	ATDSTAT0,$80,Attendre   	; Attendre la fin des trois conversions (SCF)
           	movb     	ATDDR2L, Vcapt_droit 		; sauvegarde des trois voltages des capteurs
           	movb     	ATDDR1L, Vcapt_centre
           	movb     	ATDDR0L, Vcapt_gauche

		    jsr         afficherResultats  ;transformer pour LCD et non pas comm serie
		
			
			
            ;***********************************************************************
            ;*								Fuzzification						   *
            ;***********************************************************************
            
            ; Preparation pour evalution des fonctions membres capteur droit
            LDX  #D_LOIN
            LDY  #D_L
            LDAA Vcapt_droit 
            LDAB #$03
            ; Evaluation des fonction membres capteur droit
CAPT_D:     MEM
            DBNE B,CAPT_D
             
            ; Preparation pour evalution des fonctions membres capteur centre
            LDX  #C_LOIN
            LDY  #C_L
            LDAA Vcapt_centre 
            LDAB #$03
            ; Evaluation des fonction membres capteur droit
CAPT_C:     MEM
            DBNE B,CAPT_C
             
            ; Preparation pour evalution des fonctions membres capteur gauche
            LDX  #G_LOIN
            LDY  #G_L
            LDAA Vcapt_gauche 
            LDAB #$03
            ; Evaluation des fonctions membres capteur gauche
CAPT_G:     MEM
            DBNE B,CAPT_G
            
                    
            ;***********************************************************************
            ;*						Evaluation des regles						   *
            ;*********************************************************************** 
             
            ; Preparation pour evalution regles
            LDY  #D_L
            LDX  #RULESTART
            LDAA #ENDRO
            ; Evaluation des regles          
            REV  
             
            ;***********************************************************************
            ;*				      		Calcul de sortie						   *
            ;*********************************************************************** 
            
            ; Preparation du calcul de sortie
            LDX  #SINGLETON
            LDY  #SF_ADROITE
            LDAB #$03
            ; Evaluation de la sortie
            WAV
            EDIV
            TFR Y,D
            
            STAB COMMANDE
             
            ;***********************************************************************
            ;*				      Affichge des informations						   *
            ;*********************************************************************** 
            jsr     afficherResultats;
            ldy	#200		 ; À refaire 4 à 5 fois par secondes
        	jsr	DELAI
           	bra      	FINAL             		; et pour toujours
  

FIN:		BRA		FIN

;**************************************************************
;*             Fonction DELAI                         *
;**************************************************************

DELAI: 
Boucle2:LDX 	#5000 	; 50,000 fois en boucle interne=25 msec
Boucle1:DEX 		    ; décrémente X
		BNE 	Boucle1	; boucle interne
		DEY 		    ; décrémente Y
		BNE 	Boucle2	; boucle externe
		RTS 		    ; retour de la sous-routine

;**************************************************************
;*             Fonction d'afficheage                          *
;**************************************************************
afficherResultats:
            printf	#str1		; "Entrées : "
            
            printf	#str2		; "    Vcap_gauche = "
            out2hex	Vcapt_gauche	    ; Afficher l'index du tableau
            printf	#str3		; "    Vcap_centre = "
            out2hex	Vcapt_centre	    ; Afficher l'index du tableau
            printf	#str4		; "    Vcap_droite = "
            out2hex	Vcapt_droit	    ; Afficher l'index du tableau
            printf	#CRLF		; CRLF
            printf	#str5		; "Sortie =  "
    		out2hex	COMMANDE	    ; Afficher l'index du tableau
    		printf	#CRLF		; CRLF
            rts

;**************************************************************
;*             Définition des chaine de char                  *
;**************************************************************
str1:	DC.B	'Entrées : ',$00
str2:	DC.B	'    Vcap_gauche = ',$00
str3:	DC.B	'    Vcap_centre = ',$00
str4:	DC.B	'    Vcap_droite = ',$00
str5:	DC.B	'Sortie = ',$00
CRLF:	DC.B	$0A,$00		


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
RULESTART: DC.W     O_G_L, O_C_L, O_D_L, MARKER, O_SF_AVANT,   MARKER ;1
           DC.W     O_G_L, O_C_L, O_D_M, MARKER, O_SF_AGAUCHE, MARKER ;2
           DC.W     O_G_L, O_C_L, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;3
           DC.W     O_G_L, O_C_M, O_D_L, MARKER, O_SF_ADROITE, MARKER ;4
           DC.W     O_G_L, O_C_M, O_D_M, MARKER, O_SF_AGAUCHE, MARKER ;5 
           DC.W     O_G_L, O_C_M, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;6 
           DC.W     O_G_L, O_C_P, O_D_L, MARKER, O_SF_ADROITE, MARKER ;7 
           DC.W     O_G_L, O_C_P, O_D_M, MARKER, O_SF_AGAUCHE, MARKER ;8 
           DC.W     O_G_L, O_C_P, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;9 
           DC.W     O_G_M, O_C_L, O_D_L, MARKER, O_SF_ADROITE, MARKER ;10
           DC.W     O_G_M, O_C_L, O_D_M, MARKER, O_SF_ADROITE, MARKER ;11 
           DC.W     O_G_M, O_C_L, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;12 
           DC.W     O_G_M, O_C_M, O_D_L, MARKER, O_SF_ADROITE, MARKER ;13 
           DC.W     O_G_M, O_C_M, O_D_M, MARKER, O_SF_ADROITE, MARKER ;14 
           DC.W     O_G_M, O_C_M, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;15 
           DC.W     O_G_M, O_C_P, O_D_L, MARKER, O_SF_ADROITE, MARKER ;16 
           DC.W     O_G_M, O_C_P, O_D_M, MARKER, O_SF_ADROITE, MARKER ;17 
           DC.W     O_G_M, O_C_P, O_D_P, MARKER, O_SF_AGAUCHE, MARKER ;18 
           DC.W     O_G_P, O_C_L, O_D_L, MARKER, O_SF_ADROITE, MARKER ;19 
           DC.W     O_G_P, O_C_L, O_D_M, MARKER, O_SF_ADROITE, MARKER ;20 
           DC.W     O_G_P, O_C_L, O_D_P, MARKER, O_SF_ADROITE, MARKER ;21 
           DC.W     O_G_P, O_C_M, O_D_L, MARKER, O_SF_ADROITE, MARKER ;22 
           DC.W     O_G_P, O_C_M, O_D_M, MARKER, O_SF_ADROITE, MARKER ;23 
           DC.W     O_G_P, O_C_M, O_D_P, MARKER, O_SF_ADROITE, MARKER ;24 
           DC.W     O_G_P, O_C_P, O_D_L, MARKER, O_SF_ADROITE, MARKER ;25 
           DC.W     O_G_P, O_C_P, O_D_M, MARKER, O_SF_ADROITE, MARKER ;26 
           DC.W     O_G_P, O_C_P, O_D_P, MARKER, O_SF_ADROITE, ENDRO  ;27 
  

;**************************************************************
;*                       Singleton                            *
;* NAME:        DC.B    Liste de valeur                       *
;**************************************************************
SINGLETON: DC.B $F0, $80, $10

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