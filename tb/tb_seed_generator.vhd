-- @file seed_generator_tb.vhd
-- @brief Exhaustive test for Seed Generator (Normalization + Sqrt Guess)
-- @output seed_gen_results.csv

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity seed_generator_tb is
end entity;

architecture behavior of seed_generator_tb is

    component seed_generator is
        port (
            clk, rst      : in std_logic;
            ready         : out std_logic;
            data_16       : in std_logic_vector(15 downto 0);
            seed          : out std_logic_vector(31 downto 0);
            rescale_shift : out integer range 0 to 31;
            data_norm     : out std_logic_vector(31 downto 0)
        );
    end component;

    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal ready         : std_logic;
    signal data_in       : std_logic_vector(15 downto 0) := (others => '0');
    signal seed_out      : std_logic_vector(31 downto 0);
    signal norm_out      : std_logic_vector(31 downto 0);
    signal shift_out     : integer range 0 to 31;
    
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Clock Generation
    clk <= not clk after CLK_PERIOD/2;

    -- DUT
    dut: seed_generator
        port map (
            clk           => clk,
            rst           => rst,
            ready         => ready,
            data_16       => data_in,
            seed          => seed_out,
            rescale_shift => shift_out,
            data_norm     => norm_out
        );

    -- Stimulus
    process
        file out_file : text open write_mode is "seed_gen_results.csv";
        variable out_line : line;
        variable i : integer;
    begin
        -- Header
        write(out_line, string'("input_dec,norm_hex,seed_hex,shift_dec"));
        writeline(out_file, out_line);

        rst <= '1'; wait for 20 ns; rst <= '0';

        -- Sweep 1 to 65535
        for i in 1 to 65535 loop
            data_in <= std_logic_vector(to_unsigned(i, 16));
            
            -- Wait for 'ready' signal logic
            -- Your logic requires input stability. We hold for a few clocks.
            wait for CLK_PERIOD * 4; 
            
            -- Log Data (Sampling at the stable point)
            write(out_line, i);
            write(out_line, string'(","));
            hwrite(out_line, norm_out);
            write(out_line, string'(","));
            hwrite(out_line, seed_out);
            write(out_line, string'(","));
            write(out_line, shift_out);
            writeline(out_file, out_line);
            
            -- Progress report
            if (i mod 10000 = 0) then 
                report "Processed " & integer'image(i); 
            end if;
        end loop;

        report "Seed Generator Test Complete.";
        wait;
    end process;

end architecture;