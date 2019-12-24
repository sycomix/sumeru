.global _start
_start:
    li t0,0
    csrrwi zero,0x100,1
    csrrwi zero,0x103,1
main:
    addi t0,t0,1
    srli t1,t0,25
    csrrw zero,0x103,t1
    j main

.align(8)
globals:
