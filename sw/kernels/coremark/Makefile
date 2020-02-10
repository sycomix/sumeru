PROG = coremark

CFLAGS += -O2 -nostdinc -ffreestanding
CFLAGS += -Wall 
CFLAGS += -march=rv32im -mabi=ilp32

#CFLAGS += -DCORE_DEBUG -DMEM_METHOD=MEM_STATIC
CFLAGS += -DITERATIONS=4000 -DMEM_METHOD=MEM_MALLOC
CFLAGS += -DCLOCKS_PER_SEC=75000000

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
#CFLAGS += -DTIME
CFLAGS += -DHZ=85000000

# XXX gc-sections breaks things ... how? investigate :)
#LDFLAGS += -gc-sections
LDFLAGS += -EL -nostdlib
LDFLAGS += -static --section-start=.text=0x10000

CFILES = $(PROG).c
CFILES += core_list_join.c core_matrix.c core_portme.c 
CFILES += core_state.c core_util.c
ASFILES = ../../conf/entry.s

OBJFILES = $(CFILES:.c=.o)
OBJFILES += $(ASFILES:.s=.o)

LDADD = ../../sys-libs/libc/libc.a ../../sys-libs/drivers/libsumeru_drivers.a

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

uload: all
	${SUMERU_DIR}/tools/bootloader_uart_client -f ${PROG}.bin

bload: all
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_bootloader_client; ./bluetooth_bootloader_client ../../../sw/kernels/${PROG}/${PROG}.bin)

terminal:
	(cd ${SUMERU_DIR}/tools/bluetooth/bluetooth_le_terminal; ./bluetooth_le_terminal)
