library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;

entity cpu_stage_iexec is
port(
    sys_clk:                    in std_logic;
    cache_clk:                  in std_logic;
    latch_clk:                  in std_logic;
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

    signal shift_result:        std_logic_vector(31 downto 0);
    signal cxfer_sync_strobe:   std_logic := '0';
    signal cxfer_async_strobe:  std_logic := '0';
    signal cxfer_mux:           std_logic := '0';
    signal cxfer_async_pc:      std_logic_vector(31 downto 0);
    signal skip_cycle:          std_logic := '0';

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
        rs2_data when iexec_in.cmd_use_reg = '1' else iexec_in.imm;

    alu: entity work.cpu_alu
        port map(
            sys_clk => sys_clk,
            a => rs1_data,
            b => operand2,
            op => iexec_in.cmd_op,
            result => alu_result);

    shift: entity work.cpu_shift
        port map(
            sys_clk => sys_clk,
            shift_data => rs1_data,
            shift_amt => operand2(4 downto 0),
            shift_bit => iexec_in.cmd_op(1),
            shift_dir_lr => iexec_in.cmd_op(0),
            shift_result => shift_result);

    with cmd_result_mux select rd_write_data <=
        alu_result when CMD_ALU,
        shift_result when others;

    process(latch_clk)
    begin
        -- XXX Adjust latch_clk to be optimal
        if (rising_edge(latch_clk) and regfile_wren = '1') then
            last_rd_data <= rd_write_data;
            last_rd <= regfile_wraddr;
        end if;
    end process;

    iexec_out_fetch.cxfer_async_strobe <= cxfer_async_strobe;
    iexec_out_decode.cxfer_async_strobe <= cxfer_async_strobe;
    iexec_out_fetch.cxfer_sync_strobe <= cxfer_sync_strobe;
    iexec_out_fetch.cxfer_pc <= 
        alu_result when cxfer_mux = '0' else cxfer_async_pc;

    process(sys_clk)
        variable br: std_logic;
    begin
        if (rising_edge(sys_clk)) then
            regfile_wren <= '0';
            skip_cycle <= '0';
            if (iexec_in.valid = '1' and skip_cycle = '0')  then
                -- set mux to alu or branch
                if (iexec_in.cmd = CMD_ALU) then
                    cxfer_mux <= '0';
                else
                    cxfer_mux <= '1';
                end if;
                if (iexec_in.strobe_cxfer_sync = '1') then
                    cxfer_sync_strobe <= not cxfer_sync_strobe;
                end if;
                cmd_result_mux <= iexec_in.cmd;
                case iexec_in.cmd is
                    when CMD_ALU | CMD_SHIFT =>
                        regfile_wraddr <= iexec_in.rd;
                        regfile_wren <= 
                            iexec_in.rd(0) or iexec_in.rd(1) or 
                            iexec_in.rd(2) or iexec_in.rd(3) or iexec_in.rd(4);
                    when CMD_BRANCH =>
                        case iexec_in.cmd_op(2 downto 1) is
                            when "00" =>
                                if (rs1_data = rs2_data) then
                                    br := '1';
                                else
                                    br := '0';
                                end if;
                            when "10" =>
                                if (signed(rs1_data) < signed(rs2_data)) then
                                    br := '1';
                                else
                                    br := '0';
                                end if;
                            when others =>
                                if (unsigned(rs1_data) < unsigned(rs2_data)) then
                                    br := '1';
                                else
                                    br := '0';
                                end if;
                        end case;
                        if ((br xor iexec_in.cmd_op(0)) = '1') then
                            -- BRANCH TAKEN
                            cxfer_async_strobe <= not cxfer_async_strobe;
                            cxfer_async_pc <= iexec_in.imm;
                            -- skip the next cycle as there maybe a valid
                            -- decode command pending
                            skip_cycle <= '1';
                            -- mux is set above
                        -- else do nothing, fetch stage is reading ahead
                        end if;
                    when others =>
                end case;
            end if;
        end if;
    end process;

    iexec_out_decode <= ('0', '0');


end architecture;
