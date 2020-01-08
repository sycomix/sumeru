library IEEE, lpm;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use lpm.lpm_components.all;

entity mark1_spi_passthrough is
	port(
		clk_50m: in std_logic;
		led: out std_logic;

		sck: in std_logic;
		miso: out std_logic;
		mosi: in std_logic;
		nce: in std_logic;

		flash_sck: out std_logic;
		flash_miso: in std_logic;
		flash_mosi: out std_logic;
		flash_nce: out std_logic
		);
end entity;

architecture synth of mark1_spi_passthrough is
	signal ctr : std_logic_vector(31 downto 0);
	signal pll_clk_0 : std_logic;
	signal pll_locked : std_logic;
	
	signal r_mosi : std_logic register;
	signal r_miso : std_logic register;
	signal r_sck : std_logic register;
	signal r_nce : std_logic register;
	
begin
	led <= ctr(21);
	pll: entity work.pll port map(clk_50m, pll_clk_0, pll_locked);
	
	counter: lpm_counter
        generic map(LPM_WIDTH => 32)
        port map(clock => clk_50m, q => ctr);

	flash_mosi <= r_mosi;
	miso <= r_miso;
	flash_sck <= r_sck;
	flash_nce <= r_nce;
		    
	process(pll_clk_0)
	begin
		if rising_edge(pll_clk_0) then
			r_mosi <= mosi;
			r_miso <= flash_miso;
			r_sck <= sck;
			r_nce <= nce;
		end if;
	end process;
end architecture;
