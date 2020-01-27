#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <stdlib.h>

unsigned int g_timer_intr_pending;
unsigned int g_uart0_tx_intr_pending;
unsigned int g_uart0_rx_intr_pending;

void
sio_putchar(int c)
{ }


void
main(int argc, char **argv, char **envp)
{
    gpio_set_dir(1);
    gpio_set_out(1);

    while (1)
        gpio_set_out((rdtime() >> 25) & 1);

    return 0;
}
