library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use lpm.lpm_components.lpm_counter;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity csr_sio_rs232 is
port(
    clk:                        in std_logic;
    clk_siox16:                 in std_logic;
    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    sdc_data_out:               in std_logic_vector(15 downto 0);
    csr_in:                     in csr_channel_in_t;
    csr_sel_result:             out std_logic_vector(31 downto 0);
    tx_intr_trigger:            out std_logic;
    uart0_tx:                   out std_logic;
    uart0_rx:                   in std_logic);
end entity;

architecture synth of csr_sio_rs232 is
signal counter:         std_logic_vector(3 downto 0);
signal tx_done:         std_logic := '0';
signal tx_start:        std_logic := '0';
signal tx_start_ack:    std_logic := '0';
signal tx_started:      std_logic := '0';
signal bstate:          std_logic_vector(3 downto 0) := (others => '0');
signal tx_byte:         std_logic_vector(7 downto 0);
signal tx_mem_word:     std_logic_vector(15 downto 0);
signal rx_ctrl:         std_logic_vector(31 downto 0) := (others => '0');
alias sclk:             std_logic is counter(3);
signal tx_ctrl:         std_logic_vector(31 downto 0) := (others => '0');
signal tx_buf_len:      std_logic_vector(7 downto 0);
alias tx_buf_curpos:    std_logic_vector(7 downto 0) is tx_ctrl(7 downto 0);

signal mem_op_strobe_save: std_logic;
signal mem_op_start:    std_logic := '0';

type tx_state_t is (
    RUNNING,
    MEM_OP_WAIT,
    WAIT_TX_BYTE);

signal tx_state:        tx_state_t := RUNNING;

begin

csr_sel_result <=
    rx_ctrl when csr_in.csr_sel_reg = CSR_REG_UART0_RX else
    tx_ctrl when csr_in.csr_sel_reg = CSR_REG_UART0_TX else
    "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

process(clk)
begin
    if (rising_edge(clk)) then
        if (csr_in.csr_op_valid = '1') then
            case csr_in.csr_op_reg is
                when CSR_REG_UART0_TX =>
                   tx_ctrl(31 downto 0) <= csr_in.csr_op_data(31 downto 7) & "00000000";
                   tx_buf_len <= csr_in.csr_op_data(7 downto 0);
                when others =>
            end case;
        end if;
    end if;
end process;

clk_counter: lpm_counter
    generic map(
        LPM_WIDTH => 4)
    port map(
        clock => clk_siox16,
        q => counter);

with bstate select
    uart0_tx <=
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

-- Back-to-back capable transmission algo
process(sclk)
begin
    if (rising_edge(sclk)) then
        if (tx_started = '1') then
            bstate <= std_logic_vector(unsigned(bstate) - 1);
            if (bstate = "0001") then
                tx_started <= '0';
                tx_start_ack <= tx_start;
            end if;
        else
            if (tx_start /= tx_start_ack) then
                tx_started <= '1';
                bstate <= "1001";
                tx_byte <= tx_mem_word(7 downto 0);
            end if;
        end if;
    end if;
end process;


mc_in.op_start <= mem_op_start;

tx_intr_trigger <= 
    '1' when (tx_buf_curpos = tx_buf_len and tx_buf_len /= "0000") else '0';


process(clk)
begin
    if (rising_edge(clk)) then
        case tx_state is 
            when RUNNING =>
                if (tx_buf_len /= tx_buf_curpos) then
                    if (tx_buf_curpos(0) = '1') then
                        tx_mem_word(7 downto 0) <= tx_mem_word(15 downto 8);
                        tx_state <= WAIT_TX_BYTE;
                        tx_start <= not tx_start;
                    else
                        mc_in.op_addr <= tx_ctrl(24 downto 8) & tx_buf_curpos;
                        mc_in.op_start <= not mem_op_start;
                        mc_in.op_wren <= '0';
                        mc_in.op_burst <= '0';
                        mc_in.op_dqm <= "00";
                        tx_state <= MEM_OP_WAIT;
                        mem_op_strobe_save <= mc_out.op_strobe;
                    end if;
                end if;
            when MEM_OP_WAIT =>
                if (mc_out.op_strobe /= mem_op_strobe_save) then
                    tx_mem_word <= sdc_data_out;                    
                    tx_state <= WAIT_TX_BYTE;
                    tx_start <= not tx_start;
                end if;
            when WAIT_TX_BYTE =>
                if (tx_done = '1') then
                    tx_buf_curpos <= 
                        std_logic_vector(unsigned(tx_buf_curpos) + 1); 
                    tx_state <= RUNNING;
                end if;
        end case;
    end if;
end process;

end architecture;
