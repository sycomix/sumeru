#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>
#include <string.h>

unsigned int g_uart0_rx_pos = 0;
/*
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
}*/

void
handle_interrupt(int id)
{
    switch (id) {
        case INTR_ID_TIMER:
            timer_set(0);
            break;
        case INTR_ID_UART0_TX:
            g_uart0_tx_intr_pending = 0;
            break;
        case INTR_ID_UART0_RX:
            /* XXX BUG activating nop causes invalid return?? */
#if 1
            asm("nop");
#endif
            break;
    }
}
