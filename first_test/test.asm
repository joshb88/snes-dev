; Disable interrupts and enable native mode
sei         ; disable IRQ interrupts
clc         ; clear the carry
xce         ; swap carry and emulate bit (turning off the emulation mode)
cld         ; clear decimal mode

rep #$30    ; set A, X, Y registers to 16 bit

clv         ; clear overflow status

; set 