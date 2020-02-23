CFLAGS += -nostdinc -ffreestanding
CFLAGS += -g -Wall -Werror -I ../../include 
CFLAGS += -I ../../sys-libs/libc/include
CFLAGS += -I../../sys-libs/libc/include/sumeru_rv32
CFLAGS += -I../../sys-libs/libc/include/gcc
CFLAGS += -march=rv32im -mabi=ilp32

ASFLAGS += -march=rv32im -mabi=ilp32

CC = riscv32-unknown-linux-gnu-gcc
AS = riscv32-unknown-linux-gnu-as
AR = riscv32-unknown-linux-gnu-ar
LD = riscv32-unknown-linux-gnu-ld
RANLIB = riscv32-unknown-linux-gnu-ranlib

CFLAGS += -fno-common -Os
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -I. -Iinclude -Iinclude/sumeru_rv32 -Iinclude/gcc

#LDFLAGS += -gc-sections
LDFLAGS += -N -EL -nostdlib
LDFLAGS += -static --section-start=.text=0x10000

OBJFILES = $(CFILES:.c=.o)
OBJFILES += $(ASFILES:.s=.o)
CFLAGS += -nostdinc -nostdlib
CFLAGS += -g -Wall -Werror -I include

# Just include all the source files in the build.
CSRC = $(wildcard *.c)
OBJS = $(CSRC:.c=.o)

# Some of the files uses "templates", i.e. common pieces
# of code included from multiple files.
CFLAGS += -Itemplates

all: libsumeru_drivers.a

clean:
	$(RM) $(OBJS) libsumeru_drivers.a

libsumeru_drivers.a: $(OBJS)
	$(RM) $@
	$(AR) ru $@ $^
	$(RANLIB) $@

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
