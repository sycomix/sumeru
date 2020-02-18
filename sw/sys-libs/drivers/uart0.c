#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>

#include <string.h>

unsigned char *g_tx_drvbuf_start = (unsigned char*)UART0_TX_DRVBUF_START;
unsigned char *g_rx_drvbuf_start = (unsigned char*)UART0_RX_DRVBUF_START;

unsigned char *g_rx_streambuf_start = (unsigned char*)UART0_RX_STREAMBUF_START;
unsigned char *g_rx_streambuf_end = (unsigned char*)UART0_RX_STREAMBUF_END;

volatile unsigned char * volatile g_rx_streambuf_cons = (unsigned char*)UART0_RX_STREAMBUF_START;
volatile unsigned char * volatile g_rx_streambuf_prod = (unsigned char*)UART0_RX_STREAMBUF_START;

volatile unsigned int g_uart0_rx_flags = 0;
volatile unsigned int g_uart0_tx_intr_pending = 0;


unsigned char*
streambuf_incr(unsigned int start, unsigned int x, unsigned int len)
{
    unsigned int a;
    a = (x + len) & 0xfff;
    if (a < x)
        a += start;
    return (unsigned char*)a;
}


int
uart0_blocking_getchar()
{
    unsigned int c;

    g_uart0_rx_flags |= UART_FLAG_READ_TIMER;
    while (g_rx_streambuf_prod == g_rx_streambuf_cons)
        gpio_set_dummy((rdtime() >> 22) & 1);
    g_uart0_rx_flags &= ~UART_FLAG_READ_TIMER;

    c = *g_rx_streambuf_cons;
    g_rx_streambuf_cons = 
        streambuf_incr((unsigned int) g_rx_streambuf_start, 
                       (unsigned int) g_rx_streambuf_cons, 
                       1);
    return c;
}


int
uart0_blocking_read(unsigned char *buf, unsigned int len)
{
    unsigned int a;
    unsigned char *ptr;

    len &= 0xff;        // 255 bytes max allowed, silent truncation, evil ;))

    a = (g_rx_streambuf_prod >= g_rx_streambuf_cons) ?
            (g_rx_streambuf_prod - g_rx_streambuf_cons) :
            ((g_rx_streambuf_end - g_rx_streambuf_cons) +
                (g_rx_streambuf_prod - g_rx_streambuf_start));

    ptr = streambuf_incr(
            (unsigned int) g_rx_streambuf_start, 
            (unsigned int) g_rx_streambuf_cons, 
            len);

    if (len > a) {
        g_uart0_rx_flags |= UART_FLAG_READ_TIMER;
        if (g_rx_streambuf_prod < ptr) 
            while (g_rx_streambuf_prod < ptr)
                gpio_set_dummy((rdtime() >> 22) & 1);
        else
            while (ptr < g_rx_streambuf_prod)
                gpio_set_dummy((rdtime() >> 22) & 1);
        g_uart0_rx_flags &= ~UART_FLAG_READ_TIMER;
    }

    if (g_rx_streambuf_cons <= ptr) {
        memcpy(buf, (unsigned char *)g_rx_streambuf_cons, len);
    } else {
        a = g_rx_streambuf_end - g_rx_streambuf_cons; 
        memcpy(buf, (unsigned char *)g_rx_streambuf_cons, a);
        buf = buf + a;
        a = len - a;
        memcpy(buf, g_rx_streambuf_start, a);
    }

    g_rx_streambuf_cons = ptr;

    return len;
}


int
uart0_blocking_write(const unsigned char *buf, unsigned int len)
{
    len &= 0xff;        // 255 bytes max allowed, silent truncation
    memcpy(g_tx_drvbuf_start, buf, len);
    flush_dcache_range(g_tx_drvbuf_start, g_tx_drvbuf_start + len);

    g_uart0_tx_intr_pending = 1;
    uart0_set_tx(((unsigned int)g_tx_drvbuf_start) | len);
    while (g_uart0_tx_intr_pending == 1)
        gpio_set_dummy((rdtime() >> 21) & 1);
        
    return 0;
}

