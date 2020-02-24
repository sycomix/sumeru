#include <machine/constants.h>
#include <machine/csr.h>
#include <machine/memctl.h>

#include <stdio.h>
#include <string.h>

#include <machine/uart0.h>

#define MIN(a,b)        (a <= b ? a : b)

consprod_t      tx_consprod;

void
uart0_start_engine()
{
    consprod_init(&tx_consprod, 
                    (char *)UART0_TX_STREAMBUF_START, 
                    (char *)UART0_TX_STREAMBUF_END);
}

void
uart0_stop_engine()
{ }

int
uart0_blocking_write(const char *buf, unsigned int len)
{
    return consprod_produce(&tx_consprod, buf, len, 1);
}

int
uart0_blocking_read(char *buf, unsigned int len)
{
    return consprod_consume(&tx_consprod, buf, len, 1);
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
        //uart0_blocking_read(buf + r, count);
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

