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
    ifetch_in:          in ifetch_channel_in_t;
    idecode_in:         out idecode_channel_in_t;
    idecode_out:        in idecode_channel_out_t
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
    signal async_cxfer_strobe_save: std_logic;

    type state_t is (
        RUNNING,
        JAL_SWITCH,
        FLUSH_WAIT,
        CXFER_WAIT,
        CSR_UPDATE);
    
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
                if (ifetch_in.sync_cxfer = '1') then
                    if (ifetch_in.cxfer_branch = '1') then
                        if (ifetch_in.cxfer_branch_taken = '1') then
                            pc <= std_logic_vector(
                                    signed(idecode_in.pc) + 
                                    signed(idecode_in.inst(31) & inst(7) & 
                                            idecode_in.inst(30 downto 25) & 
                                            idecode_in.inst(11 downto 8) & "0"));
                        end if;
                    else
                        -- XXX Provide mechnism for setting intr_enable
                        pc <= ifetch_in.cxfer_pc;
                    end if;
                    state <= RUNNING;
                end if;
            when CSR_UPDATE =>
                cache_strobe_save <= icache_flush_strobe;
                if (idecode_in.inst(15) = '0') then
                    -- FENCE.I ICACHE_FLUSH
                    icache_flush <= '1';
                    state <= FLUSH_WAIT;
                end if;
            when RUNNING =>
                if (ifetch_in.async_cxfer_strobe /= async_cxfer_strobe_save) then
                    async_cxfer_strobe_save <= not async_cxfer_strobe_save;
                    pc <= ifetch_in.cxfer_pc;
                elsif (icache_meta(19 downto 0) = (pc(30 downto 12) & "1")) 
                then 
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
                            when OP_TYPE_CSR =>
                                if (inst(31 downto 20) = x"C0D") then
                                    valid <= '0';
                                    state <= CSR_UPDATE;
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
