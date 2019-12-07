library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant BOOTCODE_LOAD_ADDR:    std_logic_vector(31 downto 0) := x"00000000";
constant IVECTOR_RESET_ADDR:    std_logic_vector(31 downto 0) := x"00000000";

--
-- isrs are placed at 32 byte intervals (8 instruction invervals)
-- BOOT_OFFSET is at 0x10 instead of 0x00 because the minimal IVECTOR, 
-- 16 bytes in size, is stored at 0x00 on startup 
-- Hitherto: the minimal IVECTOR contains only one entry (BOOT_OFFSET) hence
-- the bootcode should relocate and setup IVECTOR as early as feasible
--

constant BOOT_OFFSET:                   std_logic_vector(7 downto 0) := x"10";
constant EXN_TLB_ABSENT:                std_logic_vector(7 downto 0) := x"20";
-- constant EXN_UNALIGNED_PC_OFFSET:       std_logic_vector(7 downto 0) := x"20";
-- constant EXN_UNKNOWN_INSTR_OFFSET:      std_logic_vector(7 downto 0) := x"30";
-- constant INTR_TIMER_OFFSET:             std_logic_vector(7 downto 0) := x"40";
-- constant INTR_UART_OFFSET:              std_logic_vector(7 downto 0) := x"50";

end package;
