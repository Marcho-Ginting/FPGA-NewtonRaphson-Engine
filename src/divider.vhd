library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    port (
        clk, rst, start : in std_logic;
        finish          : out std_logic;
        numerator       : in std_logic_vector(31 downto 0); -- Expects Normalized [1.0, 2.0)
        denominator     : in std_logic_vector(31 downto 0); -- Expects Normalized [1.0, 2.0)
        quotient        : out std_logic_vector(31 downto 0)
    );
end entity;

architecture structural of divider is
    signal initial_guess : std_logic_vector(31 downto 0);
begin
    -- ROM uses bits 29 downto 22 (The 8 bits AFTER the leading '1' at bit 30)
    U_ROM : entity work.gs_initial_guess
        port map (
            address   => denominator(29 downto 22),
            guess_out => initial_guess
        );
        
    U_GOLDSCHMIDT : entity work.goldschmidt
        port map (
            clk => clk, rst => rst, start => start, finish => finish,
            num_norm => numerator, den_norm => denominator,
            initial_guess => initial_guess, quotient_out => quotient
        );
end architecture;