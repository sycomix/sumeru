.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
    li t0,1
    li t1,1
    beq t0,t1,vtrue
vfalse:
    csrrwi zero,0x103,1
vfloop:
    j vfloop
vtrue:
    csrrwi zero,0x103,0
vtloop:
    j vtloop

.align(8)
globals:
