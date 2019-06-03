TOPLEVEL = %%SKEL_PRJNAME%%

SRCS = pll.vhd \
        ${TOPLEVEL}.vhd \
        ${TOPLEVEL}_tb.vhd

SIM_PERIOD = 50us
LIB_DIR = ../altera-lib

compile:
	for fn in $(SRCS); do \
		ghdl -a --std=08 -fexplicit --ieee=synopsys \
                        -P$(LIB_DIR) $(SRCS); \
	done
	ghdl -e --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) \
                $(TOPLEVEL)_tb

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
