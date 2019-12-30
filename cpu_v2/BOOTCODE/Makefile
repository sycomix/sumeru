
PROG = BOOTCODE
CFLAGS = -nostdinc -ffreestanding
LDFLAGS = -nostdlib --section-start=.text=0x0000

CFILES = boot.c
#ASFILES = crt0.s

WITHOUT_FLOAT = true

include ${POST_MK}

clean:
	@rm -rf BOOTCODE.srec BOOTCODE BOOTCODE.bin obj
