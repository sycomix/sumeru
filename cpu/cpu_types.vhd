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

    -- META COMMANDS
    constant META_CMD_BASIC:    std_logic_vector(3 downto 0) := "0000";
    constant META_CMD_LOAD:     std_logic_vector(3 downto 0) := "0001";
    constant META_CMD_STORE:    std_logic_vector(3 downto 0) := "0010";
    constant META_CMD_BRANCH:   std_logic_vector(3 downto 0) := "0011";
    constant META_CMD_JALR:     std_logic_vector(3 downto 0) := "0100";
    constant META_CMD_MISC:     std_logic_vector(3 downto 0) := "0101";
    constant META_CMD_CSRXXX:   std_logic_vector(3 downto 0) := "0110";
    constant META_CMD_MULDIV:   std_logic_vector(3 downto 0) := "1000";
    constant META_CMD_CLFLUSH:  std_logic_vector(3 downto 0) := "1001";
    constant META_CMD_EXCEPTION: std_logic_vector(3 downto 0) := "1111";

    -- COMMANDS

    constant CMD_ADD:           std_logic_vector(3 downto 0) := "0000";
    constant CMD_SUB:           std_logic_vector(3 downto 0) := "1000";
    constant CMD_SLL:           std_logic_vector(3 downto 0) := "0001";
    constant CMD_SLT:           std_logic_vector(3 downto 0) := "0010";
    constant CMD_SLTU:          std_logic_vector(3 downto 0) := "0011";
    constant CMD_XOR:           std_logic_vector(3 downto 0) := "0100";
    constant CMD_SRL:           std_logic_vector(3 downto 0) := "0101";
    constant CMD_SRA:           std_logic_vector(3 downto 0) := "1101";
    constant CMD_OR:            std_logic_vector(3 downto 0) := "0110";
    constant CMD_AND:           std_logic_vector(3 downto 0) := "0111";

    constant CMD_BR_EQ:         std_logic_vector(3 downto 0) := "0000";
    constant CMD_BR_NE:         std_logic_vector(3 downto 0) := "0001";
    constant CMD_BR_LT:         std_logic_vector(3 downto 0) := "0100";
    constant CMD_BR_GE:         std_logic_vector(3 downto 0) := "0101";
    constant CMD_BR_LTU:        std_logic_vector(3 downto 0) := "0110";
    constant CMD_BR_GEU:        std_logic_vector(3 downto 0) := "0111";

    constant CMD_LOAD_B:        std_logic_vector(3 downto 0) := "0000";
    constant CMD_LOAD_H:        std_logic_vector(3 downto 0) := "0001";
    constant CMD_LOAD_W:        std_logic_vector(3 downto 0) := "0010";
    constant CMD_LOAD_BU:       std_logic_vector(3 downto 0) := "0100";
    constant CMD_LOAD_HU:       std_logic_vector(3 downto 0) := "0101";

    constant CMD_STORE_B:       std_logic_vector(3 downto 0) := "0000";
    constant CMD_STORE_H:       std_logic_vector(3 downto 0) := "0001";
    constant CMD_STORE_W:       std_logic_vector(3 downto 0) := "0010";

    constant CMD_JALR:          std_logic_vector(3 downto 0) := "0000";

    constant CMD_ENV:           std_logic_vector(3 downto 0) := "0000";
    constant CMD_WR_RS2:        std_logic_vector(3 downto 0) := "0001";
    -- XUI and JAL are both mapped to WR_RS2 (write rs2)
    -- constant CMD_XUI:           std_logic_vector(3 downto 0) := "0001";
    -- constant CMD_JAL:           std_logic_vector(5 downto 0) := "0010";

    constant CMD_CSRW:          std_logic_vector(3 downto 0) := "0001";
    constant CMD_CSRRS:         std_logic_vector(3 downto 0) := "0010";
    constant CMD_CSRRC:         std_logic_vector(3 downto 0) := "0011";
    constant CMD_CSRRWI:        std_logic_vector(3 downto 0) := "0101";
    constant CMD_CSRRSI:        std_logic_vector(3 downto 0) := "0110";
    constant CMD_CSRRCI:        std_logic_vector(3 downto 0) := "0111";

    constant CMD_MUL:           std_logic_vector(3 downto 0) := "0000";
    constant CMD_MULH:          std_logic_vector(3 downto 0) := "0001";
    constant CMD_MULHSU:        std_logic_vector(3 downto 0) := "0010";
    constant CMD_MULHU:         std_logic_vector(3 downto 0) := "0011";
    constant CMD_DIV:           std_logic_vector(3 downto 0) := "0100";
    constant CMD_DIVU:          std_logic_vector(3 downto 0) := "0101";
    constant CMD_REM:           std_logic_vector(3 downto 0) := "0110";
    constant CMD_REMU:          std_logic_vector(3 downto 0) := "0111";

    type ifetch_channel_in_t is record
        raise_intr:             std_logic;
        intr_idx:               std_logic_vector(7 downto 0);
    end record;

    type idecode_channel_in_t is record
        valid:                  std_logic;
        inst:                   std_logic_vector(31 downto 0);
        inst_data:              std_logic_vector(31 downto 0);
    end record;

    type idecode_channel_out_t is record
        busy:                   std_logic;
    end record;

    type iexec_channel_out_t is record
        cxfer_valid:            std_logic;
        cxfer_taken:            std_logic;
        raise_switch:           std_logic;
        switch_pc:              std_logic_vector(31 downto 0);
    end record;
end package;
