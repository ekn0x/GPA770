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

;Offset pour les 27 régles
O_D_LOIN  EQU   $00      
O_D_MIDI  EQU   $01      
O_D_PRES  EQU   $02      
O_C_LOIN  EQU   $03      
O_C_MIDI  EQU   $04      
O_C_PRES  EQU   $05      
O_G_LOIN  EQU   $06      
O_G_MIDI  EQU   $07      
O_G_PRES  EQU   $08
O_DROITE  EQU   $09
O_AVANT   EQU   $0A
O_GAUCHE  EQU   $0B

MARKER    EQU     $FE  ;Séparateur pour les régles      
ENDR      EQU     $FF  ;Variable de fin pour les régles      



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


;Variables d'entrées pour la fuzzification
E_D_LOIN:       DS.B    1   
E_D_MIDI:       DS.B    1
E_D_PRES:       DS.B    1
E_C_LOIN:       DS.B    1
E_C_MIDI:       DS.B    1
E_C_PRES:       DS.B    1
E_G_LOIN:       DS.B    1
E_G_MIDI:       DS.B    1
E_G_PRES:       DS.B    1

;Valeur après fuzzification
SORTIE_D:	    	DS.B    1	  
SORTIE_C: 		  DS.B    1
SORTIE_G: 	    DS.B    1

VCAPT_DROIT:    DS.B    1    ;Valeurs données par le capteur droit
VCAPT_CENTRE:   DS.B    1    ;Valeurs données par le capteur centre
VCAPT_GAUCHE:   DS.B    1    ;Valeurs données par le capteur gauche
COMMANDE:       DS.B    1    ;Valeur de sortie
	

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

MAIN:
    JSR FINAL
    ;JSR afficherResultats  ;transformer pour LCD et non pas comm serie
    JSR FUZZI
    LDY #100
    JSR DELAI 
    BRA MAIN

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
           	movb     	ATDDR2L, VCAPT_DROIT 		; sauvegarde des trois voltages des capteurs
           	movb     	ATDDR1L, VCAPT_CENTRE
           	movb     	ATDDR0L, VCAPT_GAUCHE
			RTS


;*************************************************************************
;**
;* ROUTINE FUZZI
;* Cette routine permet de faire le calul de logique floue et de touver
;* la commande de braquague
;**
;*************************************************************************

FUZZI:  LDX     #D_LOIN	    ;Le début des entrées utilisé par la fonction MEM
	    LDY     #E_D_LOIN   ;Le début des valeurs fuzzifiées
	   	LDAA    VCAPT_DROIT ;Valeur du capteur droit
	    LDAB    #3          ;Nombre d'ittération
		
LoopD:  MEM                 ;Assigner les valeurs au MEM
        DBNE    B,LoopD     ;Faire les 3 ittérations
        
        LDAA    VCAPT_CENTRE;Valeur du capteur central
        LDAB    #3          ;Nombre d'ittération
LoopC:  MEM                 ;Assigner les valeurs au MEM
        DBNE    B,LoopC     ;Faire les 3 ittérations
        
        LDAA    VCAPT_GAUCHE;Valeur du capteur gauche
        LDAB    #3          ;Nombre d'ittération
LoopG:  MEM                 ;Assigner les valeurs au MEM
        DBNE    B,LoopG     ;Faire les 3 ittérations
        
        ;Remise à zéro des trois sortie pour la défuzzification
        CLR     SORTIE_D
        CLR		  SORTIE_C
        CLR	  	SORTIE_G
        
        LDY     #E_D_LOIN
        LDX     #RULE_START ;Départ des règles
        
        LDAA    #$FF
        
        REV                 ;Évaluer les 27 règles
        
;Défuzzification
        LDX     #A_DROITE   ;Le début des sorties utilisé par la fonction MEM
        LDY     #SORTIE_D   ;Le début des sorties défuzzifiés
        LDAB    #$03        ;Faire la somme des 3 sorties
        WAV
        EDIV
        TFR     Y,D         ;Mettre la réponse dans D
        STAB    COMMANDE    ;Sauvegarder la réponse 
        LDAB    COMMANDE
        JSR     clearLCD
        JSR     LCD2hex
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
		;affLCD  $01, $04, $04   ; Clear Display
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
            ;JSR clearLCD

            LDAB    VCAPT_GAUCHE  ;Mettre la valeur de 'VCAPT_GAUCHE' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
            AFFLCD  ':',2,$05
            LDAB    VCAPT_CENTRE  ;Mettre la valeur de 'VCAPT_CENTRE' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
            AFFLCD  ':',2,$05
            LDAB    VCAPT_DROIT   ;Mettre la valeur de 'VCAPT_DROIT' dans 'B'
            JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'

            rts

; Fonctions d'apartenance pour la fuzzification     
D_LOIN:         dc.b    $00,$30,$00,$10	   
D_MIDI:         dc.b    $20,$60,$10,$10
D_PRES:         dc.b    $50,$FF,$10,$00
C_LOIN:         dc.b    $00,$30,$00,$10
C_MIDI:         dc.b    $20,$60,$10,$10
C_PRES:         dc.b    $50,$FF,$10,$00
G_LOIN:         dc.b    $00,$30,$00,$10
G_MIDI:         dc.b    $20,$60,$10,$10
G_PRES:         dc.b    $50,$FF,$10,$00

;Valeur des trois singletons pour la défuzzification
A_DROITE:       dc.b    $F0
DEVANT:         dc.b    $80
A_GAUCHE:       dc.b    $10

;Définition des 27 règles 
RULE_START:     dc.b    O_G_LOIN, O_C_LOIN, O_D_LOIN, MARKER, O_AVANT,  MARKER      
                dc.b    O_G_LOIN, O_C_LOIN, O_D_MIDI, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_LOIN, O_C_LOIN, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_LOIN, O_C_MIDI, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_LOIN, O_C_MIDI, O_D_MIDI, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_LOIN, O_C_MIDI, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_LOIN, O_C_PRES, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_LOIN, O_C_PRES, O_D_MIDI, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_LOIN, O_C_PRES, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_MIDI, O_C_LOIN, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_LOIN, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_LOIN, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_MIDI, O_C_MIDI, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_MIDI, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_MIDI, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_MIDI, O_C_PRES, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_PRES, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_MIDI, O_C_PRES, O_D_PRES, MARKER, O_GAUCHE, MARKER
                dc.b    O_G_PRES, O_C_LOIN, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_LOIN, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_LOIN, O_D_PRES, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_MIDI, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_MIDI, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_MIDI, O_D_PRES, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_PRES, O_D_LOIN, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_PRES, O_D_MIDI, MARKER, O_DROITE, MARKER
                dc.b    O_G_PRES, O_C_PRES, O_D_PRES, MARKER, O_DROITE, ENDR


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
