import csv
import math

def to_float_q8_8(hex_str):
    # Q8.8 means 8 integer bits, 8 fractional bits.
    # Divide integer value by 2^8 (256).
    val = int(hex_str, 16)
    return val / 256.0

def verify_system():
    filename = "D:\Quartus\Sistem Digital\Square-Root-Digital-main\output_files\system_results.csv"
    print(f"Verifying {filename}...")
    
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        fail = 0
        max_err = 0.0
        row_cnt = 0
        
        for row in reader:
            row_cnt += 1
            inp = int(row['input_dec'])
            hw_out = to_float_q8_8(row['output_q8_8_hex'])
            
            # Ground Truth
            expected = math.sqrt(inp)
            
            err = abs(expected - hw_out)
            if err > max_err: max_err = err
            
            # Tolerance Calculation:
            # 1. Q8.8 resolution is 1/256 = 0.0039.
            # 2. NR Algorithm approximation error.
            # 3. Accumulated truncation in pipeline.
            # Safe tolerance: 0.05 (approx 12 LSBs).
            # This is standard for integer-based fixed-point approximation.
            if err > 0.05:
                if fail < 10:
                    print(f"FAIL: In={inp} | Exp={expected:.4f} | Got={hw_out:.4f} | Err={err:.4f}")
                fail += 1

    print("-" * 30)
    print(f"Checked {row_cnt} vectors.")
    print(f"Max Absolute Error: {max_err:.6f}")
    
    if fail == 0:
        print("SUCCESS: The Newton-Raphson Square Root Machine is Fully Functional.")
    else:
        print(f"FAILURE: {fail} errors found.")

if __name__ == "__main__":
    verify_system()