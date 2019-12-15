.global _start
_start:
main:
    addi t0,zero,1
mainloop:
    sll t0,t0,1
    j mainloop

.align(8)
globals:
