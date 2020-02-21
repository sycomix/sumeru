#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>

#include <string.h>

unsigned int g_uart0_rx_pos = 0;
unsigned int g_uart0_tx_write_len = 0;

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
    unsigned int len;
    unsigned int wlen = uart0_get_tx() & 0xff;
    unsigned char *nptr;

    if (wlen == g_uart0_tx_write_len) {
        if (g_tx_streambuf_cons != g_tx_streambuf_prod) 
        {
            len = (g_tx_streambuf_prod >= g_tx_streambuf_cons) ?
                        (g_tx_streambuf_prod - g_tx_streambuf_cons) :
                        ((g_tx_streambuf_end - g_tx_streambuf_cons) +
                            (g_tx_streambuf_prod - g_tx_streambuf_start));

            len &= 0xff;
    
            nptr = streambuf_incr(
                        (unsigned int) g_tx_streambuf_start, 
                        (unsigned int) g_tx_streambuf_cons, 
                        len);

            if (nptr > g_tx_streambuf_cons) {
                memcpy((unsigned char *)g_tx_drvbuf_start, 
                       (unsigned char *)g_tx_streambuf_cons, 
                       len);
            } else {
                wlen = g_tx_streambuf_end - g_tx_streambuf_cons;
                memcpy((unsigned char *)g_tx_drvbuf_start, 
                       (unsigned char *)g_tx_streambuf_cons, 
                       wlen);
                memcpy((unsigned char *)(g_tx_drvbuf_start + wlen),
                       (unsigned char *)g_tx_streambuf_start,
                       len - wlen);
            }
            flush_dcache_range(g_tx_drvbuf_start, g_tx_drvbuf_start + len);
            g_uart0_tx_write_len = len;
            g_tx_streambuf_cons = nptr;
            uart0_set_tx(((unsigned int)g_tx_drvbuf_start) | len);
        }
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
