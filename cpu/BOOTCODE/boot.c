#include <machine/csr.h>
#include <machine/memctl.h>
#include <machine/uart0.h>

extern volatile unsigned int g_timer_intr_pending;
extern volatile unsigned int g_uart0_tx_intr_pending;
extern volatile unsigned int g_uart0_rx_intr_pending;

unsigned int *mem_ptr = (unsigned int*)0x10000;

static inline
void 
memcpy(unsigned char *dst, unsigned char *src, unsigned int len)
{
    while (len--)
        *dst++ = *src++;
}


int
compute_16b_cksum(unsigned char *buf)
{
    int c = 0;
    for (int i = 0; i < 16; ++i)
        c ^= buf[i];
    return c;
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
    unsigned int num;

    gpio_set_dir(1);
    gpio_set_out(1);

    while (1) {
        uart0_blocking_read(buf, 1);
        switch (buf[0]) {
            case 'a':
                uart0_blocking_read(buf, 5);     /* 4 bytes + 1 checksum */
                if (conv_5b_to_int(buf, &num) == 0) {
                    mem_ptr = (unsigned int *)num;
                    buf[0] = 'O';
                } else {
                    buf[0] = 'E';
                }
                uart0_blocking_write(buf, 1);
                break;
            case 'w':
                uart0_blocking_read(buf, 17);     /* 16 bytes + 1 checksum */
                if (compute_16b_cksum(buf) == buf[16]) {
                    memcpy((unsigned char *)mem_ptr, buf, 16);
                    flush_dcache_line((unsigned int)mem_ptr);
                    mem_ptr += 4;       /* XXX Note increment by 4 as mem_ptr is an integer pointer */
                    buf[0] = 'O';
                } else {
                    buf[0] = 'E';
                }
                uart0_blocking_write(buf, 1);
                break;
            case 'r':
                memcpy(buf, (unsigned char *)mem_ptr, 16);
                buf[16] = compute_16b_cksum(buf);
                mem_ptr += 4;           /* XXX Note increment by 4 as mem_ptr is an integer pointer */
                uart0_blocking_write(buf, 17);
                break;
            case 'v':
                buf[0] = '1';
                uart0_blocking_write(buf, 1);
                break;
            case 'j':
                buf[0] = 'O';
                uart0_blocking_write(buf, 1);
                asm("fence.i");
                gpio_set_out(0); /* set led to known state -- on */
                asm volatile("jalr ra, %0;" : : "r"(mem_ptr));
                /* XXX - presently not reached, but we may allow returns in the future */
                break;
            default:
                buf[0] = 'E';
                uart0_blocking_write(buf, 1);
                break;
        }
    }
}
