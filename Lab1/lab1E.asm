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
            INCLUDE 'D_BUG12M.mac'

            list

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; code section
            ORG   ROMStart


Entry:
            CLI                   	; enable interrupts
            LDS #$1000 ; initialisation de la pileau haut
                       ; de ls RAM ($0800-$0FFF)
                       
            ;*************************************************************************
            ;
            ;Init portb en sortie

             LDAB #$ff ; 1 = sortie
             STAB DDRB
             
            ;*************************************************************************
            ;
            ; Init du SCI (transmetteur et récepteur de caractères sériel)
             CLR SCIBDH
             LDAB #$34 ; si bus clk est à 8MHz
             STAB SCIBDL ; 9600 BAUDS
             CLR SCICR1 ; M BIT = 0 POUR 8 BITS
             LDAB #$0C
             STAB SCICR2 ; TE , RE

            ;*************************************************************************
            
            ; Demande a l'utilisateur de la vitesse et du temps
            JSR     GetVitesse
            JSR     GetTemps
            
            ; Phase de calcul
            LDD     TTotal
            LDY     VCst
			JSR		Calcul

            ; Construction du profil
			LDY		#VMD
			LDX		#DeltaV
			JSR		Profil

			; affichage du profil de vitesse
			LDX		#VMD
        	LDY		#VMG
            JSR		PrintProfil	; essai de la fonction
            
            

			BRN		Entry
			
;**************************************************************
;*                          Pentes                            *
;* NAME:        DC.B    Pts1, Pts2, Pent2, Pente2             *
;**************************************************************
; Right
R_VERY_STRONG:  DC.B    $B0, $FF, $10, $00
R_STRONG:       DC.B    $90, $C0, $10, $10
R_MEDIUM:       DC.B    $60, $A0, $10, $10
R_WEAK:         DC.B    $40, $70, $10, $10
R_VERY_WEAK:    DC.B    $00, $50, $00, $10
; Center
C_VERY_STRONG:  DC.B    $B0, $FF, $10, $00
C_STRONG:       DC.B    $90, $C0, $10, $10
C_MEDIUM:       DC.B    $60, $A0, $10, $10
C_WEAK:         DC.B    $40, $70, $10, $10
C_VERY_WEAK:    DC.B    $00, $50, $00, $10
; Left
L_VERY_STRONG:  DC.B    $B0, $FF, $10, $00
L_STRONG:       DC.B    $90, $C0, $10, $10
L_MEDIUM:       DC.B    $60, $A0, $10, $10
L_WEAK:         DC.B    $40, $70, $10, $10
L_VERY_WEAK:    DC.B    $00, $50, $00, $10

;**************************************************************
;*                          Rules                             *
;* NAME:        DC.B    Pts1, Pts2, Pent2, Pente2             *
;**************************************************************

;*************************************************************************
;* 																		 *
;* Inclusion du fichier D_BUG12M.ASM 									 *
;* 																		 *
;*************************************************************************
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
											; fonctions D_BUG12

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
