-- @file seed_generator.vhd
-- @brief Process the raw input and generates an initial guess (seed) for the NR math.

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------
entity seed_generator is 
	port (
		------------ CONTROL -------------
		clk           : in std_logic;
		rst           : in std_logic;
		ready         : out std_logic;
		
		------------ INPUT -----------
		data_16       : in std_logic_vector(15 downto 0);
		
		----------- OUTPUT -----------
		seed          : out std_logic_vector(31 downto 0);
		rescale_shift : out integer range 0 to 31;
		data_norm     : out std_logic_vector(31 downto 0)
	);
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture structural of seed_generator is
	signal rom_address : std_logic_vector(9 downto 0);
	signal raw_rom_out : std_logic_vector(31 downto 0);
	signal internal_data_norm : std_logic_vector(31 downto 0);
	signal rescale_val : integer range 0 to 31;
begin
	----------------------------------------
	------------- PRE-PROCESSOR ------------
	----------------------------------------
	U_PRE_PROC : entity work.pre_processor
		port map (
			raw_data_in   => data_16,
			rom_address   => rom_address,
			rescale_shift => rescale_val,
			data_norm     => internal_data_norm
		);
	
	----------------------------------------
	---------- NEWTON-RAPHSON ROM ----------
	----------------------------------------
	U_NR_ROM : entity work.nr_initial_guess
		port map (
			address           => rom_address,
			initial_guess_out => raw_rom_out
		);
	
	---------------------------------------
	----------- RESCALE SHIFTER -----------
	---------------------------------------
	process(clk, rst)
		variable last_input : std_logic_vector(15 downto 0);
	begin
		if rst = '1' then
			seed      <= (others => '0');
			data_norm <= (others => '0');
			last_input := (others => '1');
			rescale_shift <= 0;
			ready     <= '0';
		elsif rising_edge(clk) then
			seed      <= raw_rom_out;
			data_norm <= internal_data_norm;
			rescale_shift <= rescale_val;
			if data_16 /= last_input then
				ready <= '0';
				last_input := data_16;
			else
				ready <= '1';
			end if;
		end if;
	end process;
end architecture;