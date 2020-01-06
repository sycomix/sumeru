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
    signal ctx_pc_switch_r:     std_logic_vector(31 downto 0) := (others => '0');
    signal ctr_instret:         std_logic_vector(63 downto 0);
    signal ctr_cycle:           std_logic_vector(63 downto 0);
begin

ctx_pc_switch <= ctx_pc_switch_r;

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

csr_sel_result <=
    ctx_pc_save   when csr_in.csr_sel_reg = CSR_REG_CTX_PCSAVE else
    ctx_pc_switch when csr_in.csr_sel_reg = CSR_REG_CTX_PCSWITCH else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1' and 
            csr_in.csr_op_reg = CSR_REG_CTX_PCSWITCH) 
        then
            ctx_pc_switch_r <= csr_in.csr_op_data;
        end if;
    end if;
end process;

end architecture;
