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
    uart_rx:                    in std_logic);
end entity;

architecture synth of csr_uart_rs232 is
signal tx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');
signal rx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal rx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');

signal tx_intr_toggle_r:        std_logic := '0';


begin
csr_sel_result <=
    (rx_ctrl & rx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    (tx_ctrl & tx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

tx_intr_toggle <= tx_intr_toggle_r;
end architecture;
