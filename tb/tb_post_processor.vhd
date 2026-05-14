-- @file post_processor_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity post_processor_tb is
end entity;

architecture behavior of post_processor_tb is

    component post_processor is
        port (
            clk, rst, start : in std_logic;
            done            : out std_logic;
            nr_in           : in std_logic_vector(31 downto 0);
            rescale_shift   : in integer range 0 to 31;
            sqrt_out_16     : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk, rst, start, done : std_logic := '0';
    signal nr_in : std_logic_vector(31 downto 0);
    signal shift : integer range 0 to 31;
    signal result : std_logic_vector(15 downto 0);
    constant CLK_PERIOD : time := 10 ns;

begin
    clk <= not clk after CLK_PERIOD/2;

    dut: post_processor port map (
        clk => clk, rst => rst, start => start, done => done,
        nr_in => nr_in, rescale_shift => shift, sqrt_out_16 => result
    );

    process
        file out_file : text open write_mode is "post_proc_results.csv";
        variable out_line : line;
        variable i : integer;
        variable shift_calc : integer;
        variable input_q30 : unsigned(31 downto 0);
        
    begin
        write(out_line, string'("input_dec,nr_in_hex,shift_dec,result_hex"));
        writeline(out_file, out_line);

        rst <= '1'; wait for 20 ns; rst <= '0';

        for i in 1 to 65535 loop
            -- 1. Calculate Shift S (Position of MSB to Bit 30)
            shift_calc := 30 - integer(floor(log2(real(i))));
            
            -- 2. Simulate what the Core outputs: Sqrt(Normalized Input) in Q2.30
            -- Value = Sqrt( i * 2^S ) * 2^15 (adjustment for integer math representation)
            input_q30 := to_unsigned(integer(sqrt(real(i) * (2.0**real(shift_calc))) * 32768.0), 32);

            nr_in <= std_logic_vector(input_q30);
            shift <= shift_calc;
            
            wait for 10 ns;
            
            -- Robust Handshake
            start <= '1'; 
            wait until done = '1'; 
            start <= '0';          
            wait for CLK_PERIOD;
            
            write(out_line, i);
            write(out_line, string'(","));
            hwrite(out_line, nr_in);
            write(out_line, string'(","));
            write(out_line, shift);
            write(out_line, string'(","));
            hwrite(out_line, result);
            writeline(out_file, out_line);
            
            if (i mod 10000 = 0) then report "Processed " & integer'image(i); end if;
        end loop;
        
        report "Post-Processor Test Complete.";
        wait;
    end process;
end architecture;