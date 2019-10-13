library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity page_tlb is
port(
        sys_clk:                in std_logic;
        cache_clk:              in std_logic;
        enable:                 in std_logic;

        page_table_baseaddr:    in std_logic_vector(24 downto 0);

        chan0_addr:             in std_logic_vector(15 downto 0);
        chan0_hit:              out std_logic;
        chan0_data:             out std_logic_vector(15 downto 0);

        chan1_addr:             in std_logic_vector(15 downto 0);
        chan1_hit:              out std_logic;
        chan1_data:             out std_logic_vector(15 downto 0);

        flush:                  in std_logic;
        flush_line:             in std_logic_vector(7 downto 0);

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0)
    );
end entity;

architecture synth of page_tlb is
    signal chan0_meta:                  std_logic_vector(7 downto 0);
    signal chan0_meta_wren:             std_logic := '0';
    alias chan0_meta_line_valid:        std_logic is chan0_meta(0);

    signal chan1_meta:                  std_logic_vector(7 downto 0);
    signal chan1_meta_wren:             std_logic := '0';
    alias chan1_meta_line_valid:        std_logic is chan1_meta(0);

    signal chan0_data0:                 std_logic_vector(15 downto 0);
    signal chan0_data0_wren:            std_logic := '0';

    signal chan1_data0:                 std_logic_vector(15 downto 0);
    signal chan1_data0_wren:            std_logic := '0';

    signal op_start:            std_logic := '0';

    type cache_state_t is (
        IDLE,
        WAIT_CHAN0,
        WAIT_CHAN1
    );

    signal state:               cache_state_t := IDLE;

    signal chan0_meta_data:     std_logic_vector(7 downto 0);
    signal chan0_write_data:    std_logic_vector(31 downto 0);

    signal chan1_meta_data:     std_logic_vector(7 downto 0);
    signal chan1_write_data:    std_logic_vector(31 downto 0);

    signal chan0_meta_addr:     std_logic_vector(7 downto 0);
    signal chan1_meta_addr:     std_logic_vector(7 downto 0);

    signal flush_enable:        std_logic := '0';
    signal meta_write_line_valid: std_logic;

begin
    chan0_meta_addr <= 
        chan0_addr(7 downto 0) when flush_enable = '0' else flush_line;

    chan1_meta_addr <= 
        chan1_addr(7 downto 0) when flush_enable = '0' else flush_line;

    chan0_meta_ram: entity work.ram1p_256x8
        port map(
            clock => cache_clk,
            address => chan0_meta_addr,
            data => chan0_meta_data,
            wren => chan0_meta_wren,
            q => chan0_meta);

    chan0_data0_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => chan0_addr(7 downto 0),
            data => sdc_data_out,
            wren => chan0_data0_wren,
            q => chan0_data);

    chan1_meta_ram: entity work.ram1p_256x8
        port map(
            clock => cache_clk,
            address => chan1_meta_addr,
            data => chan1_meta_data,
            wren => chan1_meta_wren,
            q => chan1_meta);

    chan1_data0_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => chan1_addr(7 downto 0),
            data => sdc_data_out,
            wren => chan1_data0_wren,
            q => chan1_data);

    chan0_hit <= '1' when chan0_meta = (chan0_addr(14 downto 8) & "1") else '0';
    chan0_meta_data <= chan0_addr(14 downto 8) & meta_write_line_valid;

    chan1_hit <= '1' when chan1_meta = (chan1_addr(14 downto 8) & "1") else '0';
    chan1_meta_data <= chan1_addr(14 downto 8) & meta_write_line_valid;
 
    mc_in.op_start <= op_start;

    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    mc_in.op_burst <= '0';
    
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            chan0_data0_wren <= '0';
            chan0_meta_wren <= '0';
            chan1_data0_wren <= '0';
            chan1_meta_wren <= '0';
            meta_write_line_valid <= '1';
            
            case state is
                when IDLE =>
                    if (chan0_hit = '0' and enable = '1') then
                        mc_in.op_addr <= 
                            std_logic_vector(
                                unsigned(page_table_baseaddr(24 downto 1)) + 
                                unsigned("00000000" & chan0_addr));
                        op_start <= not op_start;
                        state <= WAIT_CHAN0;
                    elsif (chan1_hit = '0' and enable = '1') then
                        mc_in.op_addr <= 
                            std_logic_vector(
                                unsigned(page_table_baseaddr(24 downto 1)) + 
                                unsigned("00000000" & chan1_addr));
                        op_start <= not op_start;
                        state <= WAIT_CHAN1;
                    elsif (flush = '1') then
                        flush_enable <= '1';
                        meta_write_line_valid <= '0';
                        chan0_meta_wren <= '1';
                        chan1_meta_wren <= '1';
                    end if;
                when WAIT_CHAN0 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= IDLE;
                        chan0_data0_wren <= '1';
                        chan0_meta_wren <= '1';
                    end if;
                when WAIT_CHAN1 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= IDLE;
                        chan1_data0_wren <= '1';
                        chan1_meta_wren <= '1';
                    end if;
            end case;
        end if;
    end process;

end architecture;


