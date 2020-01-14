library ieee, lpm;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity periph_dma is
port(
    clk:                        in std_logic;
    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    sdc_data_out:               in std_logic_vector(15 downto 0);
    pdma_in:                    in periph_dma_channel_in_t;
    pdma_out:                   out periph_dma_channel_out_t
    );
end entity;

architecture synth of periph_dma is
signal read_ack:        std_logic := '0';
signal write_ack:       std_logic := '0';
signal mem_op_start:    std_logic := '0';
signal mem_op_strobe_save: std_logic;

type mem_state_t is (
    MS_RUNNING,
    MS_WAIT);

signal mem_state: mem_state_t := MS_RUNNING;

signal last_read_addr:  std_logic_vector(23 downto 0);
signal mem_read_word:   std_logic_vector(15 downto 0);                

begin

mc_in.op_start <= mem_op_start;
mc_in.op_burst <= '0';

process(clk)
begin
    if (rising_edge(clk)) then
        case mem_state is
            when MS_RUNNING =>
                -- read check must have priority as we don't set
                -- read ack in MS_WAIT and set in below instead
                if (pdma_in.read /= read_ack) then
                    if (last_read_addr = pdma_in.addr(24 downto 1)) 
                    then
                        read_ack <= not read_ack;
                        if (pdma_in.addr(0) = '0') then
                            pdma_out.read_data <= mem_read_word(7 downto 0);
                        else
                            pdma_out.read_data <= mem_read_word(15 downto 8);
                        end if;
                    else
                        mc_in.op_addr <= pdma_in.addr(24 downto 1);
                        mem_op_start <= not mem_op_start;
                        mc_in.op_wren <= '0';
                        mc_in.op_dqm <= "00";
                        mem_op_strobe_save <= mc_out.op_strobe;
                        mem_state <= MS_WAIT;
                    end if;
                elsif (pdma_in.write /= write_ack) then
                    mc_in.op_addr <= pdma_in.addr(24 downto 1);
                    mem_op_start <= not mem_op_start;
                    mc_in.op_wren <= '1';
                    mc_in.write_data <= pdma_in.write_data & pdma_in.write_data;
                    mc_in.op_dqm(0) <= pdma_in.addr(0);
                    mc_in.op_dqm(1) <= not pdma_in.addr(0);
                    mem_op_strobe_save <= mc_out.op_strobe;
                    mem_state <= MS_WAIT;
                end if;
            when MS_WAIT =>
                if (mc_out.op_strobe /= mem_op_strobe_save) then
                    if (mc_in.op_wren = '1') then
                        write_ack <= not write_ack;
                    else
                        -- read_ack is set above refer to comment
                        last_read_addr <= pdma_in.addr(24 downto 1);
                        mem_read_word <= sdc_data_out;                    
                    end if;
                    mem_state <= MS_RUNNING;
                end if;
        end case;
    end if;
end process;

end architecture;
