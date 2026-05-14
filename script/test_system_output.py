import csv
import serial
import struct
import time
import math
import sys
import os
import numpy as np  # Kita butuh numpy buat ngitung SQNR/Statistik biar gaya

# ================= KONFIGURASI =================
PORT_NAME = 'COM5'   
BAUD_RATE = 115200     
INPUT_FILE = 'input_vectors.csv' 
OUTPUT_FILE = 'scientific_results.csv' # Nama file biar keren dikit

# Toleransi Error dalam LSB (2 LSB = toleransi selisih 2 bit terakhir)
# Untuk Q8.8, 1 LSB = 1/256 = ~0.0039
MAX_LSB_TOLERANCE = 2.0 
# ===============================================

def run_scientific_test():
    if not os.path.exists(INPUT_FILE):
        print(f"ERROR: File '{INPUT_FILE}' tidak ditemukan!")
        return

    print(f"[1/2] Connecting to {PORT_NAME}...")
    
    try:
        ser = serial.Serial(PORT_NAME, BAUD_RATE, timeout=1)
        time.sleep(2)
        
        # Array untuk menampung data statistik akhir
        list_expected = []
        list_actual = []
        list_errors = []
        
        with open(OUTPUT_FILE, mode='w', newline='') as outfile:
            writer = csv.writer(outfile)
            writer.writerow([
                'Input (Dec)', 
                'Expected (Float)', 
                'FPGA (Q8.8)', 
                'Abs Error', 
                'Error (LSB)',   # <--- Kolom Baru yang Elegan
                'Status'
            ])
            
            with open(INPUT_FILE, mode='r') as infile:
                reader = csv.DictReader(infile)
                rows = list(reader)
                total_tests = len(rows)
                
                print(f"[2/2] Running precision test on {total_tests} vectors...")
                start_time = time.time()
                
                pass_count = 0
                
                for idx, row in enumerate(rows):
                    try:
                        val = int(row['decimal_input'])
                        
                        # 1. Kirim
                        ser.write(struct.pack('<H', val))
                        
                        # 2. Terima
                        response = ser.read(2)
                        
                        if len(response) == 2:
                            raw_val = struct.unpack('<H', response)[0]
                            fpga_float = raw_val / 256.0
                            expected_float = math.sqrt(val)
                            
                            # --- PERHITUNGAN ELEGAN ---
                            abs_error = abs(fpga_float - expected_float)
                            
                            # Konversi Error ke satuan LSB
                            # Rumus: Error / (1/256)  SAMA DENGAN  Error * 256
                            error_in_lsb = abs_error * 256.0
                            
                            # Pass/Fail berdasarkan presisi hardware (bukan angka asal 0.1)
                            is_pass = error_in_lsb <= MAX_LSB_TOLERANCE
                            status = 'PASS' if is_pass else 'FAIL'
                            
                            if is_pass: pass_count += 1
                            
                            # Simpan data untuk statistik global
                            list_expected.append(expected_float)
                            list_actual.append(fpga_float)
                            list_errors.append(abs_error)

                            writer.writerow([
                                val,
                                f"{expected_float:.4f}",
                                f"{fpga_float:.4f}",
                                f"{abs_error:.6f}",
                                f"{error_in_lsb:.2f} LSB", # Keren nih di CSV
                                status
                            ])
                            
                            if (idx + 1) % 1000 == 0:
                                print(f"      Processing: {idx + 1}/{total_tests}...")
                        else:
                            print(f"TIMEOUT @ Input {val}")
                            break
                            
                    except ValueError:
                        continue

        # --- STATISTIK AKHIR (Buat Laporan) ---
        duration = time.time() - start_time
        
        # Hitung SQNR (Signal to Quantization Noise Ratio)
        # Rumus: 10 * log10( Power_Signal / Power_Error )
        arr_signal = np.array(list_expected)
        arr_error = np.array(list_errors)
        
        # Hindari division by zero
        power_signal = np.sum(arr_signal ** 2)
        power_error = np.sum(arr_error ** 2)
        
        if power_error == 0:
            sqnr = 999.0 # Perfect score
        else:
            sqnr = 10 * np.log10(power_signal / power_error)
            
        max_lsb_error = max(list_errors) * 256.0
        avg_lsb_error = np.mean(list_errors) * 256.0

        print("\n" + "="*50)
        print("          FINAL STATISTICAL REPORT          ")
        print("="*50)
        print(f"Total Vectors  : {total_tests}")
        print(f"Passed         : {pass_count} ({(pass_count/total_tests)*100:.2f}%)")
        print("-" * 50)
        print(f"Max Error      : {max_lsb_error:.2f} LSB")
        print(f"Avg Error      : {avg_lsb_error:.2f} LSB")
        print(f"SQNR           : {sqnr:.2f} dB  <-- Masukkan ini ke laporan!")
        print("="*50)
        print(f"Results saved to '{OUTPUT_FILE}'")
        ser.close()

    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    run_scientific_test()