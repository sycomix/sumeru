library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity csr_misc is
port(
    clk:                        in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    ivector_addr:               out std_logic_vector(23 downto 0);
    ctx_pc_save:                in std_logic_vector(31 downto 0);
    ctx_pc_switch:              out std_logic_vector(31 downto 0)
    );
end entity;

architecture synth of csr_misc is
    signal ctx_pc_switch_r:     std_logic_vector(31 downto 0) := (others => '0');
    signal ivector_addr_r:      std_logic_vector(31 downto 0) := (others => '0');
begin

ivector_addr <= ivector_addr_r(31 downto 8);
ctx_pc_switch <= ctx_pc_switch_r;

csr_sel_result <=
    ctx_pc_save when csr_in.csr_sel_reg = CSR_REG_CTX_PCSAVE else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is 
                when CSR_REG_IVECTOR_ADDR =>
                    ivector_addr_r <= csr_in.csr_op_data;
                when CSR_REG_CTX_PCSWITCH =>
                    ctx_pc_switch_r <= csr_in.csr_op_data;
                when others =>
            end case;
        end if;
    end if;
end process;

end architecture;
