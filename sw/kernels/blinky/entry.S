#include "machine/constants.h"
.globl _start
_start:
    csrrwi zero,CSR_REG_GPIO_DIR,1
    csrrwi zero,CSR_REG_GPIO_OUT,1
    addi a5,zero,0
loop:
    addi a5,a5,1
    srli a4,a5,20
    csrrw zero,CSR_REG_GPIO_OUT,a4
    j loop
