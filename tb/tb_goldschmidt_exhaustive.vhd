library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- For floating point calculation in the testbench

entity tb_goldschmidt_exhaustive is
end tb_goldschmidt_exhaustive;

architecture behavior of tb_goldschmidt_exhaustive is

    component goldschmidt
    Port (
        clk, rst, start : in std_logic;
        dividend, divisor : in std_logic_vector(15 downto 0);
        quotient : out std_logic_vector(15 downto 0);
        ready : out std_logic
    );
    end component;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal start : std_logic := '0';
    signal dividend_s, divisor_s : std_logic_vector(15 downto 0) := (others => '0');
    signal quotient_s : std_logic_vector(15 downto 0);
    signal ready : std_logic;

    constant clk_period : time := 10 ns;
    constant TEST_SAMPLES : integer := 50; 

    signal errors_found : integer := 0;

    -- Function to convert Q1.15 VHDL result to real (floating point)
    function to_real_q1_15 (q_val : std_logic_vector) return real is
        constant M : real := real(2**15);
        variable unsigned_val : unsigned(q_val'range) := unsigned(q_val);
    begin
        return real(to_integer(unsigned_val)) / M;
    end function;
    
    -- Function to convert real to Q1.15 VHDL representation
    function to_q1_15_slv (r_val : real) return std_logic_vector is
        constant M : real := real(2**15);
        variable int_val : integer := integer(r_val * M);
    begin
        if int_val > (2**16 - 1) then int_val := (2**16 - 1); end if;
        if int_val < 0 then int_val := 0; end if; 
        return std_logic_vector(to_unsigned(int_val, 16));
    end function;

begin

    uut: goldschmidt port map (
        clk => clk, rst => rst, start => start,
        dividend => dividend_s, divisor => divisor_s,
        quotient => quotient_s, ready => ready
    );

    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
        variable N_real : real;
        variable D_real : real;
        variable Q_expected_real : real;
        variable Q_expected_q15 : std_logic_vector(15 downto 0);
        variable Q_actual_real : real;
        variable i : integer := 0;
        
        variable seed1, seed2 : positive := 1;
        variable rand_N_int, rand_D_int : integer;
        variable rand_N_slv, rand_D_slv : std_logic_vector(15 downto 0);

        type test_case_t is record
            N_hex : std_logic_vector(15 downto 0);
            D_hex : std_logic_vector(15 downto 0);
        end record;
        type test_vector_t is array (integer range <>) of test_case_t;

        constant HAND_PICKED_TESTS : test_vector_t := (
            (x"4000", x"6000"),
            (x"7333", x"7999"),
            (x"00A3", x"4000"),
            (x"1000", x"0010"),
            (x"7FFF", x"7FFF"),
            (x"4000", x"7FFF"),
            (x"7FFF", x"0001") 
        );
        
        -- FIX: Helper function to safely convert std_logic_vector to string using decimal representation
        function slv_to_str(s : std_logic_vector) return string is
            variable val : integer := to_integer(unsigned(s));
        begin
            return integer'image(val);
        end function;

        procedure run_test (N_in : std_logic_vector; D_in : std_logic_vector) is
        begin
            dividend_s <= N_in;
            divisor_s <= D_in;
            
            start <= '1';
            wait for clk_period;
            start <= '0';

            wait until ready = '1' for 1000 * clk_period;

            -- FIX: Using slv_to_str for std_logic_vector output
            if now >= 1000 * clk_period then
                report "Error: Test Case timed out (N=" & slv_to_str(N_in) & ", D=" & slv_to_str(D_in) & ")" severity error;
                errors_found <= errors_found + 1;
            else
                N_real := to_real_q1_15(N_in);
                D_real := to_real_q1_15(D_in);

                if D_real = 0.0 or D_real < 0.0001 then
                    report "Warning: Skipping division by near-zero test. D=" & real'image(D_real) severity note;
                    wait for clk_period;
                    return; 
                end if;
                
                Q_expected_real := N_real / D_real;
                Q_expected_q15 := to_q1_15_slv(Q_expected_real);
                Q_actual_real := to_real_q1_15(quotient_s);

                -- FIX: Using slv_to_str for std_logic_vector output
                if quotient_s /= Q_expected_q15 then
                    report "TEST FAILED: " & LF &
                           "  N/D (Dec): " & slv_to_str(N_in) & " / " & slv_to_str(D_in) & LF &
                           "  Expected Real: " & real'image(Q_expected_real) & LF &
                           "  Expected Q1.15 (Dec): " & slv_to_str(Q_expected_q15) & LF &
                           "  Actual Q1.15 (Dec): " & slv_to_str(quotient_s) & LF &
                           "  Actual Real: " & real'image(Q_actual_real) & LF
                           severity error;
                    errors_found <= errors_found + 1;
                else
                    report "Test Passed: N/D (" & slv_to_str(N_in) & " / " & slv_to_str(D_in) & ") = " & slv_to_str(quotient_s) severity note;
                end if;
            end if;

            wait for 2 * clk_period;
        end procedure;

    begin
        rst <= '1';
        wait for 4 * clk_period;
        rst <= '0';
        wait for clk_period;

        report "--- Starting Hand-Picked Edge Cases ---" severity note;
        for j in HAND_PICKED_TESTS'range loop
            i := i + 1;
            report "Running Test " & integer'image(i) & " (Hand-Picked)" severity note;
            run_test(HAND_PICKED_TESTS(j).N_hex, HAND_PICKED_TESTS(j).D_hex);
        end loop;

        report "--- Starting Random Coverage Tests ---" severity note;
        
        uniform(seed1, seed2, N_real); 

        for j in 1 to TEST_SAMPLES loop
            i := i + 1;
            report "Running Test " & integer'image(i) & " (Random)" severity note;
            
            uniform(seed1, seed2, N_real); 
            rand_N_int := integer(N_real * real(2**15 - 1)) + 1;
            rand_N_slv := std_logic_vector(to_unsigned(rand_N_int, 16));
            
            uniform(seed1, seed2, D_real); 
            rand_D_int := integer(D_real * real(2**15 - 1000)) + 1000; 
            rand_D_slv := std_logic_vector(to_unsigned(rand_D_int, 16));
            
            if unsigned(rand_N_slv) > unsigned(rand_D_slv) then
                rand_N_slv := std_logic_vector(to_unsigned(rand_D_int, 16));
                rand_D_slv := std_logic_vector(to_unsigned(rand_N_int, 16));
            end if;
            
            run_test(rand_N_slv, rand_D_slv);
        end loop;

        if errors_found = 0 then
            report "--- ALL " & integer'image(i) & " TESTS PASSED SUCCESSFULLY! ---" severity note;
        else
            report "--- TEST BENCH FAILED: " & integer'image(errors_found) & " ERRORS FOUND! ---" severity failure;
        end if;
        
        wait;
    end process;
    
end behavior;