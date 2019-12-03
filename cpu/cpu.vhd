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
    signal pll_locked:          std_logic;
    signal reset_n:             std_logic;

    signal sdc_in:              mem_channel_in_t;
    signal sdc_out:             mem_channel_out_t;
    signal sdc_data_out:        std_logic_vector(15 downto 0);
    signal sdc_busy:            std_logic;

    signal mc0_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc1_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc2_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc3_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc4_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc5_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc6_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal mc7_in:              mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));

    signal mc0_out:             mem_channel_out_t;
    signal mc1_out:             mem_channel_out_t;
    signal mc2_out:             mem_channel_out_t;
    signal mc3_out:             mem_channel_out_t;
    signal mc4_out:             mem_channel_out_t;
    signal mc5_out:             mem_channel_out_t;
    signal mc6_out:             mem_channel_out_t;
    signal mc7_out:             mem_channel_out_t;

    signal bc_mc_in:            mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));
    signal pbus_mc_in:          mem_channel_in_t := ((others => '0'), '0', '0', '0', (others => '0'), (others => '0'));

    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_tlb_meta:     std_logic_vector(7 downto 0);
    signal icache_tlb_data:     std_logic_vector(15 downto 0);
    signal icache_tlb_last:     std_logic_vector(14 downto 0) := (others => '1');
    signal icache_tlb_load:     std_logic := '0';
    signal icache_tlb_busy:     std_logic := '0';

    signal icache_translated_addr: std_logic_vector(30 downto 0);
    alias icache_tlb_present:   std_logic is icache_tlb_data(15);

    signal icache_meta:         std_logic_vector(31 downto 0);
    signal icache_data:         std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';
    signal icache_busy:         std_logic := '0';

    signal page_table_baseaddr: std_logic_vector(24 downto 0) := (others => '0');

    signal idecode_fifo_empty:  std_logic;
    signal idecode_fifo_full:   std_logic;
    signal idecode_fifo_aclr:   std_logic;
    signal idecode_fifo_rden:   std_logic;
    signal idecode_fifo_wren:   std_logic;
    signal idecode_fifo_write_data: std_logic_vector(31 downto 0);
    signal idecode_fifo_read_data: std_logic_vector(31 downto 0);

    type state_t is (
        START,
        RUNNING
    );
        
    signal state:               state_t := START;

begin
spi0_sck <= '0';
spi0_ss <= '0';
spi0_mosi <= '0';

pll: entity work.pll 
    port map(
        inclk0 => clk_50m,
        c0 => sys_clk,
        c1 => mem_clk,
        locked => pll_locked);

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

mc7_in <= bc_mc_in when reset_n = '0' else pbus_mc_in;

bootcode_loader: entity work.memory_loader
        generic map(
        DATA_FILE => "BOOTCODE.hex"
    )
    port map(
        sys_clk => sys_clk,
        mem_clk => mem_clk,
        reset_n => pll_locked,

        load_done => reset_n,
        mc_in => bc_mc_in,
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

-- Bit 31 of page address is reserved as 'present' bit
icache_translated_addr <= icache_tlb_data(14 downto 0) & pc(15 downto 0); 

icache: entity work.read_cache_16x32x256
    port map(
        sys_clk => sys_clk,
        cache_clk => mem_clk,
        addr => icache_translated_addr,
        meta => icache_meta,
        data => icache_data,
        load => icache_load,
        flush => '0',
        -- flush_strobe =>
        mc_in => mc1_in,
        mc_out => mc1_out,
        sdc_data_out => sdc_data_out);

idecode_fifo: entity work.idecode_fifo
    port map(
        clock => sys_clk,
        empty => idecode_fifo_empty,
        full => idecode_fifo_full,
        aclr => idecode_fifo_aclr,
        rdreq => idecode_fifo_rden,
        wrreq => idecode_fifo_wren,
        data => idecode_fifo_write_data,
        q => idecode_fifo_read_data);

idecode: entity work.cpu_stage_idecode
    port map(
        sys_clk => sys_clk,
        fifo_empty => idecode_fifo_empty,
        fifo_rden => idecode_fifo_rden,
        fifo_read_data => idecode_fifo_read_data
        );

led <= '0' when icache_data = x"00000013" else '1';

process(sys_clk)
begin
    if (rising_edge(sys_clk)) then
        icache_load <= '0';
        icache_tlb_load <= '0';
        idecode_fifo_wren <= '0';
        case state is 
            when START =>
                if (reset_n = '1') then
                    state <= RUNNING;
                end if;
            when RUNNING =>
                if (icache_tlb_meta = (pc(22 downto 16) & "1")) then
                    -- it takes one cycle delay to switch tlb entries
                    -- hence this check and delay
                    if (icache_tlb_last = pc(30 downto 16)) then
                        -- TLB HIT
                        icache_tlb_busy <= '0';
                        if (icache_meta(31 downto 12) = (pc(30 downto 12) & "1")) 
                        then 
                            -- ICACHE HIT
                            icache_busy <= '0';
                            if (idecode_fifo_full /= '1') then
                                idecode_fifo_wren <= '1';
                                idecode_fifo_write_data <= icache_data;
                                pc <= pc(31 downto 4) & std_logic_vector(unsigned(pc(3 downto 0)) + 4);
                            end if;
                        else
                            -- LOAD CACHE LINE
                            if (icache_busy = '0') then
                                icache_load <= '1';
                                icache_busy <= '1';
                            end if;
                        end if;
                    -- else
                        -- if (icache_tlb_present = '0') then
                            -- RAISE PAGE NOT PRESENT EXCEPTION
                        -- end if;
                    end if;
                    icache_tlb_last <= pc(30 downto 16);
                else
                    -- LOAD TLB ENTRY
                    if (icache_tlb_busy = '0') then
                        icache_tlb_load <= '1';
                        icache_tlb_busy <= '1';
                    end if;
                end if;
        end case;
    end if;
end process;

end architecture;
