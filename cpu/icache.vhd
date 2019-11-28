library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity icache is
port(
        sys_clk:                in std_logic;
        cache_clk:              in std_logic;
        enable:                 in std_logic;

        pc:                     in std_logic_vector(31 downto 0);

        tlb_hit:                out std_logic;
        hit:                    out std_logic;
        data:                   out std_logic_vector(31 downto 0);

        flush:                  in std_logic;
        flush_strobe:           out std_logic;

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0);

        page_table_baseaddr:    in std_logic_vector(24 downto 0)
    );
end entity;

architecture synth of icache is
    signal meta:                std_logic_vector(15 downto 0);
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
        FLUSH_CACHE,
        WAIT_TLB,
        WAIT_B1,
        WAIT_B2,
        WAIT_B3,
        WAIT_B4,
        WAIT_B5,
        WAIT_B6,
        WAIT_B7,
        WAIT_B8
    );

    signal state:               cache_state_t := IDLE;

    signal meta_data:           std_logic_vector(15 downto 0);
    signal meta_data_line_valid: std_logic;

    signal write_data:          std_logic_vector(31 downto 0);
    signal meta_addr:           std_logic_vector(7 downto 0);

    signal flush_enable:        std_logic := '0';
    signal flush_strobe_r:      std_logic := '0';
    signal flush_addr:          std_logic_vector(7 downto 0);

    alias tlb_addr:             std_logic_vector(15 downto 0) is pc(31 downto 16);
    signal tlb_meta_addr:       std_logic_vector(7 downto 0);
    signal tlb_meta_data:       std_logic_vector(7 downto 0);
    signal tlb_meta:            std_logic_vector(7 downto 0);
    signal tlb_meta_wren:       std_logic := '0';
    signal tlb_data:            std_logic_vector(15 downto 0);
    signal tlb_data_wren:       std_logic := '0';
    signal tlb_hit0:            std_logic;
    signal tlb_meta_data_line_valid: std_logic;
    signal tlb_lastaddr:        std_logic_vector(15 downto 0) := (others => '1');

    signal addr:                std_logic_vector(24 downto 0);

begin
    flush_strobe <= flush_strobe_r;

    -- TLB Stuff

    tlb_meta_addr <= 
        tlb_addr(7 downto 0) when flush_enable = '0' else flush_addr;

    tlb_meta_ram: entity work.ram1p_256x8
        port map(
            clock => cache_clk,
            address => tlb_meta_addr,
            data => tlb_meta_data,
            wren => tlb_meta_wren,
            q => tlb_meta);

    tlb_data_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => tlb_addr(7 downto 0),
            data => sdc_data_out,
            wren => tlb_data_wren,
            q => tlb_data);

    tlb_hit0 <= '1' when tlb_meta = (tlb_addr(14 downto 8) & "1") else '0';

    tlb_hit <= '1' when (tlb_lastaddr = tlb_addr and tlb_hit0 = '1') else '0';

    tlb_meta_data <= tlb_addr(14 downto 8) & tlb_meta_data_line_valid;

    process(sys_clk)
    begin
            if (tlb_hit0) then
                tlb_lastaddr <= tlb_addr;
            end if;
    end process;

    -- End TLB Stuff

    addr <= tlb_data(8 downto 0) & pc(15 downto 0);

    meta_addr <= 
        addr(11 downto 4) when flush_enable = '0' else flush_addr;

    meta_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => meta_addr,
            data => meta_data,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.ram1p_256x32
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data0_wren,
            q => data0);

    data1_ram: entity work.ram1p_256x32
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data1_wren,
            q => data1);

    data2_ram: entity work.ram1p_256x32
        port map(
            clock => cache_clk,
            address => addr(11 downto 4),
            data => write_data,
            wren => data2_wren,
            q => data2);

    data3_ram: entity work.ram1p_256x32
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

    hit <= '1' when meta(15 downto 2) = (addr(24 downto 12) & "1") else '0';
    meta_data <= addr(24 downto 12) & meta_data_line_valid & "00" ;
 
    mc_in.op_start <= op_start;
    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';
            meta_data_line_valid <= '1';
            write_data(15 downto 0) <= write_data(31 downto 16);
            write_data(31 downto 16) <= sdc_data_out;

            tlb_data_wren <= '0';
            tlb_meta_wren <= '0';
            tlb_meta_data_line_valid <= '1';
            
            case state is
                when IDLE =>
                    if (flush = '1') then
                        flush_enable <= '1';
                        flush_addr <= (others => '1');
                        meta_data_line_valid <= '0';
                        meta_wren <= '1';
                        tlb_meta_data_line_valid <= '0';
                        tlb_meta_wren <= '1';
                        state <= FLUSH_CACHE;
                    elsif (enable = '1' and tlb_hit = '0') then
                        mc_in.op_addr <= 
                            std_logic_vector(
                                unsigned(page_table_baseaddr(24 downto 1)) + 
                                unsigned(tlb_addr));
                        op_start <= not op_start;
                        state <= WAIT_TLB;
                        mc_in.op_burst <= '0';
                    elsif (enable = '1' and hit = '0') then
                        mc_in.op_addr <= addr(24 downto 4) & "000"; -- read only at 16 byte boundary
                        op_start <= not op_start;
                        state <= WAIT_B1;
                        -- Invalidate line till it is fully loaded
                        meta_data_line_valid <= '0';
                        meta_wren <= '1';
                        mc_in.op_burst <= '1';
                    end if;
                when FLUSH_CACHE =>
                    if (flush_addr = x"00") then
                        flush_enable <= '0';
                        flush_strobe_r <= not flush_strobe_r;
                        state <= IDLE;
                    else
                        flush_addr <= std_logic_vector(unsigned(flush_addr) - 1);
                    end if;
                when WAIT_TLB =>
                    if (mc_out.op_strobe = op_start) then
                        state <= IDLE;
                        tlb_data_wren <= '1';
                        tlb_meta_wren <= '1';
                    end if;
                when WAIT_B1 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= WAIT_B2;
                    end if;
                when WAIT_B2 =>
                    state <= WAIT_B3;
                    data0_wren <= '1';
                when WAIT_B3 =>
                    state <= WAIT_B4;
                when WAIT_B4 =>
                    state <= WAIT_B5;
                    data1_wren <= '1';
                when WAIT_B5 =>
                    state <= WAIT_B6;
                when WAIT_B6 =>
                    state <= WAIT_B7;
                    data2_wren <= '1';
                when WAIT_B7 =>
                    state <= WAIT_B8;
                when WAIT_B8 =>
                    state <= IDLE;
                    data3_wren <= '1';
                    meta_wren <= '1';
            end case;
        end if;
    end process;

end architecture;


