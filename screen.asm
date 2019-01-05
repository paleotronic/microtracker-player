; monitor calls
SCRNFUNC        .equ $FC2C

ClearScreen
            LDX #160
            LDX #$00
CSLoop1     
            STA $400,X
            STA $500,X
            STA $600,X
            STA $700,X
            INX
            BNE CSLoop1
            RTS


            
             