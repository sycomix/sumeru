TOPLEVEL = cpu
LIBSRC_DIR = ${SUMERU_DIR}/sw/vhdl/libsrc
SRCS = sumeru_constants.vhd \
        cpu_types.vhd \
        memory_channel_types.vhd \
        sdram_controller_simlowdelay.vhd \
        pll.vhd \
        rom_512x16.vhd \
        ram1p_256x32.o \
        ram1p_256x16.o \
        ram1p_256x36_byteena.o \
        ram2p_simp_32x32.o \
        memory_arbitrator.vhd \
        memory_loader.vhd \
        readcache_256x4x32.vhd \
        cpu_stage_ifetch.vhd \
        cpu_stage_idecode.vhd \
        cpu_alu.vhd \
        cpu_shift.vhd \
        readwritecache_256x4x32.vhd \
        cpu_stage_iexec.vhd \
        csr_gpio.vhd \
	${TOPLEVEL}.vhd \
        sim_sdram_mt48lc16m16a2.vhd \
        ${TOPLEVEL}_tb.vhd

OBJS = $(SRCS:.vhd=.o)

SIM_PERIOD = 50us
LIB_DIR = ${SUMERU_DIR}/sw/vhdl/altera-lib

#****************************************************************

%.o : %.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

compile: $(TOPLEVEL)_tb

#****************************************************************

${TOPLEVEL}_tb.o: ${TOPLEVEL}.o sim_sdram_mt48lc16m16a2.o

${TOPLEVEL}.o: cpu_types.o \
        sumeru_constants.o \
        pll.o \
        memory_channel_types.o \
        sdram_controller_simlowdelay.o \
        memory_arbitrator.o \
        memory_loader.o \
        readcache_256x4x32.o \
        readwritecache_256x4x32.o \
        cpu_stage_ifetch.o \
        cpu_stage_idecode.o \
        cpu_stage_iexec.o \
        csr_gpio.o

sdram_controller_simlowdelay.o: memory_channel_types.o
memory_arbitrator.o: memory_channel_types.o 
memory_loader.o: memory_channel_types.o rom_512x16.o
readcache_256x4x32.o: ram1p_256x32.o ram1p_256x16.o
cpu_stage_ifetch.o: cpu_types.o readcache_256x4x32.o
cpu_stage_decode.o: cpu_types.o
cpu_stage_iexec.o: cpu_types.o cpu_alu.vhd cpu_shift.vhd
cpu_alu.o: cpu_types.o
cpu_shift.o: cpu_types.o
csr_gpio.o: cpu_types.o


#****************************************************************

rom_512x16.o: ${LIBSRC_DIR}/rom_512x16.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

ram1p_256x32.o: ${LIBSRC_DIR}/ram1p_256x32.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

ram1p_256x16.o: ${LIBSRC_DIR}/ram1p_256x16.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

ram1p_256x36_byteena.o: ${LIBSRC_DIR}/ram1p_256x36_byteena.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

ram2p_simp_32x32.o: ${LIBSRC_DIR}/ram2p_simp_32x32.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

sim_sdram_mt48lc16m16a2.o: simulation/sim_sdram_mt48lc16m16a2.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

#****************************************************************

$(TOPLEVEL)_tb: $(OBJS) BOOTCODE.hex
	ghdl -e --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $(TOPLEVEL)_tb

sdram_controller_simlowdelay.vhd: sdram_controller.vhd
	sed -e 's/(STARTUP_CYCLE_BITNR)/(4)/g' sdram_controller.vhd > sdram_controller_simlowdelay.vhd

synth: BOOTCODE.hex
	quartus_sh --flow compile $(TOPLEVEL)

test:
	./$(TOPLEVEL)_tb --stop-time=$(SIM_PERIOD) --wave=$(TOPLEVEL)_tb.ghw

viewtest:
	gtkwave ${TOPLEVEL}_tb.ghw ${TOPLEVEL}_tb.gtkw

editlpm:
	sudo unshare -n -- env LD_PRELOAD=$(LIBPNG_PRELOAD) \
                su -c ${QDIR}/bin/qmegawizq r0h17

clean:
	rm -Rf output_files incremental_db db work-obj08.cf work-obj93.cf \
                greybox_tmp work-obj93.cf *.qws *.o $(TOPLEVEL)_tb \
                sdram_controller_simlowdelay.vhd \
                PLLJ_*.txt obj *.ppf *.cmp *.qdf \
				*.vhd.bak \
                BOOTCODE.bin BOOTCODE.hex BOOTCODE

prog:
	quartus_pgm -c 1 jtag_chain.cdf

#compile_bootcode:
#	(cd CPU-BOOTCODE; make)
#	@riscv32-unknown-linux-gnu-objdump -M no-aliases -d CPU-BOOTCODE/bootcode
#	@riscv32-unknown-linux-gnu-objcopy -O binary CPU-BOOTCODE/bootcode CPU-BOOTCODE/bootcode.bin
#	@../tools/genbootcode < CPU-BOOTCODE/bootcode.bin > BOOTCODE.hex

BOOTCODE.hex: BOOTCODE.s
	@mkdir -p obj/riscv
	@riscv32-unknown-linux-gnu-as -march=rv32im -mabi=ilp32 -o obj/riscv/BOOTCODE.o BOOTCODE.s
	@riscv32-unknown-linux-gnu-ld -N -EL -gc-sections -nostdlib --section-start=.text=0x0000 -o BOOTCODE  ./obj/riscv/BOOTCODE.o  
#	@tclsh /home/r0h17/workspace-vhdl/sake/sw/../tools/isa_check.tcl riscv BOOTCODE
	@riscv32-unknown-linux-gnu-objdump -M no-aliases -d BOOTCODE
	@riscv32-unknown-linux-gnu-objcopy -O binary BOOTCODE BOOTCODE.bin
	@../tools/genbootcode < BOOTCODE.bin > BOOTCODE.hex


