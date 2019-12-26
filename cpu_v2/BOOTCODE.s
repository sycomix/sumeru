.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
    li x1,0x80
    li x3,0xc081
    sh x3,2(x1)
    fence.i
    lbu x2,2(x1)
    li x3,0x81
    beq x2,x3,vtrue 
vfalse:
    csrrwi zero,0x103,1
    j vfalse
vtrue:
    csrrwi zero,0x103,0
    j vtrue

.align(8)
globals:
