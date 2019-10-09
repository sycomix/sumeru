library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.memory_channel_types.ALL;

entity dcache is
port(
        sys_clk:                in std_logic;
        mem_clk:                in std_logic;
        
        addr:                   in std_logic_vector(31 downto 0);
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

    signal meta:                std_logic_vector(31 downto 0);
    signal meta_wren:           std_logic := '0';
    alias line_valid:           std_logic is meta(3);
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

    signal meta_write:              std_logic_vector(31 downto 0);
    signal meta_write_line_valid:   std_logic;
    signal meta_write_line_dirty:   std_logic;

    signal cache_byteena:       std_logic_vector(3 downto 0);
    signal cache_write_data:    std_logic_vector(35 downto 0);
    -- componets of cache_write_data
    signal cache_write_data_b0:     std_logic_vector(7 downto 0);
    signal cache_write_data_b1:     std_logic_vector(7 downto 0);
    signal cache_write_data_b2:     std_logic_vector(7 downto 0);
    signal cache_write_data_b3:     std_logic_vector(7 downto 0);
    signal cache_write_data_bytevalid0:     std_logic;
    signal cache_write_data_bytevalid1:     std_logic;
    signal cache_write_data_bytevalid2:     std_logic;
    signal cache_write_data_bytevalid3:     std_logic;
    --
   
    -- cache data is data bits and byteena bits
    signal cache_data:          std_logic_vector(35 downto 0);
    -- alias for byteena bits
    alias data_bytevalid0:      std_logic is cache_data(8);
    alias data_bytevalid1:      std_logic is cache_data(17);
    alias data_bytevalid2:      std_logic is cache_data(26);
    alias data_bytevalid3:      std_logic is cache_data(35);
    signal data_bytevalidall:    std_logic_vector(3 downto 0);

    signal write_strobe_save:   std_logic := '0';
    signal counter:             std_logic_vector(2 downto 0);

begin
    data_bytevalidall <= 
        data_bytevalid3 & data_bytevalid2 &
        data_bytevalid1 & data_bytevalid0;

    cache_write_data <= 
        cache_write_data_bytevalid3 & cache_write_data_b3 &
        cache_write_data_bytevalid2 & cache_write_data_b2 &
        cache_write_data_bytevalid1 & cache_write_data_b1 &
        cache_write_data_bytevalid0 & cache_write_data_b0;

    meta_ram: entity work.alt_ram
        generic map(
            AWIDTH => 8,
            DWIDTH => 32)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => meta_write,
            wren => meta_wren,
            q => meta);

    data0_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 36)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data0_wren,
            byteena => cache_byteena,
            q => data0);

    data1_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 36)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data1_wren,
            byteena => cache_byteena,
            q => data1);

    data2_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 36)
        port map(
            clock => mem_clk,
            address => addr(11 downto 4),
            data => cache_write_data,
            wren => data2_wren,
            byteena => cache_byteena,
            q => data2);

    data3_ram: entity work.alt_ram_byteena
        generic map(
            AWIDTH => 8,
            DWIDTH => 36)
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

    hit <= '1' 
        when ((meta(31 downto 3) = (addr(31 downto 4) & "1")) and
              (data_bytevalidall and byteena) = byteena) 
        else '0';

    meta_write <= 
        addr(31 downto 4) & meta_write_line_valid & 
        meta_write_line_dirty & "00";
        
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
                        if (hit = '0') then
                            if (line_dirty = '1') then
                                -- STORE LINE
                                mc_op_start <= not mc_op_start;
                                mc_in.op_addr <= meta(24 downto 4) & "000";
                                mc_in.op_wren <= '1';
                                mc_in.op_dqm <= 
                                        (not data0(17)) & (not data0(8));
                                mc_in.write_data <= 
                                        data0(16 downto 9) & data0(7 downto 0);
                                state <= STORE_LINE;
                                counter <= (others => '0');
                            elsif (wren = '0') then
                                -- LOAD LINE
                                mc_op_start <= not mc_op_start;
                                mc_in.op_addr <= addr(24 downto 4) & "000";
                                mc_in.op_wren <= '0';
                                mc_in.op_dqm <= "00";
                                meta_write_line_valid <= '1';
                                meta_write_line_dirty <= '0';
                                cache_write_data_bytevalid0 <= '1';
                                cache_write_data_bytevalid1 <= '1';
                                cache_write_data_bytevalid2 <= '1';
                                cache_write_data_bytevalid3 <= '1';
                                cache_byteena <= "1111";
                                state <= LOAD_LINE;
                                counter <= (others => '0');
                            else
                                -- INITIALIZE LINE
                                meta_write_line_valid <= '1';
                                meta_write_line_dirty <= '0';
                                -- XXX Data we don't care as bytevalid are 0
                                cache_write_data_bytevalid0 <= '0';
                                cache_write_data_bytevalid1 <= '0';
                                cache_write_data_bytevalid2 <= '0';
                                cache_write_data_bytevalid3 <= '0';
                                cache_byteena <= "1111";
                                data0_wren <= '1';
                                data1_wren <= '1';
                                data2_wren <= '1';
                                data3_wren <= '1';
                                meta_wren <= '1';
                            end if;
                        elsif (wren = '1') then
                            -- WRITE TO LINE
                            cache_write_data_bytevalid0 <= '1';
                            cache_write_data_bytevalid1 <= '1';
                            cache_write_data_bytevalid2 <= '1';
                            cache_write_data_bytevalid3 <= '1';
                            cache_byteena <= byteena;
                            meta_write_line_dirty <= '1';
                            meta_write_line_valid <= '1';
                            data0_wren <= '1';
                            data1_wren <= '1';
                            data2_wren <= '1';
                            data3_wren <= '1';
                            meta_wren <= '1';
                            start_save <= not start_save;
                        else
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
            end case;
        end if;
    end process;
end architecture;


