library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lt_24_analyzer is 
    port (
        clk             : in std_logic;
        reset_n         : in std_logic;
        
        -- avalon slave
        as_addr         : in std_logic_vector(2 downto 0);
        as_rd           : in std_logic;
        as_wr           : in std_logic;
        as_wrdata       : in std_logic_vector(31 downto 0);
        as_rddata       : out std_logic_vector(31 downto 0);

        --avalon master
        am_addr         : out std_logic_vector(31 downto 0);
        am_rd           : out std_logic;
        am_wr           : out std_logic;
        am_wrdata       : out std_logic_vector(31 downto 0);
        am_rddata       : in std_logic_vector(31 downto 0);
        am_waitrequest  : in std_logic;

        -- lt_24 output
        lcd_reset_n     : out std_logic;
        lcd_on          : out std_logic;
        lcd_cs_n        : out std_logic;
        lcd_dc_n        : out std_logic;
        lcd_rd_n        : out std_logic;
        lcd_wr_n        : out std_logic;
        lcd_data        : out std_logic_vector(15 downto 0)
    );
end entity lt_24_analyzer;

architecture comp of lt_24_analyzer is

    constant LCD_HEIGHT : integer := 240;
    constant LCD_WIDTH  : integer := 320;
    constant DEFAUL_VAL : integer := 120;
    constant MAX_CMD_NUM: integer := 15;
    constant CMD_START_FRAME    : std_logic_vector(15 downto 0) := "0000000000101100" ; -- 0x002C -> new frame
    constant CMD_END_FRAME      : std_logic_vector(15 downto 0) := "0000000000000000" ; -- 0x0000 -> end frame

    type Tsate is (IDLE, REQUEST_0, GET_0, REQUEST_1, GET_1, START_FRAME, PUT, END_FRAME, CMD, CMD_DATA);
    type table is array(LCD_WIDTH - 1 downto 0) of integer;
    type commands is array(MAX_CMD_NUM - 1 downto 0) of std_logic_vector(15 downto 0);

    -- read address for the value
    signal address0     : std_logic_vector(31 downto 0);
    signal address1     : std_logic_vector(31 downto 0);
    signal run          : std_logic := '0';
    signal write_cmd    : std_logic;

    -- commands signals
    signal cmd_cmd      : std_logic_vector(15 downto 0);
    signal cmd_datas    : commands;
    signal cmd_num      : std_logic_vector(3 downto 0);
    signal cmd_count_r  : unsigned(4 downto 0);
    signal cmd_count_w  : unsigned(4 downto 0);

    signal data         : std_logic_vector(15 downto 0);
    signal datas_0      : table;
    signal datas_1      : table;
    signal state        : Tsate;
    signal height_count : unsigned(8 downto 0);
    signal width_count  : unsigned(8 downto 0);
    signal count        : unsigned(1 downto 0);
    signal offset       : integer := 0;

begin

-- main process
main: process(clk, reset_n)
begin 
    if reset_n = '0' then 
        -- reset internal signals
        data         <= (others => '0');
        for i in 0 to LCD_WIDTH - 1 loop
            datas_0(i) <= DEFAUL_VAL;
        end loop;
        for i in 0 to LCD_WIDTH - 1 loop
            datas_1(i) <= DEFAUL_VAL;
        end loop;
        state        <= IDLE;
        height_count <= to_unsigned(0, 9);
        width_count  <= to_unsigned(0, 9);
        count        <= "00";
        offset       <= 0;

        -- reset the lcd
        lcd_cs_n    <= '1';
        lcd_dc_n    <= '1';
        lcd_wr_n    <= '0';
        lcd_data    <= (others => '0');

    elsif rising_edge(clk) then
        -- set the lcd
        lcd_cs_n    <= '0';
        lcd_dc_n    <= '1';
        lcd_wr_n    <= '1';
        lcd_data    <= (others => '0');

        am_addr <= (others => '0');
        am_rd <= '0';

        case state is 
        when IDLE => 
            count <= "00";
            -- if write_cmd set CMD
            if write_cmd = '1' then
                state <= CMD;
            -- if run is set LOCK
            elsif run = '1' then
                state <= GET_0;
            end if;

        when REQUEST_0 => 
            am_addr <= address0;
            am_rd <= '1';
            state <= GET_0;

        when GET_0 => 
            -- read the value from the address
            am_addr     <= address0;
            am_rd       <= '1';
            if am_waitrequest = '0' then
                datas_0((offset + (LCD_WIDTH - 1)) mod LCD_WIDTH) <= to_integer(unsigned(am_rddata));
                state <= REQUEST_1;
            end if;

        when REQUEST_1 =>
            am_addr <= address1;
            am_rd <= '1';
            state <= GET_1;

        when GET_1 => 
            -- read the value from the address
            am_addr     <= address1;
            am_rd       <= '1';
            if am_waitrequest = '0' then
                datas_1((offset + (LCD_WIDTH - 1)) mod LCD_WIDTH) <= to_integer(unsigned(am_rddata));
                state <= START_FRAME;
            end if;

        when START_FRAME => 
            -- write START_FRAME to lcd
            lcd_data <= CMD_START_FRAME;
            lcd_dc_n <= '0';
            count <= count + 1;

            case count is 
            when "00" | "01" => lcd_wr_n <= '0';
            when "10" => lcd_wr_n <= '1';
            when "11" => 
                lcd_wr_n <= '1';
                count <= "00";
                state <= PUT;
            when others => null;
            end case;

        when PUT =>
            -- write to the LCD
            -- write the data to the LCD

            count <= count + 1;
            case count is
            when "00" =>
                -- data is x"FFFF" when heiht_count is between data((width_count + offset) mod LCD_WIDTH) 
                -- and data((width_count + offset + 1) mod LCD_WIDTH)
                -- data is x"0000" when heiht_count is not between data((width_count + offset) mod LCD_WIDTH) 
                -- and data((width_count + offset + 1) mod LCD_WIDTH)

                lcd_data <= x"0000";
                data <= x"0000";

                if (width_count = LCD_WIDTH - 1) then 
                    if (height_count = datas_0((to_integer(width_count) + offset) mod LCD_WIDTH)) then
                        lcd_data <= x"F800";
                        data <= x"F800";
                    elsif (height_count = datas_1((to_integer(width_count) + offset) + 120 mod LCD_WIDTH) + 120) then
                        lcd_data <= x"07E0";
                        data <= x"07E0";
                    end if;
                else
                    if (((height_count <= datas_0((to_integer(width_count) + offset) mod LCD_WIDTH)) 
                    and (height_count >= datas_0((to_integer(width_count) + offset + 1) mod LCD_WIDTH))) 
                    or ((height_count >= datas_0((to_integer(width_count) + offset) mod LCD_WIDTH)) 
                    and (height_count <= datas_0((to_integer(width_count) + offset + 1) mod LCD_WIDTH)))) then
                        lcd_data <= x"F800";
                        data <= x"F800";
                    end if;
                    if (((height_count <= datas_1((to_integer(width_count) + offset) mod LCD_WIDTH) + 120) 
                    and (height_count >= datas_1((to_integer(width_count) + offset + 1) mod LCD_WIDTH) + 120)) 
                    or ((height_count >= datas_1((to_integer(width_count) + offset) mod LCD_WIDTH) + 120) 
                    and (height_count <= datas_1((to_integer(width_count) + offset + 1) mod LCD_WIDTH) + 120))) then
                        lcd_data <= x"07E0";
                        data <= x"07E0";
                    end if;
                end if;

                lcd_wr_n <= '0';
            when "01" =>
                lcd_data <= data;
                lcd_wr_n <= '0';
            when "10" =>
                lcd_data <= data;
                lcd_wr_n <= '1';
            when "11" =>
                lcd_data <= data;
                lcd_wr_n <= '1';
                count <= "00";
                height_count <= height_count + 1;
                if (width_count + 1) = LCD_WIDTH and (height_count + 1) = LCD_HEIGHT then
                    -- entire frame is written
                    width_count <= to_unsigned(0, 9);
                    height_count <= to_unsigned(0, 9);
                    offset <= (offset + 1) mod LCD_WIDTH;
                    state <= END_FRAME;
                elsif height_count + 1 = LCD_HEIGHT then
                    height_count <= to_unsigned(0, 9);
                    width_count <= width_count + 1;
                end if;
            when others => null;
            end case;

        when END_FRAME =>
            -- write END_FRAME to lcd
            lcd_data <= CMD_END_FRAME;
            lcd_dc_n <= '0';
            count <= count + 1;

            case count is 
            when "00" | "01" => lcd_wr_n <= '0';
            when "10" => lcd_wr_n <= '1';
            when "11" => 
                lcd_wr_n <= '1';
                count <= "00";
                state <= IDLE;
            when others => null;
            end case;

        when CMD =>
            -- write CMD to lcd
            lcd_data <= cmd_cmd;
            lcd_dc_n <= '0';
            count <= count + 1;

            case count is 
            when "00" | "01" => lcd_wr_n <= '0';
            when "10" => lcd_wr_n <= '1';
            when "11" => 
                lcd_wr_n <= '1';
                count <= "00";
                if to_integer(unsigned(cmd_num)) = 0 then
                    state <= IDLE;
                else
                    state <= CMD_DATA;
                    cmd_count_w <= to_unsigned(0, 5);
                end if;
            when others => null;
            end case;

        when CMD_DATA =>
            -- write cmd_data to lcd
            lcd_data <= cmd_datas(to_integer(cmd_count_w));
            count <= count + 1;

            case count is 
            when "00" | "01" => lcd_wr_n <= '0';
            when "10" => lcd_wr_n <= '1';
            when "11" => 
                lcd_wr_n <= '1';
                count <= "00";
                cmd_count_w <= cmd_count_w + 1;
                if cmd_count_w = to_integer(unsigned(cmd_num)) - 1 then
                    state <= IDLE;
                end if;
            when others => null;
            end case;
        end case;
    end if;
end process main;

-- write process for the slave
slave_write: process(clk, reset_n)
begin
    if reset_n = '0' then
        address0 <= (others => '0');
        address1 <= (others => '0');
        run     <= '0';
        write_cmd <= '0';
        for i in 0 to MAX_CMD_NUM - 1 loop
            cmd_datas(i) <= (others => '0');
        end loop;

    elsif rising_edge(clk) then
        write_cmd <= '0';
        if as_wr = '1' then
            case as_addr is 
            when "000" => address0 <= as_wrdata;
            when "001" => address1 <= as_wrdata;
            when "010" => 
                run     <= as_wrdata(0);
                write_cmd <= as_wrdata(1);
            when "011" => 
                cmd_cmd <= as_wrdata(15 downto 0);
                cmd_count_r <= to_unsigned(0, 5);
            when "100" => 
                cmd_num <= as_wrdata(3 downto 0);
            when "101" =>
                cmd_count_r <= cmd_count_r + 1;
                cmd_datas(to_integer(cmd_count_r)) <= as_wrdata(15 downto 0);
            when others => null;
            end case;
        end if;
    end if;
end process slave_write;

-- read process for slave
slave_read: process(clk, reset_n)
begin
    if reset_n = '0' then
        as_rddata <= (others => '0');
    elsif rising_edge(clk) then
        if as_rd = '1' then
            case as_addr is 
            when "000" => as_rddata <= address0;
            when "001" => as_rddata <= address1;
            when "010" => 
                as_rddata(0) <= run;
                as_rddata(1) <= write_cmd;
            when "011" => as_rddata(15 downto 0) <= cmd_cmd;
            when "100" => as_rddata(3 downto 0) <= cmd_num;
            when others => null;
            end case;
        end if;
    end if;
end process slave_read;

lcd_rd_n <= '1';
am_wr <= '0';
am_wrdata <= (others => '0');
lcd_reset_n <= reset_n;
lcd_on <= '1';

end comp;