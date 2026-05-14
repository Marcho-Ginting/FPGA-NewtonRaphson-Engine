# FPGA-Based Hardware Accelerator: Newton-Raphson Square Root Machine

A high-speed, hardware-accelerated computational engine designed for real-time mathematical operations using the Newton-Raphson iterative method.

## 📊 Technical Specifications
* **Language:** VHDL.
* **Arithmetic:** Q2.30 Fixed-Point Math (32-bit internal precision).
* **Architecture:** Iterative pipelined logic optimized for FPGA implementation.
* **Validation:** Verified against 65,535 test vectors with 100% computational accuracy.

## ⚡ Engineering Highlights
* **Fixed-Point Precision:** Implemented **Q2.30 math** to maintain high numerical precision while minimizing resource utilization on the FPGA fabric.
* **Iterative Optimization:** Leveraged the Newton-Raphson method to achieve fast convergence for square root calculations, outperforming standard software-based implementations.
* **Robust Verification:** Engineered a comprehensive testbench that validated the design across the entire input range of **65,535 vectors**, ensuring zero-error performance.

## 📂 Repository Structure
* `/src`: Core VHDL source files for the Newton-Raphson hardware engine.
* `/tb`: Testbench files used for the 65,535 vector validation.
* `/simulation`: Functional and timing simulation files.
* `/docs`: Technical documentation and mathematical derivation of the Q2.30 logic.
* `/script`: Automation scripts for synthesis or simulation flows.
* `/output_files`: Compiled hardware bitstreams and synthesis reports.
* `top_squarero...igital_uart.qpf`: Intel Quartus Prime Project File.

## 📷 Interface Snapshot
<img width="1600" height="870" src="https://github.com/user-attachments/assets/f227c732-83aa-454e-a4bd-e08f86fa08f5" />
