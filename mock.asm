

; PSG Register enums
PSGFreqFineA            .equ $00 
PSGFreqCourseA          .equ $01
PSGFreqFineB            .equ $02
PSGFreqCourseB          .equ $03
PSGFreqFineC            .equ $04
PSGFreqCourseC          .equ $05
PSGFreqNG               .equ $06
PSGEnableControl        .equ $07
PSGLevelAndEnvA         .equ $08
PSGLevelAndEnvB         .equ $09
PSGLevelAndEnvC         .equ $0a
PSGEnvPeriodFine        .equ $0b
PSGEnvPeriodCourse      .equ $0c
PSGEnvShape             .equ $0d

; PSG enable flags
PSGEnableNoiseOnC       .equ 32
PSGEnableNoiseOnB       .equ 16
PSGEnableNoiseOnA       .equ 8
PSGEnableToneOnC        .equ 4
PSGEnableToneOnB        .equ 2
PSGEnableToneOnA        .equ 1

startmock               JSR MBInit
                        JSR ToneTest
                        RTS

; Register in A, X .equ $00 for chip 0, $80 for chip 1
MBRegSelect           
                        JSR SetPSGRegIdx
                        JSR VIASetA
                        JSR VIASetRegister
                        RTS

MBRegWrite              JSR StrPSGRegVal
                        JSR VIASetA
                        JSR VIAWriteData
                        RTS

MBRegRead               ;JSR VIAReadData    ; Seems register reads from the PSG works fine with microM8, Jace
                        ;JSR VIAGetA        ; and not so well with AppleWin and Virtual II
                        JSR GetPSGRegVal
                        RTS

MBInit                  JSR RstPSGReg
                        JSR VIAInit
                        LDX #$80
                        JSR VIAReset 
                        LDX #$00
                        JSR VIAReset
                        LDX #0
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        LDA #255
                        JSR MBRegWrite
                        LDX #$80
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        LDA #255
                        JSR MBRegWrite
                        LDA #255 
                        STA PSGEnableState+0
                        STA PSGEnableState+1
                        LDA #0
                        STA PSGVolumeA
                        STA PSGVolumeA+1
                        STA PSGVolumeB
                        STA PSGVolumeB+1
                        STA PSGVolumeC
                        STA PSGVolumeC+1
                        RTS

ToneTest               
                        JSR StartSong
                        RTS

SetTonePeriodCoarseA    TAY
                        LDA #PSGFreqCourseA
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetTonePeriodCoarseB    TAY
                        LDA #PSGFreqCourseB
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS            

SetTonePeriodCoarseC    TAY
                        LDA #PSGFreqCourseC
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS
                        
SetTonePeriodFineA      TAY
                        LDA #PSGFreqFineA
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetTonePeriodFineB      TAY
                        LDA #PSGFreqFineB
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS                   

SetTonePeriodFineC      TAY
                        LDA #PSGFreqFineC
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

EnableToneA             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$FE
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS      

EnableToneB             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$FD
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS              

EnableToneC                          
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$FB
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS   

EnableNoiseA             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$F7
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS      

EnableNoiseB             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$EF
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS              

EnableNoiseC                          
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        AND #$DF
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS 

; disable code

DisableToneA             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #1
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS      

DisableToneB             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #2
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS              

DisableToneC                          
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #4
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS   

DisableNoiseA             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #8
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS      

DisableNoiseB             
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #16
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS              

DisableNoiseC                          
                        LDA #PSGEnableControl
                        JSR MBRegSelect
                        JSR ReadPSGEnableState   
                        ORA #32
                        JSR StorePSGEnableState
                        JSR MBRegWrite
                        RTS 

SetVolumeA              JSR StoreVolumeA
                        TAY
                        LDA #PSGLevelAndEnvA
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetVolumeB              JSR StoreVolumeB
                        TAY
                        LDA #PSGLevelAndEnvB
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetVolumeC              JSR StoreVolumeC
                        TAY
                        LDA #PSGLevelAndEnvC
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetNoisePeriod          TAY
                        LDA #PSGFreqNG
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetEnvShape             TAY
                        LDA #PSGEnvShape
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetEnvPeriodCoarse      TAY
                        LDA #PSGEnvPeriodCourse
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

SetEnvPeriodFine        TAY
                        LDA #PSGEnvPeriodFine
                        JSR MBRegSelect
                        TYA
                        JSR MBRegWrite 
                        RTS

; used for reading / writing PSG register values
PSGRegister             .byte $00 
PSGValue                .byte $00
; 
PSGEnableState          .byte $ff
                        .byte $ff
PSGVolumeA              .byte $00
                        .byte $00
PSGVolumeB              .byte $00
                        .byte $00
PSGVolumeC              .byte $00
                        .byte $00

PSGSaveX                .equ $D9

ReadPSGEnableState      ; Assumes X = $80/$00
                        STX PSGSaveX
                        TXA
                        CLC
                        ROL
                        ROL
                        TAX
                        LDA PSGEnableState,X
                        LDX PSGSaveX 
                        RTS

StorePSGEnableState     ; Assumes X = $80/$00
                        PHA ; save a
                        STX PSGSaveX ; save x
                        TXA ; x -> a
                        CLC ; << 2
                        ROL
                        ROL
                        TAX ; a -> x
                        PLA ; restore a
                        STA PSGEnableState,X
                        LDX PSGSaveX 
                        RTS

ReadVolumeA             ; Assumes X = $80/$00
                        STX PSGSaveX
                        TXA
                        CLC
                        ROL
                        ROL
                        TAX
                        LDA PSGVolumeA,X
                        LDX PSGSaveX 
                        RTS

StoreVolumeA            ; Assumes X = $80/$00
                        PHA ; save a
                        STX PSGSaveX ; save x
                        TXA ; x -> a
                        CLC ; << 2
                        ROL
                        ROL
                        TAX ; a -> x
                        PLA ; restore a
                        STA PSGVolumeA,X
                        LDX PSGSaveX 
                        RTS

ReadVolumeB             ; Assumes X = $80/$00
                        STX PSGSaveX
                        TXA
                        CLC
                        ROL
                        ROL
                        TAX
                        LDA PSGVolumeB,X
                        LDX PSGSaveX 
                        RTS

StoreVolumeB            ; Assumes X = $80/$00
                        PHA ; save a
                        STX PSGSaveX ; save x
                        TXA ; x -> a
                        CLC ; << 2
                        ROL
                        ROL
                        TAX ; a -> x
                        PLA ; restore a
                        STA PSGVolumeB,X
                        LDX PSGSaveX 
                        RTS

ReadVolumeC             ; Assumes X = $80/$00
                        STX PSGSaveX
                        TXA
                        CLC
                        ROL
                        ROL
                        TAX
                        LDA PSGVolumeC,X
                        LDX PSGSaveX 
                        RTS

StoreVolumeC            ; Assumes X = $80/$00
                        PHA ; save a
                        STX PSGSaveX ; save x
                        TXA ; x -> a
                        CLC ; << 2
                        ROL
                        ROL
                        TAX ; a -> x
                        PLA ; restore a
                        STA PSGVolumeC,X
                        LDX PSGSaveX 
                        RTS

; note offsets
; 0: tone period coarse | 0xff
; 1: tone period fine | 0xff
; 2: noise period | 0xff
; 3: volume | 0xff
; 4: env coarse | 0xff
; 5: env fine | 0xff
; 6: env shape | 0xff
; 7: command | 0xff
; 8: command val
offsetToneCoarse        .equ $00
offsetToneFine          .equ $01
offsetNoisePeriod       .equ $02
offsetVolume            .equ $03
offsetEnvCoarse         .equ $04
offsetEnvFine           .equ $05
offsetEnvShape          .equ $06
offsetCommand           .equ $07
offsetCommandParam      .equ $08
offsetChannelState      .equ $09

REGPtr                   .byte $00
REGSaveBuffer            .byte 0,0,0,0,0,0,0,255
                         .byte 0,0,0,0,0,0,0,0
                         .byte 0,0,0,0,0,0,0,255
                         .byte 0,0,0,0,0,0,0,0

RstPSGReg                 LDX #0
                          LDA #0
RstPSGRegL                STA REGSaveBuffer,X 
                          INX
                          CPX #32
                          BNE RstPSGRegL
                          LDA #255
                          STA REGSaveBuffer+7
                          STA REGSaveBuffer+23
                          RTS

SetPSGRegIdx              ; X = $00/$80, A = PSGRegNumber
                          STA REGPtr 
                          ; save registers X, A
                          PHA
                          TXA
                          PHA
                          ; now xreg is in A
                          CLC
                          ROR 
                          ROR 
                          ROR 
                          ADC REGPtr
                          STA REGPtr
                          PLA 
                          TAX
                          PLA
                          RTS 

GetPSGRegVal              LDY REGPtr
                          LDA REGSaveBuffer,Y
                          RTS

StrPSGRegVal              LDY REGPtr
                          STA REGSaveBuffer,Y
                          RTS
                          


; GetTonePeriodCoarse
GetTonePeriodCoarse       
                          LDA noteChannel
                          BNE GTPCIs1
                          LDA #PSGFreqCourseA
                          JMP GetTPCValue
GTPCIs1                   
                          CMP #1
                          BNE GTPCIs2
                          LDA #PSGFreqCourseB
                          JMP GetTPCValue
GTPCIs2                   
                          LDA #PSGFreqCourseC
GetTPCValue
                          JSR MBRegSelect
                          JSR MBRegRead
                          RTS

; GetTonePeriodFine
GetTonePeriodFine       
                          LDA noteChannel
                          BNE GTPFIs1
                          LDA #PSGFreqFineA
                          JMP GetTPFValue
GTPFIs1                   
                          CMP #1
                          BNE GTPFIs2
                          LDA #PSGFreqFineB
                          JMP GetTPFValue
GTPFIs2                   
                          LDA #PSGFreqFineC
GetTPFValue
                          JSR MBRegSelect
                          JSR MBRegRead
                          RTS

; SetTonePeriodCoarse
SetTonePeriodCoarse       PHA 
                          LDA noteChannel
                          BNE TPCIs1
                          PLA 
                          JSR SetTonePeriodCoarseA
                          RTS
TPCIs1                    CMP #1
                          BNE TPCIs2
                          PLA
                          JSR SetTonePeriodCoarseB
                          RTS
TPCIs2                    PLA
                          JSR SetTonePeriodCoarseC
                          RTS

; SetTonePeriodFine
SetTonePeriodFine         PHA 
                          LDA noteChannel
                          BNE TPFIs1
                          PLA 
                          JSR SetTonePeriodFineA
                          RTS
TPFIs1                    CMP #1
                          BNE TPFIs2
                          PLA
                          JSR SetTonePeriodFineB
                          RTS
TPFIs2                    PLA
                          JSR SetTonePeriodFineC
                          RTS

; GetVolume
GetVolume                 PHA 
                          LDA noteChannel
                          BNE GVIs1 
                          LDA #PSGLevelAndEnvA
                          JMP GVRead
GVIs1                     
                          CMP #1
                          BNE GVIs2
                          LDA #PSGLevelAndEnvB
                          JMP GVRead
GVIs2              
                          LDA #PSGLevelAndEnvC
GVRead                    JSR MBRegSelect
                          JSR MBRegRead
                          RTS

; SetVolume
SetVolume                 PHA 
                          LDA noteChannel
                          BNE SVIs1
                          PLA 
                          JSR SetVolumeA
                          RTS
SVIs1                     CMP #1
                          BNE SVIs2
                          PLA
                          JSR SetVolumeB
                          RTS
SVIs2                     PLA
                          JSR SetVolumeC
                          RTS

; EnableTone
EnableTone                 
                          LDA noteChannel
                          BNE ETIs1
                          JSR EnableToneA
                          RTS
ETIs1                     CMP #1
                          BNE ETIs2
                          JSR EnableToneB
                          RTS
ETIs2                     JSR EnableToneC
                          RTS

; DisableTone
DisableTone                
                          LDA noteChannel
                          BNE DTIs1
                          JSR DisableToneA
                          RTS
DTIs1                     CMP #1
                          BNE DTIs2
                          JSR DisableToneB
                          RTS
DTIs2                     JSR DisableToneC
                          RTS

; EnableNoise
EnableNoise                
                          LDA noteChannel
                          BNE ENIs1
                          JSR EnableNoiseA
                          RTS
ENIs1                     CMP #1
                          BNE ENIs2
                          JSR EnableNoiseB
                          RTS
ENIs2                     JSR EnableNoiseC
                          RTS

; DisableNoise
DisableNoise               
                          LDA noteChannel
                          BNE DNIs1
                          JSR DisableNoiseA
                          RTS
DNIs1                     CMP #1
                          BNE DNIs2
                          JSR DisableNoiseB
                          RTS
DNIs2                     JSR DisableNoiseC
                          RTS


