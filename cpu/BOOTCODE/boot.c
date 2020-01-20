#include <machine/csr.h>

void
start(void)
{
    unsigned int i = 0;
    gpio_set_dir(1);
    gpio_set_out(1);
    timer_set(0x004F);
    uart0_set_rx(0xa0001);

    while(1) {
        ++i;
        gpio_set_out((i >> 23) & 1);
    }
}


__attribute__ ((always_inline))
inline void
flush_word(unsigned int x)
{
    asm volatile("sw %0, 0(zero);" : : "r"(x));
    asm volatile(" \
        li x1,0x10000; \
        .word 0x0000B023; " : : : "x1");

}

void
handle_interrupt(int id)
{
    if (id == 1) {
        timer_set(0x04F);
    } else if (id == 2) {
        uart0_set_rx(0xa0001);
    } else if (id == 3) {
        uart0_set_tx(0xa0001);
    }
}
