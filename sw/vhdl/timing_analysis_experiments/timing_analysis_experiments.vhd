library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity timing_analysis_experiments is
port(
        clk_50m:                in std_logic;
        btn:                    in std_logic;
        led:                    out std_logic
        );
end entity;

architecture synth of timing_analysis_experiments is
        signal sys_clk:         std_logic;
        signal mem_clk:         std_logic;
        signal reset_n:         std_logic;

        signal address_counter: std_logic_vector(7 downto 0);
        signal dout:            std_logic_vector(31 downto 0);
        signal wdata:           std_logic_vector(31 downto 0);

begin
        wdata <= (others => (address_counter(0) and btn));
        
        pll: entity work.pll 
                port map(
                        inclk0 => clk_50m,
                        c0 => sys_clk,          -- 200 MHz
                        c1 => mem_clk,          -- 100 MHz                
                        locked => reset_n);

        counter : entity work.counter
                port map(
                        clock => sys_clk,
                        q => address_counter);
                        
        ram : entity work.ram
                port map(
                        clock => sys_clk,
                        address => address_counter,
                        data => wdata,
                        wren => '1',
                        q => dout);
                       
        process(sys_clk)
        begin
                if (rising_edge(sys_clk)) then
                        led <= dout(0);
                end if;
        end process;

end architecture;
