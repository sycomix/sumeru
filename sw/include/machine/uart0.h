#ifndef __SUMERU_DRIVERS_UART0_H
#define __SUMERU_DRIVERS_UART0_H

#include <machine/consprod.h>

extern consprod_t       tx_cp;
extern consprod_t       rx_cp;

void    uart0_start_engine();
void    uart0_stop_engine();
int     uart0_blocking_read(char *buf, unsigned int len);
int     uart0_blocking_write(const char *buf, unsigned int len);
int     uart0_blocking_getchar();

#endif
