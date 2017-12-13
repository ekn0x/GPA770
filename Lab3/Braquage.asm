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

affLCD:     MACRO
			MOVB    #\3, PORTB
			MOVB    #\1, PORTA
			BCLR     PORTB, $04
			LDY     #\2
			JSR     DELAI
			BSET    PORTB, $04
            ENDM

 ORG RAMStart

 COMMANDE:        DS.B 1
 COMPTBRA:        DS.B 1  ; Compt le nombre de ticks durant le braquage
 ETATS:           DS.B 1	 ;S?lectionne les ?tats
 COMPTARR:        DS.B 1  ; Compteur marche arri?re



 ORG ROMStart



 ANGLES:         DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1 	        ;address va de #$10 ? #$78
                 DC.B    107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95, 94, 93, 92
                 DC.B    91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76
                 DC.B    75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60
                 DC.B    59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44
                 DC.B    43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28
                 DC.B    27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12
                 DC.B    11, 10, 9,  8,  7,  6,  5,  4,  1,  1,  1,  1,  1,  1,  1,  1
                 DC.B    1,	1,	1,	1,	1,	1,	1,	1,	4,	5,	6,	7,	8,	9,	10,	11
                 DC.B    12,	13,	14,	15,	16,	17,	18,	19,	20,	21,	22,	23,	24,	25,	26,	27
                 DC.B    28,	29,	30,	31,	32,	33,	34,	35,	36,	37,	38,	39,	40,	41,	42,	43
                 DC.B    44,	45,	46,	47,	48,	49,	50,	51,	52,	53,	54,	55,	56,	57,	58,	59
                 DC.B    60,	61,	62,	63,	64,	65,	66,	67,	68,	69,	70,	71,	72,	73,	74,	75
                 DC.B    76,	77,	78,	79,	80,	81,	82,	83,	84,	85,	86,	87,	88,	89,	90,	91
                 DC.B    92,	93,	94,	95,	96,	97,	98,	99,	100, 101, 102, 103,	104, 105, 106, 107
                 DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1           ;address termine de #$88 ? #$F0


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

  MOVB #$02,ETATS
  JSR INIT_PULSE
  JSR initPushButton
  JSR initPortLCD
  ;Activer interuption
  CLI
  MOVB #$A9, COMMANDE
  JSR BRAQ
FIN: BRA FIN



  ;*************************************************************************
  ;**
  ;* SECTION DES ROUTINES
  ;**
  ;*************************************************************************

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

    DELAI:
    Boucle2:LDX 	#5000 	; 50,000 fois en boucle interne=25 msec
    Boucle1:DEX 		    ; d?cr?mente X
    		BNE 	Boucle1	; boucle interne
    		DEY 		    ; d?cr?mente Y
    		BNE 	Boucle2	; boucle externe
    		RTS 		    ; retour de la sous-routine

  ;*************************************************************************
  ;**
  ;* ROUTINE BRAQ
  ;* Cette routine permet de savoir a combien le conteur pour le braquage
  ;* doit ?tre initialis?
  ;**
  ;*************************************************************************

  BRAQ:
              LDAB  ANGLES
              LDX  #COMMANDE
              ABX
  			MOVW  X,COMPTBRA

              LDAA COMMANDE
              CMPA #$88
              BHI Droite
              CMPA #$78
              BLO Gauche
              MOVB #$04, ETATS
              BRA AFF
  Gauche:     MOVB    #$20,ETATS

              BRA AFF

  Droite:     MOVB    #$10,ETATS
  AFF:	    RTS


;*************************************************************************
;**
;* ROUTINE INIT_PULSE
;* Cette routine permet d'initialiser les pulses contr?lants les moteur
;* Elle initialise aussi les entr?es pour les interruptions reli?es
;* Aux pulses
;**
;*************************************************************************

 INIT_PULSE:
 MOVB #$0A,TSCR2
 MOVB #$8C,TIOS
 MOVB #$0C,OC7M
 MOVB #$0C,OC7D
 MOVB #$A0,TCTL2
 MOVB #$05,TCTL4 ; trig count dans les front montant
 MOVW #$BB8,TC2 ;3000
 MOVW #$BB8,TC3 ;3000
 MOVW #$9C40,TC7 ;40 000
 MOVB #$03, TIE ; IC0 et IC1 en interruption
 MOVB #$80,TSCR1 ; Derni?re initialisation et d?but des pulses

 RTS


;************************************************************************
;**
;* ROUTINE initPushButton
;* Cette routine permet d'initialiser le port P pour les boutton poussoir
;**
;************************************************************************

; Diagramme de connection push button
;	5V ---- PPSP ---- 470Ohm ---- PERP ---- PORTP --+-- PushButton ---- Gnd
initPushButton:	; initialisation du registre PTP, pour le polling du push-button
		BCLR	DDRP,$00		; mode 0 - mode read
		BSET	PERP,$FF		; mode 1 - either pullup or pulldown
		MOVB	#$00,PPSP		; mode 0 - mode pull up
		MOVB    #$15,PIFP       ; set the flag for the interrup on PP1
		MOVB    #$15,PIEP       ; enable the interrupt on PP1
		NOP
		NOP
		NOP
		rts

;*************************************************************************
;**
;*ROUTINE D'INTERRUPTION
;**
;*************************************************************************

;*************************************************************************
;**
;* ROUTINE DECISION
;* Fonction qui regarde ou elle se trouve et prends action en cons?quence
;* Cette routine est appel? a toutes les 20 ms
;**
;*************************************************************************

      DECISION:
          ;JSR initPortLCD
          MOVB #$01,TFLG1

          LDAA ETATS
          CMPA #$01
          BEQ  ACC
          CMPA #$02
          BEQ  ARR
          CMPA #$04
          BEQ  MAV
          CMPA #$08
          BEQ  MAR
          CMPA #$10
          BEQ  BDR
          CMPA #$20
          BEQ  BGA
          CMPA #$40
          BEQ  ETAL

      ACC:
          ;LAB2C
          BRA FOW

      ARR:
          MOVW #3000,TC2
          MOVW #3000,TC3
          BRA END_DEC

      MAV:
          MOVW #3150,TC3
          MOVW #2850,TC2
          BRA END_DEC

      MAR:
          MOVW #2950,TC3
          MOVW #3050,TC2
          DEC COMPTARR
          BEQ BRAC
          BRA END_DEC

      BDR:
          DEC COMPTBRA
          BEQ FOW
          ;LDAB    COMPTBRA
          ;JSR     LCD2hex
          MOVW   #3000,TC3
          MOVW   #2945,TC2
          BRA END_DEC

      BGA:
          DEC COMPTBRA
          BEQ FOW
         ; LDAB    COMPTBRA
         ; JSR     LCD2hex
          MOVW   #3055,TC3
          MOVW   #3000,TC2
          BRA END_DEC

      ETAL:
           ;A FAIRE
           BRA END_DEC

      FOW: MOVB #$04,ETATS
           BRA END_DEC

      BRAC: MOVB #$20,ETATS

      END_DEC: RTI




      INCLUDE 'LCDhex.ASM'
      INCLUDE 'D_BUG12M.ASM'


     ;************************************************************************
     ;*																		*
     ;*Vecteur Interuption des routines et du reset							*
     ;*																		*
     ;************************************************************************

      ORG $FFD6
      fdb DECISION ;fonction interupt

      ORG $FFFE
      fdb Entry ;Reset


      END ; fin de compilation
