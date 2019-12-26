.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
    li x1,0x80
    li x3,0xdeadc0de
    sw x3,0(x1)

    lw x2,0(x1)
    li x1,0x10080

    #0000000 00000 00001 011 00000 0100011
    #0000 0000 0000 0000 1011 0000 0010 0011

    .word 0x0000B023

    li x1,0x80
    lw x2,0(x1)

    beq x2,x3,vtrue 
vfalse:
    csrrwi zero,0x103,1
    j vfalse
vtrue:
    csrrwi zero,0x103,0
    j vtrue

.align(8)
globals:
