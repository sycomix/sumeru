#ifndef __SUMERU_MEMCTL_H
#define __SUMERU_MEMCTL_H

__attribute__ ((always_inline))
inline void
flush_dcache_line(unsigned int x)
{
    x ^= 0x10000;
    x &= SUMERU_CACHE_LINE_MASK;
    asm volatile(" \
        addi a5,%0,0; \
        .word 0x0007B023; " : : "r"(x) : "a5");
}

__attribute__ ((always_inline))
inline void
flush_dcache_range(unsigned char *start, unsigned char *end)
{
    start = (unsigned char*)(((unsigned int) start) & SUMERU_CACHE_LINE_MASK);
    while (start < end) {
        flush_dcache_line((unsigned int)start);
        start += SUMERU_CACHE_LINE_SIZE;
    }
}

#endif
