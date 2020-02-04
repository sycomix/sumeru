#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>


#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)

const unsigned int g_uart0_rx_buffer_loc = 0x2000;
const unsigned int g_uart0_tx_buffer_loc = 0x2100;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

int
uart0_read(unsigned char *buf, unsigned int len)
{
    unsigned char *rx_buf = (unsigned char *)g_uart0_rx_buffer_loc;

    g_uart0_rx_intr_pending = 1;
    len &= 0xff;
    uart0_set_rx(g_uart0_rx_buffer_loc | len);

    while (g_uart0_rx_intr_pending == 1)
        ;

    for (unsigned int i = 0; i < len; ++i, buf++, rx_buf++) {
        if ((i & 0xf) == 0) {
            flush_line((unsigned int)rx_buf);
        }
        *buf = *rx_buf;
    }
        
    return 0;
}


int
uart0_write(unsigned char *buf, unsigned int len)
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
        ;
        
    return 0;
}

void
main(void)
{
    unsigned int counter;
    unsigned char buf[4];

    gpio_set_dir(1);
    gpio_set_out(0);

    counter = 0;
    while (1) {
        gpio_set_out((counter++ >> 10) & 1);
        buf[0] = counter & 0xff;
        uart0_write(buf, 1);
    }
}
