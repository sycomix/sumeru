library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity memory_loader is
generic(
        DATA_FILE:              string);
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        reset_n:                in std_logic;
        load_done:              out std_logic;
        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t
    );
end entity;

architecture synth of memory_loader is
    signal counter:             std_logic_vector(9 downto 0) := (others => '0');
    signal rom_data:            std_logic_vector(15 downto 0);
    signal op_start:            std_logic := '0';

    type loader_state_t is (
        IDLE,
        WAIT_STROBE,
        DONE);

    signal state:               loader_state_t := IDLE;


begin
    load_done <= counter(9);
    mc_in.op_addr <= "000000000000000" & counter(8 downto 0);
    mc_in.op_start <= op_start;
    mc_in.op_wren <= '1';
    mc_in.op_burst <= '0';
    mc_in.op_dqm <= "00";
    mc_in.write_data <= rom_data;

    rom: entity work.alt_rom
        generic map(
            AWIDTH => 9,
            DWIDTH => 16,
            DATA_FILE => DATA_FILE)
        port map(
            clock => sys_clk,
            address => counter(8 downto 0),
            q => rom_data);

    process(sys_clk)
    begin
        if (rising_edge(sys_clk) and reset_n = '1') then
            case state is
                when IDLE =>
                    if (load_done = '1') then
                        state <= DONE;
                    else
                        op_start <= not op_start;
                        state <= WAIT_STROBE;
                    end if;
                when WAIT_STROBE =>
                    if (op_start = mc_out.op_strobe) then
                        counter <= std_logic_vector(unsigned(counter) + 1);
                    end if;
                when DONE =>
            end case;
        end if;
    end process;

end architecture;


