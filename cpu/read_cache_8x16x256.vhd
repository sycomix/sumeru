library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity read_cache_8x16x256 is
port(
        sys_clk:                in std_logic;
        cache_clk:              in std_logic;

        addr:                   in std_logic_vector(15 downto 0);

        meta:                   out std_logic_vector(7 downto 0);
        data:                   out std_logic_vector(15 downto 0);

        load:                   in std_logic;
        flush:                  in std_logic;
        flush_strobe:           out std_logic;

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0);
        page_table_baseaddr:    in std_logic_vector(24 downto 0)
    );
end entity;

architecture synth of read_cache_8x16x256 is
    signal meta_wren:           std_logic := '0';

    signal data0:               std_logic_vector(15 downto 0);
    signal data1:               std_logic_vector(15 downto 0);
    signal data2:               std_logic_vector(15 downto 0);
    signal data3:               std_logic_vector(15 downto 0);

    signal data0_wren:          std_logic := '0';
    signal data1_wren:          std_logic := '0';
    signal data2_wren:          std_logic := '0';
    signal data3_wren:          std_logic := '0';

    signal op_start:            std_logic := '0';

    type cache_state_t is (
        IDLE,
        FLUSH_CACHE,
        WAIT_B1
    );

    signal state:               cache_state_t := IDLE;

    signal meta_data:           std_logic_vector(7 downto 0);
    signal meta_data_line_valid: std_logic;

    signal meta_addr:           std_logic_vector(7 downto 0);

    signal flush_enable:        std_logic := '0';
    signal flush_strobe_r:      std_logic := '0';
    signal flush_addr:          std_logic_vector(7 downto 0);

begin
    flush_strobe <= flush_strobe_r;

    meta_addr <= 
        addr(7 downto 0) when flush_enable = '0' else flush_addr;

    meta_ram: entity work.ram1p_256x8
        port map(
            clock => cache_clk,
            address => meta_addr,
            data => meta_data,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => sdc_data_out,
            wren => data0_wren,
            q => data0);

    data1_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => sdc_data_out,
            wren => data1_wren,
            q => data1);

    data2_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => sdc_data_out,
            wren => data2_wren,
            q => data2);

    data3_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => sdc_data_out,
            wren => data3_wren,
            q => data3);

    with addr(3 downto 2) select 
        data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    meta_data <= addr(14 downto 8) & meta_data_line_valid;
 
    mc_in.op_start <= op_start;
    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    mc_in.op_burst <= '0';
    mc_in.op_addr <= std_logic_vector(
                        unsigned(page_table_baseaddr(24 downto 1)) + 
                        unsigned(addr));
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';
            meta_data_line_valid <= '1';

            case state is
                when IDLE =>
                    if (flush = '1') then
                        flush_enable <= '1';
                        flush_addr <= (others => '1');
                        meta_data_line_valid <= '0';
                        meta_wren <= '1';
                        state <= FLUSH_CACHE;
                    elsif (load = '1') then
                        op_start <= not op_start;
                        state <= WAIT_B1;
                        -- Invalidate line till it is fully loaded
                        meta_data_line_valid <= '0';
                        meta_wren <= '1';
                    end if;
                when FLUSH_CACHE =>
                    if (flush_addr = x"00") then
                        flush_enable <= '0';
                        flush_strobe_r <= not flush_strobe_r;
                        state <= IDLE;
                    else
                        flush_addr <= std_logic_vector(unsigned(flush_addr) - 1);
                    end if;
                when WAIT_B1 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= IDLE;
                        data3_wren <= '1';
                        meta_wren <= '1';
                    end if;
            end case;
        end if;
    end process;

end architecture;


