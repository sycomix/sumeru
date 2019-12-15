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
    signal regfile_wraddr:      std_logic_vector(4 downto 0) := (others => '0');
    signal last_rd:             std_logic_vector(4 downto 0) := (others => '0');
    signal last_rd_data:        std_logic_vector(31 downto 0) := (others => '0');
    signal alu_result:          std_logic_vector(31 downto 0);
    signal cmd_result_mux:      std_logic_vector(2 downto 0) := (others => '0');

begin
    regfile_a: entity work.ram2p_simp_32x32
        port map(
            rdclock => cache_clk,
            wrclock => sys_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs1,
            wraddress => regfile_wraddr,
            wren => regfile_wren,
            q => rs1_read_data);

    regfile_b: entity work.ram2p_simp_32x32
        port map(
            rdclock => cache_clk,
            wrclock => sys_clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs2,
            wraddress => regfile_wraddr,
            wren => regfile_wren,
            q => rs2_read_data);

    rs1_data <=  
        last_rd_data when last_rd = iexec_in.rs1 else rs1_read_data;

    rs2_data <=
        last_rd_data when last_rd = iexec_in.rs2 else rs2_read_data;

    operand2 <= 
        iexec_in.imm when iexec_in.cmd_use_imm = '1' else rs2_data;

    alu: entity work.cpu_alu
        port map(
            sys_clk => sys_clk,
            a => rs1_data,
            b => operand2,
            op => iexec_in.cmd_op,
            result => alu_result);

    rd_write_data <= 
        alu_result when cmd_result_mux = CMD_ALU;

    process(cache_clk)
    begin
        if (rising_edge(cache_clk) and regfile_wren = '1') then
            last_rd_data <= rd_write_data;
            last_rd <= regfile_wraddr;
        end if;
    end process;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            regfile_wren <= '0';
            if (iexec_in.valid = '1')  then
                cmd_result_mux <= iexec_in.cmd;
                if (iexec_in.cmd = CMD_ALU) then
                    regfile_wraddr <= iexec_in.rd;
                    regfile_wren <= 
                        iexec_in.rd(0) or iexec_in.rd(1) or 
                        iexec_in.rd(2) or iexec_in.rd(3) or iexec_in.rd(4);
                end if;
            end if;
        end if;
    end process;

    iexec_out_fetch <= ('0', '0', (others =>'0'));
    iexec_out_decode <= ('0', '0');


end architecture;
