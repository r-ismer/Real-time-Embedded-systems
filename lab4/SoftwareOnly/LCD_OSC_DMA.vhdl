library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCD_OSC_DMA is
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- Avalon slave interface
        as_address :        in std_logic_vector(1 downto 0);
        as_read :           in std_logic;
        as_readdata :       out std_logic_vector(31 downto 0);
        as_write :          in std_logic;
        as_writedata :      in std_logic_vector(31 downto 0);

        -- Avalon master interface
        --am_address :        out std_logic_vector(31 downto 0);
        --am_read :           out std_logic;
        --am_readdata :       in std_logic_vector(31 downto 0);
        ---am_write :          out std_logic;
        --am_writedata :      out std_logic_vector(31 downto 0);
        --am_wait_request :   in std_logic;
        --am_byte_enable :    out std_logic_vector(3 downto 0);

        -- LCD interface
        lcd_on : out std_logic;
        rs : out std_logic; -- the D/C signal
        D : out std_logic_vector(15 downto 0);
        wr_n : out std_logic;
        rd_n : out std_logic;
        cs_n : out std_logic;
        res_n : out std_logic
    );
end LCD_OSC_DMA;

architecture comp of LCD_OSC_DMA is
    type LCD_STATES is (IDLE, WRITE_LOW_0, WRITE_LOW_1, WRITE_HIGH_0, WRITE_HIGH_1);
    signal RegDirectCom : std_logic_vector(15 downto 0);
    signal RegDirectType : std_logic;

    signal lcd_prot_state : LCD_STATES;

    signal FlagSendLCD : std_logic;
    signal RegSendLCD : std_logic_vector(15 downto 0);

begin
    -- constant signals on pins
    rd_n <= '1';
    cs_n <= '0';
    res_n <= '1';
    lcd_on <= '1';

    slave_write : process(clk, nReset)
    begin
        if nReset = '0' then
            RegDirectCom <= (others => '0');
            RegDirectType <= '0';
            FlagSendLCD <= '0';
            RegSendLCD <= (others => '0');

        elsif rising_edge(clk) then
            FlagSendLCD <= '0';
            if as_write = '1' then
                case as_address is
                    when "00" =>
                        RegDirectCom <= as_writedata(15 downto 0);
                        RegSendLCD <= as_writedata(15 downto 0);
                        RegDirectType <= as_writedata(16);
                        FlagSendLCD <= '1';
                    when others => null;
                end case;
            end if;
        end if;
    end process slave_write;

    slave_read : process(clk, nReset)
    begin
        if nReset = '0' then
            as_readdata <= (others => '0');
        end if;
    end process slave_read;

    lcd_protocol : process(clk, nReset)
    begin
        if nReset = '0' then
            -- pins
            rs <= '1';
            D <= (others => '0');
            wr_n <= '1';

            lcd_prot_state <= IDLE;

        elsif rising_edge(clk) then
            case lcd_prot_state is
                when IDLE =>
                if FlagSendLCD = '1' then
                    lcd_prot_state <= WRITE_LOW_0;
                    D <= RegSendLCD;
                    rs <= RegDirectType;
                    wr_n <= '0';
                end if;

                when WRITE_LOW_0 =>
                    lcd_prot_state <= WRITE_LOW_1;

                when WRITE_LOW_1 =>
                    lcd_prot_state <= WRITE_HIGH_0;
                    wr_n <= '1';

                when WRITE_HIGH_0 =>
                    lcd_prot_state <= WRITE_HIGH_1;

                when WRITE_HIGH_1 =>
                    lcd_prot_state <= IDLE;
                    wr_n <= '0';

                when others => null;
            end case;
        end if;
    end process lcd_protocol;
end comp;