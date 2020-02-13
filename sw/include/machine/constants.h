#ifndef __SUMERU_CONSTANTS_H
#define __SUMERU_CONSTANTS_H

#define CSR_REG_GPIO_DIR                0x881
#define CSR_REG_GPIO_OUT                0x882
#define CSR_REG_GPIO_INPUT              0xCC1

#define CSR_REG_TIMER_CTRL              0x884
#define CSR_REG_TIMER_VALUE             0xCC2

#define CSR_REG_CTR_CYCLE               0xC00
#define CSR_REG_CTR_CYCLE_H             0xC80
#define CSR_REG_CTR_INSTRET             0xC02
#define CSR_REG_CTR_INSTRET_H           0xC82

#define CSR_REG_CTX_PCSAVE              0xCC0
#define CSR_REG_CTX_PCSWITCH            0x880
#define CSR_REG_SWITCH                  0x9C0
#define CSR_REG_IVECTOR_ADDR            0x9C1

#define CSR_REG_UART0_RX                0x888
#define CSR_REG_UART0_TX                0x889
#define CSR_REG_UART0_RX_BAUD           0x88A
#define CSR_REG_UART0_TX_BAUD           0x88B

#define INTR_ID_TIMER                   0x1
#define INTR_ID_UART0_TX                0x2
#define INTR_ID_UART0_RX                0x3

#define DEFAULT_UART0_RX_BUFFFER_LOC    0x2000
#define DEFAULT_UART0_TX_BUFFFER_LOC    0x2000

/* Stack grows down from 32M */
#define STACK_START_LOC                 0x1FFFFF0

/* Malloc-able memory starts at 4M and is 26M in size */
#define MALLOC_MEM_START                0x400000
#define MALLOC_MEM_SIZE                 0x1a00000

#define UART0_TX_DRVBUF_START           0x100
#define UART0_RX_DRVBUF_START           0x200
#define UART0_RX_STREAMBUF_START        0x300
#define UART0_RX_STREAMBUF_END          0x1000

#define SUMERU_CACHE_LINE_SIZE          16
#define SUMERU_CACHE_LINE_MASK          0xFFFFFFF0

#endif
