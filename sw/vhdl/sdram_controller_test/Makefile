TOPLEVEL = sdram_controller_test

SRCS = pll.vhd \
        cpu_types.vhd \
        memory_channel_types.vhd \
        sdram_controller_simlowdelay.vhd \
        simulation/sim_sdram_mt48lc16m16a2.vhd \
        ${TOPLEVEL}.vhd \
        ${TOPLEVEL}_tb.vhd

SIM_PERIOD = 50us
LIB_DIR = ${SUMERU_DIR}/sw/vhdl/altera-lib

compile: sdram_controller_simulation
	for fn in $(SRCS); do \
		ghdl -a --std=08 -fexplicit --ieee=synopsys \
                        -P$(LIB_DIR) $(SRCS); \
	done
	ghdl -e --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) \
                $(TOPLEVEL)_tb

sdram_controller_simulation:
	@sed -e 's/(STARTUP_CYCLE_BITNR)/(4)/g' sdram_controller.vhd > sdram_controller_simlowdelay.vhd

synth: 
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
                PLLJ_*.txt obj *.ppf *.cmp *.qip *.qdf

prog:
	quartus_pgm -c 1 jtag_chain.cdf
