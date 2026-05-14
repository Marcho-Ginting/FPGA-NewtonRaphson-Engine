import pandas as pd
import numpy as np
import os

# Konfigurasi Nama File
FILE_PRECISION = 'scientific_results.csv'
FILE_LATENCY = 'latency_results.csv'
OUTPUT_FILE = 'FPGA_Performance_Analysis.csv'

def generate_full_analysis():
    print("Membaca data dari CSV...")
    
    # Cek file ada atau tidak
    if not os.path.exists(FILE_PRECISION) or not os.path.exists(FILE_LATENCY):
        print("ERROR: File CSV input tidak ditemukan. Pastikan sudah menjalankan tes sebelumnya.")
        return

    # --- 1. LOAD DATA ---
    try:
        df_sci = pd.read_csv(FILE_PRECISION)
        df_lat = pd.read_csv(FILE_LATENCY)
        
        # Bersihkan kolom 'Error (LSB)' yang ada teks " LSB"-nya
        df_sci['Error (LSB)'] = df_sci['Error (LSB)'].astype(str).str.replace(' LSB', '', regex=False).astype(float)
        
    except Exception as e:
        print(f"Error saat membaca file: {e}")
        return

    # --- 2. HITUNG INDIKATOR PRESISI ---
    total_vectors = len(df_sci)
    avg_error = df_sci['Error (LSB)'].mean()
    max_error = df_sci['Error (LSB)'].max()
    std_error = df_sci['Error (LSB)'].std()
    
    # Pass Rates (Bandingkan 2 standar)
    pass_strict = (df_sci['Error (LSB)'] <= 2.0).sum()
    rate_strict = (pass_strict / total_vectors) * 100
    
    pass_relaxed = (df_sci['Error (LSB)'] <= 10.0).sum()
    rate_relaxed = (pass_relaxed / total_vectors) * 100

    # SQNR (Signal to Noise Ratio)
    # Rumus: 10 * log10( Power_Signal / Power_Error )
    signal_power = (df_sci['Expected (Float)'] ** 2).sum()
    error_power = (df_sci['Abs Error'] ** 2).sum()
    
    if error_power == 0:
        sqnr = 999.0 # Infinity
    else:
        sqnr = 10 * np.log10(signal_power / error_power)

    # --- 3. HITUNG INDIKATOR PERFORMA (TIMING) ---
    avg_lat = df_lat['latency_ms'].mean()
    min_lat = df_lat['latency_ms'].min()
    max_lat = df_lat['latency_ms'].max()
    jitter = df_lat['latency_ms'].std()
    throughput = 1000.0 / avg_lat if avg_lat > 0 else 0

    # --- 4. BUAT TABEL RANGKUMAN ---
    summary_data = [
        # KATEGORI: STATISTIK UMUM
        ['General', 'Total Test Vectors', total_vectors, 'Jumlah data uji input (0-65535)'],
        
        # KATEGORI: AKURASI & PRESISI
        ['Precision', 'Pass Rate (Strict < 2 LSB)', f"{rate_strict:.2f} %", 'Success rate dengan toleransi ketat (Ideal Rounding)'],
        ['Precision', 'Pass Rate (Relaxed < 10 LSB)', f"{rate_relaxed:.2f} %", 'Success rate dengan toleransi Truncation (Real Hardware)'],
        ['Precision', 'Average Error', f"{avg_error:.4f} LSB", 'Rata-rata penyimpangan bit'],
        ['Precision', 'Max Error', f"{max_error:.4f} LSB", 'Penyimpangan terburuk (Worst Case)'],
        ['Precision', 'Error Std Dev', f"{std_error:.4f} LSB", 'Variasi kestabilan error'],
        
        # KATEGORI: KUALITAS SINYAL
        ['Signal Quality', 'SQNR', f"{sqnr:.2f} dB", 'Kualitas sinyal output (Target > 48 dB untuk 8-bit)'],
        
        # KATEGORI: KECEPATAN (PERFORMANCE)
        ['Timing', 'Average Latency', f"{avg_lat:.4f} ms", 'Rata-rata waktu proses per data'],
        ['Timing', 'Max Latency', f"{max_lat:.4f} ms", 'Waktu terlama (Lag spike)'],
        ['Timing', 'Jitter', f"{jitter:.4f} ms", 'Ketidakstabilan waktu komunikasi'],
        ['Timing', 'System Throughput', f"{throughput:.2f} ops/sec", 'Estimasi jumlah operasi per detik (@9600 baud)']
    ]

    # Buat DataFrame
    df_summary = pd.DataFrame(summary_data, columns=['Category', 'Metric', 'Value', 'Description'])

    # --- 5. SIMPAN KE CSV ---
    df_summary.to_csv(OUTPUT_FILE, index=False)
    
    print("="*60)
    print(f"✅ SUKSES! File analisis tersimpan di: {OUTPUT_FILE}")
    print("="*60)
    print(df_summary.to_string(index=False))

if __name__ == "__main__":
    # Pastikan library pandas terinstall: pip install pandas
    generate_full_analysis()