#ifndef _CPU_SAKE_RV32IMA_H
#define _CPU_SAKE_RV32IMA_H

#include <stdint.h>

#define IRET()                          \
    asm volatile("                      \
        csrrw ra, 0xff1, zero;          \
        csrrw zero, 0xff2, ra;          \
        lw ra, 0(zero);                 \
        csrrw zero, 0xfff, zero")

#define CSR_WRITE_I(csr,x) \
    asm volatile("csrrw zero, %0, %1" : : "i" (csr), "i" (x));

#define CSR_READWRITE_I(csr,x,result) \
    asm volatile("csrrw %0, %1, %2" : "=r" (result) : "i" (csr), "i" (x));

#define CSR_SET_I(csr,x) \
    asm volatile("csrrs zero, %0, %1" : : "i" (csr), "i" (x));

#define CSR_READSET_I(csr,x,result) \
    asm volatile("csrrs %0, %1, %2" : "=r" (result) : "i" (csr), "i" (x));

#define CSR_CLEAR_I(csr,x) \
    asm volatile("csrrc zero, %0, %1" : : "i" (csr), "i" (x));

#define CSR_READCLEAR_I(csr,x,result) \
    asm volatile("csrrc %0, %1, %2" : "=r" (result) : "i" (csr), "i" (x));

#define CSR_WRITE_R(csr,x) \
    asm volatile("csrrw zero, %0, %1" : : "i" (csr), "r" (x));

#define CSR_READWRITE_R(csr,x,result) \
    asm volatile("csrrw %0, %1, %2" : "=r" (result) : "i" (csr), "r" (x));

#define CSR_SET_R(csr,x) \
    asm volatile("csrrs zero, %0, %1" : : "i" (csr), "r" (x));

#define CSR_READSET_R(csr,x,result) \
    asm volatile("csrrs %0, %1, %2" : "=r" (result) : "i" (csr), "r" (x));

#define CSR_CLEAR_R(csr,x) \
    asm volatile("csrrc zero, %0, %1" : : "i" (csr), "r" (x));

#define CSR_READCLEAR_R(csr,x,result) \
    asm volatile("csrrc %0, %1, %2" : "=r" (result) : "i" (csr), "r" (x));

#endif 
