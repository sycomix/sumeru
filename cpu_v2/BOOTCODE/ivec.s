.globl ivec
ivec:
ivec_entry_boot:
    j _start
    nop 
    nop
    nop
ivec_entry_timer:
    j _start2
    nop
    nop
    nop
