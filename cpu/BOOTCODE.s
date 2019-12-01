.global _start
_start:

minimal_boot_page_table:
.short   0x0000
.short   0x0007
.short   0x0006
.short   0x0005
.short   0x0004
.short   0x0003
.short   0x0002
.short   0x0001

minimal_boot_ivector:
    j main
    nop
    nop
    nop

main:
    csrrsi zero,0xf01,1         #set gpio direction         
    csrrsi zero,0xf03,1         #set gpio(0) led
    lui sp, 0x2                 #stack at 0x2000
    la gp, globals              #globals at 0x3000

    addi t0,zero,0
mainloop:
    addi t0,t0,1
    csrrw zero,0xf03,t0         #set gpio(0) led
    j mainloop

.align(8)
globals:
