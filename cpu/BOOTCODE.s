.global _start
_start:
main:
    li t0, 1
    li t1, 1
    csrrw zero,0x100,t0
mainloop:
    beq t0,t1,vtrue
vfalse:
    csrrwi zero,0x103,1
    j vfalse
vtrue:
    csrrwi zero,0x103,0
    j vtrue

.align(8)
globals:
