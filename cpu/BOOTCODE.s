.global _start
_start:
main:
    li t0, 1
    li t1, 1
    csrrw zero,0x100,t0
    csrrw zero,0x103,t0
mainloop:
    beq t0,t1,vtrue
vfalse:
    j vfalse
vtrue:
    addi t0,t0,1
    srli t1,t0,25
    csrrw zero,0x103,t1
    j vtrue

.align(8)
globals:
