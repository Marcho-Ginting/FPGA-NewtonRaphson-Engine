import csv
import serial
import struct
import time
import math
import statistics

# ================= KONFIGURASI =================
PORT_NAME = 'COM9'   # SESUAIKAN COM PORT KAMU!
BAUD_RATE = 115200    
INPUT_FILE = 'input_vectors.csv' # Pastikan file ini sudah ada dari langkah sebelumnya
OUTPUT_FILE = 'latency_results.csv'
# ===============================================

def run_latency_test():
    print(f"[INFO] Membuka koneksi ke {PORT_NAME} untuk pengukuran delay...")
    
    try:
        ser = serial.Serial(PORT_NAME, BAUD_RATE, timeout=1)
        time.sleep(2)  # Tunggu FPGA stabil
        
        # List untuk menampung data latency
        latencies = []
        
        with open(OUTPUT_FILE, mode='w', newline='') as outfile:
            writer = csv.writer(outfile)
            # Header CSV
            writer.writerow([
                'input_decimal', 
                'input_hex', 
                'fpga_result_hex', 
                'latency_seconds', 
                'latency_ms'
            ])
            
            # Kita pakai data input yang sama (0 - 65535)
            # Jika file csv belum ada, kita generate range-nya langsung di sini
            test_range = range(0, 65536) 
            total_tests = len(test_range)
            
            print(f"[START] Memulai pengukuran untuk {total_tests} data...")
            
            # Catat waktu mulai total
            total_start_time = time.perf_counter()
            
            for i in test_range:
                val = i
                
                # 1. Packing Data
                data_to_send = struct.pack('<H', val)
                
                # === MULAI STOPWATCH (Per Proses) ===
                t_start = time.perf_counter()
                
                # 2. Kirim & Terima
                ser.write(data_to_send)
                response = ser.read(2)
                
                # === STOP STOPWATCH (Per Proses) ===
                t_end = time.perf_counter()
                
                # Hitung durasi per item
                duration = t_end - t_start
                duration_ms = duration * 1000.0 # Ubah ke milidetik
                
                if len(response) == 2:
                    raw_val = struct.unpack('<H', response)[0]
                    
                    # Simpan ke list untuk statistik akhir
                    latencies.append(duration)
                    
                    # Tulis ke CSV
                    writer.writerow([
                        val, 
                        f"0x{val:04X}", 
                        f"0x{raw_val:04X}", 
                        f"{duration:.6f}", 
                        f"{duration_ms:.3f}"
                    ])
                else:
                    print(f"TIMEOUT pada input {val}")
                    break
                
                # Progress bar sederhana
                if i % 5000 == 0:
                    print(f"   Progress: {i}/{total_tests} ... (Latest: {duration_ms:.2f} ms)")

            # Catat waktu selesai total
            total_end_time = time.perf_counter()
            
        # ================= HITUNG STATISTIK =================
        total_duration = total_end_time - total_start_time
        avg_latency = statistics.mean(latencies)
        min_latency = min(latencies)
        max_latency = max(latencies)
        throughput = total_tests / total_duration
        
        print("\n" + "="*40)
        print("HASIL PENGUKURAN DELAY (Input -> Output)")
        print("="*40)
        print(f"Total Data Proses : {total_tests} item")
        print(f"Total Waktu Real  : {total_duration:.2f} detik ({total_duration/60:.2f} menit)")
        print("-" * 40)
        print(f"Delay Rata-rata   : {avg_latency*1000:.3f} ms / proses")
        print(f"Delay Minimum     : {min_latency*1000:.3f} ms")
        print(f"Delay Maximum     : {max_latency*1000:.3f} ms")
        print("-" * 40)
        print(f"Throughput        : {throughput:.2f} operasi / detik")
        print("="*40)
        print(f"Detail tersimpan di '{OUTPUT_FILE}'")
        
        ser.close()

    except serial.SerialException:
        print(f"ERROR: Port {PORT_NAME} tidak bisa dibuka atau sedang dipakai.")

if __name__ == "__main__":
    run_latency_test()