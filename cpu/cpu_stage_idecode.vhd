library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t;
    iexec_in:                   out iexec_channel_in_t;
    iexec_out:                  in iexec_channel_out_decode_t;
    debug:                      out std_logic
    );
end entity;


architecture synth of cpu_stage_idecode is
    signal debug_r:     std_logic := '1';
    signal decode_busy: std_logic := '0';
    signal exec_valid:  std_logic := '0';

    alias exec_busy:    std_logic is iexec_out.busy;
    alias fetch_valid:  std_logic is idecode_in.valid;
begin
    debug <= debug_r;
    idecode_out.busy <= decode_busy;
    iexec_in.valid <= exec_valid;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            if (exec_busy = '0') then
                decode_busy <= '0';
                if (fetch_valid = '1') then
                    exec_valid <= '1';
                    -- DO DECODE

                else
                    exec_valid <= '0';
                end if;
            else
                if (idecode_in.valid = '1') then
                    decode_busy <= '1';
                else
                    decode_busy <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;
