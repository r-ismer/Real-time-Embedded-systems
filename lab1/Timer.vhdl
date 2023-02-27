library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Timer is
    port(
        clk : in std_logic;
        nReset : in std_logic;

        -- Avalon slave interface
        read : in std_logic;
        readdata : out std_logic_vector(31 downto 0);
        write : in std_logic;
        writedata : in std_logic_vector(31 downto 0);
        address : in std_logic_vector(2 downto 0);

        -- interrupt
        irq : out std_logic;
    );
end Timer;

architecture comp of Timer is
    signal iRegCount : unsigned(31 downto 0);
    signal iRegComp : std_logic_vector(31 downto 0);
    signal iRegEnable : std_logic;
    signal iRegStatus : std_logic_vector(31 downto 0);
    signal iRegIrqEnable : std_logic;

    signal iClrEOF : std_logic;
    signal iReset : std_logic;
    signal 
begin

slave_write : process(clk,nReset)
begin
    if nReset = '0' then

    elsif rising_edge(clk) then
        if write = '1' then
            case address is
                when "000" => iRegCount <= 
                when "001" => 

    end if;
end process;


slave_read : process(clk,nReset)










process(clk,nReset)
    begin
    -- Reset
    if nReset = '0' then
        iRegCount <= (others => '0');
        readdata <= (others => '0');
        iRegActive <= '0';
    elsif rising_edge(clk) then
        -- Avalon Slave read
        if read = '1' then
            case Address is
                when "00" => readdata <= iRegCount;
                when others => null;
            end case;
        end if;
        -- Avalon Slave write
        if write = '1' then
            case address is
                when "00" => iRegCount <= writedata;
                when "01" => iRegCount <= (others => '0'); -- CLEAR
                when "10" => iRegActive <= '1'; -- START
                when "11" => iRegActive <= '0'; -- PAUSE
                when others => null;
            end case;
        -- Counter incrementation
        elsif iRegActive = '1' then
            iRegCount <= std_logic_vector(unsigned(iRegCount) + 1);
        end if;
    end if;
end process;
end comp;