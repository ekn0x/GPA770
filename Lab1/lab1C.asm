		ORG		RAMSTART
VCst:	DS.W	1
TTotal:	DS.W	1
TA:		DS.W	1
TC:		DS.W	1
DeltaV:	DS.W	1			; 
VMD:	DS.W	30			; Vitesse moteur droit
VMG:	DS.W	30			; Vitesse moteur gauche
COMPT:  DS.B    1

Avance:	EQU		3200		; Vitesse maximale d'avancement
Arret:	EQU		3000		; Valeurs d'arrêt
Recule:	EQU		2800		; Vitesse maximale de recule

;	Functions
Calcul:		; Calculer DeltaV, TA, TC
		PSHY				; Mettre sur la stack le registre Y

	; Calcul de TA
		LDX		#05			; Mettre 5 decimal dans le registre X
		IDIV				; Diviser registre D par registre X
		STX		TA			; Enregistre la valeur de TA dans la RAM
	
	; Calcul de TC
		LDD		TA			; Mettre dans le registre D, la valeur de TA
		LDY 	#04			; Mettre 4 decimal dans le registre Y
		EMUL				; Multiplier registre D par registre Y
		STD		TC			; Calcul de TC

	; Calcul de DeltaV
		PULD				; Ramener la vitesse constante
		SUBD	#Arret		; Soustraire la valeur decimale 3000 au registre D
		LDX		#10			; 
		IDIV				; Diviser Registre D par registre X
		STX		DeltaV		; Enregistre la valeur de DeltaV dans la RAM

		rts					; Retour de la fonction.
		
Profil:		; Écrire les valeurs du profil de vitesse dans les tableaux
		PSHY				; Move to stack VMD
		; X Register: VMG 3000, 2800
		
		MOVB	#10,CMPT 	; Assignation de 10 dans le compteur
		LDD		#Arret		; Mettre dans le registre D, la valeur d'arret
		CLRB				; B = 0
		
		; Dans cette fonction, le registre D sert de stackeur pour evaluer la vitesse
		; Le registre X sers de pointeur sur la vitesse
		; Le registre B sert de comparateur pour savoir quand la loop est terminer		
		
ACC:	; Remplir profil acceleration
	; Operation
		SUBD	DeltaV		; Add DeltaV to D register
		STD		2,X+		; Stock la valeur du registre D a l'addr pointer par le registre X, puis incrementer de 16bit
		DEC 	COMPT		; decrement compteur
		BNE 	ACC			; COMPT != 0
	
	; Remplir profil constante
	
	
	; Remplir porfil decceleration
	
	
		rts

; 	Program
		ORG		ROMSTART		

		LDD		TTotal
		LDY		VCst
		JSR		Calcul
		
		LDY		#VMD
		LDX		#VMG
		JSR		Profil
