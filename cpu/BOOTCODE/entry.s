.globl boot
ivec:
ivec_boot:
    j _start
    nop 
    nop
    nop
ivec_timer:
    j _start2
    nop 
    nop
    nop
ivec_uart_tx:
    j _start2
    nop 
    nop
    nop
