#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>

#include <uart0_io.h>

#define MIN(x,y)        (x <= y ? x : y)


void
uart0_start_rxengine()
{
    g_uart0_rx_pos = 0;
    g_uart0_rx_flags |= UART_FLAG_RX_ON;
    uart0_set_rx(((unsigned int)g_rx_drvbuf_start) | 255);
    timer_set(UART0_RX_TIMER_TICKS | 0xf);
}


void
uart0_stop_rxengine()
{
    timer_set(0);
    g_uart0_rx_flags &= ~UART_FLAG_RX_ON;
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

