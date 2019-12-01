library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity memory_arbitrator is
port(
        clk:                    in std_logic;
        sdc_busy:               in std_logic;
        sdc_in:                 out mem_channel_in_t;
        sdc_out:                in mem_channel_out_t;
        
        mc0_in:                 in mem_channel_in_t;
        mc0_out:                out mem_channel_out_t;

        mc1_in:                 in mem_channel_in_t;
        mc1_out:                out mem_channel_out_t;
        
        mc2_in:                 in mem_channel_in_t;
        mc2_out:                out mem_channel_out_t;

        mc3_in:                 in mem_channel_in_t;
        mc3_out:                out mem_channel_out_t;

        mc4_in:                 in mem_channel_in_t;
        mc4_out:                out mem_channel_out_t;

        mc5_in:                 in mem_channel_in_t;
        mc5_out:                out mem_channel_out_t;

        mc6_in:                 in mem_channel_in_t;
        mc6_out:                out mem_channel_out_t;

        mc7_in:                 in mem_channel_in_t;
        mc7_out:                out mem_channel_out_t
    );
end entity;

architecture synth of memory_arbitrator is

    type arbit_state_t is (
        IDLE,
        WAIT_STROBE,
        WAIT_BUSY
        );

    signal state:               arbit_state_t := IDLE;
    signal chan:                std_logic_vector(2 downto 0) := (others => '0');
    signal op_start:            std_logic := '0';

    signal mc0_strobe_mux:      std_logic := '0';
    signal mc1_strobe_mux:      std_logic := '0';
    signal mc2_strobe_mux:      std_logic := '0';
    signal mc3_strobe_mux:      std_logic := '0';
    signal mc4_strobe_mux:      std_logic := '0';
    signal mc5_strobe_mux:      std_logic := '0';
    signal mc6_strobe_mux:      std_logic := '0';
    signal mc7_strobe_mux:      std_logic := '0';
    signal mc0_strobe:          std_logic := '0';
    signal mc1_strobe:          std_logic := '0';
    signal mc2_strobe:          std_logic := '0';
    signal mc3_strobe:          std_logic := '0';
    signal mc4_strobe:          std_logic := '0';
    signal mc5_strobe:          std_logic := '0';
    signal mc6_strobe:          std_logic := '0';
    signal mc7_strobe:          std_logic := '0';
    signal mc0_strobe_reg:      std_logic;
    signal mc1_strobe_reg:      std_logic;
    signal mc2_strobe_reg:      std_logic;
    signal mc3_strobe_reg:      std_logic;
    signal mc4_strobe_reg:      std_logic;
    signal mc5_strobe_reg:      std_logic;
    signal mc6_strobe_reg:      std_logic;
    signal mc7_strobe_reg:      std_logic;

begin
    sdc_in.op_start <= op_start;

    with chan select
        sdc_in.write_data <=
            mc0_in.write_data when "000",
            mc1_in.write_data when "001",
            mc2_in.write_data when "010",
            mc3_in.write_data when "011",
            mc4_in.write_data when "100",
            mc5_in.write_data when "101",
            mc6_in.write_data when "110",
            mc7_in.write_data when others;

    with chan select
        sdc_in.op_dqm <=
            mc0_in.op_dqm when "000",
            mc1_in.op_dqm when "001",
            mc2_in.op_dqm when "010",
            mc3_in.op_dqm when "011",
            mc4_in.op_dqm when "100",
            mc5_in.op_dqm when "101",
            mc6_in.op_dqm when "110",
            mc7_in.op_dqm when others;

    mc0_out.op_strobe <= 
             (sdc_out.op_strobe xor mc0_strobe_reg) when mc0_strobe_mux = '1'
             else mc0_strobe;
    mc1_out.op_strobe <= 
             (sdc_out.op_strobe xor mc1_strobe_reg) when mc1_strobe_mux = '1'
             else mc1_strobe;
    mc2_out.op_strobe <= 
             (sdc_out.op_strobe xor mc2_strobe_reg) when mc2_strobe_mux = '1'
             else mc2_strobe;
    mc3_out.op_strobe <= 
             (sdc_out.op_strobe xor mc3_strobe_reg) when mc3_strobe_mux = '1'
             else mc3_strobe;
    mc4_out.op_strobe <= 
             (sdc_out.op_strobe xor mc4_strobe_reg) when mc4_strobe_mux = '1'
             else mc4_strobe;
    mc5_out.op_strobe <= 
             (sdc_out.op_strobe xor mc5_strobe_reg) when mc5_strobe_mux = '1'
             else mc5_strobe;
    mc6_out.op_strobe <= 
             (sdc_out.op_strobe xor mc6_strobe_reg) when mc6_strobe_mux = '1'
             else mc6_strobe;
    mc7_out.op_strobe <= 
             (sdc_out.op_strobe xor mc7_strobe_reg) when mc7_strobe_mux = '1'
             else mc7_strobe;

    process(clk)
    begin
        if (rising_edge(clk)) then
            case state is
                when IDLE =>
                    if (mc0_in.op_start /= mc0_strobe) then
                        sdc_in.op_addr <= mc0_in.op_addr;
                        sdc_in.op_wren <= mc0_in.op_wren;
                        sdc_in.op_burst <= mc0_in.op_burst;
                        chan <= "000";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc0_strobe_mux <= '1';
                        mc0_strobe_reg <= 
                            mc0_strobe xor sdc_out.op_strobe;
                        mc0_strobe <= not mc0_strobe;
                    elsif (mc1_in.op_start /= mc1_strobe) then
                        sdc_in.op_addr <= mc1_in.op_addr;
                        sdc_in.op_wren <= mc1_in.op_wren;
                        sdc_in.op_burst <= mc1_in.op_burst;
                        chan <= "001";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc1_strobe_mux <= '1';
                        mc1_strobe_reg <= 
                            mc1_strobe xor sdc_out.op_strobe;
                        mc1_strobe <= not mc1_strobe;
                    elsif (mc2_in.op_start /= mc2_strobe) then
                        sdc_in.op_addr <= mc2_in.op_addr;
                        sdc_in.op_wren <= mc2_in.op_wren;
                        sdc_in.op_burst <= mc2_in.op_burst;
                        chan <= "010";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc2_strobe_mux <= '1';
                        mc2_strobe_reg <= 
                            mc2_strobe xor sdc_out.op_strobe;
                        mc2_strobe <= not mc2_strobe;
                    elsif (mc3_in.op_start /= mc3_strobe) then
                        sdc_in.op_addr <= mc3_in.op_addr;
                        sdc_in.op_wren <= mc3_in.op_wren;
                        sdc_in.op_burst <= mc3_in.op_burst;
                        chan <= "011";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc3_strobe_mux <= '1';
                        mc3_strobe_reg <= 
                            mc3_strobe xor sdc_out.op_strobe;
                        mc3_strobe <= not mc3_strobe;
                    elsif (mc4_in.op_start /= mc4_strobe) then
                        sdc_in.op_addr <= mc4_in.op_addr;
                        sdc_in.op_wren <= mc4_in.op_wren;
                        sdc_in.op_burst <= mc4_in.op_burst;
                        chan <= "100";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc4_strobe_mux <= '1';
                        mc4_strobe_reg <= 
                            mc4_strobe xor sdc_out.op_strobe;
                        mc4_strobe <= not mc4_strobe;
                    elsif (mc5_in.op_start /= mc5_strobe) then
                        sdc_in.op_addr <= mc5_in.op_addr;
                        sdc_in.op_wren <= mc5_in.op_wren;
                        sdc_in.op_burst <= mc5_in.op_burst;
                        chan <= "101";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc5_strobe_mux <= '1';
                        mc5_strobe_reg <= 
                            mc5_strobe xor sdc_out.op_strobe;
                        mc5_strobe <= not mc5_strobe;
                    elsif (mc6_in.op_start /= mc6_strobe) then
                        sdc_in.op_addr <= mc6_in.op_addr;
                        sdc_in.op_wren <= mc6_in.op_wren;
                        sdc_in.op_burst <= mc6_in.op_burst;
                        chan <= "110";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc6_strobe_mux <= '1';
                        mc6_strobe_reg <= 
                            mc6_strobe xor sdc_out.op_strobe;
                        mc6_strobe <= not mc6_strobe;
                    elsif (mc7_in.op_start /= mc7_strobe) then
                        sdc_in.op_addr <= mc7_in.op_addr;
                        sdc_in.op_wren <= mc7_in.op_wren;
                        sdc_in.op_burst <= mc7_in.op_burst;
                        chan <= "111";
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                        mc7_strobe_mux <= '1';
                        mc7_strobe_reg <= 
                            mc7_strobe xor sdc_out.op_strobe;
                        mc7_strobe <= not mc7_strobe;
                    end if;
                when WAIT_STROBE =>
                    if (sdc_out.op_strobe = op_start) then
                        state <= WAIT_BUSY;
                        mc0_strobe_mux <= '0';
                        mc1_strobe_mux <= '0';
                        mc2_strobe_mux <= '0';
                        mc3_strobe_mux <= '0';
                        mc4_strobe_mux <= '0';
                        mc5_strobe_mux <= '0';
                        mc6_strobe_mux <= '0';
                        mc7_strobe_mux <= '0';
                    end if;
                when WAIT_BUSY =>
                    if (sdc_busy = '0') then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture;


