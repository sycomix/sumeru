library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_alu is
port(
    sys_clk:    in std_logic;
    a:          in std_logic_vector(31 downto 0);
    b:          in std_logic_vector(31 downto 0);
    op:         in std_logic_vector(3 downto 0);
    result:     out std_logic_vector(31 downto 0);
    result_br:  out std_logic
    );
end entity;


architecture synth of cpu_alu is
    signal op_r: std_logic_vector(3 downto 0);
    signal a_r: std_logic_vector(31 downto 0) := (others => '0');
    signal b_r: std_logic_vector(31 downto 0) := (others => '0');
    signal result_add: std_logic_vector(31 downto 0);
    signal result_sub: std_logic_vector(31 downto 0);
    signal result_lt:  std_logic_vector(31 downto 0);
    signal result_ltu: std_logic_vector(31 downto 0);
    signal result_and: std_logic_vector(31 downto 0);
    signal result_or:  std_logic_vector(31 downto 0);
    signal result_xor: std_logic_vector(31 downto 0);
    signal result_br_eq: std_logic;
    signal result_br_mux: std_logic;
begin
    result <= 
        result_add when op_r = "0000" else
        result_lt when op_r = "0010" else
        result_ltu when op_r = "0011" else
        result_xor when op_r = "0100" else
        result_or when op_r = "0110" else
        result_and when op_r = "0111" else
        result_sub;

    result_add <= std_logic_vector(signed(a_r) + signed(b_r));
    result_sub <= std_logic_vector(signed(a_r) - signed(b_r));
    result_lt <= (0 => '1', others => '0') when signed(a_r) < signed(b_r) else (others => '0');
    result_ltu <= (0 => '1', others => '0') when unsigned(a_r) < unsigned(b_r) else (others => '0');
    result_xor <= a_r xor b_r;
    result_or <= a_r or b_r;
    result_and <= a_r and b_r;

    result_br_eq <= '1' when (a_r = b_r) else '0';

    result_br_mux <= 
        result_br_eq when op_r(2 downto 1) = "00" else
        result_lt(0) when op_r(2 downto 1) = "10" else
        result_ltu(0);

    result_br <= result_br_mux xor op_r(0);


    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            op_r <= op;
            a_r <= a;
            b_r <= b;
        end if;
    end process;
end architecture;
