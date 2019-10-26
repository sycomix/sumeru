library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity register_file is
port(
        cache_clk:              in std_logic;
        rs1:                    in std_logic_vector(4 downto 0);
        rs2:                    in std_logic_vector(4 downto 0);
        rd:                     in std_logic_vector(4 downto 0);

        rs1_read_data:          out std_logic_vector(31 downto 0);
        rs2_read_data:          out std_logic_vector(31 downto 0);
        rd_write_data:          in std_logic_vector(31 downto 0);
        rd_wren:                in std_logic
    );
end entity;

architecture synth of register_file is
    signal rs1_data:    std_logic_vector(31 downto 0);
    signal rs2_data:    std_logic_vector(31 downto 0);
begin

    bank0: entity work.ram2p_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => rs1,
            wraddress => rd,
            wren => rd_wren,
            q => rs1_data);

    bank1: entity work.ram2p_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => rs2,
            wraddress => rd,
            wren => rd_wren,
            q => rs2_data);

    rs1_read_data <= rd_write_data when rs1 = rd else rs1_data;
    rs2_read_data <= rd_write_data when rs2 = rd else rs2_data;

end architecture;


