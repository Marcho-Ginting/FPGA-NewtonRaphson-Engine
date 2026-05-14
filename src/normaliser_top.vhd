-- @file normaliser_top.vhd
-- @brief This is a wrapper module for the MSB detector and barrel shifter.

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------

entity normaliser_top is
	port (
		------- INPUTS --------
		num_in   : in std_logic_vector(31 downto 0); -- Raw numerator
		den_in   : in std_logic_vector(31 downto 0); -- Raw denominator
		
		------- OUTPUTS --------
		num_norm : out std_logic_vector(31 downto 0); -- Normalised numerator
		den_norm : out std_logic_vector(31 downto 0); -- Normalised denominator
		
		
		------- METADATA ------
		out_shift     : out std_logic_vector(4 downto 0); -- Shift magnitude
		out_direction : out std_logic                     -- Shift direction
	);
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture structural of normaliser_top is
	signal shift_mag      : std_logic_vector(4 downto 0);
	signal shift_dir      : std_logic;
begin
	-- MSB Detector instantiation
	master_detector : entity work.msb_detector
		port map(
			data_in   => den_in, -- Normalisation depends on denominator
			shift     => shift_mag,
			direction => shift_dir
		);
	

	-- Denominator barrel shifter
	den_shifter : entity work.barrel_shifter
		port map(
			data_in   => den_in,
			shift     => shift_mag,
			direction => shift_dir,
			data_out  => den_norm
		);
	
	-- Numerator barrel shifter
	num_shifter : entity work.barrel_shifter
		port map(
			data_in   => num_in,
			shift     => shift_mag,
			direction => shift_dir,
			data_out  => num_norm
		);
	
	-- Pass metadata to denormilase in the future
	out_shift     <= shift_mag;
	out_direction <= shift_dir;
	
end architecture;