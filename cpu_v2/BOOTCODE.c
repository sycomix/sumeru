void _start(void) __attribute__ (( naked ));
void set_gpio_dir(unsigned int x);
void set_gpio_out(unsigned int x);
int op_div(int a, int b);

void
_start(void)
{
    int x, y, z;

    asm("lui sp, 1");
    set_gpio_dir(1);
    set_gpio_out(1);

    x = -626222723;
    y = 5921;
    z = op_div(-626222723, 5921);

    if (z == -105763) 
        set_gpio_out(0);

    while (1)
        ;
}

int
op_div(int a, int b)
{
    return a / b;
}

void set_gpio_dir(unsigned int x)
{
    asm volatile("csrrw x0, 0x100, %0;" : : "r"(x));
}

void set_gpio_out(unsigned int x)
{
    asm volatile("csrrw x0, 0x103, %0;" : : "r"(x));
}
