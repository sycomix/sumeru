#include "machine/constants.h"
.section .text.ivector
.global _start
_start:
ivec:
ivec_boot:
    j _entry
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

.text

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

exit:
    j exit

_entry:
    #stack pointer always points to top of stack value
    # Initialize ivector address
    la sp,ivec
    csrrw zero,CSR_REG_IVECTOR_ADDR,sp
    # Setup the stack
    lui sp,0x1

  # Initialize global pointer
.option push
.option norelax
1:  auipc gp, %pcrel_hi(__global_pointer$)
    addi  gp, gp, %pcrel_lo(1b)
.option pop

  # Clear the bss segment
  la      a0, _edata
  la      a2, _end
  sub     a2, a2, a0
  li      a1, 0
  call    memset

  la      a0, __libc_fini_array   # Register global termination functions
  call    atexit                  #  to be called upon exit
  call    __libc_init_array       # Run global initialization functions

  li      a0, 0                  # a0 = argc = 0
  li      a1, 0                  # a1 = argv = NULL
  li      a2, 0                  # a2 = envp = NULL
  call    main
  tail    exit

.global _init
.global _fini
_init:
_fini:
  # These don't have to do anything since we use init_array/fini_array.
  ret

