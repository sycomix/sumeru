library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    idecode_in:                 in idecode_channel_in;
    idecode_out:                out idecode_channel_out
    );
end entity;

architecture synth of cpu_stage_idecode is
begin
--    if (rising_edge(sys_clk) and idecode_in.bus_valid = '1') then
--    end if;
end architecture;
