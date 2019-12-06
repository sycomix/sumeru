library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t
    );
end entity;

architecture synth of cpu_stage_idecode is
begin
    idecode_out.busy <= '0';
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
        end if;
    end process;
end architecture;
