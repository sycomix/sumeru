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
    signal result:              std_logic_vector(32 downto 0);
    signal intr_trigger_r:      std_logic := '0';
    alias timer_enabled:        std_logic is timer_ctrl(0);
    alias timer_intr_enabled:   std_logic is timer_ctrl(1);
    alias timer_max_count:      std_logic_vector(27 downto 0) is timer_ctrl(31 downto 4);
    signal sel:                 std_logic := '0';
begin

csr_sel_result <= result(31 downto 0);

result <=
    "1" & timer_ctrl when csr_in.csr_sel_reg = CSR_REG_TIMER_CTRL else
    "0" & timer_value when csr_in.csr_sel_reg = CSR_REG_TIMER_VALUE else
    "0ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

intr_trigger <= intr_trigger_r;

process(clk)
begin
    if (rising_edge(clk)) then
        sel <= result(32);
        timer_value <= std_logic_vector(unsigned(timer_value) + 1);
        if (sel = '1' and csr_in.csr_op_valid = '1') then
            if (csr_in.csr_op_data(2) = '1') then
                timer_value <= (others => '0');
                timer_ctrl <= csr_in.csr_op_data;
            end if;
            if (csr_in.csr_op_data(3) = '1') then
                intr_trigger_r <= '0';
            end if;
        elsif (timer_enabled = '1') then
            if (timer_value(31 downto 4) = timer_max_count) then
                intr_trigger_r <= timer_intr_enabled;
            end if;
        end if;
    end if;
end process;

end architecture;
