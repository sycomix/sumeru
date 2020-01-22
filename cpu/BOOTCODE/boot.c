#include <machine/csr.h>
#include <machine/memctl.h>

const unsigned int g_uart0_rx_buffer_loc = 0x10000;
const unsigned int g_uart0_tx_buffer_loc = 0x10100;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

void
main(void)
{
    unsigned int i = 0;

    g_timer_intr_pending = 0;
    g_uart0_tx_intr_pending = 0;
    g_uart0_rx_intr_pending = 0;

    gpio_set_dir(1);
    gpio_set_out(1);
    g_uart0_rx_intr_pending = 1;
    uart0_set_rx(g_uart0_rx_buffer_loc | 0x1);

    while (g_uart0_rx_intr_pending == 1) 
        ;

    /* Nothing here -- we are interupt driven */
    while(1) {
        gpio_set_out((++i >> 23) & 1);
    }
}
