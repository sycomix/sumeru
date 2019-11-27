library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant BOOTCODE_LOAD_ADDR:    std_logic_vector(31 downto 0) := x"00000000";
constant IVECTOR_RESET_ADDR:    std_logic_vector(31 downto 0) := x"00000000";

-- isr are place at 32 byte intervals (8 instruction invervals)
constant BOOT_OFFSET:                   std_logic_vector(7 downto 0) := x"00";
constant EXN_UNALIGNED_PC_OFFSET:       std_logic_vector(7 downto 0)  := x"10";
constant EXN_UNKNOWN_INSTR_OFFSET:      std_logic_vector(7 downto 0) := x"20";
constant INTR_TIMER_OFFSET:             std_logic_vector(7 downto 0) := x"30";
constant INTR_UART_OFFSET:              std_logic_vector(7 downto 0) := x"40";

end package;
