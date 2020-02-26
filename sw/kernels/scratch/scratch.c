#include <machine/constants.h>
#include <machine/csr.h>

#include <stdio.h>
#include <stdlib.h>

#include <machine/uart0.h>


int
main(int argc, char *argv)
{
    char buf[128];
    volatile int c;

    gpio_set_out(0);
    gpio_set_dir(1);
    uart0_start_engine();

    while (1) {
        uart0_blocking_write("0123456789AB\n", 13);
    }
    return 0;
}
