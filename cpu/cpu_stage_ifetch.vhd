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
    iexec_out:          in iexec_channel_out_t;
    debug:              out std_logic
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 
    signal pc_p4:               std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_tlb_addr:     std_logic_vector(15 downto 0) := (others => '1');
    signal icache_tlb_meta:     std_logic_vector(7 downto 0);
    signal icache_tlb_data:     std_logic_vector(15 downto 0);
    signal icache_tlb_start:    std_logic := '0';
    signal icache_tlb_load:     std_logic;
    signal icache_tlb_busy:     std_logic := '0';
    signal icache_tlb_flush:    std_logic := '0';
    signal icache_tlb_flush_strobe: std_logic;
    signal tlb_strobe_save:     std_logic;

    signal icache_translated_addr: std_logic_vector(30 downto 0);
    alias icache_tlb_absent:    std_logic is icache_tlb_data(15);

    signal icache_meta:         std_logic_vector(31 downto 0);
    signal inst:                std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';
    signal icache_busy:         std_logic := '0';
    signal icache_flush:        std_logic := '0';
    signal icache_flush_strobe: std_logic;
    signal cache_strobe_save:    std_logic;

    signal page_table_baseaddr: std_logic_vector(24 downto 0) := (others => '0');
    signal pc_save:             std_logic_vector(31 downto 0);
    signal ivector_baseaddr:    std_logic_vector(23 downto 0) := IVECTOR_RESET_ADDR(31 downto 8);
    signal raise_switch_ack:    std_logic := '0';
    signal raise_intr_ack:      std_logic := '0';
    signal intr_enabled:        std_logic := '0';

    signal valid:               std_logic := '0';
    signal cxfer_valid_save:    std_logic := '0';

    type state_t is (
        RUNNING,
        FLUSH_WAIT,
        CXFER_WAIT,
        TLB_EVICT_WAIT
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

debug <= debug_r;

pc_p4 <= std_logic_vector(unsigned(pc) + 4);
idecode_in.valid <= valid;

process(sys_clk)
begin
    if (rising_edge(sys_clk)) then
        icache_load <= '0';
        icache_tlb_start <= '0';
        icache_flush <= '0';
        icache_tlb_flush <= '0';
        case state is 
            when CXFER_WAIT =>
                if (iexec_out.cxfer_valid /= cxfer_valid_save) then
                    cxfer_valid_save <= not cxfer_valid_save;
                    if (iexec_out.cxfer_taken = '1') then            
                        pc <= iexec_out.switch_pc;
                    end if;
                    state <= RUNNING;
                end if;
            when TLB_EVICT_WAIT =>
                state <= RUNNING;
            when FLUSH_WAIT =>
                if (tlb_strobe_save /= icache_tlb_flush_strobe or
                    cache_strobe_save /= icache_flush_strobe) 
                then
                    state <= RUNNING;
                end if;
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
                            if (idecode_out.busy = '0') then
                                valid <= '0';
                                if (icache_tlb_absent = '1') then
                                    pc <= ivector_baseaddr & TLB_ABSENT;
                                    pc_save <= pc;
                                    -- Invalidate tlb entry anticipating ... 
                                    icache_tlb_start <= '1';
                                    icache_tlb_load <= '0';
                                    state <= TLB_EVICT_WAIT;
                                elsif (raise_switch_ack /= iexec_out.raise_switch) then
                                    -- disable / enable intrs based on flags
                                    raise_switch_ack <= not raise_switch_ack;
                                    pc <= iexec_out.switch_pc;
                                    pc_save <= pc;
                                elsif (intr_enabled = '1' and
                                       raise_intr_ack /= ifetch_in.raise_intr) then
                                    -- disable interrupts
                                    raise_intr_ack <= not raise_intr_ack;
                                    pc <= ivector_baseaddr & ifetch_in.intr_idx;
                                    pc_save <= pc;
                                else
                                    valid <= '1';
                                    idecode_in.inst <= inst;
                                    idecode_in.inst_data <= pc_p4;
                                    -- ?? output insn bit marker (execswitch)
                                    pc <= pc_p4;
                                    case inst(6 downto 2) is
                                        when OP_TYPE_JAL =>
                                            pc <= std_logic_vector(
                                                    signed(pc) + 
                                                    signed(
                                                        inst(31) & inst(19 downto 12) & 
                                                        inst(20) & inst(30 downto 21) & "0"));
                                        when OP_TYPE_JALR =>
                                            state <= CXFER_WAIT;
                                        when OP_TYPE_B =>
                                            state <= CXFER_WAIT;
                                            idecode_in.inst_data <= std_logic_vector(
                                                    signed(pc) + 
                                                    signed(
                                                        inst(31) & inst(7) & 
                                                        inst(30 downto 25) & 
                                                        inst(11 downto 8) & "0"));
                                        when OP_TYPE_CSR =>
                                            if (inst(14 downto 12) = "111" and
                                                inst(31 downto 20) = x"C0D") then
                                                valid <= '0';
                                                tlb_strobe_save <= icache_tlb_flush_strobe;
                                                cache_strobe_save <= icache_flush_strobe;
                                                case inst(16 downto 15) is
                                                    when "00" =>
                                                        -- TLB FLUSH
                                                        icache_tlb_flush <= '1';
                                                        state <= FLUSH_WAIT;
                                                    when "01" => 
                                                        -- FENCE.I ICACHE_FLUSH
                                                        icache_flush <= '1';
                                                        state <= FLUSH_WAIT;
                                                    when "10" =>
                                                        -- ENABLE INTRS
                                                        intr_enabled <= '1';
                                                    when others =>
                                                        -- DISABLE INTRS
                                                        intr_enabled <= '0';
                                                end case;
                                            end if;
                                        when others =>
                                end case;
                              end if;
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
        end case;
    end if;
end process;
end architecture;
