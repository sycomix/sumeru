.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,0
    li t0,1
    li t1,1
    beq t0,t1,vtrue
vfalse:
    csrrwi zero,0x103,1
    j vfalse
vtrue:
    csrrwi zero,0x103,0
    j vtrue

.align(8)
globals:
