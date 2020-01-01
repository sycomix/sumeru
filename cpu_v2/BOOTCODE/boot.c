void    _start(void) __attribute__ (( naked ));
void    _start2(void) __attribute__ (( naked ));
void    set_gpio_dir(unsigned int x);
void    set_gpio_out(unsigned int x);
int     op_div(int x, int y);

void
_start(void)
{
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(1);
    set_timer(0x0000001F);

    while (1)
        ;
}

void
_start2(void)
{
    asm("lui sp, 1");
    set_gpio_out(0);

    while (1)
        ;
}

void
set_timer(unsigned int x)
{
    asm volatile("csrrw x0, 0x00A, %0;" : : "r"(x));
}

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

void
set_gpio_dir(unsigned int x)
{
    asm volatile("csrrw x0, 0x008, %0;" : : "r"(x));
}

void
set_gpio_out(unsigned int x)
{
    asm volatile("csrrw x0, 0x009, %0;" : : "r"(x));
}
