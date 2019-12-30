.global _start
_start:
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
    li x1, 0x18
    jalr x2,0(x1)
loop:
    j loop

fun_a:
    csrrwi zero,0x103,0
    jalr zero,0(x2)
