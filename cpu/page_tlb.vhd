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
        addr:                   in std_logic_vector(15 downto 0);
        hit:                    out std_logic;
        data:                   out std_logic_vector(15 downto 0);

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0)
    );
end entity;

architecture synth of page_tlb is
    signal meta:                std_logic_vector(15 downto 0);
    signal meta_wren:           std_logic := '0';
    alias meta_line_valid:      std_logic is meta(7);

    signal data0:               std_logic_vector(15 downto 0);
    signal data0_wren:          std_logic := '0';

    signal op_start:            std_logic := '0';

    type cache_state_t is (
        IDLE,
        WAIT_B1
    );

    signal state:               cache_state_t := IDLE;

    signal meta_data:           std_logic_vector(15 downto 0);
    signal meta_data_line_valid: std_logic;

    signal write_data:          std_logic_vector(31 downto 0);

begin
    meta_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => meta_data,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.ram1p_256x16
        port map(
            clock => cache_clk,
            address => addr(7 downto 0),
            data => sdc_data_out,
            wren => data0_wren,
            q => data);

    hit <= '1' when meta(15 downto 7) = (addr(15 downto 8) & "1") else '0';
    meta_data <= addr(15 downto 8) & meta_data_line_valid & "0000000";
 
    mc_in.op_start <= op_start;
    mc_in.op_addr <= 
            std_logic_vector(
                unsigned(page_table_baseaddr(24 downto 1)) + 
                unsigned("00000000" & addr));
    mc_in.op_wren <= '0';
    mc_in.op_dqm <= "00";
    mc_in.op_burst <= '0';
    
    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            meta_wren <= '0';
            meta_data_line_valid <= '1';
            
            case state is
                when IDLE =>
                    if (hit = '0' and enable = '1') then
                        op_start <= not op_start;
                        state <= WAIT_B1;
                    end if;
                when WAIT_B1 =>
                    if (mc_out.op_strobe = op_start) then
                        state <= IDLE;
                        data0_wren <= '1';
                        meta_wren <= '1';
                    end if;
            end case;
        end if;
    end process;

end architecture;


