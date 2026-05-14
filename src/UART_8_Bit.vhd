library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_8_Bit is
    Generic (
        CLK_FREQ    : integer := 50000000; 
        BAUD_RATE   : integer := 9600      
    );
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        rx_pin      : in  STD_LOGIC;
        tx_pin      : out STD_LOGIC;
        tx_data     : in  STD_LOGIC_VECTOR(7 downto 0);
        tx_start    : in  STD_LOGIC;
        tx_busy     : out STD_LOGIC;
        rx_data     : out STD_LOGIC_VECTOR(7 downto 0);
        rx_dv       : out STD_LOGIC 
    );
end UART_8_Bit;

architecture Behavioral of UART_8_Bit is
    constant BIT_TIMER_LIMIT : integer := CLK_FREQ / BAUD_RATE;
    
    -- TX Signals
    type tx_states is (IDLE, START, DATA, STOP);
    signal tx_state : tx_states := IDLE;
    signal tx_timer : integer range 0 to BIT_TIMER_LIMIT := 0;
    signal tx_bit_idx : integer range 0 to 7 := 0;
    signal tx_shifter : std_logic_vector(7 downto 0) := (others => '0');

    -- RX Signals
    type rx_states is (IDLE, START, DATA, STOP);
    signal rx_state : rx_states := IDLE;
    signal rx_timer : integer range 0 to BIT_TIMER_LIMIT := 0;
    signal rx_bit_idx : integer range 0 to 7 := 0;
    signal rx_shifter : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_sync    : std_logic_vector(1 downto 0) := "11";

begin

    -- =======================
    -- TX PROCESS
    -- =======================
    process(clk, rst)
    begin
        -- FIX: Ubah '0' jadi '1' (Active High) agar sinkron dengan RX dan Top Level
        if rst = '1' then 
            tx_state <= IDLE;
            tx_pin <= '1';
            tx_busy <= '0';
            tx_timer <= 0;
        elsif rising_edge(clk) then
            case tx_state is
                when IDLE =>
                    tx_pin <= '1';
                    if tx_start = '1' then
                        tx_shifter <= tx_data;
                        tx_state <= START;
                        tx_busy <= '1';
                        tx_timer <= 0;
                    else
                        tx_busy <= '0';
                    end if;
                
                when START =>
                    tx_pin <= '0';
                    if tx_timer = BIT_TIMER_LIMIT - 1 then
                        tx_timer <= 0;
                        tx_state <= DATA;
                        tx_bit_idx <= 0;
                    else
                        tx_timer <= tx_timer + 1;
                    end if;
                    
                when DATA =>
                    tx_pin <= tx_shifter(tx_bit_idx);
                    if tx_timer = BIT_TIMER_LIMIT - 1 then
                        tx_timer <= 0;
                        if tx_bit_idx = 7 then
                            tx_state <= STOP;
                        else
                            tx_bit_idx <= tx_bit_idx + 1;
                        end if;
                    else
                        tx_timer <= tx_timer + 1;
                    end if;
                    
                when STOP =>
                    tx_pin <= '1';
                    if tx_timer = BIT_TIMER_LIMIT - 1 then
                        tx_state <= IDLE;
                        tx_busy <= '0';
                    else
                        tx_timer <= tx_timer + 1;
                    end if;
            end case;
        end if;
    end process;

    -- =======================
    -- RX PROCESS
    -- =======================
    process(clk, rst)
    begin
        if rst = '1' then
            rx_state <= IDLE;
            rx_dv <= '0';
            rx_sync <= "11";
        elsif rising_edge(clk) then
            rx_dv <= '0';
            rx_sync <= rx_sync(0) & rx_pin;
            
            case rx_state is
                when IDLE =>
                    if rx_sync(1) = '0' then 
                        rx_state <= START;
                        rx_timer <= 0;
                    end if;
                    
                when START =>
                    if rx_timer = (BIT_TIMER_LIMIT / 2) - 1 then 
                        if rx_sync(1) = '0' then
                            rx_state <= DATA;
                            rx_timer <= 0;
                            rx_bit_idx <= 0;
                        else
                            rx_state <= IDLE;
                        end if;
                    else
                        rx_timer <= rx_timer + 1;
                    end if;
                    
                when DATA =>
                    if rx_timer = BIT_TIMER_LIMIT - 1 then
                        rx_timer <= 0;
                        rx_shifter(rx_bit_idx) <= rx_sync(1);
                        if rx_bit_idx = 7 then
                            rx_state <= STOP;
                        else
                            rx_bit_idx <= rx_bit_idx + 1;
                        end if;
                    else
                        rx_timer <= rx_timer + 1;
                    end if;
                    
                when STOP =>
                    if rx_timer = BIT_TIMER_LIMIT - 1 then
                        rx_state <= IDLE;
                        rx_dv <= '1'; 
                        rx_data <= rx_shifter;
                    else
                        rx_timer <= rx_timer + 1;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;