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
buf_next_cons(consprod_t *cp)
{
    char *c = (char *)cp->cons + 1;
    if (c == cp->buffer_end)
        c = cp->buffer_start;
    return c;
}

char*
buf_next_prod(consprod_t *cp)
{
    char *p = (char *)cp->prod + 1;
    if (p == cp->buffer_end)
        p = cp->buffer_start;
    return p;
}

unsigned int
consprod_consume(consprod_t *cp, char *buf, unsigned int len, unsigned int wait)
{
    unsigned int x = len;
    char *p = (char *)cp->prod;
    char *c = buf_next_cons(cp);

    while (x && c != p) {
        *buf = *c;
        x--;
        buf = buf + 1;
        cp->cons = c;
        c = buf_next_cons(cp);
    }

    if (x > 0) {
        if (wait) {
            while (cp->prod == p)
                ;
            return consprod_consume(cp, buf + (len - x), x, wait);
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
    char *p = buf_next_prod(cp);
    char *c = (char *)cp->cons;

    while (x && p != c)
    {
        *cp->prod = *buf;

        x--;
        buf = buf + 1;
        cp->prod = p;
        p = buf_next_prod(cp);
    }

    if (x > 0) {
        if (wait) {
            while (cp->cons == c)
                ;
            return consprod_produce(cp, buf + (len - x), x, wait);
        } else {
            len = len - x;
        }
    }

    return len;
}
