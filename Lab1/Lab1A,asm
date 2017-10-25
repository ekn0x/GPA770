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

;*************************************************************************
;* *
;* Déclaration des variables *
;* *
;* data section MY_EXTENDED_RAM à $0800 *
;* *
;*************************************************************************
    ORG RAMStart

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
; À partir des fonctions D_BUG12
;
; 1) Envoyer un message au terminal VT100
; 2) Recevoir des caractères du clavier et en faire l’écho sur le terminal
; jusqu’à la réception du caractère crlf [ENTER]

    Main:
     printf #Message ; envoyer un message de bienvenue
    ReChar1: ; lecture du clavier
     getchar
     CMPB #$0d ; si crlf fin de lecture
     BEQ Mes1
     putchar
     BRA ReChar1 ; faire un écho
    Mes1: printf #Message2 ; envoyer message à la prochaine
;*************************************************************************
;*
;* Essai des fonctions d’affichage hexadécimal à ASCII
     out2hex Message ; faire test hex to ascii 1 octets
     ; mode étendu
     printf #CRLF ; Retour à la ligne et nouvelle ligne

     out4hex #$a25f ; faire test hex to ascii 2 octets
     ; mode immédiat
;*************************************************************************
;*
;* Compteur binaire sur le port B
     LDX #$0000

    loop: INX ; petit délai de 65536 comptes
     BNE loop
     LDAB Compt ; Incrémenter la variable Compt
     INCB
     STAB Compt
     STAB PORTB ; Compt vers le port B
     BRA loop

    Message: dc.b 'Bienvenue au laboratoire de microélectronique',$0A,$0D
     dc.b 'appliquée',$0A,$0D,$00
    Message2: dc.b $0A,$0D, 'Bravo et à la prochaine !!! ',$0A,$0D,$00
    CRLF: dc.b $0A,$0D,$00 ; $0A = descendre le curseur d’une ligne
     ; $0D = retourner le curseur à la colonne 0
    ; $00 = fin de texte pour la fonction printf

     NOLIST
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
