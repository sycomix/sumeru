ENDIANFLAGS = -EL

ARCH_DIR = ${ARCH}
TOOLPREFIX = ${ARCH}32-unknown-linux-gnu

# Includes
MK_INCLUDES += -I${BASE_DIR}../riscv-gnu-toolchain/sysroot/usr/include
MK_INCLUDES += -I${BASE_DIR}../riscv-gnu-toolchain/sysroot/usr/include/linux

# Libs
LIBDIR = -L${BASE_DIR}../riscv-gnu-toolchain/sysroot/usr/lib

# RISCV-specific flags
MK_CFLAGS += -march=rv32im
MK_CFLAGS += -mabi=ilp32

# Optimization options
ifeq ($(findstring -O,$(CFLAGS)),)
#	MK_CFLAGS += -Os -fpeel-loops
	MK_CFLAGS += -Os
endif

MK_CFLAGS += -c -pipe
#MK_CFLAGS += -ffunction-sections -fdata-sections

# Default is to warn and abort on all standard errors and warnings
ifndef WARNS
	WARNS = 2
endif

# Warning flags
ifeq ($(findstring ${WARNS}, "01234"),)
	$(error Unsupportde WARNS level ${WARNS})
endif
ifneq ($(findstring ${WARNS}, "1234"),)
	MK_CFLAGS += -Wall
endif
# ifneq ($(findstring ${WARNS}, "234"),)
#	MK_CFLAGS += -Werror
# endif
ifneq ($(findstring ${WARNS}, "34"),)
	MK_CFLAGS += -Wextra -Wsystem-headers -Wshadow
endif
ifneq ($(findstring ${WARNS}, "4"),)
	MK_CFLAGS += -Winline
endif

# Pull in any module-specific compiler flags
MK_CFLAGS += ${CFLAGS}
MK_CXXFLAGS += ${CXXFLAGS}

# Linker flags
MK_LDFLAGS += -N -EL
#MK_LDFLAGS += -gc-sections
MK_LDFLAGS += ${LDFLAGS}


# Library construction flags
MK_ARFLAGS = r

CC = ${TOOLPREFIX}-gcc ${MK_CFLAGS} ${MK_STDINC} ${MK_INCLUDES}
CXX = ${TOOLPREFIX}-g++ ${MK_CFLAGS} ${MK_CXXFLAGS} ${MK_STDINC} ${MK_INCLUDES} -fno-rtti -fno-exceptions
AS = ${TOOLPREFIX}-gcc ${MK_CFLAGS} ${MK_ASFLAGS} ${MK_INCLUDES}
LD = ${TOOLPREFIX}-ld ${MK_LDFLAGS}
AR = ${TOOLPREFIX}-ar ${MK_ARFLAGS}
OBJCOPY = ${TOOLPREFIX}-objcopy
ifeq ($(shell uname -s), FreeBSD)
	ISA_CHECK = ${BASE_DIR}../tools/isa_check.tcl
else
	ISA_CHECK = tclsh ${BASE_DIR}../tools/isa_check.tcl
endif
MKDEP = ${CC} -MM


#
# All object files go to OBJDIR
#

ifndef OBJDIR
	OBJDIR=./obj/${ARCH_DIR}
endif
# We need this crap for feeding sed when parsing .depend
OBJDIR_ESC := $(shell echo ${OBJDIR} | sed -E "s%([\\./])%\\\\\1%g")

#
# Autogenerate targets
#

ifeq ($(PROG),)
	ifeq ($(LIB),)
		.DEFAULT_GOAL := abort
	endif
endif

ASM_OBJS = $(addprefix ${OBJDIR}/,$(ASFILES:.s=.o))

CXX_OBJS = $(CXXFILES)
CXX_OBJS := $(CXX_OBJS:.cc=.o)
CXX_OBJS := $(CXX_OBJS:.cpp=.o)
CXX_OBJS := $(CXX_OBJS:.c++=.o)
CXX_OBJS := $(CXX_OBJS:.cxx=.o)

CXX_OBJS := $(addprefix ${OBJDIR}/,$(CXX_OBJS))

C_OBJS = $(addprefix ${OBJDIR}/,$(CFILES:.c=.o))
OBJS = ${ASM_OBJS} ${C_OBJS} ${CXX_OBJS}

BIN = ${PROG}.bin
SREC = ${PROG}.srec
HEX = ${PROG}.hex

${SREC}: ${BIN} Makefile
	${OBJCOPY} ${OBJFLAGS} -O srec ${PROG} ${SREC}

${HEX}: ${BIN} Makefile
	${OBJCOPY} ${OBJFLAGS} -O ihex ${PROG} ${HEX}

${BIN}: ${PROG} Makefile
	${ISA_CHECK} ${ARCH} ${PROG}
	${OBJCOPY} ${OBJFLAGS} -O binary ${PROG} ${BIN}
# Add a 16 bytes padding to file to help with flush in bootloader firmware
	dd if=/dev/zero of=${BIN} oflag=append bs=1 conv=notrunc count=16

${PROG}: ${OBJS} Makefile
	${LD} -o ${PROG} ${OBJS} ${MK_LIBS}

${LIB}: ${OBJS} Makefile
	${AR} ${LIBDIR}/lib${LIB}.a ${OBJS}

depend:
	@mkdir -p ${OBJDIR}
	${MKDEP} ${CFILES} ${CXXFILES} \
	    | sed "s/\(^[^ ]*\):/${OBJDIR_ESC}\/\1:/" > ${OBJDIR}/.depend

clean:
	rm -f ${OBJDIR}

cleandepend:
	rm -f ${OBJDIR}/.depend

abort:
	@ echo Error: unspecified target!

#
# Rule for compiling .s files
#
$(addprefix ${OBJDIR}/,%.o) : %.s
	@mkdir -p $(dir $@)
	${CC} -o $@ $<

#
# Rule for compiling C files
#
$(addprefix ${OBJDIR}/,%.o) : %.c
	@mkdir -p $(dir $@)
	${CC} -o $@ $<

#
# Rule for compiling C++ files
# XXX fixme extensions: .cc, .cxx, .c++ etc.
#
$(addprefix ${OBJDIR}/,%.o) : %.cpp
	@mkdir -p $(dir $@)
	${CXX} -o $@ $<

$(addprefix ${OBJDIR}/,%.o) : %.cc
	@mkdir -p $(dir $@)
	${CXX} -o $@ $<

$(addprefix ${OBJDIR}/,%.o) : %.cxx
	@mkdir -p $(dir $@)
	${CXX} -o $@ $<

$(addprefix ${OBJDIR}/,%.o) : %.c++
	@mkdir -p $(dir $@)
	${CXX} -o $@ $<

#
# Rule for compiling ASM files
#
$(addprefix ${OBJDIR}/,%.O) : %.S
	@mkdir -p $(dir $@)
	${AS} -o $@ $<

