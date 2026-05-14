import tkinter as tk
from tkinter import ttk, messagebox
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import serial
import serial.tools.list_ports
import threading
import time
import math
import queue

# =============================================================================
# KONFIGURASI TEMA (LIGHT MODE - FINAL)
# =============================================================================
THEME_DARK_MODE = False  

if THEME_DARK_MODE:
    plt.style.use('dark_background')
    COLOR_BG_APP    = "#121212"
    COLOR_FG_TEXT   = "white"
    COLOR_IDEAL     = "#00FFFF"
    COLOR_FPGA      = "#00FF00"
    COLOR_ERROR     = "#FF5555"
    COLOR_LATENCY   = "#FF00FF"
    COLOR_GRID      = "#333333"
else:
    plt.style.use('default')        
    COLOR_BG_APP    = "#F5F5F5"     # Abu-abu muda
    COLOR_FG_TEXT   = "black"       
    
    # WARNA GRAFIK
    COLOR_IDEAL     = "#006400"     # Dark Green (Ideal Line)
    COLOR_FPGA      = "#0000FF"     # Blue (FPGA Dots)
    COLOR_ERROR     = "#D32F2F"     # Red (Error Dots)
    COLOR_LATENCY   = "#800080"     # Purple (Latency Line)
    COLOR_GRID      = "#E0E0E0"     # Abu-abu tipis

DEFAULT_BAUD = 115200
REFRESH_RATE_MS = 200 

class FPGADashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("FPGA Square Root Accelerator - Live Demo System")
        self.root.geometry("1280x850")
        self.root.configure(bg=COLOR_BG_APP)
        
        # Style Configuration
        style = ttk.Style()
        style.theme_use('clam')
        
        style.configure("TFrame", background=COLOR_BG_APP)
        style.configure("TLabel", background=COLOR_BG_APP, foreground=COLOR_FG_TEXT)
        style.configure("TLabelframe", background=COLOR_BG_APP, foreground=COLOR_FG_TEXT)
        style.configure("TLabelframe.Label", background=COLOR_BG_APP, foreground=COLOR_FG_TEXT)
        
        # Variables
        self.is_running = False
        self.ser = None
        self.data_queue = queue.Queue()
        
        self.inputs = []
        self.outputs = []
        self.ideals = []
        self.errors = []
        self.latencies = []
        
        # --- UI SETUP ---
        self.setup_control_panel()
        self.setup_dashboard_plots()
        
        # Start GUI Update Loop
        self.root.after(REFRESH_RATE_MS, self.update_gui)

    def setup_control_panel(self):
        # Frame Kontrol
        ctrl_frame = ttk.Frame(self.root, padding="10")
        ctrl_frame.pack(side=tk.TOP, fill=tk.X)
        
        # Kiri: Koneksi
        frame_conn = ttk.Labelframe(ctrl_frame, text=" Connection Setup ", padding="5")
        frame_conn.pack(side=tk.LEFT, padx=5)
        
        ttk.Label(frame_conn, text="Port:").pack(side=tk.LEFT)
        self.port_combo = ttk.Combobox(frame_conn, width=15)
        self.port_combo.pack(side=tk.LEFT, padx=5)
        self.refresh_ports()
        
        ttk.Label(frame_conn, text="Baud:").pack(side=tk.LEFT, padx=5)
        self.baud_entry = ttk.Entry(frame_conn, width=8)
        self.baud_entry.insert(0, str(DEFAULT_BAUD))
        self.baud_entry.pack(side=tk.LEFT)

        # Tengah: Tombol Start
        self.btn_start = ttk.Button(ctrl_frame, text="▶ START DEMO", command=self.toggle_test)
        self.btn_start.pack(side=tk.LEFT, padx=20, fill=tk.Y, ipadx=10)

        # Kanan: Status
        frame_stat = ttk.Frame(ctrl_frame)
        frame_stat.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=20)
        
        self.lbl_status = ttk.Label(frame_stat, text="SYSTEM READY", font=("Arial", 10, "bold"), foreground="gray")
        self.lbl_status.pack(anchor="w")
        
        self.progress = ttk.Progressbar(frame_stat, orient="horizontal", length=300, mode="determinate")
        self.progress.pack(fill=tk.X, pady=2)
        
        self.lbl_counter = ttk.Label(frame_stat, text="0 / 65535 (0%)")
        self.lbl_counter.pack(anchor="e")

    def setup_dashboard_plots(self):
        # Panel Statistik Angka
        stats_frame = ttk.Frame(self.root, padding="5")
        stats_frame.pack(side=tk.TOP, fill=tk.X)
        
        def create_stat_box(parent, label, text_color):
            frame = ttk.Frame(parent, borderwidth=1, relief="solid")
            frame.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=2)
            
            lbl_title = ttk.Label(frame, text=label, font=("Arial", 8), anchor="center")
            lbl_title.config(background="#E0E0E0", foreground="black") 
            lbl_title.pack(fill=tk.X)
            
            lbl_val = ttk.Label(frame, text="--", font=("Consolas", 16, "bold"), foreground=text_color, anchor="center")
            lbl_val.config(background="white")
            lbl_val.pack(pady=5, fill=tk.X)
            return lbl_val

        self.val_input = create_stat_box(stats_frame, "INPUT INTEGER", "black")
        self.val_output = create_stat_box(stats_frame, "FPGA RESULT", COLOR_FPGA)
        self.val_error = create_stat_box(stats_frame, "ERROR (LSB)", COLOR_ERROR)
        self.val_latency = create_stat_box(stats_frame, "LATENCY (ms)", COLOR_LATENCY)

        # Area Plotting
        self.fig = plt.figure(figsize=(10, 8), dpi=100)
        self.fig.patch.set_facecolor(COLOR_BG_APP) 
            
        gs = self.fig.add_gridspec(3, 2, height_ratios=[2, 1.5, 1.5]) 
        
        # --- 1. Main Curve (System Response) ---
        self.ax1 = self.fig.add_subplot(gs[0, :])
        self.ax1.set_title("System Response (Input vs Output)", fontsize=10, fontweight='bold', color=COLOR_FG_TEXT)
        self.ax1.set_xlim(0, 65535)
        self.ax1.set_ylim(0, 256)
        self.ax1.grid(True, linestyle=':', color=COLOR_GRID)
        
        # >>> ADDED AXIS LABELS <<<
        self.ax1.set_xlabel("Input Integer (16-bit Unsigned)", fontsize=9, color=COLOR_FG_TEXT)
        self.ax1.set_ylabel("Output Value (Q8.8 Fixed-Point)", fontsize=9, color=COLOR_FG_TEXT)
        
        self.line_ideal, = self.ax1.plot([], [], color=COLOR_IDEAL, linewidth=1.5, label='Ideal Math (Ref)', alpha=0.8)
        self.line_fpga, = self.ax1.plot([], [], '.', color=COLOR_FPGA, markersize=2, label='FPGA Hardware', alpha=0.6)
        
        leg = self.ax1.legend(loc='upper left')
        
        # --- 2. Error Scatter ---
        self.ax2 = self.fig.add_subplot(gs[1, 0])
        self.ax2.set_title("Error Distribution (Precision)", fontsize=9, color=COLOR_FG_TEXT)
        self.ax2.set_xlim(0, 65535)
        self.ax2.set_ylim(0, 10) 
        self.ax2.grid(True, linestyle=':', color=COLOR_GRID)
        
        # >>> ADDED AXIS LABELS <<<
        self.ax2.set_xlabel("Input Integer", fontsize=8, color=COLOR_FG_TEXT)
        self.ax2.set_ylabel("Error Magnitude (LSB)", fontsize=8, color=COLOR_FG_TEXT)
        
        self.ax2.axhline(y=2, color=COLOR_IDEAL, linestyle='--', alpha=0.5, linewidth=1, label="Strict Limit") 
        self.scat_error, = self.ax2.plot([], [], '.', color=COLOR_ERROR, markersize=1, alpha=0.5)

        # --- 3. Latency ---
        self.ax3 = self.fig.add_subplot(gs[1, 1])
        self.ax3.set_title("Communication Latency (Performance)", fontsize=9, color=COLOR_FG_TEXT)
        self.ax3.set_xlim(0, 65535)
        self.ax3.grid(True, linestyle=':', color=COLOR_GRID)
        
        # >>> ADDED AXIS LABELS <<<
        self.ax3.set_xlabel("Input Integer", fontsize=8, color=COLOR_FG_TEXT)
        self.ax3.set_ylabel("Latency (ms)", fontsize=8, color=COLOR_FG_TEXT)
        
        self.line_latency, = self.ax3.plot([], [], color=COLOR_LATENCY, linewidth=1)

        self.fig.tight_layout()
        
        self.canvas = FigureCanvasTkAgg(self.fig, master=self.root)
        self.canvas.draw()
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

    def refresh_ports(self):
        ports = [p.device for p in serial.tools.list_ports.comports()]
        ports.append("SIMULATION_MODE")
        self.port_combo['values'] = ports
        if ports: self.port_combo.current(0)

    def toggle_test(self):
        if not self.is_running:
            port = self.port_combo.get()
            baud = self.baud_entry.get()
            
            # Clear Data
            self.inputs = []
            self.outputs = []
            self.ideals = []
            self.errors = []
            self.latencies = []
            
            self.line_fpga.set_data([], [])
            self.scat_error.set_data([], [])
            self.line_latency.set_data([], [])
            self.canvas.draw()

            if port == "SIMULATION_MODE":
                self.ser = None
                self.lbl_status.config(text="MODE: SIMULATION", foreground="orange")
            else:
                try:
                    self.ser = serial.Serial(port, int(baud), timeout=1)
                    self.lbl_status.config(text=f"CONNECTED: {port}", foreground="green")
                except Exception as e:
                    messagebox.showerror("Connection Error", str(e))
                    return

            self.is_running = True
            self.btn_start.config(text="■ STOP")
            threading.Thread(target=self.worker_process, daemon=True).start()
        else:
            self.is_running = False
            if self.ser: self.ser.close()
            self.btn_start.config(text="▶ START DEMO")
            self.lbl_status.config(text="STOPPED", foreground="red")

    def worker_process(self):
        # Loop Processing
        for i in range(1, 65536):
            if not self.is_running: break
            
            t_start = time.perf_counter()
            
            if self.ser:
                try:
                    self.ser.write(i.to_bytes(2, 'little'))
                    rx = self.ser.read(2)
                    if len(rx) != 2: continue
                    raw_val = int.from_bytes(rx, 'little')
                except: break
            else:
                # Simulasi
                time.sleep(0.00001) 
                ideal = math.sqrt(i)
                raw_val = int(math.floor(ideal * 256)) 
            
            t_end = time.perf_counter()
            lat = (t_end - t_start) * 1000
            
            val_fpga = raw_val / 256.0
            val_ideal = math.sqrt(i)
            err_lsb = abs(val_ideal - val_fpga) * 256.0
            
            self.data_queue.put((i, val_fpga, val_ideal, err_lsb, lat))
            
            # Throttle simulasi biar grafik terlihat 'jalan' (kalau real hardware hapus aja)
            if not self.ser and i % 100 == 0: time.sleep(0.001)

    def update_gui(self):
        new_pts = 0
        last_packet = None
        
        # 1. EMPTY THE QUEUE (Keep this fast!)
        while not self.data_queue.empty():
            last_packet = self.data_queue.get()
            self.inputs.append(last_packet[0])
            self.outputs.append(last_packet[1])
            self.ideals.append(last_packet[2])
            self.errors.append(last_packet[3])
            self.latencies.append(last_packet[4])
            new_pts += 1
            
        if new_pts > 0 and self.is_running:
            # Update Text Value (Keep this, it's cheap)
            self.val_input.config(text=str(last_packet[0]))
            self.val_output.config(text=f"{last_packet[1]:.4f}")
            
            err = last_packet[3]
            ec = COLOR_FPGA if err < 2 else "orange" if err < 8 else COLOR_ERROR
            self.val_error.config(text=f"{err:.2f}", foreground=ec)
            self.val_latency.config(text=f"{last_packet[4]:.2f}")
            
            # Update Progress
            curr = last_packet[0]
            pct = (curr / 65535) * 100
            self.progress['value'] = pct
            self.lbl_counter.config(text=f"{curr} / 65535 ({pct:.0f}%)")
            
            # --- THE FIX: DOWNSAMPLING ---
            # Instead of plotting everything, we slice the list [::step]
            # This plots every 50th point. 
            step = 50 if len(self.inputs) > 1000 else 1 
            
            self.line_ideal.set_data(self.inputs[::step], self.ideals[::step])
            self.line_fpga.set_data(self.inputs[::step], self.outputs[::step])
            self.scat_error.set_data(self.inputs[::step], self.errors[::step])
            self.line_latency.set_data(self.inputs[::step], self.latencies[::step])
            
            if self.latencies:
                mx = max(self.latencies)
                self.ax3.set_ylim(0, mx * 1.2 if mx > 0 else 10)

            # Now this draw call is light as a feather
            self.canvas.draw()
            
        self.root.after(REFRESH_RATE_MS, self.update_gui)

if __name__ == "__main__":
    root = tk.Tk()
    app = FPGADashboard(root)
    root.mainloop()