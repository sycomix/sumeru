#ifndef __SUMERU_DRIVERS_UART0_H
#define __SUMERU_DRIVERS_UART0_H

#define UART_FLAG_RX_ON         (1 << 0)
#define UART_FLAG_READ_TIMER    (1 << 1)

extern unsigned char *g_tx_drvbuf_start;
extern unsigned char *g_rx_drvbuf_start;
extern unsigned char *g_rx_streambuf_start;
extern unsigned char *g_rx_streambuf_end;

extern volatile unsigned char *g_rx_streambuf_prod;
extern volatile unsigned int g_uart0_rx_flags;
extern volatile unsigned int g_uart0_tx_intr_pending;

extern unsigned int g_uart0_rx_pos;

unsigned char* streambuf_incr(unsigned int start, unsigned int x, unsigned int len);
int     uart0_blocking_getchar();
int     uart0_blocking_read(unsigned char *buf, unsigned int len);
int     uart0_blocking_write(const unsigned char *buf, unsigned int len);

#endif
