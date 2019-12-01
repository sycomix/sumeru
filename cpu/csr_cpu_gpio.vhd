library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity csr_cpu_gpio is
port(
    sys_clk:                    in std_logic;

    gpio:                       inout std_logic_vector(8 downto 0);

    csr_in:                     in csr_channel_in;
    csr_result:                 inout std_logic_vector(33 downto 0));
end entity;

architecture synth of csr_cpu_gpio is
    signal csr_result_v:        std_logic_vector(34 downto 0);
    signal csr_gpio_write:      std_logic_vector(8 downto 0) := (others => '0');
    signal csr_gpio_direction:  std_logic_vector(8 downto 0) := (others => '0');
    signal csr_gpio_read:       std_logic_vector(8 downto 0);

begin
    csr_result <= csr_result_v(33 downto 0);

    with csr_in.addr select
        csr_result_v <=
            "1" & CSR_OP_READ & "00000000000000000000000" & csr_gpio_direction  when x"F01",
            "0" & CSR_OP_READ & "00000000000000000000000" & csr_gpio_read  when x"F02",
            "1" & CSR_OP_READ & "00000000000000000000000" & csr_gpio_write  when x"F03",
            "0ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" when others;

    gpio(0) <= csr_gpio_write(0) when csr_gpio_direction(0) = '1' else 'Z';
    gpio(1) <= csr_gpio_write(1) when csr_gpio_direction(1) = '1' else 'Z';
    gpio(2) <= csr_gpio_write(2) when csr_gpio_direction(2) = '1' else 'Z';
    gpio(3) <= csr_gpio_write(3) when csr_gpio_direction(3) = '1' else 'Z';
    gpio(4) <= csr_gpio_write(4) when csr_gpio_direction(4) = '1' else 'Z';
    gpio(5) <= csr_gpio_write(5) when csr_gpio_direction(5) = '1' else 'Z';
    gpio(6) <= csr_gpio_write(6) when csr_gpio_direction(6) = '1' else 'Z';
    gpio(7) <= csr_gpio_write(7) when csr_gpio_direction(7) = '1' else 'Z';
    gpio(8) <= csr_gpio_write(8) when csr_gpio_direction(8) = '1' else 'Z';

    csr_gpio_read <= gpio;

    process(sys_clk)
        variable result: std_logic_vector(8 downto 0);
    begin
        if (rising_edge(sys_clk) and csr_in.valid = '1' and csr_result_v(34) = '1') then
            if (csr_in.funct3(1 downto 0) = "10") then
                result := csr_result_v(8 downto 0) or csr_in.value(8 downto 0);
            elsif (csr_in.funct3(1 downto 0) = "11") then
                result := csr_result_v(8 downto 0) and (not csr_in.value(8 downto 0));
            else
                if (csr_in.funct3(2) = '1') then
                    result := csr_result_v(8 downto 5) & csr_in.value(4 downto 0);
                else
                    result := csr_in.value(8 downto 0);
                end if;
            end if;
            if (csr_in.addr(1) = '1') then
                csr_gpio_write <= result;
            else
                csr_gpio_direction <= result;
            end if;
        end if;
    end process;

end architecture;
