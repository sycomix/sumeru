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
    ctx_pc_save:                out std_logic_vector(31 downto 0);
    ctx_pc_switch:              out std_logic_vector(31 downto 0)
    );
end entity;


architecture synth of cpu_stage_idecode is
signal pc_r:        std_logic_vector(31 downto 0);
signal inst_r:      std_logic_vector(31 downto 0);

signal exec_valid:  std_logic := '0';

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

idecode_out.busy <= exec_busy;

idecode_out.cxfer <= iexec_out.cxfer;
idecode_out.cxfer_pc <= iexec_out.cxfer_pc;
iexec_in.valid <= exec_valid;
iexec_in.pc_p4 <= std_logic_vector(unsigned(pc) + 4);
iexec_in.csr_reg <= inst(31 downto 20);
iexec_in.rd <= "00" & inst_funct3 when inst_opcode = OP_TYPE_S else inst_rd;

process(all)
begin
        case inst_opcode is 
            when OP_TYPE_L =>
                iexec_in.rs2 <= "00" & inst_funct3;
            when OP_TYPE_CSR =>
                iexec_in.rs2 <= inst_rs1;
            when others =>
                iexec_in.rs2 <= inst_rs2;
        end case;
end process;

process(all)
begin
        case inst_opcode is 
            when OP_TYPE_JAL | OP_TYPE_U_LUI | OP_TYPE_U_AUIPC =>
                iexec_in.rs1 <= (others => '0');
            when others =>
                iexec_in.rs1 <= inst_rs1;
        end case;
end process;




process(all)
    variable add_ext: std_logic_vector(1 downto 0);
begin
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
                iexec_in.cmd_use_reg <= '0';
            when OP_TYPE_CSR =>
                iexec_in.cmd <= CMD_CSR;
                iexec_in.cmd_op <= "0" & inst_funct3;
                iexec_in.cmd_use_reg <= not inst_funct3(2);
            when others =>      -- OP_TYPE_R | OP_TYPE_I
                iexec_in.cmd_use_reg <= inst_opcode(3);
                if (inst_funct3(1 downto 0) = "01") then
                    iexec_in.cmd <= CMD_SHIFT;
                    iexec_in.cmd_op <= "00" & inst(30) & inst_funct3(2);
                elsif (inst_opcode(3) = '1') then
                    add_ext := inst(30) & inst(25);
                    case add_ext is
                        when "10" =>
                            -- XXX funct3 = 000 check in not
                            -- needed for spec 2.2 as besides
                            -- sub there are no other register
                            -- ALU ops that set bit 30
                            iexec_in.cmd <= CMD_ALU;
                            iexec_in.cmd_op <= CMD_ALU_OP_SUB;
                        when "01" =>
                            iexec_in.cmd <= CMD_MULDIV;
                            iexec_in.cmd_op <= "0" & inst_funct3;
                        when others =>
                            iexec_in.cmd <= CMD_ALU;
                            iexec_in.cmd_op <= "0" & inst_funct3;
                    end case;
                else
                    iexec_in.cmd <= CMD_ALU;
                    iexec_in.cmd_op <= "0" & inst_funct3;
                end if;
        end case;
end process;


process(all)
begin
            case inst_opcode is 
                when OP_TYPE_B =>
                    iexec_in.imm <= std_logic_vector(
                                        signed(pc) + signed(inst(31) & inst(7) & 
                                        inst(30 downto 25) & 
                                        inst(11 downto 8) & "0"));
                when OP_TYPE_JAL  =>
                    iexec_in.imm <= std_logic_vector(unsigned(pc) + 4);
                when OP_TYPE_U_LUI =>
                    iexec_in.imm <= inst_imm_ui & "000000000000";
                when OP_TYPE_U_AUIPC =>
                    iexec_in.imm <= 
                        std_logic_vector(unsigned(pc) + 
                        unsigned(inst_imm_ui & "000000000000"));
                when OP_TYPE_R | OP_TYPE_I | OP_TYPE_JALR | OP_TYPE_L =>
                    iexec_in.imm <= sxt(inst_imm_i, 32);
                when OP_TYPE_S =>
                    iexec_in.imm <= sxt(inst(31 downto 25) & inst(11 downto 7), 32);
                when others =>             -- OP_TYPE_CSR and others
                    iexec_in.imm <= ext(inst(19 downto 15), 32);
            end case;
end process;


process(clk)
begin
    if (rising_edge(clk)) then
        if (iexec_out.cxfer = '1') then
            exec_valid <= '0';
        elsif (exec_busy = '0') then
            if (fetch_valid = '1') then
                pc_r <= idecode_in.pc;
                inst_r <= idecode_in.inst;
                exec_valid <= '1';
                if (idecode_in.inst(6 downto 2) = OP_TYPE_JALR) then
                    iexec_in.trigger_cxfer <= '1';
                else
                    iexec_in.trigger_cxfer <= '0';
                end if;
            else
                exec_valid <= '0';
            end if;
        end if;
    end if;
end process;

end architecture;
