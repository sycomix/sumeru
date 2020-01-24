#ifndef __SUMERU_MEMCTL_H
#define __SUMERU_MEMCTL_H

__attribute__ ((always_inline))
inline void
flush_line(unsigned int x)
{
    x ^= 0x10000;
    asm volatile(" \
        addi x1,%0,0; \
        .word 0x0000B023; " : : "r"(x) : "x1");
}

#endif
