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
    ;; Variables
    gamestate:      .res 1  
    ballx:          .res 1  
    bally:          .res 1
    ballup:         .res 1  ; 1 = ball going up
    balldown:       .res 1  ; 1 = ball going down
    ballleft:       .res 1  ; 1 = ball going left
    ballright:      .res 1  ; 1 = ball going right
    ballspeedx:     .res 1
    ballspeedy:     .res 1
    paddle1ytop:    .res 1
    paddle1ybottom: .res 1
    paddle2ytop:    .res 1
    paddle2ybottom: .res 1
    score1:         .res 1  ; reserve 1 byte of RAM for score1 variable
    score2:         .res 1  ; reserve 1 byte of RAM for score2 variable
    buttons1:       .res 1  ; put controller data for player 1
    buttons2:       .res 1  ; put controller data for player 2 
    paddlespeed:    .res 1
    
    ;; Constants
    STATETITLE      = $00   ; is on title screen
    STATEPLAYING    = $01   ; is playing game
    STATEGAMEOVER   = $02   ; is gameover

    RIGHTWALL       = $E5   ; when the ball reaches one of these we'll do some bounce logic
    TOPWALL         = $20
    BOTTOMWALL      = $E0
    LEFTWALL        = $04

    PADDLE1X        = $15 
    PADDLE2X        = $D4
    ;;;;;;;;;;; 
    BALLSTARTX      = $80
    BALLSTARTY      = $50

.segment "STARTUP"
.segment "CODE"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subroutines ;;;
vblankwait: 
    BIT $2002
    BPL vblankwait
    RTS 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup code ;;;
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

    JSR vblankwait

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
    NOP         ; takes 513 or 514 CPU cycles, so this basically pauses program I think?

clearnametables:
    LDA $2002   ; reset PPU status
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
    LDX #$08    ; prepare to fill 8 pages ($800 bytes)
    LDY #$00    ; X/Y is 16-bit counter, bigh byte in X
    LDA #$24    ; fill with tile $24 (sky block)
:
    STA $2007
    DEY 
    BNE :-
    DEX 
    BNE :-

loadpalette:
    LDA $2002 
    LDA #$3f
    STA $2006
    LDA #$00
    STA $2006

    LDX #$00
loadpaletteloop:
    LDA palettedata,X
    STA $2007
    INX 
    CPX #$20
    BNE loadpaletteloop

;;; set intial ball values
    LDA #$01
    STA ballright
    STA ballup
    LDA #$00
    STA balldown
    STA ballleft

    LDA #BALLSTARTY
    STA bally

    LDA #BALLSTARTX
    STA ballx

    LDA #$01
    STA ballspeedx
    STA ballspeedy

;;; set paddle speed + start position
    LDA #$02
    STA paddlespeed
    LDA #$10
    STA paddle1ytop
    LDA #$18
    STA paddle1ybottom

    LDA #$10
    STA paddle2ytop
    LDA #$18
    STA paddle2ybottom
    
;;; Set starting game state
    LDA #STATEPLAYING
    STA gamestate

    CLI             ; clear interrupt flag
    LDA #%10010000  ; enable NMI, sprites from pattern table 0, background from pattern table 1
    STA $2000

    LDA #%00011110  ; background and sprites enable, no clipping on left
    STA $2001

forever:
    JMP forever

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VBLANK loop - called every frame ;;;
VBLANK:
    LDA #$00
    STA $2003   ; low byte of RAM address
    LDA #$02
    STA $4014   ; high byte of RAM address, start transfer

    ;; PPU clean up section, so rendering the next frame starts properly
    LDA #%10010000  ; enable NMI, sprites from pattern table 0, background from pattern table 1
    STA $2000
    LDA #%00011110  ; enable sprites, background, no left side clipping
    STA $2001
    LDA #$00
    STA $2005       ; no X scrolling
    STA $2005       ; no Y scrolling

    ;;;; all graphics updates run by now, so run game engine
    JSR readcontroller1 ; get current button data for player 1
    JSR readcontroller2 ; get current button data for player 2

GAMEENGINE:
    LDA gamestate
    CMP #STATETITLE
    BEQ enginetitle ; is it on title screen?
    
    LDA gamestate
    CMP #STATEGAMEOVER
    BEQ enginegameover ; is it on gameover screen?
    
    LDA gamestate
    CMP #STATEPLAYING
    BEQ engineplaying ; is it on playing screen?
GAMEENGINEDONE:
    JSR updatesprites   ; set ball/paddle sprites

    RTI 

enginetitle:
    ;;  if start button pressed
    ;;      turn screen off
    ;;      load game screen
    ;;      set starting paddle/ball position
    ;;      go to playing state
    ;;      turn screen on
    JMP GAMEENGINEDONE

enginegameover:
    ;;  if start button pressed
    ;;      turn screen off
    ;;      load title screen
    ;;      go to title screen
    ;;      turn screen on
    JMP GAMEENGINEDONE

engineplaying:

moveballright:
    LDA ballright   ; is ball moving right?
    BEQ moveballrightdone   ; if ballright = 0 then skip

    LDA ballx 
    CLC     ; clear carry cos we adding 
    ADC ballspeedx 
    STA ballx       ; new ball x = ball x + ball x speed

    LDA ballx 
    CMP #RIGHTWALL  ; if ball x < right wall, still on screen, then skip next section - CMP sets Carry if >=
    BCC moveballrightdone 
    LDA #$00 
    STA ballright 
    LDA #$01
    STA ballleft    ; set moving right to falase, and bounce
    ; increase player 1 score, reset ball to center
moveballrightdone:

moveballleft:
    LDA ballleft   ; is ball moving left?
    BEQ moveballleftdone   ; if ballleft = 0 then skip

    LDA ballx 
    SEC     ; set carry cos we subtracting 
    SBC ballspeedx 
    STA ballx       ; new ball x = ball x - ball x speed

    LDA ballx 
    CMP #LEFTWALL  ; if ball x > left wall, still on screen, then skip next section - CMP sets Carry if >=
    BCS moveballleftdone   ; branch if carry
    LDA #$00 
    STA ballleft 
    LDA #$01
    STA ballright    ; set moving left to falase, and bounce
    ; increase player 2 score, reset ball to center
moveballleftdone:

moveballup:
    LDA ballup   ; is ball moving up?
    BEQ moveballupdone   ; if ballup = 0 then skip

    LDA bally 
    SEC     ; set carry cos we subtracting 
    SBC ballspeedy 
    STA bally       ; new ball y = ball y - ball y speed

    LDA bally 
    CMP #TOPWALL  ; if ball y > top wall, still on screen, then skip next section - CMP sets Carry if >=
    BCS moveballupdone   ; branch if carry
    LDA #$00 
    STA ballup 
    LDA #$01
    STA balldown    ; set moving up to falase, and bounce
moveballupdone:

moveballdown:
    LDA balldown   ; is ball moving down?
    BEQ moveballdowndone   ; if balldown = 0 then skip

    LDA bally 
    CLC     ; clear carry cos we adding 
    ADC ballspeedy 
    STA bally       ; new ball y = ball y + ball y speed

    LDA bally 
    CMP #BOTTOMWALL  ; if ball y < bottom wall, still on screen, then skip next section - CMP sets Carry if >=
    BCC moveballdowndone   ; branch if carry

    LDA #$00 
    STA balldown 
    LDA #$01
    STA ballup    ; set moving down to falase, and bounce
moveballdowndone:

movepaddleup:
    ;;  if up pressed
    ;;      if paddle top > top wall
    ;;          move paddle top and bottom up

movepaddleupdone:

movepaddledown:
    ;;  if down pressed
    ;;      if paddle bottom < bottom wall
    ;;          move paddle top and bottom down

movepaddledowndone:
checkpaddlecollision:
    ;;if ball x < paddle1x
        ;;  if ball y > paddle y top
        ;;    if ball y < paddle y bottom
        ;;      bounce, ball now moving left
checkpaddlecollisiondone:

    JMP GAMEENGINEDONE

updatesprites:
    ;; ball sprites
    LDA bally 
    STA $0200

    LDA #$75    ; tile
    STA $0201

    LDA #$00
    STA $0202

    LDA ballx 
    STA $0203

    ;;; paddle sprites

    RTS

drawscore:
    ;;draw score on screen using background tiles
    ;;or using many sprites
    RTS

readcontroller1:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
readcontroller1loop:
    LDA $4016
    LSR A           ; Logical shift right - all bits in A are shifted to the right, bit7 is 0 and whatever is in bit0 goes to Carry flag
    ROL buttons1    ; Rotate left - opposite of LSR
    ;; used as a smart way to read controller inputs, as when each button is read, the button data is in bit0, and doing LSR puts the button 
    ;; in the Carry. Then ROL shifts the previous button data over and puts the carry back into bit0
    DEX 
    BNE readcontroller1loop
    RTS 

    
readcontroller2:
    LDA #$01
    STA $4017
    LDA #$00
    STA $4017
    LDX #$08
readcontroller2loop:
    LDA $4017
    LSR A           ; Logical shift right - all bits in A are shifted to the right, bit7 is 0 and whatever is in bit0 goes to Carry flag
    ROL buttons2    ; Rotate left - opposite of LSR
    ;; used as a smart way to read controller inputs, as when each button is read, the button data is in bit0, and doing LSR puts the button 
    ;; in the Carry. Then ROL shifts the previous button data over and puts the carry back into bit0
    DEX 
    BNE readcontroller2loop
    RTS 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sprite / palette / nametable / attributes ;;;
palettedata:
    .byte $22,$29,$1a,$0F,   $22,$36,$17,$0F,   $22,$30,$21,$0F,   $22,$27,$17,$0F  ; background palette data
    .byte $22,$16,$27,$18,   $22,$1A,$30,$27,   $22,$16,$30,$27,   $22,$0F,$36,$17  ; sprite palette data

spritedata:
    ;      Y  tile  attr  X
    .byte $80, $32, $00, $80 ; ball
    .byte $80, $33, $00, PADDLE1X
    .byte $88, $34, $00, $80
    .byte $88, $35, $00, PADDLE1X


.segment "VECTORS"
    .word VBLANK
    .word RESET
    .word 0
.segment "CHARS"
    .incbin "mario.chr"