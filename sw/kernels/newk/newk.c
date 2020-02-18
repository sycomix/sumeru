#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/uart0.h>

#include <uart0_io.h>
#include <stdio.h>


int
main(int argc, char *argv)
{
    char buf[16];

    gpio_set_out(0);
    gpio_set_dir(1);
    buf[0] = 'H';
    uart0_start_rxengine();
    while (1) {
        buf[0] = (char)uart0_blocking_getchar();
        uart0_blocking_write((unsigned char *)buf, 1);
    }
    return 0;
}
