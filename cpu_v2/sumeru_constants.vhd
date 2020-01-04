library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant IVECTOR_RESET_ADDR:    std_logic_vector(23 downto 0) := x"000000";

constant IVECTOR_ENTRY_BOOT:    std_logic_vector(3 downto 0) := x"0";
constant IVECTOR_ENTRY_TIMER:   std_logic_vector(3 downto 0) := x"1";

constant CSR_REG_GPIO_DIR:     std_logic_vector(11 downto 0) := "0000" & "0000" & "1000";
constant CSR_REG_GPIO_OUTPUT:  std_logic_vector(11 downto 0) := "0000" & "0000" & "1001";
constant CSR_REG_GPIO_INPUT:   std_logic_vector(11 downto 0) := "1100" & "0000" & "0001";
 
constant CSR_REG_TIMER_CTRL:   std_logic_vector(11 downto 0) := "0000" & "0000" & "1010";
constant CSR_REG_TIMER_VALUE:  std_logic_vector(11 downto 0) := "1100" & "0000" & "0010";

constant CSR_REG_CTR_CYCLE:    std_logic_vector(11 downto 0) := "1100" & "1000" & "0000";
constant CSR_REG_CTR_CYCLE_H:  std_logic_vector(11 downto 0) := "1100" & "1000" & "1000";
constant CSR_REG_CTR_INSTRET:  std_logic_vector(11 downto 0) := "1100" & "1000" & "0001";
constant CSR_REG_CTR_INSTRET_H: std_logic_vector(11 downto 0):= "1100" & "1000" & "1001";
constant CSR_REG_CTX_PCSAVE:     std_logic_vector(11 downto 0) := "1100" & "1000" & "0010";

constant CSR_REG_CTX_PCSWITCH:   std_logic_vector(11 downto 0) := "1000" & "0000" & "0000";
constant CSR_REG_SWITCH:         std_logic_vector(11 downto 0) := "1000" & "0000" & "0001";

end package;
