library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_integration_all is
end tb_integration_all;

architecture behavior of tb_integration_all is

    -- Component Declaration for the Unit Under Test (UUT)
    component Integration
    Port(
        clk : in std_logic;
        rst : in std_logic;
        A   : in std_logic_vector(15 downto 0);
        B   : in std_logic_vector(15 downto 0);
        Sel : in std_logic_vector(2 downto 0);
        Result : out std_logic_vector(15 downto 0)
    );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal A : std_logic_vector(15 downto 0) := (others => '0');
    signal B : std_logic_vector(15 downto 0) := (others => '0');
    signal Sel : std_logic_vector(2 downto 0) := (others => '0');

    -- Outputs
    signal Result : std_logic_vector(15 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: Integration port map (
        clk => clk, rst => rst, A => A, B => B, Sel => Sel, Result => Result
    );

    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';

        -- 1. Test Barrel Shifter (assuming Sel=001)
        Sel <= "001";
        A <= x"0008"; -- 8
        B <= x"0001"; -- Shift 1
        wait for 20 ns;

        -- 2. Test Normalise (assuming Sel=010)
        Sel <= "010";
        A <= x"00FF";
        wait for 20 ns;

        -- 3. Test Goldschmidt Division (Sel=011)
        Sel <= "011";
        -- 0x4000 (0.5) / 0x8000 (1.0 interpreted as fraction, or just check ratio)
        A <= x"4000"; 
        B <= x"8000"; 
        
        -- With 2 iterations, it takes roughly 6-8 clock cycles to be safe
        wait for 100 ns; 
        
        -- Result should be stable on the output bus now
        
        wait;
    end process;

end behavior;