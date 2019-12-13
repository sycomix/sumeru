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
    cache_mc_in:        out mem_channel_in_t;
    cache_mc_out:       in mem_channel_out_t;
    sdc_data_out:       in std_logic_vector(15 downto 0);
    idecode_in:         out idecode_channel_in_t;
    idecode_out:        in idecode_channel_out_t;
    iexec_out:          in iexec_channel_out_fetch_t
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 

    signal icache_meta:         std_logic_vector(31 downto 0);
    signal inst:                std_logic_vector(31 downto 0);
    signal icache_load:         std_logic := '0';
    signal icache_busy:         std_logic := '0';
    signal icache_flush:        std_logic := '0';
    signal icache_flush_strobe: std_logic;

    signal valid:               std_logic := '0';
    signal cache_strobe_save:   std_logic;
    signal cxfer_strobe_save:   std_logic;

    type state_t is (
        RUNNING,
        JAL_SWITCH,
        FLUSH_WAIT,
        CXFER_WAIT);
    
    signal state:               state_t := RUNNING;

begin
icache: entity work.read_cache_32x32x256
    port map(
        sys_clk => sys_clk,
        cache_clk => cache_clk,
        addr => pc(30 downto 0),
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
        icache_flush <= '0';

        if (idecode_out.busy = '0') then
            valid <= '0';
        end if;

        case state is 
            when JAL_SWITCH =>
                pc <= std_logic_vector(
                        signed(idecode_in.pc) + 
                        signed(idecode_in.inst(31) & idecode_in.inst(19 downto 12) & 
                               idecode_in.inst(20) & idecode_in.inst(30 downto 21) & "0"));
                state <= RUNNING;
            when FLUSH_WAIT =>
                if (cache_strobe_save /= icache_flush_strobe) 
                then
                    state <= RUNNING;
                end if;
            when CXFER_WAIT =>
                -- CXFER_WAIT is required to stop fetches when a JALR or
                --  BRANCH instr is encountered. In another strategy we
                --  could avoid using cxfer_sync / CXFER_WAIT
                --  and rely solely on cxfer_async. In that case fetch 
                --  would continue to prefetch instructions
                --  on the branch not taken path -- akin to a crude static
                --  branch predictor.
                if (iexec_out.cxfer_sync = '1') then
                    pc <= iexec_out.cxfer_pc;
                    -- XXX Provide mechnism for setting intr_enable
                    state <= RUNNING;
                end if;
            when RUNNING =>
                if (iexec_out.cxfer_async_strobe /= cxfer_strobe_save) then
                    cxfer_strobe_save <= not cxfer_strobe_save;
                    pc <= iexec_out.cxfer_pc;
                elsif (icache_meta(19 downto 0) = (pc(30 downto 12) & "1")) then 
                    -- ICACHE HIT
                    icache_busy <= '0';
                    if (idecode_out.busy = '0') then
                        valid <= '1';
                        idecode_in.inst <= inst;
                        idecode_in.pc <= pc;
                        pc <= std_logic_vector(unsigned(pc) + 4);
                        case inst(6 downto 2) is
                            when OP_TYPE_JAL =>
                                state <= JAL_SWITCH;
                            when OP_TYPE_B | OP_TYPE_JALR =>
                                state <= CXFER_WAIT;
                            when OP_TYPE_MISC_MEM =>
                                if (inst(12) = '1') then
                                    -- FENCE.I
                                    valid <= '0';
                                    icache_flush <= '1';                                    
                                    state <= FLUSH_WAIT;
                                    cache_strobe_save <= icache_flush_strobe;
                                end if;
                            when others =>
                        end case;
                    end if;
                else
                    -- LOAD CACHE LINE
                    if (icache_busy = '0' and enable = '1') then
                        icache_load <= '1';
                        icache_busy <= '1';
                    end if;
                end if;
        end case;
    end if;
end process;
end architecture;
