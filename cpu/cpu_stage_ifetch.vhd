library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu_stage_ifetch is
port(
    sys_clk:            in std_logic;
    cache_clk:          in std_logic;
    enable:             in std_logic;
    tlb_mc_in:          out mem_channel_in_t;
    tlb_mc_out:         in mem_channel_out_t;
    cache_mc_in:        out mem_channel_in_t;
    cache_mc_out:       in mem_channel_out_t;
    sdc_data_out:       in std_logic_vector(15 downto 0);
    ifetch_in:          in ifetch_channel_in_t;
    idecode_in:         out idecode_channel_in_t;
    idecode_out:        in idecode_channel_out_t;
    iexec_out:          in iexec_channel_out_t
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_tlb_addr:     std_logic_vector(15 downto 0) := (others => '1');
    signal icache_tlb_meta:     std_logic_vector(7 downto 0);
    signal icache_tlb_data:     std_logic_vector(15 downto 0);
    signal icache_tlb_start:    std_logic := '0';
    signal icache_tlb_load:     std_logic;
    signal icache_tlb_busy:     std_logic := '0';
    signal icache_tlb_flush:    std_logic := '0';
    signal icache_tlb_flush_strobe: std_logic;

    signal icache_translated_addr: std_logic_vector(30 downto 0);
    alias icache_tlb_absent:    std_logic is icache_tlb_data(15);

    signal icache_meta:         std_logic_vector(31 downto 0);
    signal inst:                std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';
    signal icache_busy:         std_logic := '0';
    signal icache_flush:        std_logic := '0';
    signal icache_flush_strobe: std_logic;

    signal page_table_baseaddr: std_logic_vector(24 downto 0) := (others => '0');
    signal pc_save:             std_logic_vector(31 downto 0);

    signal valid:               std_logic := '0';

begin
icache_tlb: entity work.read_cache_8x16x256
    port map(
        sys_clk => sys_clk,
        cache_clk => cache_clk,
        addr => icache_tlb_addr,
        meta => icache_tlb_meta,
        data => icache_tlb_data,
        start => icache_tlb_start,
        load => icache_tlb_load,
        flush => icache_tlb_flush,
        flush_strobe => icache_tlb_flush_strobe,
        mc_in => tlb_mc_in,
        mc_out => tlb_mc_out,
        sdc_data_out => sdc_data_out,
        page_table_baseaddr => page_table_baseaddr);

-- Bit 31 of page address is reserved as 'absent' bit
icache_translated_addr <= icache_tlb_data(14 downto 0) & pc(15 downto 0); 

icache: entity work.read_cache_32x32x256
    port map(
        sys_clk => sys_clk,
        cache_clk => cache_clk,
        addr => icache_translated_addr,
        meta => icache_meta,
        data => inst,
        load => icache_load,
        flush => icache_flush,
        flush_strobe => icache_flush_strobe,
        mc_in => cache_mc_in,
        mc_out => cache_mc_out,
        sdc_data_out => sdc_data_out);

idecode_in.valid <= valid;

process(sys_clk)
begin
    if (rising_edge(sys_clk)) then
        icache_load <= '0';
        icache_tlb_start <= '0';
        icache_flush <= '0';
        icache_tlb_flush <= '0';

        if (idecode_out.busy = '0') then
            valid <= '0';
        end if;

        -- it takes one cycle delay to switch tlb entries
        -- hence this check and delay
        if (icache_tlb_addr =  pc(31 downto 16)) then
            if (icache_tlb_meta = (pc(30 downto 24) & "1")) then
                -- TLB HIT
                icache_tlb_busy <= '0';
                if (icache_meta(19 downto 0) = (icache_translated_addr(30 downto 12) & "1")) 
                then 
                    -- ICACHE HIT
                    icache_busy <= '0';
                    if (idecode_out.busy = '0') then
                        valid <= '1';
                        idecode_in.inst <= inst;
                        idecode_in.pc <= pc;
                        pc <= std_logic_vector(unsigned(pc) + 4);
                    end if;
                else
                    -- LOAD CACHE LINE
                    if (icache_busy = '0') then
                        icache_load <= '1';
                        icache_busy <= '1';
                    end if;
                end if;
            else
                -- LOAD TLB ENTRY
                if (icache_tlb_busy = '0' and enable = '1') then
                    icache_tlb_start <= '1';
                    icache_tlb_load <= '1';
                    icache_tlb_busy <= '1';
                end if;
            end if;
        end if;
        icache_tlb_addr <= pc(31 downto 16);
    end if;
end process;
end architecture;
