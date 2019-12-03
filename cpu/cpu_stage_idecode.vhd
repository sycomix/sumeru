library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    fifo_empty:                 in std_logic;
    fifo_rden:                  out std_logic;
    fifo_read_data:             in std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of cpu_stage_idecode is
    signal inst:        std_logic_vector(31 downto 0);

begin
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            fifo_rden <= '0';
            if (fifo_empty /= '1') then
                fifo_rden <= '1';
                inst <= fifo_read_data;
            end if;
        end if;
    end process;
end architecture;
