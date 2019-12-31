library work, ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity csr_timer is
port(
    clk:                        in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_out:                    out csr_channel_out_t;
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
begin

result <=
    "1" & timer_ctrl when csr_in.csr_sel_reg = x"110" else
    "0" & timer_value when csr_in.csr_sel_reg = x"112" else
    (others => 'Z');

intr_trigger <= intr_trigger_r;

process(clk)
begin
    if (rising_edge(clk)) then
        timer_value <= std_logic_vector(unsigned(timer_value) + 1);
        if (result(32) = '1' and csr_in.csr_op_valid = '1') then
            if (csr_in.csr_op_data(2)) then
                timer_value <= (others => '0');
                timer_ctrl <= csr_in.csr_op_data;
            else
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
