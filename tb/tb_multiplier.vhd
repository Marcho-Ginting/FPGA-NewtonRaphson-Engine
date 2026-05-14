library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity q16_multiplier_tb is
end entity;

architecture sim of q16_multiplier_tb is
    signal t_a, t_b, t_q : std_logic_vector(31 downto 0);
begin
    dut: entity work.multiplier
        port map (x_in => t_a, y_in => t_b, q_out => t_q);

    process
    begin
        -- Test 1: 1.0 * 1.0 = 1.0
        -- 1.0 in Q16.16 is 0x00010000
        t_a <= x"00010000"; t_b <= x"00010000";
        wait for 10 ns;
        assert (t_q = x"00010000") report "Test 1 Failed" severity error;

        -- Test 2: 0.5 * 0.5 = 0.25
        -- 0.5 is 0x8000, 0.25 is 0x4000
        t_a <= x"00008000"; t_b <= x"00008000";
        wait for 10 ns;
        assert (t_q = x"00004000") report "Test 2 Failed" severity error;

        -- Test 3: 1.5 * 2.0 = 3.0
        -- 1.5 is 0x00018000, 2.0 is 0x00020000, 3.0 is 0x00030000
        t_a <= x"00018000"; t_b <= x"00020000";
        wait for 10 ns;
        assert (t_q = x"00030000") report "Test 3 Failed" severity error;

        report "Multiplier Sanity Check Passed!";
        wait;
    end process;
end architecture;