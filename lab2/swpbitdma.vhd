library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity swapbitdma is
    port(
        clk :               in std_logic;
        reset_n :           in std_logic;

        as_address :        in std_logic_vector(1 downto 0);
        as_read :           in std_logic;
        as_readdata :       out std_logic_vector(31 downto 0);
        as_write :          in std_logic;
        as_writedata :      in std_logic_vector(31 downto 0);

        am_address :        out std_logic_vector(31 downto 0);
        am_read :           out std_logic;
        am_readdata :       in std_logic_vector(31 downto 0);
        am_write :          out std_logic;
        am_writedata :      out std_logic_vector(31 downto 0);
        am_wait_request :   in std_logic;
        am_byte_enable :    out std_logic_vector(3 downto 0)
    );
end entity swapbitdma;

architecture comp of swapbitdma is

    type States is (IDLE, RETRIEVE, SEND);
    signal state : States;

    signal read_address :   std_logic_vector(31 downto 0);
    signal write_address :  std_logic_vector(31 downto 0);
    signal length :         std_logic_vector(31 downto 0);
    signal start :          std_logic;

    signal index :          unsigned(31 downto 0);

    signal data :           std_logic_vector(31 downto 0);

begin
    slave_read: process(clk, reset_n)
    begin
        if reset_n = '0' then 
            as_readdata <= (others => '0');
        elsif rising_edge(clk) then
            if as_read = '1' then
                as_readdata <= (others => '0');
                case as_address is
                when "00" => 
                    as_readdata <= read_address;
                when "01" => 
                    as_readdata <= write_address;
                when "10" => 
                    as_readdata <= length;
                when "11" =>
                    if state /= IDLE then
                        as_readdata(0) <= '0';
                    else
                        as_readdata(0) <= '1';
                    end if;
                when others => null;
                end case;
            end if;
        end if;
    end process;

    slave_write: process(clk, reset_n)
    begin
        if reset_n = '0' then
            read_address <= (others => '0');
            write_address <= (others => '0');
            length <= (others => '0');
            start <= '0';
        elsif rising_edge(clk) then
            start <= '0';
            if as_write = '1' then
                case as_address is
                when "00" =>
                    read_address <= as_writedata;
                when "01" => 
                    write_address <= as_writedata;
                when "10" => 
                    length <= as_writedata;
                when "11" =>
                    start <= as_writedata(0);
                when others => null;
                end case;
            end if;
        end if;
    end process;

    am_process: process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            index <= (others => '0');
            am_address <= (others => '0');
            am_read <= '0';
            am_write <= '0';
            am_writedata <= (others => '0');
            am_byte_enable <= (others => '0');
        elsif rising_edge(clk) then

            case state is 
            when IDLE =>
                index <= (others => '0');
                if start = '1' then
                    state <= RETRIEVE;
                end if;
            when RETRIEVE => 
                am_address <= std_logic_vector((unsigned(read_address) + (index*4)));
                am_read <= '1';
                am_byte_enable <= "1111";
                if am_wait_request = '0' then 
                    state <= SEND;
                    am_read <= '0';
                    data(7 downto 0) <= am_readdata(31 downto 24);
                    data(8) <= am_readdata(23);
                    data(9) <= am_readdata(22);
                    data(10) <= am_readdata(21);
                    data(11) <= am_readdata(20);
                    data(12) <= am_readdata(19);
                    data(13) <= am_readdata(18);
                    data(14) <= am_readdata(17);
                    data(15) <= am_readdata(16);
                    data(16) <= am_readdata(15);
                    data(17) <= am_readdata(14);
                    data(18) <= am_readdata(13);
                    data(19) <= am_readdata(12);
                    data(20) <= am_readdata(11);
                    data(21) <= am_readdata(10);
                    data(22) <= am_readdata(9);
                    data(23) <= am_readdata(8);
                    data(31 downto 0) <= am_readdata(7 downto 0);
                end if;
            when SEND => 
                am_address <= std_logic_vector(unsigned(write_address) + (index*4));
                am_write <= '1';
                am_writedata <= data;
                if am_wait_request = '0' then
                    index <= index + 1;
                    am_write <= '0';
                    if index + 1 >= unsigned(length) then 
                        index <= (others => '0');
                        state <= IDLE;
                    end if;
                end if;
            when others => null;
            end case;
        end if;
    end process;

end comp;


