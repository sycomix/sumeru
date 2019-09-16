library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity cpu_tb is
end entity;

architecture sim of cpu_tb is
        constant half_period: time := 10 ns;
        constant period: time := 20 ns;

        signal clk_50m:                 std_logic := '0';

        signal led:                     std_logic;
        signal btn:                     std_logic := '1';

        signal spi0_ss:                 std_logic := '0';
        signal spi0_sck:                std_logic := '0';
        signal spi0_mosi:               std_logic := '0';
        signal spi0_miso:               std_logic := '0';


        signal sdram_data:              std_logic_vector(15 downto 0);
        signal sdram_addr:              std_logic_vector(12 downto 0);
        signal sdram_ba:                std_logic_vector(1 downto 0);
        signal sdram_dqm:               std_logic_vector(1 downto 0);
        signal sdram_ras, sdram_cas:    std_logic;
        signal sdram_cke, sdram_clk:    std_logic;
        signal sdram_we, sdram_cs:      std_logic;


begin
        clk_50m <= not clk_50m after half_period;

        sdram: entity work.sim_sdram_mt48lc16m16a2
            port map(
                dq => sdram_data,
                dqm => sdram_dqm,
                addr => sdram_addr,
                ba => sdram_ba,
                clk => sdram_clk,
                cke => sdram_cke,
                cs_n => sdram_cs,
                ras_n => sdram_ras,
                cas_n => sdram_cas,
                we_n => sdram_we);

        cpu: entity work.cpu
            port map(
                clk_50m => clk_50m,
                btn => btn,
                led => led,
                
                -- uart
                -- gpio
                
                -- spio_*
                spi0_ss => spi0_ss,
                spi0_sck => spi0_sck,
                spi0_mosi => spi0_mosi,
                spi0_miso => spi0_miso,
                
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
