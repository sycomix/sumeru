library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;
use work.cpu_types.ALL;
use work.sumeru_constants.ALL;

entity cpu is
port(
    clk_50m:                    in std_logic;
    btn:                        in std_logic;
    led:                        out std_logic;
    spi0_sck:                   out std_logic;
    spi0_ss:                    out std_logic;
    spi0_mosi:                  out std_logic;
    spi0_miso:                  in std_logic;
    sdram_data:                 inout std_logic_vector(15 downto 0);
    sdram_addr:                 out std_logic_vector(12 downto 0);
    sdram_ba:                   out std_logic_vector(1 downto 0);
    sdram_dqm:                  out std_logic_vector(1 downto 0);
    sdram_ras:                  out std_logic;
    sdram_cas:                  out std_logic;
    sdram_cke:                  out std_logic;
    sdram_clk:                  out std_logic;
    sdram_we:                   out std_logic;
    sdram_cs:                   out std_logic);
end entity;

architecture synth of cpu is
    signal sys_clk:             std_logic;
    signal mem_clk:             std_logic;
    signal cache_clk:           std_logic;
    signal reset_n:             std_logic;

    signal sdc_in:              mem_channel_in_t;
    signal sdc_out:             mem_channel_out_t;
    signal sdc_data_out:        std_logic_vector(15 downto 0);
    signal sdc_busy:            std_logic;

    signal mc0_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc0_out:             mem_channel_out_t;

    signal mc1_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc1_out:             mem_channel_out_t;

    signal mc2_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc2_out:             mem_channel_out_t;

    signal mc3_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc3_out:             mem_channel_out_t;

    signal mc4_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc4_out:             mem_channel_out_t;

    signal mc5_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc5_out:             mem_channel_out_t;

    signal mc6_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc6_out:             mem_channel_out_t;

    signal mc7_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc7_out:             mem_channel_out_t;

    signal bc_mc1_in:           mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal pbus_mc1_in:         mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));

    signal bootcode_load_done:  std_logic;

    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_addr:         std_logic_vector(24 downto 0);
    signal icache_meta:         std_logic_vector(15 downto 0);
    signal icache_data:         std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';

    signal icache_tlb_meta:     std_logic_vector(7 downto 0);
    signal icache_tlb_data:     std_logic_vector(15 downto 0);
    signal icache_tlb_last_idx: std_logic_vector(7 downto 0);
    signal icache_tlb_load:     std_logic := '0';

    signal page_table_baseaddr: std_logic_vector(24 downto 0) := (others => '0');

    type state_t is (
        IDLE,
        WAIT_ICACHE_LOAD,
        WAIT_ICACHE_TLB_LOAD,
        DONE
    );
        
    signal state:               state_t := IDLE;

begin
spi0_sck <= '0';
spi0_ss <= '0';
spi0_mosi <= '0';

pll: entity work.pll 
    port map(
        inclk0 => clk_50m,
        c0 => sys_clk,
        c1 => mem_clk,
        locked => reset_n);

sdram_controller: entity work.sdram_controller
    port map(
        sys_clk => sys_clk,
        mem_clk => mem_clk,
        mc_in => sdc_in,
        mc_out => sdc_out,
        data_out => sdc_data_out,
        sdram_data => sdram_data,
        sdram_addr => sdram_addr,
        sdram_ba => sdram_ba,
        sdram_dqm => sdram_dqm,
        sdram_ras => sdram_ras,
        sdram_cas => sdram_cas,
        sdram_cke => sdram_cke,
        sdram_clk => sdram_clk,
        sdram_we => sdram_we,
        sdram_cs => sdram_cs,
        busy => sdc_busy);
        
memory_arbitrator: entity work.memory_arbitrator
    port map(
        clk => sys_clk,

        sdc_busy => sdc_busy,
        sdc_in => sdc_in,
        sdc_out => sdc_out,

        mc0_in => mc0_in,
        mc0_out => mc0_out,

        mc1_in => mc1_in,
        mc1_out => mc1_out,

        mc2_in => mc2_in,
        mc2_out => mc2_out,

        mc3_in => mc3_in,
        mc3_out => mc3_out,

        mc4_in => mc4_in,
        mc4_out => mc4_out,

        mc5_in => mc5_in,
        mc5_out => mc5_out,

        mc6_in => mc6_in,
        mc6_out => mc6_out,

        mc7_in => mc7_in,
        mc7_out => mc7_out
    );

mc7_in <= bc_mc1_in when bootcode_load_done = '0' else pbus_mc1_in;

bootcode_loader: entity work.memory_loader
        generic map(
        DATA_FILE => "BOOTCODE.hex"
    )
    port map(
        sys_clk => sys_clk,
        mem_clk => mem_clk,
        reset_n => reset_n,

        load_done => bootcode_load_done,
        mc_in => bc_mc1_in,
        mc_out => mc7_out);

icache_tlb: entity work.read_cache_8x16x256
    port map(
        sys_clk => sys_clk,
        cache_clk => mem_clk,
        addr => pc(31 downto 16),
        meta => icache_tlb_meta,
        data => icache_tlb_data,
        load => icache_tlb_load,
        flush => '0',
        -- flush_strobe =>
        mc_in => mc0_in,
        mc_out => mc0_out,
        sdc_data_out => sdc_data_out,
        page_table_baseaddr => page_table_baseaddr);

icache_addr <= icache_tlb_data(8 downto 0) & pc(15 downto 0); 

icache: entity work.read_cache_16x32x256
    port map(
        sys_clk => sys_clk,
        cache_clk => mem_clk,
        addr => icache_addr,
        meta => icache_meta,
        data => icache_data,
        load => icache_load,
        flush => '0',
        -- flush_strobe =>
        mc_in => mc1_in,
        mc_out => mc1_out,
        sdc_data_out => sdc_data_out);

led <= '0' when icache_data = x"0100006F" else '1';

process(sys_clk)
begin
    if (rising_edge(sys_clk) and bootcode_load_done = '1') then
        case state is 
            when IDLE =>
                if (icache_tlb_meta = (pc(22 downto 16) & "1")) then
                    if (icache_tlb_last_idx = pc(23 downto 16)) then
                        -- TLB HIT
                        if (icache_meta(15 downto 2) = (pc(24 downto 12) & "1")) 
                        then 
                            -- ICACHE HIT
                            state <= DONE;
                        else
                            icache_load <= '1';
                            state <= WAIT_ICACHE_LOAD;
                        end if;
                    else
                        icache_tlb_last_idx <= pc(23 downto 16);
                    end if;
                else
                    icache_tlb_load <= '1';
                    state <= WAIT_ICACHE_TLB_LOAD;
                end if;
            when WAIT_ICACHE_LOAD =>
                icache_load <= '0';
                if (icache_meta(15 downto 2) = (pc(24 downto 12) & "1"))  then
                    state <= IDLE;
                end if;
            when WAIT_ICACHE_TLB_LOAD =>
                icache_tlb_load <= '0';
                icache_tlb_last_idx <= pc(23 downto 16);
                if (icache_tlb_meta = (pc(22 downto 16) & "1")) then
                    state <= IDLE;
                end if;
            when DONE =>
        end case;
    end if;
end process;

end architecture;
