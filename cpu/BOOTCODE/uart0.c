#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include "util.h"

unsigned char *g_uart0_rx_buffer_loc = (unsigned char *)DEFAULT_UART0_RX_BUFFFER_LOC;
unsigned char *g_uart0_tx_buffer_loc = (unsigned char *)DEFAULT_UART0_TX_BUFFFER_LOC;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

int
uart0_blocking_read(unsigned char *buf, unsigned int len)
{
    len &= 0xff;
    g_uart0_rx_intr_pending = 1;
    uart0_set_rx((unsigned int)g_uart0_rx_buffer_loc | len);
    while (g_uart0_rx_intr_pending == 1)
        gpio_set_out((rdtime() >> 25) & 1);
    flush_dcache_range(g_uart0_rx_buffer_loc, g_uart0_rx_buffer_loc + len);
    memcpy(buf, g_uart0_rx_buffer_loc, len);

    return 0;
}


int
uart0_blocking_write(const unsigned char *buf, unsigned int len)
{
    len &= 0xff;        // 255 bytes max allowed, silent truncation
    memcpy(g_uart0_tx_buffer_loc, buf, len);
    flush_dcache_range(g_uart0_tx_buffer_loc, g_uart0_tx_buffer_loc + len);
    g_uart0_tx_intr_pending = 1;
    uart0_set_tx((unsigned int)g_uart0_tx_buffer_loc | len);
    while (g_uart0_tx_intr_pending == 1)
        gpio_set_out((rdtime() >> 23) & 1);
    return 0;
}

