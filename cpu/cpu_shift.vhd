library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_shift is
port(
    sys_clk:    in std_logic;
    shift_data: in std_logic_vector(31 downto 0);
    shift_amt:  in std_logic_vector(4 downto 0);
    shift_bit:  in std_logic;
    shift_dir_lr: in std_logic;
    shift_result:     out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_shift is
    signal shift_data_r: std_logic_vector(31 downto 0);
    signal shift_amt_r: std_logic_vector(4 downto 0);
    signal shift_bit_r: std_logic;
    signal shift_dir_lr_r: std_logic;
    signal shiftrx_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftrx_stage1_result_b: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_b: std_logic_vector(15 downto 0);
    signal shiftll_result: std_logic_vector(31 downto 0);
    signal shiftrx_result: std_logic_vector(31 downto 0);

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
    shift_result <= shiftll_result when shift_dir_lr_r = '0' else shiftrx_result;

    shiftll_result <= 
        shiftll_stage1_result_b & shiftll_stage1_result_a 
            when shift_amt_r(0) = '0' else
        shiftll_stage1_result_b(14 downto 0) & shiftll_stage1_result_a & '0';

    shiftrx_result <= 
        shiftrx_stage1_result_b & shiftrx_stage1_result_a 
            when shift_amt_r(0) = '0' else
        shift_bit_r & shiftrx_stage1_result_b & shiftrx_stage1_result_a(15 downto 1);

    with to_bitvector(shift_amt_r(4 downto 1)) select
        shiftrx_stage1_result_b <= 
            shift_data_r(31 downto 16) when "0000",
            sxt(shift_bit_r & shift_data_r(31 downto 18), 16) when "0001",
            sxt(shift_bit_r & shift_data_r(31 downto 20), 16) when "0010",
            sxt(shift_bit_r & shift_data_r(31 downto 22), 16) when "0011",
            sxt(shift_bit_r & shift_data_r(31 downto 24), 16) when "0100",
            sxt(shift_bit_r & shift_data_r(31 downto 26), 16) when "0101",
            sxt(shift_bit_r & shift_data_r(31 downto 28), 16) when "0110",
            sxt(shift_bit_r & shift_data_r(31 downto 30), 16) when "0111",
            (shift_bit_r & shift_bit_r & shift_bit_r & shift_bit_r &
                shift_bit_r & shift_bit_r & shift_bit_r & shift_bit_r &
                shift_bit_r & shift_bit_r & shift_bit_r & shift_bit_r &
                shift_bit_r & shift_bit_r & shift_bit_r & shift_bit_r) when others;

    with to_bitvector(shift_amt_r(4 downto 1)) select
        shiftrx_stage1_result_a <= 
            shift_data_r(15 downto 0) when "0000",
            shift_data_r(17 downto 2) when "0001",
            shift_data_r(19 downto 4) when "0010",
            shift_data_r(21 downto 6) when "0011",
            shift_data_r(23 downto 8) when "0100",
            shift_data_r(25 downto 10) when "0101",
            shift_data_r(27 downto 12) when "0110",
            shift_data_r(29 downto 14) when "0111",
            shift_data_r(31 downto 16) when "1000",
            sxt(shift_bit_r & shift_data_r(31 downto 18), 16) when "1001",
            sxt(shift_bit_r & shift_data_r(31 downto 20), 16) when "1010",
            sxt(shift_bit_r & shift_data_r(31 downto 22), 16) when "1011",
            sxt(shift_bit_r & shift_data_r(31 downto 24), 16) when "1100",
            sxt(shift_bit_r & shift_data_r(31 downto 26), 16) when "1101",
            sxt(shift_bit_r & shift_data_r(31 downto 28), 16) when "1110",
            sxt(shift_bit_r & shift_data_r(31 downto 30), 16) when "1111";

    with to_bitvector(shift_amt_r(4 downto 1)) select
        shiftll_stage1_result_b <= 
            shift_data_r(31 downto 16) when "0000",
            shift_data_r(29 downto 14) when "0001",
            shift_data_r(27 downto 12) when "0010",
            shift_data_r(25 downto 10) when "0011",
            shift_data_r(23 downto 8) when "0100",
            shift_data_r(21 downto 6) when "0101",
            shift_data_r(19 downto 4) when "0110",
            shift_data_r(17 downto 2) when "0111",
            shift_data_r(15 downto 0) when "1000",
            shift_data_r(13 downto 0) & "00" when "1001",
            shift_data_r(11 downto 0) & "0000" when "1010",
            shift_data_r(9 downto 0) & "000000" when "1011",
            shift_data_r(7 downto 0) & "00000000" when "1100",
            shift_data_r(5 downto 0) & "0000000000" when "1101",
            shift_data_r(3 downto 0) & "000000000000" when "1110",
            shift_data_r(1 downto 0) & "00000000000000" when "1111";

    with to_bitvector(shift_amt_r(4 downto 1)) select
        shiftll_stage1_result_a <= 
            shift_data_r(15 downto 0) when "0000",
            shift_data_r(13 downto 0) & "00" when "0001",
            shift_data_r(11 downto 0) & "0000" when "0010",
            shift_data_r(9 downto 0) & "000000" when "0011",
            shift_data_r(7 downto 0) & "00000000" when "0100",
            shift_data_r(5 downto 0) & "0000000000" when "0101",
            shift_data_r(3 downto 0) & "000000000000" when "0110",
            shift_data_r(1 downto 0) & "00000000000000" when "0111",
            "0000000000000000" when others;
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            shift_data_r <= shift_data;
            shift_bit_r <= shift_bit;
            shift_amt_r <= shift_amt;
            shift_dir_lr_r <= shift_dir_lr;
        end if;
    end process;
end architecture;
