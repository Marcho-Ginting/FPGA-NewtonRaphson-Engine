library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Integration is
    Port (
        clk    : in  std_logic;                     -- We must bring the Clock in
        rst    : in  std_logic;                     -- We must bring the Reset in
        A      : in  std_logic_vector(15 downto 0); -- Data to shift
        B      : in  std_logic_vector(15 downto 0); -- Shift amount (we use bottom 4 bits)
        Sel    : in  std_logic_vector(2 downto 0);  -- Operation Selector
        Output : out std_logic_vector(15 downto 0)
    );
end Integration;

architecture Structure of Integration is

    -- Inside Architecture of Integration.vhd

    component goldschmidt
        Port ( clk, rst, start : in std_logic;
               dividend, divisor : in std_logic_vector(15 downto 0);
               quotient : out std_logic_vector(15 downto 0);
               ready : out std_logic );
    end component;

    signal div_out : std_logic_vector(15 downto 0);
    signal div_start : std_logic;

begin
    -- Auto-start when Sel = "011"
    div_start <= '1' when Sel = "011" else '0';

    U_DIV: goldschmidt port map (
        clk => clk,
        rst => rst,
        start => div_start,
        dividend => A,
        divisor => B,
        quotient => div_out,
        ready => open -- logic will just wait for it to settle
    );

    -- Multiplexer
    with Sel select
        Output <= 
            -- ... other cases ...
            div_out when "011",
            (others => '0') when others;

end Structure;