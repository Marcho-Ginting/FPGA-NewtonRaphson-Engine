library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity msb_detector is
    port (
        data_in   : in  std_logic_vector(31 downto 0);
        shift     : out std_logic_vector(4 downto 0);
        direction : out std_logic
    );
end entity;

architecture behavioral of msb_detector is
    -- Helper function to count leading zeros in a 16-bit word
    function count_lz_16(val : std_logic_vector(15 downto 0)) return integer is
        variable temp : unsigned(15 downto 0);
        variable cnt  : integer := 0;
    begin
        temp := unsigned(val);
        if temp(15 downto 8) = x"00" then cnt := cnt + 8; temp := temp sll 8; end if;
        if temp(15 downto 12) = x"0" then cnt := cnt + 4; temp := temp sll 4; end if;
        if temp(15 downto 14) = "00" then cnt := cnt + 2; temp := temp sll 2; end if;
        if temp(15) = '0'            then cnt := cnt + 1; end if;
        return cnt;
    end function;

    signal msb_idx : integer;
begin
    process(data_in)
        variable lz_upper, lz_lower : integer;
        variable current_msb_pos    : integer;
        variable shift_amt          : integer;
    begin
        lz_upper := count_lz_16(data_in(31 downto 16));
        lz_lower := count_lz_16(data_in(15 downto 0));

        if unsigned(data_in(31 downto 16)) /= 0 then
            current_msb_pos := 31 - lz_upper;
        else
            current_msb_pos := 15 - lz_lower;
        end if;

        -- TARGET: Bit 30.
        shift_amt := 30 - current_msb_pos;

        if shift_amt >= 0 then
            direction <= '1'; -- Left Shift
            shift     <= std_logic_vector(to_unsigned(shift_amt, 5));
        else
            direction <= '0'; -- Right Shift (Should rarely happen for integers)
            shift     <= std_logic_vector(to_unsigned(abs(shift_amt), 5));
        end if;
    end process;
end architecture;