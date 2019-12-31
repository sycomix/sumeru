library ieee;

use ieee.std_logic_1164.all;

package sumeru_constants is

constant IVECTOR_RESET_ADDR:    std_logic_vector(23 downto 0) := x"000000";

constant IVECTOR_ENTRY_BOOT:    std_logic_vector(3 downto 0) := x"0";
constant IVECTOR_ENTRY_TIMER:   std_logic_vector(3 downto 0) := x"1";

end package;
