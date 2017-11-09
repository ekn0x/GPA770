;**************************************************************
;	Speed profile
;**************************************************************

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
		SUBD	#Neutre		; Soustraire la valeur decimale 3000 au registre D
		LDX		#10			;
		IDIV				; Diviser Registre D par registre X
		STX		DeltaV		; Enregistre la valeur de DeltaV dans la RAM

	; Fin de calcul
		rts

Profil:		; ?crire les valeurs du profil de vitesse dans les tableaux
		;	ramp down
		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
		LDD		#Neutre		; Charger la valeur neutre dans le registre D

RampUD:
		ADDD	X
		STD		2,Y+		; Enregistrer le registre D et decaler l'addr du registre Y
		DEC 	COMPT		; decrement compteur
		BNE 	RampUD

		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
ConstD:
		STD		2,Y+
		DEC 	COMPT		; decrement compteur
		BNE 	ConstD

		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
RampDD:
		SUBD	X
		STD		2,Y+
		DEC 	COMPT		; decrement compteur
		BNE 	RampDD

		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
RampDG:
		SUBD	X
		STD		2,Y+
		DEC 	COMPT		; decrement compteur
		BNE 	RampDG

		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
ConstG:
		STD		2,Y+
		DEC 	COMPT		; decrement compteur
		BNE 	ConstG

		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
RampUG:
		ADDD	X
		STD		2,Y+
		DEC 	COMPT		; decrement compteur
		BNE 	RampUG

		rts
