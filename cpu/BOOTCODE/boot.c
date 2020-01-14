void    _start(void) __attribute__ (( naked ));
void    handle_interrupt(int id);

__attribute__ ((always_inline))
inline void
flush_word(unsigned int x)
{
    asm volatile("sw %0, 0(zero);" : : "r"(x));
    asm volatile(" \
        li x1,0x10000; \
        .word 0x0000B023; " : : : "x1");

}

__attribute__ ((always_inline))
inline void
set_uart_tx(unsigned int x)
{
    asm volatile("csrrw x0, 0x886, %0;" : : "r"(x));
}

__attribute__ ((always_inline))
inline void
set_uart_rx(unsigned int x)
{
    asm volatile("csrrw x0, 0x885, %0;" : : "r"(x));
}

__attribute__ ((always_inline))
inline void
set_timer(unsigned int x)
{
    asm volatile("csrrw x0, 0x884, %0;" : : "r"(x));
}

__attribute__ ((always_inline))
inline void
set_gpio_dir(unsigned int x)
{
    asm volatile("csrrw x0, 0x881, %0;" : : "r"(x));
}

__attribute__ ((always_inline))
inline void
set_gpio_out(unsigned int x)
{
    asm volatile("csrrw x0, 0x882, %0;" : : "r"(x));
}

__attribute__ ((always_inline))
inline unsigned int
get_gpio_out()
{
    unsigned int x;
    asm volatile("csrrsi %0, 0x882, 0;" : "=r"(x));
    return x;
}

void
_start(void)
{
    unsigned int i = 0;
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(1);
    set_uart_tx(0x00000001);

    while(1) {
        ++i;
        set_gpio_out((i >> 25) & 1);
    }
}

void
handle_interrupt(int id)
{
    if (id == 3) {
    } else if (id == 2) {
        set_uart_tx(0x00000001);
    }
}
