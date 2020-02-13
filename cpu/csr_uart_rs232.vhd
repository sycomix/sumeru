library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;
use lpm.lpm_components.lpm_shiftreg;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity csr_uart_rs232 is
port(
    clk:                        in std_logic;
    reset:                      in std_logic;
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    pdma_in:                    out periph_dma_channel_in_t;
    pdma_out:                   in periph_dma_channel_out_t;
    tx_intr_toggle:             out std_logic;
    rx_intr_toggle:             out std_logic;
    uart_tx:                    out std_logic;
    uart_rx:                    in std_logic
    );
end entity;

architecture synth of csr_uart_rs232 is
signal tx_baud:                 std_logic_vector(11 downto 0) := DEFAULT_UART0_TX_BAUD;
signal tx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_len:              std_logic_vector(7 downto 0) := (others => '0');
signal tx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');

signal rx_ctrl:                 std_logic_vector(23 downto 0) := (others => '0');
signal rx_buf_curpos:           std_logic_vector(7 downto 0) := (others => '0');

signal tx_intr_toggle_r:        std_logic := '0';
signal rx_intr_toggle_r:        std_logic := '0';

signal tx_clk:                  std_logic := '0';
signal tx_clk_ctr:              std_logic_vector(11 downto 0) := (others => '0');

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

signal read_r:                  std_logic := '0';
signal write_r:                 std_logic := '0';

type rxd_state_t is (
    RXD_IDLE,
    RXD_RUNNING,
    RXD_CHECK_STOPBIT,
    RXD_MEM_WAIT,
    RXD_WAIT_STOPBIT
    );

signal rxd_state: rxd_state_t := RXD_IDLE;

signal rx_baud_a:       std_logic_vector(15 downto 0) := DEFAULT_UART0_RX_BAUD_A;
signal rx_baud_b:       std_logic_vector(15 downto 0) := DEFAULT_UART0_RX_BAUD_B;

signal rx_shreg_data:   std_logic_vector(15 downto 0);
signal rx_datareg_clk:  std_logic := '0';
signal rx_datareg_data: std_logic_vector(7 downto 0);

signal rx_reset_curpos: std_logic := '0';
signal rx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');

signal rx_counter:      std_logic_vector(15 downto 0);
signal rx_bitnr:        std_logic_vector(3 downto 0);
signal rx_reset_curpos_ack: std_logic := '0';

begin

pdma_in.read <= read_r;
pdma_in.write <= write_r;

csr_sel_result <=
    (rx_ctrl & rx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    (tx_ctrl & tx_buf_curpos) when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

tx_intr_toggle <= tx_intr_toggle_r;
rx_intr_toggle <= rx_intr_toggle_r;

rx_shreg: lpm_shiftreg
    generic map(
        LPM_DIRECTION => "RIGHT",
        LPM_WIDTH => 16)
    port map(
        clock => clk,
        aset => reset,
        shiftin => uart_rx,
        q => rx_shreg_data);

rx_datreg: lpm_shiftreg
    generic map(
        LPM_DIRECTION => "RIGHT",
        LPM_WIDTH => 8)
    port map(
        clock => rx_datareg_clk,
        shiftin => uart_rx,
        q => rx_datareg_data);

rx_reg_update: process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is
                when CSR_REG_UART0_RX =>
                    if (csr_in.csr_op_data(31) = '0') then
                        rx_ctrl <= csr_in.csr_op_data(31 downto 8);
                        rx_buf_len <= csr_in.csr_op_data(7 downto 0);
                        rx_reset_curpos <= not rx_reset_curpos;
                    end if;
                when CSR_REG_UART0_RX_BAUD =>
                    rx_baud_a <= csr_in.csr_op_data(15 downto 0);
                    rx_baud_b <= csr_in.csr_op_data(31 downto 16);
                when others =>
            end case;
        end if;
    end if;
end process;

process(clk)
begin
    if (rising_edge(clk)) then
        rx_datareg_clk <= '0';
        case rxd_state is
            when RXD_IDLE =>
                if (rx_shreg_data = x"0000") then
                    -- RX Start Bit
                    rx_counter <= rx_baud_a;
                    rxd_state <= RXD_RUNNING;
                    rx_bitnr <= "0000";
                end if;
            when RXD_RUNNING =>
                if (rx_counter = "0000000000000000") then
                    rx_datareg_clk <= '1';
                    rx_counter <= rx_baud_b;
                    rx_bitnr <= std_logic_vector(unsigned(rx_bitnr) + 1);
                    if (rx_bitnr = "0111") then
                        rxd_state <= RXD_CHECK_STOPBIT;
                    end if;
                else
                    rx_counter <= std_logic_vector(unsigned(rx_counter) - 1);
                end if;
            when RXD_CHECK_STOPBIT =>
                if (rx_counter = "0000000000000000") then
                    if (rx_shreg_data = x"FFFF") then
                        -- DMA BYTE TO MEM
                        pdma_in.write_data <= rx_datareg_data;
                        if (rx_reset_curpos /= rx_reset_curpos_ack) then
                            rx_reset_curpos_ack <= not rx_reset_curpos_ack;
                            pdma_in.write_addr <= rx_ctrl(16 downto 0) & "00000000";
                            if (rx_buf_len /= "00000000") then
                                write_r <= not write_r;
                                rxd_state <= RXD_MEM_WAIT;
                                rx_buf_curpos <= "00000001";
                            else
                                rx_buf_curpos <= "00000000";
                                rxd_state <= RXD_IDLE;
                            end if;
                        else
                            pdma_in.write_addr <= rx_ctrl(16 downto 0) & rx_buf_curpos;
                            if (rx_buf_curpos /= rx_buf_len)
                            then
                                rx_buf_curpos <= std_logic_vector(unsigned(rx_buf_curpos) + 1);
                                write_r <= not write_r;
                                rxd_state <= RXD_MEM_WAIT;
                            else
                                rxd_state <= RXD_IDLE;
                            end if;
                        end if;
                    else
                        rxd_state <= RXD_WAIT_STOPBIT;
                    end if;
                else
                    rx_counter <= std_logic_vector(unsigned(rx_counter) - 1);
                end if;
            when RXD_MEM_WAIT =>
                if (write_r = pdma_out.write_ack) then
                    if (rx_buf_curpos = rx_buf_len) then
                        rx_intr_toggle_r <= not rx_intr_toggle_r;
                    end if;
                    rxd_state <= RXD_IDLE;
                end if;
            when RXD_WAIT_STOPBIT =>
                if (rx_shreg_data = x"FFFF") then
                    rxd_state <= RXD_IDLE;
                end if;
        end case;
    end if;
end process;

tx_clk_gen: process(clk)
begin
    if (rising_edge(clk)) then
        if (tx_clk_ctr = tx_baud) then
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

process(clk)
begin
    if (rising_edge(clk)) then
        case tx_state is 
            when TX_IDLE =>
                if (csr_in.csr_op_valid = '1') then
                    case csr_in.csr_op_reg is
                        when CSR_REG_UART0_TX =>
                            if (csr_in.csr_op_data(31) = '0') then
                                tx_ctrl <= csr_in.csr_op_data(31 downto 8);
                                tx_buf_len <= csr_in.csr_op_data(7 downto 0);
                                tx_buf_curpos <= (others => '0');
                                tx_state <= TX_RUNNING;
                            end if;
                        when CSR_REG_UART0_TX_BAUD =>
                            tx_baud <= csr_in.csr_op_data(11 downto 0);
                        when others =>
                    end case;
                end if;
            when TX_RUNNING =>
                if (tx_buf_curpos /= tx_buf_len) then
                    pdma_in.read_addr <= tx_ctrl(16 downto 0) & tx_buf_curpos;
                    read_r <= not read_r;
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
