library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

use work.cpu_types.ALL;
use work.memory_channel_types.ALL;

entity cpu_stage_iexec is
port(
    clk:                        in std_logic;
    clk_n:                      in std_logic;
    iexec_in:                   in iexec_channel_in_t;
    iexec_out:                  out iexec_channel_out_t;
    dcache_mc_in:               out mem_channel_in_t;
    dcache_mc_out:              in mem_channel_out_t;
    sdc_data_out:               in std_logic_vector(15 downto 0);
    csr_in:                     out csr_channel_in_t;
    csr_out:                    in csr_channel_out_t;
    debug:                      out std_logic
    );
end entity;

architecture synth of cpu_stage_iexec is
    signal regfile_wren:        std_logic := '0';
    signal regfile_wren_nz:     std_logic;
    signal regfile_wraddr:      std_logic_vector(4 downto 0) := (others => '0');

    signal rd_write_data:       std_logic_vector(31 downto 0) := (others => '0');
    signal rs1_read_data:       std_logic_vector(31 downto 0);
    signal rs2_read_data:       std_logic_vector(31 downto 0);

    signal alu_result:          std_logic_vector(31 downto 0);
    signal br_result:           std_logic;
    signal cmd_result_mux:      std_logic_vector(2 downto 0) := (others => '0');

    signal shift_result:        std_logic_vector(31 downto 0);
    signal cxfer_async_strobe:  std_logic := '0';
    signal cxfer_mux:           std_logic := '0';
    signal cxfer_async_pc:      std_logic_vector(31 downto 0);
    signal trigger_cxfer:       std_logic := '0';
    signal br_inst:             std_logic := '0';
    signal br_taken:            std_logic;

    signal dcache_addr:         std_logic_vector(24 downto 0) := (others => '0');
    signal dcache_start:        std_logic := '0';
    signal dcache_hit:          std_logic;
    signal dcache_read_data:    std_logic_vector(31 downto 0);
    signal dcache_wren:         std_logic;
    signal dcache_byteena:      std_logic_vector(3 downto 0);
    signal dcache_write_strobe: std_logic;
    signal dcache_write_data:   std_logic_vector(31 downto 0);

    signal dcache_write_strobe_save: std_logic := '0';
    signal busy_r:              std_logic := '0';

    signal op_a:                std_logic_vector(31 downto 0) := (others => '0');
    signal op_b:                std_logic_vector(31 downto 0) := (others => '0');
    signal shift_bit:           std_logic := '0';
    signal shift_dir_lr:        std_logic := '0';

    type state_t is (
        RUNNING,
        LOAD_1,
        LOAD_WAIT
        );

    signal state:               state_t := RUNNING;

begin
    regfile_a: entity work.ram2p_simp_32x32
        port map(
            rdclock => clk_n,
            wrclock => clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs1,
            wraddress => regfile_wraddr,
            wren => regfile_wren_nz,
            q => rs1_read_data);

    regfile_b: entity work.ram2p_simp_32x32
        port map(
            rdclock => clk_n,
            wrclock => clk,
            data => rd_write_data,
            rdaddress => iexec_in.rs2,
            wraddress => regfile_wraddr,
            wren => regfile_wren_nz,
            q => rs2_read_data);

    regfile_wren_nz <= 
        regfile_wren and (regfile_wraddr(0) or regfile_wraddr(1) or
                          regfile_wraddr(2) or regfile_wraddr(3) or
                          regfile_wraddr(4));

    alu: entity work.cpu_alu
        port map(
            a => op_a,
            b => op_b,
            op => iexec_in.cmd_op,
            result => alu_result,
            result_br => br_result);

    shift: entity work.cpu_shift
        port map(
            shift_data => op_a,
            shift_amt => op_b(4 downto 0),
            shift_bit => shift_bit,
            shift_dir_lr => shift_dir_lr,
            shift_result => shift_result);

    dcache: entity work.readwritecache_256x4x32
        port map(
            clk => clk,
            clk_n => clk_n,
            addr => dcache_addr,
            start => dcache_start,
            hit => dcache_hit,
            read_data => dcache_read_data,
            wren => dcache_wren,
            byteena => dcache_byteena,
            write_strobe => dcache_write_strobe,
            write_data => dcache_write_data,
            mc_in => dcache_mc_in,
            mc_out => dcache_mc_out,
            sdc_data_out => sdc_data_out
        );

    with cmd_result_mux select rd_write_data <=
        alu_result when CMD_ALU,
        shift_result when CMD_SHIFT,
        csr_out.csr_op_result when CMD_CSR,
        x"00000000" when CMD_BRANCH,
        x"00000000" when CMD_STORE,
        dcache_read_data when others;

    br_taken <= (br_inst and br_result) or trigger_cxfer;

    process(clk_n)
    begin
        -- XXX Timing Risk
        if (rising_edge(clk_n)) then
            if (br_taken = '1')
            then        
                -- BRANCH TAKEN
                cxfer_async_strobe <= not cxfer_async_strobe;
                -- skip the next cycle as there maybe a valid
                -- decode command pending
                -- mux is set above
                -- incase of not-taken do nothing, fetch stage is reading ahead
            end if;
        end if;
    end process;

    iexec_out.cxfer <= cxfer_async_strobe;
    iexec_out.cxfer_pc <= alu_result when cxfer_mux = '0' else cxfer_async_pc;
    iexec_out.busy <= busy_r;

    csr_in.csr_op_data <= op_b;

    debug <= op_a(27);

    process(clk)
        variable br: std_logic;
    begin
        if (rising_edge(clk)) then
            regfile_wren <= '0';
            br_inst <= '0';
            trigger_cxfer <= '0';
            busy_r <= '0';
            csr_in.csr_op_valid <= '0';
            case state is
            when LOAD_1 =>
                busy_r <= '1';
                dcache_addr <= alu_result(24 downto 0);
                dcache_wren <= '0';
                dcache_start <= not dcache_start;
                dcache_byteena <= (others => '1');
                state <= LOAD_WAIT;
            when LOAD_WAIT =>
                if (dcache_hit = '1') then
                    regfile_wren <= '1';
                    state <= RUNNING;
                else
                    busy_r <= '1';
                end if;
            when RUNNING =>
                if (iexec_in.valid = '1' and br_taken = '0')  then
                    if (iexec_in.rs1 = regfile_wraddr) then
                        op_a <= rd_write_data;
                    else
                        op_a <= rs1_read_data;
                    end if;
                    if (iexec_in.cmd_use_reg = '0') then
                        op_b <= iexec_in.imm;
                    elsif (iexec_in.rs2 = regfile_wraddr) then
                        op_b <= rd_write_data;
                    else
                        op_b <= rs2_read_data;
                    end if;
                    trigger_cxfer <= iexec_in.trigger_cxfer;
                    cxfer_mux <= '0';
                    shift_bit <= iexec_in.cmd_op(1);
                    shift_dir_lr <= iexec_in.cmd_op(0);
                    -- set mux to alu or branch
                    cmd_result_mux <= iexec_in.cmd;
                    regfile_wraddr <= iexec_in.rd;
                    case iexec_in.cmd is
                        when CMD_LOAD => 
                            state <= LOAD_1;
                            busy_r <= '1';
                            -- XXX for stores set wraddr = 0 and mux wrdata = '0'
                        when CMD_ALU | CMD_SHIFT =>
                            regfile_wren <= '1';
                        when CMD_BRANCH =>
                            br_inst <= '1';
                            cxfer_async_pc <= iexec_in.imm;
                            cxfer_mux <= '1';
                            -- we need to set wraddr so thatn op_a and op_b
                            -- are set correctly next cycle
                            regfile_wraddr <= (others => '0');
                        when CMD_CSR =>
                            csr_in.csr_reg <= iexec_in.csr_reg;
                            csr_in.csr_op_valid <= '1';
                            csr_in.csr_op <= iexec_in.cmd_op(1 downto 0);
                            regfile_wren <= '1';
                        when others =>
                    end case;
                end if;
            end case;
        end if;
    end process;

end architecture;
