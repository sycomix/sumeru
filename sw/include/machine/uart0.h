#ifndef __SUMERU_DRIVERS_UART0_H
#define __SUMERU_DRIVERS_UART0_H

#include <machine/consprod.h>

#define UART0_ENGINE_ON         (1 << 0)
#define UART0_RX_TIMER_ENABLE   (1 << 1)

extern consprod_t               g_uart0_tx_cp;
extern consprod_t               g_uart0_rx_cp;
extern volatile unsigned int    g_uart0_flags;
extern volatile unsigned int    g_uart0_rx_lastpos;

void    uart0_start_engine();
void    uart0_stop_engine();
int     uart0_blocking_read(char *buf, unsigned int len);
int     uart0_blocking_write(const char *buf, unsigned int len);
int     uart0_blocking_getchar();

#endif
