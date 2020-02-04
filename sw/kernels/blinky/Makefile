PROG = KERNEL
CFLAGS = -O -nostdinc -ffreestanding -I. -I../../include
LDFLAGS = -nostdlib --section-start=.text=0x10000 
LDFLAGS += ../../sys-libs/drivers/libsumeru_drivers.a

CFILES = boot.c 
ASFILES = entry.s

WITHOUT_FLOAT = true

all: KERNEL.bin

clean:
	rm -rf obj
	rm -f KERNEL.srec KERNEL KERNEL.bin KERNEL.hex

uload: all
	${SUMERU_DIR}/tools/bootloader_uart_client -f ${PROG}.bin

bload: 
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_bootloader_client; ./bluetooth_bootloader_client ../../../sw/kernels/blinky/${PROG}.bin)

terminal:
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_le_terminal; ./bluetooth_le_terminal)

include ${POST_MK}

