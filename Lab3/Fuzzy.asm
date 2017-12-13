;*************************************************************************
;* *
;* Auteurs : Samuel Fortin
;           Alexis Lagueux
;* Date :   Novembre 2017
;* *
;* Ce programme : EST UNE COPIE DU LAB 2-C
;* *
;* 1)
;*
;*
;* *
;*************************************************************************
; Point d?entr?e du programme
 ABSENTRY Entry; point d?entr?e pour adressage absolu
 nolist ; D?sactiver l?insertion de texte dans le
; fichier .LST
 INCLUDE 'mc9s12c32.inc' ; Inclusion du fichier d?identification des
; registres
 INCLUDE 'D_BUG12M.MAC'
; R?activer l?insertion de texte dans le
 list ; fichier .LST
;Adresse absolue pour le d?but du programme et des constantes
ROMStart EQU $4000

MARKER          EQU  $FE    	    ;Pour la fuzzy logique
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


affLCD:     MACRO
			MOVB    #\3, PORTB
			MOVB    #\1, PORTA
			BCLR     PORTB, $04
			LDY     #\2
			JSR     DELAI
			BSET    PORTB, $04
            ENDM

 ORG RAMStart

;************************************************************************
;**
;* VARIABLE
;**
;************************************************************************


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

 ORG ROMStart

 Entry:
   lds #$1000
 ;*************************************************************************
 ;**
 ;* Initialisation du SCI (transmetteur et r?cepteur de caract?res s?riel)
 ;**
 ;*************************************************************************
  CLR SCIBDH
  LDAB #$34 ; si bus clk est ? 8MHz
  STAB SCIBDL ; 9600 BAUDS
  CLR SCICR1 ; M BIT = 0 POUR 8 BITS
  LDAB #$0C
  STAB SCICR2 ; TE , RE

 ;*************************************************************************
 ;   Initialisation du convertisseur N/A
 ;   	Mode 8 bits non sign?s ? droite
 ;   	Multiple num?risations. Canal 1, 2 et 3
 ;  	Vitesse du ?sample and hold? ? 2 coups d'horloge
 ;   	Vitesse de l'horloge de conversion ? 2MHz

         movb    	#$C0,ATDCTL2            	; mise en marche du convertisseur et du AFFC
         movb   	#$18,ATDCTL3            	; 3 conversions ? la fois
         movb    	#$81,ATDCTL4            	; 8 bits, 2 clocks S/H, 2MHz
 ;*************************************************************************
 ;INIT: ARR =1

  JSR initPortLCD
 ;Activer interuption
  CLI

  MOVB #$00,SF_ADROITE
  MOVB #$00,SF_AVANT
  MOVB #$00,SF_AGAUCHE

MAIN:
    JSR FINAL
    JSR afficherResultats  ;transformer pour LCD et non pas comm serie
    JSR FUZZI

;*************************************************************************
;**
;* SECTION DES ROUTINES
;**
;*************************************************************************

;*************************************************************************
;**
;* ROUTINE FINAL
;* Cette routine permet de convertire le signal analogique des capteurs
;* IR en num?rique
;**
;*************************************************************************


FINAL:      MOVB	#$91,ATDCTL5            	; d?but de conversion justifi?e ? droite, multiple, ? partir du
                                            	; canal 1

Attendre:  	brclr    	ATDSTAT0,$80,Attendre   	; Attendre la fin des trois conversions (SCF)
           	movb     	ATDDR2L, Vcapt_gauche 		; sauvegarde des trois voltages des capteurs
           	movb     	ATDDR1L, Vcapt_centre
           	movb     	ATDDR0L, Vcapt_droit
			RTS


;*************************************************************************
;**
;* ROUTINE FUZZI
;* Cette routine permet de faire le calul de logique floue et de touver
;* la commande de braquague
;**
;*************************************************************************

            ;***********************************************************************
            ;*								Fuzzification						   *
            ;***********************************************************************

FUZZI:      ; Preparation pour evalution des fonctions membres capteur droit
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
            JSR initPortLCD
            STAB COMMANDE
            LDAB    COMMANDE
            JSR  LCD2hex
            RTS

;*************************************************************************
;**
;* ROUTINE initPortLD
;* Cette routine permet d'initialiser l'?cran LCD
;**
;*************************************************************************

initPortLCD:
		;BSET    DDRB, #$07      ; Set la direction du portB
		;BSET    DDRA, #$FF      ; Set la direction du portA
		MOVB    #$FF, DDRA  ;Initialiser le PORTA en mode sortie
        MOVB    #$FF, DDRB  ;Initialiser le PORTB en mode sortie
		;
		affLCD  $30, 15, $04   ; reset1
		affLCD  $30, $04, $04   ; reset2
		affLCD  $30, $04, $04   ; reset3
		affLCD  $30, $04, $04   ; 1/2 ligne
		affLCD  $08, $04, $04   ; DisplayOff
		affLCD  $01, $04, $04   ; Clear Display
		affLCD  $06, $04, $04   ; Type Curseur
		affLCD  $0E, $04, $04   ; DisplayOn

        rts

;*************************************************************************
;**
;* ROUTINE clearLCD
;* Cette routine permet d'éffacer l'?cran LCD
;**
;*************************************************************************

clearLCD:
		affLCD  $01, $04, $04   ; Clear Display
		affLCD  $02, $04, $04   ; Curseur Home
        rts



DELAI:
Boucle2:LDX 	#5000 	; 50,000 fois en boucle interne=25 msec
Boucle1:DEX 		    ; d?cr?mente X
		BNE 	Boucle1	; boucle interne
		DEY 		    ; d?cr?mente Y
		BNE 	Boucle2	; boucle externe
		RTS 		    ; retour de la sous-routine


;*************************************************************************
;**
;* ROUTINE afficherResultats
;* Cette routine permet d'afficher les valeurs des capteurs sur l'?cran
;* LCD
;**
;*************************************************************************

afficherResultats:
            JSR clearLCD

            LDAB    Vcapt_gauche  ;Mettre la valeur de 'VCAPT_GAUCHE' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
            AFFLCD  ':',2,$05
            LDAB    Vcapt_centre  ;Mettre la valeur de 'VCAPT_CENTRE' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
            AFFLCD  ':',2,$05
            LDAB    Vcapt_droit   ;Mettre la valeur de 'VCAPT_DROIT' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'

            rts

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

 INCLUDE 'LCDhex.ASM'
 INCLUDE 'D_BUG12M.ASM'


;************************************************************************
;*																		*
;*Vecteur Interuption des routines et du reset							*
;*																		*
;************************************************************************

 ORG $FFFE
 fdb Entry ;Reset


 END ; fin de compilation
