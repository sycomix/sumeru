#ifndef __SUMERU_BOOT_UTIL_H
#define __SUMERU_BOOT_UTIL_H

__attribute__ ((always_inline))
static inline void
memcpy(unsigned char *dst, const unsigned char *src, unsigned int len)
{
    while (len-- > 0)
        *dst++ = *src++;
}

#endif
