-- @file system_tb.vhd
-- @brief Exhaustive Integration Test for Newton-Raphson Sqrt Machine
-- @output system_results.csv

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity system_tb is
end entity;

architecture behavior of system_tb is

    -- DUT: The Top Level Entity
    component squarerootdigital is
        port (
            clk           : in std_logic;
            rst           : in std_logic;
            uart_rx_valid : in std_logic;
            uart_tx_start : out std_logic;
            uart_tx_busy  : out std_logic;
            uart_data_in  : in std_logic_vector(15 downto 0);
            uart_data_out : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal rx_valid      : std_logic := '0';
    signal tx_start      : std_logic;
    signal tx_busy       : std_logic;
    signal data_in       : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out      : std_logic_vector(15 downto 0);
    
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Clock Generation
    clk <= not clk after CLK_PERIOD/2;

    -- DUT Instantiation
    dut: squarerootdigital
        port map (
            clk           => clk,
            rst           => rst,
            uart_rx_valid => rx_valid,
            uart_tx_start => tx_start,
            uart_tx_busy  => tx_busy,
            uart_data_in  => data_in,
            uart_data_out => data_out
        );

    -- Main Stimulus Process
    process
        file out_file : text open write_mode is "system_results.csv";
        variable out_line : line;
        variable i : integer;
    begin
        -- Header
        write(out_line, string'("input_dec,output_q8_8_hex"));
        writeline(out_file, out_line);

        -- Reset Sequence
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Exhaustive Sweep 1 to 65535
        for i in 1 to 65535 loop
            
            -- 1. Drive Input
            data_in <= std_logic_vector(to_unsigned(i, 16));
            
            -- 2. Pulse Valid (Simulate UART Packet Received)
            rx_valid <= '1';
            wait for CLK_PERIOD;
            rx_valid <= '0';
            
            -- 3. Wait for Completion
            -- The machine goes IDLE -> PRE -> DIVIDE -> POLISH -> POST -> SEND
            -- We wait for the 'uart_tx_start' strobe.
            wait until tx_start = '1';
            
            -- 4. Sample Output immediately (tx_start is 1-cycle strobe)
            -- Note: Simulation might trigger 'wait' on the rising edge.
            -- We wait a tiny delta to ensure data is stable, though synchronous logic is fine.
            wait for 1 ns; 
            
            -- 5. Log Result
            write(out_line, i);
            write(out_line, string'(","));
            hwrite(out_line, data_out);
            writeline(out_file, out_line);
            
            -- 6. Back off for next cycle
            wait for CLK_PERIOD * 2;
            
            -- Progress Update (simulation takes longer now)
            if (i mod 5000 = 0) then 
                report "Processed Input: " & integer'image(i); 
            end if;
            
        end loop;

        report "Full System Exhaustive Test Complete.";
        wait;
    end process;

end architecture;