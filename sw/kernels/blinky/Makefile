PROG = KERNEL
CFLAGS = -O -nostdinc -ffreestanding -I. -I../../include
LDFLAGS = -nostdlib --section-start=.text=0x10000

CFILES = 
ASFILES = entry.s

WITHOUT_FLOAT = true

all: KERNEL.bin

clean:
	rm -rf obj
	rm -f KERNEL.srec KERNEL KERNEL.bin KERNEL.hex

include ${POST_MK}

