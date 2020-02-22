#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/uart0.h>

#include <uart0_io.h>
#include <stdio.h>
#include <stdlib.h>


int
main(int argc, char *argv)
{
    //unsigned char *buf;

    gpio_set_out(0);
    gpio_set_dir(1);
    //buf = (unsigned char*) malloc(128);
    uart0_start_engine();
    while (1) {
        //fgets(buf, 128, stdin);
        //fputs(buf, stdout);
        uart0_blocking_write((unsigned char *)"Hello\n", 6);
    }
    return 0;
}
