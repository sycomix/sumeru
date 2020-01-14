library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity csr_uart_rs232 is
port(
    clk:                        in std_logic;
    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    sdc_data_out:               in std_logic_vector(15 downto 0);
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             out std_logic_vector(31 downto 0);
    tx_intr_trigger:            out std_logic;
    rx_intr_trigger:            out std_logic;
    uart_tx:                    out std_logic;
    uart_rx:                    in std_logic);
end entity;

architecture synth of csr_uart_rs232 is
signal mem_read:        std_logic := '0';
signal mem_write:       std_logic := '0';
signal mem_read_ack:    std_logic := '0';
signal mem_write_ack:   std_logic := '0';
signal mem_op_start:    std_logic := '0';
signal mem_op_strobe_save: std_logic;

type mem_state_t is (
    MS_RUNNING,
    MS_WAIT);

signal mem_state: mem_state_t := MS_RUNNING;

signal rx_ctrl:         std_logic_vector(23 downto 0) := (others => '0');
signal rx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');
signal rx_buf_curpos:   std_logic_vector(23 downto 0) := (others => '0');
signal rx_byte:         std_logic_vector(7 downto 0);

signal tx_ctrl:         std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');
signal tx_buf_curpos:   std_logic_vector(23 downto 0) := (others => '0');
signal tx_mem_word:     std_logic_vector(15 downto 0);

begin
csr_sel_result <=
    (rx_ctrl & rx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    (tx_ctrl & tx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

-- Memory Read/Write process
mc_in.op_start <= mem_op_start;
mc_in.op_burst <= '0';

process(clk)
begin
    if (rising_edge(clk)) then
        case mem_state is
            when MS_RUNNING =>
                if (mem_write /= mem_write_ack) then
                    mc_in.op_addr <= rx_ctrl(16 downto 0) & rx_buf_curpos(7 downto 1);
                    mem_op_start <= not mem_op_start;
                    mc_in.op_wren <= '1';
                    mc_in.write_data <= rx_byte & rx_byte;
                    mc_in.op_dqm(0) <= rx_buf_curpos(0);
                    mc_in.op_dqm(1) <= not rx_buf_curpos(0);
                    mem_op_strobe_save <= mc_out.op_strobe;
                    mem_state <= MS_WAIT;
                elsif (mem_read /= mem_read_ack) then
                    if (tx_buf_curpos(0) = '1') then
                        tx_mem_word(7 downto 0) <= tx_mem_word(15 downto 8);
                        mem_read_ack <= not mem_read_ack;
                    else
                        mc_in.op_addr <= tx_ctrl(16 downto 0) & tx_buf_curpos(7 downto 1);
                        mem_op_start <= not mem_op_start;
                        mc_in.op_wren <= '0';
                        mc_in.op_dqm <= "00";
                        mem_op_strobe_save <= mc_out.op_strobe;
                        mem_state <= MS_WAIT;
                    end if;
                end if;
            when MS_WAIT =>
                if (mc_out.op_strobe /= mem_op_strobe_save) then
                    if (mc_in.op_wren = '1') then
                        mem_write_ack <= not mem_write_ack;
                    else
                        mem_read_ack <= not mem_read_ack;
                        tx_mem_word <= sdc_data_out;                    
                    end if;
                    mem_state <= MS_RUNNING;
                end if;
        end case;
    end if;
end process;

end architecture;
