library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity swapbitdma_tb is
end entity swapbitdma_tb;


architecture comp of swapbitdma_tb is
    constant CLK_PERIOD : time := 20 ns; -- PARAMETER

    signal clk :               std_logic;
     signal reset_n :          std_logic;

    signal as_address :        std_logic_vector(1 downto 0);
    signal as_read :           std_logic;
    signal as_readdata :       std_logic_vector(31 downto 0);
    signal as_write :          std_logic;
    signal as_writedata :      std_logic_vector(31 downto 0);

    signal am_address :        std_logic_vector(31 downto 0);
    signal am_read :           std_logic;
    signal am_readdata :       std_logic_vector(31 downto 0);
    signal am_write :          std_logic;
    signal am_writedata :      std_logic_vector(31 downto 0);
    signal am_wait_request :   std_logic;
    signal am_byte_enable :    std_logic_vector(3 downto 0);

    begin
        UUT: entity work.swapbitdma port map(
            clk => clk,
            reset_n => reset_n,
            as_address => as_address,
            as_read => as_read,
            as_readdata => as_readdata,
            as_write => as_write,
            as_writedata => as_writedata,
        
            am_address => am_address,
            am_read =>  am_read,
            am_readdata => am_readdata,
            am_write => am_write,
            am_writedata => am_writedata,
            am_wait_request => am_wait_request,
            am_byte_enable => am_byte_enable
        );

        -- CLOCK generation
        clock_generation : process
        begin
            clk <= '1';
            wait for CLK_PERIOD/2;
            clk <= '0';
            wait for CLK_PERIOD/2;
        end process clock_generation;

        simulation : process
        begin
            reset_n <= '0';
            wait for 20 ns;
            reset_n <= '1';
            --wait for 20 ns;
            am_wait_request <= '0';
            am_readdata <= x"89ABCDEF";
            as_read <= '0';
            as_address <= "00";
            as_writedata <= x"12345678";
            as_write <= '1';
            wait for 20 ns;
            as_address <= "01";
            as_writedata <= x"00000000"; --x"76543210";
            wait for 20 ns;     
            as_address <= "10";
            as_writedata <= "00000000000000000000000000000011";
            wait for 20 ns;
            as_address <= "11";
            as_writedata <= x"FFFFFFFF";
            wait for 20 ns;
            as_write <= '0';

            wait for 40 ns;
            am_wait_request <= '1';
            wait for 40 ns;
            am_wait_request <= '0';
            wait for 5000 ns;

        end process;

end comp;