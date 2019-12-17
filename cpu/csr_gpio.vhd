library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity csr_gpio is
port(
    mem_clk:                    in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_out:                    out csr_channel_out_t;
    gpio:                       inout std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of csr_gpio is
    signal result:              std_logic_vector(32 downto 0);
    signal reg_output:          std_logic_vector(31 downto 0);
    signal reg_dir:             std_logic_vector(31 downto 0) := (others => '0');
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

    process(mem_clk)
    begin
        if (rising_edge(mem_clk) and result(32) = '1') then
            if (csr_in.csr_reg(0) = '0') then
                reg_dir <= csr_in.csr_op_data;
            else
                reg_output <= csr_in.csr_op_data;
            end if;
        end if;
    end process;

end architecture;
