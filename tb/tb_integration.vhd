library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_integration_smart is
end tb_integration_smart;

architecture behavior of tb_integration_smart is

    -- COMPONENT DECLARATION
    component Integration
    port(
        clk    : in  std_logic;
        rst    : in  std_logic; -- NEW: Add Reset to component
        A      : in  std_logic_vector(15 downto 0);
        B      : in  std_logic_vector(15 downto 0);
        Sel    : in  std_logic_vector(2 downto 0);
        Output : out std_logic_vector(15 downto 0)
    );
    end component;

    -- SIGNALS
    signal clk_tb    : std_logic := '0';
    signal rst_tb    : std_logic := '0'; -- NEW: Reset Signal
    signal A_tb      : std_logic_vector(15 downto 0) := (others => '0');
    signal B_tb      : std_logic_vector(15 downto 0) := (others => '0');
    signal Sel_tb    : std_logic_vector(2 downto 0)  := (others => '0');
    signal Output_tb : std_logic_vector(15 downto 0);

    -- CONFIGURATION
    constant OP_SH_LEFT  : std_logic_vector(2 downto 0) := "100"; 
    constant OP_SH_RIGHT : std_logic_vector(2 downto 0) := "101"; 
    constant clk_period  : time := 10 ns;

begin

    -- Instantiate UUT
    uut: Integration port map (
        clk    => clk_tb,
        rst    => rst_tb, -- NEW: Connect Reset
        A      => A_tb,
        B      => B_tb,
        Sel    => Sel_tb,
        Output => Output_tb
    );

    -- CLOCK PROCESS
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- TEST PROCESS
    process
        variable expected_val : integer;
    begin
        
        -- 1. RESET SEQUENCE
        report "Resetting System..." severity note;
        rst_tb <= '1';     -- Assert Reset
        wait for 50 ns;
        rst_tb <= '0';     -- De-assert Reset
        wait for 50 ns;    -- Wait for stabilization

        report "STARTING SYNCHRONOUS SMART EXHAUSTIVE TEST..." severity note;
        
        ------------------------------------------------------------
        -- PHASE 1: SHIFT LEFT
        ------------------------------------------------------------
        report "Phase 1: Testing Logical Shift Left...";
        Sel_tb <= OP_SH_LEFT;
        
        for i in 0 to 65535 loop
            for j in 0 to 15 loop
                
                wait until falling_edge(clk_tb);
                A_tb <= std_logic_vector(to_unsigned(i, 16));
                B_tb <= std_logic_vector(to_unsigned(j, 16)); 
                
                wait until rising_edge(clk_tb);
                wait for 1 ns; 

                expected_val := to_integer(shift_left(to_unsigned(i, 16), j));
                
                if to_integer(unsigned(Output_tb)) /= expected_val then
                    report "ERROR: Shift Left Failed!" &
                           " Input=" & integer'image(i) &
                           " Shift=" & integer'image(j) &
                           " Got=" & integer'image(to_integer(unsigned(Output_tb))) &
                           " Exp=" & integer'image(expected_val)
                    severity failure;
                end if;
            end loop;
        end loop;

        ------------------------------------------------------------
        -- PHASE 2: SHIFT RIGHT
        ------------------------------------------------------------
        report "Phase 2: Testing Logical Shift Right...";
        Sel_tb <= OP_SH_RIGHT;
        
        for i in 0 to 65535 loop
            for j in 0 to 15 loop
                
                wait until falling_edge(clk_tb);
                A_tb <= std_logic_vector(to_unsigned(i, 16));
                B_tb <= std_logic_vector(to_unsigned(j, 16));
                
                wait until rising_edge(clk_tb);
                wait for 1 ns;
                
                expected_val := to_integer(shift_right(to_unsigned(i, 16), j));
                
                if to_integer(unsigned(Output_tb)) /= expected_val then
                    report "ERROR: Shift Right Failed!" &
                           " Input=" & integer'image(i) &
                           " Shift=" & integer'image(j)
                    severity failure;
                end if;
            end loop;
        end loop;

        report "SUCCESS: All tests passed!";
        wait; 
    end process;

end behavior;