#include <machine/constants.h>
#include <machine/csr.h>

volatile int done = 0;

void
handle_interrupt(int id)
{
    switch (id) {
        case INTR_ID_TIMER:
            timer_set(0);
            done = 1;
            break;
    }
}


int
main(int argc, char **argv)
{
    gpio_set_out(1);
    gpio_set_dir(1);
    timer_set(1024 | 0xf);

    while (1) {
        asm("redo: lw t1,0(%0); beq zero,t1,redo" : : "r"(&done) : "t1");
        gpio_set_out(rdtime() >> 23 & 1);
        timer_set(1024 | 0xf);
        done = 0;
    }

    return 0;
}
