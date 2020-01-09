library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity csr_sio_rs232 is
port(
    clk:                        in std_logic;
    clk_siox16:                 in std_logic;
    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             out std_logic_vector(31 downto 0);
    intr_trigger:               out std_logic;
    uart0_tx:                   out std_logic;
    uart0_rx:                   in std_logic);
end entity;

architecture synth of csr_sio_rs232 is
signal counter:         std_logic_vector(3 downto 0);
signal tx_done:         std_logic := '0';
signal tx_start:        std_logic := '0';
signal tx_start_ack:    std_logic := '0';
signal tx_started:      std_logic := '0';
signal bstate:          std_logic_vector(3 downto 0) := (others => '0');
signal tx_byte:         std_logic_vector(7 downto 0);
signal tx_mem_byte:     std_logic_vector(7 downto 0);
alias sclk:             std_logic is counter(3);

begin
clk_counter: lpm_counter
    generic map(
        LPM_WIDTH => 4)
    port map(
        clock => clk_siox16,
        q => counter);

with bstate select
    uart0_tx <=
        tx_byte(7)      when "0001",
        tx_byte(6)      when "0010",
        tx_byte(5)      when "0011",
        tx_byte(4)      when "0100",
        tx_byte(3)      when "0101",
        tx_byte(2)      when "0110",
        tx_byte(1)      when "0111",
        tx_byte(0)      when "1000",
        '0'             when "1001",
        '1'             when others;

tx_done <= '1' when tx_start = tx_start_ack else '0';

-- Back-to-back capable transmission algo
process(sclk)
begin
    if (rising_edge(sclk)) then
        if (tx_started = '1') then
            bstate <= std_logic_vector(unsigned(bstate) - 1);
            if (bstate = "0001") then
                tx_started <= '0';
                tx_start_ack <= tx_start;
            end if;
        else
            if (tx_start /= tx_start_ack) then
                tx_started <= '1';
                bstate <= "1001";
                tx_byte <= tx_mem_byte;
            end if;
        end if;
    end if;
end process;

end architecture;
