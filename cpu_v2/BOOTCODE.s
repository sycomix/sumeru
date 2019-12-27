.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
    li x1,0
loop:
    addi x1,x1,1
    srli x2,x1,20
    andi x2,x2,1
    csrrw zero,0x103,x2
    j loop
