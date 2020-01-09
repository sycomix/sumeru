void    _start(void) __attribute__ (( naked ));
void    _start2(void) __attribute__ (( naked ));

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

void
_start(void)
{
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(1);
    flush_word(0x0a726d73);
    set_uart_tx(0x00000004);

    while(1)
        ;
}

void
_start2(void)
{
    asm volatile("              \
        csrrsi a0,0x882,0;      \
        xori a0,a0,-1;          \
        csrrw x0,0x882,a0;      \
                                \
                                \
        csrrsi a0,0xCC0,0;      \
        csrrw  x0,0x880,a0;     \
        li a0,0x00000004;       \
        csrrw x0,0x886,a0;      \
        csrrwi x0,0x9C0,0;"); 

    /* Not reached */
    while (1)
        ;
}
