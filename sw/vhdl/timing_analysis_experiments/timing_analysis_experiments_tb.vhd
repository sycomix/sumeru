library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity timing_analysis_experiments_tb is
end entity;

architecture sim of timing_analysis_experiments_tb is
        constant half_period: time := 10 ns;
        constant period: time := 20 ns;

        signal clk:                     std_logic := '0';
        signal led:                     std_logic;
        signal btn:                     std_logic := '1';
        signal uart0_rx:                std_logic := '1';
        signal spi0_miso:               std_logic := '0';

        signal sdram_data:              std_logic_vector(15 downto 0);
        signal sdram_addr:              std_logic_vector(12 downto 0);
        signal sdram_ba:                std_logic_vector(1 downto 0);
        signal sdram_dqm:               std_logic_vector(1 downto 0);
        signal sdram_ras, sdram_cas:    std_logic;
        signal sdram_cke, sdram_clk:    std_logic;
        signal sdram_we, sdram_cs:      std_logic;
begin
        clk <= not clk after half_period;

        timing_analysis_experiments: entity work.timing_analysis_experiments
                port map(
                        clk_50m => clk,
                        btn => btn,
                        led => led,

                        uart0_rx => uart0_rx,
                        spi0_miso => spi0_miso,

                        -- gpio
                        -- spio_*

                        sdram_data => sdram_data,
                        sdram_addr => sdram_addr,
                        sdram_ba => sdram_ba,
                        sdram_dqm => sdram_dqm,
                        sdram_ras => sdram_ras,
                        sdram_cas => sdram_cas,
                        sdram_cke => sdram_cke,
                        sdram_clk => sdram_clk,
                        sdram_cs => sdram_cs,
                        sdram_we => sdram_we
                );
                        
end architecture;
