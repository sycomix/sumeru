library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_idecode is
port(
    sys_clk:                    in std_logic;
    idecode_in:                 in idecode_channel_in_t;
    idecode_out:                out idecode_channel_out_t;
    iexec_in:                   out iexec_channel_in_t;
    iexec_out:                  in iexec_channel_out_decode_t
    );
end entity;


architecture synth of cpu_stage_idecode is
    signal decode_busy: std_logic := '0';
    signal exec_valid:  std_logic := '0';
    signal rs1:         std_logic_vector(4 downto 0) := (others => '0');
    signal rs2:         std_logic_vector(4 downto 0) := (others => '0');
    signal rd:          std_logic_vector(4 downto 0) := (others => '0');

    alias exec_busy:    std_logic is iexec_out.busy;
    alias fetch_valid:  std_logic is idecode_in.valid;
    alias inst:         std_logic_vector(31 downto 0) is idecode_in.inst;
    alias inst_opcode:  std_logic_vector(4 downto 0) is inst(6 downto 2);
    alias inst_funct3:  std_logic_vector(2 downto 0) is inst(14 downto 12);
    alias inst_rs1:     std_logic_vector(4 downto 0) is inst(19 downto 15);
    alias inst_rs2:     std_logic_vector(4 downto 0) is inst(24 downto 20);
    alias inst_rd:      std_logic_vector(4 downto 0) is inst(11 downto 7);
    alias inst_imm_i:   std_logic_vector(11 downto 0) is inst(31 downto 20);

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
    idecode_out.busy <= decode_busy;
    iexec_in.valid <= exec_valid;
    iexec_in.rs1 <= rs1;
    iexec_in.rs2 <= rs2;
    iexec_in.rd <= rd;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            if (exec_busy = '0') then
                decode_busy <= '0';
                exec_valid <= fetch_valid;
                if (fetch_valid = '1') then
                    -- DO DECODE
                    rs1 <= inst_rs1;
                    rs2 <= inst_rs2;
                    rd <= inst_rd;
                    case inst_opcode is
                        when OP_TYPE_R | OP_TYPE_I =>
                            iexec_in.imm <= sxt(inst_imm_i, 32);
                            iexec_in.cmd_use_imm <= not inst(5);
                            if (inst_funct3 = "000" and inst(30) = '1') then
                                -- SUBTRACT
                                iexec_in.cmd <= CMD_ALU;
                                iexec_in.cmd_op <= CMD_ALU_OP_SUB;
                            elsif (inst_funct3(1 downto 0) = "01") then
                                -- SHIFT
                                iexec_in.cmd <= CMD_SHIFT;
                                iexec_in.cmd_op <= "00" & inst(30) & inst_funct3(2);
                            else
                                iexec_in.cmd <= CMD_ALU;
                                iexec_in.cmd_op <= "0" & inst_funct3;
                            end if;
                        when others =>
                            iexec_in.cmd <= CMD_UNKNOWN;
                            iexec_in.cmd_op <= (others => '0');
                    end case;
                end if;
            else
                decode_busy <= idecode_in.valid;
            end if;
        end if;
    end process;

end architecture;
