-- @file barrel_shifter.vhd
-- @brief This module is an implementation of a barrel shifter.

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------
entity barrel_shifter is
    Port (
		  ------- INPUTS -------
        data_in   : in std_logic_vector(31 downto 0);  -- 32-bit input data
		  shift     : in std_logic_vector(4 downto 0);   -- 5-bit shift magnitude
		  direction : in std_logic;		  -- Shift direction. '0' for right, '1' for left.
		  
		  ------- OUTPUTS -------
		  data_out  : out std_logic_vector(31 downto 0) -- Normalised input
    );
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture behavioral of barrel_shifter is
begin
    process(data_in, shift, direction)
		variable shift_int : integer range 0 to 31; -- Temporary storage for converting shift to int.
    begin
		shift_int := to_integer(unsigned(shift));
		
		if direction = '1' then
			-- Logical left shift
			data_out <= std_logic_vector(shift_left(unsigned(data_in), shift_int));
		else
			-- Logical right shift
			data_out <= std_logic_vector(shift_right(unsigned(data_in), shift_int));
		end if;
    end process;
end architecture;