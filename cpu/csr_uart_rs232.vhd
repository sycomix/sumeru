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
    clk_uartx16:                in std_logic;
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

signal tx_counter:      std_logic_vector(3 downto 0);
alias  tx_clk:          std_logic is tx_counter(3);
signal tx_done:         std_logic := '0';
signal tx_start:        std_logic := '0';
signal tx_start_ack:    std_logic := '0';
signal tx_started:      std_logic := '0';
signal tx_bstate:       std_logic_vector(3 downto 0) := (others => '0');
signal tx_ctrl:         std_logic_vector(23 downto 0) := (others => '0');
signal tx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');
signal tx_buf_curpos:   std_logic_vector(7 downto 0) := (others => '0');
signal tx_byte:         std_logic_vector(7 downto 0);
signal tx_mem_word:     std_logic_vector(15 downto 0);

type tx_state_t is (
    TX_RUNNING,
    TX_MEM_OP_WAIT,
    TX_WAIT_BYTE);

signal tx_state:        tx_state_t := TX_RUNNING;

signal rx_baud_counter: std_logic_vector(3 downto 0);
signal rx_wait_counter: std_logic_vector(3 downto 0);
signal rx_ctrl:         std_logic_vector(23 downto 0) := (others => '0');
signal rx_buf_len:      std_logic_vector(7 downto 0) := (others => '0');
signal rx_buf_curpos:   std_logic_vector(7 downto 0) := (others => '0');
signal rx_byte:         std_logic_vector(7 downto 0) := (others => '0');
signal rx_done:         std_logic := '0';
signal rx_detect:       std_logic := '0';
signal rx_bit_count:    std_logic_vector(3 downto 0);

type rx_state_t is (
    RX_RUNNING,
    RX_BITS);

signal rx_state:        rx_state_t := RX_RUNNING;

type rxd_state_t is (
    RXD_RUNNING,
    RXD_MEM_OP_WAIT);

signal rxd_state:       rxd_state_t := RXD_RUNNING;

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

-- RX Section
rx_intr_trigger <= 
    '1' when (rx_buf_curpos = rx_buf_len and rx_buf_len /= "00000000") else '0';

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is
                when CSR_REG_UART0_RX =>
                   rx_ctrl <= csr_in.csr_op_data(31 downto 8);
                   rx_buf_curpos <= (others => '0');
                   rx_buf_len <= csr_in.csr_op_data(7 downto 0);
                when others =>
            end case;
        end if;
        case rxd_state is
            when RXD_RUNNING =>
                if (rx_done = '1') then 
                    if (rx_buf_len /= rx_buf_curpos) then
                        mem_write <=  not mem_write;
                        rxd_state <= RXD_MEM_OP_WAIT;
                    end if;
                end if;
            when RXD_MEM_OP_WAIT =>
                if (mem_write = mem_write_ack) then
                    rx_buf_curpos <= 
                        std_logic_vector(unsigned(rx_buf_curpos) + 1);
                    rxd_state <= RXD_RUNNING;
                end if;
        end case;
    end if;
end process;


process(clk_uartx16)
begin
    if (rising_edge(clk_uartx16)) then
        rx_done <= '0';
        case rx_state is
            when RX_RUNNING =>
                if (uart_rx = '0') then
                    if (rx_detect = '0') then
                        rx_baud_counter <= (others => '0');
                        rx_detect <= '1';
                    else
                        rx_baud_counter <= 
                            std_logic_vector(unsigned(rx_baud_counter) + 1);
                    end if;
                else
                    if (rx_detect = '1') then
                        -- rx_baud_counter now contains bit delay
                        rx_bit_count <= "1000";
                        rx_state <= RX_BITS;
                        -- center wait for first bit
                        rx_wait_counter <= "0" & rx_baud_counter(3 downto 1);
                    end if;
                end if;
            when RX_BITS =>
                if (rx_wait_counter /= "0000") then
                    rx_wait_counter <= 
                        std_logic_vector(unsigned(rx_wait_counter) - 1);
                else
                    rx_wait_counter <= rx_baud_counter;
                    rx_bit_count <= 
                        std_logic_vector(unsigned(rx_bit_count) - 1);
                    if (rx_bit_count = "0000") then
                        -- stop bit check -- else error
                        if (uart_rx = '1') then
                            rx_done <= '1';
                        end if;
                        rx_state <= RX_RUNNING;
                    else
                        rx_byte <= uart_rx & rx_byte(7 downto 1);
                    end if;
                end if;
        end case;
    end if;
end process;


-- TX Section
tx_clk_counter: lpm_counter
    generic map(
        LPM_WIDTH => 4)
    port map(
        clock => clk_uartx16,
        q => tx_counter);

with tx_bstate select
    uart_tx <=
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
tx_intr_trigger <= '1' when (tx_buf_curpos = tx_buf_len and tx_buf_len /= "00000000") else '0';

process(tx_clk)
begin
    if (rising_edge(tx_clk)) then
        if (tx_started = '1') then
            tx_bstate <= std_logic_vector(unsigned(tx_bstate) - 1);
            if (tx_bstate = "0001") then
                tx_started <= '0';
                tx_start_ack <= tx_start;
            end if;
        else
            if (tx_start /= tx_start_ack) then
                tx_started <= '1';
                tx_bstate <= "1001";
                tx_byte <= tx_mem_word(7 downto 0);
            end if;
        end if;
    end if;
end process;

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is
                when CSR_REG_UART0_TX =>
                   tx_ctrl <= csr_in.csr_op_data(31 downto 8);
                   tx_buf_curpos <= (others => '0');
                   tx_buf_len <= csr_in.csr_op_data(7 downto 0);
                when others =>
            end case;
        end if;

        case tx_state is 
            when TX_RUNNING =>
                if (tx_buf_len /= tx_buf_curpos) then
                    mem_read <=  not mem_read;
                    tx_state <= TX_MEM_OP_WAIT;
                end if;
            when TX_MEM_OP_WAIT =>
                if (mem_read = mem_read_ack) then
                    tx_state <= TX_WAIT_BYTE;
                    tx_start <= not tx_start;
                end if;
            when TX_WAIT_BYTE =>
                if (tx_done = '1') then
                    tx_buf_curpos <= 
                        std_logic_vector(unsigned(tx_buf_curpos) + 1); 
                    tx_state <= TX_RUNNING;
                end if;
        end case;
    end if;
end process;

end architecture;
