library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant IVEC_TIMER:            std_logic_vector(3 downto 0) := "0001";
constant IVEC_UART0_TX:         std_logic_vector(3 downto 0) := "0010";
constant IVEC_UART0_RX:         std_logic_vector(3 downto 0) := "0011";

constant CSR_REG_GPIO_DIR:      std_logic_vector(11 downto 0) := x"881";
constant CSR_REG_GPIO_OUTPUT:   std_logic_vector(11 downto 0) := x"882";
constant CSR_REG_GPIO_INPUT:    std_logic_vector(11 downto 0) := x"CC1";
 
constant CSR_REG_TIMER_CTRL:    std_logic_vector(11 downto 0) := x"884";
constant CSR_REG_TIMER_VALUE:   std_logic_vector(11 downto 0) := x"CC2";

constant CSR_REG_CTR_CYCLE:     std_logic_vector(11 downto 0) := x"C00";
constant CSR_REG_CTR_CYCLE_H:   std_logic_vector(11 downto 0) := x"C80";
constant CSR_REG_CTR_TIME:      std_logic_vector(11 downto 0) := x"C01";
constant CSR_REG_CTR_TIME_H:    std_logic_vector(11 downto 0) := x"C81";
constant CSR_REG_CTR_INSTRET:   std_logic_vector(11 downto 0) := x"C02";
constant CSR_REG_CTR_INSTRET_H: std_logic_vector(11 downto 0) := x"C82";

constant CSR_REG_CTX_PCSAVE:    std_logic_vector(11 downto 0) := x"CC0";
constant CSR_REG_CTX_PCSWITCH:  std_logic_vector(11 downto 0) := x"880";
constant CSR_REG_SWITCH:        std_logic_vector(11 downto 0) := x"9C0";
constant CSR_REG_IVECTOR_ADDR:  std_logic_vector(11 downto 0) := x"9C1";

constant CSR_REG_UART0_RX:      std_logic_vector(11 downto 0) := x"888";
constant CSR_REG_UART0_TX:      std_logic_vector(11 downto 0) := x"889";

end package;
