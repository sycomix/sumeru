library ieee;

use ieee.std_logic_1164.all;

package memory_channel_types is

type mem_channel_in_t is record
    op_addr:            std_logic_vector(23 downto 0);
    op_start:           std_logic;
    op_wren:            std_logic;
    op_burst:           std_logic;
    op_dqm:             std_logic_vector(1 downto 0);
    write_data:         std_logic_vector(15 downto 0);
end record;

type mem_channel_out_t is record
    op_strobe:          std_logic;
end record;

end package;
