library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity dcache is
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        
        addr:                   in std_logic_vector(24 downto 0);
        start:                  in std_logic;

        hit:                    out std_logic;
        read_data:              out std_logic_vector(31 downto 0);

        wren:                   in std_logic;
        byteena:                in std_logic_vector(3 downto 0);
        write_strobe:           out std_logic;
        write_data:             in std_logic_vector(31 downto 0);

        mc_in:                  out mem_channel_in_t;
        mc_out:                 in mem_channel_out_t;
        sdc_data_out:           in std_logic_vector(15 downto 0)
    );
end entity;

architecture synth of dcache is
    signal start_save:          std_logic := '0';

    signal meta:                std_logic_vector(15 downto 0);
    signal meta_wren:           std_logic := '0';
    alias line_dirty:           std_logic is meta(2);

    signal data0:               std_logic_vector(35 downto 0);
    signal data1:               std_logic_vector(35 downto 0);
    signal data2:               std_logic_vector(35 downto 0);
    signal data3:               std_logic_vector(35 downto 0);

    signal data0_wren:          std_logic := '0';
    signal data1_wren:          std_logic := '0';
    signal data2_wren:          std_logic := '0';
    signal data3_wren:          std_logic := '0';

    signal mc_op_start:         std_logic := '0';

    type cache_state_t is (
          IDLE
        , STORE_LINE
        , LOAD_LINE
    );

    signal state:               cache_state_t := IDLE;

    signal line_hit:            std_logic;

    signal meta_write:              std_logic_vector(15 downto 0);
    signal meta_write_line_dirty:   std_logic;

    signal cache_byteena:       std_logic_vector(3 downto 0);
    signal cache_write_data:    std_logic_vector(35 downto 0);
    -- componets of cache_write_data
    signal cache_write_data_b0:     std_logic_vector(7 downto 0);
    signal cache_write_data_b1:     std_logic_vector(7 downto 0);
    signal cache_write_data_b2:     std_logic_vector(7 downto 0);
    signal cache_write_data_b3:     std_logic_vector(7 downto 0);
    signal cache_write_data_byteena0:     std_logic;
    signal cache_write_data_byteena1:     std_logic;
    signal cache_write_data_byteena2:     std_logic;
    signal cache_write_data_byteena3:     std_logic;
    --
   
    -- cache data is data bits and byteena bits
    signal cache_data:          std_logic_vector(35 downto 0);
    -- alias for byteena bits
    alias data_byteena0:      std_logic is cache_data(8);
    alias data_byteena1:      std_logic is cache_data(17);
    alias data_byteena2:      std_logic is cache_data(26);
    alias data_byteena3:      std_logic is cache_data(35);
    signal data_byteenaall:    std_logic_vector(3 downto 0);

    signal write_strobe_save:   std_logic := '0';
    signal counter:             std_logic_vector(2 downto 0);

begin
    data_byteenaall <= 
        data_byteena3 & data_byteena2 &
        data_byteena1 & data_byteena0;

    cache_write_data <= 
        cache_write_data_byteena3 & cache_write_data_b3 &
        cache_write_data_byteena2 & cache_write_data_b2 &
        cache_write_data_byteena1 & cache_write_data_b1 &
        cache_write_data_byteena0 & cache_write_data_b0;

    -- XXX: Init (via file) meta ram values to 0 on start
    meta_ram: entity work.ram1p_256x16
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => meta_write,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.ram1p_256x36_byteena
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data0_wren,
            byteena => cache_byteena,
            q => data0);

    data1_ram: entity work.ram1p_256x36_byteena
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data1_wren,
            byteena => cache_byteena,
            q => data1);

    data2_ram: entity work.ram1p_256x36_byteena
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data2_wren,
            byteena => cache_byteena,
            q => data2);

    data3_ram: entity work.ram1p_256x36_byteena
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data3_wren,
            byteena => cache_byteena,
            q => data3);

    read_data <= 
        cache_data(34 downto 27) & cache_data(25 downto 18) &
        cache_data(16 downto 9) & cache_data(7 downto 0);

    with addr(3 downto 2) select 
        cache_data <= data0 when "00",
                data1 when "01",
                data2 when "10",
                data3 when others;

    line_hit <= '1' when meta(15 downto 3) = addr(24 downto 12) else '0';

    hit <= '1' 
        when (line_hit = '1' and (data_byteenaall and byteena) = byteena)
        else '0';

    meta_write <= addr(24 downto 12) & meta_write_line_dirty & "00";
        
    write_strobe <= write_strobe_save;

    mc_in.op_burst <= '1';
    mc_in.op_start <= mc_op_start;

    process(sys_clk)
    begin
        if (rising_edge(sys_clk)) then
            data0_wren <= '0';
            data1_wren <= '0';
            data2_wren <= '0';
            data3_wren <= '0';
            meta_wren <= '0';

            cache_write_data_b0 <= cache_write_data_b2;
            cache_write_data_b1 <= cache_write_data_b3;
            cache_write_data_b2 <= sdc_data_out(7 downto 0);
            cache_write_data_b3 <= sdc_data_out(15 downto 8);

            case state is
                when IDLE =>
                    if (start /= start_save) then
                        if (wren = '1' and line_hit = '1') then
                            -- Write data to line
                            start_save <= not start_save;
                            write_strobe_save <= not write_strobe_save;
                            cache_write_data_byteena0 <= '1';
                            cache_write_data_byteena1 <= '1';
                            cache_write_data_byteena2 <= '1';
                            cache_write_data_byteena3 <= '1';
                            cache_write_data_b0 <= write_data(7 downto 0);
                            cache_write_data_b1 <= write_data(15 downto 8);
                            cache_write_data_b2 <= write_data(23 downto 16);
                            cache_write_data_b3 <= write_data(31 downto 24);
                            cache_byteena <= byteena;
                            meta_write_line_dirty <= '1';
                            meta_wren <= '1';
                            case addr(3 downto 2) is
                                when "00" =>
                                    data0_wren <= '1';
                                when "01" =>
                                    data1_wren <= '1';
                                when "10" =>
                                    data2_wren <= '1';
                                when others =>
                                    data3_wren <= '1';
                            end case;
                        elsif (hit = '0') then
                            -- Cache miss
                            if (line_dirty = '1') then
                                -- Store line
                                mc_op_start <= not mc_op_start;
                                mc_in.op_addr <= meta(15 downto 3) & addr(11 downto 4) & "000";
                                mc_in.op_wren <= '1';
                                mc_in.op_dqm <= 
                                        (not data0(17)) & (not data0(8));
                                mc_in.write_data <= 
                                        data0(16 downto 9) & data0(7 downto 0);
                                -- After storing, store should reset the
                                -- line dirty 
                                meta_write_line_dirty <= '0';
                                state <= STORE_LINE;
                                counter <= (others => '0');
                            elsif (wren = '0') then
                                -- Load line
                                -- hit going high will signify completion
                                start_save <= not start_save;
                                mc_op_start <= not mc_op_start;
                                mc_in.op_addr <= addr(24 downto 4) & "000";
                                mc_in.op_wren <= '0';
                                mc_in.op_dqm <= "00";
                                meta_write_line_dirty <= '0';
                                cache_write_data_byteena0 <= '1';
                                cache_write_data_byteena1 <= '1';
                                cache_write_data_byteena2 <= '1';
                                cache_write_data_byteena3 <= '1';
                                cache_byteena <= "1111";
                                state <= LOAD_LINE;
                                counter <= (others => '0');
                            else
                                -- INITIALIZE LINE
                                -- XXX Invariant: Must be followed by write
                                meta_write_line_dirty <= '0';
                                -- XXX Data we don't care as byteena are 0
                                cache_write_data_byteena0 <= '0';
                                cache_write_data_byteena1 <= '0';
                                cache_write_data_byteena2 <= '0';
                                cache_write_data_byteena3 <= '0';
                                cache_byteena <= "1111";
                                data0_wren <= '1';
                                data1_wren <= '1';
                                data2_wren <= '1';
                                data3_wren <= '1';
                                meta_wren <= '1';
                            end if;
                        else
                            -- NOP: Cahe-hit Read
                            start_save <= not start_save;
                        end if;
                    end if;
                when LOAD_LINE =>
                    if (mc_out.op_strobe = mc_op_start) then
                        counter <= std_logic_vector(unsigned(counter) + 1);
                        case counter is
                            when "000" =>
                                data0_wren <= '1';
                            when "010" =>
                                data1_wren <= '1';
                            when "100" =>
                                data2_wren <= '1';
                            when "110" =>
                                data3_wren <= '1';
                                meta_wren <= '1';
                                state <= IDLE;
                            when others =>
                        end case;
                    end if;
                when STORE_LINE =>
                    if (mc_out.op_strobe = mc_op_start) then
                        counter <= std_logic_vector(unsigned(counter) + 1);
                        case counter is
                            when "000" =>
                                mc_in.op_dqm <= (not data0(35)) & (not data0(26));
                                mc_in.write_data <= data0(34 downto 27) & data0(25 downto 18);
                            when "001" =>
                                mc_in.op_dqm <= (not data1(17)) & (not data1(8));
                                mc_in.write_data <= data1(16 downto 9) & data1(7 downto 0);
                            when "010" =>
                                mc_in.op_dqm <= (not data1(35)) & (not data1(26));
                                mc_in.write_data <= data1(34 downto 27) & data1(25 downto 18);
                            when "011" =>
                                mc_in.op_dqm <= (not data2(17)) & (not data2(8));
                                mc_in.write_data <= data2(16 downto 9) & data2(7 downto 0);
                            when "100" =>
                                mc_in.op_dqm <= (not data2(35)) & (not data2(26));
                                mc_in.write_data <= data2(34 downto 27) & data2(25 downto 18);
                            when "101" =>
                                mc_in.op_dqm <= (not data3(17)) & (not data3(8));
                                mc_in.write_data <= data3(16 downto 9) & data3(7 downto 0);
                            when "110" =>
                                mc_in.op_dqm <= (not data3(35)) & (not data3(26));
                                mc_in.write_data <= data3(34 downto 27) & data3(25 downto 18);
                                meta_wren <= '1';
                                state <= IDLE;
                            when others =>
                        end case;
                    end if;
            end case;
        end if;
    end process;
end architecture;
