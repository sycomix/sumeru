library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_muldiv is
port(
    clk:        in std_logic;
    a:          in std_logic_vector(31 downto 0);
    b:          in std_logic_vector(31 downto 0);
    op:         in std_logic_vector(3 downto 0);
    mul_result: out std_logic_vector(31 downto 0);
    div_result: out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_muldiv is
    signal mul_sign_a: std_logic;
    signal mul_sign_b: std_logic;
    signal mult_result: std_logic_vector(63 downto 0);

    signal div_numer_b32: std_logic;
    signal div_denom_b32: std_logic;
    signal div_numer: std_logic_vector(32 downto 0);
    signal div_denom: std_logic_vector(32 downto 0);
    signal div_quotient: std_logic_vector(32 downto 0);
    signal div_remain: std_logic_vector(32 downto 0);
begin

mul_result <= mult_result(31 downto 0) when op = "0000" else mult_result(63 downto 32);

mul_sign_a <= '0' when op(1 downto 0) = "11" else '1';
mul_sign_b <= '0' when op(1) = '1' else '1';

mult: entity work.cpu_mult
    port map(
        dataa_0 => a,
        datab_0 => b,
        signa => mul_sign_a,
        signb => mul_sign_b,
        result => mult_result);

div_result <= 
    div_quotient(31 downto 0) when op(1) = '0' else div_remain(31 downto 0);

div_numer_b32 <= a(31) when op(0) = '0' else '0';
div_denom_b32 <= b(31) when op(0) = '0' else '0';

div_numer <= div_numer_b32 & a;
div_denom <= div_denom_b32 & b;

div: entity work.cpu_div
    port map(
        clock => clk,
        numer => div_numer,
        denom => div_denom,
        quotient => div_quotient,
        remain => div_remain);

end architecture;
