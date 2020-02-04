#ifndef __SUMERU_DRIVERS_UART0_H
#define __SUMERU_DRIVERS_UART0_H

extern volatile unsigned int g_timer_intr_pending;
extern volatile unsigned int g_uart0_tx_intr_pending;
extern volatile unsigned int g_uart0_rx_intr_pending;

int     uart0_blocking_read(unsigned char *buf, unsigned int len);
int     uart0_blocking_write(unsigned char *buf, unsigned int len);

#endif
