library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter is
    port(
        clk : in std_logic;
        reset_n : in std_logic;

        as_address :        in std_logic;
        as_read :           in std_logic;
        as_readdata :       out std_logic_vector(31 downto 0);
        as_write :          in std_logic;
        as_writedata :      in std_logic_vector(31 downto 0)
    );
end entity Counter;

architecture comp of Counter is
    signal value : unsigned(31 downto 0);

begin
    slave_read: process(clk, reset_n)
    begin
        if reset_n = '0' then 
            as_readdata <= (others => '0');
        elsif rising_edge(clk) then
            if as_read = '1' then
                as_readdata <= (others => '0');
                case as_address is
                when '0' => 
                    as_readdata <= std_logic_vector(value);
                when others => null;
                end case;
            end if;
        end if;
    end process;
    
    slave_write: process(clk, reset_n)
    begin
        if reset_n = '0' then
            value <= (others => '0');
        elsif rising_edge(clk) then
            if as_write = '1' then
                case as_address is
                when '0' =>
                    value <= unsigned(as_writedata);
                when '1' => 
                    value <= unsigned(as_writedata) + value;
                when others => null;
                end case;
            end if;
        end if;
    end process;

end comp;