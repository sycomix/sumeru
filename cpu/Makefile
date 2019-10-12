TOPLEVEL = cpu

LIBSRC_DIR = ${SUMERU_DIR}/sw/vhdl/libsrc
SRCS = pll.vhd \
        ${LIBSRC_DIR}/rom_512x16.vhd \
        ${LIBSRC_DIR}/ram1p_256x36_byteena.vhd \
        ${LIBSRC_DIR}/ram1p_256x36.vhd \
        ${LIBSRC_DIR}/ram1p_256x32.vhd \
        ${LIBSRC_DIR}/ram1p_256x16.vhd \
        cpu_types.vhd \
        memory_channel_types.vhd \
        sdram_controller_simlowdelay.vhd \
        memory_arbitrator.vhd \
        memory_loader.vhd \
        icache.vhd \
	dcache.vhd \
	page_tlb.vhd \
        ${TOPLEVEL}.vhd \
        simulation/sim_sdram_mt48lc16m16a2.vhd \
        ${TOPLEVEL}_tb.vhd

SIM_PERIOD = 50us
LIB_DIR = ${SUMERU_DIR}/sw/vhdl/altera-lib

compile: sdram_controller_simulation BOOTCODE.hex
	for fn in $(SRCS); do \
		ghdl -a --std=08 -fexplicit --ieee=synopsys \
                        -P$(LIB_DIR) $(SRCS); \
	done
	ghdl -e --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) \
                $(TOPLEVEL)_tb

sdram_controller_simulation:
	@sed -e 's/(STARTUP_CYCLE_BITNR)/(4)/g' sdram_controller.vhd > sdram_controller_simlowdelay.vhd

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
	@tclsh /home/r0h17/workspace-vhdl/sake/sw/../tools/isa_check.tcl riscv BOOTCODE
	@riscv32-unknown-linux-gnu-objdump -M no-aliases -d BOOTCODE
	@riscv32-unknown-linux-gnu-objcopy -O binary BOOTCODE BOOTCODE.bin
	@../tools/genbootcode < BOOTCODE.bin > BOOTCODE.hex
