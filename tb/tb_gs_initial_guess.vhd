library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity initial_guess_rom_tb is
end entity;

architecture sim of initial_guess_rom_tb is
    signal t_addr : std_logic_vector(7 downto 0);
    signal t_f0   : std_logic_vector(31 downto 0);
begin
    dut: entity work.gs_initial_guess
        port map (address => t_addr, guess_out => t_f0);

    process
    begin
        -- Address 0x00 corresponds to Denominator = 0.5
        -- 1/0.5 should be 2.0 (0x00020000)
        t_addr <= x"00";
        wait for 10 ns;
        report "Addr 0x00 (D=0.5) Result: " & to_hstring(t_f0);

        -- Address 0x80 corresponds to Denominator = 0.75
        -- 1/0.75 should be 1.333 (approx 0x00015555)
        t_addr <= x"80";
        wait for 10 ns;
        report "Addr 0x80 (D=0.75) Result: " & to_hstring(t_f0);

        -- Address 0xFF corresponds to Denominator ~1.0
        -- 1/1.0 should be 1.0 (0x00010000)
        t_addr <= x"FF";
        wait for 10 ns;
        report "Addr 0xFF (D~1.0) Result: " & to_hstring(t_f0);

        wait;
    end process;
end architecture;