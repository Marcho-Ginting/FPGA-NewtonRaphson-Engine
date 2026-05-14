-- @file nr_polisher_tb.vhd
-- @brief Robust Testbench for Newton-Raphson Polisher
-- @output polisher_results.csv

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity nr_polisher_tb is
end entity;

architecture behavior of nr_polisher_tb is

    component nr_polisher is
        port (
            clk, rst, start : in std_logic;
            done            : out std_logic;
            seed_in         : in std_logic_vector(31 downto 0);
            quotient_in     : in std_logic_vector(31 downto 0);
            nr_out          : out std_logic_vector(31 downto 0)
        );
    end component;

    signal clk, rst, start, done : std_logic := '0';
    signal seed_s, quot_s, res_s : std_logic_vector(31 downto 0);
    constant CLK_PERIOD : time := 10 ns;

begin
    -- Clock Generation
    clk <= not clk after CLK_PERIOD/2;

    dut: nr_polisher
        port map (
            clk => clk, rst => rst, start => start, done => done,
            seed_in => seed_s, quotient_in => quot_s, nr_out => res_s
        );

    process
        file out_file : text open write_mode is "polisher_results.csv";
        variable out_line : line;
        variable i : integer;
        
        -- Q2.30 Constants
        constant ONE_Q30 : unsigned(31 downto 0) := x"40000000"; 
        constant MAX_Q30 : unsigned(31 downto 0) := x"7FFFFFFF"; 
        
        variable v_seed, v_quot : unsigned(31 downto 0);
        variable offset : unsigned(31 downto 0);
        
    begin
        write(out_line, string'("seed_hex,quot_hex,result_hex"));
        writeline(out_file, out_line);

        rst <= '1'; wait for 20 ns; rst <= '0';

        -- Sweep 65535 vectors
        for i in 0 to 65535 loop
            -- Create inputs in valid range [1.0, 2.0)
            offset := to_unsigned(i * 16384, 32); 
            
            v_seed := ONE_Q30 + offset;
            if v_seed > MAX_Q30 then v_seed := MAX_Q30; end if;
            
            v_quot := MAX_Q30 - offset;
            if v_quot < ONE_Q30 then v_quot := ONE_Q30; end if;
            
            -- Drive Signals
            seed_s <= std_logic_vector(v_seed);
            quot_s <= std_logic_vector(v_quot);
            
            wait for 10 ns;
            
            -- ROBUST HANDSHAKE:
            -- 1. Assert Start
            start <= '1'; 
            
            -- 2. Wait until hardware responds with Done
            wait until done = '1';
            
            -- 3. De-assert Start
            start <= '0';
            
            -- 4. Wait for clock to finish cycle
            wait for CLK_PERIOD;
            
            -- Log
            hwrite(out_line, seed_s);
            write(out_line, string'(","));
            hwrite(out_line, quot_s);
            write(out_line, string'(","));
            hwrite(out_line, res_s);
            writeline(out_file, out_line);
            
        end loop;
        
        report "Polisher Test Complete";
        wait;
    end process;
end architecture;