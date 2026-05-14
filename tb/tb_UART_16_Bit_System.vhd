library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_UART_16_Bit_System is
-- Testbench has no ports
end tb_UART_16_Bit_System;

architecture Behavioral of tb_UART_16_Bit_System is

    -- Component Declaration for the Unit Under Test (UUT)
    component UART_16_Bit_System
    Generic (
        CLK_FREQ    : integer;
        BAUD_RATE   : integer
    );
    Port (
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;
        uart_rx_pin     : in  STD_LOGIC;
        uart_tx_pin     : out STD_LOGIC;
        tx_data_16      : in  STD_LOGIC_VECTOR(15 downto 0);
        tx_start        : in  STD_LOGIC;
        tx_busy         : out STD_LOGIC;
        rx_data_16      : out STD_LOGIC_VECTOR(15 downto 0);
        rx_valid        : out STD_LOGIC
    );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal uart_rx_pin : std_logic := '1'; -- UART idle is High
    signal tx_data_16 : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_start : std_logic := '0';

    -- Outputs
    signal uart_tx_pin : std_logic;
    signal tx_busy : std_logic;
    signal rx_data_16 : std_logic_vector(15 downto 0);
    signal rx_valid : std_logic;

    -- Clock period definitions
    constant clk_period : time := 20 ns; -- 50 MHz Clock
    
    -- SIMULATION SPEED-UP
    -- We use a very high baud rate relative to the clock just for simulation speed.
    -- In real hardware (50MHz clock), 9600 baud takes forever to simulate.
    -- Here: 50MHz Clock, 5MBaud -> 10 clocks per bit. Fast simulation.
    constant SIM_CLK_FREQ  : integer := 50000000;
    constant SIM_BAUD_RATE : integer := 5000000; 

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: UART_16_Bit_System
    Generic map (
        CLK_FREQ  => SIM_CLK_FREQ,
        BAUD_RATE => SIM_BAUD_RATE
    )
    Port map (
        clk => clk,
        rst => rst,
        -- LOOPBACK CONNECTION: RX is connected to TX
        uart_rx_pin => uart_tx_pin, 
        uart_tx_pin => uart_tx_pin,
        
        tx_data_16 => tx_data_16,
        tx_start => tx_start,
        tx_busy => tx_busy,
        rx_data_16 => rx_data_16,
        rx_valid => rx_valid
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- 1. Hold Reset
        rst <= '1';
        wait for 100 ns;	
        rst <= '0';
        wait for 100 ns;

        -- 2. Send First 16-bit Number: 0xAB12 (43794 decimal)
        -- The system should send Low Byte (0x12) then High Byte (0xAB)
        report "Starting Test 1: Sending 0xAB12";
        tx_data_16 <= x"AB12";
        tx_start   <= '1';
        wait for clk_period; -- Pulse start for 1 clock
        tx_start   <= '0';

        -- 3. Wait for transmission and reception to finish
        -- We wait until the system is no longer busy AND we receive valid data
        wait until rx_valid = '1';
        
        -- 4. Verify Result
        if rx_data_16 = x"AB12" then
            report "TEST 1 PASSED: Received 0xAB12 correctly." severity note;
        else
            report "TEST 1 FAILED: Expected 0xAB12 but got " & integer'image(to_integer(unsigned(rx_data_16))) severity error;
        end if;

        wait for 500 ns;

        -- 5. Send Second 16-bit Number: 0x3E80 (16000 decimal)
        report "Starting Test 2: Sending 0x3E80";
        tx_data_16 <= x"3E80";
        tx_start   <= '1';
        wait for clk_period;
        tx_start   <= '0';
        
        wait until rx_valid = '1';
        
        if rx_data_16 = x"3E80" then
            report "TEST 2 PASSED: Received 0x3E80 correctly." severity note;
        else
            report "TEST 2 FAILED: Expected 0x3E80 but got " & integer'image(to_integer(unsigned(rx_data_16))) severity error;
        end if;

        report "ALL TESTS COMPLETED";
        wait;
    end process;

end Behavioral;