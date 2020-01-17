library work, ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sumeru_constants.ALL;
use work.cpu_types.all;

entity csr_timer is
port(
    clk:                        in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    intr_trigger:               out std_logic
    );
end entity;

architecture synth of csr_timer is
    signal timer_ctrl:          std_logic_vector(31 downto 0) := (others => '0');
    signal timer_value:         std_logic_vector(31 downto 0) := (others => '0');
    signal intr_trigger_r:      std_logic := '0';
    alias timer_enabled:        std_logic is timer_ctrl(0);
    alias timer_max_count:      std_logic_vector(31 downto 4) is timer_ctrl(31 downto 4);
begin

csr_sel_result <=
    timer_ctrl when csr_in.csr_sel_reg = CSR_REG_TIMER_CTRL else
    timer_value when csr_in.csr_sel_reg = CSR_REG_TIMER_VALUE else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

intr_trigger <= intr_trigger_r;

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1' and
            csr_in.csr_op_reg = CSR_REG_TIMER_CTRL) 
        then
            timer_value <= (others => '0');
            timer_ctrl <= csr_in.csr_op_data;
            intr_trigger_r <= '0';
        else
            timer_value <= std_logic_vector(unsigned(timer_value) + 1);
            if (timer_enabled = '1' and 
                timer_value(31 downto 0) = (timer_max_count & "0000")) 
            then
                intr_trigger_r <= '1';
            end if;
        end if;
    end if;
end process;

end architecture;
