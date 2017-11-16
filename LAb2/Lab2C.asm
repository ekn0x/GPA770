;*****************************************************************
;* This is a tempplate for our labs
;*****************************************************************
; export symbols
            XDEF Entry            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point

;**************************************************************
;	include derivative specific macros
;**************************************************************    
            INCLUDE 'mc9s12c32.inc'
            INCLUDE 'D_BUG12M.mac'

            list
;**************************************************************
;	MACROs and DEFINEs
;**************************************************************  

affLCD:     MACRO
			MOVB    #\3, PORTB
			MOVB    #\1, PORTA
			BCLR     PORTB, $04
			LDY     #\2
			JSR     DELAI
			BSET    PORTB, $04
            ENDM
  
ROMStart    EQU  $4000      ; Absolute address to place my code/constant data
Compteur    EQU  $0044      ; Adresse du compteur 16 bits du TIM
ComptReset  EQU  40000      ; Valeur a laquelle le compteur est remis a zero
Simulateur  EQU	 0

Avance: 	EQU	 3200		; Vitesse maximale d'avancement
Neutre:	    EQU  3000		; Valeurs d'arrêt
Recule: 	EQU  2800		; Vitesse maximale de recule


; variable/data section

;**************************************************************
;	RAM
;**************************************************************    
            ORG RAMStart

VCst:	    DS.W	1
TTotal:	    DS.W	1
TA:		    DS.W	1
TC:		    DS.W	1
DeltaV:	    DS.W	1
VMD:	    DS.W	30		; Vitesse moteur droit
VMG:    	DS.W	30		; Vitesse moteur gauche
PtrVMD:	    DS.W	1		
PtrVMG:    	DS.W	1

COMPT:   	DS.B	1		; Compteur 


VDiff:   	DS.W	1		; Variable custom 

ComptMG:    DS.B    1
ComptMD:    DS.B    1
ComptSec:   DS.B    1
TmpSec:     DS.B    1



;**************************************************************
;	ROM
;**************************************************************    
            ORG   ROMStart
Entry:
            CLI             ; enable interrupts
            LDS     #$1000  ; initialisation de la pileau haut
                            ; de ls RAM ($0800-$0FFF)
                            ; Initialisation communication
            ;jsr     initPortLCD
                     
            MOVB    $00,ComptMG
            MOVB    $00,ComptMD
            MOVB    $00,ComptSec
            MOVB    $00,TmpSec
            MOVW    VMD,PtrVMD
			MOVW    VMG,PtrVMG
            jsr     initProcedure
            MOVW    #Neutre,TTotal
            MOVW    #Avance,VCst
            LDD     TTotal
            LDY     VCst
            jsr     Calcul
            LDY		#VMD
			LDX		#DeltaV
			JSR		Profil
			JSR     initTimer
			

            
DONE:		BRA	    DONE

;**************************************************************
;	Functions
;**************************************************************    
initProcedure:
            ;Init portb en sortie
            LDAB    #$ff ; 1 = sortie
            STAB    DDRB
             
            ; Init du SCI (transmetteur et récepteur de caractères sériel)
            CLR     SCIBDH
            LDAB    #$34 ; si bus clk est à 8MHz
            STAB    SCIBDL ; 9600 BAUDS
            CLR     SCICR1 ; M BIT = 0 POUR 8 BITS
            LDAB    #$0C
            STAB    SCICR2 ; TE , RE
            rts

; Diagramme de connection ecran LCD
; PORTA : Data
; PORTB : $04 - Enable                                              
;       : $02 - Read/Write
;       : $01 - Select Register
; 1. Reset procedure ($30, $30, $30)
; 2. 1/2 lignes (Options: $30)
; 3. display off ($08)
; 4. Clr Display ($01)
; 5. type curseur (option: $06)
; 6. Display on ($0E)
initPortLCD:
		BSET    DDRB, #$07      ; Set la direction du portB
		BSET    DDRA, #$FF      ; Set la direction du portA
		
		affLCD  $30, 15, $04   ; reset1
		affLCD  $30, $04, $04   ; reset2			  
		affLCD  $30, $04, $04   ; reset3
		affLCD  $30, $04, $04   ; 1/2 ligne
		affLCD  $08, $04, $04   ; DisplayOff
		affLCD  $01, $04, $04   ; Clear Display
		affLCD  $06, $04, $04   ; Type Curseur
		affLCD  $0E, $04, $04   ; DisplayOn
		
        rts            

            
initTimer:
            MOVB    #$0A,TSCR2          ; Diviser la clock de 8MHz par 4
                                        ; et activation du reset (TCRE)
            ;MOVB    #$80,TFLG2          ; Activer le bit pour le débordement
            MOVB    #$8C,TIOS           ; Pin 0 et 1 => Entree, 2 et 3 => Sortie
            MOVW    #ComptReset,TC7     ; On place le reset a 40000 
             
            IF Simulateur = 0           
                MOVB    #$03,TIE        ; Si en reel interrupt port Entree
            ELSE
                MOVB    #$0C,TIE        ; Si en sim interrupt port Sortie
            ENDIF                                        
            
            MOVW    #Neutre,TC2         ; Valeur initiale pour que les moteurs
            MOVW    #Neutre,TC3         ; ne bouge pas au demarrage du robot
            
            MOVB    #$0C,OC7M           ; Mask des reset de sortie
            MOVB    #$0C,OC7D           ; Activation des sortie lors du reset
            
            MOVB    #$A0,TCTL2
            
            MOVB    #$0A,TCTL4          ; Activation de la detection des rising edge
            
            MOVB    #$80,TSCR1          ; Activer le module TIM 
            RTS
            
            
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

Profil:		; Ecrire les valeurs du profil de vitesse dans les tableaux
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
    		
		
ComptMotR:	
            MOVB    #$01,TFLG1	; Routine qui incremente le compte 
            LDAA    ComptMG		; des impulsion envoyer au moteur
            LDAB    ComptMD
            
            ADDD    #$0101		; !!!ABSOLUTE OPTIMIZATION!!!
            
            STAA    ComptMG
            STAB    ComptMD
            
            SUBB    #25
            BHS     RS_TIM     
            
RETOURR:    SUBA    #50
            BLO     NoIncSec
            
            
            LDAA    TmpSec
            INCA
            STAA    TmpSec
            MOVB    #$00,ComptMG
            MOVB    #$00,ComptMD
            
            JSR     printSec
            
NoIncSec:   NOP  
            RTI                     


ComptMotS:	
            MOVB    #$04,TFLG1	; Routine qui incremente le compte 
            LDAA    ComptMG		; des impulsion envoyer au moteur
            LDAB    ComptMD
            
            ADDD    #$0101		; !!!ABSOLUTE OPTIMIZATION!!!
            
            STAA    ComptMG
            STAB    ComptMD
            
            SUBA    #50
            BLO     NoIncSecs
            
      
            LDAA    TmpSec
            INCA
            STAA    TmpSec
            MOVB    #$00,ComptMG
            MOVB    #$00,ComptMD
            
            JSR     printSec
            
NoIncSecs:   NOP           
            RTI
       

AutreR:  
        	MOVB        #$02,TFLG1	 ; reel #$02, sim #$08
        	RTI
        
AutreS:
            MOVB        #$08,TFLG1	 ; reel #$02, sim #$08
        	RTI
        	 
DELAI: 
Boucle2:    LDX     	#5000 	; 50,000 fois en boucle interne=25 msec
Boucle1:    DEX 		        ; décrémente X
		    BNE     	Boucle1	; boucle interne
		    DEY 		        ; décrémente Y
		    BNE 	    Boucle2	; boucle externe
		    RTS 		        ; retour de la sous-routine

printSec:
            printf      #str1
            out2hex     TmpSec
            printf      #str2 
            rts
            
RS_TIM:
        
            LDY     PtrVMD
            LDX     PtrVMG
            MOVW    2,X+,TC2
            MOVW    2,y+,TC3
            STY     PtrVMD
            STX     PtrVMG
            LBRA    RETOURR
         
;**************************************************************
;* Messages textes
;**************************************************************
str1:	DC.B	'Temps : ', $00
str2:	DC.B	' secondes', $00


;**************************************************************
;* Inclusion du fichier D_BUG12M.ASM
;**************************************************************
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
                                            ; fonctions D_BUG12
            INCLUDE     'LCDhex.asm'
 

;**************************************************************
;* Interrupt Vectors
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
            ORG   $FFEE
            DC.W  ComptMotR
            ORG   $FFEC
            DC.W  AutreR
            ORG   $FFEA
            DC.W  ComptMotS
            ORG   $FFE8
            DC.W  AutreS
