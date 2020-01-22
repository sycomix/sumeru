#include <machine/csr.h>
#include <machine/memctl.h>

const unsigned int g_uart0_rx_buffer_loc = 0x10000;
const unsigned int g_uart0_tx_buffer_loc = 0x10100;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

int
uart0_read(unsigned char *buf, unsigned int len)
{
    unsigned char *rx_buf = (unsigned char *)g_uart0_rx_buffer_loc;

    if (g_uart0_rx_intr_pending != 0) {
        /* EPROG */
        return -1;
    }

    g_uart0_rx_intr_pending = 1;
    len &= 0xff;
    uart0_set_rx(g_uart0_rx_buffer_loc | len);

    while (g_uart0_rx_intr_pending == 1)
        ;

    for (int i = 0; i < len; ++i, buf++, rx_buf++) {
        if ((((unsigned int)rx_buf) & 0xf) == 0) {
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

    if (g_uart0_tx_intr_pending != 0) {
        /* EPROG */
        return -1;
    }

    g_uart0_tx_intr_pending = 1;
    len &= 0xff;

    for (int i = 0; i < len; ++i, buf++, tx_buf++) {
        *tx_buf = *buf;
        if ((((unsigned int)tx_buf) & 0xf) == 0xf) {
            flush_line(((unsigned int)tx_buf) & 0xfffffff0);
        }
    }

    if ((len & 0xf) != 0) {
        flush_line(((unsigned int)tx_buf) & 0xfffffff0);
    }

    uart0_set_tx(g_uart0_tx_buffer_loc | len);
    while (g_uart0_tx_intr_pending == 1)
        ;
        
    return 0;
}


int
machine_init()
{
    g_timer_intr_pending = 0;
    g_uart0_tx_intr_pending = 0;
    g_uart0_rx_intr_pending = 0;
}


static inline
void memcpy(unsigned char *src, unsigned char *dst, unsigned int len)
{
    while (len)
        *dst++ = *src;
}


int
conv_5b_to_int(unsigned char *buf, unsigned int *i)
{
    *i = 0xdeadc0de;
    return 0;
}


void
main(void)
{
    unsigned char buf[16];
    unsigned char *tx_buf = (unsigned char *)g_uart0_tx_buffer_loc;
    int i, err;

    gpio_set_dir(1);
    gpio_set_out(1);

    while (1) {
        uart0_read(buf, 1);
        switch (buf[0]) {
            case 'R':
                uart0_read(buf, 5);     /* 4 bytes + 1 checksum */
                uart0_write(buf, 5);
                //if (conv_5b_to_int(buf, &i) == 0) {
                //}
                break;
        }
    }
}
