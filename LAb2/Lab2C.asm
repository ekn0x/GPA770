
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
ROMStart    EQU  $4000  ; Absolute address to place my code/constant data
Compteur    EQU  $0044  ; Adresse du compteur 16 bits du TIM
ComptReset  EQU  $9C40  ; Valeur a laquelle le compteur est remis a zero


; variable/data section

;**************************************************************
;	RAM
;**************************************************************    
            ORG RAMStart

;**************************************************************
;	ROM
;**************************************************************    
            ORG   ROMStart
Entry:
            CLI             ; enable interrupts
            LDS     #$1000  ; initialisation de la pileau haut
                            ; de ls RAM ($0800-$0FFF)
                            ; Initialisation communication
            jsr     initProcedure
            
			BRN		Entry

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
            
initTimer:
            MOVB    #$0A,TSCR2          ; Diviser la clock de 8MHz par 4
                                        ; et activation du reset (TCRE)
            MOVB    #$80,TFLG2          ; Activer le bit pour le débordement
            MOVB    #$0C,TIOS           ; Pin 0 et 1 => Entree, 2 et 3 => Sortie
            MOVB    #$9C,$005E          ; Reset a 40000
            MOVB    #$40,$005F                                                          
            MOVB    #$80,TSCR1          ; Activer le module TIM 
            RTS
;**************************************************************
;* Messages textes
;**************************************************************

;**************************************************************
;* Inclusion du fichier D_BUG12M.ASM
;**************************************************************
			INCLUDE 	'D_BUG12M.ASM' 		; Fichier pour la simulation des
                                            ; fonctions D_BUG12
 

;**************************************************************
;* Interrupt Vectors
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
