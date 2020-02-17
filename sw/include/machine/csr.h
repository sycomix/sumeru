#ifndef __SUMERU_CSR_H
#define __SUMERU_CSR_H

#include <machine/constants.h>

__attribute__ ((always_inline))
inline void
ivector_set_addr(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_IVECTOR_ADDR));
}


__attribute__ ((always_inline))
inline void
uart0_set_tx(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_UART0_TX));
}


__attribute__ ((always_inline))
inline unsigned int
uart0_get_tx()
{
    unsigned int v = 0x80000000;
    unsigned int x;
    asm volatile("csrrw %0, %2, %1;" : "=r"(x) : "r"(v), "i"(CSR_REG_UART0_TX));
    return x;
}


__attribute__ ((always_inline))
inline unsigned int
uart0_get_rx()
{
    unsigned int v = 0x80000000;
    unsigned int x;
    asm volatile("csrrw %0, %2, %1;" : "=r"(x) : "r"(v), "i"(CSR_REG_UART0_RX));
    return x;
}


__attribute__ ((always_inline))
inline void
uart0_set_rx_baud(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_UART0_RX_BAUD));
}


__attribute__ ((always_inline))
inline void
uart0_set_tx_baud(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_UART0_TX_BAUD));
}


__attribute__ ((always_inline))
inline void
uart0_set_rx(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_UART0_RX));
}


__attribute__ ((always_inline))
inline void
timer_set(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_TIMER_CTRL));
}


__attribute__ ((always_inline))
inline unsigned int
timer_get_count()
{
    unsigned int x;
    asm volatile("csrrsi %0, 0xCC2, 0;" : "=r"(x));
    return x;
}


__attribute__ ((always_inline))
inline void
gpio_set_dir(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_GPIO_DIR));
}


__attribute__ ((always_inline))
inline void
gpio_set_out(unsigned int x)
{
    asm volatile("csrrw x0, %1, %0;" : : "r"(x), "i"(CSR_REG_GPIO_OUT));
}


__attribute__ ((always_inline))
inline void
gpio_set_dummy(unsigned int x)
{
    asm volatile("csrrw x0, 0, %0;" : : "r"(x));
}


__attribute__ ((always_inline))
inline unsigned int
rdtime()
{
    unsigned int x;
    asm volatile("rdtime %0;" : "=r"(x));
    return x;
}


__attribute__ ((always_inline))
inline unsigned int
rdcycle()
{
    unsigned int x;
    asm volatile("rdcycle %0;" : "=r"(x));
    return x;
}


__attribute__ ((always_inline))
inline unsigned int
rdinstret()
{
    unsigned int x;
    asm volatile("rdinstret %0;" : "=r"(x));
    return x;
}

#endif
