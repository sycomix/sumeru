CFLAGS += -nostdinc -ffreestanding
CFLAGS += -g -Wall -Werror -I include -I ../../include
CFLAGS += -march=rv32im -mabi=ilp32

ASFLAGS += -march=rv32im -mabi=ilp32

CC = riscv32-unknown-linux-gnu-gcc
AS = riscv32-unknown-linux-gnu-as
AR = riscv32-unknown-linux-gnu-ar
LD = riscv32-unknown-linux-gnu-ld
RANLIB = riscv32-unknown-linux-gnu-ranlib

CFLAGS += -fno-common -O2
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -I. -Iinclude -Iinclude/sumeru_rv32 -Iinclude/gcc

#LDFLAGS += -gc-sections
LDFLAGS += -N -EL -nostdlib
LDFLAGS += -static --section-start=.text=0x10000

#OBJFILES = $(CFILES:.c=.o)
#OBJFILES += $(ASFILES:.s=.o)
CFLAGS += -nostdinc -nostdlib
CFLAGS += -g -Wall -Werror -I include

# Just include all the source files in the build.
CSRC = $(wildcard *.c)
OBJS = $(CSRC:.c=.o)
ASRC = $(wildcard *.S)
OBJS += $(ASRC:.S=.o)

# Some of the files uses "templates", i.e. common pieces
# of code included from multiple files.
CFLAGS += -Itemplates

all: libc.a

clean:
	$(RM) $(OBJS) libc.a

libc.a: $(OBJS)
	$(RM) $@
	$(AR) ru $@ $^
	$(RANLIB) $@

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
