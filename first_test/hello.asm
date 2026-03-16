; .setcpu "65816"
.p816
.a8
.i16

.include "snes.inc"
.include "charmap.inc"

.segment "HEADER"       ; +7FE0 in file
.byte "CA65 EXAMPLE"    ; ROM name

.segment "ROMINFO"      ; +7FD5 in memory
.byte $30               ; LoROM, fast-capable
.byte 0                 ; no battery RAM
.byte $07               ; 128k ROM
.byte 0,0,0,0
.word $AAAA,$5555       ;dummy checksum, compliment

.segment "CODE"
    jmp start

VRAM_CHARSET    = $0000 ; must be at $1000 boundary
VRAM_BG1        = $1000 ; must be at $0400 boundary
VRAM_BG2        = $1400 ; must be at $0400 boundary
VRAM_BG3        = $1800 ; must be at $0400 boundary
VRAM_BG4        = $1C00 ; must be at $0400 boundary
START_X         = 9
START_Y         = 14
START_TM_ADDR   = VRAM_BG1 + 32*START_Y + START_X

hello_str: .asciiz "Hello, world!"

start:
; Disable interrupts and enable native mode
    sei             ; disable IRQ interrupts
    clc             ; clear the carry
    xce             ; swap carry and emulate bit (turning off the emulation mode)
    cld             ; clear decimal mode
    clv             ; clear overflow status

    rep #$10        ; set x/y 16 bit
    sep #$20        ; set A 8 bit

    jmp ClearVRAM

    @loop:
    stz INIDISP,x
    stz NMITIMEN,x
    dex
    bpl @loop

    lda #128
    sta INIDISP ; undo the accidental stz to 2100h due to BPL actually being a branch on nonnegative

    ; set palette to black background and 3 shades of red
    stz CGADD
    stz CGDATA      ; none more black
    stz CGDATA
    lda #$10        ; color 1: dark red (0000 0000 0001 0000)
    sta CGDATA      ; low byte
    stz CGDATA      ; high byte
    lda #$1f        ; color 2: neutral red (0000 0000 0001 1111)
    sta CGDATA      ; low byte
    stz CGDATA      ; high byte
    lda #$1f        ; color 3: light red (0100 0010 0001 1111)
    sta CGDATA
    lda #$42
    sta CGDATA

    ; setup graphics mode 0, 8x8 tiles all layers
    stz BGMODE
    lda #>VRAM_BG1
    sta BG1SC       ; BG1 at VRAM_BG1, only single 32x32 map (4 way mirror)
    lda #((>VRAM_CHARSET >> 4) | (>VRAM_CHARSET & $F0))
    sta BG12NBA

    ; load character set into vram
    lda #$80
    sta VMAIN       ; VRAM stride of 1 word
    ldx #VRAM_CHARSET
    stx VMADDL
    ldx #0
@charset_loop:
    lda NESfont,x
    stz VMDATAL     ; color index low bit = 0
    sta VMDATAH     ; color index high bit set -> neutral red (2)
    inx
    cpx #(128*8)
    bne @charset_loop
@string_loop:
    lda hello_str,x
    beq @enable_display
    sta VMDATAL
    lda #$20        ; priority 1
    sta VMDATAH
    inx
    bra @string_l0oop
@enable_display:
    ; Show BG1
    lda #$01
    sta TM
    ; max screen brightess
    lda #$0F
    sta INIDISP

    ; enable NMI for vertical blank
    lda #$80
    sta NMITIMEN

game_loop:
    wai             ; pause until next interrupt complete (i.e. vblank processings done)
    ; do a thing
    jmp game_loop

nmi:
    rep #$10        ; x/y 16bit
    sep #$20        ; a 8 bit
    phd
    pha
    phx
    phy
    ; do stuff that needs to be done during vblank
    lda RDNMI       ; reset NMI flag
    ply
    plx
    pla
    pld
return_int:
    rti

;----------------------------------------------------------------------------
; ClearVRAM -- Sets every byte of VRAM to zero
; from bazz's VRAM tutorial
; In: None
; Out: None
; Modifies: flags
;----------------------------------------------------------------------------

ClearVRAM:
    pha
    phx
    php

    rep #$10        ; x/y 16bit
    sep #$20        ; a 8 bit

    lda #$80
    sta VMAIN       ; set VRAM port to word access
    ldx #$1809
    stx DMAPx       ; set dma mode to fixed source, word to $2118/9
    ldx #$0000
    stx VMADDL      ; store vram port address to $0000
    stx $0000       ; set $00:0000 to $0000 (assumes scratchpad ram)
    stx A1TxL       ; set source address to $xx:0000
    lda #$00
    sta $A1Bx       ; set source bank to $00
    ldx #$FFFF
    stx $DASxL      ; set transfer size to 64k-1 bytes
    lda #$01
    sta MDMAEN      ; initiate transfer

    stz VMDATAH     ; clear the last byte of the VRAM

    plp
    plx
    pla
    rts

.include "charset.asm"

.segment "VECTORS"
.word 0, 0          ; native mode vectors
.word return_int    ; COP
.word return_int    ; BRK
.word return_int    ; ABORT
.word nmi           ; NMI
.word start         ; RST
.word return_int    ; IRQ

.wrod 0,0           ; emulation mode vectors
.word return_int   ; COP
.word 0
.word return_int    ; ABORT
.word nmi           ; NMI
.word start         ; RST
.word return_int    ; IRQ