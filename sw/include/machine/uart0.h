#ifndef __SUMERU_DRIVERS_UART0_H
#define __SUMERU_DRIVERS_UART0_H

#define UART_FLAG_ENGINE_ON     (1 << 0)
#define UART_FLAG_READ_TIMER    (1 << 1)
#define UART_FLAG_WRITE_TIMER   (1 << 2)

extern unsigned char *g_tx_drvbuf_start;
extern unsigned char *g_rx_drvbuf_start;
extern unsigned char *g_rx_streambuf_start;
extern unsigned char *g_rx_streambuf_end;
extern unsigned char *g_tx_streambuf_start;
extern unsigned char *g_tx_streambuf_end;

extern volatile unsigned char * volatile g_rx_streambuf_prod;
extern volatile unsigned char * volatile g_rx_streambuf_cons;
extern volatile unsigned char * volatile g_tx_streambuf_prod;
extern volatile unsigned char * volatile g_tx_streambuf_cons;
extern volatile unsigned int g_uart0_flags;

extern volatile unsigned int g_uart0_rx_pos;
extern volatile unsigned int g_uart0_tx_active;

unsigned char* streambuf_incr(unsigned int start, unsigned int x, unsigned int len);
int     uart0_blocking_getchar();
int     uart0_blocking_read(unsigned char *buf, unsigned int len);
int     uart0_blocking_write(const unsigned char *buf, unsigned int len);
size_t  uart0_blocking_write_multiple(FILE *instance, const char *buf, size_t len);
size_t  uart0_blocking_read_multiple(FILE *instance, char *buf, size_t len);
void    uart0_start_engine();
void    uart0_stop_engine();

#endif
