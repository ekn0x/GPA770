;*************************************************************************
;* *
;* Auteurs : Samuel Fortin
;           Alexis Lagueux
;           Alexandre Halle-Lamarche
;           Samuel  Murray
;           Antoine Dozois
;           Micheal Gagnon 
;
;* Date :   D�cembre 2017 
;* *									 
;* Ce programme : sert a contr�ller un robot � roulette autonome dans
;* un labyrinthe. Il acquisitionne 3 valeurs de distances par des capteurs
;* infrarouges. Un fuzzy est appliquer aux valeurs afin de v�rifier s'il
;* doit faire un virage. Si une collision arrive a l'avant, deux moustaches
;* servent pour d�clencher une marche arri�re. Les vitesses peuvent �tre
;* calibr� avant de d�marrer
;*************************************************************************

; Point d�entr�e du programme
 ABSENTRY Entry; point d�entr�e pour adressage absolu
 nolist ; D�sactiver l�insertion de texte dans le
; fichier .LST
 INCLUDE 'mc9s12c32.inc' ; Inclusion du fichier d�identification des
; registres
 INCLUDE 'D_BUG12M.MAC'
; R�activer l�insertion de texte dans le
 list ; fichier .LST
;Adresse absolue pour le d�but du programme et des constantes
ROMStart EQU $4000 

;Offset pour les 27 r�gles
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

MARKER    EQU     $FE  ;S�parateur pour les r�gles      
ENDR      EQU     $FF  ;Variable de fin pour les r�gles    

;************************************************************************
;**
;* MACRO
;**
;************************************************************************

;************************************************************************
;**
;* affLCD
;* Cette macro permet d'afficher des information au LCD
;**
;************************************************************************
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

 
;Variables d'entr�es pour la fuzzification
E_D_LOIN:       DS.B    1   
E_D_MIDI:       DS.B    1
E_D_PRES:       DS.B    1
E_C_LOIN:       DS.B    1
E_C_MIDI:       DS.B    1
E_C_PRES:       DS.B    1
E_G_LOIN:       DS.B    1
E_G_MIDI:       DS.B    1
E_G_PRES:       DS.B    1

;Valeur apr�s fuzzification
SORTIE_D:	    DS.B    1	  
SORTIE_C: 		DS.B    1
SORTIE_G: 	    DS.B    1

VCAPT_DROIT:    DS.B    1    ;Valeurs donn�es par le capteur droit
VCAPT_CENTRE:   DS.B    1    ;Valeurs donn�es par le capteur centre
VCAPT_GAUCHE:   DS.B    1    ;Valeurs donn�es par le capteur gauche
COMMANDE:       DS.B    1    ;Valeur de sortie
 

VConstante:      DS.W 1  ; Constante de vitesse
TTotal:          DS.W 1  ; Temps total
TA:              DS.W 1  ; Temps partiel A
TC:              DS.W 1  ; Temps partiel C
DELTAV:          DS.W 1  ; Grandeur de saut de vitesse par temps
VMD:             DS.W 30 ; Vitesse du moteur de droite
VMG:             DS.W 30 ; Vitesse du moteur de gauche 
COMPT:           DS.B 1  ; Compteur pour les boucles pour cr�er les tableaux
COMPT2:          DS.B 2  ; Compteur pour afficher	
COMPT3:          DS.B 1  ; Compt interruption /pulse
COMPTBRA:        DS.B 1  ; Compt le nombre de ticks durant le braquage
FLAG_MESSAGE:    DS.B 1  ; Affiche le message
ADRESSE_TEMPX:   DS.W 1  ; Affiche le message
ADRESSE_TEMPY:   DS.W 1  ; Affiche le message
COMPTARR         DS.W 1  ; Compteur marche arri�re
VITD:            DS.W 1  ; Vitesse moteur droit
VITG:            DS.W 1	 ; Vitesse moteur gauche
INCVITD:         DS.W 1	 ; Incr�menteur droit
INCVITG:         DS.W 1	 ; Incr�menteur gauche
CMPT_VIT:		 DS.B 1	 ; Compteur vitesse
CMPT_ACC:		 DS.B 1	 ; Compteur acc�l�ration
VITDESD:         DS.W 1	 ;
VITDESG:         DS.W 1	 ;

ETATS:           DS.B 1	 ;S�lectionne les �tats
COMPT_BGA:       DS.B 1	 ;Compte le nombre de tick pour gauche
COMPT_BDR:       DS.B 1  ;Compte le nombre de tick pour droit
COMPT_MAR:       DS.B 1	 ;Compte le nombre de tick pour marche arri�re
Flag_Toggle:     DS.B 1  ; Flag pour le toggle du bouton

;************************************************************************
;**
;* Constante
;**
;************************************************************************

 ORG ROMStart
 
 
 
ANGLES:          DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1 	        ;address va de #$10 � #$78
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
                 DC.B    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1           ;address termine de #$88 � #$F0
                
                              
;*************************************************************************
;* *
;* D�but du code dans la section CODE SECTION 
;* *
;*************************************************************************

                
  Entry:
 lds #$1000              
;*************************************************************************
;**
;* Initialisation du SCI (transmetteur et r�cepteur de caract�res s�riel)
;**
;*************************************************************************
 CLR SCIBDH
 LDAB #$34 ; si bus clk est � 8MHz
 STAB SCIBDL ; 9600 BAUDS
 CLR SCICR1 ; M BIT = 0 POUR 8 BITS
 LDAB #$0C
 STAB SCICR2 ; TE , RE

;*************************************************************************
;*  Initialisation du convertisseur N/A
;*  Mode 8 bits non sign�s � droite
;*  Multiple num�risations. Canal 1, 2 et 3
;* 	Vitesse du �sample and hold� � 2 coups d'horloge
;* 	Vitesse de l'horloge de conversion � 2MHz
;*************************************************************************

 movb #$C0,ATDCTL2  ; mise en marche du convertisseur et du AFFC
 movb #$18,ATDCTL3  ; 3 conversions � la fois
 movb #$81,ATDCTL4  ; 8 bits, 2 clocks S/H, 2MHz   
  
;*************************************************************************
;*  Initialisation des variables reli�es aux vitesses
;*************************************************************************

 MOVW #2900, VITDESD
 MOVW #3100, VITDESG
 MOVB #0,CMPT_VIT
 MOVB #0,CMPT_ACC
 MOVW #3000,VITG
 MOVW #3010,VITD
 
;*************************************************************************
;*  Calcul des profils de vitesses
;*************************************************************************
 
 JSR  CALVITD		  
 JSR  CALVITG
 ;Mise a l'�tat initial d'arr�t
 MOVB #$02,ETATS	
 
;*************************************************************************
;* Initialisation du mat�riel. Les pulses, les pouton poussoirs et 
;* le LCD
;************************************************************************* 
    
 JSR INIT_PULSE
 JSR initPushButton
 JSR initPortLCD
;Activer interuption
 CLI
 

;*************************************************************************
;*  Boucle Principale
;*************************************************************************

MAIN:
    ;Si a l'arr�t, attendre de quitter ce mode par interruption
    LDAA ETATS
    CMPA #$02
    BEQ MAIN   
    ;Mesure des capteurs 
    JSR FINAL
    ;Nettoyer l'affichage du LCD
    JSR clearLCD
    ;Afficher les r�sultats au LCD
    JSR afficherResultats   
    ;Calculer si un braquage est n�cessaire 
    JSR FUZZI
    ;Ajustement de la direction
    JSR BRAQ
    ;Petit d�lais de mise a jours et retour au d�but de l'acquisition
    LDY #125
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
;* doit �tre initialis�
;**
;************************************************************************* 

BRAQ: 
    ;mettres les valeurs dans les registre
    LDAB  ANGLES
    LDX  #COMMANDE
    ABX
	MOVW  X,COMPTBRA

    ;D�cision de l'�tat � effectuer
	LDAA ETATS
    CMPA #$02
    BEQ AFF
	LDAA ETATS
    CMPA #$01
    BEQ AFF
	LDAA ETATS
    CMPA #$40
    BEQ AFF
	LDAA ETATS
    CMPA #$08
    BEQ AFF
    LDAA COMMANDE
    CMPA #$A8
    BHI Droite
    CMPA #$58
    BLO Gauche
    MOVB #$04, ETATS
    BRA AFF
    
Gauche: 
    MOVB #$20,ETATS        
    BRA AFF
            
Droite: 
    MOVB #$10,ETATS
AFF:	
    RTS


;*************************************************************************
;**
;* ROUTINE FINAL
;* Cette routine permet de convertire le signal analogique des capteurs 
;* IR en num�rique
;**
;************************************************************************* 


FINAL:  
    MOVB #$91,ATDCTL5            	; d�but de conversion justifi�e � droite, multiple, � partir du 
                                            	; canal 1
                                            	
Attendre:
  	brclr ATDSTAT0,$80,Attendre   ; Attendre la fin des trois conversions (SCF)
    movb  ATDDR2L, VCAPT_GAUCHE 	; sauvegarde des trois voltages des capteurs
    movb  ATDDR1L, VCAPT_CENTRE
    movb  ATDDR0L, VCAPT_DROIT
	RTS
			
;*************************************************************************
;**
;* ROUTINE FUZZI
;* Cette routine permet de faire le calul de logique floue et de touver
;* la commande de braquague
;**
;************************************************************************* 			
			
FUZZI:  
    LDX  #D_LOIN	    ;Le d�but des entr�es utilis� par la fonction MEM
	LDY  #E_D_LOIN      ;Le d�but des valeurs fuzzifi�es
	LDAA VCAPT_DROIT    ;Valeur du capteur droit
	LDAB #3             ;Nombre d'itt�ration
		
LoopD:  
    MEM                 ;Assigner les valeurs au MEM
    DBNE B,LoopD        ;Faire les 3 itt�rations
        
    LDAA VCAPT_CENTRE   ;Valeur du capteur central
    LDAB #3             ;Nombre d'itt�ration
    
LoopC:
    MEM                 ;Assigner les valeurs au MEM
    DBNE B,LoopC        ;Faire les 3 itt�rations
        
    LDAA VCAPT_GAUCHE   ;Valeur du capteur gauche
    LDAB #3             ;Nombre d'itt�ration
    
LoopG:
    MEM                 ;Assigner les valeurs au MEM
    DBNE B,LoopG        ;Faire les 3 itt�rations
        
    ;Remise � z�ro des trois sortie pour la d�fuzzification
    CLR  SORTIE_D
    CLR	 SORTIE_C
    CLR	 SORTIE_G
        
    LDY  #E_D_LOIN
    LDX  #RULE_START    ;D�part des r�gles
        
    LDAA #$FF
        
    REV                 ;�valuer les 27 r�gles
        
    ;D�fuzzification
    LDX  #A_DROITE   ;Le d�but des sorties utilis� par la fonction MEM
    LDY  #SORTIE_D   ;Le d�but des sorties d�fuzzifi�s
    LDAB #$03        ;Faire la somme des 3 sorties
    WAV
    EDIV
    TFR  Y,D         ;Mettre la r�ponse dans D
    STAB COMMANDE    ;Sauvegarder la r�ponse 
    LDAB COMMANDE
    RTS

;*************************************************************************
;**
;* ROUTINE initPortLD
;* Cette routine permet d'initialiser l'�cran LCD
;**
;*************************************************************************       
      
initPortLCD:

	MOVB    #$FF, DDRA      ;Initialiser le PORTA en mode sortie
    MOVB    #$FF, DDRB      ;Initialiser le PORTB en mode sortie

	affLCD  $30, 15, $04    ; reset1
	affLCD  $30, $04, $04   ; reset2			  
	affLCD  $30, $04, $04   ; reset3
	affLCD  $30, $04, $04   ; 1/2 ligne
	affLCD  $08, $04, $04   ; DisplayOff
	affLCD  $01, $04, $04   ; Clear Display
	affLCD  $06, $04, $04   ; Type Curseur
	affLCD  $0E, $04, $04   ; DisplayOn
		
    RTS
        
;*************************************************************************
;**
;* ROUTINE clearLCD
;* Cette routine permet d'�ffacer l'�cran LCD
;**
;*************************************************************************

clearLCD:
	affLCD  $01, $04, $04   ; Clear Display
	affLCD  $02, $04, $04   ; Curseur Home
    RTS
        
DELAI: 
Boucle2:
    LDX 	#5000 	        ; 50,000 fois en boucle interne=25 msec
Boucle1:
    DEX 		            ; d�cr�mente X
	BNE 	Boucle1	        ; boucle interne
	DEY 		            ; d�cr�mente Y
	BNE 	Boucle2	        ; boucle externe
	RTS 		            ; retour de la sous-routine
		

;*************************************************************************
;**
;* ROUTINE afficherResultats
;* Cette routine permet d'afficher les valeurs des capteurs sur l'�cran
;* LCD
;**
;************************************************************************* 

afficherResultats:            
    JSR initPortLCD
              
    LDAB    VCAPT_GAUCHE    ;Mettre la valeur de 'VCAPT_GAUCHE' dans 'B'
    JSR     LCD2hex         ;Appel de la routine 'LCD2hex' pour affiche 'B'
    AFFLCD  ':',2,$05
    LDAB    VCAPT_CENTRE    ;Mettre la valeur de 'VCAPT_CENTRE' dans 'B'
    JSR     LCD2hex         ;Appel de la routine 'LCD2hex' pour affiche 'B'
    AFFLCD  ':',2,$05
    LDAB    VCAPT_DROIT     ;Mettre la valeur de 'VCAPT_DROIT' dans 'B'
    JSR     LCD2hex         ;Appel de la routine 'LCD2hex' pour affiche 'B'
            
    RTS
;*************************************************************************
;**
;* ROUTINE INIT_PULSE
;* Cette routine permet d'initialiser les pulses contr�lants les moteur
;* Elle initialise aussi les entr�es pour les interruptions reli�es
;* Aux pulses
;**
;************************************************************************* 

 INIT_PULSE: 
    MOVB    #$0A,TSCR2 
    MOVB    #$8C,TIOS  
    MOVB    #$0C,OC7M 
    MOVB    #$0C,OC7D
    MOVB    #$A0,TCTL2
    MOVB    #$05,TCTL4      ; trig count dans les front montant
    MOVW    #$BB8,TC2       ;3000 
    MOVW    #$BB8,TC3       ;3000
    MOVW    #$9C40,TC7      ;40 000
    MOVB    #$03, TIE       ; IC0 et IC1 en interruption 
    MOVB    #$80,TSCR1      ; Derni�re initialisation et d�but des pulses
 
 RTS	

 
;************************************************************************
;**
;* ROUTINE CREE_TAB
;* Cr�ation du tableau de sous vitesse
;**
;************************************************************************

 CREE_TAB:
    MOVW    #3200,TTotal    ;Le temps pour faire le profil est de 15s
    MOVW    #3200,VConstante;Le moteur doit allez a 3200 
  
;Preparation pour le transfert a la sous routine  
  
    LDD TTotal
    LDY VConstante
 
;Calcul du profil

    JSR CALCUL              ;Sous fonction de calcul
 
;Cr�ation du tableau

    LDY     #VMD
    LDX     #DELTAV
    JSR     PROFIL          ; Sous fonction de tableau
 
    LDY     #VMD            ; adresse tableau droit dans X
    LDX     #VMG            ; adresse  tableau gauche dans y

;stockage des adresse Y et X dans des variables d�di�es
 
    STY     ADRESSE_TEMPY 
    STX     ADRESSE_TEMPX
 
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
	MOVB    #$1F,PIFP       ; set the flag for the interrup on PP1
	MOVB    #$1F,PIEP       ; enable the interrupt on PP1
	NOP
	NOP
	NOP
	RTS


;*************************************************************************
;**
;* ROUTINE CALCUL
;* Fonction qui calcul l'acc�l�ration et la d�c�l�ration  
;**
;*************************************************************************

 CALCUL:
 
;Mettre dans la pile les valeurs de Vcontante et TTotal
;Afin de pouvoir les retir� au bon moment

    PSHY  
    PSHD  
 		  
;Calcul de la valeur de temps TA
;Ajout de la decimal 5 dans x afin de faire une division
;de Ttotal/5 puis on stock le resultat dans TA

    LDX     #5 
    IDIV
    STX     TA 
 			
;Calcul de la valeur de temps TC
;On retire la valeur de TTotal de la pile et on la met dans D afin
;de faire une soustration entre le TTotal et le TA
;Puis on met la valeur dans TC

    PULD
    SUBD    TA
    STD     TC
 			
;Calcul pour deltaV
;On retire la valeur de VConstante de la pile et on la met dans D, 
;On soustrait alors la valeur de VConstante par 3000 puis on divise le 
;resultat par 10 qui � �t� ins�rer dans x, finalement on place le resultat
;dans DELTAV
 			
    PULD 
    SUBD    #3000
    LDX     #10
    IDIV
    STX     DELTAV
 
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
		
    MOVB    #10,COMPT       ;On met 10 dans compteur pour faire 10 boucle
    LDD     #3000			;Initialisation de la premi�re entr� du tableau


;boucle 1 : Monter de vitesse du moteur de gauche
 		
 BOUCLE1: 
    ADDD    0,x             ;D�part de la boucle et addition 
                            ;des valeurs pr�c�dente avec x
 
    STD     2,y+            ;Storage du r�sultat dans 2 espace puis d�calage
    
    DEC     COMPT			;D�cr�mentation du compteur
    BNE     BOUCLE1		   ;V�rification de l'�tat actuel du compteur
 		

;Initialisation de la boucle 2	
	
    MOVB    #10,COMPT
   
;boucle 2 : Maintient de la vitesse du moteur de gauche 
		
 BOUCLE2: ;Inscrit 10 fois la m�me valeur
 
    STD     2,y+ 
    
    DEC     COMPT
    BNE     BOUCLE2
 		
;Initialisation de la boucle 3

    MOVB    #10,COMPT

;boucle 3 : D�cr�mentation de la vitesse du moteur de gauche
  		
 BOUCLE3: 
    SUBD    0,x		        ;Soustraction des valeurs pr�c�dentes avec x
 
    STD     2,y+ 
    
    DEC     COMPT
    BNE     BOUCLE3
 		
 	 		 
 	 		 
;Initialisation de la boucle 4
	
    MOVB    #10,COMPT
   
;boucle 4 : D�cr�mentation de la vitesse du moteur de gauche 

 BOUCLE4:
    SUBD    0,x
 
    STD     2,y+ 
    
    DEC     COMPT
    BNE     BOUCLE4
 		
 
	  
;Initialisation de la boucle 5	
 
    MOVB    #10,COMPT
   
;boucle 5 : Maintient de la vitesse du moteur de gauche
 		
 BOUCLE5:
 
    STD     2,y+ 
    
    DEC     COMPT
    BNE     BOUCLE5
 		
 
;Initialisation de la boucle 6
    MOVB    #10,COMPT

;boucle 6 : Acc�l�ration de la vitesse du moteur de gauche
  		
 BOUCLE6:
    ADDD    0,x
 
    STD     2,y+ 
    
    DEC     COMPT
    BNE     BOUCLE6 		 
    RTS	
    
;*************************************************************************
;**
;* ROUTINE AFFVIT
;* Fonction qui affiche la vitesse au LCD, utiliser en debug
;** 
;************************************************************************* 

 AFFVIT:
    LDD     VITD
    JSR     clearLCD
    TAB
    JSR     LCD2hex 
    LDD     VITD
    JSR     LCD2hex
    RTS

;*************************************************************************
;**
;* ROUTINE UPCOMPT
;* Fonction qui augmente de 10 la valeur de base du moteurs droit
;** 
;*************************************************************************

UPCOMPT:  
    LDD     VITDESD
    ADDD    #10
    CPD     #3000
    BHS     MAX       
        
    STD     VITDESD
    BRA     ENDUP
        
MAX:
    LDD     #3000
    STD     VITDESD        
        
ENDUP:    
    RTS 
   
;*************************************************************************
;**
;* ROUTINE CALVITD
;* Fonction qui calcul la vitesse et les incr�ments du moteur droit 
;** 
;************************************************************************* 	 


CALVITD:  
    LDD     #3000
    LDX     #20
    SUBD    VITDESD    
    IDIV  
 	STX     INCVITD
 	RTS
 	
;*************************************************************************
;**
;* ROUTINE CALVITG
;* Fonction qui calcul la vitesse et les incr�ments du moteurs gauche 
;** 
;************************************************************************* 	
 		  
CALVITG:
    LDD     VITDESG         
    LDX     #20          
    SUBD    #3000        
    IDIV              
 	STX     INCVITG     
 	RTS
 		  
 		  
;*************************************************************************
;**
;*ROUTINE D'INTERRUPTION
;**
;*************************************************************************  



;*************************************************************************
;**
;* ROUTINE DECISION
;* Fonction qui regarde ou elle se trouve et prends action en cons�quence
;* Cette routine est appel� a toutes les 20 ms 
;**
;*************************************************************************

DECISION:

    MOVB    #$01,TFLG1
    
    LDAA    ETATS
    CMPA    #$01			;Acc�l�ration
    BEQ     ACC
    CMPA    #$02			;Arr�t
    BEQ     ARR														  
    CMPA    #$04			;Marche avant
    BEQ     MAV
    CMPA    #$08			;Marche arri�re
    BEQ     MAR
    CMPA    #$10			;Braquage droit
    BEQ     BDR
    CMPA    #$20			;Braquage gauche
    BEQ     BGA
    CMPA    #$40            ;�tallonage
    BEQ     ETAL
    
ACC:
    LDAA    CMPT_VIT
    CMPA    #20
    BEQ     FOW
    LDAA    CMPT_ACC        ;Mettre le contenu de 'CMPT_VIT' dans 'A'
    CMPA    #10             ;Comparer la valeur de 'A' avec '25' (0.5 sec)
    BHS     VITESSE         ;Si 'A' est plus grand que '25', aller � 'VITESSE'
    INC     CMPT_ACC
    LBRA    END_DEC

ARR:
    MOVW    #3000,TC2		;Arr�t des deux moteurs
    MOVW    #3000,TC3   
    LBRA    END_DEC
    
MAV:
    MOVW    VITG,TC3		;Garde les vitesses de marche avant.
    MOVW    VITD,TC2 
    BRA     END_DEC

MAR:
    MOVW    #2900,TC3		;Permet une marche arri�re
    MOVW    #3100,TC2
    JSR     clearLCD
 
    DEC     COMPTARR		;Compte le nombre de temps restant dans ce mode
    BEQ     BRAC			;Effectue un braquage
    BRA     END_DEC

BDR:
    DEC     COMPTBRA		;Tourne a droite selon le nombre de tick/degr�
    BEQ     FOW				;Pour les vitesses de moteurs suivantes
    MOVW    #3000,TC3
    MOVW    #2945,TC2		
    BRA     END_DEC

BGA:
    DEC     COMPTBRA		;Tourne a gauche selon le nombre de tick/degr�
    BEQ     FOW				;Pour les vitesses de moteurs suivantes
    MOVW    #3055,TC3
    MOVW    #3000,TC2
    BRA     END_DEC

ETAL:
    BRA     END_DEC			;Mode �tallonage
     
FOW: 
    MOVB    #0,CMPT_VIT		;Mise en marche avant
    MOVB    #$04,ETATS
    BRA     END_DEC

VITESSE:  					;Ajustement de la vitesse
    LDD     VITD
    SUBD    INCVITD
    STD     VITD
    LDD     VITG
    ADDD    INCVITG
    STD     VITG
    MOVB    #0,CMPT_ACC
    MOVW    VITG,TC3
    MOVW    VITD,TC2
    INC     CMPT_VIT
    BRA     END_DEC

BRAC: 
    MOVB    #$20,ETATS		;Bracage typique

END_DEC: 
    RTI



 
 
;*************************************************************************
;**
;* ROUTINE INT_AFFICHE_TEMPS
;* Fonction qui compte le temps. Active un drapeau pour l'affichage 
;* Au seconde.
;* L'interruption ce fait normalement aux 50ms
;* Incr�mente certain compteur
;**
;*************************************************************************  
 INT_AFFICHE_TEMPS:	
 
;Acquittement de l'interruption

    MOVB    #$02,TFLG1

;V�rification si une secondes d'�couler
;Si une seconde est pass�e, activer le drapeau de rafraichissement du temps
;Et remettre le compteur d'interruption a 0.
 
    LDAB    COMPT3
    CMPB    #050 
    MOVB    #$01,FLAG_MESSAGE
    MOVB    #$00,COMPT3

    INC     COMPT2
 
    RTI
 
 
;*************************************************************************
;*																		 
;* ROUTINE TOGGLE_PP0											 
;* Routine s�lectionnant les actions lorsqu'on bouton est appuy�. 
;* Selon le mode, ceci permet d'ajuster l'�tallonage, d'arr�ter,
;* d'allez en marche avant ou arri�re 									 
;*																		 
;*************************************************************************  
TOGGLE_PP0:	
	  
	BRSET   PIFP,#1,MARARR
	BRSET   PIFP,#4,INT_PARECHOC
	BRSET   PIFP,#8,INT_PARECHOC
	BRSET   PIFP,#2,ETALONAGE    
	BRA     END_PP0
        
MARARR:
       	
    LDAA    SCISR1	        ; lecture du SCI Status Register 1
    LDAA    SCIDRL          ; lecture du SCI Status Register 1
    LDAA    ETATS
    CMPA    #$02
    BEQ     CARR
   	MOVB    #$02,ETATS
    BRA     T_out
CARR:
    MOVB    #$01,ETATS
T_out: 
    MOVW    #3000,VITD
    MOVW    #3000,VITG
    MOVB    #01,PIFP        ; Aquitter l'interruption
	LDY     #50				; On fais un delai d'une demi-seconde		   
	JSR     DELAI																   
	BRSET   PIFP,#01,T_out  ; V�rifie si le flag est � 1,
	                        ; sinon on refait l'interruption   
	      
    BRA     END_PP0
       
       
END_PP0:

    RTI
 
;*************************************************************************
;*																		 
;* ROUTINE INT_PARECHOC											 
;* Routine pour les cas du PP2 et PP3. En mode �tallonage, utiliser pour
;* Modifier la valeur du moteur droit. Sinon, faire marche arri�re.                         										 
;*																		 
;*************************************************************************   
 INT_PARECHOC:
    LDAA    ETATS
 	CMPA    #$40
 	BEQ     FLAG
        
    LDAA    ETATS
 	CMPA    #$02
 	BEQ     FINPAR
        
    MOVB    #50, COMPTARR        
    MOVB    #8, ETATS
        
    BRA     FINPAR 
         
FLAG:
    BRSET   PIFP,#4,UP

	LDD     VITDESD      
	SUBD    #10
	CPD     #2800
	BLS     MIN
		
	STD     VITDESD
	BRA     FINPAR
		
UP: 
    JSR     UPCOMPT
    BRA     FINPAR
        
MIN:
    LDD     #2800
    STD     VITDESD
    BRA     FINPAR
    
    
;*************************************************************************
;*																		 
;* ROUTINE FINPAR											 
;* Calcul de la vitesse droite 							 										 
;*																		 
;*************************************************************************                               

FINPAR: 
    JSR     CALVITD		  
    MOVB    #14, PIFP			   	
    RTI
;*************************************************************************
;*																		 
;* ROUTINE ETALONAGE											 
;* Routine qui ajuste les commandes aux moteurs selon un d�callage manuel
;* Sur le moteur droit							 
;*  										 
;*																		 
;*************************************************************************  
 ETALONAGE:
    LDAA    ETATS
 	CMPA    #$40
 	BEQ     ARRETL
 		  
 	MOVB    #$40, ETATS
 	BRA     FF
 		  
 ARRETL:
    MOVB     #$02, ETATS
          
 FF:	    
    MOVB     #2, PIFP
    RTI

;Code lab2d	  Fuzzy logique
;*************************************************************************
;*             D�finition des chaine de char                  
;*************************************************************************
str1:	DC.B	'Entr�es : ',$00
str2:	DC.B	'    Vcap_gauche = ',$00
str3:	DC.B	'    Vcap_centre = ',$00
str4:	DC.B	'    Vcap_droite = ',$00
str5:	DC.B	'Sortie = ',$00
CRLF:	DC.B	$0A,$00		


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

;Valeur des trois singletons pour la d�fuzzification
A_DROITE:       dc.b    $F0
DEVANT:         dc.b    $80
A_GAUCHE:       dc.b    $10

;D�finition des 27 r�gles 
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

 
;*************************************************************************
;*																		
;*Vecteur Interuption des routines et du reset							
;*																		
;*************************************************************************

 ;interrupt compteur temps IC1
 
 ORG $FFEC 
 fdb INT_AFFICHE_TEMPS  ;fonction interupt 
 
 ;interrupt compteur pulse IC0
 
 ORG $FFEE 
 fdb DECISION           ;fonction interupt 
 
 ORG $FFFE
 fdb Entry              ;Reset

 ;Interrupt des boutons pressoirs PP0 � PP3 
 ORG $FF8E
 fdb TOGGLE_PP0
 

 END                    ; fin de compilation