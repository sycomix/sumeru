PROG = BOOTCODE
CFLAGS = -O -nostdinc -ffreestanding -I. -I../../sw/include
LDFLAGS = -nostdlib --section-start=.text=0x0000

CFILES = boot.c uart0.c
ASFILES = entry.s

WITHOUT_FLOAT = true

include ${POST_MK}

clean:
	rm -rf obj
	rm -f BOOTCODE.srec BOOTCODE BOOTCODE.bin BOOTCODE.hex
