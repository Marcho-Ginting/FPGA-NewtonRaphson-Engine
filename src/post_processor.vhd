library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity post_processor is
    port (
        clk           : in std_logic;
        rst           : in std_logic;
        start         : in std_logic;
        done          : out std_logic;
        nr_in         : in std_logic_vector(31 downto 0);
        rescale_shift : in integer range 0 to 31;
        sqrt_out_16   : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of post_processor is
    -- STAGE 1 SIGNALS
    signal stg1_val       : unsigned(47 downto 0);
    signal stg1_shift_amt : integer range 0 to 31;
    signal stg1_valid     : std_logic;
    
begin
    process(clk, rst)
        variable v_wide_in   : unsigned(47 downto 0);
        -- INCREASED SIZE: 48-bit input * 16-bit constant = 64-bit result
        variable v_mult_temp : unsigned(63 downto 0); 
        
        variable v_final_shift : unsigned(47 downto 0);
        variable v_round_bit   : std_logic;
    begin
        if rst = '1' then
            sqrt_out_16    <= (others => '0');
            done           <= '0';
            stg1_valid     <= '0';
            stg1_val       <= (others => '0');
            stg1_shift_amt <= 0;
        elsif rising_edge(clk) then
            
            -------------------------------------------------------
            -- STAGE 1: Multiplication & Pre-normalization
            -------------------------------------------------------
            v_wide_in := resize(unsigned(nr_in), 48);
            
            if (rescale_shift mod 2) /= 0 then
                -- FIX: Use High-Precision Constant (46341 / 65536)
                -- 46341 is much closer to 1/sqrt(2) than 181 is.
                v_mult_temp := v_wide_in * to_unsigned(46341, 16);
                
                -- Rounding: Add half of divisor (65536 / 2 = 32768)
                -- Shift: Right by 16 bits
                stg1_val <= resize(shift_right(v_mult_temp + 32768, 16), 48);
            else
                stg1_val <= v_wide_in;
            end if;

            stg1_shift_amt <= 7 + (rescale_shift / 2);
            stg1_valid <= start;

            -------------------------------------------------------
            -- STAGE 2: Dynamic Shifting & Final Rounding
            -------------------------------------------------------
            if stg1_valid = '1' then
                if stg1_shift_amt > 0 then
                    v_round_bit := stg1_val(stg1_shift_amt - 1);
                else
                    v_round_bit := '0';
                end if;

                v_final_shift := shift_right(stg1_val, stg1_shift_amt);

                if v_round_bit = '1' then
                    v_final_shift := v_final_shift + 1;
                end if;

                sqrt_out_16 <= std_logic_vector(v_final_shift(15 downto 0));
                done <= '1';
            else
                done <= '0';
            end if;
            
        end if;
    end process;
end architecture;