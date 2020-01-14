library ieee;

use ieee.std_logic_1164.all;

package cpu_types is
    -- XXX as of now this needs to be in (manual) sync with pll.vhd setting
    signal SYS_CLK_FREQ:                integer := 100000000;

    constant OP_TYPE_R:         std_logic_vector(4 downto 0) := "01100";
    constant OP_TYPE_I:         std_logic_vector(4 downto 0) := "00100";
    constant OP_TYPE_L:         std_logic_vector(4 downto 0) := "00000";
    constant OP_TYPE_S:         std_logic_vector(4 downto 0) := "01000";
    constant OP_TYPE_U_AUIPC:   std_logic_vector(4 downto 0) := "00101";
    constant OP_TYPE_U_LUI:     std_logic_vector(4 downto 0) := "01101";
    constant OP_TYPE_B:         std_logic_vector(4 downto 0) := "11000";
    constant OP_TYPE_JAL:       std_logic_vector(4 downto 0) := "11011";
    constant OP_TYPE_JALR:      std_logic_vector(4 downto 0) := "11001";
    constant OP_TYPE_CSR:       std_logic_vector(4 downto 0) := "11100";
    constant OP_TYPE_MISC_MEM:  std_logic_vector(4 downto 0) := "00011";

    constant OP_IFUNCT7_MULDIV: std_logic_vector(6 downto 0) := "0000001";

    constant FUNCT_AOS:         std_logic_vector(2 downto 0) := "000";
    constant FUNCT_SLL:         std_logic_vector(2 downto 0) := "001";
    constant FUNCT_SLT:         std_logic_vector(2 downto 0) := "010";
    constant FUNCT_SLTU:        std_logic_vector(2 downto 0) := "011";
    constant FUNCT_XOR:         std_logic_vector(2 downto 0) := "100";
    constant FUNCT_SRX:         std_logic_vector(2 downto 0) := "101";
    constant FUNCT_OR:          std_logic_vector(2 downto 0) := "110";
    constant FUNCT_AND:         std_logic_vector(2 downto 0) := "111";

    -- INSTRUCTIONS
    constant INST_ADDI_Z_IMM:   std_logic_vector(31 downto 0) := x"00000013";

    -- COMMANDS
    constant CMD_ALU:           std_logic_vector(2 downto 0) := "000";
    constant CMD_SHIFT:         std_logic_vector(2 downto 0) := "001";
    constant CMD_BRANCH:        std_logic_vector(2 downto 0) := "010";
    constant CMD_CSR:           std_logic_vector(2 downto 0) := "011";
    constant CMD_JALR:          std_logic_vector(2 downto 0) := "100";
    constant CMD_LOAD:          std_logic_vector(2 downto 0) := "101";
    constant CMD_STORE:         std_logic_vector(2 downto 0) := "110";
    constant CMD_MULDIV:        std_logic_vector(2 downto 0) := "111";

    constant CMD_ALU_OP_ADD:    std_logic_vector(3 downto 0) := "0000";
    constant CMD_ALU_OP_SUB:    std_logic_vector(3 downto 0) := "1000";

    type idecode_channel_in_t is record
        valid:                  std_logic;
        inst:                   std_logic_vector(31 downto 0);
        pc:                     std_logic_vector(31 downto 0);
    end record;

    type idecode_channel_out_t is record
        busy:                   std_logic;
        cxfer:                  std_logic;
        cxfer_pc:               std_logic_vector(31 downto 0);
    end record;

    type iexec_channel_in_t is record
        valid:                  std_logic;
        cmd:                    std_logic_vector(2 downto 0);
        cmd_op:                 std_logic_vector(3 downto 0);
        cmd_use_reg:            std_logic;
        trigger_cxfer:          std_logic;
        imm:                    std_logic_vector(31 downto 0);
        rs1:                    std_logic_vector(4 downto 0);
        rs2:                    std_logic_vector(4 downto 0);
        rd:                     std_logic_vector(4 downto 0);
        csr_reg:                std_logic_vector(11 downto 0);
        intr_nextpc:            std_logic_vector(31 downto 0);
    end record;

    type iexec_channel_out_t is record
        busy:                   std_logic;
        cxfer:                  std_logic;
        cxfer_pc:               std_logic_vector(31 downto 0);
    end record;

    type csr_channel_in_t is record
        csr_sel_valid:          std_logic;
        csr_sel_reg:            std_logic_vector(11 downto 0);
        csr_sel_op:             std_logic_vector(1 downto 0);

        csr_op_valid:           std_logic;
        csr_op_reg:             std_logic_vector(11 downto 0);
        csr_op_data:            std_logic_vector(31 downto 0);
    end record;

    type intr_channel_out_t is record
        intr_trigger:           std_logic;
        intr_vec:               std_logic_vector(3 downto 0);
    end record;

    type periph_dma_channel_in_t is record
        addr:                   std_logic_vector(24 downto 0);
        read:                   std_logic;
        write:                  std_logic;
        write_data:             std_logic_vector(7 downto 0);
    end record;

    type periph_dma_channel_out_t is record
        read_data:              std_logic_vector(7 downto 0);
    end record;

end package;
