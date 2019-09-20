library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity sdram_controller_test is
port(
        clk_50m:                in std_logic;
        btn:                    in std_logic;
        led:                    out std_logic;
        spi0_sck:               out std_logic;
        spi0_ss:                out std_logic;
        spi0_mosi:              out std_logic;
        spi0_miso:              in std_logic;
        sdram_data:             inout std_logic_vector(15 downto 0);
        sdram_addr:             out std_logic_vector(12 downto 0);
        sdram_ba:               out std_logic_vector(1 downto 0);
        sdram_dqm:              out std_logic_vector(1 downto 0);
        sdram_ras:              out std_logic;
        sdram_cas:              out std_logic;
        sdram_cke:              out std_logic;
        sdram_clk:              out std_logic;
        sdram_we:               out std_logic;
        sdram_cs:               out std_logic);
end entity;

architecture synth of sdram_controller_test is
        signal sys_clk:         std_logic;
        signal mem_clk:         std_logic;
        signal reset_n:         std_logic;
        signal mc_in:           mem_channel_in_t;
        signal mc_out:          mem_channel_out_t;

        type controller_state_t is (
            START,
            DONE);

        signal state:           controller_state_t := START;

begin
        spi0_sck <= '0';
        spi0_ss <= '0';
        spi0_mosi <= '0';

        pll: entity work.pll 
                port map(
                        inclk0 => clk_50m,
                        c0 => sys_clk,
                        c1 => mem_clk,
                        locked => reset_n);

        sdram_controller: entity work.sdram_controller
                port map(
                        sys_clk => sys_clk,
                        mem_clk => mem_clk,
                        mc_in => mc_in,
                        mc_out => mc_out,
                        sdram_data => sdram_data,
                        sdram_addr => sdram_addr,
                        sdram_ba => sdram_ba,
                        sdram_dqm => sdram_dqm,
                        sdram_ras => sdram_ras,
                        sdram_cas => sdram_cas,
                        sdram_cke => sdram_cke,
                        sdram_clk => sdram_clk,
                        sdram_we => sdram_we,
                        sdram_cs => sdram_cs);

        process(sys_clk)
        begin
            if (rising_edge(sys_clk)) then
                case state is
                    when START =>
                        mc_in.op_addr <= "000000000000000000000000";
                        mc_in.op_start <= '1';
                        mc_in.op_wren <= '1';
                        mc_in.write_data <= "0000000000000001";
                        mc_in.write_dqm <= "00";
                    when DONE =>
                end case;
            end if;
        end process;
end architecture;


