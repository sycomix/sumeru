.global _start
_start:
main:
    addi t0,zero,4
    addi t1,zero,4
mainloop:
    beq t0,t1,vtrue
vfalse:
    j vfalse
vtrue:
    j vtrue

.align(8)
globals:
