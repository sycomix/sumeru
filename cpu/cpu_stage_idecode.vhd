library work, ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.sumeru_constants.all;
use work.cpu_types.all;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;

    pc:                         out std_logic_vector(31 downto 0);

    icache_tlb_hit:             in std_logic;
    icache_hit:                 in std_logic;
    icache_data:                in std_logic_vector(31 downto 0);

    iexec_in:                   out iexec_channel_in;                    
    iexec_out:                  in iexec_channel_out;                    

    csr_cycle_counter:          out std_logic_vector(63 downto 0);

    icache_flush:               out std_logic;
    icache_flush_strobe:        in std_logic;

    exception_pc_save:          out std_logic_vector(31 downto 0);

    intr_in:                    out interrupt_channel_in;
    intr_out:                   in interrupt_channel_out
);
end entity;

architecture synth of cpu_stage_idecode is
    type decode_state is (
        IDLE,
        WAIT_JALR_PC_UPDATE,
        WAIT_BR_PC_UPDATE,
        WAIT_CACHE_FLUSH);

    alias i_opcode: std_logic_vector(6 downto 0) is icache_data(6 downto 0);
    alias i_rd: std_logic_vector(4 downto 0) is icache_data(11 downto 7);
    alias i_funct3: std_logic_vector(2 downto 0) is icache_data(14 downto 12);
    alias i_rs1: std_logic_vector(4 downto 0) is icache_data(19 downto 15);
    alias i_rs2: std_logic_vector(4 downto 0) is icache_data(24 downto 20);
    alias i_funct7: std_logic_vector(6 downto 0) is icache_data(31 downto 25);
    alias ins: std_logic_vector(31 downto 0) is icache_data;

    signal state:               decode_state := IDLE;
    signal i_type_i_imm:        std_logic_vector(31 downto 0);
    signal i_type_s_imm:        std_logic_vector(31 downto 0);
    signal i_type_u_imm:        std_logic_vector(31 downto 0);
    signal i_type_b_imm:        std_logic_vector(31 downto 0);
    signal i_type_j_imm:        std_logic_vector(31 downto 0);
    signal imm_save:            std_logic_vector(31 downto 0);
    signal pc_p4:               std_logic_vector(31 downto 0);
    signal icache_flush_strobe_save: std_logic := '0';

    signal exception_start_save: std_logic := '0';
    signal iexec_exception_start_save: std_logic := '0';
    signal exception_start:     std_logic := '0';
    signal exception_offset:    std_logic_vector(31 downto 0);
    signal delayed_exception:   std_logic := '0';
    signal delayed_exception_offset: std_logic_vector(31 downto 0);
    signal delayed_exception_pc: std_logic_vector(31 downto 0);
    signal toggle_intr_freeze:  std_logic;
    signal intr_freeze_flag:    std_logic;

    signal pc_r:                std_logic_vector(31 downto 0) := IVECTOR_RESET_ADDR(31 downto 8) & BOOT_OFFSET;
    signal icache_flush_r:      std_logic := '0';
    signal csr_cycle_counter_r: std_logic_vector(63 downto 0) := (others => '0');
    signal bus_valid:           std_logic := '0';
    signal intr_start_save:     std_logic := '0';
    signal intr_freeze:         std_logic := '0';

    
begin
    pc <= pc_r;
    icache_flush <= icache_flush_r;
    iexec_in.bus_valid <= bus_valid;
    intr_in.idecode_intr_start_save <= intr_start_save;
    intr_in.intr_freeze <= intr_freeze;
    csr_cycle_counter <= csr_cycle_counter_r;

    pc_p4 <= std_logic_vector(unsigned(pc_r) + 4);

    i_type_i_imm <= 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31 downto 20);
    i_type_s_imm <= 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31 downto 25) & ins(11 downto 7);
    i_type_u_imm <= ins(31 downto 12) & "000000000000";
    i_type_b_imm <= 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) &
        ins(31) & ins(7) & ins(30 downto 25) & ins(11 downto 8) & "0";
    i_type_j_imm <=
        ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & ins(31) & 
        ins(31) & ins(31) & ins(31) & ins(31) &
        ins(31) & ins(19 downto 12) & ins(20) & ins(30 downto 21) & "0";

    process(sys_clk)
        variable vx: std_logic_vector(31 downto 0);
    begin
        if (rising_edge(sys_clk) and iexec_out.bus_busy = '0') then
            case state is
                when IDLE =>
                    if (icache_tlb_hit = '1' and icache_hit = '1') then
                        csr_cycle_counter_r <= std_logic_vector(unsigned(csr_cycle_counter_r) + 1);
                        pc_r <= pc_p4;
                        iexec_in.cmd <= "0" & i_funct3;
                        iexec_in.rs1 <= i_rs1;
                        iexec_in.rs2 <= i_rs2;
                        iexec_in.rd <= i_rd;
                        bus_valid <= '1';
                        iexec_in.cmd_r2_imm <= '1';
                        iexec_in.immediate <= i_type_i_imm;
                        iexec_in.meta_cmd <= META_CMD_MISC;
                        case i_opcode(6 downto 2) is 
                            when OP_TYPE_MISC_MEM =>
                                -- Only FENCE.I is applicable to us ATM
                                -- therefore FENCE is a NOP
                                if (i_funct3(0) = '1') then
                                    icache_flush_r <= not icache_flush_r;
                                    state <= WAIT_CACHE_FLUSH;
                                end if;
                                bus_valid <= '0';
                            when OP_TYPE_CSR =>
                                -- i_funct3 is zero for ECALL and EBREAK instructions
                                -- and i_funct3 is valid for CSRXXX therefore
                                -- we don't set iexec_cmd specifically here
                                -- above iexec_cmd is set to i_funct3 which
                                -- works correctly for both cases handled here
                                if (i_funct3 /= "000") then
                                    if (i_type_i_imm(11 downto 1) = "00000000000") then
                                        iexec_in.meta_cmd <= META_CMD_CLFLUSH;
                                        iexec_in.dcache_line_evict <= i_type_i_imm(0);
                                    else
                                        iexec_in.meta_cmd <= META_CMD_CSRXXX;
                                    end if;
                                end if;
                            when OP_TYPE_L =>
                                iexec_in.meta_cmd <= META_CMD_LOAD;
                           when OP_TYPE_S =>
                                iexec_in.cmd_r2_imm <= '0';
                                iexec_in.immediate <= i_type_s_imm;
                                iexec_in.meta_cmd <= META_CMD_STORE;
                           when OP_TYPE_I =>
                                iexec_in.meta_cmd <= META_CMD_BASIC;
                                if (i_funct3 = FUNCT_SRX and ins(30) = '1') then
                                    iexec_in.cmd <= CMD_SRA;
                                end if;
                           when OP_TYPE_U_LUI =>
                                iexec_in.immediate <= i_type_u_imm; 
                                iexec_in.cmd <= CMD_WR_RS2;
                           when OP_TYPE_U_AUIPC =>
                                iexec_in.immediate <= std_logic_vector(unsigned(pc_r) + unsigned(i_type_u_imm));
                                iexec_in.cmd <= CMD_WR_RS2;
                           when OP_TYPE_JAL =>
                                iexec_in.immediate <= pc_p4;
                                iexec_in.cmd <= CMD_WR_RS2;
                                pc_r <= std_logic_vector(unsigned(pc_r) + unsigned(i_type_j_imm));
                                -- This optimisation is useful only when
                                -- iexec_bus_busy = '1'
                                -- XXX we should optimize all cases where i_rd = 0??
                                -- if (i_rd = "00000") then
                                -- bus_valid <= '0';
                                -- end if;
                           when OP_TYPE_JALR =>
                                iexec_in.immediate <= pc_p4;
                                iexec_in.meta_cmd <= META_CMD_JALR;
                                iexec_in.cmd <= CMD_JALR;
                                pc_r <= pc_r;      -- don't update PC as it can cause a cache miss
                                imm_save <= i_type_i_imm;
                                state <= WAIT_JALR_PC_UPDATE;
                           when OP_TYPE_B =>
                                -- set cmd to type of branch
                                iexec_in.cmd_r2_imm <= '0';
                                imm_save <= std_logic_vector(unsigned(pc_r) + unsigned(i_type_b_imm));
                                iexec_in.meta_cmd <= META_CMD_BRANCH;
                                pc_r <= pc_r;      -- don't update PC as it can cause a cache miss
                                state <= WAIT_BR_PC_UPDATE;
                           when OP_TYPE_R =>
                                iexec_in.cmd_r2_imm <= '0';
                                iexec_in.meta_cmd <= META_CMD_BASIC;
                                if (i_funct7 = OP_IFUNCT7_MULDIV) then
                                    iexec_in.meta_cmd <= META_CMD_MULDIV;
                                elsif (i_funct3 = FUNCT_SRX and ins(30) = '1') then
                                    iexec_in.cmd <= CMD_SRA;
                                elsif(i_funct3 = FUNCT_AOS and ins(30) = '1') then
                                    iexec_in.cmd <= CMD_SUB;
                                end if; 
                            -- XXX TODO OP: ECALL EBREAK
                           when others =>
                                -- XXX Handle invalid instruction exceptions here
                                -- raise exception, branch ??
                                bus_valid <= '0';
                                delayed_exception <= '1';
                                delayed_exception_pc <= pc_r;
                                delayed_exception_offset <= 
                                    intr_out.intr_vector_addr & EXN_UNKNOWN_INSTR_OFFSET;
                           end case;
                    else
                        bus_valid <= '0';
                    end if;
                when WAIT_CACHE_FLUSH =>
                    if (icache_flush_strobe_save /= icache_flush_strobe) then
                        icache_flush_strobe_save <= icache_flush_strobe;
                        state <= IDLE;
                    end if;
                when WAIT_JALR_PC_UPDATE =>
                    bus_valid <= '0';
                    if (iexec_out.pc_update_done = '1') then
                        -- XXX set pc(0) to zero as required by spec
                        vx := std_logic_vector(unsigned(iexec_out.jalr_branch_addr) + unsigned(imm_save));
                        pc_r <= vx(31 downto 1) & '0';
                        state <= IDLE;
                    end if;
                when WAIT_BR_PC_UPDATE =>
                    bus_valid <= '0';
                    if (iexec_out.pc_update_done = '1') then
                        if (iexec_out.pc_branch_taken) then
                            pc_r <= imm_save;
                        else
                            pc_r <= pc_p4;
                        end if;
                        state <= IDLE;
                    end if;
            end case;

            if (exception_start_save /= exception_start) then
                exception_start_save <= exception_start;
                pc_r <= exception_offset;
                bus_valid <= '0';
                delayed_exception <= '0';
                state <= IDLE;
                intr_freeze <= intr_freeze xor toggle_intr_freeze; 
                intr_in.intr_freeze_flag <= intr_freeze_flag;
            end if;
        end if;
    end process;

    process(sys_clk)
    begin
        if (falling_edge(sys_clk)) then
            toggle_intr_freeze <= '1';
            intr_freeze_flag <= '1';
            if (pc_r(1 downto 0) /= "00") then
                exception_start <= not exception_start;
                exception_pc_save <= pc_r;
                exception_offset <= intr_out.intr_vector_addr & EXN_UNALIGNED_PC_OFFSET;
            elsif (iexec_exception_start_save /= iexec_out.exception_start) then
                iexec_exception_start_save <= iexec_out.exception_start;
                exception_start <= not exception_start;
                exception_offset <= iexec_out.exception_pc;
                intr_freeze_flag <= '0';
            elsif (delayed_exception = '1') then
                -- use the last executed pc
                exception_start <= not exception_start;
                exception_offset <= delayed_exception_offset;
                exception_pc_save <= delayed_exception_pc;
            elsif (intr_start_save /= intr_out.intr_start) then
                intr_start_save <= intr_out.intr_start;
                exception_start <= not exception_start;
                exception_offset <= intr_out.intr_vector_addr & intr_out.intr_vector_offset & "0000";
                exception_pc_save <= pc;
                -- interrupts already disabled by interrupt controller hence no toggle required
                toggle_intr_freeze <= '0';
            end if;
        end if;
    end process;

end architecture;
