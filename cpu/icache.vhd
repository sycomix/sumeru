library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity icache is
port(
        sys_clk:                in std_logic;
        cache_clk:              in std_logic;
        enable:                 in std_logic;

        addr:                   in std_logic_vector(31 downto 0);
        hit:                    out std_logic;
        data:                   out std_logic_vector(31 downto 0);

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0)
    );
end entity;

architecture synth of icache is
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

    signal op_start:            std_logic := '0';

    type cache_state_t is (
        IDLE,
        WAIT_B1,
        WAIT_B2,
        WAIT_B3,
        WAIT_B4,
        WAIT_B5,
        WAIT_B6,
        WAIT_B7
    );

    signal state:               cache_state_t := IDLE;

    signal meta_data:           std_logic_vector(31 downto 0);
    signal write_data:          std_logic_vector(31 downto 0);

begin
    meta_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => meta_data,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data0_wren,
            q => data0);

    data1_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data1_wren,
            q => data1);

    data2_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data2_wren,
            q => data2);

    data3_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data3_wren,
            q => data3);

    with addr(3 downto 2) select 
        data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    hit <= '1' when (meta(31 downto 3) = (addr(31 downto 4) & "1")) else '0';
        
    meta_data <= addr(31 downto 4) & "1000";
 
    mc_in.op_start <= op_start;
    mc_in.op_addr <= addr(24 downto 1);
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
            write_data(15 downto 0) <= write_data(31 downto 16);
            write_data(31 downto 16) <= sdc_data_out;
            
            case state is
                when IDLE =>
                    if (hit = '0' and enable = '1') then
                        op_start <= not op_start;
                        state <= WAIT_B1;
                    end if;
                when WAIT_B1 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= WAIT_B2;
                        data0_wren <= '1';
                    end if;
                when WAIT_B2 =>
                    state <= WAIT_B3;
                when WAIT_B3 =>
                    state <= WAIT_B4;
                    data1_wren <= '1';
                when WAIT_B4 =>
                    state <= WAIT_B5;
                when WAIT_B5 =>
                    state <= WAIT_B6;
                    data2_wren <= '1';
                when WAIT_B6 =>
                    state <= WAIT_B7;
                when WAIT_B7 =>
                    state <= IDLE;
                    data3_wren <= '1';
                    meta_wren <= '1';
            end case;
        end if;
    end process;

end architecture;


