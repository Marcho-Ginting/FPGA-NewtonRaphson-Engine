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
    signal product_64 : signed(63 downto 0);
    signal upper_part : signed(31 downto 0);
    signal round_bit  : std_logic;
begin
    product_64 <= signed(x_in) * signed(y_in);
    
    -- Extract the upper significant bits
    upper_part <= product_64(61 downto 30);
    
    -- Extract the "0.5" bit (the highest bit we are about to throw away)
    round_bit  <= product_64(29);

    process(upper_part, round_bit)
    begin
        if round_bit = '1' then
            -- Round Up
            q_out <= std_logic_vector(upper_part + 1);
        else
            -- Truncate (Round Down)
            q_out <= std_logic_vector(upper_part);
        end if;
    end process;
end architecture;