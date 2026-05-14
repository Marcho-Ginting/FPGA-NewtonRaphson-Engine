library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_msb_detector is
end entity;

architecture sim of tb_msb_detector is
    -- Signals to connect to UUT
    signal t_data_in   : std_logic_vector(15 downto 0) := (others => '0');
    signal t_shift     : std_logic_vector(3 downto 0);
    signal t_direction : std_logic;

    -- Helper function to find MSB the "slow/software" way for checking
    function get_expected_pos(val : std_logic_vector(15 downto 0)) return integer is
    begin
        for i in 15 downto 0 loop
            if val(i) = '1' then return i; end if;
        end loop;
        return 0;
    end function;

begin
    -- Instantiate the Unit Under Test (UUT)
    dut: entity work.msb_detector
        port map (
            data_in   => t_data_in,
            shift     => t_shift,
            direction => t_direction
        );

    -- Main Stimulus Process
    process
        variable exp_pos   : integer;
        variable exp_delta : integer;
        variable actual_s  : integer;
    begin
        report "Starting exhaustive test (skipping 0)...";

        for i in 1 to 65535 loop
            t_data_in <= std_logic_vector(to_unsigned(i, 16));
            wait for 10 ns; -- Allow combinational logic to settle

            -- Calculate what the hardware SHOULD have done
            exp_pos   := get_expected_pos(t_data_in);
            exp_delta := 7 - exp_pos;
            actual_s  := to_integer(unsigned(t_shift));

            -- Check Direction
            if exp_delta < 0 then
                assert t_direction = '0' report "Dir Error at " & integer'image(i) severity error;
            elsif exp_delta > 0 then
                assert t_direction = '1' report "Dir Error at " & integer'image(i) severity error;
            end if;

            -- Check Shift Magnitude
            assert actual_s = abs(exp_delta) 
                report "Shift Error at " & integer'image(i) & 
                       " Expected: " & integer'image(abs(exp_delta)) & 
                       " Got: " & integer'image(actual_s)
                severity error;
        end loop;

        report "Exhaustive test complete! If no errors appeared, your sorcery works.";
        wait; -- Stop simulation
    end process;
end architecture;