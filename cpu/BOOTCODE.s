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
    csrrw zero, 1, zero
    csrrw zero, 0, zero
    j vtrue

.align(8)
globals:
