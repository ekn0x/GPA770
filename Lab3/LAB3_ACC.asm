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
; Point d’entrée du programme
 ABSENTRY Entry; point d’entrée pour adressage absolu
 nolist ; Désactiver l’insertion de texte dans le
; fichier .LST
 INCLUDE 'mc9s12c32.inc' ; Inclusion du fichier d’identification des
; registres
 INCLUDE 'D_BUG12M.MAC'
; Réactiver l’insertion de texte dans le
 list ; fichier .LST
;Adresse absolue pour le début du programme et des constantes
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
 

VConstante:      DS.W 1  ; Constante de vitesse
TTotal:          DS.W 1  ; Temps total
TA:              DS.W 1  ; Temps partiel A
TC:              DS.W 1  ; Temps partiel C
DELTAV:          DS.W 1  ; Grandeur de saut de vitesse par temps
VMD:             DS.W 30 ; Vitesse du moteur de droite
VMG:             DS.W 30 ; Vitesse du moteur de gauche 
COMPT:           DS.B 1  ; Compteur pour les boucles pour créer les tableaux
COMPT2:          DS.B 2  ; Compteur pour afficher	
COMPT3:          DS.B 1  ; Compt interruption /pulse
COMPTBRA:        DS.B 1  ; Compt le nombre de ticks durant le braquage
FLAG_MESSAGE:    DS.B 1  ; Affiche le message
ADRESSE_TEMPX:   DS.W 1  ; Affiche le message
ADRESSE_TEMPY:   DS.W 1  ; Affiche le message
COMPTARR         DS.B 1  ; Compteur marche arrière


;**********************************DÉBUT VARIABLE DU PROJET***************

ETATS:           DS.B 1	 ;Sélectionne les états
COMPT_BGA:       DS.B 1	 ;Compte le nombre de tick pour gauche
COMPT_BDR:       DS.B 1  ;Compte le nombre de tick pour droit
COMPT_MAR:       DS.B 1
Flag_Toggle:     DS.B 1  ; Flag pour le toggle du bouton

;************************************************************************
;**
;* Constante
;**
;************************************************************************

 ORG ROMStart
 
 
 
ANGLES:          DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1 	        ;address va de #$10 à #$78
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
                 DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1           ;address termine de #$88 à #$F0
                
                              
;*************************************************************************
;* *
;* Début du code dans la section CODE SECTION *
;* *
;*************************************************************************

                
  Entry:
  lds #$1000              
;*************************************************************************
;**
;* Initialisation du SCI (transmetteur et récepteur de caractères sériel)
;**
;*************************************************************************
 CLR SCIBDH
 LDAB #$34 ; si bus clk est à 8MHz
 STAB SCIBDL ; 9600 BAUDS
 CLR SCICR1 ; M BIT = 0 POUR 8 BITS
 LDAB #$0C
 STAB SCICR2 ; TE , RE

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
;INIT: ARR =1

 MOVB #$02,ETATS
 JSR CREE_TAB	   				  ;****
 JSR INIT_PULSE
 JSR initPushButton
 JSR initPortLCD
;Activer interuption
 CLI
 
 MOVB #$00,SF_ADROITE
 MOVB #$00,SF_AVANT
 MOVB #$00,SF_AGAUCHE


MAIN:
    LDAA ETATS
    CMPA #$02
    BEQ MAIN    
    JSR FINAL
    JSR afficherResultats  ;transformer pour LCD et non pas comm serie    
    JSR FUZZI
    JSR BRAQ
    LDY #15
    JSR DELAI 
    BRA MAIN
    
            

            
;*************************************************************************
;**
;* SECTION DES ROUTINES
;**
;************************************************************************* 

;*************************************************************************
;**
;* ROUTINE BRAQ
;* Cette routine permet de savoir a combien le conteur pour le braquage
;* doit être initialisé
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
;* ROUTINE FINAL
;* Cette routine permet de convertire le signal analogique des capteurs 
;* IR en numérique
;**
;************************************************************************* 


FINAL:      MOVB	#$91,ATDCTL5            	; début de conversion justifiée à droite, multiple, à partir du 
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
;* Cette routine permet d'initialiser l'écran LCD
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
Boucle1:DEX 		    ; décrémente X
		BNE 	Boucle1	; boucle interne
		DEY 		    ; décrémente Y
		BNE 	Boucle2	; boucle externe
		RTS 		    ; retour de la sous-routine
		

;*************************************************************************
;**
;* ROUTINE afficherResultats
;* Cette routine permet d'afficher les valeurs des capteurs sur l'écran
;* LCD
;**
;************************************************************************* 

afficherResultats:            
            JSR initPortLCD
              
            LDAB    Vcapt_gauche  ;Mettre la valeur de 'VCAPT_GAUCHE' dans 'B'
           ; JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
           ; AFFLCD  ':',2,$05
            LDAB    Vcapt_centre  ;Mettre la valeur de 'VCAPT_CENTRE' dans 'B'
           ; JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
           ; AFFLCD  ':',2,$05
            LDAB    Vcapt_droit   ;Mettre la valeur de 'VCAPT_DROIT' dans 'B'
           ; JSR     LCD2hex       ;Appel de la routine 'LCD2hex' pour affiche 'B'
            
            rts
;*************************************************************************
;**
;* ROUTINE INIT_PULSE
;* Cette routine permet d'initialiser les pulses contrôlants les moteur
;* Elle initialise aussi les entrées pour les interruptions reliées
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
 MOVB #$80,TSCR1 ; Dernière initialisation et début des pulses
 
 RTS	

 
;************************************************************************
;**
;* ROUTINE CREE_TAB
;* Création du tableau de sous vitesse
;**
;************************************************************************

 CREE_TAB:
 MOVW #3200,TTotal ;Le temps pour faire le profil est de 30s
 MOVW #3150,VConstante ; le moteur doit allez a 3200 		  ;****
  
;Preparation pour le transfert a la sous routine  
  
 LDD TTotal
 LDY VConstante
 
;Calcul du profil

 JSR CALCUL ;Sous fonction de calcul
 
;Création du tableau

 LDY #VMD
 LDX #DELTAV
 JSR PROFIL ; Sous fonction de tableau
 
 LDY #VMD ; adresse tableau droit dans X
 LDX #VMG ;adresse  tableau gauche dans y

;stockage des adresse Y et X dans des variables dédiées
 
 STY ADRESSE_TEMPY 
 STX ADRESSE_TEMPX
 
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
;* ROUTINE CALCUL
;* Fonction qui calcul l'accélération et la décélération  
;**
;*************************************************************************

 CALCUL:
 
;Mettre dans la pile les valeurs de Vcontante et TTotal
;Afin de pouvoir les retiré au bon moment

 PSHY  
 PSHD  
 		  
;Calcul de la valeur de temps TA
;Ajout de la decimal 5 dans x afin de faire une division
;de Ttotal/5 puis on stock le resultat dans TA

 LDX #5 
 IDIV
 STX TA 
 			
;Calcul de la valeur de temps TC
;On retire la valeur de TTotal de la pile et on la met dans D afin
;de faire une soustration entre le TTotal et le TA
;Puis on met la valeur dans TC

 PULD
 SUBD TA
 STD TC
 			
;Calcul pour deltaV
;On retire la valeur de VConstante de la pile et on la met dans D, 
;On soustrait alors la valeur de VConstante par 3000 puis on divise le 
;resultat par 10 qui à été insérer dans x, finalement on place le resultat
;dans DELTAV
 			
 PULD 
 SUBD #3000
 LDX #10
 IDIV
 STX DELTAV
 
 RTS
 
;*************************************************************************
;**
;* ROUTINE PROFIL
;* Fonction qui rempli les tableau de vitesse des moteurs en fonction 
;* du temps 
;** 
;*************************************************************************

 PROFIL:
 

;Initialisation boucle 1:
		
 MOVB #10,COMPT ;On met 10 dans compteur pour faire 10 boucle
 LDD #3000			;Initialisation de la première entré du tableau


;boucle 1 : Monter de vitesse du moteur de gauche
 		
 BOUCLE1: ADDD 0,x ;Départ de la boucle et addition des valeurs précédente avec x
 
 STD 2,y+          ;Storage du résultat dans 2 espace puis décalage
    
 DEC COMPT			   ;Décrémentation du compteur
 BNE BOUCLE1		   ;Vérification de l'état actuel du compteur
 		

;Initialisation de la boucle 2	
	
 MOVB #10,COMPT
   
;boucle 2 : Maintient de la vitesse du moteur de gauche 
		
 BOUCLE2: ;Inscrit 10 fois la même valeur
 
 STD 2,y+ 
    
 DEC COMPT
 BNE BOUCLE2
 		
;Initialisation de la boucle 3

 MOVB #10,COMPT

;boucle 3 : Décrémentation de la vitesse du moteur de gauche
  		
 BOUCLE3: SUBD 0,x		;Soustraction des valeurs précédentes avec x
 
 STD 2,y+ 
    
 DEC COMPT
 BNE BOUCLE3
 		
 	 		 
 	 		 
;Initialisation de la boucle 4
	
 MOVB #10,COMPT
   
;boucle 4 : Décrémentation de la vitesse du moteur de gauche 

 BOUCLE4: SUBD 0,x
 
 STD 2,y+ 
    
 DEC COMPT
 BNE BOUCLE4
 		
 
	  
;Initialisation de la boucle 5	
 
 MOVB #10,COMPT
   
;boucle 5 : Maintient de la vitesse du moteur de gauche
 		
 BOUCLE5:
 
 STD 2,y+ 
    
 DEC COMPT
 BNE BOUCLE5
 		
 
;Initialisation de la boucle 6
 MOVB #10,COMPT

;boucle 6 : Accélération de la vitesse du moteur de gauche
  		
 BOUCLE6: ADDD 0,x
 
 STD 2,y+ 
    
 DEC COMPT
 BNE BOUCLE6 		 
 RTS	
 
 

  
;*************************************************************************
;**
;*ROUTINE D'INTERRUPTION
;**
;*************************************************************************  



;*************************************************************************
;**
;* ROUTINE DECISION
;* Fonction qui regarde ou elle se trouve et prends action en conséquence
;* Cette routine est appelé a toutes les 20 ms 
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
    LBEQ  BGA
    CMPA #$40
    LBEQ  ETAL
    
ACC: ;**** all of it inside ****;
    ;Incrémentation du compteur d'interruptions (COMPT3)
    INC COMPT3
 
    ;Début adressage et changement de valeur
  ;   LDD 		ADRESSE_TEMPY
  ;   SUBD #60
  ;   CPD #VMD
  ;   BHS suite

    ;A 0,5s ou a 1s, ajuster la vitesse
    ;Remise a zéro du compteur après 1S dans une autre interruption
     
     LDAB COMPT3
     CMPB #25 ;0.5S
     BEQ Tableau_Vitesse
     CMPB #50 ;1S
     BEQ Tableau_Vitesse

     BRA suite

    ; Ajustement de la vitesse
     
     Tableau_Vitesse:
     
    ;Remettre les valeurs des adresses de moteurs dans X et Y
     
     LDX ADRESSE_TEMPX
     LDY ADRESSE_TEMPY

    ;Incrémenter les adresse pour la nouvelles vitesse
     
     MOVW 2,x+,TC2
     MOVW 2,y+,TC3


    ;Mémoriser la nouvelle adresse dans X et Y
     
     STX ADRESSE_TEMPX
     STY ADRESSE_TEMPY 
     
     suite: 
     
    LDX TC2
    CPX #3150
    BEQ FOW 
    BRA END_DEC					 

    
ARR:
    ;arrêt roue
    MOVW #3000,TC2
    MOVW #3000,TC3 
    ;Remise a l'état initial des accélérations
    MOVW #VMD,ADRESSE_TEMPX	 ;*****
    MOVW #VMG,ADRESSE_TEMPY  ;*****  
    BRA END_DEC
    
MAV:
    ;MOVW #3150,TC3
    ;MOVW #2850,TC2 
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


;*************************************************************************
;**
;* ROUTINE INT_COMPT
;* Fonction qui compte le nombre d'interruption
;* Change la vitesse du moteurs au 0,5S 
;* L'interruption ce fait normalement aux 20ms
;**
;*************************************************************************

 INT_COMPT:
 
;Acquittement de l'interruption 

 MOVB #$01,TFLG1 

;Incrémentation du compteur d'interruptions (COMPT3)
 INC COMPT3
 
;Début adressage et changement de valeur
 LDD 		ADRESSE_TEMPY
 SUBD #60
 CPD #VMD
 BHS suite

;A 0,5s ou a 1s, ajuster la vitesse
;Remise a zéro du compteur après 1S dans une autre interruption
 
 LDAB COMPT3
 CMPB #25 ;0.5S
 BEQ ACCTableau_Vitesse
 CMPB #50 ;1S
 BEQ ACCTableau_Vitesse

 BRA ACCsuite

; Ajustement de la vitesse
 
 ACCTableau_Vitesse:
 
;Remettre les valeurs des adresses de moteurs dans X et Y
 
 LDX ADRESSE_TEMPX
 LDY ADRESSE_TEMPY

;Incrémenter les adresse pour la nouvelles vitesse
 
 MOVW 2,x+,TC2
 MOVW 2,y+,TC3


;Mémoriser la nouvelle adresse dans X et Y
 
 STX ADRESSE_TEMPX
 STY ADRESSE_TEMPY 
 
 ACCsuite: 
 
 RTI 
 
;*************************************************************************
;**
;* ROUTINE INT_AFFICHE_TEMPS
;* Fonction qui compte le temps. Active un drapeau pour l'affichage 
;* Au seconde.
;* L'interruption ce fait normalement aux 50ms
;**
;*************************************************************************  
 INT_AFFICHE_TEMPS:							 ;****TOUT SON CONTENU****
 
;Acquittement de l'interruption

 MOVB #$02,TFLG1

;Vérification si une secondes d'écouler
;si oui, remettre le compteur d'interruption a 0.
 
 LDAB COMPT3
 CMPB #050 									
 BEQ CLR_COMPT3								
 BRA SUITE_AFFICHE					
 
 CLR_COMPT3:
 MOVB #$00,COMPT3
 
 
 SUITE_AFFICHE:
 RTI
 
 
;*************************************************************************
;*																		 *
;* ROUTINE TOGGLE_PP0										        	 *
;* Routine pour le bouton d'arrêt d'urgence;							 *
;*  verfifé si le bouton est pesé										 *
;*																		 *
;*************************************************************************  
TOGGLE_PP0:	
	  
	   BRSET    PIFP,#1,MARARR
	   BRSET    PIFP,#2,INT_PARECHOC    ;A CHANGER POUR ETALONAGE
	   BRSET    PIFP,#4,INT_PARECHOC
	   BRSET    PIFP,#8,INT_PARECHOC
	   BRA  END_PP0
        
MARARR:
       	
       LDAA     SCISR1	        ; lecture du SCI Status Register 1
       LDAA     SCIDRL         ; lecture du SCI Status Register 1
       LDAA     ETATS
       CMPA     #$02
       BEQ      CARR
   	   MOVB     #$02,ETATS
       BRA      T_out
CARR:  MOVB     #$01,ETATS  ;****
T_out: MOVB     #01,PIFP       ; Aquitter l'interruption
	   LDY      #10				; On fais un delai d'une demi-seconde		   (ANTOINE, MICHAEL)
	   JSR      DELAI																   ;(ANTOINE, MICHAEL)
	   BRSET    PIFP,#01,T_out ; Vérifie si le flag est à 1, sinon on refait l'interruption    (ANTOINE, MICHAEL)
	      
       BRA  END_PP0
       
       
END_PP0: RTI
 
;*************************************************************************
;*																		 *
;* ROUTINE INT_AFFICHE_TEMPS											 *
;* Routine pour le bouton d'arrêt d'urgence;							 *
;*  verfifé si le bouton est pesé										 *
;*																		 *
;*************************************************************************   
 INT_PARECHOC:
        
        MOVB  #50, COMPTARR        
        MOVB  #8, ETATS
        
        MOVB  #14, PIFP 
	   	
        RTI
        
;*************************************************************************
;*																		 *
;* Liste des message utiliser dans le programme 						 *
;* $0A = descendre le curseur d’une ligne								 *
;* $0D = retourner le curseur à la colonne 0							 *
;* $00 = fin de texte pour la fonction printf							 *
;*																		 *
;*************************************************************************
 		 
Message0: dc.b $0A,$0D,$00
Message1: dc.b 'Temps : ',$00
Message2: dc.b ' secondes ',$0A,$0D,$00
 
 	  	 
;Fin du code lab_2c



;Code lab2d	  Fuzzy logique
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

 INCLUDE 'LCDhex.ASM'
 INCLUDE 'D_BUG12M.ASM'

 
;************************************************************************
;*																		*
;*Vecteur Interuption des routines et du reset							*
;*																		*
;************************************************************************

 ;interrupt compteur temps IC1
 
 ORG $FFEC 
 fdb INT_AFFICHE_TEMPS ;fonction interupt 
 
 ;interrupt compteur pulse IC0
 
 ORG $FFEE 
 fdb DECISION ;fonction interupt 
 
 ORG $FFFE
 fdb Entry ;Reset
 
 ORG $FF8E
 fdb TOGGLE_PP0
 

 END ; fin de compilation