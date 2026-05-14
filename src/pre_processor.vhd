-- @file pre_processor.vhd
-- @brief Prepares 16-bit integers for Q2.30 Newton-Raphson
--        1. Normalizes input to [1.0, 2.0) (MSB at Bit 30)
--        2. Extracts 10-bit Mantissa for ROM Address (29 downto 20)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pre_processor is
    port (
        ----------- INPUT -----------
        raw_data_in   : in std_logic_vector(15 downto 0);
        
        ----------- OUTPUTS -----------
        rom_address   : out std_logic_vector(9 downto 0); -- 10-bit ROM address
        rescale_shift : out integer range 0 to 31;        -- Amount shifted
        data_norm     : out std_logic_vector(31 downto 0) -- Q2.30 Normalized
    );
end entity;

architecture structural of pre_processor is
    
    signal input_32    : std_logic_vector(31 downto 0);
    signal w_data_norm : std_logic_vector(31 downto 0);
    signal w_den_dummy : std_logic_vector(31 downto 0);
    signal w_shift_mag : std_logic_vector(4 downto 0);
    signal w_shift_dir : std_logic;

begin
    -- 1. Pad 16-bit input to 32-bit (Q16.0 -> Q32.0 effectively)
    input_32 <= x"0000" & raw_data_in; 
    
    ------------------------------------
    ---------- NORMALISER --------------
    ------------------------------------
    -- This relies on msb_detector targeting Bit 30.
    U_NORM : entity work.normaliser_top
        port map (
            num_in        => input_32,
            den_in        => input_32, -- Use input as denominator reference for shifting
            num_norm      => w_data_norm,
            den_norm      => w_den_dummy,
            out_shift     => w_shift_mag,
            out_direction => w_shift_dir
        );
        
    ------------------------------------
    ---------- MAPPING LOGIC -----------
    ------------------------------------
    -- 1. Output Normalized Data
    data_norm <= w_data_norm;

    -- 2. ROM Address Extraction
    -- Standard: Normalized range [1.0, 2.0).
    -- MSB is at Bit 30 (Value 1). It is always '1'.
    -- We take the next 10 bits (29 downto 20) as the fractional index.
    rom_address <= w_data_norm(29 downto 20);

    -- 3. Rescale Shift Output
    -- Convert the vector to integer for easier handling downstream.
    process(w_shift_mag)
    begin
        if is_x(w_shift_mag) then
            rescale_shift <= 0;
        else
            rescale_shift <= to_integer(unsigned(w_shift_mag));
        end if;
    end process;

end architecture;