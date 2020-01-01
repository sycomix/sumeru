library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu_stage_ifetch is
port(
    clk:                in std_logic;
    clk_n:              in std_logic;
    enable:             in std_logic;
    idecode_in:         out idecode_channel_in_t;
    idecode_out:        in idecode_channel_out_t;
    icache_mc_in:       out mem_channel_in_t;
    icache_mc_out:      in mem_channel_out_t;
    sdc_data_out:       in std_logic_vector(15 downto 0);
    clk_cycle:          out std_logic
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal icache_hit:          std_logic;
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR & IVECTOR_ENTRY_BOOT & "0000"; 
    signal inst:                std_logic_vector(31 downto 0);
    signal icache_flush:        std_logic := '0';
    signal icache_flush_ack:    std_logic;
    signal jmp_pc:              std_logic_vector(31 downto 0);
    signal pc_p4:               std_logic_vector(31 downto 0);
    signal cxfer_pending:       std_logic := '0';
    signal clk_cycle_r:         std_logic := '0';

begin
    clk_cycle <= clk_cycle_r;

icache: entity work.read_cache_256x4x32
    port map(
        clk => clk,
        clk_n => clk_n,
        enable => enable,
        addr => pc(24 downto 0),
        hit => icache_hit,
        data => inst,
        flush => icache_flush,
        flush_ack => icache_flush_ack,
        mc_in => icache_mc_in,
        mc_out => icache_mc_out,
        sdc_data_out => sdc_data_out);

jmp_pc <= std_logic_vector(signed(pc) +
                        signed(inst(31) & inst(19 downto 12) & 
                               inst(20) & inst(30 downto 21) & 
                               "0"));

pc_p4 <= std_logic_vector(unsigned(pc) + 4);

process(clk)
begin
    if (rising_edge(clk)) then
            if (icache_flush_ack /= icache_flush) then
                idecode_in.valid <= '0';
                if (idecode_out.cxfer = '1') then
                    cxfer_pending <= '1';
                end if;
            elsif ((idecode_out.cxfer = '1' or cxfer_pending = '1') and icache_hit = '1') then
                -- We can only do cxfer when hit=1 because we don't want
                -- to change the pc while a cache line is loading
                cxfer_pending <= '0';
                pc <= idecode_out.cxfer_pc;
                idecode_in.valid <= '0';
            elsif (idecode_out.busy = '0' and icache_hit = '1') then
                clk_cycle_r <= not clk_cycle_r;
                pc <= pc_p4;
                idecode_in.valid <= '1';
                idecode_in.inst <= inst;
                idecode_in.pc <= pc;
                case inst(6 downto 2) is
                    when OP_TYPE_JAL =>
                        pc <= jmp_pc;
                    when OP_TYPE_MISC_MEM =>
                        if (inst(12) = '1') then
                            -- FENCE.I
                            -- XXX Understand and Imporve
                            idecode_in.valid <= '0';
                            icache_flush <= not icache_flush;
                        end if;
                    when others =>
                end case;
            else
                if (idecode_out.busy = '0' or idecode_out.cxfer = '1') then
                    idecode_in.valid <= '0';
                end if;
                if (idecode_out.cxfer = '1') then
                    cxfer_pending <= '1';
                end if;
            end if;
    end if;
end process;

end architecture;
