-- @file goldschmidt.vhd
-- @brief This is the goldschmidt divider algorithm module

--------------------------------------------
---------------- LIBRARIES -----------------
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------
-------------- ENTITY ----------------
--------------------------------------
entity goldschmidt is
	port (
		------- CONTROL -------
		clk          : in std_logic; -- Internal clock
		rst          : in std_logic; -- Reset button
		start        : in std_logic; -- Handshake
		finish         : out std_logic; -- Handshake
		
		------- INPUTS --------
		num_norm     : in std_logic_vector(31 downto 0); -- Normalised numerator Q16.16
		den_norm     : in std_logic_vector(31 downto 0); -- Normalised denominator Q16.16
		initial_guess: in std_logic_vector(31 downto 0); -- Initial guess from ROM Q16.16
		
		------- OUTPUTS --------
		quotient_out : out std_logic_vector(31 downto 0) -- Output to denormaliser
	);
end entity;

---------------------------------------
------------ ARCHITECTURE -------------
---------------------------------------
architecture rtl of goldschmidt is
	-- Constant Declaration
	constant TWO_Q16 : unsigned(31 downto 0) := x"80000000";
	
	-- FSM Declaration
	type state_type is (IDLE, INIT, CALC, DONE);
	signal state : state_type;
	
	-- Internal wires
	signal mult_num_out, mult_den_out : std_logic_vector(31 downto 0); -- Output from multiplier
	signal reg_num, reg_den, reg_fac  : std_logic_vector(31 downto 0); -- Internal registers
	signal count                      : integer range 0 to 2;          -- Iteration tracker
begin
	-----------------------------------
	--------- MULTILPLIERS ------------
	-----------------------------------
	mult_num : entity work.multiplier
		port map(x_in => reg_num, y_in => reg_fac, q_out => mult_num_out);
	
	mult_den : entity work.multiplier
		port map(x_in => reg_den, y_in => reg_fac, q_out => mult_den_out);
	
	----------------------------------
	---------- CONTROL PATH ----------
	----------------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			state <= IDLE;
			-- Clear registers from junk
			reg_num <= (others => '0');
			reg_den <= (others => '0');
			reg_fac <= (others => '0');
			count <= 0;
			finish <= '0';
		elsif rising_edge(clk) then
			case state is
				when IDLE =>
					finish <= '0';
					if start = '1' then
						state <= INIT;
					end if;
				
				when INIT =>
					reg_num <= num_norm;     -- Grab normalised numerator
					reg_den <= den_norm;     -- Grab normalised denominator
					reg_fac <= initial_guess; -- Grab initial guess
					count <= 0;
					state <= CALC;
				
				when CALC =>
					reg_num <= mult_num_out; -- Update value from multiplier
					reg_den <= mult_den_out; -- Update value from multiplier
					reg_fac <= std_logic_vector(TWO_Q16 - unsigned(mult_den_out));
					
					if count = 2 then
						state <= DONE;
					else
						count <= count + 1;
					end if;
				
				when DONE =>
					finish <= '1';
					state <= IDLE;
			end case;
		end if;
	end process;
	
	------ OUTPUT TO DENORMALISER ------
	quotient_out <= reg_num;
end architecture;