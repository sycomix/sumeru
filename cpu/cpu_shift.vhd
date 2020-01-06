library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_shift is
port(
    shift_data: in std_logic_vector(31 downto 0);
    shift_amt:  in std_logic_vector(4 downto 0);
    shift_bit:  in std_logic;
    shift_dir_lr: in std_logic;
    shift_result:     out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_shift is
    signal shiftrx_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftrx_stage1_result_b: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_b: std_logic_vector(15 downto 0);
    signal shiftll_result: std_logic_vector(31 downto 0);
    signal shiftrx_result: std_logic_vector(31 downto 0);
    signal shiftrx_bit: std_logic;

    pure function sxt(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(x), n));
    end function;

    pure function ext(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(unsigned(x), n));
    end function;

begin
    shift_result <= shiftll_result when shift_dir_lr = '0' else shiftrx_result;

    shiftll_result <= 
        shiftll_stage1_result_b & shiftll_stage1_result_a 
            when shift_amt(0) = '0' else
        shiftll_stage1_result_b(14 downto 0) & shiftll_stage1_result_a & '0';

    shiftrx_bit <= shift_bit and shift_data(31);

    shiftrx_result <= 
        shiftrx_stage1_result_b & shiftrx_stage1_result_a 
            when shift_amt(0) = '0' else
        shiftrx_bit & shiftrx_stage1_result_b & shiftrx_stage1_result_a(15 downto 1);

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftrx_stage1_result_b <= 
            shift_data(31 downto 16) when "0000",
            sxt(shiftrx_bit & shift_data(31 downto 18), 16) when "0001",
            sxt(shiftrx_bit & shift_data(31 downto 20), 16) when "0010",
            sxt(shiftrx_bit & shift_data(31 downto 22), 16) when "0011",
            sxt(shiftrx_bit & shift_data(31 downto 24), 16) when "0100",
            sxt(shiftrx_bit & shift_data(31 downto 26), 16) when "0101",
            sxt(shiftrx_bit & shift_data(31 downto 28), 16) when "0110",
            sxt(shiftrx_bit & shift_data(31 downto 30), 16) when "0111",
            (shiftrx_bit & shiftrx_bit & shiftrx_bit & shiftrx_bit &
                shiftrx_bit & shiftrx_bit & shiftrx_bit & shiftrx_bit &
                shiftrx_bit & shiftrx_bit & shiftrx_bit & shiftrx_bit &
                shiftrx_bit & shiftrx_bit & shiftrx_bit & shiftrx_bit) when others;

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftrx_stage1_result_a <= 
            shift_data(15 downto 0) when "0000",
            shift_data(17 downto 2) when "0001",
            shift_data(19 downto 4) when "0010",
            shift_data(21 downto 6) when "0011",
            shift_data(23 downto 8) when "0100",
            shift_data(25 downto 10) when "0101",
            shift_data(27 downto 12) when "0110",
            shift_data(29 downto 14) when "0111",
            shift_data(31 downto 16) when "1000",
            sxt(shiftrx_bit & shift_data(31 downto 18), 16) when "1001",
            sxt(shiftrx_bit & shift_data(31 downto 20), 16) when "1010",
            sxt(shiftrx_bit & shift_data(31 downto 22), 16) when "1011",
            sxt(shiftrx_bit & shift_data(31 downto 24), 16) when "1100",
            sxt(shiftrx_bit & shift_data(31 downto 26), 16) when "1101",
            sxt(shiftrx_bit & shift_data(31 downto 28), 16) when "1110",
            sxt(shiftrx_bit & shift_data(31 downto 30), 16) when "1111";

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftll_stage1_result_b <= 
            shift_data(31 downto 16) when "0000",
            shift_data(29 downto 14) when "0001",
            shift_data(27 downto 12) when "0010",
            shift_data(25 downto 10) when "0011",
            shift_data(23 downto 8) when "0100",
            shift_data(21 downto 6) when "0101",
            shift_data(19 downto 4) when "0110",
            shift_data(17 downto 2) when "0111",
            shift_data(15 downto 0) when "1000",
            shift_data(13 downto 0) & "00" when "1001",
            shift_data(11 downto 0) & "0000" when "1010",
            shift_data(9 downto 0) & "000000" when "1011",
            shift_data(7 downto 0) & "00000000" when "1100",
            shift_data(5 downto 0) & "0000000000" when "1101",
            shift_data(3 downto 0) & "000000000000" when "1110",
            shift_data(1 downto 0) & "00000000000000" when "1111";

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftll_stage1_result_a <= 
            shift_data(15 downto 0) when "0000",
            shift_data(13 downto 0) & "00" when "0001",
            shift_data(11 downto 0) & "0000" when "0010",
            shift_data(9 downto 0) & "000000" when "0011",
            shift_data(7 downto 0) & "00000000" when "0100",
            shift_data(5 downto 0) & "0000000000" when "0101",
            shift_data(3 downto 0) & "000000000000" when "0110",
            shift_data(1 downto 0) & "00000000000000" when "0111",
            "0000000000000000" when others;
end architecture;
