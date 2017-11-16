;**************************************************************
;*                                                            *      
;*  Routines: LCD2hex copié de Out4hex                        *      
;*  Entrée:   registre b contient le code hexadécimal         *      
;*  Tâche:    transmettre à un LCD la valeur ascii            *
;*            du nombre hexadécimal             	          *
;*  Sortie:   aucune                                          *      
;*                                                            * 
;*                                                            *      
;*  Revision 29 oct 2008                                      *      
;*                                                            *      
;*                                                            *      
;*                                                            *           
;**************************************************************

LCD2hex:
        pshb		        ; Sauvegarder b
        lsrb
        lsrb
        lsrb
        lsrb
        cmpb  #$0a			; quartet du haut
        bhs   llettre1      ; si plus grand ou égal c'est + 41h
        
lchiffre1:
        addb  #$30          ; traduire le quartet en ascii
        bra   lsuitehex1
        
llettre1:
        addb  #$37          ; traduire le quartet en ascii
        
lsuitehex1:
        pshd
        ldy     #$2
        jsr     DELAI
        puld        
        ldaa    #$05        ; mot de cntrl                        
        staa    PORTB       ; 
        stab    PORTA
        bclr    PORTB,#$04  ; E bit à 0
        
        pulb                ; on reprend b
        andb  #$0f          ; garger la partie basse quartet du bas
        cmpb  #$0a
        bhs   llettre2      ; si plus grand ou égal c'est + 41h
        
lchiffre2:
        addb  #$30          ; traduire le quartet en ascii
        bra   lsuitehex2
        
llettre2:
        addb  #$37          ; traduire le quartet en ascii
        
lsuitehex2:
        pshd
        ldy     #$2
        jsr     DELAI
        puld              
        ldaa    #$05        ; mot de cntrl                        
        staa    PORTB       ; 
        stab    PORTA
        bclr    PORTB,#$04  ; E bit à 0

        ldy     #$2				; oct 2008
        jsr     DELAI				; oct 2008
        bset    PORTB,#$04  ; E bit à 1		; oct 2008
        
        rts   