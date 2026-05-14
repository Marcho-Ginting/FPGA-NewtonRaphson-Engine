-- @file multiplier.vhd
-- @brief This is a customised multiplier module.

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------
entity multiplier is
	port (
		-------- INPUTS ---------
		x_in  : in std_logic_vector(31 downto 0);
		y_in  : in std_logic_vector(31 downto 0);
		
		-------- OUTPUTS -------
		q_out : out std_logic_vector(31 downto 0)
	);
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture behavioral of multiplier is
	signal product_64 : signed(63 downto 0); -- Signed is used because internal math is more familiar with signed
begin
	product_64 <= signed(x_in) * signed(y_in);
	q_out <= std_logic_vector(product_64(61 downto 30)); -- Slice the junk bits.
end architecture;