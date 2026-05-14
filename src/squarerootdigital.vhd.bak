-- @file squarerootdigital.vhd
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
entity squarerootdigital is
	port (
		------------ CONTROL ------------
		clk           : in std_logic;
		rst           : in std_logic;
		uart_rx_valid : in std_logic;
		uart_tx_start : out std_logic;
		uart_tx_busy  : out std_logic;
		
		----------- INPUT ---------------
		uart_data_in  : in std_logic_vector(15 downto 0); -- uint-16 data from UART
		
		----------- OUTPUT --------------
		uart_data_out : out std_logic_vector(15 downto 0) -- Q8.8 output data to UART
	);
end entity;

architecture structural of squarerootdigital is
	-- FSM states declaration
	type state_type is (IDLE, PRE_PROC, DIVIDE, POLISH, POST_PROC, SEND);
	signal state : state_type := IDLE;
	
	----------------- INTERNAL WIRES ------------------
	-- From seed generator
	signal sig_ready_seed        : std_logic;
	signal sig_seed              : std_logic_vector(31 downto 0); -- To polisher
	signal sig_data_norm         : std_logic_vector(31 downto 0); -- To divider
	signal sig_rescale           : integer range 0 to 31;         -- To post-processor
	
	-- To divider
	signal sig_div_start         : std_logic := '0';
	signal sig_div_done          : std_logic;
	
	-- From divider
	signal sig_quotient          : std_logic_vector(31 downto 0); -- To polisher
	
	-- To polisher
	signal sig_pol_start         : std_logic := '0';
	
	-- From polisher
	signal sig_pol_done          : std_logic;
	signal sig_nr                : std_logic_vector(31 downto 0); -- To post-processor
	
	-- From post-processor
	signal sig_final_math_result : std_logic_vector(15 downto 0);
	-- To post-processor
	signal sig_post_start        : std_logic := '0';
	signal sig_post_done         : std_logic;
begin
	---------------------------------------------------
	----------------- SEED GENERATOR ------------------
	---------------------------------------------------
	U_SEED_GEN : entity work.seed_generator
		port map (
			clk           => clk,
			rst           => rst,
			ready         => sig_ready_seed,
			data_16       => uart_data_in,
			seed          => sig_seed,
			rescale_shift => sig_rescale,
			data_norm     => sig_data_norm
		);

	---------------------------------------------------
	-------------------- DIVIDER ----------------------
	---------------------------------------------------		
	U_DIVIDER : entity work.divider
		port map (
			clk         => clk,
			rst         => rst,
			start       => sig_div_start,
			finish      => sig_div_done,
			numerator   => sig_data_norm,
			denominator => sig_seed,
			quotient    => sig_quotient
		);
		
	---------------------------------------------------
	------------------- POLISHER ----------------------
	---------------------------------------------------
	U_POLISHER : entity work.nr_polisher
		port map (
			clk         => clk,
			rst         => rst,
			start       => sig_pol_start,
			done        => sig_pol_done,
			seed_in     => sig_seed,
			quotient_in => sig_quotient,
			nr_out      => sig_nr
		);
	
	---------------------------------------------------
	----------------- POST-PROCESSOR ------------------
	---------------------------------------------------
	U_POST : entity work.post_processor
		port map (
			clk           => clk,
			rst           => rst,
			start         => sig_post_start,
			done          => sig_post_done,
			nr_in         => sig_nr,
			rescale_shift => sig_rescale,
			sqrt_out_16   => sig_final_math_result
		);
	
	--------------------------------------------------
	------------------ MASTER FSM --------------------
	--------------------------------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			state <= IDLE;
			uart_data_out <= (others => '0');
			sig_div_start  <= '0';
			sig_pol_start  <= '0';
			sig_post_start <= '0';
			uart_tx_start  <= '0';
		elsif rising_edge(clk) then
			case state is
				when IDLE =>
					uart_tx_start <= '0';
					if uart_rx_valid = '1' then
						if unsigned(uart_data_in) = 0 then
							uart_data_out <= (others => '0'); -- Zero input fail-safe
							state  <= SEND;
						else
							state <= PRE_PROC;
						end if;
					end if;
					
				when PRE_PROC =>
					if sig_ready_seed = '1' then
						sig_div_start <= '1'; -- Start divider
						state <= DIVIDE;
					end if;
				
				when DIVIDE =>
					sig_div_start <= '0'; -- Stop divider
					if sig_div_done = '1' then
						sig_pol_start <= '1';
						state <= POLISH;
					end if;
				
				when POLISH =>
					sig_pol_start <= '0'; -- Stop polisher
					if sig_pol_done = '1' then
						sig_post_start <= '1';
						state <= POST_PROC;
					end if;
				
				when POST_PROC =>
					sig_post_start <= '0'; -- Stop post-processor
					if sig_post_done = '1' then
						state <= SEND;
					end if;
					
				when SEND =>
					if unsigned(uart_data_in) = 0 then
						uart_data_out <= (others => '0');
					else
						uart_data_out <= sig_final_math_result;
					end if;
					uart_tx_start <= '1';
					state <= IDLE;
				
				when others => state <= IDLE;
			end case;
		end if;
	end process;
end architecture;