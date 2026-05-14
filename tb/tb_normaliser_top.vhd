-- @file normaliser_tb.vhd
-- @brief Exhaustive testbench for Normaliser (1 to 65535)
-- @output normaliser_results.csv

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_normaliser is
end entity;

architecture behavior of tb_normaliser is

    -- Component Declaration
    component normaliser_top is
        port (
            num_in        : in std_logic_vector(31 downto 0);
            den_in        : in std_logic_vector(31 downto 0);
            num_norm      : out std_logic_vector(31 downto 0);
            den_norm      : out std_logic_vector(31 downto 0);
            out_shift     : out std_logic_vector(4 downto 0);
            out_direction : out std_logic
        );
    end component;

    -- Signals
    signal num_in_s        : std_logic_vector(31 downto 0) := (others => '0');
    signal den_in_s        : std_logic_vector(31 downto 0) := (others => '0');
    signal num_norm_s      : std_logic_vector(31 downto 0);
    signal den_norm_s      : std_logic_vector(31 downto 0);
    signal out_shift_s     : std_logic_vector(4 downto 0);
    signal out_direction_s : std_logic;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: normaliser_top
        port map (
            num_in        => num_in_s,
            den_in        => den_in_s,
            num_norm      => num_norm_s,
            den_norm      => den_norm_s,
            out_shift     => out_shift_s,
            out_direction => out_direction_s
        );

    -- Stimulus Process
    stim_proc: process
        file out_file : text open write_mode is "normaliser_results.csv";
        variable out_line : line;
        variable i : integer;
        
    begin
        -- 1. Write Header to CSV
        write(out_line, string'("den_in_dec,num_in_hex,den_in_hex,den_norm_hex,num_norm_hex,shift_dec,dir_bit"));
        writeline(out_file, out_line);

        -- 2. Wait for system stability
        wait for 10 ns;

        -- 3. Loop from 1 to 65535 (Exhaustive low range)
        -- We fix num_in to a pattern to verify it shifts identically to den_in
        num_in_s <= x"AAAAAAAA"; 

        for i in 1 to 65535 loop
            -- Drive input
            den_in_s <= std_logic_vector(to_unsigned(i, 32));
            
            -- Wait for combinatorial logic to settle
            wait for 10 ns;
            
            -- Write Inputs (Decimal and Hex)
            write(out_line, i); -- den_in decimal
            write(out_line, string'(","));
            hwrite(out_line, num_in_s); -- num_in hex
            write(out_line, string'(","));
            hwrite(out_line, den_in_s); -- den_in hex
            write(out_line, string'(","));
            
            -- Write Outputs (Hex)
            hwrite(out_line, den_norm_s); -- den_norm
            write(out_line, string'(","));
            hwrite(out_line, num_norm_s); -- num_norm
            write(out_line, string'(","));
            
            -- Write Metadata
            write(out_line, to_integer(unsigned(out_shift_s)));
            write(out_line, string'(","));
            write(out_line, out_direction_s);

            writeline(out_file, out_line);
        end loop;

        report "Exhaustive test complete. Results written to normaliser_results.csv";
        wait;
    end process;

end architecture;