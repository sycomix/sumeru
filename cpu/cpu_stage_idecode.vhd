library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic
    );
end entity;

architecture synth of cpu_stage_idecode is
begin
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
        end if;
    end process;
end architecture;
