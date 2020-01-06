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
begin

OUTPUTS: for I in 0 to 31 generate
    gpio(I) <= reg_output(I) when reg_dir(I) = '1' else 'Z';
end generate OUTPUTS;


csr_sel_result <=
    reg_dir when csr_in.csr_sel_reg = CSR_REG_GPIO_DIR else
    reg_output when csr_in.csr_sel_reg = CSR_REG_GPIO_OUTPUT else
    gpio when csr_in.csr_sel_reg = CSR_REG_GPIO_INPUT else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is
                when CSR_REG_GPIO_DIR =>
                    reg_dir <= csr_in.csr_op_data;
                when CSR_REG_GPIO_OUTPUT =>
                    reg_output <= csr_in.csr_op_data;
                when others =>
            end case;
        end if;
    end if;
end process;

end architecture;
