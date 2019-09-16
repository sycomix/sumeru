library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

--
-- 8192 rows x 512 columns x 16 bits
-- addr(23 downto 11) row, addr(10 downto 9) bank, addr(8 downto 0) col
--

entity sdram_controller is
    generic(
        -- One refresh command every 7.813us (or 7813 ns)
        -- (7812.5 / SYS_CLK_PERIOD_NS) - 7.0;
        REFRESH_CYCLES:         natural := 1035;
        TRFC_CYCLES:            std_logic_vector(2 downto 0) := "111";
        TRP_CYCLES:             std_logic_vector(2 downto 0) := "010";
        TRCD_CYCLES:            std_logic_vector(2 downto 0) := "010";
        CAS_CYCLES:             std_logic_vector(2 downto 0) := "001";

        STARTUP_CYCLE_BITNR:    natural := 14
    );
    port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        mc_in:                  in mem_channel_in_t;
        mc_out:                 out mem_channel_out_t;

        sdram_data:             inout std_logic_vector(15 downto 0);
        sdram_addr:             out std_logic_vector(12 downto 0);
        sdram_ba:               out std_logic_vector(1 downto 0);
        sdram_dqm:              out std_logic_vector(1 downto 0);
        sdram_ras:              out std_logic;
        sdram_cas:              out std_logic;
        sdram_cke:              out std_logic;
        sdram_clk:              out std_logic;
        sdram_we:               out std_logic;
        sdram_cs:               out std_logic
    );
end entity;

architecture synth of sdram_controller is
    constant LMR_SETTING:       std_logic_vector(12 downto 0) :="0010000100011";

    constant CMD_INHIBIT:       std_logic_vector(3 downto 0) := "1111";
    constant CMD_NOP:           std_logic_vector(3 downto 0) := "0111";
    constant CMD_PRECHARGE:     std_logic_vector(3 downto 0) := "0010";
    constant CMD_LMR:           std_logic_vector(3 downto 0) := "0000";
    constant CMD_REFRESH:       std_logic_vector(3 downto 0) := "0001";
    constant CMD_ACTIVE:        std_logic_vector(3 downto 0) := "0011";
    constant CMD_WRITE:         std_logic_vector(3 downto 0) := "0100";
    constant CMD_READ:          std_logic_vector(3 downto 0) := "0101";
    constant CMD_BURST_TERMINATE: std_logic_vector(3 downto 0) := "0110";

    alias op_addr_row: std_logic_vector(12 downto 0) is mc_in.op_addr(23 downto 11);
    --
    -- XXX : decide where bank bits should be placed???
    --
    alias op_addr_bank: std_logic_vector(1 downto 0) is mc_in.op_addr(10 downto 9);
    alias op_addr_col: std_logic_vector(8 downto 0) is mc_in.op_addr(8 downto 0);


    type controller_state_t is (
        STARTUP,
        IDLE
    );

    signal state:       controller_state_t := STARTUP;
    signal command:     std_logic_vector(3 downto 0) := CMD_INHIBIT;
    signal cke:         std_logic := '0';
    signal addr:        std_logic_vector(12 downto 0) := LMR_SETTING;                                
    signal ba:          std_logic_vector(1 downto 0) := (others => '0');
    signal dqm:         std_logic_vector(1 downto 0) := (others => '1');
    signal busy_wait:   std_logic_vector(3 downto 0) := (others => '0');

    signal cycle_counter:       std_logic_vector(STARTUP_CYCLE_BITNR downto 0) := 
                                                            (others => '0');

    type bank_state_t is record
        active:         std_logic;
        row:            std_logic_vector(12 downto 0);
    end record;

    type bank_states_t is array(0 to 3) of bank_state_t;

    signal bank_states: bank_states_t;
    signal cur_bank_active: std_logic;
    signal cur_bank_row: std_logic_vector(12 downto 0);

begin
    sdram_clk <= mem_clk;
    sdram_cke <= cke;
    sdram_addr <= addr;
    sdram_ba <= ba;
    sdram_dqm <= dqm;

    sdram_cs <= command(3);
    sdram_ras <= command(2);
    sdram_cas <= command(1);
    sdram_we <= command(0);

    sdram_data <= (others => 'Z');

    cur_bank_active <= bank_states(to_integer(unsigned(op_addr_bank))).active;
    cur_bank_row <= bank_states(to_integer(unsigned(op_addr_bank))).row;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            cycle_counter <= std_logic_vector(unsigned(cycle_counter) + 1);
            case state is
                when STARTUP =>
                    if (cycle_counter(STARTUP_CYCLE_BITNR) = '1') then
                        cke <= '1';
                        command <= CMD_NOP;
                        if (cycle_counter(2 downto 0) = "001") then
                            command <= CMD_PRECHARGE;
                        elsif (cycle_counter(2 downto 0) = "101") then
                            command <= CMD_LMR;
                        elsif (cycle_counter(2 downto 0) = "111") then
                            state <= IDLE;
                            mc_out.op_strobe <= '0';
                        end if;
                    end if;
                when IDLE =>
                    command <= CMD_NOP;
                    if (busy_wait = "0000") then
                        if (unsigned(cycle_counter) > REFRESH_CYCLES) then
                            busy_wait <= "0" & TRFC_CYCLES;
                            cycle_counter <= 
                                std_logic_vector(unsigned(cycle_counter) - 
                                                                REFRESH_CYCLES);
                            command <= CMD_REFRESH;
                        else
                            if (mc_in.op_start /= mc_out.op_strobe) then
                                if (cur_bank_active = '0') then
                                    -- Activate row
                                    command <= CMD_ACTIVE;
                                    bank_states(
                                        to_integer(
                                            unsigned(op_addr_bank))).row <= 
                                                op_addr_row;
                                    bank_states(
                                        to_integer(
                                            unsigned(op_addr_bank))).active <= '1';
                                    addr <= op_addr_row; 
                                    ba <= op_addr_bank;
                                    busy_wait <= "0" & TRCD_CYCLES;
                                else
                                    if (cur_bank_row /= op_addr_row) then
                                        -- Precharge row
                                        command <= CMD_PRECHARGE;
                                        addr(10) <= '0';
                                        ba <= op_addr_bank;
                                        busy_wait <= "0" & TRP_CYCLES;
                                        bank_states(
                                            to_integer(
                                                unsigned(op_addr_bank))).active <= '0';
                                    else
                                        if (mc_in.op_wren = '1') then
                                            -- Write Operation
                                        else
                                            -- Read Operation
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    else
                        busy_wait <= std_logic_vector(unsigned(busy_wait) - 1);
                    end if;
            end case;
        end if;
    end process;
end architecture;


