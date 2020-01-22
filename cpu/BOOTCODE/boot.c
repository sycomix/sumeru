#include <machine/csr.h>
#include <machine/memctl.h>

const unsigned int g_uart0_rx_buffer_loc = 0x10000;
const unsigned int g_uart0_tx_buffer_loc = 0x10100;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

int
uart0_read(unsigned char *buf, unsigned int len)
{
    unsigned char *rbuf = (unsigned char *)g_uart0_rx_buffer_loc;

    if (g_uart0_rx_intr_pending != 0) {
        /* EPROG */
        return -1;
    }

    g_uart0_rx_intr_pending = 1;
    len &= 0xff;
    uart0_set_rx(g_uart0_rx_buffer_loc | len);

    while (g_uart0_rx_intr_pending == 1)
        ;

    for (int i = 0; i < len; ++i, buf++, rbuf++) {
        if (((unsigned int)rbuf) & 0xf == 0) {
            flush_line((unsigned int)rbuf);
        }
        *buf = *rbuf;
    }
        
    return 0;
}


int
machine_init()
{
    g_timer_intr_pending = 0;
    g_uart0_tx_intr_pending = 0;
    g_uart0_rx_intr_pending = 0;
}


void
main(void)
{
    unsigned int i = 0;
    unsigned char buf[1];
    gpio_set_dir(1);
    gpio_set_out(1);

    uart0_read(buf, 1);

    /* Nothing here -- we are interupt driven */
    while(1) {
        if (buf[0] == 'R')
            gpio_set_out((++i >> 23) & 1);
    }
}
