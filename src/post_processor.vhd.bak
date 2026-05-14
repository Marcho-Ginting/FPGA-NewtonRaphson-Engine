-- @file post_processor.vhd
-- @brief Converts Q2.30 Result -> Q8.8 Integer Output
--        FIXED: Corrected Shift Formula (7 + S/2) to prevent data loss

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity post_processor is
    port (
        clk           : in std_logic;
        rst           : in std_logic;
        start         : in std_logic;
        done          : out std_logic;
        nr_in         : in std_logic_vector(31 downto 0); -- Q2.30 Input
        rescale_shift : in integer range 0 to 31;         -- Original Left Shift S
        sqrt_out_16   : out std_logic_vector(15 downto 0) -- Q8.8 Output
    );
end entity;

architecture rtl of post_processor is
begin
    process(clk, rst)
        variable v_wide      : unsigned(47 downto 0);
        variable v_shift_tot : integer;
        variable v_mult_temp : unsigned(55 downto 0);
    begin
        if rst = '1' then
            sqrt_out_16 <= (others => '0');
            done <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                -- Load Q2.30 input
                v_wide := resize(unsigned(nr_in), 48);
                
                -- 1. ODD SHIFT CORRECTION
                -- If S is odd, we are too large by sqrt(2). Multiply by 0.707 (181/256).
                if (rescale_shift mod 2) /= 0 then
                    -- Explicit multiply 48-bit * 8-bit
                    v_mult_temp := v_wide * to_unsigned(181, 8);
                    -- Divide by 256 (Shift 8) and resize back
                    v_wide := resize(shift_right(v_mult_temp, 8), 48);
                end if;

                -- 2. DENORMALIZATION & ALIGNMENT
                -- Formula: 7 + (S/2)
                v_shift_tot := 7 + (rescale_shift / 2);
                
                v_wide := shift_right(v_wide, v_shift_tot);

                -- 3. Output
                sqrt_out_16 <= std_logic_vector(v_wide(15 downto 0));
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;
end architecture;