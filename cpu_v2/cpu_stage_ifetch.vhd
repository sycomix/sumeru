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
    cache_mc_in:        out mem_channel_in_t;
    cache_mc_out:       in mem_channel_out_t;
    sdc_data_out:       in std_logic_vector(15 downto 0);
    ifetch_in:          in ifetch_channel_in_t;
    ifetch_out:         out ifetch_channel_out_t
    );
end entity;

architecture synth of cpu_stage_ifetch is
    signal pc:                  std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET; 
    signal icache_meta:         std_logic_vector(15 downto 0);
    signal inst:                std_logic_vector(31 downto 0);

    signal valid_r:             std_logic := '0';

begin
icache: entity work.read_cache_256x4x32
    port map(
        clk => clk,
        addr => pc(24 downto 0),
        meta => icache_meta,
        data => inst,
        load => ifetch_in.cache_load,
        load_ack => ifetch_out.cache_load_ack,
        flush => ifetch_in.cache_flush,
        flush_ack => ifetch_out.cache_flush_ack,
        mc_in => cache_mc_in,
        mc_out => cache_mc_out,
        sdc_data_out => sdc_data_out);

process(clk_n)
begin
    if (rising_edge(clk_n)) then
        if (icache_meta(13 downto 0) = (pc(24 downto 12) & "1")) 
        then 
            if (ifetch_in.switch = '1') then
                pc <= ifetch_in.switch_pc;
                ifetch_out.inst_valid <= '0';
            else
                pc <= std_logic_vector(unsigned(pc) + 4);
                ifetch_out.inst_valid <= '1';
                ifetch_out.inst <= inst;
                ifetch_out.pc <= pc;
            end if;
        else
            ifetch_out.inst_valid <= '0';
        end if;
    end if;
end process;

end architecture;
