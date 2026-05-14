library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_squarerootdigital_uart is
    Port (
        clk         : in  STD_LOGIC;
        rst_btn     : in  STD_LOGIC; -- Reset Button (Active Low)
        
        -- UART PINS (Ke Luar Chip)
        uart_rx     : in  STD_LOGIC;
        uart_tx     : out STD_LOGIC;
        
        -- DEBUG LED (Opsional, buat ngecek status)
        led_busy    : out STD_LOGIC  -- Nyala kalau System lagi sibuk ngitung
    );
end top_squarerootdigital_uart;

architecture Behavioral of top_squarerootdigital_uart is

    -- KABEL INTERNAL (Wires)
    -- Untuk menghubungkan UART <--> SquareRoot
    
    -- Jalur Data Masuk (RX)
    signal w_rx_data   : std_logic_vector(15 downto 0);
    signal w_rx_valid  : std_logic;
    
    -- Jalur Data Keluar (TX)
    signal w_tx_data   : std_logic_vector(15 downto 0);
    signal w_tx_start  : std_logic;
    signal w_uart_busy : std_logic; -- Status UART lagi sibuk kirim atau nggak
    
    -- Sinyal Reset Bersih
    signal sys_rst     : std_logic;

begin

    -- 1. Normalisasi Reset (Active Low Button -> Active High Logic)
    sys_rst <= not rst_btn;

    -- ====================================================
    -- INSTANCE 1: KOMUNIKASI (UART 16-BIT SYSTEM)
    -- ====================================================
    U_COMMS : entity work.UART_16_Bit_System
    Generic map (
        CLK_FREQ  => 50000000, 
        BAUD_RATE => 9600
    )
    Port map (
        clk         => clk,
        rst         => sys_rst,
        
        -- Pin Fisik
        uart_rx_pin => uart_rx,
        uart_tx_pin => uart_tx,
        
        -- Sambungan ke SquareRoot (TX / Kirim Balik)
        tx_data_16  => w_tx_data,   -- Ambil data dari SquareRoot
        tx_start    => w_tx_start,  -- Disuruh kirim sama SquareRoot
        tx_busy     => w_uart_busy, -- Laporan status (opsional dipake)
        
        -- Sambungan ke SquareRoot (RX / Terima Data)
        rx_data_16  => w_rx_data,   -- Kasih data ke SquareRoot
        rx_valid    => w_rx_valid   -- Colek SquareRoot suruh kerja
    );

    -- ====================================================
    -- INSTANCE 2: OTAK UTAMA (SQUARE ROOT DIGITAL)
    -- ====================================================
    U_CORE : entity work.squarerootdigital
    Port map (
        -- Control
        clk           => clk,
        rst           => sys_rst,
        
        -- Input dari UART
        uart_rx_valid => w_rx_valid, -- Trigger dari UART
        uart_data_in  => w_rx_data,  -- Data mentah dari UART
        
        -- Output ke UART
        uart_tx_start => w_tx_start, -- Perintah kirim ke UART
        uart_data_out => w_tx_data,  -- Hasil hitungan Q8.8 ke UART
        
        -- Status
        uart_tx_busy  => led_busy    -- Tampilkan status busy ke LED
    );

end Behavioral;