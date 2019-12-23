.global _start
_start:
    li t0,0
    
main:
    addi t0,t0,1
    addi t0,t0,1
    j main

.align(8)
globals:
