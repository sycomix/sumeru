library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_alu is
port(
    a:          in std_logic_vector(31 downto 0);
    b:          in std_logic_vector(31 downto 0);
    op:         in std_logic_vector(3 downto 0);
    result:     out std_logic_vector(31 downto 0);
    result_br:  out std_logic
    );
end entity;


architecture synth of cpu_alu is
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
        result_add when op = "0000" else
        result_lt when op = "0010" else
        result_ltu when op = "0011" else
        result_xor when op = "0100" else
        result_or when op = "0110" else
        result_and when op = "0111" else
        result_sub;

    result_add <= std_logic_vector(signed(a) + signed(b));
    result_sub <= std_logic_vector(signed(a) - signed(b));
    result_lt <= (0 => '1', others => '0') when signed(a) < signed(b) else (others => '0');
    result_ltu <= (0 => '1', others => '0') when unsigned(a) < unsigned(b) else (others => '0');
    result_xor <= a xor b;
    result_or <= a or b;
    result_and <= a and b;

    result_br_eq <= '1' when (a = b) else '0';

    result_br_mux <= 
        result_br_eq when op(2 downto 1) = "00" else
        result_lt(0) when op(2 downto 1) = "10" else
        result_ltu(0);

    result_br <= result_br_mux xor op(0);

end architecture;
