library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant CSR_REG_GPIO_DIR:     std_logic_vector(11 downto 0) := "0000" & "0000" & "1000";
constant CSR_REG_GPIO_OUTPUT:  std_logic_vector(11 downto 0) := "0000" & "0000" & "1001";
constant CSR_REG_GPIO_INPUT:   std_logic_vector(11 downto 0) := "1100" & "0000" & "0001";

end package;
