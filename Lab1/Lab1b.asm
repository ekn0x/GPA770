;*************************************************************************
;* *
;* Auteur : Maurice Tremblay *
;* Date : avril 2007 *
;* *
;* *
;* Ce programme : *
;* *
;* 1) *
;* affiche un message de bienvenue par une transmission *
;* sérielle de caractères du microcontrôleur, port SCI, vers le port de *
;* communication COM1 d’un ordinateur personnel en émulation de terminal*
;* VT100. *
;* *
;* 2) *
;* reçoit des caractères à partir d’un clavier *
;* *
;* 3) *
;* traduit des chiffres hexadécimaux en caractère ascii pour les *
;* afficher sur le terminal *
;* *
;* 4) *
;* active un compteur binaire sur les DELs branchées sur le port B *
;* *
;*************************************************************************
; Point d’entrée du programme
    ABSENTRY Entry ; point d’entrée pour adressage absolu
     nolist ; Désactiver l’insertion de texte dans le
 ; fichier .LST
    INCLUDE 'mc9s12c32.inc' ; Inclusion du fichier d’identification des
 ; registres
    INCLUDE 'D_BUG12M.MAC' ; Définition de macros pour des appels simples
 ; en assembleur ; getchar, putchar, out2hex
 ; out4hex, printf
; Réactiver l’insertion de texte dans le
    list ; fichier .LST

ROMStart EQU $4000 ; Adresse absolue pour le début du programme
                   ; et des constantes
CAPTEUR1 EQU $0091
CAPTEUR2 EQU $0093
CAPTEUR3 EQU $0095
SEUIL    EQU $55

;*************************************************************************
;* *
;* Déclaration des variables *
;* *
;* data section MY_EXTENDED_RAM à $0800 *
;* *
;*************************************************************************
    ORG RAMStart
Reg1:   DS.B    1
Reg2:   DS.B    1
Reg3:   DS.B    1

Compt ds.b 1 ; Compteur binaire
;*************************************************************************
;*************************************************************************
;* *
;* Début du code dans la section CODE SECTION *
;* *
;* *
;* *
;*************************************************************************
;*************************************************************************
    ORG ROMStart
    Entry:
        CLI ; permettre les interruptions

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
;

        ; Chargement des valeurs des capteurs dans la mémoire RAM
        MOVB CAPTEUR1, Reg1
        MOVB CAPTEUR2, Reg2
        MOVB CAPTEUR3, Reg3
       
        ; Vérification si la valeur est plus grande que le seuil
        ; et on branch sur HI si c'est le cas
        LDAA #SEUIL
        SUBA Reg1
        BLO  HI
        
        ; Vérification si la valeur est plus petite que le seuil
        ; et on branch sur LO si c'est le cas
Suite1: LDAA #SEUIL
        SUBA Reg2
        BHI  LO
        ; Vérification si la valeur est plus grande que le seuil
        ; et on branch sur HI2 si c'est le cas
Suite2: LDAA #SEUIL
        SUBA Reg3
        BLO  HI2
        
        ; On arrête le parcours du programcounter(PC)
FIN:    BRA  FIN
        

        ; On calcul 1+2+3+4+5 et le place dans le bon registre        
HI:     LDAB #$00
        ADDB #$01
        ADDB #$02
        ADDB #$03
        ADDB #$04
        ADDB #$05
        STAB Reg1
        BRA  Suite1
       
        ; On place la valeurs $00 dans le bon registre 
LO:     MOVB #$00, Reg2
        BRA Suite2

        ; On Soustrait $10 a la valeur ce trouvant a $0803
HI2:    LDAB Reg3
        SUBB #$10
        STAB Reg3
        BRA FIN
        

;*************************************************************************
;* *
;* Inclusion du fichier D_BUG12M.ASM *
;* *
;*************************************************************************

     INCLUDE 'D_BUG12M.ASM' ; Fichier pour la simulation des
     ; fonctions D_BUG12
     LIST
;*************************************************************************
;* *
;* Vecteur d’interruption pour le reset *
;* *
;*************************************************************************

     ORG $FFFE
     fdb Entry ;Reset

     END ; fin de compilation
