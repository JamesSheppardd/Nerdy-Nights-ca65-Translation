.segment "HEADER"       ; Setting up the header, needed for emulators to understand what to do with the file, not needed for actual cartridges
    .byte "NES"         ; The beginning of the HEADER of iNES header
    .byte $1a           ; Signature of iNES header that the emulator will look for
    .byte $02           ; 2 * 16KB PRG (program) ROM
    .byte $01           ; 1 * 8KB CHR ROM 
    .byte %00000000     ; mapper and mirroring - no mapper here due to no bank switching, no mirroring - using binary as it's easier to control
    .byte $0            
    .byte $0
    .byte $0
    .byte $0
    .byte $0, $0, $0, $0, $0    ; unused
.segment "ZEROPAGE"
.segment "STARTUP"
.segment "CODE"

RESET:
    SEI             ; disable IRQs
    CLD             ; disable decimal mode
    LDX #$40
    STX $4017       ; disable APU frame counter IRQ - disable sound
    LDX #$ff
    TXS             ; setup stack starting at FF as it decrements instead if increments
    INX             ; overflow X reg to $00
    STX $2000       ; disable NMI - PPUCTRL reg
    STX $2001       ; disable rendering - PPUMASK reg
    STX $4010       ; disable DMC IRQs

vblankwait1:        ; wait for vblank to make sure PPU is ready
    BIT $2002       ; returns bit 7 of ppustatus reg, which holds the vblank status with 0 being no vblank, 1 being vblank
    BPL vblankwait1

clearmem:
    LDA #$00        ; can also do TXA as x is $#00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    LDA #$fe
    STA $0200, x    ; Set aside space in RAM for sprite data
    INX 
    BNE clearmem

vblankwait2:        ; PPU is ready after this
    BIT $2002
    BPL vblankwait2

clearpalette:
    ; Need to clear both palettes to $00. 
    LDA $2002   ; read PPU status to reset PPU address
    LDA #$3F    ; Set PPU address to BG palette RAM ($3F00)
    STA $2006
    LDA #$00
    STA $2006

    LDX #$20    ; Loop $20 (16) times (up to $3F20)
    LDA #$00    ; Set each entry to $00

:
    STA $2007
    DEX
    BNE :-      ; using anonymous label, don't use these too often unless travelling very small distances in code

    LDA #%10000000  ; intensify blues
    STA $2001       ; in $2001 bits are BGRs bMmG (BGR is colour emphasis)

forever:
    JMP forever     ; an infinite loop when init code is run

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    RTI  ; Aren't actually doing anything in the program each frame, so just return from the interrupt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "VECTORS"
    .word  NMI
    .word  RESET
    .word  0
.segment "CHARS"