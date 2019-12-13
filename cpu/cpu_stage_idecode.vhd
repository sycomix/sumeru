library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t;
    iexec_out:                  in iexec_channel_out_decode_t;
    debug:                      out std_logic
    );
end entity;


architecture synth of cpu_stage_idecode is
    signal debug_r:     std_logic := '1';
begin
    idecode_out.busy <= '0';
    debug <= debug_r;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            if (idecode_in.valid <= '1' and idecode_in.pc <= x"00000038") 
            then
                debug_r <= not debug_r;
            end if;
        end if;
    end process;

end architecture;
