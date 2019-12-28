library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_muldiv is
port(
    a:          in std_logic_vector(31 downto 0);
    b:          in std_logic_vector(31 downto 0);
    op:         in std_logic_vector(3 downto 0);
    result:     out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_muldiv is
    signal mul_sign_a: std_logic;
    signal mul_sign_b: std_logic;
    signal mult_result: std_logic_vector(63 downto 0);
begin

result <= mult_result(31 downto 0) when op = "0000" else mult_result(63 downto 32);

mul_sign_a <= '0' when op(1 downto 0) = "11" else '1';
mul_sign_b <= '0' when op(1) = '1' else '1';

mult: entity work.cpu_mult
    port map(
        dataa_0 => a,
        datab_0 => b,
        signa => mul_sign_a,
        signb => mul_sign_b,
        result => mult_result);

end architecture;
