# CNN1 - MNIST Hardware Accelerator on FPGA

A complete hardware-software co-design project for deploying a Convolutional Neural Network on FPGA to classify handwritten digits from the MNIST dataset.

## 🎯 Project Goal

Design and implement an FPGA-based hardware accelerator for real-time digit classification (0-9) with >90% accuracy.

**Achieved Accuracy: 97.39%** ✅

## 🏗️ Architecture

**Simplified CNN Pipeline:**
```
Input (28×28) → Conv (3×3, 4 filters) → ReLU → MaxPool (2×2) → Dense (676→10) → Digit
```

**Implementation:**
- **Software**: PyTorch reference model, training, quantization
- **Hardware**: Verilog RTL modules for FPGA deployment
- **Quantization**: Q4.4 fixed-point (8-bit signed integers)

## 📁 Project Structure

```
CNN1/
├── python/              # Software reference implementation
│   ├── train_mnist_cnn.py              # Train PyTorch model
│   ├── quantize_weights.py             # Convert to 8-bit fixed-point
│   └── generate_integration_test.py    # Generate test vectors
│
├── hardware/            # Verilog RTL modules
│   ├── line_buffer.v                   # 3×3 sliding window generator
│   ├── conv_unit.v                     # Convolution engine (9 parallel MACs)
│   ├── relu.v                          # ReLU activation function
│   ├── max_pool.v                      # 2×2 max pooling
│   ├── dense_layer.v                   # Fully connected layer
│   ├── cnn_top.v                       # Top-level integration
│   ├── tb_*.v                          # Testbenches
│   └── Makefile                        # Build automation
│
├── data/                # Datasets and model files
│   ├── MNIST/                          # Dataset (auto-downloaded)
│   ├── mnist_cnn_model.pth            # Trained model weights
│   └── integration_test/               # Test vectors
│
└── docs/
    └── PROJECT_DOCUMENTATION.md        # Complete architecture guide
```

## 🚀 Quick Start

### Prerequisites
```bash
# Python packages
pip install torch torchvision numpy

# Hardware simulation
sudo apt-get install iverilog gtkwave  # Linux
brew install icarus-verilog gtkwave    # macOS
```

### Step 1: Train the Model
```bash
cd python
python train_mnist_cnn.py
# Output: mnist_cnn_model.pth (97.39% test accuracy)
```

### Step 2: Quantize to Fixed-Point
```bash
python quantize_weights.py
# Generates: conv_weights.vh, fc_weights.vh (8-bit integers)
```

### Step 3: Run Hardware Tests
```bash
cd ../hardware
make test_line_buffer    # Test 3×3 window generation
make test_conv_unit      # Test convolution arithmetic
make test_all            # Run all working tests
```

### Step 4: View Results
```bash
# Check test output
cat build/*.log

# View waveforms (if generated)
gtkwave build/*.vcd
```

## ✅ Verification Status

| Module | Test Status | Notes |
|--------|-------------|-------|
| Line Buffer | ✅ PASS | Generates 676 correct 3×3 windows |
| Conv Unit | ✅ PASS | Exact arithmetic verified |
| ReLU | ✅ PASS | Combinational logic |
| Max Pool | ⚠️ Created | Testbench hangs (needs debug) |
| System Integration | ⚠️ Created | Pipeline test hangs (needs debug) |
| Dense Layer | ⏳ Pending | Not tested yet |
| Full CNN | ⏳ Pending | Awaiting module fixes |

## 📊 Performance Estimates

**Software Model:**
- Test Accuracy: **97.39%**
- Model Size: 6,810 parameters
- Quantization Error: <0.02

**Hardware (Estimated for Artix-7 XC7A35T @ 100 MHz):**
- LUTs: ~8,000 (38% utilization)
- Registers: ~5,000 (12%)
- DSP48E1: 36-45 (40% - for multipliers)
- Block RAM: 6 (12%)
- **Throughput: ~66,666 images/sec**
- **Latency: ~15 μs/image**
- **Power: ~200-500 mW**

## 🔍 Key Features

**Software:**
- PyTorch implementation for easy training
- Automatic MNIST dataset download
- 8-bit fixed-point quantization with <2% error
- Test vector generation for hardware validation

**Hardware:**
- Modular Verilog design (easy to understand/modify)
- Parallel convolution engine (9 MACs)
- Efficient line buffer (minimal memory)
- Comprehensive testbenches with Makefile automation
- Fits on low-cost FPGAs (Artix-7 and larger)

## 📖 Documentation

For detailed architecture, module descriptions, and complete design flow:
- **[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)** - Comprehensive guide

Key sections:
- Complete file-by-file descriptions
- Hardware-software integration
- Module architecture diagrams
- Testing and verification strategy
- Performance analysis
- Future improvements

## 🛠️ Current Limitations & Future Work

**Needs Debugging:**
- Max pooling module (state machine hangs)
- System integration test (pipeline stalls)
- Dense layer weight memory access

**Planned Enhancements:**
1. **Pipeline Optimization**: Add inter-stage registers for higher throughput
2. **Deeper Network**: Add 2nd conv layer for >98% accuracy
3. **Board Integration**: Camera input, HDMI output
4. **AXI Interface**: Enable SoC integration (Zynq)
5. **Weight Compression**: Pruning + quantization for 50% memory savings

## 📚 Learning Outcomes

This project teaches:
- ✅ CNN architecture design and training (PyTorch)
- ✅ Neural network quantization techniques
- ✅ Verilog RTL design for digital signal processing
- ✅ FPGA resource estimation and optimization
- ✅ Hardware-software co-verification
- ✅ Fixed-point arithmetic in hardware
- ✅ Pipeline and datapath design

## 🎓 Suitable For

- FPGA/hardware acceleration beginners
- Machine learning engineers exploring edge deployment
- Computer engineering students (senior projects)
- Prototyping low-latency ML inference systems

## 📝 License

See [LICENSE](../LICENSE) file in repository root.

## 🤝 Contributing

This is an educational project. Feel free to:
- Fix bugs (especially max_pool and integration tests!)
- Add documentation
- Optimize modules
- Add new features

## 📧 Contact

For questions about this project, see the parent repository.

---

**Project Status**: 🟡 **90% Complete** - Core modules working, integration debugging in progress

**Last Updated**: February 10, 2026
