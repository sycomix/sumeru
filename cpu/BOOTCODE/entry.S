#include "machine/constants.h"
.globl _start, main
_start:
ivec:
ivec_boot:
    j asm_entry
    nop 
    nop
    nop
ivec_timer:
    sw a0,0(zero)
    li a0,INTR_ID_TIMER
    j asm_handle_interrupt
    nop
ivec_uart_tx:
    sw a0,0(zero)
    li a0,INTR_ID_UART0_TX
    j asm_handle_interrupt
    nop
ivec_uart_rx:
    sw a0,0(zero)
    li a0,INTR_ID_UART0_RX
    j asm_handle_interrupt
    nop

asm_entry:
    lui sp,0x1
    jal ra,main
asm_entry_done:
    j asm_entry_done

#stack pointer points to next free for use 
asm_handle_interrupt:
    sw a1,4(zero)
    li a1,1
    beq a0,a1,1f 
    li a1,2
    beq a0,a1,2f 
    li a1,3
    beq a0,a1,3f 
    j intr_return

1:
    la a0,g_timer_intr_pending
    sw zero,0(a0)
    j intr_return
2:
    la a0,g_uart0_tx_intr_pending
    sw zero,0(a0)
    j intr_return
3:
    la a0,g_uart0_rx_intr_pending
    sw zero,0(a0)

intr_return:
    lw a1,4(zero)
    csrrsi a0,CSR_REG_CTX_PCSAVE,0
    csrrw  zero,CSR_REG_CTX_PCSWITCH,a0
    lw a0,0(zero)
    csrrwi zero,CSR_REG_SWITCH,0

#******* not reached ***********

