library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity dcache is
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        
        hit:                    out std_logic;

        op_start:               in std_logic;
        op_wren:                in std_logic;
        op_byteena:             in std_logic_vector(3 downto 0);
        op_strobe:              out std_logic;

        op_addr:                in std_logic_vector(31 downto 0);
        op_data:                out std_logic_vector(31 downto 0);
        op_data_write:          in std_logic_vector(31 downto 0);

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0)
    );
end entity;

architecture synth of dcache is
    signal meta:                std_logic_vector(31 downto 0);
    signal meta_wren:           std_logic := '0';

    signal data0:               std_logic_vector(31 downto 0);
    signal data1:               std_logic_vector(31 downto 0);
    signal data2:               std_logic_vector(31 downto 0);
    signal data3:               std_logic_vector(31 downto 0);

    signal data0_wren:          std_logic := '0';
    signal data1_wren:          std_logic := '0';
    signal data2_wren:          std_logic := '0';
    signal data3_wren:          std_logic := '0';

    signal mc_op_start:         std_logic := '0';

    type cache_state_t is (
        IDLE,
        WAIT_B1,
        WAIT_B2,
        WAIT_B3,
        WAIT_B4,
        WAIT_B5,
        WAIT_B6,
        WAIT_B7,        
        WAIT_B8);

    signal state:               cache_state_t := IDLE;

    signal meta_write:          std_logic_vector(31 downto 0);
    signal data_write:          std_logic_vector(31 downto 0);

begin
    meta_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => op_addr(11 downto 4),
            data => meta_write,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => op_addr(11 downto 4),
            data => data_write,
            wren => data0_wren,
            q => data0);

    data1_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => op_addr(11 downto 4),
            data => data_write,
            wren => data1_wren,
            q => data1);

    data2_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => op_addr(11 downto 4),
            data => data_write,
            wren => data2_wren,
            q => data2);

    data3_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => op_addr(11 downto 4),
            data => data_write,
            wren => data3_wren,
            q => data3);

    with op_addr(3 downto 2) select 
        op_data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    hit <= '1' when (meta(31 downto 3) = (op_addr(31 downto 4) & "1")) else '0';
        
    meta_write <= op_addr(31 downto 4) & "1000";
 
    mc_in.op_start <= mc_op_start;
    mc_in.op_addr <= op_addr(24 downto 1);
    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    mc_in.op_burst <= '1';
    
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';
            data_write(15 downto 0) <= data_write(31 downto 16);
            data_write(31 downto 16) <= sdc_data_out;
            
            case state is
                when IDLE =>
                    if (hit = '0' and enable = '1') then
                        mc_op_start <= not mc_op_start;
                        state <= WAIT_B1;
                    end if;
                when WAIT_B1 =>
                    if (mc_out.op_strobe = mc_op_start) then
                        state <= WAIT_B2;
                    end if;
                when WAIT_B2 =>
                    data0_wren <= '1';
                    state <= WAIT_B3;
                when WAIT_B3 =>
                    state <= WAIT_B4;
                when WAIT_B4 =>
                    data1_wren <= '1';
                    state <= WAIT_B5;
                when WAIT_B5 =>
                    state <= WAIT_B6;
                when WAIT_B6 =>
                    data2_wren <= '1';
                    state <= WAIT_B7;
                when WAIT_B7 =>
                    state <= WAIT_B8;
                when WAIT_B8 =>
                    data3_wren <= '1';
                    meta_wren <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;

end architecture;


