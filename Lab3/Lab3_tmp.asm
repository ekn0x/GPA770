;*************************************************************************
;* *
;* Auteur : Samuel Fortin
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
 ABSENTRY lab_2c; point d’entrée pour adressage absolu
 nolist ; Désactiver l’insertion de texte dans le
; fichier .LST
 INCLUDE 'mc9s12c32.inc' ; Inclusion du fichier d’identification des
; registres
 INCLUDE 'D_BUG12M.MAC'
; Réactiver l’insertion de texte dans le
 list ; fichier .LST
;Adresse absolue pour le début du programme et des constantes
ROMStart EQU $4000 
 
  
 ORG RAMStart
 
;************************************************************************
;**
;* VARIABLE
;**
;************************************************************************

VConstante: ds.w 1		;constante de vitesse
TTotal: ds.w 1				;Temps total
TA: ds.w 1						;Temps partiel A
TC: ds.w 1						;Temps partiel C
DELTAV: ds.w 1				;Grandeur de saut de vitesse par temps
VMD: ds.w 30					;Vitesse du moteur de droite
VMG: ds.w 30					;Vitesse du moteur de gauche 
COMPT: ds.b 1		     	;Compteur pour les boucles pour créer les tableaux
COMPT2: ds.b 2			   ;Compteur pour afficher	
COMPT3: ds.b 1         ;Compt interreuption /pulse
FLAG_MESSAGE: ds.b 1   ;Affiche le message
ADRESSE_TEMPX: ds.w 1  ;Affiche le message
ADRESSE_TEMPY: ds.w 1  ;Affiche le message

;**********************************DÉBUT VARIABLE DU PROJET***************

ETATS: ds.b 1							;Sélectionne les états
COMPT_BGA: ds.b 1					;Compte le nombre de tick pour gauche
COMPT_BDR: ds.b 1					;Compte le nombre de tick pour droit
COMPT_MAR: ds.b 1
Flag_Toggle: ds.b 1        ; Flag pour le toggle du bouton
 
;*************************************************************************
;* *
;* Début du code dans la section CODE SECTION *
;* *
;*************************************************************************

 ORG ROMStart
 lab_2c:
 lds #$1000
 
 ;Table_angle dc.w 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
 
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
;INIT: Arr =1

 MOVB #$02,ETATS
 JSR INIT_PULSE
 JSR initPushButton
;Activer interuption
 CLI
 Main: ;Boucle principale qui regarde les états et attends les interruptions
 
 LDAA ETATS
 CMPA #$01
 BEQ  Acc
 CMPA #$02
 BEQ  Arr														  
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
 ;compare avec mask, va a 
 
 Acc:  ;section d'accélération (1)
 
 BRA  Main
 Arr: ;Section d'arrêt  (2)
 MOVW #3000,TC3
 MOVW #3000,TC2

 BRA  Main
 MAV: ;Section marche avant (4)
 MOVW #3150,TC3
 MOVW #2850,TC2

 BRA  Main
 MAR: ;Section marche arrière (8)
 
 BRA  Main
 BDR:	 ;Section braquage droit (10h)
 
 BRA  Main
 BGA:	 ;Section brquage gauche (20h)
 JSR braq_court
 BRA Main
 
 ETAL: ;Section étalonnage (40h)
  
 BRA Main
 
;*************************************************************************
;**
;* SECTION DES ROUTINES
;**
;************************************************************************* 

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

 ;ALEXIS LAGUEUX
 braq_court: 
 
 
 ;aller copier le nombre de tick du braquage dans Y , X
 
 ;inverser les commande moteurs
 
 ;boucler pour nombre de tick
 
 ;fin du virage

 RTS
;************************************************************************
;**
;* ROUTINE CREE_TAB
;* Création du tableau de sous vitesse
;**
;************************************************************************
 CREE_TAB:
 MOVW #3200,TTotal ;Le temps pour faire le profil est de 15s
 MOVW #3200,VConstante ; le moteur doit allez a 3200 
  
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
;* Fonction qui remplir les tableau de vitesse des moteurs en fonction 
;* du temps 
;** 
;*************************************************************************

 PROFIL:
 

;Initialisation boucle 1:
		
 MOVB #10,COMPT ;On met 10 dans compteur pour faire 10 boucle
 LDD #3000			;Initialisation de la première entré du tableau


;boucle 1 : Monter de vitesse du moteur de gauche
 		
 BOUCLE1: ADDD 0,x ;Départ de la boucle et adition des valeurs précédente avec x
 
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
 
 RTI 
 
;*************************************************************************
;**
;* ROUTINE INT_AFFICHE_TEMPS
;* Fonction qui compte le temps. Active un drapeau pour l'affichage 
;* Au seconde.
;* L'interruption ce fait normalement aux 50ms
;**
;*************************************************************************  
 INT_AFFICHE_TEMPS:	
 
;Acquittement de l'interruption

 MOVB #$02,TFLG1

;Vérification si une secondes d'écouler
;Si une seconde est passée, activer le drapeau de rafraichissement du temps
;Et remettre le compteur d'interruption a 0.
 
 LDAB COMPT3
 CMPB #050 
 ;BNE flag_up 
 MOVB #$01,FLAG_MESSAGE
 MOVB #$00,COMPT3
 
;Incrémenter le compteur de secondes

 INC COMPT2
 
 RTI
 
 
 ;*************************************************************************
;**
;* ROUTINE INT_AFFICHE_TEMPS
;* Fonction qui compte le temps. Active un drapeau pour l'affichage 
;* Au seconde.
;* L'interruption ce fait normalement aux 50ms
;**
;*************************************************************************  
TOGGLE_PP0:	
       LDAA    SCISR1	        ; lecture du SCI Status Register 1
       LDAA    SCIDRL         ; lecture du SCI Status Register 1
       LDAA ETATS
       CMPA #$02
       BEQ  CARR
   		 MOVB #$02,ETATS
       BRA T_out
CARR:	 MOVB #$04,ETATS
T_out: MOVB    #$02,PIFP       ; Aquitter l'interruption
       NOP
       NOP
       NOP
       NOP
       NOP
       RTI
 
;*************************************************************************
;**
;* Liste des message utiliser dans le programme 
;* $0A = descendre le curseur d’une ligne
;* $0D = retourner le curseur à la colonne 0
;* $00 = fin de texte pour la fonction printf
;**
;*************************************************************************
 		 
Message0: dc.b $0A,$0D,$00
Message1: dc.b 'Temps : ',$00
Message2: dc.b ' secondes ',$0A,$0D,$00
 
 	  	 
;Fin du code lab_2c

 INCLUDE 'D_BUG12M.ASM'

 
;************************************************************************
;**
;*Vecteur Interuption des routines et du reset
;**
;************************************************************************

 ;interrupt compteur temps IC1
 
 ORG $FFEC 
 fdb INT_AFFICHE_TEMPS ;fonction interupt 
 
 ;interrupt compteur pulse IC0
 
 ORG $FFEE 
 fdb INT_COMPT ;fonction interupt 
 
 ORG $FFFE
 fdb lab_2c ;Reset
 
 ORG $FF8E
 fdb TOGGLE_PP0
 

 END ; fin de compilation
