library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_top_level is 
port(
    clk                 : in std_logic;
	nReset              : in std_logic;

    -- Internal interface Avalon slave
	AS_addr             : in std_logic_vector(2 downto 0); -- 2 to 0 for address register
    AS_CS               : in std_logic;
    AS_Wr               : in std_logic;
    AS_WData            : in std_logic_vector(31 downto 0);
    AS_Rd               : in std_logic;
    AS_RData            : out std_logic_vector(31 downto 0);
    AS_IRQ              : out std_logic;

    -- External interface
	Data                : out std_logic_vector(15 downto 0);
    LCD_ON              : out std_logic;
    CSx                 : out std_logic;
    DCx                 : out std_logic;
    WRx                 : out std_logic;
    RDx                 : out std_logic;

    -- master
    am_addr             : out std_logic_vector(31 downto 0);
    am_be               : out std_logic_vector(3 downto 0);
    am_rd               : out std_logic;
    am_rddata           : in std_logic_vector(31 downto 0);
    am_waitrq           : in std_logic
);
end lcd_top_level;

architecture comp of lcd_top_level is

    -- Internal interface FIFO
    signal RdFIFO              : std_logic;
    signal RdData              : std_logic_vector(15 downto 0);
    signal FIFO_Empty          : std_logic;
    signal FIFO_Almost_Empty   : std_logic;

    -- Internal interface masterCTRL
    signal buf_addr            : std_logic_vector(31 downto 0) := (others => '0');
    signal buf_length          : std_logic_vector(31 downto 0) := (others => '0');

    -- FIFO
    signal FIFO_wr             : std_logic;
    signal FIFO_wrdata         : std_logic_vector(15 downto 0);
    signal FIFO_full           : std_logic;
    signal FIFO_almostfull     : std_logic;

begin

    lcd_controler : entity work.slaveCTRL 
    port map(
        clk => clk,
        nReset => nReset,
    
        -- Internal interface Avalon slave
        AS_addr => AS_addr,
        AS_CS => AS_CS,
        AS_Wr => AS_Wr,
        AS_WData => AS_WData,
        AS_Rd => AS_Rd,
        AS_RData => AS_RData,
        AS_IRQ => AS_IRQ,
        
        -- Internal interface FIFO
        RdFIFO => RdFIFO,
        RdData => RdData,
        FIFO_Empty => FIFO_Empty,
        FIFO_Almost_Empty => FIFO_Almost_Empty,
    
        -- Internal interface masterCTRL
        buf_addr => buf_addr,
        buf_length => buf_length,
    
        -- External interface
        Data => Data,
        LCD_ON => LCD_ON,
        CSx => CSx,
        DCx => DCx,
        WRx => WRx,
        RDx => RDx
    );

    lcd_master : entity work.LCD_Master
    port map(
        clk => clk,
        reset_n => nReset,

        -- registers
        buf_addr => buf_addr,
        buf_length => buf_length,

        -- master
        am_addr => am_addr,
        am_be => am_be,
        am_rd => am_rd,
        am_rddata => am_rddata,
        am_waitrq => am_waitrq,

        -- FIFO
        FIFO_wr => FIFO_wr,
        FIFO_wrdata => FIFO_wrdata,
        FIFO_full => FIFO_full,
        FIFO_almostfull => FIFO_almostfull   
    );

    fifo : entity work.FIFO
    port map (
        clock	 => clk,
        data	 => RdData,
        rdreq	 => RdFIFO,
        wrreq	 => FIFO_wr,
        almost_empty	 => FIFO_Almost_Empty,
        almost_full	 => FIFO_almostfull,
        empty	 => FIFO_Empty,
        full	 => FIFO_full,
        q	 => FIFO_wrdata
    ); 





end;