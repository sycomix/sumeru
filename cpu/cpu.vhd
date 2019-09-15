library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity cpu is
port(
        clk_50m:                in std_logic;
        btn:                    in std_logic;
        led:                    out std_logic;
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

architecture synth of cpu is
        signal sys_clk:         std_logic;
        signal mem_clk:         std_logic;
        signal reset_n:         std_logic;

        signal pc:              std_logic_vector(31 downto 0) := (others => '0');
        signal icache_hit:      std_logic;
        signal icache_data:     std_logic_vector(31 downto 0);
begin
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
                        c1 => mem_clk,
                        locked => reset_n);

        icache: entity work.icache
                port map(
                        sys_clk => sys_clk,
                        mem_clk => mem_clk,
                        addr => pc,
                        hit => icache_hit,
                        data => icache_data);

        led <= icache_data(26);

        process(sys_clk)
        begin
            if rising_edge(sys_clk) and icache_hit = '1' then
                pc <= std_logic_vector(unsigned(pc) + 4);
            end if;
        end process;

end architecture;


