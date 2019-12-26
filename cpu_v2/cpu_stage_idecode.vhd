library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    clk:                        in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t;
    iexec_in:                   out iexec_channel_in_t;
    iexec_out:                  in iexec_channel_out_t
    );
end entity;


architecture synth of cpu_stage_idecode is
    signal exec_valid:  std_logic := '0';

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
    idecode_out.busy <= exec_busy;
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
    begin
        if (rising_edge(clk)) then
            if (iexec_out.cxfer = '1') then
                exec_valid <= '0';
            elsif (exec_busy = '0') then
                exec_valid <= fetch_valid;
                if (fetch_valid = '1') then
                    -- DO DECODE
                    iexec_in.rs1 <= inst_rs1;
                    iexec_in.rs2 <= inst_rs2;
                    iexec_in.rd <= inst_rd;
                    iexec_in.trigger_cxfer <= '0';
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
                        when OP_TYPE_R | OP_TYPE_I | OP_TYPE_JALR | OP_TYPE_L =>
                            iexec_in.imm <= sxt(inst_imm_i, 32);
                            iexec_in.cmd_use_reg <= inst_opcode(3);
                            iexec_in.trigger_cxfer <= inst_opcode(4);
                            if (inst_opcode = OP_TYPE_L) then 
                                iexec_in.cmd <= CMD_LOAD;
                                iexec_in.cmd_op <= (others => '0'); -- op add
                                iexec_in.rs2 <= "00" & inst_funct3;
                            else
                                iexec_in.cmd <= CMD_ALU;
                                iexec_in.cmd_op <= "0" & inst_funct3;
                                if (inst_funct3 = "000") then
                                    -- SUBTRACT
                                    if(inst_opcode(3) = '1' and inst(30) = '1') then
                                        iexec_in.cmd_op <= CMD_ALU_OP_SUB;
                                    end if;
                                elsif (inst_funct3(1 downto 0) = "01") then
                                    -- SHIFT
                                    iexec_in.cmd <= CMD_SHIFT;
                                    iexec_in.cmd_op <= "00" & inst(30) & inst_funct3(2);
                                end if;
                            end if;
                        when OP_TYPE_CSR =>
                            iexec_in.csr_reg <= inst(31 downto 20);
                            iexec_in.imm <= ext(inst(19 downto 15), 32);
                            iexec_in.rs2 <= inst_rs1;
                            iexec_in.cmd_use_reg <= not inst_funct3(2);
                            iexec_in.cmd <= CMD_CSR;
                            iexec_in.cmd_op <= "0" & inst_funct3;
                        when others =>
                            iexec_in.cmd <= CMD_UNKNOWN;
                            iexec_in.cmd_op <= (others => '0');
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;
