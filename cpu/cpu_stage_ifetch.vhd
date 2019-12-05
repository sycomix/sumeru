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
    debug:              out std_logic
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_tlb_addr:     std_logic_vector(15 downto 0) := (others => '1');
    signal icache_tlb_meta:     std_logic_vector(7 downto 0);
    signal icache_tlb_data:     std_logic_vector(15 downto 0);
    signal icache_tlb_load:     std_logic := '0';
    signal icache_tlb_busy:     std_logic := '0';

    signal icache_translated_addr: std_logic_vector(30 downto 0);
    alias icache_tlb_absent:    std_logic is icache_tlb_data(15);

    signal icache_meta:         std_logic_vector(31 downto 0);
    signal inst:                std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';
    signal icache_busy:         std_logic := '0';

    signal page_table_baseaddr: std_logic_vector(24 downto 0) := (others => '0');
    signal pc_save:             std_logic_vector(31 downto 0);
    signal ivector_baseaddr:    std_logic_vector(23 downto 0) := IVECTOR_RESET_ADDR(31 downto 8);
    signal switch_pc_ack:       std_logic := '0';
    signal raise_intr_ack:      std_logic := '0';

    type state_t is (
        RUNNING
        );

    signal state:               state_t := RUNNING;
    signal debug_r:             std_logic := '1';

begin
icache_tlb: entity work.read_cache_8x16x256
    port map(
        sys_clk => sys_clk,
        cache_clk => cache_clk,
        addr => icache_tlb_addr,
        meta => icache_tlb_meta,
        data => icache_tlb_data,
        load => icache_tlb_load,
        flush => '0',
        -- flush_strobe =>
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
        flush => '0',
        -- flush_strobe =>
        mc_in => cache_mc_in,
        mc_out => cache_mc_out,
        sdc_data_out => sdc_data_out);

debug <= debug_r;

process(sys_clk)
begin
    if (rising_edge(sys_clk)) then
        icache_load <= '0';
        icache_tlb_load <= '0';
        case state is 
            when RUNNING =>
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
                            if (icache_tlb_absent = '1') then
                                pc_save <= pc;
                                pc <= ivector_baseaddr & TLB_ABSENT;
                            elsif (switch_pc_ack /= ifetch_in.switch_pc) then
                                -- disable / enable intrs based on flags
                                switch_pc_ack <= ifetch_in.switch_pc;
                                -- pc <= ifetch_in.switch_pc;
                                pc_save <= pc;
                            elsif (raise_intr_ack /= ifetch_in.raise_intr) then
                                -- disable interrupts
                                raise_intr_ack <= ifetch_in.raise_intr;
                                pc <= ivector_baseaddr & ifetch_in.intr_idx;
                            else
                                pc <= std_logic_vector(unsigned(pc) + 4);
                            end if;

--                                case inst(6 downto 2) is
--                                    when OP_TYPE_JAL =>
--                                    when OP_TYPE_JALR =>
--                                    when OP_TYPE_B =>
--                                    when OP_TYPE_CSR =>
--                                        TLB FLUSH
--                                        FENCE.I
--                                        ENABLE INTRS
--                                        DISABLE INTRS
--
--                          case
--                          (JAL)
--                          (JALR)
--                          (BRANCH)
--                          (EXCEPTION)
--                          (INTERRUPT)
--                          (FENCE.I)
--                          (TLB FLUSH)
--                          end
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
                            icache_tlb_load <= '1';
                            icache_tlb_busy <= '1';
                        end if;
                    end if;
                end if;
                icache_tlb_addr <= pc(31 downto 16);
        end case;
    end if;
end process;
end architecture;
