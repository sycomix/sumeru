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
    sdram_cs:                   out std_logic);
end entity;

architecture synth of cpu is
    signal clk:                 std_logic;
    signal clk_n:               std_logic;
    signal pll_locked:          std_logic;
    signal reset_n:             std_logic;

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
    signal csr_out:             csr_channel_out_t;

begin
spi0_sck <= '0';
spi0_ss <= '0';
spi0_mosi <= '0';

pll: entity work.pll 
    port map(
        inclk0 => clk_50m,
        c0 => clk,
        c1 => clk_n,
        locked => pll_locked);

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
        busy => sdc_busy);
        
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

bootcode_loader: entity work.memory_loader
        generic map(
        DATA_FILE => "BOOTCODE.hex"
    )
    port map(
        clk => clk,
        reset_n => pll_locked,

        load_done => reset_n,
        mc_in => bc_mc_in,
        mc_out => mc7_out);

ifetch: entity work.cpu_stage_ifetch
    port map(
        clk => clk,
        clk_n => clk_n,
        enable => reset_n,
        idecode_in => idecode_in,
        idecode_out => idecode_out,
        iexec_out => iexec_out,
        icache_mc_in => mc0_in,
        icache_mc_out => mc0_out,
        sdc_data_out => sdc_data_out);

idecode: entity work.cpu_stage_idecode
    port map(
        clk => clk,
        idecode_in => idecode_in,
        idecode_out => idecode_out,
        iexec_in => iexec_in,
        iexec_out => iexec_out);

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
        csr_out => csr_out);

led <= '0';

end architecture;