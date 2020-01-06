void    _start(void) __attribute__ (( naked ));
void    _start2(void) __attribute__ (( naked ));

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
    set_timer(0x0000004F);

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
        li a0,0x4f;             \
        csrrw x0,0x884,a0;      \
        csrrwi x0,0x9C0,0;"); 

    /* Not reached */
    while (1)
        ;
}
