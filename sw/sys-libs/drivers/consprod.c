#include <machine/csr.h>
#include <machine/consprod.h>

void
consprod_init(consprod_t *cp, char *buf_start, char *buf_end)
{
    cp->buffer_start = buf_start;
    cp->buffer_end = buf_end;
    cp->prod = buf_start;
    cp->cons = buf_start;
    cp->prod_gen = 0;
    cp->cons_gen = 0;
    cp->flags = 0;
}

unsigned int
consprod_consume(consprod_t *cp, char *buf, unsigned int len, unsigned int wait)
{
    unsigned int x = len;

    while (x && (cp->cons != cp->prod)) {
        *buf = *cp->cons;

        x--;
        cp->cons = cp->cons + 1;
        buf = buf + 1;

        if (cp->cons == cp->buffer_end) {
            cp->cons_gen++;
            cp->cons = cp->buffer_start;
        }
    }

    if (x > 0) {
        if (wait) {
            char *p = (char *)cp->prod;
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

    while (x && 
           ((cp->cons != cp->prod) || (cp->cons_gen == cp->prod_gen)))
    {
        *cp->prod = *buf;

        x--;
        cp->prod = cp->prod + 1;
        buf = buf + 1;

        if (cp->prod == cp->buffer_end) {
            cp->prod_gen++;
            cp->prod = cp->buffer_start;
        }
    }

    if (x > 0) {
        if (wait) {
            char *c = (char *)cp->cons;
            while (cp->cons == c)
                ;
            return consprod_produce(cp, buf + (len - x), x, wait);
        } else {
            len = len - x;
        }
    }

    return len;
}
