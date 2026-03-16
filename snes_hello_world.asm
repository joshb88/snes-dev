

Curser_X = $40
Curser_Y = Curser_X+1

    org $8000   ;Start of ROM
    sei         ;stop interrupts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;screenInit

    ;aaaabbbb - aaa = base addr for BG2, bbb=base addr for BG1
    lda #%00010001
    sta $210B                   ; BG1 & BG2 VRAM location register [BG12NBA]

    ; xxxxxxss - xxx=address... ss=SC size  00=32x32 01 = 64x32,. 10=32x64 11=64x64
    stz $2107                   ;BG1SC - BG1 Tilemap VRAM location

    ;abcdefff - abcd=tile sizes e=pri fff=mode def
    lda #%00001001
    sta $2105                   ;BGMODE - screen mode register

    ; x000bbbb - x=screen disable (1=disable) bbbb (15 = max)
    lda #%10000000 ;0x80        ;screen off
    sta #2100                 ;INIDISP - screen display register


;paletteDefs

;Background (Color 0)
    stz $2121           ;CGADD - color selection (0=back)
        ;gggrrrrr
    stz $2122           ;CGDATA - color data register
         ;?bbbbbgg
    lda #%00111100 ; 0x3c
    sta $2122           ;CGDATA
;Font (Color 15)
    lda #15     ; color 15=Font
    sta $2121           ;CGADD - color selection  (15=font)
         ;gggrrrrr
    lda #%11111111
    sta $2122       ;CGDATA - color data regsiter
        ;?bbbbbgg
    lda#%00000011
    sta $2122       ;CGDATA

;TileDefs
    ;       i000abcd - I 1=inc on $2118 or $2139 0=$2118 or 213A abcd=move size
    stz $2115       ;VMAIN - video port control (inc on write to $2118)


;load_font
    stz $2116       ;VRAM MemL
    lda #$10
    sta $2117       ;VRAM MemH

    lda #BitmapFont&255
    sta $20
    lda #BitmapFont/256
    sta $21

    ldx #3          ;96 sprites * 8 lines = 768
    ldy #0
fontchar_loopx:
    phx

































































































Bitmapfont:
    incbin "\ResALL\Font96.FNT"