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
signal pc_r:        std_logic_vector(31 downto 0);
signal inst_r:      std_logic_vector(31 downto 0);

signal exec_valid:  std_logic := '0';
signal intr_trigger_save:   std_logic := '0';
signal intr_pending: std_logic := '0';
signal intr_switch: std_logic;

alias exec_busy:    std_logic is iexec_out.busy;
alias fetch_valid:  std_logic is idecode_in.valid;
alias pc:           std_logic_vector(31 downto 0) is pc_r;
alias inst:         std_logic_vector(31 downto 0) is inst_r;
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

-- XXX This condition should fix the intr and switch issue where we want
-- to be busy but also need the address of the next instruction
idecode_out.busy <= exec_busy or (intr_pending and fetch_valid);

idecode_out.cxfer <= iexec_out.cxfer;
idecode_out.cxfer_pc <= iexec_out.cxfer_pc;
iexec_in.valid <= exec_valid;
iexec_in.pc_p4 <= std_logic_vector(unsigned(pc) + 4);
iexec_in.csr_reg <= inst(31 downto 20);
iexec_in.rd <= "00" & inst_funct3 when inst_opcode = OP_TYPE_S else inst_rd;

process(inst_opcode)
begin
    if (inst_opcode'event) then
        case inst_opcode is 
            when OP_TYPE_L =>
                iexec_in.rs2 <= "00" & inst_funct3;
            when OP_TYPE_S =>
                iexec_in.rs2 <= inst_rs1;
            when others =>
                iexec_in.rs2 <= inst_rs2;
        end case;
    end if;
end process;

process(inst_opcode)
begin
    if (inst_opcode'event) then
        case inst_opcode is 
            when OP_TYPE_JAL | OP_TYPE_U_LUI | OP_TYPE_U_AUIPC =>
                iexec_in.rs1 <= (others => '0');
            when others =>
                iexec_in.rs1 <= inst_rs1;
        end case;
    end if;
end process;




process(inst_opcode)
begin
    if (inst_opcode'event) then
        case inst_opcode is 
            when OP_TYPE_B =>
                iexec_in.cmd <= CMD_BRANCH;
                iexec_in.cmd_op <= "0" & inst_funct3;
                iexec_in.cmd_use_reg <= '1';
            when OP_TYPE_JAL | OP_TYPE_U_LUI | OP_TYPE_U_AUIPC =>
                iexec_in.cmd <= CMD_ALU;
                iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                iexec_in.cmd_use_reg <= '0';
            when OP_TYPE_JALR =>
                iexec_in.cmd <= CMD_JALR;
                iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                iexec_in.cmd_use_reg <= '0';
            when OP_TYPE_L =>
                iexec_in.cmd <= CMD_LOAD;
                iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                iexec_in.cmd_use_reg <= '0';
            when OP_TYPE_S =>
                iexec_in.cmd <= CMD_STORE;
                iexec_in.cmd_op <= CMD_ALU_OP_ADD;
                iexec_in.cmd_use_reg <= '1';
            when others =>      -- OP_TYPE_R | OP_TYPE_I
                iexec_in.cmd <= CMD_ALU;
                iexec_in.cmd_op <= "0" & inst_funct3;
                iexec_in.cmd_use_reg <= inst_opcode(3);
        end case;
    end if;
end process;


process(inst_opcode)
begin
    if (inst_opcode'event) then
        case inst_opcode is 
            when OP_TYPE_B =>
                iexec_in.imm <= std_logic_vector(
                                    signed(pc) + signed(inst(31) & inst(7) & 
                                    inst(30 downto 25) & 
                                    inst(11 downto 8) & "0"));
            when OP_TYPE_JAL  =>
                iexec_in.imm <= std_logic_vector(unsigned(pc) + 4);
            when OP_TYPE_U_LUI =>
                iexec_in.imm <= 
                    std_logic_vector(unsigned(pc) + 
                    unsigned(inst_imm_ui & "000000000000"));
            when OP_TYPE_U_AUIPC =>
                iexec_in.imm <= inst_imm_ui & "000000000000";
            when OP_TYPE_R | OP_TYPE_I | OP_TYPE_JALR | OP_TYPE_L =>
                iexec_in.imm <= sxt(inst_imm_i, 32);
            when OP_TYPE_S =>
                iexec_in.imm <= sxt(inst(31 downto 25) & inst(11 downto 7), 32);
            when others =>             -- OP_TYPE_CSR and others
                iexec_in.imm <= ext(inst(19 downto 15), 32);
        end case;
    end if;
end process;


process(clk)
begin
    if (rising_edge(clk)) then
        if (iexec_out.cxfer = '1') then
            exec_valid <= '0';
            -- A switch is invalidated by cxfer as we don't want it
            -- to trigger after the cxfer
            intr_switch <= '0';
            iexec_in.trigger_cxfer <= '0';
        elsif (intr_pending = '1') then
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
                iexec_in.trigger_cxfer <= '1';
                pc_r <= (others => '0');
                inst_r <= INST_ADDI_Z_IMM;
                ctx_pc_save <= idecode_in.pc;
                intr_pending <= '0';
            else
                exec_valid <= '0';
                iexec_in.trigger_cxfer <= '0';
            end if;
        elsif (fetch_valid = '1' and exec_busy = '0') then
            exec_valid <= '1';
            pc_r <= idecode_in.pc;
            inst_r <= idecode_in.inst;

            if (idecode_in.inst(6 downto 2) = OP_TYPE_JALR or
                idecode_in.inst(6 downto 2) = OP_TYPE_B) 
            then
                iexec_in.trigger_cxfer <= '1';
            else
                iexec_in.trigger_cxfer <= '0';
            end if;

            if (idecode_in.inst(31 downto 20) = CSR_REG_SWITCH) then
                exec_valid <= '0';
                intr_switch <= '1';
                intr_pending <= '1';
            elsif (intr_out.intr_trigger /= intr_trigger_save) then
                intr_trigger_save <= not intr_trigger_save;
                intr_switch <= '0';
                intr_pending <= '1';
            end if;
        else
            iexec_in.trigger_cxfer <= '0';
        end if;
    end if;
end process;

end architecture;
