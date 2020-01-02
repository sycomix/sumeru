library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity csr_counters is
port(
    clk:                        in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    clk_cycle:                  in std_logic;
    clk_instret:                in std_logic;
    ctx_pc_save:                in std_logic_vector(31 downto 0);
    ctx_pc_switch:              out std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of csr_counters is
    signal result:              std_logic_vector(32 downto 0);
    signal ctr_instret:         std_logic_vector(63 downto 0);
    signal ctr_cycle:           std_logic_vector(63 downto 0);
    alias  sreg:                std_logic_vector(11 downto 0) is csr_in.csr_sel_reg;
    signal sel:                 std_logic := '0';
begin

csr_sel_result <= result(31 downto 0);

-- XXX CONNECT ACLR and reset counters on reset_n
instret_counter: lpm_counter
    generic map(
        LPM_WIDTH => 64)
    port map(
        clock => clk_instret,
        q => ctr_instret);

cycle_counter: lpm_counter
    generic map(
        LPM_WIDTH => 64)
    port map(
        clock => clk_cycle,
        q => ctr_cycle);

result <=
    "0" & ctr_cycle(31 downto 0)  when sreg = CSR_REG_CTR_CYCLE else 
    "0" & ctr_cycle(63 downto 32) when sreg = CSR_REG_CTR_CYCLE_H else 
    "0" & ctr_instret(31 downto 0)  when sreg = CSR_REG_CTR_INSTRET else 
    "0" & ctr_instret(63 downto 32) when sreg = CSR_REG_CTR_INSTRET_H else 
    "0" & ctx_pc_save   when sreg = CSR_REG_CTX_PCSAVE else
    "1" & ctx_pc_switch when sreg = CSR_REG_CTX_PCSWITCH else
    "0ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        sel <= result(32);
        if (sel = '1' and csr_in.csr_op_valid = '1') then
            ctx_pc_switch <= csr_in.csr_op_data;
        end if;
    end if;
end process;

end architecture;
