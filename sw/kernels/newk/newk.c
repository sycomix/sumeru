#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/uart0.h>

#include <uart0_io.h>
#include <stdio.h>


int
main(int argc, char *argv)
{
    //uart0_start_rxengine();
    //timer_set(0x10000f);
    //while (1) {
        //printf("Hello World\n");
        //printf("Sumeru Edu\n");
    //}
    //printf("H");
    while (1)
        uart0_blocking_write((unsigned char *)"H",1);
    return 0;
}
