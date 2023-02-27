library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ParallelPort is
    generic(
        width : integer := 32
    );
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- Avalon Slave
        read : in std_logic;
        readdata : out std_logic_vector(width-1 downto 0);
        write : in std_logic;
        writedata : in std_logic_vector(width-1 downto 0);
        address : in std_logic_vector(2 downto 0);

        -- Conduit
        ParallelPortConduit : inout std_logic_vector(width-1 downto 0)
    );
end ParallelPort;

architecture comp of ParallelPort is
    signal iRegDirection : std_logic_vector(width-1 downto 0);
    signal iRegPort : std_logic_vector(width-1 downto 0);
    signal iRegPins : std_logic_vector(width-1 downto 0);
begin
    iRegPins <= ParallelPortConduit;

    slave_read : process(clk,nReset)
    begin
        if nReset = '0' then
        elsif rising_edge(clk) then
            -- Avalon Slave read
            if read = '1' then
                readdata <= (others => '0');
                case address is
                    when "000" => readdata <= iRegPins;
                    when "001" => readdata <= iRegPort;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    slave_write : process(clk,nReset)
    begin
        if nReset = '0' then
        elsif rising_edge(clk) then
            -- Avalon Slave write
            if write = '1' then
                case address is
                    when "000" => null;
                    when "001" => iRegDirection <= writedata;
                    when "010" => iRegPort <= writedata;
                    when "011" => iRegPort <= iRegPort and (not writedata); -- clear
                    when "100" => iRegPort <= iRegPort or writedata; -- set
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    port_logic : process(iRegDirection,iRegPort)
    begin
        for i in 0 to width-1 loop
            if iRegDirection(i) = '0' then
                ParallelPortConduit(i) <= 'Z';
            else
                ParallelPortConduit(i) <= iRegPort(i);
            end if;
        end loop;
    end process;

end comp;