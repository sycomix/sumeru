.global _start
_start:
main:
    lw t0,0x10(zero)
    li t1, 0x1030D073
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
mainloop:
    beq t0,t1,vtrue
vfalse:
    j vfalse
vtrue:
    csrrwi zero,0x103,0
    j vtrue

.align(8)
globals:
