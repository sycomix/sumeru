BASE_DIR = $(subst conf/sumeru.mk,,${MAKEFILES})

LIBS_MK = $(join ${BASE_DIR},conf/libs.mk)
POST_MK = $(join ${BASE_DIR},conf/post.mk)

# MI32 (MIPS) is the default architecture
ifndef ARCH
	ARCH = riscv
endif
