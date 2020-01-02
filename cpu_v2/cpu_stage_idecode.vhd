library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.sumeru_constants.ALL;
use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    clk:                        in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t;
    iexec_in:                   out iexec_channel_in_t;
    iexec_out:                  in iexec_channel_out_t;
    intr_out:                   in intr_channel_out_t;
    ctx_pc_save:                out std_logic_vector(31 downto 0);
    ctx_pc_switch:              out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_stage_idecode is
    signal exec_valid:  std_logic := '0';
    signal intr_trigger_save:   std_logic := '0';
    signal intr_pending: std_logic := '0';
    signal intr_reset_r: std_logic := '0';
    signal intr_switch: std_logic := '0';

    signal imm_wr_mux:  std_logic_vector(31 downto 0);


    alias exec_busy:    std_logic is iexec_out.busy;
    alias fetch_valid:  std_logic is idecode_in.valid;

    alias inst:         std_logic_vector(31 downto 0) is idecode_in.inst;
    alias inst_opcode:  std_logic_vector(4 downto 0) is inst(6 downto 2);
    alias inst_funct3:  std_logic_vector(2 downto 0) is inst(14 downto 12);
    alias inst_rs1:     std_logic_vector(4 downto 0) is inst(19 downto 15);
    alias inst_rs2:     std_logic_vector(4 downto 0) is inst(24 downto 20);
    alias inst_rd:      std_logic_vector(4 downto 0) is inst(11 downto 7);
    alias inst_imm_i:   std_logic_vector(11 downto 0) is inst(31 downto 20);
    alias inst_imm_ui:  std_logic_vector(19 downto 0) is inst(31 downto 12);

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
    -- XXX does this condition fix the intr and switch issue where we want
    -- to be busy but also need the address of the next instruction
    idecode_out.busy <= 
        exec_busy or ((intr_pending or intr_switch) and fetch_valid)

    idecode_out.cxfer <= iexec_out.cxfer;
    idecode_out.cxfer_pc <= iexec_out.cxfer_pc;
    iexec_in.valid <= exec_valid;

    with inst_opcode select imm_wr_mux <=
        inst_imm_ui & "000000000000" when OP_TYPE_U_LUI,
        std_logic_vector(unsigned(idecode_in.pc) + 
                         unsigned(inst_imm_ui & "000000000000")) 
            when OP_TYPE_U_AUIPC,
        std_logic_vector(unsigned(idecode_in.pc) + 4) when others;

    process(clk)
        variable add_ext: std_logic_vector(1 downto 0);
    begin
        if (rising_edge(clk)) then
            if (iexec_out.cxfer = '1') then
                exec_valid <= '0';
                -- A switch is invalidated by cxfer as we don't want it
                -- to trigger after the cxfer
                intr_switch <= '0';
            elsif (intr_pending = '1' or intr_switch = '1') then
                -- XXX FIXME DEDLOCK HERE because we are checking fetch_valid
                -- and setting busy (intr_pending) therefore fetch will not
                -- output a valid instruction???
                if (exec_busy = '0' and exec_valid = '0' and fetch_valid = '1') then
                    -- We need fetch_valid because we need to record the next
                    -- pc from where execution will/may continue
                    -- exec_valid = 0 causes us to wait for a cycle if the
                    -- previous cycle issued an instruction. Thereby ensuring
                    -- iexec is free or busy with no instructions pending.
                    -- exec_valid=0 should also insure if the dispatched instr
                    -- was JALR or BRANCH we get to see the resultant 
                    -- iexec_out.cxfer before processing intr_pending.
                    exec_valid <= '1';
                    iexec_in.cmd <= CMD_ALU;
                    iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                    iexec_in.cmd_use_reg <= '0';
                    iexec_in.trigger_cxfer <= '1';
                    iexec_in.rs1 <= (others => '0');
                    iexec_in.rs2 <= (others => '0');
                    iexec_in.rd <= (others => '0');
                    -- XXX What to do if intr_pending and intr_switch occur
                    -- simultaneously??? 
                    -- The strategy below gives prcedence to switch over
                    -- intr with the reasoning the intr will be correctly 
                    -- processed after the switch has take place -- pls. verify
                    if (intr_switch = '1') then
                        intr_switch <= '0';
                        iexec_in.imm <= ctx_pc_switch;
                    else
                        iexec_in.imm <= 
                            IVECTOR_RESET_ADDR & intr_out.intr_ivec_entry & "0000";
                        ctx_pc_save <= idecode_in.pc;
                        intr_pending <= '0';
                    end if;
                else
                    exec_valid <= '0';
                end if;
            elsif (exec_busy = '0') then
                exec_valid <= fetch_valid;
                if (intr_out.intr_trigger /= intr_trigger_save) then
                    intr_trigger_save <= not intr_trigger_save;
                    intr_pending <= '1';
                end if;
                if (fetch_valid = '1') then
                    -- DO DECODE
                    iexec_in.rs1 <= inst_rs1;
                    iexec_in.rs2 <= inst_rs2;
                    iexec_in.rd <= inst_rd;
                    iexec_in.trigger_cxfer <= '0';
                    iexec_in.pc_p4 <= 
                        std_logic_vector(unsigned(idecode_in.pc) + 4);
                    case inst_opcode is
                        when OP_TYPE_B =>
                            iexec_in.imm <= 
                                std_logic_vector(
                                    signed(idecode_in.pc) + 
                                    signed(inst(31) & inst(7) & 
                                                inst(30 downto 25) & 
                                                inst(11 downto 8) & "0"));
                            iexec_in.cmd_use_reg <= '1';
                            iexec_in.cmd <= CMD_BRANCH;
                            iexec_in.cmd_op <= "0" & inst_funct3;
                        when OP_TYPE_JAL | OP_TYPE_U_LUI | OP_TYPE_U_AUIPC =>
                            iexec_in.imm <= imm_wr_mux;
                            iexec_in.rs1 <= (others => '0');
                            iexec_in.cmd_use_reg <= '0';
                            iexec_in.cmd <= CMD_ALU;
                            iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                        when OP_TYPE_R | OP_TYPE_I | OP_TYPE_JALR | OP_TYPE_L | OP_TYPE_S =>
                            iexec_in.imm <= sxt(inst_imm_i, 32);
                            iexec_in.cmd_use_reg <= 
                                inst_opcode(3) xor inst_opcode(0);
                            iexec_in.trigger_cxfer <= inst_opcode(4);
                            case inst_opcode is
                            when OP_TYPE_JALR =>
                                iexec_in.cmd <= CMD_JALR;
                            when OP_TYPE_L =>
                                iexec_in.cmd <= CMD_LOAD;
                                iexec_in.cmd_op <= (others => '0'); -- op add
                                iexec_in.rs2 <= "00" & inst_funct3;
                            when OP_TYPE_S =>
                                iexec_in.imm <= 
                                    sxt(inst(31 downto 25) & 
                                        inst(11 downto 7), 32);
                                iexec_in.cmd <= CMD_STORE;
                                iexec_in.cmd_op <= (others => '0'); -- op add
                                iexec_in.rd <= "00" & inst_funct3;
                                iexec_in.cmd_use_reg <= '0';
                            when others =>
                                iexec_in.cmd <= CMD_ALU;
                                iexec_in.cmd_op <= "0" & inst_funct3;
                                if (inst_funct3(1 downto 0) = "01") then
                                    -- SHIFT
                                    iexec_in.cmd <= CMD_SHIFT;
                                    iexec_in.cmd_op <= "00" & inst(30) & inst_funct3(2);
                                elsif(inst_opcode(3) = '1') then
                                    add_ext := inst(30) & inst(25);
                                    case add_ext is
                                        when "10" =>
                                            -- XXX funct3 = 000 check in not
                                            -- needed for spec 2.2 as besides
                                            -- sub there are no other register
                                            -- ALU ops that set bit 30
                                            iexec_in.cmd_op <= CMD_ALU_OP_SUB;
                                        when "01" =>
                                            iexec_in.cmd <= CMD_MULDIV;
                                        when others =>
                                    end case;
                                end if;
                            end case;
                        when OP_TYPE_CSR =>
                            -- XXX What happens if a simulatenous intr_pending
                            -- occurs??
                            if (inst(31 downto 20) = CSR_REG_SWITCH) then
                                exec_valid <= '0';
                                intr_switch <= '1';
                            else
                                iexec_in.csr_reg <= inst(31 downto 20);
                                iexec_in.imm <= ext(inst(19 downto 15), 32);
                                iexec_in.rs2 <= inst_rs1;
                                iexec_in.cmd_use_reg <= not inst_funct3(2);
                                iexec_in.cmd <= CMD_CSR;
                                iexec_in.cmd_op <= "0" & inst_funct3;
                            end if;
                        when others =>
                            -- XXX TODO Raise exception
                            exec_valid <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;
