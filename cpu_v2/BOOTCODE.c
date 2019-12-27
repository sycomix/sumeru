void _start(void) __attribute__ (( naked ));
void set_gpio_dir(unsigned int x);
void set_gpio_out(unsigned int x);

void
_start(void)
{
    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(0);
    while (1)
        ;
}

void set_gpio_dir(unsigned int x)
{
    asm volatile("csrrw x0, 0x100, %0;" : : "r"(x));
}

void set_gpio_out(unsigned int x)
{
    asm volatile("csrrw x0, 0x103, %0;" : : "r"(x));
}