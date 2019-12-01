library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.memory_channel_types.ALL;
use work.cpu_types.ALL;

entity cpu_stage_iexecute is
port(
    sys_clk:                    in std_logic;
    cache_clk:                  in std_logic;

    iexec_in:                   in iexec_channel_in;                    
    iexec_out:                  out iexec_channel_out;                    

    mc_in:                      out mem_channel_in_t;
    mc_out:                     in mem_channel_out_t;
    sdc_data_out:               in std_logic_vector(15 downto 0);

    csr_instret_counter:        out std_logic_vector(63 downto 0);

    csr_in:                     out csr_channel_in;
    csr_out:                    in csr_channel_out;

    page_table_baseaddr:        in std_logic_vector(24 downto 0)
);
end entity;

architecture synth of cpu_stage_iexecute is
    type execute_state is (
        IDLE,
        LOAD_WAIT,
        STORE_INIT,
        STORE_WAIT,
        SLL_STAGE2,
        SRX_STAGE2,
        DIV_STAGE2,
        MUL_STAGE2,
        CSRXXX_STAGE2,
        EXEC_EXN_STAGE2);

    signal state:               execute_state := IDLE;
    signal rs1_read_data:       std_logic_vector(31 downto 0);
    signal rs2_read_data:       std_logic_vector(31 downto 0);
    signal rd_write_data:       std_logic_vector(31 downto 0) := (others => '0');
    signal rd_wren:             std_logic := '0';

    signal iexec_rd_ff:         std_logic_vector(4 downto 0) := (others => '0');

    signal cache_addr:          std_logic_vector(31 downto 0) := (others => '0');
    signal cache_dqm:           std_logic_vector(3 downto 0) := (others => '0');
    signal cd:                  std_logic_vector(31 downto 0);
    signal cache_hit:           std_logic;
    signal cache_tlb_hit:       std_logic;
    signal cache_start:         std_logic := '0';      
    signal cache_write_data:    std_logic_vector(31 downto 0);
    signal cache_write_strobe:  std_logic;
    signal cache_addr_v:        std_logic_vector(31 downto 0);
    signal cache_wren:          std_logic;

    signal last_rd: std_logic_vector(4 downto 0) := (others => '0');
    signal last_rd_data: std_logic_vector(31 downto 0) := (others => '0');

    signal shift_data:          std_logic_vector(31 downto 0);
    signal shift_amt:           std_logic_vector(4 downto 0);
    signal shift_bit:           std_logic;
    signal shiftrx_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftrx_stage1_result_b: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_a: std_logic_vector(15 downto 0);
    signal shiftll_stage1_result_b: std_logic_vector(15 downto 0);

    signal stage2_cmd_save:     std_logic_vector(3 downto 0);
    signal stage2_data_save:    std_logic_vector(31 downto 0);
    signal stage2_wren_save:    std_logic;

    signal rs1_data_ff: std_logic_vector(31 downto 0);
    signal rs2_data_ff: std_logic_vector(31 downto 0);
    signal rs2_data_regval: std_logic_vector(31 downto 0);

    signal use_load_sign:       std_logic;
    signal ls0:                 std_logic;
    signal ls1:                 std_logic;
    signal ls2:                 std_logic;
    signal ls3:                 std_logic;

    signal load_result_0011: std_logic_vector(31 downto 0);
    signal load_result_1100: std_logic_vector(31 downto 0);
    signal load_result_0001: std_logic_vector(31 downto 0);
    signal load_result_0010: std_logic_vector(31 downto 0);
    signal load_result_0100: std_logic_vector(31 downto 0);
    signal load_result_1000: std_logic_vector(31 downto 0);

    signal muldiv_op1:          std_logic_vector(32 downto 0) := (others => '0');
    signal muldiv_op2:          std_logic_vector(32 downto 0) := (others => '0');
    signal muldiv_counter:      std_logic_vector(5 downto 0) := (others => '0');
    signal muldiv_cke:          std_logic := '0';
    signal mul_result:          std_logic_vector(65 downto 0);

    signal div_quotient:        std_logic_vector(32 downto 0);
    signal div_remainder:       std_logic_vector(32 downto 0);

    signal cmp_eq_op1_op2:      std_logic;
    signal cmp_lt_op1_op2:      std_logic;
    signal cmp_lt_u_op1_op2:    std_logic;

    signal csr_instret_counter_r: std_logic_vector(63 downto 0) := (others => '0');
    signal bus_busy:            std_logic := '0';
    signal csr_valid:           std_logic := '0';
    signal exception_start:     std_logic := '0';
    signal pc_update_done:      std_logic := '0';

    pure function sxt(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(x), n));
    end function;

    pure function ext(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(unsigned(x), n));
    end function;

begin
    csr_instret_counter <= csr_instret_counter_r;
    iexec_out.bus_busy <= bus_busy;
    csr_in.valid <= csr_valid;
    iexec_out.exception_start <= exception_start;
    iexec_out.pc_update_done <= pc_update_done;

    dcache: entity work.dcache
        port map(
            sys_clk => sys_clk,
            cache_clk => cache_clk,

            daddr => cache_addr,
            start => cache_start,
           
            tlb_hit => cache_tlb_hit,
            hit => cache_hit,
            read_data => cd,

            wren => cache_wren,
            byteena => cache_dqm,
            write_strobe => cache_write_strobe,
            write_data => cache_write_data,

            mc_in => mc_in,
            mc_out => mc_out,
            sdc_data_out => sdc_data_out,

            page_table_baseaddr => page_table_baseaddr
    );

    reg_bank1: entity work.ram2p_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs1,
            wraddress => iexec_rd_ff,
            wren => rd_wren,
            q => rs1_read_data
        );

    reg_bank2: entity work.ram2p_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs2,
            wraddress => iexec_rd_ff,
            wren => rd_wren,
            q => rs2_read_data
        );

    multip: entity work.multiplier
        port map(
            clken => muldiv_cke,
            clock => sys_clk,
            dataa => muldiv_op1,
            datab => muldiv_op2,
            result => mul_result);

    divider: entity work.divider
        port map(
            clken => muldiv_cke,
            clock => sys_clk,
            numer => muldiv_op1,
            denom => muldiv_op2,
            quotient => div_quotient,
            remain => div_remainder);

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftrx_stage1_result_b <= 
            shift_data(31 downto 16) when "0000",
            sxt(shift_bit & shift_data(31 downto 18), 16) when "0001",
            sxt(shift_bit & shift_data(31 downto 20), 16) when "0010",
            sxt(shift_bit & shift_data(31 downto 22), 16) when "0011",
            sxt(shift_bit & shift_data(31 downto 24), 16) when "0100",
            sxt(shift_bit & shift_data(31 downto 26), 16) when "0101",
            sxt(shift_bit & shift_data(31 downto 28), 16) when "0110",
            sxt(shift_bit & shift_data(31 downto 30), 16) when "0111",
            (shift_bit & shift_bit & shift_bit & shift_bit &
                shift_bit & shift_bit & shift_bit & shift_bit &
                shift_bit & shift_bit & shift_bit & shift_bit &
                shift_bit & shift_bit & shift_bit & shift_bit) when others;

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftrx_stage1_result_a <= 
            shift_data(15 downto 0) when "0000",
            shift_data(17 downto 2) when "0001",
            shift_data(19 downto 4) when "0010",
            shift_data(21 downto 6) when "0011",
            shift_data(23 downto 8) when "0100",
            shift_data(25 downto 10) when "0101",
            shift_data(27 downto 12) when "0110",
            shift_data(29 downto 14) when "0111",
            shift_data(31 downto 16) when "1000",
            sxt(shift_bit & shift_data(31 downto 18), 16) when "1001",
            sxt(shift_bit & shift_data(31 downto 20), 16) when "1010",
            sxt(shift_bit & shift_data(31 downto 22), 16) when "1011",
            sxt(shift_bit & shift_data(31 downto 24), 16) when "1100",
            sxt(shift_bit & shift_data(31 downto 26), 16) when "1101",
            sxt(shift_bit & shift_data(31 downto 28), 16) when "1110",
            sxt(shift_bit & shift_data(31 downto 30), 16) when "1111";

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftll_stage1_result_b <= 
            shift_data(31 downto 16) when "0000",
            shift_data(29 downto 14) when "0001",
            shift_data(27 downto 12) when "0010",
            shift_data(25 downto 10) when "0011",
            shift_data(23 downto 8) when "0100",
            shift_data(21 downto 6) when "0101",
            shift_data(19 downto 4) when "0110",
            shift_data(17 downto 2) when "0111",
            shift_data(15 downto 0) when "1000",
            shift_data(13 downto 0) & "00" when "1001",
            shift_data(11 downto 0) & "0000" when "1010",
            shift_data(9 downto 0) & "000000" when "1011",
            shift_data(7 downto 0) & "00000000" when "1100",
            shift_data(5 downto 0) & "0000000000" when "1101",
            shift_data(3 downto 0) & "000000000000" when "1110",
            shift_data(1 downto 0) & "00000000000000" when "1111";

    with to_bitvector(shift_amt(4 downto 1)) select
        shiftll_stage1_result_a <= 
            shift_data(15 downto 0) when "0000",
            shift_data(13 downto 0) & "00" when "0001",
            shift_data(11 downto 0) & "0000" when "0010",
            shift_data(9 downto 0) & "000000" when "0011",
            shift_data(7 downto 0) & "00000000" when "0100",
            shift_data(5 downto 0) & "0000000000" when "0101",
            shift_data(3 downto 0) & "000000000000" when "0110",
            shift_data(1 downto 0) & "00000000000000" when "0111",
            "0000000000000000" when others;

    ls0 <= use_load_sign and cd(7);
    ls1 <= use_load_sign and cd(15);
    ls2 <= use_load_sign and cd(23);
    ls3 <= use_load_sign and cd(31);

    load_result_0011 <= 
        ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 &
        ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 &
        cd(15 downto 0);
    load_result_1100 <=
        ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 &
        ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 &
        cd(31 downto 16);
    load_result_0001 <=
        ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & 
        ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & 
        ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 & ls0 &
        cd(7 downto 0);
    load_result_0010 <=
        ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & 
        ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & 
        ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 & ls1 &
        cd(15 downto 8);
    load_result_0100 <=
        ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & 
        ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & 
        ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & ls2 & 
        cd(23 downto 16);
    load_result_1000 <=
        ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & 
        ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & 
        ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & ls3 & 
        cd(31 downto 24);


    rs1_data_ff <= last_rd_data when iexec_in.rs1 = last_rd else rs1_read_data;

    rs2_data_regval <=
        last_rd_data when iexec_in.rs2 = last_rd else rs2_read_data;

    rs2_data_ff <= 
        iexec_in.immediate when iexec_in.cmd_r2_imm = '1' else 
        rs2_data_regval;

    cmp_eq_op1_op2 <= '1' when rs1_data_ff = rs2_data_ff else '0';
    cmp_lt_op1_op2 <= 
        '1' when signed(rs1_data_ff) < signed(rs2_data_ff) else
        '0';
    cmp_lt_u_op1_op2 <= 
        '1' when unsigned(rs1_data_ff) < unsigned(rs2_data_ff) else
        '0';

    cache_addr_v <= std_logic_vector(unsigned(rs1_data_ff) + unsigned(iexec_in.immediate));

    process(sys_clk)
        variable op_result: std_logic_vector(31 downto 0);
        variable rd_wren_ff: std_logic;
        variable iexec_rd_ff_v: std_logic_vector(4 downto 0);

begin
        if (rising_edge(sys_clk)) then
            case state is
                when IDLE =>
                    bus_busy <= '0';
                    pc_update_done <= '0';
                    rd_wren_ff := '0';

                    if (iexec_in.bus_valid = '1') then
                        csr_instret_counter_r <= std_logic_vector(unsigned(csr_instret_counter_r) + 1);
                        iexec_rd_ff_v := iexec_in.rd;
                        if (iexec_in.rd = "00000") then
                            rd_wren_ff := '0';
                            stage2_wren_save <= '0';
                        else
                            rd_wren_ff := '1';
                            stage2_wren_save <= '1';
                        end if;

                        stage2_cmd_save <= iexec_in.cmd;
                        stage2_data_save <= rs2_data_ff;

                        muldiv_counter <= (others => '0');
                        muldiv_op1 <= rs1_data_ff(31) & rs1_data_ff;
                        muldiv_op2 <= rs2_data_ff(31) & rs2_data_ff;

                        case (iexec_in.cmd(1 downto 0) & cache_addr_v(1 downto 0)) is
                            when "0000" =>
                                cache_dqm <= "0001";
                            when "0001" =>
                                cache_dqm <= "0010";
                            when "0010" =>
                                cache_dqm <= "0100";
                            when "0011" =>
                                cache_dqm <= "1000";
                            when "0100" =>
                                cache_dqm <= "0011";
                            when "0110" =>
                                cache_dqm <= "1100";
                            when others =>
                                cache_dqm <= "1111";
                        end case;

                        case iexec_in.cmd is
                            when CMD_BR_EQ | CMD_BR_NE =>
                                iexec_out.pc_branch_taken <= 
                                    cmp_eq_op1_op2 xor iexec_in.cmd(0);
                            when CMD_BR_LT | CMD_BR_GE =>
                                iexec_out.pc_branch_taken <= 
                                    cmp_lt_op1_op2 xor iexec_in.cmd(0);
                            when others =>
                                iexec_out.pc_branch_taken <= 
                                    cmp_lt_u_op1_op2 xor iexec_in.cmd(0);
                        end case;

                        case iexec_in.meta_cmd is
                            when META_CMD_CLFLUSH =>
                                -- hitherto, we are using cache_addr_v
                                -- hence CLFLUSH needs the immediate to
                                -- be 0 therefore we must map cache flush to
                                -- CSR addr 0
                                rd_wren_ff := '0';
                                bus_busy <= '1';
                                -- DCACHE LINE EVICTION
                                cache_addr <= 
                                    "0000000000000000000" &
                                    (not cache_addr(12)) & 
                                    cache_addr_v(11 downto 0);
                                cache_wren <= '1';
                                cache_dqm <= "0000";
                                cache_start <= not cache_start;
                                state <= STORE_WAIT;
                            when META_CMD_MULDIV =>
                                rd_wren_ff := '0';
                                bus_busy <= '1';
                                if (iexec_in.cmd(2) = '0') then
                                    state <= MUL_STAGE2;
                                else
                                    state <= DIV_STAGE2;
                                end if;
                            when META_CMD_CSRXXX =>
                                rd_wren_ff := '0';
                                bus_busy <= '1';
                                csr_valid <= '1';
                                csr_in.funct3 <= iexec_in.cmd(2 downto 0);
                                csr_in.addr <= rs2_data_ff(11 downto 0);
                                state <= CSRXXX_STAGE2;
                                if (iexec_in.cmd(2) = '1') then
                                    csr_in.value <= ext(iexec_in.rs1, 32);
                                else
                                    csr_in.value <= rs1_data_ff;
                                end if;
                            when META_CMD_LOAD =>
                                cache_addr <= cache_addr_v;
                                state <= LOAD_WAIT;
                                rd_wren_ff := '0';
                                bus_busy <= '1';
                                use_load_sign <= not iexec_in.cmd(2);
                                cache_start <= not cache_start;
                                cache_wren <= '0';
                            when META_CMD_STORE =>
                                cache_addr <= cache_addr_v;
                                cache_wren <= '1';
                                state <= STORE_INIT;
                                rd_wren_ff := '0';
                                bus_busy <= '1';
                            when META_CMD_JALR =>
                                pc_update_done <= '1';
                                iexec_out.pc_branch_taken <= '1';
                                iexec_out.jalr_branch_addr <= rs1_data_ff;
                                op_result := iexec_in.immediate;
                            when META_CMD_BRANCH =>
                                rd_wren_ff := '0';
                                pc_update_done <= '1';
                            when META_CMD_MISC =>
                                -- for now, no other command in this cat hence no conditional needed
                                op_result := rs2_data_ff;
                                if (iexec_in.cmd = CMD_ENV) then
                                    -- TODO Implement ECALL EBREAK
                                    rd_wren_ff := '0';
                                end if;
                            when META_CMD_BASIC =>
                                shift_data <= rs1_data_ff;
                                shift_amt <= rs2_data_ff(4 downto 0);
                                case iexec_in.cmd is
                                    when CMD_SUB =>
                                        op_result := std_logic_vector(signed(rs1_data_ff) - signed(rs2_data_ff));
                                    when CMD_SLT =>
                                        op_result := "0000000000000000000000000000000" & cmp_lt_op1_op2;
                                    when CMD_SLTU =>
                                        op_result := "0000000000000000000000000000000" & cmp_lt_u_op1_op2;
                                    when CMD_XOR =>
                                        op_result := rs1_data_ff xor rs2_data_ff;
                                    when CMD_OR =>
                                        op_result := rs1_data_ff or rs2_data_ff;
                                    when CMD_AND =>
                                        op_result := rs1_data_ff and rs2_data_ff;
                                    when CMD_SRA =>
                                        shift_bit <= rs1_data_ff(31);
                                        bus_busy <= '1';
                                        rd_wren_ff := '0';
                                        state <= SRX_STAGE2;
                                    when CMD_SRL =>
                                        shift_bit <= '0';
                                        bus_busy <= '1';
                                        rd_wren_ff := '0';
                                        state <= SRX_STAGE2;
                                    when CMD_SLL =>
                                        bus_busy <= '1';
                                        rd_wren_ff := '0';
                                        state <= SLL_STAGE2;
                                    when others =>              -- ADD
                                        op_result := std_logic_vector(unsigned(rs1_data_ff) + unsigned(rs2_data_ff));
                                end case;
                            when others =>
                                -- execption code here
                                rd_wren_ff := '0';
                        end case;
                    end if;
                when CSRXXX_STAGE2 =>
                    csr_valid <= '0';
                    if (csr_out.csr_op(1) = '1') then
                            -- we keep assert valid as the csr unit in question
                            -- may be busy and could have not seen valid high
                            -- XXX This causes a benign side-effect ... 
                            -- see comment in csr_periph for more details.
                            csr_valid <= '1';
                    elsif (csr_out.csr_op = CSR_OP_READ) then
                            bus_busy <= '0';
                            state <= IDLE;
                            rd_wren_ff := stage2_wren_save;
                            op_result := csr_out.result;
                    else
                            bus_busy <= '0';
                            --
                            -- invariant: decoder is aware of bus busy
                            -- but there may be a command present
                            -- on the iexec bus, we do not want to execute this
                            -- command as we have issued a pc switch
                            -- therefore we set bus_busy = '0' and goto stage2
                            -- EXEC_EXN_STAGE2 is a dummy state that ignores
                            -- a command (if present) on the iexec bus
                            -- same for the interrupt case below
                            --
                            state <= EXEC_EXN_STAGE2;
                            exception_start <= not exception_start;
                            iexec_out.exception_pc <= csr_out.result;
                    end if;
                when EXEC_EXN_STAGE2 =>
                    -- dummy state to ignore a command if present
                    state <= IDLE;
                when DIV_STAGE2 =>
                    -- XXX **** Ignore divide by zero for now ...
                    --          RISC-V mandates specific output
                    --          result for divide by zero and 
                    --          signed divide overflow.

                    muldiv_counter <= std_logic_vector(unsigned(muldiv_counter) + 1);
                    if (muldiv_counter = "000000") then
                        muldiv_cke <= '1';
                        if (stage2_cmd_save = CMD_DIVU or 
                            stage2_cmd_save = CMD_REMU) then
                                muldiv_op1(32) <= '0';
                                muldiv_op2(32) <= '0';
                        end if;
                    elsif (muldiv_counter = "001001") then
                        bus_busy <= '0';
                        rd_wren_ff := stage2_wren_save;
                        state <= IDLE;
                        case stage2_cmd_save is
                            when CMD_DIV =>
                                op_result := 
                                        div_quotient(32) &
                                            div_quotient(30 downto 0);
                            when CMD_DIVU =>
                                op_result := div_quotient(31 downto 0);
                            when CMD_REM =>
                                op_result := 
                                        div_remainder(32) &
                                            div_remainder(30 downto 0);
                            when others => -- CMD_REMU
                                op_result := div_remainder(31 downto 0);
                        end case;
                    end if;
                when MUL_STAGE2 =>
                    muldiv_counter <= std_logic_vector(unsigned(muldiv_counter) + 1);
                    if (muldiv_counter = "000000") then
                        muldiv_cke <= '1';
                        case stage2_cmd_save is
                            when CMD_MULHSU =>
                                muldiv_op2(32) <= '0';
                                state <= MUL_STAGE2;
                            when CMD_MULHU =>
                                muldiv_op1(32) <= '0';
                                muldiv_op2(32) <= '0';
                            when others =>
                        end case;
                    elsif (muldiv_counter = "000010") then
                        muldiv_cke <= '0';
                        rd_wren_ff := stage2_wren_save;
                        state <= IDLE;
                        bus_busy <= '0';
                        case stage2_cmd_save is
                            when CMD_MUL =>
                                op_result := mul_result(31 downto 0);
                            when CMD_MULHU =>
                                op_result := mul_result(63 downto 32);
                            when others => -- CMD_MULH | CMD_MULHSU
                                op_result := mul_result(65) &
                                                mul_result(62 downto 32);
                        end case;
                    end if;
                when SLL_STAGE2 =>
                    if (shift_amt(0) = '0') then
                        op_result := shiftll_stage1_result_b & shiftll_stage1_result_a;
                    else
                        op_result := shiftll_stage1_result_b(14 downto 0) & shiftll_stage1_result_a & '0';
                    end if;
                    bus_busy <= '0';
                    rd_wren_ff := stage2_wren_save;
                    state <= IDLE;
                when SRX_STAGE2 =>
                    if (shift_amt(0) = '0') then
                        op_result := shiftrx_stage1_result_b & shiftrx_stage1_result_a;
                    else
                        op_result := shift_bit & shiftrx_stage1_result_b & shiftrx_stage1_result_a(15 downto 1);
                    end if;
                    bus_busy <= '0';
                    rd_wren_ff := stage2_wren_save;
                    state <= IDLE;
                when LOAD_WAIT =>
                    if (cache_tlb_hit = '1' and cache_hit = '1') then
                        state <= IDLE;
                        rd_wren_ff := stage2_wren_save;
                        bus_busy <= '0';
                        case cache_dqm is
                            when "1111" =>
                                op_result := cd;
                            when "0011" =>
                                op_result := load_result_0011;
                            when "1100" =>
                                op_result := load_result_1100;
                            when "0001" =>
                                op_result := load_result_0001;
                            when "0010" =>
                                op_result := load_result_0010;
                            when "0100" =>
                                op_result := load_result_0100;
                            when others =>
                                op_result := load_result_1000;
                        end case;
                    end if;
                when STORE_INIT =>
                    case (stage2_cmd_save(1 downto 0) & cache_addr(1 downto 0)) is
                        when "0000" =>
                            cache_dqm <= "0001";
                            cache_write_data <= "000000000000000000000000" & stage2_data_save(7 downto 0);
                        when "0001" =>
                            cache_dqm <= "0010";
                            cache_write_data <= "0000000000000000" & stage2_data_save(7 downto 0) & "00000000";
                        when "0010" =>
                            cache_dqm <= "0100";
                            cache_write_data <= "00000000" & stage2_data_save(7 downto 0) & "0000000000000000";
                        when "0011" =>
                            cache_dqm <= "1000";
                            cache_write_data <= stage2_data_save(7 downto 0) & "000000000000000000000000";
                        when "0100" =>
                            cache_dqm <= "0011";
                            cache_write_data <= "0000000000000000" & stage2_data_save(15 downto 0);
                        when "0110" =>
                            cache_dqm <= "1100";
                            cache_write_data <=  stage2_data_save(15 downto 0) & "0000000000000000";
                        when others =>
                            cache_dqm <= "1111";
                            cache_write_data <=  stage2_data_save; 
                    end case;
                    state <= STORE_WAIT;
                    cache_start <= not cache_start;
                when STORE_WAIT =>
                    if (cache_write_strobe = '1') then
                        state <= IDLE;
                        bus_busy <= '0';
                    end if;
            end case;

            iexec_rd_ff <= iexec_rd_ff_v;

            if (rd_wren_ff = '1') then
                last_rd <= iexec_rd_ff_v;
                last_rd_data <= op_result;
                rd_write_data <= op_result;
                rd_wren <= '1';
            else
                rd_wren <= '0';
            end if;
        end if;
    end process;
end architecture;

