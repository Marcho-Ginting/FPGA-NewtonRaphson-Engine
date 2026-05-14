-- @file nr_polisher.vhd
-- @brief This module takes data from ROM and divider, adds it, and right-shifs by 1-bit.

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------
entity nr_polisher is
	port (
		---------- CONTROL ----------
		clk         : in std_logic; 
		rst         : in std_logic;
		start       : in std_logic;
		done        : out std_logic;
		
		---------- INPUTS -----------
		seed_in     : in std_logic_vector(31 downto 0); -- From NR Initial guess module
		quotient_in : in std_logic_vector(31 downto 0); -- From divider module
		
		---------- OUTPUTS -----------
		nr_out      : out std_logic_vector(31 downto 0) -- x_(i+1) output
	);
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture rtl of nr_polisher is
	signal sum : unsigned(32 downto 0); -- Additional guard bit to prevent overflow
begin
	-- Addition
	sum <= resize(unsigned(seed_in), 33) + resize(unsigned(quotient_in), 33);
	process(clk, rst)
	begin
		if rst = '1' then
			nr_out <= (others => '0');
			done   <= '0';
		elsif rising_edge(clk) then
			if start = '1' then
				-- Division by 2
				nr_out <= std_logic_vector(sum(32 downto 1));
				
				done <= '1';
			else
				done <= '0';
			end if;
		end if;
	end process;
end architecture;