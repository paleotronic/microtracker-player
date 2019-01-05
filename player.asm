                ORG $4000

Start
                ;JMP TestModValue
                JMP StartMusic                  ; ORG + 0
                JMP KillMusic                   ; ORG + 3
                JMP TogglePause                 ; ORG + 6
                JMP JukeBoxStart                ; ORG + 9
                JMP JukeBoxPlay                 ; ORG + 12

JBPatternIndex  .byte $00                       ; ORG + 15

PlayerPaused    .byte $00

; TestModValue
;                 LDA #8
;                 STA ValueToMod
;                 LDA #$80
;                 JSR ModifyValue
;                 LDA ValueToMod
;                 STA $8000
;                 LDA #8
;                 STA ValueToMod
;                 LDA #$07
;                 JSR ModifyValue
;                 LDA ValueToMod
;                 STA $8001
;                 RTS

; Queue track and start IRQ
JukeBoxStart    
                JSR SetPause 
StartMusic
                JSR MBInit
                LDA #0
                STA patternListIndex
                STA patternNum
                STA patternPos
                STA patternTrack
                JSR LoadPattern       ; load first pattern
                JSR SetupIRQ
                RTS
; Kill music stops the IRQ etc
KillMusic
                LDX #0
                JSR VIADisableT1IRQ
                JSR MBInit
                LDA OldIRQPtr+0
                STA $3FE
                LDA OldIRQPtr+1
                STA $3FF
                LDX #$00
                JSR VIAReset
                LDX #$80
                JSR VIAReset
                RTS 

ResetTicks 
                .byte $00
NextNoteTicks
                .byte $01
TicksNeeded
                .byte $02
CurrentTicks 
                .byte $00
TickInterval 
                .word 63780

HandleIRQ
                PHA                     ; save A
                TXA                     ; copy X
                PHA                     ; save X
                TYA                     ; copy Y
                PHA                     ; save Y
IRQMain
                LDA PlayerPaused        ; if paused just exit the irq (no work done)
                BEQ CheckTickReset
                JMP ExitIRQ

CheckTickReset
                LDA ResetTicks
                BEQ HandleTick
                JSR SetupIRQ
                LDA #0
                STA ResetTicks
                LDX #0
                JSR VIAUpdateTimer1
                ; we only do the main thing every TicksNeeded IRQ calls because 
                ; of limitations of the counter registers
HandleTick
                INC CurrentTicks
                LDA CurrentTicks
                CMP TicksNeeded
                BNE CheckPlayNote
                ; reset the counter
                LDA #0
                STA CurrentTicks
                JSR ActionAdvance
                JMP ExitIRQ
CheckPlayNote
                CMP NextNoteTicks
                BNE ExitIRQ
                JSR ActionPlay
                ; clean up and return from irq
ExitIRQ
                JSR VIAACKTimer1IRQ 
                PLA                     ; pull Y
                TAY                     ; restore it
                PLA                     ; pull X
                TAX                     ; restore it
                PLA                     ; restore A
                RTI                     ; this was an interrupt service so exit properly

OldIRQPtr       .word $0000

SetupIRQ
                ; save old irq
                LDA $3FE
                STA OldIRQPtr+0
                LDA $3FF
                STA OldIRQPtr+1
                ; set new irq
                LDA #<HandleIRQ
                STA $3FE
                LDA #>HandleIRQ
                STA $3FF
                LDA TickInterval+0
                STA Timer1Counter+0
                LDA TickInterval+1
                STA Timer1Counter+1
                LDX #0
                JSR VIASetTimer1
                RTS

ActionPlay 
                JSR PlayRow
                RTS

ActionAdvance
                JSR NextRow
                RTS

; Pause / Unpause routine
TogglePause     
                LDA PlayerPaused
                BEQ SetPause
                LDA #0
                STA PlayerPaused
                RTS
SetPause        
                LDA #1
                STA PlayerPaused
                RTS

; JukeboxPlay
JukeBoxPlay     
                LDA JBPatternIndex
                STA patternListIndex
                LDA #0
                STA patternPos
                JSR LoadNewPattern
                LDA #0
                STA CurrentTicks
                STA PlayerPaused
                RTS

; core playing code here, references mock.asm for lower level subroutines


; CheckNoise will check and apply a noise period
; if required
CheckNoise                LDY #2       
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ DoneNoise
                          JSR SetNoisePeriod
DoneNoise                 RTS

; CheckEnvelope will check and apply env params
; if set
CheckEnvelope             LDY #9
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ DoneEnvelope   ; dont interpret bits if $FF present
                          AND #4
                          BEQ DoneEnvelope
                          LDY #4
                          LDA (noteAddrLo),Y
SetEnvelope               JSR SetEnvPeriodCoarse
                          LDY #5
                          LDA (noteAddrLo),Y
                          JSR SetEnvPeriodFine
                          LDY #6
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ DoneEnvelope
                          JSR SetEnvShape 
DoneEnvelope              RTS           



; SoundNote
; Play note data pointed to noteAddrLo/noteAddrHi
; Send to chip $00/$01
; Send to channel noteChannel
SoundNote
                          LDX noteChip
; --
                          LDY #0
CheckTone                 LDA (noteAddrLo),Y
                          CMP #$FE                          ; handle XXX inline
                          BNE CheckEmpty
                          JSR DisableNoise
                          JSR DisableTone
                          JMP CheckCommand
CheckEmpty                CMP #$FF
                          BEQ DoneTone
ApplyTone                 JSR SetTonePeriodCoarse
                          LDY #1
                          LDA (noteAddrLo),Y
                          JSR SetTonePeriodFine
; --
DoneTone                  JSR CheckNoise
; --
CheckVolume               LDX noteChip
                          LDY #3
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ CheckEnv
                          JSR SetVolume
; --
CheckEnv                  JSR CheckEnvelope
; --
                          LDY #9
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ CheckCommand
                          AND #1
                          CMP #1
                          BNE ToneOff
                          JSR EnableTone
                          JMP CheckNoiseOn
ToneOff                   JSR DisableTone
; --
CheckNoiseOn              LDY #9
                          LDA (noteAddrLo),Y
                          AND #2
                          CMP #2
                          BNE NoiseOff 
                          JSR EnableNoise
                          JMP CheckCommand
NoiseOff                  JSR DisableNoise
CheckCommand              ; handle certain commands
                        ;   JMP DoneCommands
                          LDY #7
                          LDA (noteAddrLo),Y
                          CMP #$FF
                          BEQ DoneCommands
;
                          CMP #'j'
                          BNE NotJ
                          JMP CommandJ
;
NotJ                      CMP #'b'
                          BNE NotB 
                          JMP CommandB
;
NotB                      CMP #'v'
                          BNE NotV 
                          JMP CommandV
;
NotV                      CMP #'f'
                          BNE NotF
                          JMP CommandF
;
NotF                      CMP #'x'
                          BNE NotX
                          JMP CommandX
;
NotX                      CMP #'w'
                          BNE NotW 
                          JMP CommandW
;
NotW                      CMP #'s'
                          BNE NotS 
                          JMP CommandS
;
NotS                      CMP #'y'
                          BNE NotY
                          JMP CommandY
                          ;
NotY                      CMP #'z'
                          BNE NotZ
                          JMP CommandZ
;
NotZ                      CMP #'t'
                          BNE NotT
                          JMP CommandT
                          ;
NotT                      CMP #'u'
                          BNE NotU
                          JMP CommandU
;
NotU                      CMP #'q'
                          BNE NotQ
                          JMP CommandQ
                          ;
NotQ                      CMP #'r'
                          BNE NotR 
                          JMP CommandR 
                          ;
NotR                      CMP #'e'
                          BNE NotE 
                          JMP CommandE
;
NotE                      CMP #'n'
                          BNE NotN 
                          JMP CommandN
;
NotN                      CMP #'c'
                          BNE NotC 
                          JMP CommandC 
                          ;
NotC                      CMP #'p'
                          BNE NotP
                          JMP CommandP 
                          ;
NotP
DoneCommands             
                          RTS

; Pxx handler
CommandP
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          CMP #2                                        ; 2 == pause music
                          BEQ CommandPPause
                          ;
                          JSR KillMusic                                 ; anything else stop music
                          RTS
CommandPPause
                          LDA #1                                        ; pause player
                          STA PlayerPaused
                          RTS

; Cxx handler
CommandC
                          JSR GetVolume
                          PHA 
                          AND #$10
                          STA $D9 
                          PLA
                          AND #$15
                          STA ValueToMod
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          LDA ValueToMod
                          CMP #$10
                          BMI CVolOk
                          LDA #$0f
CVolOk
                          ORA $D9 
                          JSR SetVolume
                          RTS

; Exx handler
CommandE                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          BEQ ESetOff                            
ESetOn
                          JSR GetVolume
                          ORA #$10 
                          JSR SetVolume 
                          RTS
ESetOff
                          JSR GetVolume
                          AND #$0f
                          JSR SetVolume
                          RTS

; Nxx handler
CommandN                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          AND #31                             
                          JSR SetNoisePeriod
                          RTS

; Vxx handler
CommandV                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          AND #15                             
                          JSR SetEnvShape
                          RTS
; Jxx handler
CommandJ                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          ; we want to advance to next track, with pattern 
                          STA DestinationPatternRow
                          LDY patternListIndex
                          INY
                          STY DestinationPatternIndex
                          INC TimeCircuitsActivated
                          RTS

; Bxx handler
CommandB                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          ; we want to advance to pattern nn in song 
                          STA DestinationPatternIndex
                          LDA #0
                          STA DestinationPatternRow
                          INC TimeCircuitsActivated
                          RTS

; Fxx handler
CommandF                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          ; setting tempo
                          JSR SetTempo
                          RTS

RestartEnvelope           
                          LDA #PSGEnvShape
                          JSR MBRegSelect
                          JSR MBRegRead
                          PHA
                          LDA #PSGEnvShape
                          JSR MBRegSelect
                          PLA
                          JSR MBRegWrite
                          RTS

; Xxx handler
CommandX                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          ; setting env fine
                          JSR SetEnvPeriodFine
                          JSR RestartEnvelope
                          RTS

; Wxx handler
CommandW                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          ; setting env fine
                          JSR SetEnvPeriodCoarse
                          JSR RestartEnvelope
                          RTS

; Yxx handler
CommandY                  
                          ; read env period coarse -> ValueToMod
                          LDA #PSGEnvPeriodCourse
                          JSR MBRegSelect
                          JSR MBRegRead
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          ; setting env param
                          LDA ValueToMod
                          JSR SetEnvPeriodCoarse
                          ;JSR RestartEnvelope
                          RTS

; Zxx handler
CommandZ                  
                          ; read env period fine -> ValueToMod
                          LDA #PSGEnvPeriodFine
                          JSR MBRegSelect
                          JSR MBRegRead
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          LDA ValueToMod
                          ; setting env param
                          JSR SetEnvPeriodFine
                          ;JSR RestartEnvelope
                          RTS

; Qxx handler
CommandQ                  
                          ; read env period coarse -> ValueToMod
                          LDA #PSGEnvPeriodCourse
                          JSR MBRegSelect
                          JSR MBRegRead
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          ; setting env param
                          LDA ValueToMod
                          JSR SetEnvPeriodCoarse
                          ; now set fine
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          CMP #$0f
                          BPL QZeroSet
QFFSet
                          LDA #$FF
                          JSR SetEnvPeriodFine
                          RTS
QZeroSet
                          LDA #$00
                          JSR SetEnvPeriodFine
                          RTS

; Rxx handler
CommandR                  
                          ; read env period coarse -> ValueToMod
                          JSR GetTonePeriodCoarse
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          ; setting env param
                          LDA ValueToMod
                          JSR SetTonePeriodCoarse
                          ; now set fine
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          CMP #$0f
                          BPL RZeroSet
RFFSet
                          LDA #$FF
                          JSR SetTonePeriodFine
                          RTS
RZeroSet
                          LDA #$00
                          JSR SetTonePeriodFine
                          RTS

; Txx handler
CommandT                  
                          ; read env period coarse -> ValueToMod
                          JSR GetTonePeriodCoarse
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          ; setting env param
                          LDA ValueToMod
                          JSR SetTonePeriodCoarse
                          RTS

; Uxx handler
CommandU                  
                          ; read env period coarse -> ValueToMod
                          JSR GetTonePeriodFine
                          STA ValueToMod
                          ;
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          JSR ModifyValue
                          LDA ValueToMod
                          ; setting env param
                          JSR SetTonePeriodFine
                          RTS

CommandS                  
                          LDY #8                                        ; read param
                          LDA (noteAddrLo),Y
                          CMP #$00
                          BEQ SBothOff
                          CMP #$10
                          BEQ SOnlyTone
                          CMP #$01
                          BEQ SOnlyNoise
                          CMP #$11
                          BEQ SBothOn
                          RTS
SBothOff                  JSR DisableNoise
                          JSR DisableTone
                          RTS
SBothOn                   JSR EnableNoise
                          JSR EnableTone
                          RTS
SOnlyTone                 JSR DisableNoise
                          JSR EnableTone
                          RTS
SOnlyNoise                JSR DisableTone
                          JSR EnableNoise
                          RTS      

ValueToMod               .byte $00
TempModParam             .byte $00



ModifyValue               ; A reg contains diff field
                          STA TempModParam
CheckModUp
                          LSR 
                          LSR 
                          LSR 
                          LSR
                          AND #$0f
                          BEQ CheckModDown
                          ; A contains modify up count
                          TAY 
ModUpLoop                 
                          LDA ValueToMod
                          CMP #$FF
                          BEQ ModUpOk
                          INC ValueToMod
                          DEY
                          BNE ModUpLoop
ModUpOk                    
                          RTS
                          ;;
CheckModDown              LDA TempModParam
                          AND #$0f
                          BEQ ModDownOk
                          ; mod down
                          TAY 
ModDownLoop                 
                          LDA ValueToMod
                          CMP #$00
                          BEQ ModDownOk
                          DEC ValueToMod
                          DEY
                          BNE ModDownLoop
ModDownOk                          
                          RTS 

; note player routine
noteAddrLo                .equ $D0
noteAddrHi                .equ $D1
noteChip                  .byte $0
noteChannel               .byte $0

; tracker state
patternListIndex          .byte $0  ; postion in pattern list
patternNum                .byte $0
patternPos                .byte $0
patternTrack              .byte $0
trackNote                 .byte $0

; pointer to current pattern
patternPtr                .equ $D2
patternPtrHi              .equ $D3

trackPtr                  .equ $D2
trackPtrHi                .equ $D3

noteTablePtr              .equ $D4
noteTablePtrHi            .equ $D5

; pointer to start of each track
trackPtr0                 .word $0000
trackPtr1                 .word $0000
trackPtr2                 .word $0000
trackPtr3                 .word $0000
trackPtr4                 .word $0000
trackPtr5                 .word $0000

noteTablePtr0             .word $0000
noteTablePtr1             .word $0000
noteTablePtr2             .word $0000
noteTablePtr3             .word $0000
noteTablePtr4             .word $0000
noteTablePtr5             .word $0000

LoadPattern               LDX patternListIndex
                          LDA SONGADDR,X
                          STA patternNum        ; current pattern id 
                          CLC
                          ROL
                          TAX
                          LDA PATTADDR,X        ; set patternPtr to address of pattern
                          STA patternPtr
                          LDA PATTADDR+1,X
                          STA patternPtr+1

                          LDY #0
CopyTPLoop                LDA (patternPtr),Y
                          STA trackPtr0,Y
                          INY
                          CPY #12
                          BNE CopyTPLoop
                          LDA #0                ; reset pattern pos
                          STA patternPos
                          RTS

; this routine will lookup and trigger a note in track 
tempNotenum               .byte $00
emptyCount                .byte $00
PlayNote                    
                          ; set trackPtr to current track, 
                          LDA patternTrack
                          CLC
                          ROL
                          TAX
                          LDA trackPtr0,X
                          STA trackPtr
                          LDA trackPtr0+1,X
                          STA trackPtr+1
                          ; 
                          LDY patternPos    ; index to note value
                          INY
                          INY               ; add 2 to it because note table is trackPtr + 2
                          LDA (trackPtr),Y
                          CMP #$FF
                          BNE PlayNoteValid
                          INC emptyCount
                          RTS
PlayNoteValid             ; current note is a valid note index
                          ; we need to get the pointer to the note data
                          ; and put it in noteAddrLo,noteAddrHi
                          PHA              ; store note number for later
                          LDY #0
                          LDA (trackPtr),Y
                          STA noteTablePtr
                          INY
                          LDA (trackPtr),Y
                          STA noteTablePtrHi
                          PLA
                          CLC
                          ROL
                          TAY 
                          LDA (noteTablePtr),Y
                          STA noteAddrLo
                          INY
                          LDA (noteTablePtr),Y
                          STA noteAddrHi
                          JSR SoundNote
                          RTS

PlayRow                   LDA #0
                          STA emptyCount
                          LDX #0                    ; play current row
                          STX noteChip
                          LDA #0
                          STA noteChannel
                          STA patternTrack
                          JSR PlayNote
                          ;
                          INC noteChannel
                          INC patternTrack
                          JSR PlayNote
                          ;
                          INC noteChannel
                          INC patternTrack
                          JSR PlayNote
                          ;
                          LDX #$80
                          STX noteChip
                          LDA #0
                          STA noteChannel
                          LDA #3
                          STA patternTrack
                          JSR PlayNote
                          ;
                          INC patternTrack
                          INC noteChannel
                          JSR PlayNote
                          ;
                          INC patternTrack
                          INC noteChannel
                          JSR PlayNote
                          ;
                          RTS

skipAdvance               .byte $00

; 
TimeCircuitsActivated     .byte $00
DestinationPatternIndex   .byte $00
DestinationPatternRow     .byte $00

NextRow                   
                          LDA TimeCircuitsActivated
                          BEQ NextRowOk
                          ; something has requested a time jump in the song, so 
                          ; do it and exit...
                          LDA #0
                          STA TimeCircuitsActivated
                          LDA DestinationPatternIndex
                          STA patternListIndex
                          JSR LoadNewPattern
                          LDA DestinationPatternRow
                          STA patternPos
                          RTS
NextRowOk
                          INC patternPos
                          LDA patternPos
                          CMP #$40
                          BEQ NextPattern
                          RTS

NextPattern               LDA #0
                          STA patternPos
                          INC patternListIndex
LoadNewPattern            LDX patternListIndex
                          LDA SONGADDR,X
                          CMP #$FF
                          BEQ LoopPatternList
                          JSR LoadPattern
                          RTS
LoopPatternList           LDX #0
                          STX patternListIndex
                          JSR LoadPattern
                          ; JSR MBInit
                          RTS

StartSong                 JSR MBInit
                          LDA #0
                          STA patternListIndex
                          STA patternNum
                          STA patternPos
                          STA patternTrack
                          JSR LoadPattern       ; load first pattern
                          RTS

; rest of the includes
                    .include via
                    .include mock
                    .include tempo
                    .include song