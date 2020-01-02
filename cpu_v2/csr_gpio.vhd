library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity csr_gpio is
port(
    clk:                        in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    gpio:                       inout std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of csr_gpio is
    signal reg_output:          std_logic_vector(31 downto 0) := (others => '0');
    signal reg_dir:             std_logic_vector(31 downto 0) := (others => '0');
    signal result:              std_logic_vector(32 downto 0);
    signal sel:                 std_logic := '0';
begin

OUTPUTS: for I in 0 to 31 generate
    gpio(I) <= reg_output(I) when reg_dir(I) = '1' else 'Z';
end generate OUTPUTS;

csr_sel_result <= result(31 downto 0);

result <=
    "1" & reg_dir when csr_in.csr_sel_reg = CSR_REG_GPIO_DIR else
    "1" & reg_output when csr_in.csr_sel_reg = CSR_REG_GPIO_OUTPUT else
    "0" & gpio when csr_in.csr_sel_reg = CSR_REG_GPIO_INPUT else
    "0ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        sel <= result(32);
        if (sel = '1' and csr_in.csr_op_valid = '1') then
            if (csr_in.csr_op_reg(0) = '0') then
                reg_dir <= csr_in.csr_op_data;
            else
                reg_output <= csr_in.csr_op_data;
            end if;
        end if;
    end if;
end process;

end architecture;
