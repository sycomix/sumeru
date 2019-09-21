library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

--
-- 4 banks x 8192 rows x 512 columns x 16 bits
-- addr(23 downto 11) row, addr(10 downto 9) bank, addr(8 downto 0) col
--

entity sdram_controller is
    generic(
        -- One refresh command every 7.813us (or 7813 ns)
        -- (7812.5 / SYS_CLK_PERIOD_NS) - 7.0;
        REFRESH_CYCLES:         natural := 1035;
        TRFC_CYCLES:            std_logic_vector(3 downto 0) := "1000";
        TRP_CYCLES:             std_logic_vector(3 downto 0) := "0010";
        TRCD_CYCLES:            std_logic_vector(3 downto 0) := "0010";
        CAS_CYCLES:             std_logic_vector(3 downto 0) := "0001";

        STARTUP_CYCLE_BITNR:    natural := 14
    );
    port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        reset_n:                in std_logic;
        mc_in:                  in mem_channel_in_t;
        mc_out:                 out mem_channel_out_t := (op_strobe => '0');
        data_out:               out std_logic_vector(15 downto 0);

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
        IDLE,
        WRITE
    );

    signal state:       controller_state_t := STARTUP;
    signal command:     std_logic_vector(3 downto 0) := CMD_INHIBIT;
    signal cke:         std_logic := '0';
    signal addr:        std_logic_vector(12 downto 0) := LMR_SETTING;                                
    signal dqm:         std_logic_vector(1 downto 0) := (others => '1');

    signal busy_wait_counter:   std_logic_vector(3 downto 0) := (others => '0');
    signal dqm_on_counter:      std_logic_vector(3 downto 0) := (others => '0');

    signal cycle_counter:       std_logic_vector(STARTUP_CYCLE_BITNR downto 0) := 
                                                            (others => '0');

    signal refresh_lock:        std_logic := '0';

    type bank_state_t is record
        active:         std_logic;
        row:            std_logic_vector(12 downto 0);
    end record;

    type bank_states_t is array(0 to 3) of bank_state_t;

    signal bank_states: bank_states_t := (
                                            ('0', (others =>'0')),
                                            ('0', (others =>'0')),
                                            ('0', (others =>'0')),
                                            ('0', (others =>'0')));

    signal cur_bank_active: std_logic;
    signal cur_bank_row: std_logic_vector(12 downto 0);

    signal busy_wait:   std_logic;
    signal dqm_on:      std_logic;

    signal strobe_r1:   std_logic := '0';
    signal strobe_r2:   std_logic := '0';

begin
    sdram_clk <= mem_clk;
    sdram_cke <= cke;
    sdram_addr <= addr;
    sdram_ba <= op_addr_bank;

    sdram_cs <= command(3);
    sdram_ras <= command(2);
    sdram_cas <= command(1);
    sdram_we <= command(0);

    sdram_data <= mc_in.write_data when
                    (dqm_on = '1' and mc_in.op_wren = '1')
                    else (others => 'Z');

    sdram_dqm <= mc_in.op_dqm when dqm_on else "11";

    busy_wait <= 
        busy_wait_counter(0) or busy_wait_counter(1) or
        busy_wait_counter(2) or busy_wait_counter(3);

    dqm_on <= 
        dqm_on_counter(0) or dqm_on_counter(1) or
        dqm_on_counter(2) or dqm_on_counter(3);

    cur_bank_active <= bank_states(to_integer(unsigned(op_addr_bank))).active;
    cur_bank_row <= bank_states(to_integer(unsigned(op_addr_bank))).row;
    
    process(mem_clk)
    begin
        if (rising_edge(mem_clk)) then
            data_out <= sdram_data;
        end if;
    end process;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            cycle_counter <= std_logic_vector(unsigned(cycle_counter) + 1);
            mc_out.op_strobe <= strobe_r1;
            strobe_r1 <= strobe_r2;
            command <= CMD_NOP;

            if (dqm_on) then
                dqm_on_counter <= std_logic_vector(unsigned(dqm_on_counter) - 1);
            end if;

            case state is
                when STARTUP =>
                    if (cycle_counter(STARTUP_CYCLE_BITNR) = '1') then
                        cke <= '1';
                        if (cycle_counter(2 downto 0) = "001") then
                            command <= CMD_PRECHARGE;
                        elsif (cycle_counter(2 downto 0) = "101") then
                            command <= CMD_LMR;
                        elsif (cycle_counter(2 downto 0) = "111") then
                            state <= IDLE;
                        end if;
                    end if;
                when IDLE =>
                    if (busy_wait = '0') then
                        --
                        -- XXX Do not force a refresh if a transaction
                        --     is pending. As we might end up precharging
                        --     an immediately activated line berfore refresh
                        --     and this will cause a tRAS (Active-to-Precharge)
                        --     violation.
                        --     Hence in the below conditional we chech 
                        --     strobe first and then the refresh counter.
                        --
                        --     We don't expect any refresh-starvation problems.
                        --
                        --     refresh_lock is required to avoid a transaction
                        --     from pre-emeting refresh after pre-charge.
                        --
                        if (mc_in.op_start /= mc_out.op_strobe and
                            refresh_lock = '0') 
                        then
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
                                busy_wait_counter <= TRCD_CYCLES;
                            else
                                if (cur_bank_row /= op_addr_row) then
                                    -- Precharge row
                                    command <= CMD_PRECHARGE;
                                    addr(10) <= '0';
                                    busy_wait_counter <= TRP_CYCLES;
                                    bank_states(
                                        to_integer(
                                            unsigned(op_addr_bank))).active <= '0';
                                else
                                    -- Read write only on 16 byte boundaries
                                    -- cache line size is 16 bytes
                                    -- Auto pre-charge disabled
                                    addr <= "0000" & op_addr_col(8 downto 4) & "0000"; 
                                    if (mc_in.op_wren = '1') then
                                        -- Write Operation
                                        state <= WRITE;
                                        strobe_r1 <= not strobe_r2;
                                        strobe_r2 <= not strobe_r2;
                                    else
                                        -- Read Operation
                                        strobe_r2 <= not strobe_r2;
                                        command <= CMD_READ;
                                        busy_wait_counter <= "1001";
                                        dqm_on_counter <= "1000";
                                    end if;
                                end if;
                            end if;
                        elsif (unsigned(cycle_counter) > REFRESH_CYCLES) then
                            if (bank_states(0).active = '1' or
                                bank_states(1).active = '1' or
                                bank_states(2).active = '1' or
                                bank_states(3).active = '1') 
                            then
                                bank_states(0).active <= '0';
                                bank_states(1).active <= '0';
                                bank_states(2).active <= '0';
                                bank_states(3).active <= '0';
                                command <= CMD_PRECHARGE;
                                busy_wait_counter <= TRP_CYCLES;
                                addr(10) <= '1';
                                refresh_lock <= '1';
                            else
                                command <= CMD_REFRESH;
                                busy_wait_counter <= TRFC_CYCLES;
                                cycle_counter <= 
                                    std_logic_vector(unsigned(cycle_counter) - 
                                                                REFRESH_CYCLES);
                                refresh_lock <= '0';
                            end if;
                        end if;
                    else
                        busy_wait_counter <= std_logic_vector(unsigned(busy_wait_counter) - 1);
                    end if;
                when WRITE =>
                    command <= CMD_WRITE;
                    busy_wait_counter <= "0111";
                    dqm_on_counter <= "1000";
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;


