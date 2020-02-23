#include <machine/constants.h>
#include <machine/csr.h>

#include <stdio.h>
#include <stdlib.h>

#include <machine/uart0.h>


int
main(int argc, char *argv)
{
    //unsigned char *buf;
    volatile unsigned int i;

    i = 0;
    while (i++ < 10485760)
        ;

    gpio_set_out(0);
    gpio_set_dir(1);
    //buf = (unsigned char*) malloc(128);
    uart0_start_engine();
    while (1) {
        //printf("Hello World");
        uart0_blocking_write("Hello World", 11);
        //fgets(buf, 128, stdin);
        //fputs(buf, stdout);
    }
    return 0;
}
