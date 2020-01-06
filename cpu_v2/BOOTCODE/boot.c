void    _start(void) __attribute__ (( naked ));
void    _start2(void) __attribute__ (( naked ));
void    set_gpio_dir(unsigned int x);
void    set_gpio_out(unsigned int x);
void    set_timer(unsigned int x);
#if 0
int     op_mul(int x, int y);
int     op_div(int x, int y);
#endif

void
_start(void)
{
    int i;
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(1);
    set_timer(0x0000004F);

    i = 0;
    while (i++ < 0x7ffffff)
        ;
    while(1) {
        asm volatile("csrrwi x0, 0x882, 1;");
        asm volatile("csrrwi x0, 0x882, 0;");
    }
}

void
_start2(void)
{
    asm volatile("csrrwi x0, 0x882, 0;");
    while (1)
        ;
}

void
set_timer(unsigned int x)
{
    asm volatile("csrrw x0, 0x884, %0;" : : "r"(x));
}

#if 0
int
op_mul(int x, int y)
{
    return x * y;
}

int
op_div(int x, int y)
{
    return x / y;
}
#endif

void
set_gpio_dir(unsigned int x)
{
    asm volatile("csrrw x0, 0x881, %0;" : : "r"(x));
}

void
set_gpio_out(unsigned int x)
{
    asm volatile("csrrw x0, 0x882, %0;" : : "r"(x));
}
