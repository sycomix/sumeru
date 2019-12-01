library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity csr_controller is
port(
    sys_clk:                    in std_logic;

    csr_in:                     in csr_channel_in;
    csr_out:                    out csr_channel_out;

    csr_module_result:          inout std_logic_vector(33 downto 0)
);
end entity;

architecture synth of csr_controller is
begin
    csr_out.result <= csr_module_result(31 downto 0);
    csr_out.csr_op <= csr_module_result(33 downto 32);

end architecture;
