.globl boot
ivec:
ivec_boot:
    j _start
    nop 
    nop
    nop
ivec_timer:
    sw x1,0(zero)
    li x1,1
    j asm_handle_interrupt
    nop
ivec_uart_tx:
    sw x1,0(zero)
    li x1,2
    j asm_handle_interrupt
    nop
ivec_uart_rx:
    sw x1,0(zero)
    li x1,3
    j asm_handle_interrupt
    nop

#stack pointer points to next free for use 
asm_handle_interrupt:
    sw sp,4(zero)
    lui sp,0x2
    sw x5,-4(sp)
    sw x6,-8(sp)
    sw x7,-12(sp)
    sw x10,-16(sp)
    sw x11,-20(sp)
    sw x12,-24(sp)
    sw x13,-28(sp)
    sw x14,-32(sp)
    sw x15,-36(sp)
    sw x16,-40(sp)
    sw x17,-44(sp)
    sw x28,-48(sp)
    sw x29,-52(sp)
    sw x30,-56(sp)
    sw x31,-60(sp)
    addi sp,sp,-60
    addi a0,x1,0  
    jal ra,handle_interrupt
    addi sp,sp,60
    lw x5,-4(sp)
    lw x6,-8(sp)
    lw x7,-12(sp)
    lw x10,-16(sp)
    lw x11,-20(sp)
    lw x12,-24(sp)
    lw x13,-28(sp)
    lw x14,-32(sp)
    lw x15,-36(sp)
    lw x16,-40(sp)
    lw x17,-44(sp)
    lw x28,-48(sp)
    lw x29,-52(sp)
    lw x30,-56(sp)
    lw x31,-60(sp)
    lw sp,4(zero)
    csrrsi x1,0xCC0,0
    csrrw  x0,0x880,x1
    lw x1,0(zero)
    csrrwi x0,0x9C0,0

#******* not reached ***********


