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
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             out std_logic_vector(31 downto 0);
    pdma_in:                    out periph_dma_channel_in_t;
    pdma_out:                   in periph_dma_channel_out_t;
    tx_intr_toggle:             out std_logic;
    uart_tx:                    out std_logic;
    uart_rx:                    in std_logic
    ; debug:                    out std_logic
    );
end entity;

architecture synth of csr_uart_rs232 is
signal tx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_len:              std_logic_vector(7 downto 0) := (others => '0');
signal tx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');

signal rx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal rx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');

signal tx_intr_toggle_r:        std_logic := '0';

signal tx_clk:                  std_logic := '0';
signal tx_clk_ctr:              std_logic_vector(8 downto 0) := (others => '0');

signal txd_start:               std_logic := '0';

signal txd_byte:                std_logic_vector(7 downto 0) := (others => '1');
signal txd_bitnr:               std_logic_vector(3 downto 0) := (others => '0');
signal txd_start_ack:           std_logic := '0';

type tx_state_t is (
    TX_IDLE,
    TX_RUNNING,
    TX_READMEM_WAIT,
    TX_TXD_WAIT
    );

signal tx_state:                tx_state_t := TX_IDLE;

signal debug_r:                 std_logic := '0';

begin
debug <= debug_r;

csr_sel_result <=
    (rx_ctrl & rx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    (tx_ctrl & tx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

tx_intr_toggle <= tx_intr_toggle_r;

tx_clk_gen: process(clk)
begin
    if (rising_edge(clk)) then
        if (unsigned(tx_clk_ctr) = 368) then
            tx_clk <= not tx_clk;
            tx_clk_ctr <= (others => '0');
        else
            tx_clk_ctr <= std_logic_vector(unsigned(tx_clk_ctr) + 1);
        end if;
    end if;
end process;

with txd_bitnr select
    uart_tx <=
        txd_byte(7)     when "0001",
        txd_byte(6)     when "0010",
        txd_byte(5)     when "0011",
        txd_byte(4)     when "0100",
        txd_byte(3)     when "0101",
        txd_byte(2)     when "0110",
        txd_byte(1)     when "0111",
        txd_byte(0)     when "1000",
        '0'             when "1001",
        '1'             when others;

process(tx_clk)
begin
    if (rising_edge(tx_clk)) then
        if (txd_start /= txd_start_ack) then
            if (txd_bitnr = "0000") then
                txd_bitnr <= "1001";
            else
                if (txd_bitnr = "0001") then
                    txd_start_ack <= not txd_start_ack;
                end if;
                txd_bitnr <= std_logic_vector(unsigned(txd_bitnr) - 1);
            end if;
        end if;
    end if;
end process;

debug_r <= csr_in.csr_op_valid;

process(clk)
begin
    if (rising_edge(clk)) then
        case tx_state is 
            when TX_IDLE =>
                if (csr_in.csr_op_valid = '1' and 
                    csr_in.csr_op_reg = CSR_REG_UART0_TX)
                then
                    tx_ctrl <= csr_in.csr_op_data(31 downto 8);
                    tx_buf_len <= csr_in.csr_op_data(7 downto 0);
                    tx_buf_curpos <= (others => '0');
                    tx_state <= TX_RUNNING;
                end if;
            when TX_RUNNING =>
                if (tx_buf_curpos /= tx_buf_len) then
                    pdma_in.read_addr <= tx_ctrl(16 downto 0) & tx_buf_curpos;
                    pdma_in.read <= not pdma_in.read;
                    tx_state <= TX_READMEM_WAIT;
                else
                    tx_intr_toggle_r <= not tx_intr_toggle_r;
                    tx_state <= TX_IDLE;
                end if;
            when TX_READMEM_WAIT =>
                if (pdma_in.read = pdma_out.read_ack) then
                    txd_start <= not txd_start;
                    txd_byte <= pdma_out.read_data;
                    tx_state <= TX_TXD_WAIT;
                end if;
            when TX_TXD_WAIT =>
                if (txd_start = txd_start_ack) then
                    tx_state <= TX_RUNNING;
                    tx_buf_curpos <= std_logic_vector(unsigned(tx_buf_curpos) + 1);
                end if;
        end case;
    end if;
end process;

end architecture;
