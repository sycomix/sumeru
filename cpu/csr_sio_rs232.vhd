library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity csr_sio_rs232 is
port(
    clk:                        in std_logic;
    clk_sio_115200:             in std_logic;
    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             out std_logic_vector(31 downto 0);
    intr_trigger:               out std_logic);
end entity;

architecture synth of csr_sio_rs232 is
begin

end architecture;
