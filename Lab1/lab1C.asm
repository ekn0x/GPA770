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

RAMPUP:		MACRO
			
			
			
			ENDM

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


VDiff	DS.W	1			; Variable custom 

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
		BPL		Fold		; Test sur le flag Negatif est a 0
		
		LDD		#Arret		; Faire la soustraction inverse
		SUBD	VCst		
				
Fold:
		LDX		#10			; Definir le nombre de step
		IDIV				; Diviser Registre D par registre X
		STX		DeltaV		; Enregistre la valeur de DeltaV dans la RAM
		
	; Fin de calcul
		rts
		
Profil:		; Écrire les valeurs du profil de vitesse dans les tableaux
		
		rts

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
