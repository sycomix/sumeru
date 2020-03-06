#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <string.h>

#include <machine/uart0.h>

#define MIN(a,b)        (a <= b ? a : b)

static int s_uart0_tx_active = 0;

static void
process_rx_data(int uart_intr)
{ 
    unsigned int pos = uart0_get_rx() & 0xff;

    if (pos > g_uart0_rx_lastpos) {
        unsigned int len = pos - g_uart0_rx_lastpos;
        unsigned char *start = 
            ((unsigned char *)UART0_RX_DRVBUF_START) + g_uart0_rx_lastpos;
        flush_dcache_range(start, start + len);
        consprod_produce(&g_uart0_rx_cp, (const char *)start, len, 0);
        g_uart0_rx_lastpos = pos;
    }

    if (uart_intr == 1) {
        if (g_uart0_flags & UART0_ENGINE_ON) {
            g_uart0_rx_lastpos = 0;
            uart0_set_rx(UART0_RX_DRVBUF_START | 255);
        } else
            uart0_set_rx(UART0_RX_DRVBUF_START | 0);
    }
}

static void
process_tx_data(int uart_intr)
{ 
    char buf[255];
    int x;

    if (uart_intr)
        s_uart0_tx_active = 0;

    if (uart_intr || s_uart0_tx_active == 0) {
        x = consprod_consume(&g_uart0_tx_cp, buf, 255, 0);
        if (x > 0) {
            memcpy((char *)UART0_TX_DRVBUF_START, buf, x);
            flush_dcache_range(
                (unsigned char *)UART0_TX_DRVBUF_START,
                (unsigned char *)UART0_TX_DRVBUF_START + x);
            if (g_uart0_flags & UART0_ENGINE_ON) {
                uart0_set_tx(UART0_TX_DRVBUF_START | x);
                s_uart0_tx_active = 1;
            }
        }
    }
}


void
handle_interrupt(int id)
{
    switch (id) {
        case INTR_ID_TIMER:
            process_rx_data(0);
            process_tx_data(0);
            timer_set(
                (g_uart0_flags & UART0_ENGINE_ON ?
                    (UART_ENGINE_TIMER_TICKS | 0xf) : 0)
                );
            break;
        case INTR_ID_UART0_TX:
            process_tx_data(1);
            break;
        case INTR_ID_UART0_RX:
            process_rx_data(1);
            break;
    }
}
