library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_iexec is
port(
    sys_clk:                    in std_logic;
    iexec_in:                   in iexec_channel_in_t;
    iexec_out_fetch:            out iexec_channel_out_fetch_t;
    iexec_out_decode:           out iexec_channel_out_decode_t
    );
end entity;


architecture synth of cpu_stage_iexec is
begin
    iexec_out_fetch <= ('0', '0', (others =>'0'));
    iexec_out_decode <= ('0', '0');
--    process(sys_clk)
--    begin
--        if (rising_edge(sys_clk)) then
--        end if;
--    end process;

end architecture;
