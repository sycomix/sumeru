library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;
use work.cpu_types.ALL;
use work.sumeru_constants.ALL;

entity cpu_stage_idecode is
port(
    idecode_in:                 in idecode_channel_in
    );
end entity;

architecture synth of cpu_stage_idecode is
begin
end architecture;
