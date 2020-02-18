#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/uart0.h>

#include <uart0_io.h>
#include <stdio.h>


int
main(int argc, char *argv)
{
    char buf[128];

    gpio_set_out(0);
    gpio_set_dir(1);
    uart0_start_rxengine();
    while (1) {
        fgets(buf, 128, stdin);
        fputs(buf, stdout);
    }
    return 0;
}
