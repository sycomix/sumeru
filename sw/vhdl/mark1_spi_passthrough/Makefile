TOPLEVEL = mark1_spi_passthrough
LIBSRC_DIR = ${SUMERU_DIR}/sw/vhdl/libsrc

SRCS = mark1_spi_passthrough.vhd \
        pll.vhd

OBJS = $(SRCS:.vhd=.o)

SIM_PERIOD = 75us
LIB_DIR = ${SUMERU_DIR}/sw/vhdl/altera-lib

#****************************************************************

%.o : %.vhd
	ghdl -a --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $<

compile: $(TOPLEVEL)

#****************************************************************
mark1_spi_passthrough.o: pll.o

#****************************************************************

$(TOPLEVEL): $(OBJS)
	ghdl -e --std=08 -fexplicit --ieee=synopsys -P$(LIB_DIR) $(TOPLEVEL)

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
                greybox_tmp work-obj93.cf *.qws *.o $(TOPLEVEL) \
                sdram_controller_simlowdelay.vhd \
                PLLJ_*.txt obj *.ppf *.cmp *.qdf \ *.vhd.bak

prog:
	quartus_pgm -c 1 jtag_chain.cdf
