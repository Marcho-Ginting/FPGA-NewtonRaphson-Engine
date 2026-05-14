import csv
import serial
import struct
import time
import math
import sys

# ================= KONFIGURASI =================
PORT_NAME = 'COM6'   # Ganti dengan COM Port FPGA kamu
BAUD_RATE = 9600     # Harus sama dengan VHDL
INPUT_FILE = 'input_vectors.csv'
OUTPUT_FILE = 'test_results.csv'
# ===============================================

def generate_csv_input():
    print(f"[1/3] Membuat file input {INPUT_FILE}...")
    with open(INPUT_FILE, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['decimal_input'])  # Header
        
        # Loop dari 1 sampai 65535 (Max 16-bit unsigned)
        # Catatan: 2^16 = 65536, tapi max value 16-bit adalah 65535.
        for i in range(1, 65536): 
            writer.writerow([i])
    print("      Selesai! File input siap.")

def run_fpga_test():
    print(f"[2/3] Membuka koneksi ke {PORT_NAME}...")
    
    try:
        ser = serial.Serial(PORT_NAME, BAUD_RATE, timeout=1)
        time.sleep(2)  # Tunggu FPGA reset (jika ada auto-reset)
        
        # Siapkan file output
        with open(OUTPUT_FILE, mode='w', newline='') as outfile:
            writer = csv.writer(outfile)
            # Tulis Header Output
            writer.writerow([
                'input_decimal', 
                'input_hex', 
                'fpga_raw_hex', 
                'fpga_result_q88', 
                'expected_sqrt', 
                'error_diff',
                'status'
            ])
            
            # Baca file input yang tadi dibuat
            with open(INPUT_FILE, mode='r') as infile:
                reader = csv.DictReader(infile)
                rows = list(reader)
                total_tests = len(rows)
                
                print(f"[3/3] Memulai pengujian untuk {total_tests} data...")
                print("      (Estimasi waktu @9600 baud: ~5-10 menit)")
                
                start_time = time.time()
                
                for idx, row in enumerate(rows):
                    val = int(row['decimal_input'])
                    
                    # 1. Packing data (Little Endian <H)
                    data_to_send = struct.pack('<H', val)
                    
                    # 2. Kirim ke FPGA
                    ser.write(data_to_send)
                    
                    # 3. Baca Balasan (2 Byte)
                    response = ser.read(2)
                    
                    if len(response) == 2:
                        # Unpacking Q8.8 dari FPGA
                        raw_val = struct.unpack('<H', response)[0] # Hasil mentah (misal 0x1000)
                        fpga_float = raw_val / 256.0               # Hasil konversi (misal 16.0)
                        
                        # Hitung nilai asli (Golden Reference)
                        expected_float = math.sqrt(val)
                        
                        # Hitung Error
                        diff = abs(fpga_float - expected_float)
                        status = 'PASS' if diff < 0.1 else 'FAIL' # Toleransi error kecil
                        
                        # Tulis ke CSV
                        writer.writerow([
                            val, 
                            f"0x{val:04X}", 
                            f"0x{raw_val:04X}", 
                            f"{fpga_float:.4f}", 
                            f"{expected_float:.4f}", 
                            f"{diff:.6f}",
                            status
                        ])
                        
                        # Tampilkan progres setiap 1000 data
                        if (idx + 1) % 1000 == 0:
                            print(f"      Progress: {idx + 1}/{total_tests} data diproses...")
                            
                    else:
                        print(f"      TIMEOUT pada input: {val}. Cek kabel/FPGA.")
                        break

        duration = time.time() - start_time
        print(f"\n[SELESAI] Semua data tersimpan di '{OUTPUT_FILE}'.")
        print(f"          Waktu eksekusi: {duration:.2f} detik.")
        ser.close()

    except serial.SerialException:
        print(f"ERROR: Tidak bisa membuka port {PORT_NAME}. Pastikan tidak sedang dipakai aplikasi lain.")

if __name__ == "__main__":
    generate_csv_input()
    run_fpga_test()