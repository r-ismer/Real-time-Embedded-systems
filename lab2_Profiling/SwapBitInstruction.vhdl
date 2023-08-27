library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SwapBit is
    port(
        dataa : in std_logic_vector(31 downto 0);
        result : out std_logic_vector(31 downto 0)

        );
end SwapBit;

architecture comp of SwapBit is
begin
    result(7 downto 0) <= dataa(31 downto 24);
    result(8) <= dataa(23);
    result(9) <= dataa(22);
    result(10) <= dataa(21);
    result(11) <= dataa(20);
    result(12) <= dataa(19);
    result(13) <= dataa(18);
    result(14) <= dataa(17);
    result(15) <= dataa(16);
    result(16) <= dataa(15);
    result(17) <= dataa(14);
    result(18) <= dataa(13);
    result(19) <= dataa(12);
    result(20) <= dataa(11);
    result(21) <= dataa(10);
    result(22) <= dataa(9);
    result(23) <= dataa(8);
    result(31 downto 24) <= dataa(7 downto 0);
end comp;