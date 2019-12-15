.global _start
_start:
main:
    addi t0,zero,2
    addi t1,zero,4
mainloop:
    addi t0,t0,1
    addi t1,t1,1
    j mainloop

.align(8)
globals:
