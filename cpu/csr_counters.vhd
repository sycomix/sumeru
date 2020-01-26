library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity csr_counters is
port(
    clk:                        in std_logic;
    reset:                      in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    clk_cycle:                  in std_logic;
    clk_instret:                in std_logic
    );
end entity;

architecture synth of csr_counters is
    signal ctr_instret:         std_logic_vector(63 downto 0);
    signal ctr_cycle:           std_logic_vector(63 downto 0);
    signal ctr_time:            std_logic_vector(63 downto 0);
begin

with csr_in.csr_sel_reg select csr_sel_result <=
    ctr_cycle(31 downto 0) when CSR_REG_CTR_CYCLE,
    ctr_cycle(63 downto 32) when CSR_REG_CTR_CYCLE_H,
    ctr_time(31 downto 0) when CSR_REG_CTR_TIME,
    ctr_time(63 downto 32) when CSR_REG_CTR_TIME_H,
    ctr_instret(31 downto 0) when CSR_REG_CTR_INSTRET,
    ctr_instret(63 downto 32) when CSR_REG_CTR_INSTRET_H,
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" when others;

time_counter: lpm_counter
    generic map(
        LPM_WIDTH => 64)
    port map(
        clock => clk,
        aclr => reset,
        q => ctr_time);

instret_counter: lpm_counter
    generic map(
        LPM_WIDTH => 64)
    port map(
        clock => clk_instret,
        aclr => reset,
        q => ctr_instret);

cycle_counter: lpm_counter
    generic map(
        LPM_WIDTH => 64)
    port map(
        clock => clk_cycle,
        aclr => reset,
        q => ctr_cycle);

end architecture;
