#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <string.h>

#include <machine/uart0.h>

#define MIN(a, b)       (a <= b ? a : b)

/* Streambuf must be atleast twice as large as drvbuf for wrap-around
 * detection to work correctly.
 */

unsigned char *g_tx_drvbuf_start = (unsigned char*)UART0_TX_DRVBUF_START;
unsigned char *g_rx_drvbuf_start = (unsigned char*)UART0_RX_DRVBUF_START;

unsigned char *g_rx_streambuf_start = (unsigned char*)UART0_RX_STREAMBUF_START;
unsigned char *g_rx_streambuf_end = (unsigned char*)UART0_RX_STREAMBUF_END;

unsigned char *g_tx_streambuf_start = (unsigned char*)UART0_TX_STREAMBUF_START;
unsigned char *g_tx_streambuf_end = (unsigned char*)UART0_TX_STREAMBUF_END;

volatile unsigned char * volatile g_rx_streambuf_cons = (unsigned char*)UART0_RX_STREAMBUF_START;
volatile unsigned char * volatile g_rx_streambuf_prod = (unsigned char*)UART0_RX_STREAMBUF_START;

volatile unsigned char * volatile g_tx_streambuf_cons = (unsigned char*)UART0_TX_STREAMBUF_START;
volatile unsigned char * volatile g_tx_streambuf_prod = (unsigned char*)UART0_TX_STREAMBUF_START;

volatile unsigned int g_uart0_flags = 0;


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

    g_uart0_flags |= UART_FLAG_READ_TIMER;
    while (g_rx_streambuf_prod == g_rx_streambuf_cons)
        gpio_set_out((rdtime() >> 22) & 1);
    g_uart0_flags &= ~UART_FLAG_READ_TIMER;

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
    unsigned int bytes_free;
    unsigned char *nptr,*prod;

    len &= 0xff;                // 255 bytes max allowed, silent truncation, evil ;))

    prod = (unsigned char *)g_rx_streambuf_prod; //save once as isr can change this

    bytes_free = (prod >= g_rx_streambuf_cons) ?
                    (prod - g_rx_streambuf_cons) :
                    ((g_rx_streambuf_end - g_rx_streambuf_cons) +
                        (prod - g_rx_streambuf_start));

    nptr = streambuf_incr(
                (unsigned int) g_rx_streambuf_start, 
                (unsigned int) prod, 
                len - bytes_free);

    if (len > bytes_free) {
        g_uart0_flags |= UART_FLAG_READ_TIMER;
        if (prod < nptr) {
            while (g_rx_streambuf_prod >= prod &&
                   g_rx_streambuf_prod < nptr)
                gpio_set_out((rdtime() >> 22) & 1);
        } else {
            while (g_rx_streambuf_prod >= prod || 
                   g_rx_streambuf_prod < nptr)
                gpio_set_out((rdtime() >> 22) & 1);
        }
        g_uart0_flags &= ~UART_FLAG_READ_TIMER;
    }

    nptr = streambuf_incr((unsigned int) g_rx_streambuf_start, 
                          (unsigned int) g_rx_streambuf_cons, 
                          len);

    if (g_rx_streambuf_cons <= nptr) {
        memcpy(buf, (unsigned char *)g_rx_streambuf_cons, len);
    } else {
        bytes_free = g_rx_streambuf_end - g_rx_streambuf_cons; 
        bytes_free = MIN(bytes_free, len);
        memcpy(buf, (unsigned char *)g_rx_streambuf_cons, bytes_free);
        memcpy(buf + bytes_free, g_rx_streambuf_start, len - bytes_free);
    }

    g_rx_streambuf_cons = nptr;
    return len;
}

int
uart0_blocking_write(const unsigned char *buf, unsigned int len)
{
    unsigned int bytes_free;
    unsigned char *nptr, *cons;

    len &= 0xff;                // 255 bytes max allowed, silent truncation

    cons = (unsigned char *)g_tx_streambuf_cons; //save once as isr can change this

    bytes_free = (cons > g_tx_streambuf_prod) ?
                        (cons - g_tx_streambuf_prod) :
                        ((g_tx_streambuf_end - g_tx_streambuf_prod) +
                                (cons - g_tx_streambuf_start));

    if (bytes_free < len) {
        nptr = streambuf_incr((unsigned int) g_tx_streambuf_start, 
                                (unsigned int) g_tx_streambuf_cons, 
                                len - bytes_free);
        if (cons < nptr) {
            while (g_tx_streambuf_cons >= cons &&
                   g_tx_streambuf_cons < nptr)
                gpio_set_out((rdtime() >> 21) & 1);
        } else {
            while (g_tx_streambuf_cons >= cons ||
                   g_tx_streambuf_cons < nptr)
                gpio_set_out((rdtime() >> 21) & 1);
        }
    }

    nptr = streambuf_incr((unsigned int) g_tx_streambuf_start, 
                          (unsigned int) g_tx_streambuf_prod, 
                          len);

    if (nptr > g_tx_streambuf_prod) {
        memcpy((unsigned char *)g_tx_streambuf_prod, buf, len);
    } else {
        bytes_free = g_tx_streambuf_end - g_tx_streambuf_prod;        
        bytes_free = MIN(bytes_free, len);
        memcpy((unsigned char *)g_tx_streambuf_prod, buf, bytes_free);
        memcpy(g_tx_streambuf_start, buf + bytes_free, len - bytes_free);
    }

    g_tx_streambuf_prod = nptr;
    return len;
}

void
uart0_start_engine()
{
    g_uart0_rx_pos = 0;
    g_uart0_tx_active = 0;
    g_uart0_flags |= (UART_FLAG_ENGINE_ON | UART_FLAG_WRITE_TIMER);
    uart0_set_rx(((unsigned int)g_rx_drvbuf_start) | 255);
    timer_set(UART_ENGINE_TIMER_TICKS | 0xf);
}


void
uart0_stop_engine()
{
    timer_set(0);
    g_uart0_flags &= ~(UART_FLAG_ENGINE_ON | UART_FLAG_WRITE_TIMER);
}


size_t
uart0_blocking_write_multiple(FILE *instance, const char *buf, size_t len)
{
    size_t w = 0;
    size_t count;

    while (w < len) {
        count = MIN(255, len - w);
        uart0_blocking_write((const unsigned char *)buf + w, count);
        w += count;
    }
    return w;
}

size_t
uart0_blocking_read_multiple(FILE *instance, char *buf, size_t len)
{
    size_t r = 0;
    size_t count;

    while (r < len) {
        count = MIN(255, len - r);
        uart0_blocking_read((unsigned char *)buf + r, count);
        r += count;
    }
    return r;
}

struct File_methods uart0_fmethods = { 
    uart0_blocking_write_multiple, 
    uart0_blocking_read_multiple 
    };

struct File uart_fm = { &uart0_fmethods };

FILE* const stdin = &uart_fm;
FILE* const stdout = &uart_fm;
FILE* const stderr = &uart_fm;

