-- @file goldschmidt_q30_tb.vhd
-- @brief Exhaustive Q2.30 Testbench
-- @output goldschmidt_q30_results.csv

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity goldschmidt_tb is
end entity;

architecture behavior of goldschmidt_tb is
    component goldschmidt is
        port (
            clk, rst, start : in std_logic;
            finish          : out std_logic;
            num_norm        : in std_logic_vector(31 downto 0);
            den_norm        : in std_logic_vector(31 downto 0);
            initial_guess   : in std_logic_vector(31 downto 0);
            quotient_out    : out std_logic_vector(31 downto 0)
        );
    end component;

    component gs_initial_guess is
        port (
            address   : in std_logic_vector(7 downto 0);
            guess_out : out std_logic_vector(31 downto 0)
        );
    end component;

    signal clk, rst, start, finish : std_logic := '0';
    signal num_s, den_s, guess_s, quot_s : std_logic_vector(31 downto 0);
    constant CLK_PERIOD : time := 10 ns;

begin
    -- Clock
    clk <= not clk after CLK_PERIOD/2;

    -- DUT
    dut: goldschmidt port map (
        clk => clk, rst => rst, start => start, finish => finish,
        num_norm => num_s, den_norm => den_s,
        initial_guess => guess_s, quotient_out => quot_s
    );

    -- ROM (Wired for Q2.30)
    -- MSB is at Bit 29 (Value 0.5). We use the NEXT 8 bits for lookup.
    -- That means bits 28 downto 21.
    rom: gs_initial_guess port map (
        address => den_s(28 downto 21),
        guess_out => guess_s
    );

    -- STIMULUS
    process
        file out_file : text open write_mode is "goldschmidt_q30_results.csv";
        variable out_line : line;
        
        -- Use a variable for the denominator so we can manually increment it
        variable v_den : unsigned(31 downto 0); 
        
        -- 1.0 in Q2.30 is 2^30 = 0x40000000
        constant ONE_Q30 : std_logic_vector(31 downto 0) := x"40000000";
        
        -- Start at 0.5 (0x20000000)
        constant START_VAL : unsigned(31 downto 0) := x"20000000";
        
        -- End at ~1.0 (0x40000000)
        constant END_VAL   : unsigned(31 downto 0) := x"40000000";
        
        -- Step size (approx 65,000 to keep simulation time reasonable)
        constant STEP      : integer := 65536; 

    begin
        -- Header
        write(out_line, string'("den_hex,num_hex,quotient_hex"));
        writeline(out_file, out_line);

        -- Reset
        rst <= '1'; 
        wait for 20 ns; 
        rst <= '0';
        
        -- Fix Numerator to 1.0
        num_s <= ONE_Q30;

        -- Initialize Variable
        v_den := START_VAL;

        -- WHILE LOOP allows custom stepping
        while v_den < END_VAL loop
            
            -- Drive the signal
            den_s <= std_logic_vector(v_den);
            
            -- Pulse Start
            start <= '1'; 
            wait for CLK_PERIOD; 
            start <= '0';
            
            -- Wait for Finish
            wait until finish = '1'; 
            wait for CLK_PERIOD;
            
            -- Log Results
            hwrite(out_line, den_s); 
            write(out_line, string'(","));
            hwrite(out_line, num_s); 
            write(out_line, string'(","));
            hwrite(out_line, quot_s); 
            writeline(out_file, out_line);
            
            -- Manual Increment
            v_den := v_den + STEP;
            
            wait for CLK_PERIOD;
        end loop;
        
        report "Q2.30 Test Complete";
        wait;
    end process;
end architecture;