.global _start
_start:
    li t0,0
    li t1,0x8
    
main:
    addi t0,t0,1
    jalr zero, 0(t1)

.align(8)
globals:
