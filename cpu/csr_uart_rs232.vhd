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
signal rx_intr:         std_logic := '0';

signal pdma_in:         periph_dma_channel_in_t := ('0', (others => '0'), '0', (others => '0'), (others => '0'));
signal pdma_out:        periph_dma_channel_out_t;

signal tx_clk:          std_logic := '0';
signal tx_ctr:          std_logic_vector(8 downto 0) := (others => '0');

signal tx_ctrl:         std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');
signal tx_buf_curpos:   std_logic_vector(7 downto 0) := (others => '0');
signal tx_intr:         std_logic := '0';
signal tx_intr_raise:   std_logic := '0';
signal tx_intr_raise_ack: std_logic := '0';

type tx_state_t is (
    TX_IDLE,
    TX_RUNNING,
    TX_READ_MEM,
    TX_WAIT);

signal tx_state: tx_state_t := TX_IDLE;

signal txd_start:       std_logic := '0';
signal txd_start_ack:   std_logic := '0';
signal txd_busy:        std_logic := '0';


begin
tx_intr_trigger <= tx_intr;
rx_intr_trigger <= rx_intr;

csr_sel_result <=
    (rx_ctrl & rx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    (tx_ctrl & tx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

-- Memory Read/Write process
mc_in.op_start <= mem_op_start;
mc_in.op_burst <= '0';

dma_engine: entity work.periph_dma
    port map(
        clk => clk,
        mc_in => mc_in,
        mc_out => mc_out,
        sdc_data_out => sdc_data_out,
        pdma_in => pdma_in,
        pdma_out => pdma_out
    );

tx_clk_gen: process(clk)
begin
    if (rising_edge(clk)) then
        if (unsigned(tx_ctr) = 368) then
            tx_clk <= not tx_clk;
            tx_ctr <= (others => '0');
        else
            tx_ctr <= std_logic_vector(unsigned(tx_ctr) + 1);
        end if;
    end if;
end process;

tx_reg_update: process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1' and
            csr_in.csr_op_reg = CSR_REG_UART0_TX) 
        then
            tx_ctrl <= csr_in.csr_op_data(31 downto 8);
            tx_buf_len <= csr_in.csr_op_data(31 downto 8);
            tx_intr <= '0';
        elsif (tx_intr_raise /= tx_intr_raise_ack) then
            tx_intr_raise_ack <= not tx_intr_raise_ack;
            tx_intr <= '1';
        end if;

    end if;
end process;

process(clk)
begin
    case tx_state is 
        when TX_IDLE =>
            if (tx_buf_len /= tx_buf_curpos and tx_buf_len /= x"00")  then
                tx_buf_curpos <= (others => '0');                
                tx_state <= TX_RUNNING;
            end if;
        when TX_RUNNING =>
            if (tx_buf_curpos /= tx_buf_len and txd_busy = '0') then
                pdma_in.read_addr <= '0' & tx_ctrl(23 downto 8) & tx_buf_curpos;                
                pdma_in.read <= not pdma_in.read;
                tx_state <= TX_READ_MEM;
            else
                tx_intr_raise <= not tx_intr_raise;
                tx_state <= TX_IDLE;
            end if;
        when TX_READ_MEM =>
            if (pdma_in.read = pdma_out.read_ack) then
                txd_start <= not txd_start;
            end if;
        when TX_WAIT =>
            if (txd_start = txd_start_ack) then
                tx_buf_curpos <= std_logic_vector(unsigned(tx_buf_curpos) + 1);
                tx_state <= TX_RUNNING;
            end if;
    end case;
end process;

process(tx_clk)
begin
    if (txd_start /= tx_start_ack) then
        txd_bcounter <= 
end if;


end architecture;
