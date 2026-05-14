-- @file pre_processor_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity pre_processor_tb is
end entity;

architecture behavior of pre_processor_tb is

    component pre_processor is
        port (
            raw_data_in   : in std_logic_vector(15 downto 0);
            rom_address   : out std_logic_vector(9 downto 0);
            rescale_shift : out integer range 0 to 31;
            data_norm     : out std_logic_vector(31 downto 0)
        );
    end component;

    signal raw_in      : std_logic_vector(15 downto 0) := (others => '0');
    signal rom_addr    : std_logic_vector(9 downto 0);
    signal shift_amt   : integer range 0 to 31;
    signal norm_out    : std_logic_vector(31 downto 0);
    
    constant CLK_PERIOD : time := 10 ns;

begin

    dut: pre_processor
        port map (
            raw_data_in   => raw_in,
            rom_address   => rom_addr,
            rescale_shift => shift_amt,
            data_norm     => norm_out
        );

    process
        file out_file : text open write_mode is "pre_processor_results.csv";
        variable out_line : line;
        variable i : integer;
    begin
        -- Header
        write(out_line, string'("raw_dec,norm_hex,addr_hex,shift_dec"));
        writeline(out_file, out_line);

        wait for 20 ns;

        -- Sweep 1 to 65535
        for i in 1 to 65535 loop
            raw_in <= std_logic_vector(to_unsigned(i, 16));
            
            wait for 10 ns; -- Combinatorial settle
            
            write(out_line, i);
            write(out_line, string'(","));
            hwrite(out_line, norm_out);
            write(out_line, string'(","));
            hwrite(out_line, "00" & rom_addr); -- Pad for clean hex
            write(out_line, string'(","));
            write(out_line, shift_amt);
            writeline(out_file, out_line);
            
            if (i mod 10000 = 0) then report "Processed " & integer'image(i); end if;
        end loop;

        report "Pre-Processor Test Complete.";
        wait;
    end process;

end architecture;