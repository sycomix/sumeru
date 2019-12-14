library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_iexec is
port(
    sys_clk:                    in std_logic;
    cache_clk:                  in std_logic;
    iexec_in:                   in iexec_channel_in_t;
    iexec_out_fetch:            out iexec_channel_out_fetch_t;
    iexec_out_decode:           out iexec_channel_out_decode_t
    );
end entity;

architecture synth of cpu_stage_iexec is
    signal regfile_wren:        std_logic := '0';
    signal rd_write_data:       std_logic_vector(31 downto 0) := (others => '0');
    signal rs1_read_data:       std_logic_vector(31 downto 0);
    signal rs2_read_data:       std_logic_vector(31 downto 0);
    signal rs1_data:            std_logic_vector(31 downto 0);
    signal rs2_data:            std_logic_vector(31 downto 0);
    signal operand2:            std_logic_vector(31 downto 0);
    signal last_rd:             std_logic_vector(4 downto 0) := (others => '0');
    signal last_rd_data:        std_logic_vector(4 downto 0) := (others => '0');

begin
    regfile_a: entity work.ram2p_simp_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs1,
            wraddress => iexec_in.rd,
            wren => regfile_wren,
            q => rs1_read_data);

    regfile_b: entity work.ram2p_simp_32x32
        port map(
            clock => cache_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs2,
            wraddress => iexec_in.rd,
            wren => regfile_wren,
            q => rs2_read_data);

    rs1_data <=  
        last_rd_data when last_rd = iexec_in.rs1 else rs1_read_data;

    rs2_data <=
        last_rd_data when last_rd = iexec_in.rs2 else rs2_read_data;

    operand2 <= 
        iexec_in.imm when iexec_in.cmd_use_imm = '1' else rs2_data;

    alu: entity cpu_alu
        port map(
            a => rs1_data,
            b => operand2,
            result => alu_result);

    rd_write_data <= 
        alu_result when iexec_in.cmd = CMD_ALU;

    iexec_out_fetch <= ('0', '0', (others =>'0'));
    iexec_out_decode <= ('0', '0');


--    process(sys_clk)
--    begin
--        if (rising_edge(sys_clk)) then
--        end if;
--    end process;

end architecture;
