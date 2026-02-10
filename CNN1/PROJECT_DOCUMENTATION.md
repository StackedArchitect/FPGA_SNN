# CNN1 - MNIST Hardware Accelerator

## Complete Project Architecture & Documentation

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Complete File Structure](#complete-file-structure)
3. [Detailed File Descriptions](#detailed-file-descriptions)
4. [Hardware-Software Integration Flow](#hardware-software-integration-flow)
5. [Module Architecture](#module-architecture)
6. [Testing Strategy](#testing-strategy)
7. [Results & Performance](#results--performance)
8. [Future Improvements](#future-improvements)

---

## 1. Project Overview

**Objective**: Design and implement a hardware accelerator on FPGA for classifying handwritten digits (0-9) using the MNIST dataset.

**Architecture**: Simplified Convolutional Neural Network
- 1 Convolutional Layer (3×3, 4 filters)
- ReLU Activation
- Max Pooling (2×2, stride 2)
- Fully Connected Layer (676 → 10 classes)

**Target Accuracy**: >90% (Achieved: **97.39%**)

**Implementation**: Hybrid hardware-software co-design
- **Software**: PyTorch reference model, training, quantization
- **Hardware**: Verilog RTL modules for FPGA deployment

---

## 2. Complete File Structure

```
CNN1/
├── README.md                          # Project overview
├── python/                            # Software implementation
│   ├── train_mnist_cnn.py            # Train CNN model
│   ├── quantize_weights.py           # Quantize weights to 8-bit
│   ├── test_inference.py             # Test single images
│   └── generate_integration_test.py  # Generate hardware test data
├── hardware/                          # Verilog RTL implementation
│   ├── line_buffer.v                 # 3×3 sliding window generator
│   ├── conv_unit.v                   # Convolution engine
│   ├── relu.v                        # ReLU activation
│   ├── max_pool.v                    # Max pooling
│   ├── dense_layer.v                 # Fully connected layer
│   ├── cnn_top.v                     # Top-level integration
│   ├── tb_line_buffer.v              # Line buffer testbench
│   ├── tb_conv_unit.v                # Conv unit testbench
│   ├── tb_max_pool.v                 # Max pool testbench
│   ├── tb_system_simple.v            # System integration testbench
│   ├── Makefile                      # Build automation
│   ├── conv_weights.vh               # Conv layer weights (generated)
│   ├── conv_bias.vh                  # Conv layer biases (generated)
│   ├── fc_weights.vh                 # FC layer weights (generated)
│   └── fc_bias.vh                    # FC layer biases (generated)
├── data/                              # Datasets and model files
│   ├── MNIST/                        # MNIST dataset (auto-downloaded)
│   ├── mnist_cnn_model.pth          # Trained PyTorch model
│   ├── model_info.json              # Model metadata
│   ├── quantization_info.json       # Quantization parameters
│   ├── conv_weights.txt             # Human-readable weights
│   ├── fc_weights.txt               # Human-readable weights
│   ├── test_images/                 # Test images for verification
│   │   └── mnist_*_label*.hex       # Test image hex dumps
│   └── integration_test/            # System test data
│       ├── input_image.hex          # Test image (hex format)
│       ├── input_image.mem          # Test image (memory format)
│       ├── expected_conv_filter0.txt # Expected conv outputs
│       └── expected_scores.txt      # Expected class scores
└── docs/
    └── ARCHITECTURE.md               # Detailed hardware architecture
```

---

## 3. Detailed File Descriptions

### 3.1 Python Files (Software Reference)

#### `train_mnist_cnn.py`
**Purpose**: Train the reference CNN model on MNIST dataset

**What it does**:
1. Defines `SimpleMNISTCNN` architecture
   - Conv2D: 1 input channel → 4 output channels, 3×3 kernel
   - ReLU activation
   - MaxPool2D: 2×2 window, stride 2
   - Linear/Dense: 676 → 10 classes
2. Downloads MNIST dataset (60,000 training, 10,000 test images)
3. Trains for 10 epochs using Adam optimizer
4. Achieves **97.39% test accuracy**
5. Saves model to `mnist_cnn_model.pth`
6. Saves metadata to `model_info.json`

**Output Files**:
- `../data/mnist_cnn_model.pth` - Trained weights (float32)
- `../data/model_info.json` - Architecture & accuracy info

**Run**: `python train_mnist_cnn.py`

---

####`quantize_weights.py`
**Purpose**: Convert floating-point weights to fixed-point for hardware

**What it does**:
1. Loads trained model from `.pth` file
2. Analyzes weight distributions (min, max, mean, std)
3. Quantizes to **Q4.4 format** (4 integer bits, 4 fractional bits)
   - Scale factor: 16 (2^4)
   - Range: [-8.0, 7.9375]
   - Bit width: 8-bit signed integers
4. Generates Verilog header files (.vh) with weight arrays
5. Reports quantization error (typically <0.02)

**Output Files**:
- `../hardware/conv_weights.vh` - 36 conv weights (4 filters × 9 weights)
- `../hardware/conv_bias.vh` - 4 conv biases
- `../hardware/fc_weights.vh` - 6,760 FC weights (10 × 676)
- `../hardware/fc_bias.vh` - 10 FC biases
- `../data/quantization_info.json` - Scale factors & precision info

**Run**: `python quantize_weights.py`

---

#### `test_inference.py`
**Purpose**: Test inference on individual MNIST images

**What it does**:
1. Loads trained model
2. Runs inference (float and quantized) on test images
3. Compares predictions and confidence scores
4. Visualizes images as ASCII art
5. Exports images to hex format for Verilog testbenches
6. Saves expected outputs for hardware verification

**Output Files**:
- `../data/test_images/mnist_<idx>_label<L>.hex` - Test image
- `../data/test_images/mnist_<idx>_label<L>_expected.txt` - Expected results

**Run**: `python test_inference.py` (interactive)

---

#### `generate_integration_test.py`
**Purpose**: Generate comprehensive test data for system-level verification

**What it does**:
1. Loads model and test images
2. Captures intermediate layer outputs:
   - Conv layer: 26×26×4
   - ReLU output: 26×26×4
   - Pool output: 13×13×4
   - Final scores: 10 classes
3. Exports in multiple formats:
   - `.hex` - Human-readable hex dump
   - `.mem` - Verilog $readmemh format
   - `.txt` - Expected outputs for comparison

**Output Files** (per image):
- `input_image.hex/mem` - Input pixel data
- `expected_conv_filter0.txt` - Conv layer outputs
- `expected_scores.txt` - Final class scores

**Run**: `python generate_integration_test.py`

---

### 3.2 Hardware Files (Verilog RTL)

#### `line_buffer.v`
**Purpose**: Generate 3×3 sliding windows from streaming pixel input

**Architecture**:
- **Inputs**: Streaming pixels (1 per clock cycle)
- **Buffers**: 3 row buffers (each 28 pixels)
- **Outputs**: 3×3 window + valid signal

**Operation**:
1. Stores incoming pixels in row buffers (circular)
2. After receiving rows 0, 1, and 2 pixels (at position ≥2), forms first 3×3 window
3. Continues generating windows for all valid positions
4. Total windows: 26×26 = 676 (no padding)

**Timing**:
- Latency: 58 cycles (2 full rows + 2 pixels)
- Throughput: 1 window/cycle after initial latency
- Total: 784 pixels in → 676 windows out

**Test Result**: ✅ PASS (676 windows generated correctly)

---

#### `conv_unit.v`
**Purpose**: Perform 3×3 convolution with learnable weights

**Architecture**:
- **9 parallel multipliers** (8×8 → 16-bit products)
- **4-level adder tree** for fast summation
- **Bias addition**
- **Registered output** (1 cycle latency)

**Operation**:
```
output = Σ(window[i] × weight[i]) + bias, i = 0..8
```

**Resource Usage**:
- Multipliers: 9× (8×8 bits)
- Adders: 8 (tree structure)
- Registers: ~20 bits

**Test Result**: ✅ PASS (Identity & uniform weight tests correct)

---

#### `relu.v`
**Purpose**: Apply ReLU activation function

**Architecture**: Pure combinational logic

**Operation**:
```verilog
output = (input < 0) ? 0 : input
```

**Implementation**: Check MSB (sign bit), output 0 if negative

**Latency**: 0 cycles (combinational)

---

#### `max_pool.v`
**Purpose**: 2×2 max pooling with stride 2

**Architecture**:
- **State machine**: IDLE → COLLECT → OUTPUT
- **Row buffer**: Stores one complete row
- **Comparator tree**: Finds max of 4 values

**Operation**:
1. Collects 2×2 blocks of pixels
2. Outputs maximum value in each block
3. Stride 2 → non-overlapping windows

**I/O**: 26×26 input → 13×13 output (per filter)

**Status**: ⚠️ Implementation has timing issues (needs debugging)

---

#### `dense_layer.v`
**Purpose**: Fully connected classification layer

**Architecture**:
- **Serial MAC**: Process one feature at a time
- **10 parallel accumulators** (one per class)
- **Weight memory interface**

**Operation**:
```
class_score[j] = Σ(feature[i] × weight[j][i]) + bias[j]
for j=0..9, i=0..675
```

**Timing**:
- Cycles: ~676 to process all inputs
- Outputs: 10 class scores

**Status**: ⚠️ Needs refinement for weight memory access

---

#### `cnn_top.v`
**Purpose**: Integrate all modules into complete pipeline

**Data Flow**:
```
Input (28×28)
    ↓
LineBuffer (3×3 windows)
    ↓
Conv (4 filters) → 26×26×4
    ↓
ReLU → 26×26×4
    ↓
MaxPool (2×2) → 13×13×4 = 676 features
    ↓
Dense Layer → 10 class scores
    ↓
Argmax → Predicted digit (0-9)
```

**Status**: ⚠️ Needs debugging for full integration

---

### 3.3 Testbench Files

#### `tb_line_buffer.v`
Tests 3×3 window generation with incrementing pixel pattern
- **Result**: ✅ PASS (676 windows, correct values)

#### `tb_conv_unit.v`
Tests convolution arithmetic with known weights
- **Result**: ✅ PASS (Identity kernel & uniform weights correct)

#### `tb_max_pool.v`
Tests max pooling with 26×26 input
- **Status**: ⚠️ Hangs during simulation (module needs fixes)

#### `tb_system_simple.v`
Tests complete pipeline (LineBuffer → Conv → ReLU) with real MNIST image
- **Status**: ⚠️ Compiles but hangs (needs debugging)

---

### 3.4 Generated Weight Files

#### `conv_weights.vh`, `conv_bias.vh`
- **Format**: Verilog parameter arrays
- **Content**: 8-bit signed integers (hex format)
- **Conv weights**: 36 values (4 filters × 3×3)
- **Conv bias**: 4 values

#### `fc_weights.vh`, `fc_bias.vh`
- **FC weights**: 6,760 values (10 classes × 676 features)
- **FC bias**: 10 values

**Generated by**: `quantize_weights.py`

---

## 4. Hardware-Software Integration Flow

### Phase 1: Software Reference (Python)
```
1. train_mnist_cnn.py
   ↓  Trains CNN
   ↓  Saves model
   ├─→ mnist_cnn_model.pth (float weights)
   └─→ model_info.json (metadata)

2. quantize_weights.py
   ↓  Loads model
   ↓  Quantizes to Q4.4
   ├─→ conv_weights.vh (Verilog)
   ├─→ conv_bias.vh
   ├─→ fc_weights.vh
   └─→ fc_bias.vh

3. generate_integration_test.py
   ↓  Generates test vectors
   ├─→ input_image.hex/mem
   └─→ expected_conv_filter0.txt
```

### Phase 2: Hardware Implementation (Verilog)
```
1. Load generated weight files
   conv_weights.vh → Conv units
   fc_weights.vh → Dense layer

2. Compile RTL modules
   iverilog → Compile
   vvp → Simulate

3. Run testbenches
   tb_line_buffer → Verify window generation
   tb_conv_unit → Verify arithmetic
   tb_system_simple → Verify pipeline
```

### Phase 3: Verification Loop
```
1. Run inference in Python
   → Get expected outputs

2. Run simulation in Verilog
   → Get actual outputs

3. Compare results
   → Verify bit-exact match (after quantization)

4. Debug discrepancies
   → Fix hardware bugs
   → Iterate
```

### Phase 4: FPGA Deployment (Future)
```
1. Synthesize RTL
   → Xilinx Vivado / Intel Quartus

2. Place & Route
   → Optimize timing & resources

3. Generate bitstream
   → Program FPGA

4. Test on actual hardware
   → Real-time inference
```

---

## 5. Module Architecture

### 5.1 Bit-Width Progression

```
Input Pixels: 8-bit unsigned (0-255)
    ↓
3×3 Window: 9× 8-bit values
    ↓
Conv Multiply: 9× (8×8 = 16-bit products)
    ↓
Conv Sum: 20-bit accumulator
    ↓
ReLU: 20-bit (clamp negatives to 0)
    ↓
Pool: 20-bit (max of 4 values)
    ↓
Dense MAC: 32-bit accumulator
    ↓
Output: 10× 32-bit scores
```

### 5.2 Parallelism

| Module | Parallelism | Notes |
|--------|-------------|-------|
| Line Buffer | 1 window/cycle | Sequential scan |
| Conv Units | 4 filters | Parallel processing |
| ReLU | 4 channels | Combinational |
| Max Pool | Serial | 4 separate instances |
| Dense Layer | 10 accumulators | Parallel MAC |

### 5.3 Memory Requirements

| Component | Size | Type |
|-----------|------|------|
| Line buffers | ~1 KB | Distributed RAM |
| Conv weights | 36 × 8-bit = 36 bytes | ROM/registers |
| FC weights | 6,760 × 8-bit ≈ 6.6 KB | Block RAM |
| Feature buffer | 676 × 20-bit ≈ 1.7 KB | Distributed RAM |
| **Total** | **~9.4 KB** | Mixed |

---

## 6. Testing Strategy

### 6.1 Unit Tests (Verified ✅)

| Module | Test Type | Status |
|--------|-----------|--------|
| ReLU | Combinational logic | ✅ Implicit |
| Line Buffer | Window generation | ✅ PASS (676 windows) |
| Conv Unit | Arithmetic | ✅ PASS (exact results) |

### 6.2 Integration Tests (Partial ⚠️)

| Test | Components | Status |
|------|------------|--------|
| Max Pool | Standalone | ⚠️ Hangs |
| System Simple | Line+Conv+ReLU | ⚠️ Hangs |
| Full System | All modules | ⏳ Not attempted |

### 6.3 Verification Approach

1. **Golden Reference**: PyTorch model (97.39% accuracy)
2. **Quantized Reference**: Python with int8 arithmetic
3. **Hardware Simulation**: Verilog testbenches
4. **Comparison**: Bit-exact matching after quantization

---

## 7. Results & Performance

### 7.1 Software Results

| Metric | Value |
|--------|-------|
| Train Accuracy | 97.97% (epoch 10) |
| Test Accuracy | **97.39%** |
| Model Size | 6,810 parameters |
| Quantization Error (Conv) | 0.018 |
| Quantization Error (FC) | 0.016 |

### 7.2 Hardware Verification

| Module | Test | Result |
|--------|------|--------|
| Line Buffer | Window count | ✅ 676/676 |
| Line Buffer | Window values | ✅ Correct |
| Conv Unit | Identity kernel | ✅ 100/100 |
| Conv Unit | Uniform weights | ✅ 95/95 |

### 7.3 Estimated FPGA Resources (Artix-7)

| Resource | Usage | % of XC7A35T |
|----------|-------|--------------|
| Slice LUTs | ~8,000 | 38% |
| Slice Registers | ~5,000 | 12% |
| DSP48E1 (Multipliers) | 36-45 | 40% |
| Block RAM (36Kb) | 6 | 12% |
| **Feasibility** | ✅ | Fits easily |

### 7.4 Timing Estimate

| Metric | Value @ 100 MHz |
|--------|-----------------|
| Latency per image | ~1,500 cycles |
| Time per image | 15 μs |
| **Throughput** | **66,666 images/sec** |
| Power (estimated) | ~200-500 mW |

---

## 8. Future Improvements

### 8.1 Immediate Fixes Needed

1. **Max Pool Module** ⚠️
   - Debug state machine hang
   - Simplify logic or rewrite
   - Add comprehensive testbench

2. **Dense Layer** ⚠️
   - Implement proper weight ROM access
   - Add Block RAM controllers
   - Optimize MAC parallelism

3. **System Integration** ⚠️
   - Debug pipeline stalls
   - Add proper handshaking between modules
   - Implement backpressure handling

4. **Testbenches** ⚠️
   - Fix file path issues in $readmemh
   - Add more comprehensive test cases
   - Implement Python-Verilog co-simulation

### 8.2 Performance Optimizations
1. **Pipelining**
   - Add pipeline registers between stages
   - Overlap conv/pool/dense operations
   - Increase throughput to 1 image/~500 cycles

2. **Parallelization**
   - Process multiple filters in parallel
   - Batch multiple images
   - Target: 100,000+ images/sec

3. **Weight Compression**
   - Prune small weights (~20% reduction possible)
   - Huffman encoding for storage
   - Reduce memory footprint

4. **Mixed Precision**
   - Conv layer: Keep 8-bit
   - Dense layer: Use 4-bit weights
   - Minimal accuracy loss, 50% memory savings

### 8.3 Architecture Enhancements

1. **Deeper Network**
   - Add 2nd convolutional layer
   - More filters (8 or 16)
   - Target: >98% accuracy

2. **Batch Normalization**
   - Add BN layers for better training
   - Fused with convolution for efficiency

3. **Larger Datasets**
   - Scale to Fashion-MNIST
   - CIFAR-10 (32×32 color images)

### 8.4 System-Level Improvements

1. **AXI Interface**
   - Add AXI4-Stream for external memory
   - Enable integration with Zynq SoC
   - DMA for high-speed data transfer

2. **FPGA Board Integration**
   - Target: Zybo Z7, Arty A7, or Basys 3
   - Camera input (OV7670)
   - HDMI output for visualization

3. **Software Stack**
   - Linux driver for model loading
   - Python API for inference
   - Real-time demo application

### 8.5 Additional Features

1. **Dynamic Reconfiguration**
   - Load different models at runtime
   - Switch between tasks (digits, letters, objects)

2. **Power Management**
   - Clock gating for unused modules
   - Voltage/frequency scaling
   - Target: <100 mW for inference

3. **Security**
   - Model encryption
   - Secure boot
   - Side-channel attack resistance

---

## 9. How to Use This Project

### 9.1 Prerequisites
```bash
# Software
- Python 3.7+
- PyTorch, torchvision, numpy
- Icarus Verilog (iverilog)
- GTKWave (optional, for waveform viewing)

# Hardware (for FPGA deployment)
- Xilinx Vivado or Intel Quartus
- FPGA board (Artix-7 or similar)
```

### 9.2 Quick Start

**Step 1: Train the model**
```bash
cd python
python train_mnist_cnn.py
# Output: mnist_cnn_model.pth (97.39% accuracy)
```

**Step 2: Quantize weights**
```bash
python quantize_weights.py
# Outputs: conv_weights.vh, fc_weights.vh, etc.
```

**Step 3: Run hardware tests**
```bash
cd ../hardware
make test_line_buffer  # Test window generation
make test_conv_unit    # Test convolution
make test_all          # Run all working tests
```

**Step 4: Generate test data**
```bash
cd ../python
python generate_integration_test.py
# Outputs: integration test data
```

**Step 5: (Future) Synthesize for FPGA**
```bash
# Open Vivado/Quartus
# Add all .v files
# Set cnn_top.v as top module
# Synthesize & implement
# Generate bitstream
# Program FPGA
```

---

## 10. Lessons Learned

### 10.1 Design Insights

1. **Start Simple**: Focus on working modules before complex integration
2. **Test Early**: Unit tests caught bugs before they propagated
3. **Quantization Matters**: Q4.4 format worked well with minimal accuracy loss
4. **Pipeline Carefully**: Proper handshaking is critical
5. **Memory is Expensive**: Weight storage dominates resource usage

### 10.2 Common Pitfalls

1. ❌ **Array slicing** in Verilog generate blocks (Icarus limitations)
2. ❌ **Non-blocking vs blocking** assignments (timing bugs)
3. ❌ **`$readmemh` file paths** (relative paths tricky in testbenches)
4. ❌ **Window valid timing** (off-by-one errors in counters)
5. ❌ **State machine hangs** (incomplete case statements)

### 10.3 What Worked Well

1. ✅ **Modular design**: Each module independently testable
2. ✅ **Python reference**: Golden model for verification
3. ✅ **Makefile automation**: Easy to rebuild and test
4. ✅ **Quantization script**: Seamless float→int conversion
5. ✅ **Documentation**: Clear architecture from day 1

---

## 11. Conclusion

This project demonstrates a complete hardware-software co-design flow for deploying neural networks on FPGAs:

**✅ Achievements**:
- Trained high-accuracy CNN (97.39%)
- Implemented and verified key hardware modules
- Created comprehensive test infrastructure
- Documented entire design flow

**⚠️ Current Status**:
- Core modules (line buffer, conv) fully functional
- Integration needs debugging (max pool, system test)
- Ready for synthesis with fixes

**🚀 Next Steps**:
1. Fix max_pool and dense_layer bugs
2. Complete end-to-end system test
3. Synthesize and deploy on FPGA
4. Optimize for performance and power

This project provides a solid foundation for building FPGA-based inference accelerators and can be extended to more complex networks and applications.

---

**Project Status**: 🟡 Beta - Core functionality working, integration in progress

**Estimated Completion**: 90% (needs debugging of integration modules)

**Suitable for**: Learning, research, prototyping FPGA-based ML accelerators

---

*Last Updated: February 10, 2026*
*Contributors: Project CNN1*
