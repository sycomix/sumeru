#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

const unsigned int g_uart0_rx_buffer_loc = DEFAULT_UART0_RX_BUFFFER_LOC;
const unsigned int g_uart0_tx_buffer_loc = DEFAULT_UART0_TX_BUFFFER_LOC;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

int
uart0_read(unsigned char *buf, unsigned int len)
{
    unsigned char *rx_buf = (unsigned char *)g_uart0_rx_buffer_loc;

    g_uart0_rx_intr_pending = 1;
    len &= 0xff;
    uart0_set_rx(g_uart0_rx_buffer_loc | len);

    while (g_uart0_rx_intr_pending == 1)
        gpio_set_out((rdtime() >> 25) & 1);

    for (unsigned int i = 0; i < len; i++, buf++, rx_buf++) {
        if ((i & 0xf) == 0) {
            flush_line(g_uart0_rx_buffer_loc + i);
        }
        *buf = *rx_buf;
    }

    return 0;
}


int
uart0_write(unsigned char *buf, unsigned int len)
{
    unsigned char *tx_buf = (unsigned char *)g_uart0_tx_buffer_loc;

    g_uart0_tx_intr_pending = 1;
    len &= 0xff;

    for (unsigned int i = 0; i < len; i++, buf++, tx_buf++) {
        *tx_buf = *buf;
        if ((i & 0xf) == 0xf) {
            flush_line(g_uart0_tx_buffer_loc + i);
        }
    }

    if ((len & 0xf) != 0)
        flush_line(((unsigned int)tx_buf) & 0xfffffff0);

    uart0_set_tx(g_uart0_tx_buffer_loc | len);
    while (g_uart0_tx_intr_pending == 1)
        gpio_set_out((rdtime() >> 23) & 1);
        
    return 0;
}

