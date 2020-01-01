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
    csr_sel_result:             inout std_logic_vector(31 downto 0);
    clk_instret:                out std_logic
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
    signal cxfer_mux:           std_logic := '0';
    signal cxfer_pc:            std_logic_vector(31 downto 0);
    signal trigger_cxfer:       std_logic := '0';
    signal br_inst:             std_logic := '0';

    signal dcache_addr:         std_logic_vector(24 downto 0) := (others => '0');
    signal dcache_start:        std_logic := '0';
    signal dcache_hit:          std_logic;
    signal dcache_read_data:    std_logic_vector(31 downto 0);
    signal dcache_write_data:   std_logic_vector(31 downto 0);
    signal dcache_wren:         std_logic;
    signal dcache_byteena:      std_logic_vector(3 downto 0);
    signal dcache_write_strobe: std_logic;

    signal dcache_write_strobe_save: std_logic := '0';
    signal busy_r:              std_logic := '0';

    signal op_a:                std_logic_vector(31 downto 0) := (others => '0');
    signal op_b:                std_logic_vector(31 downto 0) := (others => '0');
    signal alu_op:              std_logic_vector(3 downto 0) := (others => '0');
    signal shift_bit:           std_logic := '0';
    signal shift_dir_lr:        std_logic := '0';

    signal ls_op:               std_logic_vector(1 downto 0);
    signal ls_load_sign:        std_logic;
    signal ls0:                 std_logic;
    signal ls1:                 std_logic;
    signal ls2:                 std_logic;
    signal ls3:                 std_logic;
    signal store_data:          std_logic_vector(31 downto 0);
    signal load_result:         std_logic_vector(31 downto 0);
    signal mul_result:          std_logic_vector(31 downto 0);
    signal div_result:          std_logic_vector(31 downto 0);
    signal pc_p4:               std_logic_vector(31 downto 0);
    signal div_ctr:             std_logic_vector(2 downto 0);

    signal clk_instret_r:       std_logic := '0';

    type state_t is (
        RUNNING,
        LS_1,
        LS_WAIT,
        DIV_WAIT
        );

    signal state:               state_t := RUNNING;

    pure function sxt(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(x), n));
    end function;

    pure function ext(
                    x:          std_logic_vector;
                    n:          natural)
                    return std_logic_vector is
    begin
        return std_logic_vector(resize(unsigned(x), n));
    end function;

begin
    clk_instret <= clk_instret_r;

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
            op => alu_op,
            result => alu_result,
            result_br => br_result);

    muldiv: entity work.cpu_muldiv
        port map(
            clk => clk,
            a => op_a,
            b => op_b,
            op => alu_op,
            mul_result => mul_result,
            div_result => div_result);

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
        csr_sel_result when CMD_CSR,
        load_result when CMD_LOAD,
        pc_p4 when CMD_JALR,
        mul_result when CMD_MULDIV,
        div_result when others;
        

    iexec_out.cxfer_pc <= alu_result when cxfer_mux = '0' else cxfer_pc;
    iexec_out.busy <= busy_r;

    iexec_out.cxfer <= (br_inst and br_result) or trigger_cxfer;

    ls0 <= ls_load_sign and dcache_read_data(7);
    ls1 <= ls_load_sign and dcache_read_data(15);
    ls2 <= ls_load_sign and dcache_read_data(23);
    ls3 <= ls_load_sign and dcache_read_data(31);

    with dcache_byteena select
        load_result <=
            sxt(ls1 & dcache_read_data(15 downto 0),32)    when "0011",
            sxt(ls3 & dcache_read_data(31 downto 16),32)   when "1100" ,
            sxt(ls0 & dcache_read_data(7 downto 0),32)     when "0001" ,
            sxt(ls1 & dcache_read_data(15 downto 8),32)    when "0010" ,
            sxt(ls2 & dcache_read_data(23 downto 16),32)   when "0100" ,
            sxt(ls3 & dcache_read_data(31 downto 24),32)   when "1000" ,
            dcache_read_data                               when others;

    with ls_op select
        dcache_write_data <= 
            (store_data(15 downto 0) & store_data(15 downto 0)) when "01",
            (store_data(7 downto 0) & store_data(7 downto 0) &
             store_data(7 downto 0) & store_data(7 downto 0))   when "00",
            store_data                                          when others;

    with (ls_op & alu_result(1 downto 0)) select
        dcache_byteena <= 
            "0001" when "0000",
            "0010" when "0001",
            "0100" when "0010",
            "1000" when "0011",
            "0011" when "0100",
            "1100" when "0110",
            "0000" when "1100",         -- Hitherto DCACHE LINE FLUSH operation 
            "1111" when others;

    process(clk)
        variable br: std_logic;
    begin
        if (rising_edge(clk)) then
            regfile_wren <= '0';
            br_inst <= '0';
            trigger_cxfer <= '0';
            busy_r <= '0';
            csr_in.csr_sel_valid <= '0';
            case state is
            when DIV_WAIT =>
                if (div_ctr = "000") then
                    state <= RUNNING;
                else
                    busy_r <= '1';
                    regfile_wren <= '1';
                    div_ctr <= std_logic_vector(unsigned(div_ctr) - 1);
                end if;
            when LS_1 =>
                busy_r <= '1';
                dcache_addr <= alu_result(24 downto 0);
                dcache_wren <= cmd_result_mux(1);
                dcache_start <= not dcache_start;
                state <= LS_WAIT;
            when LS_WAIT =>
                if (cmd_result_mux = CMD_LOAD and dcache_hit = '1') then
                    regfile_wren <= '1';
                    state <= RUNNING;
                elsif (cmd_result_mux = CMD_STORE and 
                        dcache_write_strobe /= dcache_write_strobe_save) then
                    dcache_write_strobe_save <= not dcache_write_strobe_save;
                    state <= RUNNING;
                else
                    busy_r <= '1';
                end if;
            when RUNNING =>
                if (iexec_in.valid = '1' and iexec_out.cxfer = '0')  then
                    alu_op <= iexec_in.cmd_op;
                    pc_p4 <= iexec_in.pc_p4;

                    if (iexec_in.rs1 = regfile_wraddr and regfile_wren = '1') then
                        op_a <= rd_write_data;
                    else
                        op_a <= rs1_read_data;
                    end if;

                    if (iexec_in.cmd_use_reg = '0') then
                        op_b <= iexec_in.imm;
                    elsif (iexec_in.rs2 = regfile_wraddr and regfile_wren = '1') then
                        op_b <= rd_write_data;
                    else
                        op_b <= rs2_read_data;
                    end if;

                    if (iexec_in.rs2 = regfile_wraddr) then
                        store_data <= rd_write_data;
                    else
                        store_data <= rs2_read_data;
                    end if;

                    trigger_cxfer <= iexec_in.trigger_cxfer;
                    cxfer_mux <= '0';
                    shift_bit <= iexec_in.cmd_op(1);
                    shift_dir_lr <= iexec_in.cmd_op(0);
                    cmd_result_mux <= iexec_in.cmd;
                    regfile_wraddr <= iexec_in.rd;
                    case iexec_in.cmd is
                        when CMD_STORE =>
                            state <= LS_1;
                            busy_r <= '1';
                            ls_op <= iexec_in.rd(1 downto 0);
                            ls_load_sign <= not iexec_in.rs2(2);
                        when CMD_LOAD => 
                            state <= LS_1;
                            busy_r <= '1';
                            ls_op <= iexec_in.rs2(1 downto 0);
                            ls_load_sign <= not iexec_in.rs2(2);
                        when CMD_MULDIV =>
                            regfile_wren <= '1';
                            if (iexec_in.cmd_op(2) = '1') then
                                -- CMD_STORE or we could use CMD_BRANCH
                                -- both will trigger the cmd_result_mux
                                -- others clause causing div_result to
                                -- output. If not for this optimisation
                                -- we would need more bits/resources.
                                cmd_result_mux <= CMD_STORE;
                                busy_r <= '1';
                                state <= DIV_WAIT;
                                div_ctr <= "110";
                            end if;
                        when CMD_ALU | CMD_SHIFT | CMD_JALR =>
                            regfile_wren <= '1';
                        when CMD_BRANCH =>
                            br_inst <= '1';
                            cxfer_pc <= iexec_in.imm;
                            cxfer_mux <= '1';
                        when CMD_CSR =>
                            regfile_wren <= '1';
                            csr_in.csr_sel_valid <= '1';
                            csr_in.csr_sel_reg <= iexec_in.csr_reg;
                            csr_in.csr_sel_op <= iexec_in.cmd_op(1 downto 0);
                        when others =>
                    end case;
                end if;
            end case;
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            csr_in.csr_op_valid <= csr_in.csr_sel_valid; 
            csr_in.csr_op_reg <= csr_in.csr_sel_reg;
            case csr_in.csr_sel_op is
                when "10" =>
                    csr_in.csr_op_data <= 
                        op_b or csr_sel_result;
                when "11" =>
                    csr_in.csr_op_data <= 
                        not op_b and csr_sel_result;
                when others =>
                    csr_in.csr_op_data <= op_b;
            end case;
        end if;
    end process;

end architecture;
