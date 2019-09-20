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
        mc_out:                 in mem_channel_out_t
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

    signal write_data:          std_logic_vector(31 downto 0);

begin
    meta_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data0_wren,
            q => data0);

    data1_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data1_wren,
            q => data1);

    data2_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data2_wren,
            q => data2);

    data3_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data3_wren,
            q => data3);

    with addr(3 downto 2) select 
        data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    hit <= 
        '1' when (meta(31 downto 3) = (addr(31 downto 4) & "1")) 
        else '0'; 


    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';
            if (hit = '0') then
                mc_in.op_addr <= addr(23 downto 0);
                mc_in.op_start <= '1';
                mc_in.op_wren <= '0';
            end if;
        end if;
    end process;

end architecture;


