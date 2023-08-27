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
        -- IRQ signal exported to the pins
        irq_pin : out std_logic
    );
end Timer;

architecture comp of Timer is
    signal iRegCount : unsigned(31 downto 0);
    signal iRegCompare : unsigned(31 downto 0);
    signal iRegEnable : std_logic;
    signal iRegEOT : std_logic;
    signal iRegIrqEnable : std_logic;

    signal iClrEOT : std_logic;
    signal iReset : std_logic;
begin

slave_write : process(clk,nReset)
begin
    if nReset = '0' then
        iRegEnable <= '0';
        iReset <= '0';
        iRegIrqEnable <= '0';
        iRegCompare <= (others => '0');

    elsif rising_edge(clk) then
        iReset <= '0';
        iClrEOT <= '0';
        if write = '1' then
            case address is
                when "000" => null;
                when "001" => iRegCompare <= unsigned(writedata);
                when "010" => iRegEnable <= writedata(0);
                when "011" => iClrEOT <= writedata(0);
                when "100" => iRegIrqEnable <= writedata(0);
                when "101" => iReset <= '1';
                when others => null;
            end case;
        end if;
    end if;
end process;


slave_read : process(clk,nReset)
begin
    if rising_edge(clk) then
        readdata <= (others => '0');
        if read = '1' then
            case address is
                when "000" => readdata <= std_logic_vector(iRegCount);
                when "001" => readdata <= std_logic_vector(iRegCompare);
                when "010" => readdata(0) <= iRegEnable;
                when "011" => readdata(0) <= iRegEOT;
                when "100" => readdata(0) <= iRegIrqEnable;
                when others => null;
            end case;
        end if;
    end if;
end process;


count : process(clk,nReset)
begin
    if rising_edge(clk) then
        if iReset = '1' then
            iRegCount <= (others => '0');
        elsif iRegEnable = '1' then
            iRegCount <= iRegCount + 1;
        end if;
    end if;
end process;


interrupt : process(clk,nReset)
begin
    if rising_edge(clk) then
        if iRegCount = iRegCompare then
            iRegEOT <= '1';
        elsif iClrEOT = '1' then
            iRegEOT <= '0';
        end if;
    end if;
end process;

irq_pin <= '1' when iRegEOT = '1' and iRegIrqEnable = '1' and iRegEnable = '1' else '0';
irq <= '1' when iRegEOT = '1' and iRegIrqEnable = '1' and iRegEnable = '1' else '0';

end comp;