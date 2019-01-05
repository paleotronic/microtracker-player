; This file represents tempo values for use with the 6522 timer function
; <counter:word>,<ticksneeded:byte>

SetTempo    ; A contains the tempo index requested
            STX PSGSaveX
            TAX
            LDA TEMPOTIMER1LO,X
            STA TickInterval+0
            LDA TEMPOTIMER1HI,X
            STA TickInterval+1
            LDA TEMPOTICKCOUNT,X
            STA TicksNeeded 
            INC ResetTicks
            LDX PSGSaveX
            RTS 
    
