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
{ }

static void
process_tx_data(int uart_intr)
{ 
    char buf[255];
    int x;

    if (uart_intr)
        s_uart0_tx_active = 0;

    if (uart_intr || s_uart0_tx_active == 0) {
        x = consprod_consume(&g_tx_cp, buf, 255, 0);
        if (x > 0) {
            memcpy((char *)UART0_TX_DRVBUF_START, buf, x);
            flush_dcache_range(
                (unsigned char *)UART0_TX_DRVBUF_START,
                (unsigned char *)UART0_TX_DRVBUF_START + x);
            uart0_set_tx(UART0_TX_DRVBUF_START | x);
            s_uart0_tx_active = 1;
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
            timer_set(UART_ENGINE_TIMER_TICKS | 0xf);
            break;
        case INTR_ID_UART0_TX:
            process_tx_data(1);
            break;
        case INTR_ID_UART0_RX:
            process_rx_data(1);
            break;
    }
}
