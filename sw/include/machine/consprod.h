#ifndef __SUMERU_CONSPROD_H
#define __SUMERU_CONSPROD_H

typedef struct consprod {
    char                        *buffer_start;
    char                        *buffer_end;
    volatile char               * volatile prod;
    volatile char               * volatile cons;
    unsigned int                prod_gen;
    unsigned int                cons_gen;
    unsigned int                flags;
} consprod_t;

void                    consprod_init(consprod_t *cp, 
                                        char *buf_start, 
                                        char *buf_end);

unsigned int            consprod_consume(consprod_t *cp, 
                                        char *buf, 
                                        unsigned int len,
                                        unsigned int wait);

unsigned int            consprod_produce(consprod_t *cp, 
                                        char *buf, 
                                        unsigned int len, 
                                        unsigned int wait);

#endif
