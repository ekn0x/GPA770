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

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
VCst:	DS.W	1
TTotal:	DS.W	1
TA:		DS.W	1
TC:		DS.W	1
DeltaV:	DS.W	1			; 
VMD:	DS.W	30			; Vitesse moteur droit
VMG:	DS.W	30			; Vitesse moteur gauche

COMPT	DS.B	1			; Compteur 

Avance:	EQU		3200		; Vitesse maximale d'avancement
Arret:	EQU		3000		; Valeurs d'arrêt
Recule:	EQU		2800		; Vitesse maximale de recule


; code section
            ORG   ROMStart
Entry:
        	CLI                   ; enable interrupts
            
			LDD		TTotal
			LDY		VCst
			JSR		Calcul
			
			LDY		#VMD
			LDX		#VMG
			JSR		Profil
			
			BRA		Entry

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
		
finCalcul:
		rts
		
Profil:		; Écrire les valeurs du profil de vitesse dans les tableaux
		PSHY				; Move to stack VMD
		; X Register: VMG 3000, 2800
		
		MOVB	#10,COMPT 	; Assignation de 10 dans le compteur
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
		MOVB	#10, COMPT
		LDD		#Arret
		LDD		VCst
		CLRB
CST:
		STD		2,X+		; Stock la valeur du registre D a l'addr pointer par le registre X, puis incrementer de 16bit
		DEC 	COMPT		; decrement compteur
		BNE 	CST
		
	
	; Remplir porfil decceleration
		MOVB	#10, COMPT
		LDD		#Arret
		CLRB	
DEC:
	
		rts

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
