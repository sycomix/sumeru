void    _start(void) __attribute__ (( naked ));
void    set_gpio_dir(unsigned int x);
void    set_gpio_out(unsigned int x);

void
_start(void)
{
    int i;
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(0);

    i = 0;
    while (i++ < 0x7ffffff)
        ;
    while(1) {
        set_gpio_out(1);
    }
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
