library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slaveCTRL is 
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
    
    -- Internal interface FIFO
    RdFIFO              : out std_logic;
    RdData              : in std_logic_vector(15 downto 0);
    FIFO_Empty          : in std_logic;
    FIFO_Almost_Empty   : in std_logic;

    -- Internal interface masterCTRL
    buf_addr            : out std_logic_vector(31 downto 0) := (others => '0');
    buf_length          : out std_logic_vector(31 downto 0) := (others => '0');

	-- External interface
	Data                : out std_logic_vector(15 downto 0);
    LCD_ON              : out std_logic;
    CSx                 : out std_logic;
    DCx                 : out std_logic;
    WRx                 : out std_logic;
    RDx                 : out std_logic
);
end slaveCTRL;

architecture comp of slaveCTRL is
    -- clk is 50 MHz (20 ns)
    constant max_CMD_data : natural := 15; -- max nbr of CMD data = 15

    type table is array(max_CMD_data-1 downto 0) of std_logic_vector(15 downto 0);
    type Tstate is (IDLE, WAIT_START, START_FRAME, WAIT_FIFO, DATA_FRAME, END_FRAME, CMD, DATA_CMD);

    constant CMD_START_FRAME    : std_logic_vector(15 downto 0) := "0000000000101100" ; -- 0x002C -> new frame
    constant CMD_NOP            : std_logic_vector(15 downto 0) := "0000000000000000" ; -- 0x0000 -> nop
    constant CYCLES4            : natural := 3 ; -- correspond to 4 cycles, {0, 1, 2, 3}

    signal buffer_addr          : std_logic_vector(31 downto 0) := (others => '0');
    signal buffer_length        : std_logic_vector(31 downto 0) := (others => '0');
    signal CMD_command          : std_logic_vector(15 downto 0) := CMD_NOP;
    signal CMD_numData          : std_logic_vector(5 downto 0);
    signal CMD_write            : std_logic_vector(1 downto 0) := "00";
    signal CMD_data             : table;

    signal pix_save             : std_logic_vector(15 downto 0) := (others => '0');
    signal state                : Tstate;
    signal address              : std_logic_vector(31 downto 0) := (others => '0');
    signal cnt_4c               : natural;
    signal cnt_data             : natural;
    signal cnt_CMD_data         : natural;
    signal done_CMD_write       : std_logic;
    signal writing_frame     : std_logic;
    
begin 


main : process(clk, nReset)
begin
    if nReset = '0' then
        state       <= IDLE;
         -- resetting data bus
        Data <= CMD_NOP;
        -- not reading from FIFO
        RdFIFO <= '0';
        -- CMD by default
        DCx <= '0';
        -- Not writing by default
        WRx <= '1';
        -- no IRQ by default
        AS_IRQ <= '0';
        -- defualt address
        address <= (others => '0');
        -- command done by default
        done_CMD_write <= '0';
        writing_frame <= '0';
        -- LCD off when reset
        LCD_ON <= '0';
        -- chip not selected when reset
        CSx <= '1';

    elsif rising_edge(clk) then
         -- resetting data bus
        Data <= CMD_NOP;
        -- not reading from FIFO
        RdFIFO <= '0';
        -- CMD by default
        DCx <= '0';
        -- Not writing by default
        WRx <= '1';
        -- no IRQ by default
        AS_IRQ <= '0';
        -- LCD on when running
        LCD_ON <= '1';
        -- chip select off by default
        CSx <= '1';

        writing_frame <= '0';

        -- FINITE STATE MACHINE
        case state is
        when IDLE => 
            -- The controller is waiting either for a command to be send 
            -- from the processor or for the buffer address to change, meaning 
            -- a new frame is available.

            -- reset counters for next action
            cnt_4c <= 0;
            cnt_data <= 0;

            if CMD_write(0) = '1' then
                -- new command
                state <= CMD;
            elsif buffer_addr /= address then
                -- buffer address changes -> new frame 
                address <= buffer_addr;
                state <= WAIT_START;
            end if;

        when WAIT_START =>
        -- wait for fifo to be not almost empty
            writing_frame <= '1';
            if FIFO_Almost_Empty = '0' and FIFO_Empty = '0' then
                -- change state
                state <= START_FRAME;
            end if;

        when START_FRAME =>
        -- The controller sends a start of frame command. 
        -- This state takes 4 cycles to execute.
            
            writing_frame <= '1';

            CSx <= '0';
            
            -- send command new frame to LCD
            Data <= CMD_START_FRAME;

            -- update counter CYCLES4
            cnt_4c <= cnt_4c + 1;

            if cnt_4c < 2 then
                WRx <= '0';
            end if;
            if cnt_4c = CYCLES4 then
                -- reset counter for next state DATA_FRAME
                cnt_4c <= 0;
                -- change state
                state <= WAIT_FIFO;
            end if;


        when WAIT_FIFO =>
            writing_frame <= '1';

            -- The controller waits for the FIFO to be almost full. 
            -- This allows a continuous data flow from the FIFO to the LCD

            if FIFO_Empty = '0' then
                -- will read FIFO at the next cycle
                RdFIFO <= '1';
                -- change state
                state <= DATA_FRAME;
            end if;
            

        when DATA_FRAME =>
            writing_frame <= '1';

            -- The controller sends a data from the FIFO while 
            -- there is some in it. This state takes 4 cycles to execute.

            CSx <= '0';

            -- sending Data
            DCx <= '1';
            -- update counter CYCLES4
            cnt_4c <= cnt_4c + 1;

            if cnt_4c < 2 then
                -- activate WR
                WRx <= '0';
            end if;

            if cnt_4c = 0 then
                -- save data FIFO
                pix_save <= RdData;
                Data <= RdData;
            else
                Data <= pix_save;

                if cnt_4c = CYCLES4 then
                    -- restart counter for the next pixel
                    cnt_4c <= 0;

                    if cnt_data = (to_integer(unsigned(buffer_length)) - 1) then
                        -- eof reached, change state
                        cnt_data <= 0;
                        state <= END_FRAME;
                    else
                        -- change pixel
                        cnt_data <= cnt_data + 1;
                        -- ask FIFO for a new line
                        if FIFO_Empty = '0' then
                            RdFIFO <= '1';
                        else 
                            state <= WAIT_FIFO;
                        end if;
                    end if;
                end if;
            end if;      


        when END_FRAME =>
            writing_frame <= '1';
            -- The controller sends a nop command to the LCD to finish the sending
            -- of the current frame. This state takes 4 cycles to execute.

            -- data bus already has the NOP command (check begining main process)
            CSx <= '0';

            -- update counter CYCLES4
            cnt_4c <= cnt_4c + 1;

            if cnt_4c < 2 then
                WRx <= '0';
            end if;
            if cnt_4c = CYCLES4 then
                -- SEND IRQ 
                AS_IRQ <= '1';
                -- change state
                state <= IDLE;
                writing_frame <= '0';
            end if;


        when CMD =>
            -- The controller sends a command located in the CMD_command 
            -- register to the LCD. This state takes 4 cycles to execute.

            CSx <= '0';

            -- send command to LCD
            Data <= CMD_command;

            -- update counter CYCLES4
            cnt_4c <= cnt_4c + 1;

            if cnt_4c < 2 then
                WRx <= '0';
            end if;

            if to_integer(unsigned(CMD_numData)) = 0 then

                if cnt_4c = CYCLES4 - 1 then 
                    done_CMD_write <= '1';
                elsif cnt_4c = CYCLES4 then 
                    cnt_4c <= 0;
                    done_CMD_write <= '0';
                    state <= IDLE;
                end if;
            else
                if cnt_4c = CYCLES4 then
                    -- reset counter for next state CMD_DATA
                    cnt_4c <= 0;
                    -- change state
                    state <= DATA_CMD;
                end if;
            end if;


        when DATA_CMD =>
            -- In this state the controller sends the data associated to 
            -- the command to the LCD. This state is repeated CMD_numData 
            -- times and takes 4 cycles to execute.

            -- sending data, not commands
            DCx <= '1';
            CSx <= '0';

            if cnt_data < to_integer(unsigned(CMD_numData)) then
                -- output new data
                Data <= CMD_data(cnt_data);

                -- update counter CYCLES4
                cnt_4c <= cnt_4c + 1;

                if cnt_4c < 2 then
                    -- activate WR
                    WRx <= '0';
                end if;
                if cnt_4c = CYCLES4 then
                    -- restart counter for the next pixel
                    cnt_4c <= 0;
                    -- change data to send
                    cnt_data <= cnt_data + 1;

                    if cnt_data = to_integer(unsigned(CMD_numData)) - 1 then
                        done_CMD_write <= '1';
                    end if;

                end if;
                


            else
                -- no more data left to send
                -- change state
                cnt_4c     <= 0;
                cnt_data   <= 0;
                state      <= IDLE;
                done_CMD_write <= '0';
            end if;
        end case;
    end if;
end process main;




slave_write : process(clk, nReset)
begin
    if nReset = '0' then
        -- reset all internal registers
        buffer_addr     <= (others => '0');
        buffer_length   <= (others => '0');
        CMD_command     <= (others => '0');
        CMD_numData     <= (others => '0');
        CMD_write       <= "00";
        for i in 0 to max_CMD_data - 1 loop
            CMD_data(i) <= (others => '0');
        end loop;


    elsif rising_edge(clk) then
        -- should we put the chip select before nReset ? or nReset restricted to this IP
        if done_CMD_write = '1' then
            CMD_write(0) <= '0';
        end if; 
        CMD_write(1) <= writing_frame;
        if AS_CS = '1' then
            if AS_Wr = '1' then
                case AS_addr is 
                    when "000" => buffer_addr       <= AS_WData;
                    when "001" => buffer_length     <= AS_WData;
                    when "010" => CMD_command       <= AS_WData(15 downto 0);
                    when "011" => 
                        CMD_numData                 <= AS_WData(5 downto 0);
                        cnt_CMD_data           <= 0;
                        
                    when "100" => 
                        if CMD_write(0) = '0' then
                            CMD_write(0)         <= AS_WData(0);
                        end if;
                    when "101" =>
                        CMD_data(cnt_CMD_data)      <= AS_WData(15 downto 0);

                        -- for no waitstate
                        if cnt_CMD_data < to_integer(unsigned(CMD_numData)) then
                            cnt_CMD_data       <= cnt_CMD_data + 1;
                        else
                            cnt_CMD_data       <= 0;
                        end if;
                    
                    when others => null;
                end case;
            end if;
        end if;
    end if;
end process slave_write;





slave_read : process(clk, nReset)
begin
    if rising_edge(clk) then
        -- should we put the chip select before nReset ? or nReset restricted to this IP
        AS_RData <= (others => '0');
        if AS_CS = '1' then
            if AS_Rd = '1' then
                case AS_addr(2 downto 0) is 
                    when "000" => AS_RData              <= buffer_addr;
                    when "001" => AS_RData              <= buffer_length;
                    when "010" => AS_RData(15 downto 0) <= CMD_command;
                    when "011" => AS_RData(5 downto 0)  <= CMD_numData;
                    when "100" => AS_RData(1 downto 0)  <= CMD_write;
                    when others => null;
                end case;
            end if;
        end if;
    end if;
end process slave_read;

buf_addr    <= buffer_addr;
buf_length  <= buffer_length;

--LCD_ON      <= '1';
--CSx         <= '0';
RDx <= '1';

end comp;