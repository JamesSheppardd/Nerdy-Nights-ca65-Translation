.segment "HEADER"
    .byte "NES"
    .byte $1a
    .byte $02
    .byte $01
    .byte %00000001
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00, $00, $00, $00, $00

.segment "ZEROPAGE"
.segment "STARTUP"
.segment "CODE"
vblankwait:
:
    BIT $2002
    BPL :-
    RTS 

RESET:
    SEI         ; disable IRQs
    CLD         ; disable decimal mode
    LDX #$40
    STX $4017   ; disable APU frame counter 
    LDX #$ff    ; setup the stack
    TXS 
    INX 
    STX $2000   ; disable NMI
    STX $2001   ; disable rendering
    STX $4010   ; disable DMC IRQs

    JSR vblankwait  ; using a subroutine to get vblankwait, as is easier to manage

    TXA         ; make A $00 
clearmem:
    STA $0000,X
    STA $0100,X
    STA $0300,X
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    LDA #$FE
    STA $0200,X   ; set aside area in RAM for sprite memory
    LDA #$00
    INX 
    BNE clearmem

    JSR vblankwait

    LDA #$02    ; load A with the high byte for sprite memory
    STA $4014   ; this uploads 256 bytes of data from the CPU page $XX00 - $XXFF (XX is 02 here) to the internal PPU OAM
    NOP         

loadpalettes:
    LDA $2002   ; reset high/low latch of $2006
    LDA #$3F
    STA $2006   ; write high byte of $3F00 address
    LDA #$00
    STA $2006   ; low byte of address

    LDX #$00
loadpaletteloop:
    LDA palettedata,X; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
    STA $2007       ; write to PPU
    INX 
    CPX #$20        ; compare to $20 - decimal 32 - as copying 32 bytes - 16 bytes of background palette and 16 bytes of sprite palettes
    BNE loadpaletteloop

    LDX #$00
loadsprites:
    ; need to enable NMI so that sprite DMA occurs, where sprite data is written to the ppu memory
    LDA spritedata,X    ; load data from spritedata + x
    STA $0200,X         ; store in RAM
    INX 
    CPX #$20            ; compare to #$20
    BNE loadsprites

    CLI                 ; clear interrupts disable flag
    LDA #%10000000      ; enable NMI
    STA $2000

    LDA #%00010000      ; enable sprite rendering
    STA $2001

forever:
    JMP forever

VBLANK:
    LDA #$02
    STA $4014

latchcontroller:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016   ; tell controller to latch buttons


; ----------- button order: A, B, Select, Start, Up, Down, Left, Right -----------
readA:
    LDA $4016       ; player 1 A
    AND #%00000001  ; only look at the first bit - will be 1 if a being pressed
    BEQ buttonAdone ; branches to buttonAdone if A not being pressed
    ;; code for when pressed

    LDA $0203   ; load sprite 0 x position
    CLC         ; clear carry flag for addition
    ADC #$01    ; add 1 to x position - move right
    STA $0203   ; store back into sprite 0 x position
buttonAdone:

readB:
    LDA $4016
    AND #%00000001
    BEQ buttonBdone ; leave if button not pressed
    ;; code for when pressed

    LDA $0203   ; load sprite 0 x position
    SEC         ; set carry flag for subtraction
    SBC #$01    ; subtract 1 to x position - move left
    STA $0203   ; store back into sprite 0 x position
buttonBdone:

readSTART:
    LDA $4016
    AND #%00000001
    BEQ buttonSTARTdone

buttonSTARTdone:

readSELECT:
    LDA $4016
    AND #%00000001
    BEQ buttonSELECTdone

buttonSELECTdone:

readUP:
    LDA $4016
    AND #%00000001
    BEQ buttonUPdone

;;; Hide if you want a challenge - setup movement using the D-Pad from what you've learnt
    ;; move all 8 sprites 
    LDA $0200       ; load Y position of first sprite
    SEC             ; set the carry flag as we SBC
    SBC #$01        ; minus $01 to the Y position
    STA $0200
    STA $0204
    ;; row 2 of sprites
    LDA $0208       
    SEC             
    SBC #$01        
    STA $0208
    STA $020C

    ;; row 3 of sprites
    LDA $0210       
    SEC             
    SBC #$01        
    STA $0210
    STA $0214

    ;; row 4 of sprites
    LDA $0218       
    SEC             
    SBC #$01        
    STA $0218
    STA $021C

buttonUPdone:

readDOWN:
    LDA $4016
    AND #%00000001
    BEQ buttonDOWNdone

;;; Hide if you want a challenge - setup movement using the D-Pad from what you've learnt
    ;; move all 8 sprites 
    LDA $0200       ; load Y position of first sprite
    CLC             ; set the carry flag as we SBC
    ADC #$01        ; minus $01 to the Y position
    STA $0200
    STA $0204
    ;; row 2 of sprites
    LDA $0208       
    CLC             
    ADC #$01        
    STA $0208
    STA $020C

    ;; row 3 of sprites
    LDA $0210       
    CLC             
    ADC #$01        
    STA $0210
    STA $0214

    ;; row 4 of sprites
    LDA $0218       
    CLC             
    ADC #$01        
    STA $0218
    STA $021C

buttonDOWNdone:

readLEFT:
    LDA $4016
    AND #%00000001
    BEQ buttonLEFTdone

;;; Hide if you want a challenge - setup movement using the D-Pad from what you've learnt
    ;; move all 8 sprites 
    LDA $0203       ; load X position of first sprite
    SEC             ; set the carry flag as we SBC
    SBC #$01        ; add $01 to the X position
    ;; as there is 4 sprites with the same X pos, just update all here so it quick
    STA $0203       ; save sprite 1 x change
    STA $020B       ; save sprite 3 x change
    STA $0213       ; save sprite 5 x change
    STA $021B       ; save sprite 7 x change

    LDA $0207
    SEC 
    SBC #$01
    STA $0207       ; save sprite 2 x change
    STA $020F       ; save sprite 4 x change
    STA $0217       ; save sprite 6 x change
    STA $021F       ; save sprite 8 x change

buttonLEFTdone:

readRIGHT:
    LDA $4016
    AND #%00000001
    BEQ buttonRIGHTdone

;;; Hide if you want a challenge - setup movement using the D-Pad from what you've learnt
    ;; move all 8 sprites 
    LDA $0203       ; load X position of first sprite
    CLC             ; clear the carry flag as we ADC 
    ADC #$01        ; add $01 to the X position
    ;; as there is 4 sprites with the same X pos, just update all here so it quick
    STA $0203       ; save sprite 1 x change
    STA $020B       ; save sprite 3 x change
    STA $0213       ; save sprite 5 x change
    STA $021B       ; save sprite 7 x change

    LDA $0207
    CLC 
    ADC #$01
    STA $0207       ; save sprite 2 x change
    STA $020F       ; save sprite 4 x change
    STA $0217       ; save sprite 6 x change
    STA $021F       ; save sprite 8 x change

buttonRIGHTdone:

@done:
    RTI 

palettedata:
    .byte $22, $29, $1a, $0F, $22, $36, $17, $0F, $22, $30, $21, $0F, $22, $27, $17, $0F  ; background palette data
    .byte $22, $16, $27, $18, $22, $1A, $30, $27, $22, $16, $30, $27, $22, $0F, $36, $17  ; sprite palette data

spritedata:
    .byte $00, $00, $00, $08 ; YCoord, tile number, attr, XCoord
    .byte $00, $01, $00, $10
    .byte $08, $02, $00, $08
    .byte $08, $03, $00, $10
    .byte $10, $04, $00, $08
    .byte $10, $05, $00, $10
    .byte $18, $06, $00, $08
    .byte $18, $07, $00, $10

.segment "VECTORS"
    .word VBLANK
    .word RESET
    .word 0
.segment "CHARS"
    .incbin "mario.chr"