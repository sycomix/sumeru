library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_ram_io;
use lpm.lpm_components.lpm_counter;

entity timing_analysis_experiment_01 is
port(
        clk_50m:                in std_logic;
        btn:                    in std_logic;
        led:                    out std_logic;
        gpio:                   inout std_logic_vector(7 downto 0);
        uart0_tx:               out std_logic;
        uart0_rx:               in std_logic;
        spi0_sck:               out std_logic;
        spi0_ss:                out std_logic;
        spi0_mosi:              out std_logic;
        spi0_miso:              in std_logic;
        sdram_data:             inout std_logic_vector(15 downto 0);
        sdram_addr:             out std_logic_vector(12 downto 0);
        sdram_ba:               out std_logic_vector(1 downto 0);
        sdram_dqm:              out std_logic_vector(1 downto 0);
        sdram_ras:              out std_logic;
        sdram_cas:              out std_logic;
        sdram_cke:              out std_logic;
        sdram_clk:              out std_logic;
        sdram_we:               out std_logic;
        sdram_cs:               out std_logic);
end entity;

architecture synth of timing_analysis_experiment_01 is
        signal sys_clk:         std_logic;
        signal reset_n:         std_logic;
        signal reset:           std_logic;

        signal ram_addr:         std_logic_vector(15 downto 0);
        signal ram_data:         std_logic_vector(15 downto 0);
        signal ram_we:           std_logic;
        signal ram_enable:       std_logic;

begin
        led <= '0';
        gpio <= (others => 'Z');
        spi0_sck <= '0';
        spi0_ss <= '0';
        spi0_mosi <= '0';
        sdram_addr <= (others => '0');
        sdram_data <= (others => 'Z');
        sdram_ba <= (others => '0');
        sdram_dqm <= (others => '0');
        sdram_ras <= '1';
        sdram_cas <= '1';
        sdram_cke <= '0';
        sdram_clk <= '0';
        sdram_we <= '1';
        sdram_cs <= '1';

        pll: entity work.pll 
                port map(
                        inclk0 => clk_50m,
                        c0 => sys_clk,
                        locked => reset_n);

        counter: lpm_counter
                generic map(
                        lpm_width => 16)
                port map(
                        clock => sys_clk,
                        aclr => reset);

        ram: lpm_ram_io
                generic map(
                        lpm_width => 16,
                        lpm_widthad => 16,
                        lpm_address_control => "UNREGISTERED",
                        lpm_indata => "UNREGISTERED",
                        lpm_outdata => "UNREGISTERED")
                port map(
                        address => ram_addr,
                        dio => ram_data,
                        we => ram_we,
                        memenab => ram_enable);

        ram_we <= '0';
        ram_enable <= '0';


end architecture;


