library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity csr_gpio is
port(
    sys_clk:                    in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_out:                    out csr_channel_out_t;
    gpio:                       inout std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of csr_gpio is
    signal result:              std_logic_vector(32 downto 0) := (others => '0');
    signal reg_output:          std_logic_vector(31 downto 0) := (others => '0');
    signal reg_dir:             std_logic_vector(31 downto 0) := (others => '0');
    signal op_result:           std_logic_vector(31 downto 0);
begin
OUTPUTS: for I in 0 to 31 generate
    gpio(I) <= reg_output(I) when reg_dir(I) = '1' else 'Z';
end generate OUTPUTS;

csr_out.csr_op_result <= result(31 downto 0);
result <=
    "1" & reg_dir when csr_in.csr_reg = x"100" else
    "0" & gpio when csr_in.csr_reg = x"102" else
    "1" & reg_output when csr_in.csr_reg = x"103" else
    (others => 'Z');

with csr_in.csr_op select op_result <=
    csr_in.csr_op_data when "01",
    csr_in.csr_op_data or result(31 downto 0) when "10",
    (not csr_in.csr_op_data) and result(31 downto 0) when others;

process(sys_clk)
begin
    if (rising_edge(sys_clk) and result(32) = '1' and csr_in.csr_op_valid = '1') then
        if (csr_in.csr_reg(0) = '0') then
            reg_dir <= op_result;
        else
            reg_output <= op_result;
        end if;
    end if;
end process;

end architecture;
