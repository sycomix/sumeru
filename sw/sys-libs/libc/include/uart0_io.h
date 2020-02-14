#ifndef __SUMERU_LIBC_UART0_IO_H
#define __SUMERU_LIBC_UART0_IO_H

#include <stdio.h>

void    uart0_start_rxengine();
void    uart0_stop_rxengine();

size_t  uart0_blocking_write_multiple(
                FILE *instance, const char *buf, size_t len);

size_t  uart0_blocking_read_multiple(
                FILE *instance, char *buf, size_t len);

extern FILE* const stdin;
extern FILE* const stdout;
extern FILE* const stderr;

#endif
