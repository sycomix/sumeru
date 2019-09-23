library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity memory_arbitrator is
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        
        mc0_enable:             in std_logic;
        mc0_in:                 in mem_channel_in_t;
        mc0_out:                out mem_channel_out_t;

        mc1_enable:             in std_logic;
        mc1_in:                 in mem_channel_in_t;
        mc1_out:                out mem_channel_out_t;
        
        mc2_enable:             in std_logic;
        mc2_in:                 in mem_channel_in_t;
        mc2_out:                out mem_channel_out_t;

        mc3_enable:             in std_logic;
        mc3_in:                 in mem_channel_in_t;
        mc3_out:                out mem_channel_out_t;

        sdc_in:                 out mem_channel_in_t;
        sdc_out:                in mem_channel_out_t;

        sdc_busy:               in std_logic
    );
end entity;

architecture synth of memory_arbitrator is

    type arbit_state_t is (
        IDLE,
        WAIT_STROBE
        );

    signal state:               arbit_state_t := IDLE;
    signal chan:                std_logic_vector(1 downto 0) := (others => '0');
    signal op_start:            std_logic := '0';
    signal mc0_strobe:          std_logic := '0';
    signal mc1_strobe:          std_logic := '0';
    signal mc2_strobe:          std_logic := '0';
    signal mc3_strobe:          std_logic := '0';

begin
    sdc_in.op_start <= op_start;
    mc0_out.op_strobe <= mc0_strobe;
    mc1_out.op_strobe <= mc1_strobe;
    mc2_out.op_strobe <= mc2_strobe;
    mc3_out.op_strobe <= mc3_strobe;

    with chan select
        sdc_in.write_data <=
            mc0_in.write_data when "00",
            mc1_in.write_data when "01",
            mc2_in.write_data when "10",
            mc3_in.write_data when others;

    with chan select
        sdc_in.op_dqm <=
            mc0_in.op_dqm when "00",
            mc1_in.op_dqm when "01",
            mc2_in.op_dqm when "10",
            mc3_in.op_dqm when others;

    process(mem_clk)
    begin
        if (rising_edge(mem_clk)) then
            case state is
                when IDLE =>
                    if (sdc_busy = '0') then
                        if (mc0_in.op_start /= mc0_strobe and mc0_enable = '1') then
                            sdc_in.op_addr <= mc0_in.op_addr;
                            sdc_in.op_wren <= mc0_in.op_wren;
                            sdc_in.op_burst <= mc0_in.op_burst;
                            chan <= "00";
                            op_start <= not op_start;
                            state <= WAIT_STROBE;
                        elsif (mc1_in.op_start /= mc1_strobe and mc1_enable = '1') then
                            sdc_in.op_addr <= mc1_in.op_addr;
                            sdc_in.op_wren <= mc1_in.op_wren;
                            sdc_in.op_burst <= mc1_in.op_burst;
                            chan <= "01";
                            op_start <= not op_start;
                            state <= WAIT_STROBE;
                        elsif (mc2_in.op_start /= mc2_strobe and mc2_enable = '1') then
                            sdc_in.op_addr <= mc2_in.op_addr;
                            sdc_in.op_wren <= mc2_in.op_wren;
                            sdc_in.op_burst <= mc2_in.op_burst;
                            chan <= "10";
                            op_start <= not op_start;
                            state <= WAIT_STROBE;
                        elsif (mc3_in.op_start /= mc3_strobe and mc3_enable = '1') then
                            sdc_in.op_addr <= mc3_in.op_addr;
                            sdc_in.op_wren <= mc3_in.op_wren;
                            sdc_in.op_burst <= mc3_in.op_burst;
                            chan <= "11";
                            op_start <= not op_start;
                            state <= WAIT_STROBE;
                        end if;
                    end if;
                when WAIT_STROBE =>
                    if (sdc_out.op_strobe = op_start) then
                        state <= IDLE;
                        case chan is
                            when "00" =>
                                mc0_strobe <= not mc0_strobe;
                            when "01" =>
                                mc1_strobe <= not mc1_strobe;
                            when "10" =>
                                mc2_strobe <= not mc2_strobe;
                            when others =>
                                mc3_strobe <= not mc3_strobe;
                        end case;
                    end if;
            end case;
        end if;
    end process;

end architecture;


