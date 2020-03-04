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
    sw sp,4(zero)
    sw ra,8(zero)
    # -- We use the user stack to service interrupts
    sw x5,-4(sp)
    sw x6,-8(sp)
    sw x7,-12(sp)
    sw x11,-16(sp)
    sw x12,-20(sp)
    sw x13,-24(sp)
    sw x14,-28(sp)
    sw x15,-32(sp)
    sw x16,-36(sp)
    sw x17,-40(sp)
    sw x28,-44(sp)
    sw x29,-48(sp)
    sw x30,-52(sp)
    sw x31,-56(sp)
    addi sp,sp,-64
    call handle_interrupt
#    la ra, g_uart0_tx_intr_pending
#    sw zero, 0(ra)
    addi sp,sp,64
    lw x5,-4(sp)
    lw x6,-8(sp)
    lw x7,-12(sp)
    lw x11,-16(sp)
    lw x12,-20(sp)
    lw x13,-24(sp)
    lw x14,-28(sp)
    lw x15,-32(sp)
    lw x16,-36(sp)
    lw x17,-40(sp)
    lw x28,-44(sp)
    lw x29,-48(sp)
    lw x30,-52(sp)
    lw x31,-56(sp)
intr_return:
    lw sp,4(zero)
    lw ra,8(zero)
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
    li sp,STACK_START_LOC

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

  # Populate malloc pool with 26M memory starting at 4M
  li      a0, MALLOC_MEM_START
  li      a1, MALLOC_MEM_SIZE
  call    add_malloc_block

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

