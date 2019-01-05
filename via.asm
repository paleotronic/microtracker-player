; slot
SLOT                   .equ $c400

; VIA registers
VIAORB                 .equ 0
VIAORA                 .equ 1
VIADDRB                .equ 2
VIADDRA                .equ 3
VIAT1CL                .equ 4
VIAT1CH                .equ 5

VIAT1LL                .equ 6
VIAT1LH                .equ 7

VIAACR                 .equ 11
VIAIFR                 .equ 13
VIAIER                 .equ 14

; set register (X contains $00 for chip 0, $80 for chip 1 )
VIAInit                
                       LDX #$80
                       LDA #$FF
                       STA SLOT+VIADDRA,X
                       LDA #$07
                       STA SLOT+VIADDRB,X
                       LDX #$00
                       LDA #$FF
                       STA SLOT+VIADDRA,X
                       LDA #$07
                       STA SLOT+VIADDRB,X
                       RTS

VIAReset               LDA #0
                       STA SLOT+VIAORB,X
                       JSR VIASetInactive
                       NOP
                       NOP
                       NOP
                       NOP
                       NOP
                       RTS

VIAWriteData           LDA #6
                       STA SLOT+VIAORB,X
                       JSR VIASetInactive
                       RTS

VIAReadData            LDA #5
                       STA SLOT+VIAORB,X
                       JSR VIASetInactive
                       RTS

VIASetRegister         LDA #7
                       STA SLOT+VIAORB,X
                       JSR VIASetInactive
                       RTS

VIASetInactive         LDA #4
                       STA SLOT+VIAORB,X
                       RTS

VIASetA                STA SLOT+VIAORA,X
                       RTS

VIAGetA                LDA #$00
                       STA SLOT+VIADDRA,X
                       LDA SLOT+VIAORA,X
                       PHA
                       LDA #$FF
                       STA SLOT+VIADDRA,X
                       PLA
                       RTS

VIAEnableT1IRQ         ; X = chip $00,$80
                       LDA #%11000000
                       STA SLOT+VIAIER,X
                       RTS

VIADisableT1IRQ        ; X = chip $00,$80
                       LDA #%01000000
                       STA SLOT+VIAIER,X
                       RTS

Timer1Counter          .word 63780

VIASetTimer1O           ; X = chip $00, $80
                       LDA Timer1Counter+0
                       STA SLOT+VIAT1CL,X
                       LDA Timer1Counter+1
                       STA SLOT+VIAT1CH,X
                       LDA SLOT+VIAACR,X
                       AND #%01111111
                       ORA #%01000000 
                       STA SLOT+VIAACR,X
                       JSR VIAEnableT1IRQ
                       RTS

VIAUpdateTimer1     
                    ;    LDA Timer1Counter+0
                    ;    STA SLOT+VIAT1LL,X
                    ;    LDA Timer1Counter+1
                    ;    STA SLOT+VIAT1LH,X 
                       ;
                       LDA Timer1Counter+0
                       STA SLOT+VIAT1CL,X
                       LDA Timer1Counter+1
                       STA SLOT+VIAT1CH,X
                       ;
                       RTS

VIASetTimer1           
                       SEI
                       ;
                       LDA #$40
                       STA SLOT+VIAACR,X
                       ;
                       LDA #$7F
                       STA SLOT+VIAIER,X
                       ;
                       LDA #$C0
                       STA SLOT+VIAIFR,X
                       STA SLOT+VIAIER,X        
                       ;               ;
                       LDA Timer1Counter+0
                       STA SLOT+VIAT1CL,X
                       LDA Timer1Counter+1
                       STA SLOT+VIAT1CH,X 
                       ;
                    ;    LDA Timer1Counter+0
                    ;    STA SLOT+VIAT1LL,X
                    ;    LDA Timer1Counter+1
                    ;    STA SLOT+VIAT1LH,X 
                       ;
                       CLI
                       ;
                       RTS

VIAACKTimer1IRQ        BIT SLOT+VIAT1CL
                       RTS
                    
                       
