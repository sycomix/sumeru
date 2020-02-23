#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <string.h>

#include <machine/uart0.h>

#define MIN(a,b)        (a <= b ? a : b)

volatile unsigned int g_uart0_rx_pos = 0;
volatile unsigned int g_uart0_tx_active = 0;

static void
process_rx_data()
{
    unsigned int pos = uart0_get_rx() & 0xff;

    if (pos > g_uart0_rx_pos) 
    {
        unsigned int len = pos - g_uart0_rx_pos;
        unsigned char *start = g_rx_drvbuf_start + g_uart0_rx_pos;
        unsigned char *nprod = 
            streambuf_incr((unsigned int) g_rx_streambuf_start, 
                           (unsigned int) g_rx_streambuf_prod,
                           len);
        flush_dcache_range(start, g_rx_drvbuf_start + pos);
        if (nprod > g_rx_streambuf_prod) 
        {
            memcpy((unsigned char*)g_rx_streambuf_prod, start, len);
        } else {
            unsigned int x = 
                (unsigned int)(g_rx_streambuf_end - g_rx_streambuf_prod);
            memcpy((unsigned char*)g_rx_streambuf_prod, start, x);
            memcpy(g_rx_streambuf_start, start + x, len - x);
        }
        g_rx_streambuf_prod = nprod;
        g_uart0_rx_pos = pos;
    }
}

static void
process_tx_data()
{
    unsigned int len, wlen;
    unsigned char *nptr;

    if (g_uart0_tx_active == 0 && 
        g_tx_streambuf_cons != g_tx_streambuf_prod) 
    {
        len = (g_tx_streambuf_prod > g_tx_streambuf_cons) ?
                (g_tx_streambuf_prod - g_tx_streambuf_cons) :
                ((g_tx_streambuf_end - g_tx_streambuf_cons) +
                    (g_tx_streambuf_prod - g_tx_streambuf_start));

        len = MIN(len, 255);
    
        nptr = streambuf_incr(
                    (unsigned int) g_tx_streambuf_start, 
                    (unsigned int) g_tx_streambuf_cons, 
                    len);

        gpio_set_out(1);
        if (nptr > g_tx_streambuf_cons) {
            memcpy((unsigned char *)g_tx_drvbuf_start, 
                   (unsigned char *)g_tx_streambuf_cons, 
                   len);
        } else {
            wlen = g_tx_streambuf_end - g_tx_streambuf_cons;
            wlen = MIN(wlen, len);
            memcpy((unsigned char *)g_tx_drvbuf_start, 
                   (unsigned char *)g_tx_streambuf_cons, 
                   wlen);
            memcpy((unsigned char *)(g_tx_drvbuf_start + wlen),
                    (unsigned char *)g_tx_streambuf_start,
                    len - wlen);
        }
        flush_dcache_range(g_tx_drvbuf_start, g_tx_drvbuf_start + len);
        gpio_set_out(0);
        g_tx_streambuf_cons = nptr;
        uart0_set_tx(((unsigned int)g_tx_drvbuf_start) | len);
        g_uart0_tx_active = 1;
    }
}


void
handle_interrupt(int id)
{
    switch (id) {
        case INTR_ID_TIMER:
            timer_set(0);
            if (g_uart0_flags & UART_FLAG_READ_TIMER)
                process_rx_data();
            if (g_uart0_flags & UART_FLAG_WRITE_TIMER)
                process_tx_data();
            if (g_uart0_flags & UART_FLAG_ENGINE_ON)
                timer_set(UART_ENGINE_TIMER_TICKS | 0xf);
            break;
        case INTR_ID_UART0_TX:
            g_uart0_tx_active = 0;
            g_tx_streambuf_cons = streambuf_incr(
                                    (unsigned int) g_tx_streambuf_start, 
                                    (unsigned int) g_tx_streambuf_cons, 
                                    (uart0_get_tx() & 0xff));
            process_tx_data();
            break;
        case INTR_ID_UART0_RX:
            process_rx_data();
            g_uart0_rx_pos = 0;
            if (g_uart0_flags & UART_FLAG_ENGINE_ON) {
                uart0_set_rx(((unsigned int)g_rx_drvbuf_start) | 255);
            }
            break;
    }
}
