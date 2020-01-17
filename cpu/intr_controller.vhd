library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity intr_controller is
port(
    clk:                        in std_logic;
    intr_out:                   out intr_channel_out_t;
    intr_reset:                 in std_logic;
    timer_intr_trigger:         in std_logic;
    uart0_tx_intr_toggle:       in std_logic
    );
end entity;

architecture synth of intr_controller is
    signal intr_frozen:                 std_logic := '0';
    signal intr_trigger_r:              std_logic := '0';
    signal uart0_tx_intr_toggle_ack:    std_logic := '0';
begin

intr_out.intr_trigger <= intr_trigger_r;

process(clk)
begin
    if (rising_edge(clk)) then
        if (intr_frozen = '1') then
            if (intr_reset = '1') then
                intr_frozen <= '0';
            end if;
        else
            if (timer_intr_trigger = '1') then
                intr_frozen <= '1';
                intr_trigger_r <= not intr_trigger_r;
                intr_out.intr_vec <= IVEC_TIMER;
            elsif (uart0_tx_intr_toggle_ack /= uart0_tx_intr_toggle) then
                uart0_tx_intr_toggle_ack <= uart0_tx_intr_toggle;
                intr_frozen <= '1';
                intr_trigger_r <= not intr_trigger_r;
                intr_out.intr_vec <= IVEC_UART0_TX;
            end if;
        end if;
    end if;
end process;

end architecture;
