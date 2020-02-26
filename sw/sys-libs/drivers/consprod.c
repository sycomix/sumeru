#include <machine/csr.h>
#include <machine/consprod.h>

void
consprod_init(consprod_t *cp, char *buf_start, char *buf_end)
{
    cp->buffer_start = buf_start;
    cp->buffer_end = buf_end;
    cp->prod = buf_start + 1;
    cp->cons = buf_start;
    cp->prod_gen = 0;
    cp->cons_gen = 0;
    cp->flags = 0;
}

char* 
cp_ptr_next(consprod_t *cp, char *ptr)
{
    char *n = ptr + 1;
    if (n == cp->buffer_end)
        n = cp->buffer_start;
    return n;
}

unsigned int
consprod_consume(consprod_t *cp, char *buf, unsigned int len, unsigned int wait)
{
    unsigned int x = len;
    char *p = (char *)cp->prod;
    char *c = cp_ptr_next(cp, (char *)cp->cons);

    while (x && c != p) {
        *buf = *c;
        x--;
        buf = buf + 1;
        cp->cons = c;
        c = cp_ptr_next(cp, c);
    }

    if (x > 0) {
        if (wait) {
            while (cp->prod == p)
                ;
            return consprod_consume(cp, buf, x, wait);
        } else {
            len = len - x;
        }
    }

    return len;
}

unsigned int
consprod_produce(
    consprod_t *cp, const char *buf, unsigned int len, unsigned int wait)
{
    unsigned int x = len;
    char *p = cp_ptr_next(cp, (char *)cp->prod);
    char *c = (char *)cp->cons;

    while (x && p != c)
    {
        *cp->prod = *buf;
        x--;
        buf = buf + 1;
        cp->prod = p;
        p = cp_ptr_next(cp, p);
    }

    if (x > 0) {
        if (wait) {
            while (cp->cons == c)
                ;
            return consprod_produce(cp, buf, x, wait);
        } else {
            len = len - x;
        }
    }

    return len;
}
