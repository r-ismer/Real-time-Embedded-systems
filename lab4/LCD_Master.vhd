library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCD_Master is
    port(
        clk                 : in std_logic;
        reset_n             : in std_logic;

        -- registers
        buf_addr            : in std_logic_vector(31 downto 0);
        buf_length          : in std_logic_vector(31 downto 0);

        -- master
        am_addr             : out std_logic_vector(31 downto 0);
        am_be               : out std_logic_vector(3 downto 0);
        am_rd               : out std_logic;
        am_rddata           : in std_logic_vector(31 downto 0);
        am_waitrq           : in std_logic;

        -- FIFO
        FIFO_wr             : out std_logic;
        FIFO_wrdata         : out std_logic_vector(15 downto 0);
        FIFO_full           : in std_logic;
        FIFO_almostfull     : in std_logic
    );
end entity LCD_Master;

architecture am of LCD_Master is

-- signals
constant ZERO_32 : std_logic_vector(31 downto 0) := (others => '0');
constant ZERO_16 : std_logic_vector(15 downto 0) := (others => '0');

constant COLUMN : natural := 320;
constant ROW    : natural := 240;

type Tstate is (IDLE, WAIT_FIFO, SEND_ADDR, READ_DATA);

signal state            : Tstate;
signal counter          : natural;
signal address          : std_logic_vector(31 downto 0);
signal data             : std_logic_vector(15 downto 0);

signal row_counter      : natural;
signal column_counter   : natural;
signal selector         : std_logic;

begin

main: process(clk, reset_n)
begin
    if reset_n = '0' then
        state <= IDLE;
        counter <= 0;
        address <= ZERO_32;
        data <= ZERO_16;
        am_addr <= ZERO_32;
        am_be <= "0000";
        am_rd <= '0';
        FIFO_wr <= '0';
        FIFO_wrdata <= ZERO_16;

        row_counter <= 0;
        column_counter <= 0;
        selector <= '0';

    elsif rising_edge(clk) then
        am_addr <= ZERO_32;
        am_be <= "0000";
        am_rd <= '0';
        FIFO_wr <= '0';
        FIFO_wrdata <= ZERO_16;

        case state is 
        when IDLE =>
            -- wait for the address to change
            if buf_addr /= address then
                address <= buf_addr;
                state <= WAIT_FIFO;
            end if;

        when WAIT_FIFO =>
            -- wait for FIFO not to be almost empty or empty
            if FIFO_almostfull = '0' and FIFO_full = '0' then
                state <= SEND_ADDR;
            end if;

        when SEND_ADDR =>
            -- send the address to the RAM 
            am_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(address)) + row_counter * COLUMN + column_counter, 32));
            am_be <= "0000";
            am_rd <= '1';
            state <= READ_DATA;
            -- TODO try sending address when waitrequest = '1'

        when READ_DATA =>
            -- read the data from the avalon bus and send it to the fifo
            am_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(address)) + row_counter * COLUMN + column_counter, 32));
            am_be <= "0000";
            am_rd <= '1';
            if am_waitrq = '0' then

                FIFO_wr <= '1';
                if selector = '0' then
                    FIFO_wrdata <= am_rddata(15 downto 0);
                else
                    FIFO_wrdata <= am_rddata(31 downto 16);
                end if;

                row_counter <= row_counter + 1;

                if (row_counter + 1) = ROW then
                    row_counter <= 0;
                    selector <= '1';
                end if;

                if ((row_counter + 1) = ROW and (selector = '1')) then
                    row_counter <= 0;
                    column_counter <= column_counter + 1;
                    selector <= '0';
                end if;

                counter <= counter + 1;
                if ((counter + 1) = to_integer(unsigned(buf_length))) then 
                    counter <= 0;
                    row_counter <= 0;
                    column_counter <= 0;
                    selector <= '0';
                    state <= IDLE;
                else 
                    counter <= counter + 1;
                    if FIFO_almostfull = '0' and FIFO_full = '0' then
                        state <= SEND_ADDR;
                    else 
                        state <= WAIT_FIFO;
                    end if;
                end if;


            end if;

        end case;
    end if;

end process main;

end;
