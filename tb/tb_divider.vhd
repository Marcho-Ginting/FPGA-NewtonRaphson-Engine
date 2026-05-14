-- @file divider_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity divider_tb is
end entity;

architecture behavior of divider_tb is

    -- DUT: The Divider (Pure Math)
    component divider is
        port (
            clk, rst, start : in std_logic;
            finish          : out std_logic;
            numerator, denominator : in std_logic_vector(31 downto 0);
            quotient        : out std_logic_vector(31 downto 0)
        );
    end component;

    -- HELPER: Normalizer (Simulates the Pre-Processor)
    component normaliser_top is
        port (
            num_in, den_in     : in std_logic_vector(31 downto 0);
            num_norm, den_norm : out std_logic_vector(31 downto 0);
            out_shift          : out std_logic_vector(4 downto 0);
            out_direction      : out std_logic
        );
    end component;

    signal clk, rst, start, finish : std_logic := '0';
    signal raw_num, raw_den : std_logic_vector(31 downto 0);
    signal w_num_norm, w_den_norm, quot_out : std_logic_vector(31 downto 0);
    
    -- Metadata we don't need for the divider test, but the normalizer outputs it
    signal trash_s : std_logic_vector(4 downto 0);
    signal trash_d : std_logic;
    
    constant CLK_PERIOD : time := 10 ns;

begin
    clk <= not clk after CLK_PERIOD/2;

    -- 1. Helper Normalizer
    -- Converts 1..65353 into Q2.30 [1.0, 2.0) so the Divider logic works
    helper: normaliser_top port map (
        num_in => raw_num, den_in => raw_den,
        num_norm => w_num_norm, den_norm => w_den_norm,
        out_shift => trash_s, out_direction => trash_d
    );

    -- 2. DUT
    dut: divider port map (
        clk => clk, rst => rst, start => start, finish => finish,
        numerator => w_num_norm, denominator => w_den_norm, quotient => quot_out
    );

    process
        file out_file : text open write_mode is "divider_results.csv";
        variable out_line : line;
        variable i, v_num, v_den : integer;
    begin
        write(out_line, string'("raw_num,raw_den,quotient_hex"));
        writeline(out_file, out_line);

        rst <= '1'; wait for 20 ns; rst <= '0';

        -- Exhaustive Loop
        for i in 1 to 65353 loop
            v_den := i;
            -- Test Case: Ratio ~2.5. 
            -- (i*2 + i/2) creates a clean integer numerator.
            v_num := i - (i / 4);
            
            raw_den <= std_logic_vector(to_unsigned(v_den, 32));
            raw_num <= std_logic_vector(to_unsigned(v_num, 32));
            
            wait for 10 ns; -- Wait for Helper Normalizer
            
            start <= '1'; wait for CLK_PERIOD; start <= '0';
            wait until finish = '1'; wait for CLK_PERIOD;
            
            write(out_line, v_num); write(out_line, string'(","));
            write(out_line, v_den); write(out_line, string'(","));
            hwrite(out_line, quot_out); writeline(out_file, out_line);
            
            if (i mod 10000 = 0) then report "Progress: " & integer'image(i); end if;
        end loop;
        report "Done.";
        wait;
    end process;
end architecture;