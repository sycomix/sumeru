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
inline unsigned int
gpio_get_out()
{
    unsigned int x;
    asm volatile("csrrsi %0, 0x882, 0;" : "=r"(x));
    return x;
}

#endif
