#include <machine/csr.h>
#include <machine/memctl.h>

const unsigned int g_uart0_rx_buffer_loc = 0x2000;
const unsigned int g_uart0_tx_buffer_loc = 0x2100;

volatile unsigned int g_timer_intr_pending;
volatile unsigned int g_uart0_tx_intr_pending;
volatile unsigned int g_uart0_rx_intr_pending;

unsigned int *mem_ptr = 0x10000;

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
void 
memcpy(unsigned char *dst, unsigned char *src, unsigned int len)
{
    while (len--)
        *dst++ = *src++;
}


int
conv_5b_to_int(unsigned char *buf, unsigned int *p)
{
    unsigned int num, cksum;

    num = cksum = 0;
    for (int i = 0; i < 4; ++i) {
        num |= buf[i] << (i << 3);
        cksum ^= buf[i];
    }

    if (((unsigned char)cksum) == buf[4]) {
        *p = num;
        return 0;
    }
    
    return 1;
} 


void
main(void)
{
    unsigned char buf[16];
    unsigned char *tx_buf = (unsigned char *)g_uart0_tx_buffer_loc;
    unsigned int num;

    gpio_set_dir(1);
    gpio_set_out(1);

    while (1) {
        uart0_read(buf, 1);
        gpio_set_out(gpio_get_out() ^ 1);
        switch (buf[0]) {
            case 'A':
                uart0_read(buf, 5);     /* 4 bytes + 1 checksum */
                if (conv_5b_to_int(buf, &num) == 0) {
                    mem_ptr = (unsigned int *)num;
                    buf[0] = 'O';
                } else {
                    buf[0] = 'E';
                }
                uart0_write(buf, 1);
                break;
            case 'W':
                uart0_read(buf, 5);     /* 4 bytes + 1 checksum */
                if (conv_5b_to_int(buf, &num) == 0) {
                    *mem_ptr = num;
                    if ((((unsigned int)mem_ptr) & 0xf) == 0xf) {
                        flush_line(((unsigned int)mem_ptr) & 0xfffffff0);
                    }
                    mem_ptr++;
                    buf[0] = 'O';
                } else {
                    buf[0] = 'E';
                }
                uart0_write(buf, 1);
                break;
            case 'R':
                memcpy(buf, (unsigned char *)mem_ptr, 4);
                buf[4] = buf[0] ^ buf[1] ^ buf[2] ^ buf[3];
                uart0_write(buf, 5);
                ++mem_ptr;
                break;
            case 'V':
                buf[0] = '1';
                uart0_write(buf, 1);
                break;
            case 'J':
                buf[0] = 'O';
                uart0_write(buf, 1);
                asm("fence.i");
                asm volatile("jalr ra, %0;" : : "r"(mem_ptr));
                /* XXX - presently not reached, but we may allow returns in the future */
                break;
            default:
                buf[0] = 'E';
                uart0_write(buf, 1);
                break;
        }
    }
}
