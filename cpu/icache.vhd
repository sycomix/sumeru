library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity icache is
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        addr:                   in std_logic_vector(31 downto 0);
        hit:                    out std_logic;
        data:                   out std_logic_vector(31 downto 0);
        
        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        mc_data_out:            in std_logic_vector(15 downto 0)
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
        WAIT_LOAD,
        WAIT_B8);

    signal state:               cache_state_t := IDLE;

    signal byteena:             std_logic_vector(3 downto 0);
    signal write_data:          std_logic_vector(31 downto 0);
    signal meta_data:           std_logic_vector(31 downto 0);

    signal b1:                  std_logic := '0';
    signal b2:                  std_logic := '0';
    signal b3:                  std_logic := '0';
    signal b4:                  std_logic := '0';
    signal b5:                  std_logic := '0';
    signal b6:                  std_logic := '0';
    signal b7:                  std_logic := '0';
    signal b8:                  std_logic := '0';

begin
    meta_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => meta_data,
            wren => meta_wren,
            byteena => byteena,
            q => meta);

    data0_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data0_wren,
            byteena => byteena,
            q => data0);

    data1_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data1_wren,
            byteena => byteena,
            q => data1);

    data2_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data2_wren,
            byteena => byteena,
            q => data2);

    data3_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data3_wren,
            byteena => byteena,
            q => data3);

    with addr(3 downto 2) select 
        data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    hit <= 
        '1' when (meta(31 downto 3) = (addr(31 downto 4) & "1")) 
        else '0'; 

    mc_in.op_start <= op_start;
    mc_in.op_addr <= addr(23 downto 0);
    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    mc_in.op_burst <= '1';
    byteena <= "1111";

    write_data <= mc_data_out & mc_data_out;
    meta_data <= addr(31 downto 4) & "1000";

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';

            b1 <= '0';
            b2 <= b1;
            b3 <= b2;
            b4 <= b3;
            b5 <= b4;
            b6 <= b5;
            b7 <= b6;
            b8 <= b7;

            case state is
                when IDLE =>
                    if (hit = '0') then
                        op_start <= not op_start;
                        state <= WAIT_LOAD;
                    end if;
                when WAIT_LOAD =>
                    if (mc_out.op_strobe = op_start) then
                        b1 <= '1';
                        state <= WAIT_B8;
                    end if;
                when WAIT_B8 =>
                    if (b8 = '1') then
                        meta_wren <= '1';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture;


