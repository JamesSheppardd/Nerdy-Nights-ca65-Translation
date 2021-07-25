.segment "HEADER"
    .byte "NES"
    .byte $1a
    .byte $02
    .byte $01
    .byte %00000000
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00, $00, $00, $00, $00
.segment "ZEROPAGE"
.segment "STARTUP"
.segment "CODE"

RESET: 
    SEI         ; Disable IRQs
    CLD         ; Get rid of decimal mode
    LDX #$40    
    STX $4017   ; Set interrupt inhibitor bit in APU frame counter on
    LDX #$ff    ; Initialise stack
    TXS 
    INX 
    STX $2000   ; Disable NMI
    STX $2001   ; Disable rendering
    STX $4010   ; Disable DMC IRQs

vblankwait1:
    BIT $2002
    BPL vblankwait1

clearmem:
    LDA #$00
    STA $0000,X
    STA $0100,X
    STA $0300,X
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    LDA #$FE
    STA $0200,X     ; move all sprites off screen
    INX 
    BNE clearmem

vblankwait2:        ; second wait for vblank, PPU ready after this
    BIT $2002
    BPL vblankwait2


;****************  NEW CODE  ****************
loadpalettes:       
    LDA #$02    ; Most significant byte of memory range that we want to read to sprite memory, as set aside $0200 for sprite loading
    STA $4014   ; OAM DMA register - access to sprite memory
    NOP         ; stands for "No Operation" - burns the cycle as PPU needs a moment to do its thing

    LDA $2002   ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006   ; write high byte of $3F00 address
    LDA #$00
    STA $2006   ; write low byte of $3F00 address
                ; the $3F00 address is the memory location for the background palette, going to $3F0F (16 bytes)
                ; the sprite palette is at $3F10, ending at $3F1F, which is 32 bytes > $3F00, so want to loop 32 times
    LDX #$00
loadpaletteloop:
    LDA palettedata,X   ; load palette byte
    STA $2007           ; write to PPU
    INX                 ; increment X
    CPX #$20            ; loop 32 times to write address from $3F00 -> $3F1F 
    BNE loadpaletteloop ; if x = $20, 32 bytes copied, all done, else loop back

    LDX #$00

;;; A bit different to how L4 of Nerdy Nights does it, as they load in sprites individually, yet this is the same method just more structured, using spritedata stored after NMI 
loadsprites:
    ; need to enable NMI so that sprite DMA occurs, where sprite data is written to the ppu memory
    LDA spritedata,X    ; accesses each sprite in spritedata starting at index 0, like reading from an array in high level languages
    STA $0200,X         ; store in sprite memory in RAM
    INX 
    CPX #$20            ; each sprite holds 4 bytes of data - Ycoord, tile, attributes and Xcoord - and there are 8 sprites, so 8*4 = 32, or $20
    BNE loadsprites

    CLI                 ; clear interrups so NMI can be called
    LDA #%10000000      
    STA $2000           ; the left most bit of $2000 sets wheteher NMI is enabled or not

    LDA #%00010000      ; enable sprites
    STA $2001

forever:
    JMP forever

VBLANK:
    ; happens at the start of each frame, so has to go here
    LDA #$02
    STA $4014   ; set high byte (02) of RAM, start transfer
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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