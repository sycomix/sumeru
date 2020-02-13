#include <machine/constants.h>
#include <machine/uart0.h>
#include <machine/uart0.h>


void
handle_interrupt(int id)
{
    switch (id) {
        case INTR_ID_TIMER:
            if (g_uart0_rx_flags & UART_FLAG_READ_TIMER) {
                            
            }
            break;
        case INTR_ID_UART0_TX:
            break;
        case INTR_ID_UART0_RX:
            break;
    }
}
