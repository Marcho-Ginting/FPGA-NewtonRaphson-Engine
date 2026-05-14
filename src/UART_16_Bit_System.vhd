library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_16_Bit_System is
    Generic (
        CLK_FREQ    : integer := 50000000;
        BAUD_RATE   : integer := 9600
    );
    Port (
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;
        
        -- External Pins (Connect to FPGA constraints)
        uart_rx_pin     : in  STD_LOGIC;
        uart_tx_pin     : out STD_LOGIC;
        
        -- Your User System Interface (16-bit Numbers)
        -- To Send a number: Place value on tx_data, pulse tx_start high for 1 clock
        tx_data_16      : in  STD_LOGIC_VECTOR(15 downto 0);
        tx_start        : in  STD_LOGIC;
        tx_busy         : out STD_LOGIC; -- Wait for this to be 0 before sending
        
        -- To Receive a number: Check rx_valid, read rx_data
        rx_data_16      : out STD_LOGIC_VECTOR(15 downto 0);
        rx_valid        : out STD_LOGIC
    );
end UART_16_Bit_System;

architecture Behavioral of UART_16_Bit_System is

    -- Signals for 8-bit core
    signal u8_tx_data  : std_logic_vector(7 downto 0);
    signal u8_tx_start : std_logic;
    signal u8_tx_busy  : std_logic;
    signal u8_rx_data  : std_logic_vector(7 downto 0);
    signal u8_rx_dv    : std_logic;
    
    -- State Machines
    type tx_state_t is (IDLE, SEND_LOW, WAIT_LOW, SEND_HIGH, WAIT_HIGH);
    signal tx_state : tx_state_t := IDLE;
    
    type rx_state_t is (IDLE, WAIT_HIGH);
    signal rx_state : rx_state_t := IDLE;
    signal rx_temp_low : std_logic_vector(7 downto 0);

begin

    -- Instantiate the 8-bit Core
    UART_CORE: entity work.UART_8_Bit
    generic map (
        CLK_FREQ => CLK_FREQ,
        BAUD_RATE => BAUD_RATE
    )
    port map (
        clk => clk,
        rst => rst,
        rx_pin => uart_rx_pin,
        tx_pin => uart_tx_pin,
        tx_data => u8_tx_data,
        tx_start => u8_tx_start,
        tx_busy => u8_tx_busy,
        rx_data => u8_rx_data,
        rx_dv => u8_rx_dv
    );

    -- ===========================
    -- 16-BIT TRANSMIT LOGIC
    -- ===========================
    process(clk, rst)
    begin
        if rst = '1' then
            tx_state <= IDLE;
            u8_tx_start <= '0';
            tx_busy <= '0';
        elsif rising_edge(clk) then
            case tx_state is
                when IDLE =>
                    if tx_start = '1' then
                        tx_busy <= '1';
                        u8_tx_data <= tx_data_16(7 downto 0); -- Send Low Byte
                        u8_tx_start <= '1';
                        tx_state <= SEND_LOW;
                    else
                        tx_busy <= '0';
                    end if;
                    
                when SEND_LOW =>
                    u8_tx_start <= '0';
                    if u8_tx_busy = '1' then -- Wait for core to accept
                        tx_state <= WAIT_LOW;
                    end if;
                    
                when WAIT_LOW =>
                    if u8_tx_busy = '0' then -- Core finished sending Low Byte
                        u8_tx_data <= tx_data_16(15 downto 8); -- Send High Byte
                        u8_tx_start <= '1';
                        tx_state <= SEND_HIGH;
                    end if;
                    
                when SEND_HIGH =>
                    u8_tx_start <= '0';
                    if u8_tx_busy = '1' then
                        tx_state <= WAIT_HIGH;
                    end if;
                    
                when WAIT_HIGH =>
                    if u8_tx_busy = '0' then -- Core finished sending High Byte
                        tx_state <= IDLE;
                        tx_busy <= '0';
                    end if;
            end case;
        end if;
    end process;

    -- ===========================
    -- 16-BIT RECEIVE LOGIC
    -- ===========================
    process(clk, rst)
    begin
        if rst = '1' then
            rx_state <= IDLE;
            rx_valid <= '0';
            rx_temp_low <= (others => '0');
        elsif rising_edge(clk) then
            rx_valid <= '0'; -- Pulse default
            
            case rx_state is
                when IDLE =>
                    if u8_rx_dv = '1' then
                        rx_temp_low <= u8_rx_data; -- Capture Low Byte
                        rx_state <= WAIT_HIGH;
                    end if;
                    
                when WAIT_HIGH =>
                    if u8_rx_dv = '1' then
                        -- Capture High Byte and Output
                        rx_data_16 <= u8_rx_data & rx_temp_low;
                        rx_valid <= '1';
                        rx_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;