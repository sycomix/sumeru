.global _start
_start:
main:
    addi t0,zero,4
mainloop:
    jalr t1,t0,0

.align(8)
globals:
