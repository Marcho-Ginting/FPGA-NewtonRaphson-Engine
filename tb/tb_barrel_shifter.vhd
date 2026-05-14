library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_barrel_shifter_exhaustive is
end tb_barrel_shifter_exhaustive;

architecture Behavioral of tb_barrel_shifter_exhaustive is

    -- Component Declaration
    component barrel_shifter is
        Port ( 
            clk       : in STD_LOGIC;
            data_in   : in STD_LOGIC_VECTOR(15 downto 0);
            shift_mag : in STD_LOGIC_VECTOR(3 downto 0);
            direction : in STD_LOGIC;
            data_out  : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Signals
    signal clk       : STD_LOGIC := '0';
    signal data_in   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal shift_mag : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal direction : STD_LOGIC := '0';
    signal data_out  : STD_LOGIC_VECTOR(15 downto 0);

    -- Simulation Constants
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: barrel_shifter Port Map (
        clk       => clk,
        data_in   => data_in,
        shift_mag => shift_mag,
        direction => direction,
        data_out  => data_out
    );

    -- Clock Process
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Exhaustive Stimulus Process
    stim_proc: process
        variable v_data_in   : integer;
        variable v_shift_amt : integer;
        variable v_dir       : integer;
        variable v_expected  : unsigned(15 downto 0);
        variable v_input_uns : unsigned(15 downto 0);
        variable error_count : integer := 0;
        variable counter     : integer := 0; -- To track progress
    begin
        -- Initial Wait to let 'UUUU' clear out
        wait for 20 ns; 
        
        report "STARTING EXHAUSTIVE TEST...";

        for dir_idx in 0 to 1 loop
            v_dir := dir_idx;
            if v_dir = 1 then direction <= '1'; else direction <= '0'; end if;

            for s_idx in 0 to 15 loop
                v_shift_amt := s_idx;
                shift_mag <= std_logic_vector(to_unsigned(v_shift_amt, 4));

                for d_idx in 0 to 65535 loop
                    v_data_in := d_idx;
                    v_input_uns := to_unsigned(v_data_in, 16);
                    data_in <= std_logic_vector(v_input_uns);

                    wait for CLK_PERIOD; -- Wait for the result

                    -- Calculate Expected
                    if v_dir = 1 then v_expected := shift_left(v_input_uns, v_shift_amt);
                    else              v_expected := shift_right(v_input_uns, v_shift_amt);
                    end if;

                    -- Check Result
                    if unsigned(data_out) /= v_expected then
                        error_count := error_count + 1;
                        report "ERROR: Input=" & integer'image(v_data_in) severity error;
                    end if;

                    -- PROGRESS REPORT (Prevents it from looking frozen)
                    counter := counter + 1;
                    if (counter mod 50000) = 0 then
                        report "Simulation running... Checked " & integer'image(counter) & " vectors so far.";
                    end if;

                end loop;
            end loop;
        end loop;

        if error_count = 0 then
            report "SUCCESS: All tests passed!";
        else
            report "FAILURE: Found errors.";
        end if;
        wait;
    end process;

end Behavioral;