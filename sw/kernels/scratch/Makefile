PROG = scratch

CFLAGS += -O -nostdinc -ffreestanding
CFLAGS += -Wall 
CFLAGS += -march=rv32im -mabi=ilp32

ASFLAGS += -march=rv32im -mabi=ilp32 -I../../include

CC = riscv32-unknown-linux-gnu-gcc
AS = riscv32-unknown-linux-gnu-as
AR = riscv32-unknown-linux-gnu-ar
LD = riscv32-unknown-linux-gnu-ld
OBJDUMP = riscv32-unknown-linux-gnu-objdump
OBJCOPY = riscv32-unknown-linux-gnu-objcopy

CFLAGS += -fno-common -Os
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -I../../include
CFLAGS += -I../../sys-libs/libc/include/sumeru_rv32
CFLAGS += -I../../sys-libs/libc/include/gcc -I../../sys-libs/libc/include
CFLAGS += -DTIME

# XXX gc-sections breaks things ... how? investigate :)
#LDFLAGS += -gc-sections
LDFLAGS += -EL -nostdlib
LDFLAGS += -static --section-start=.text=0x10000

CFILES = $(PROG).c
ASFILES = ../../conf/entry.s

OBJFILES = $(CFILES:.c=.o)
OBJFILES += $(ASFILES:.s=.o)

LDADD = ../../sys-libs/libc/libc.a

all: $(PROG)
	

$(PROG): $(OBJFILES)
	$(LD) -T../../conf/static-kernel-link.lds $(LDFLAGS) -o $@ $^ $(LDADD)
	tclsh ${SUMERU_DIR}/tools/isa_check.tcl riscv $@
	${OBJDUMP} -M no-aliases -d $@
	${OBJCOPY} -O binary $@ $(@).bin
# Add a 16 bytes padding to file to help with flush in bootloader firmware
	dd if=/dev/zero of=$(@).bin oflag=append bs=1 conv=notrunc count=16

clean:
	rm -f $(OBJFILES) $(PROG).bin $(PROG)

disa:
	${OBJDUMP} -d ${PROG} | less

load: all
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_bootloader_client; ./bluetooth_bootloader_client ../../../sw/kernels/${PROG}/${PROG}.bin)

terminal:
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_le_terminal; ./bluetooth_le_terminal)