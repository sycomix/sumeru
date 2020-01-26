library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu is
port(
    clk_50m:                    in std_logic;
    btn:                        in std_logic;
    led:                        out std_logic;
    spi0_sck:                   out std_logic;
    spi0_ss:                    out std_logic;
    spi0_mosi:                  out std_logic;
    spi0_miso:                  in std_logic;
    sdram_data:                 inout std_logic_vector(15 downto 0);
    sdram_addr:                 out std_logic_vector(12 downto 0);
    sdram_ba:                   out std_logic_vector(1 downto 0);
    sdram_dqm:                  out std_logic_vector(1 downto 0);
    sdram_ras:                  out std_logic;
    sdram_cas:                  out std_logic;
    sdram_cke:                  out std_logic;
    sdram_clk:                  out std_logic;
    sdram_we:                   out std_logic;
    sdram_cs:                   out std_logic;
    uart0_tx:                   out std_logic;
    uart0_rx:                   in std_logic
    );
end entity;

architecture synth of cpu is
    signal clk:                 std_logic;
    signal clk_n:               std_logic;
    signal pll_locked:          std_logic;
    signal reset_n:             std_logic;
    signal reset:               std_logic;

    signal sdc_in:              mem_channel_in_t;
    signal sdc_out:             mem_channel_out_t;
    signal sdc_data_out:        std_logic_vector(15 downto 0);
    signal sdc_busy:            std_logic;

    signal mc0_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc1_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc2_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc3_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc4_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc5_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc6_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc7_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));

    signal mc0_out:             mem_channel_out_t;
    signal mc1_out:             mem_channel_out_t;
    signal mc2_out:             mem_channel_out_t;
    signal mc3_out:             mem_channel_out_t;
    signal mc4_out:             mem_channel_out_t;
    signal mc5_out:             mem_channel_out_t;
    signal mc6_out:             mem_channel_out_t;
    signal mc7_out:             mem_channel_out_t;

    signal bc_mc_in:            mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal pbus_mc_in:          mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));

    signal idecode_in:          idecode_channel_in_t;
    signal idecode_out:         idecode_channel_out_t;

    signal iexec_in:            iexec_channel_in_t;
    signal iexec_out:           iexec_channel_out_t;

    signal csr_in:              csr_channel_in_t;
    signal csr_sel_result:      std_logic_vector(31 downto 0);

    signal gpio:                std_logic_vector(31 downto 0);

    signal clk_cycle:           std_logic;
    signal clk_instret:         std_logic;

    signal ctx_pc_save:         std_logic_vector(31 downto 0);
    signal ctx_pc_switch:       std_logic_vector(31 downto 0);

    signal intr_out:            intr_channel_out_t;
    signal intr_reset:          std_logic;
    signal timer_intr_trigger:  std_logic;
    signal uart0_tx_intr_toggle: std_logic;
    signal uart0_rx_intr_toggle: std_logic;

    signal ivector_addr:        std_logic_vector(23 downto 0);

    signal pdma_in:             periph_dma_channel_in_t := ('0', (others => '0'), '0', (others => '0'), (others => '0'));
    signal pdma_out:            periph_dma_channel_out_t := ('0', (others => '0'), '0');

begin
spi0_sck <= '0';
spi0_ss <= '0';
spi0_mosi <= '0';

pll: entity work.pll 
    port map(
        inclk0 => clk_50m,
        c0 => clk,
        c1 => clk_n,
        locked => pll_locked
        );

sdram_controller: entity work.sdram_controller
    port map(
        clk => clk,
        clk_n => clk_n,
        mc_in => sdc_in,
        mc_out => sdc_out,
        data_out => sdc_data_out,
        sdram_data => sdram_data,
        sdram_addr => sdram_addr,
        sdram_ba => sdram_ba,
        sdram_dqm => sdram_dqm,
        sdram_ras => sdram_ras,
        sdram_cas => sdram_cas,
        sdram_cke => sdram_cke,
        sdram_clk => sdram_clk,
        sdram_we => sdram_we,
        sdram_cs => sdram_cs,
        busy => sdc_busy
        );
        
memory_arbitrator: entity work.memory_arbitrator
    port map(
        clk => clk,

        sdc_busy => sdc_busy,
        sdc_in => sdc_in,
        sdc_out => sdc_out,

        mc0_in => mc0_in,
        mc0_out => mc0_out,

        mc1_in => mc1_in,
        mc1_out => mc1_out,

        mc2_in => mc2_in,
        mc2_out => mc2_out,

        mc3_in => mc3_in,
        mc3_out => mc3_out,

        mc4_in => mc4_in,
        mc4_out => mc4_out,

        mc5_in => mc5_in,
        mc5_out => mc5_out,

        mc6_in => mc6_in,
        mc6_out => mc6_out,

        mc7_in => mc7_in,
        mc7_out => mc7_out
    );

mc7_in <= bc_mc_in when reset_n = '0' else pbus_mc_in;
reset <= not reset_n;

bootcode_loader: entity work.memory_loader
        generic map(
        DATA_FILE => "BOOTCODE/BOOTCODE.hex"
    )
    port map(
        clk => clk,
        reset_n => pll_locked,

        load_done => reset_n,
        mc_in => bc_mc_in,
        mc_out => mc7_out
        );

ifetch: entity work.cpu_stage_ifetch
    port map(
        clk => clk,
        clk_n => clk_n,
        enable => reset_n,
        idecode_in => idecode_in,
        idecode_out => idecode_out,
        icache_mc_in => mc0_in,
        icache_mc_out => mc0_out,
        sdc_data_out => sdc_data_out,
        clk_cycle => clk_cycle
        );

idecode: entity work.cpu_stage_idecode
    port map(
        clk => clk,
        idecode_in => idecode_in,
        idecode_out => idecode_out,
        iexec_in => iexec_in,
        iexec_out => iexec_out
        );

iexec: entity work.cpu_stage_iexec
    port map(
        clk => clk,
        clk_n => clk_n,
        iexec_in => iexec_in,
        iexec_out => iexec_out,
        dcache_mc_in => mc1_in,
        dcache_mc_out => mc1_out,
        sdc_data_out => sdc_data_out,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        clk_instret => clk_instret,
        intr_out => intr_out,
        intr_reset => intr_reset,
        ivector_addr => ivector_addr,
        ctx_pc_save => ctx_pc_save,
        ctx_pc_switch => ctx_pc_switch
        );

csr_gpio: entity work.csr_gpio
    port map(
        clk => clk,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        gpio => gpio
        );

csr_timer: entity work.csr_timer
    port map(
        clk => clk,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        intr_trigger => timer_intr_trigger
        );

csr_counters: entity work.csr_counters
    port map(
        clk => clk,
        reset => reset,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        clk_cycle => clk_cycle,
        clk_instret => clk_instret
        );

csr_misc: entity work.csr_misc
    port map(
        clk => clk,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        ivector_addr => ivector_addr,
        ctx_pc_save => ctx_pc_save,
        ctx_pc_switch => ctx_pc_switch
        );

intr_controller: entity work.intr_controller
    port map(
        clk => clk,
        intr_out => intr_out,
        intr_reset => intr_reset,
        timer_intr_trigger => timer_intr_trigger,
        uart0_tx_intr_toggle => uart0_tx_intr_toggle,
        uart0_rx_intr_toggle => uart0_rx_intr_toggle
        );

uart0_pdma: entity work.periph_dma
    port map(
        clk => clk,
        mc_in => mc2_in,
        mc_out => mc2_out,
        sdc_data_out => sdc_data_out,
        pdma_in => pdma_in,
        pdma_out => pdma_out
        );

uart0: entity work.csr_uart_rs232
    port map(
        clk => clk,
        reset => reset,
        csr_in => csr_in,
        csr_sel_result => csr_sel_result,
        pdma_in => pdma_in,
        pdma_out => pdma_out,
        tx_intr_toggle => uart0_tx_intr_toggle,
        rx_intr_toggle => uart0_rx_intr_toggle,
        uart_tx => uart0_tx,
        uart_rx => uart0_rx
        );


led <= gpio(0);

end architecture;
