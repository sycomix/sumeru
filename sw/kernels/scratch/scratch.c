#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <stdlib.h>

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

const unsigned int g_uart0_rx_buffer_loc = 0x2000;
const unsigned int g_uart0_tx_buffer_loc = 0x2100;

#define MIN(x,y)        ((x < y) ? x : y)

void
uart0_blocking_read(char *buf, unsigned int len)
{
    unsigned char *rx_buf = (unsigned char *)g_uart0_rx_buffer_loc;

    g_uart0_rx_intr_pending = 1;
    len &= 0xff;
    uart0_set_rx(g_uart0_rx_buffer_loc | len);

    while (g_uart0_rx_intr_pending == 1)
        gpio_set_out((rdtime() >> 21) & 1);

    for (unsigned int i = 0; i < len; ++i, buf++, rx_buf++) {
        if ((i & 0xf) == 0) {
            flush_line((unsigned int)rx_buf);
        }
        *buf = *rx_buf;
    }
}


void
uart0_blocking_write(const char *buf, unsigned int len)
{
    unsigned char *tx_buf = (unsigned char *)g_uart0_tx_buffer_loc;

    g_uart0_tx_intr_pending = 1;
    len &= 0xff;

    for (unsigned int i = 0; i < len; ++i, buf++, tx_buf++) {
        *tx_buf = *buf;
        if ((i & 0xf) == 0xf) {
            flush_line(((unsigned int)tx_buf) & 0xfffffff0);
        }
    }

    flush_line(((unsigned int)tx_buf) & 0xfffffff0);

    uart0_set_tx(g_uart0_tx_buffer_loc | len);
    while (g_uart0_tx_intr_pending == 1)
        gpio_set_out((rdtime() >> 21) & 1);
}


size_t
uart0_blocking_write_multiple(FILE *instance, const char *buf, size_t len)
{
    size_t w = 0;
    size_t count;

    while (w < len) {
        count = MIN(255, len - w);
        uart0_blocking_write(buf + w, count);
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
        uart0_blocking_read(buf + r, count);
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

int
main(int argc, char **argv, char **envp)
{
    gpio_set_dir(1);
    gpio_set_out(1);

    while (1) {
        gpio_set_out((rdtime() >> 25) & 1);
        printf("HKHKKKHHHRHRRRHH");
    }

    return 0;
}
