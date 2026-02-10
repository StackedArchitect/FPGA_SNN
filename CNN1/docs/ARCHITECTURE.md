# CNN Hardware Architecture Documentation

## System Overview

Hardware accelerator for MNIST digit classification implementing a simplified CNN.

### Pipeline Architecture

```
Input            Line Buffer       Conv Layer        ReLU         Max Pool       Dense Layer      Output
(28x28)     ->   (3x3 window)  ->  (4 filters)  ->  (4 ch)  ->  (2x2, s=2) ->  (676->10)    -> (10 scores)
784 pixels       26x26 windows     26x26x4         26x26x4      13x13x4=676    10 classes      Prediction
```

## Module Specifications

### 1. Line Buffer (`line_buffer.v`)

**Purpose:** Generate 3×3 sliding windows from streaming pixel input

**Parameters:**

- `IMG_WIDTH`: 28 (MNIST image width)
- `DATA_WIDTH`: 8 (pixel bit width)

**Operation:**

- Buffers 2 complete rows (56 pixels)
- Creates valid 3×3 windows starting from pixel index (2×28 + 2) = 58
- Outputs 26×26 = 676 valid windows (no padding)

**Timing:**

- Latency: 58 cycles before first valid window
- Throughput: 1 window per cycle after initial latency
- Total windows: 676 for complete 28×28 image

**Resource Usage:**

- Row buffers: 2 × 28 × 8 = 448 bits
- Shift register: 3 × 8 = 24 bits

---

### 2. Convolution Unit (`conv_unit.v`)

**Purpose:** Compute 3×3 convolution with learnable kernel

**Parameters:**

- `DATA_WIDTH`: 8 (input pixel width)
- `WEIGHT_WIDTH`: 8 (quantized weight width)
- `ACC_WIDTH`: 20 (accumulator width)

**Operation:**

```
output = Σ(window[i] × weight[i]) + bias, i = 0..8
```

**Architecture:**

- 9 parallel multipliers (8×8 → 16-bit products)
- 4-level adder tree for summation
- Final bias addition
- Registered output (1 cycle latency)

**Resource Usage (per unit):**

- Multipliers: 9 × (8×8)
- Adders: 8 (tree structure)
- Registers: ~20 bits output

**Instances:** 4 (one per filter) in top module

---

### 3. ReLU Activation (`relu.v`)

**Purpose:** Apply rectified linear activation

**Operation:**

```verilog
output = (input < 0) ? 0 : input
```

**Implementation:** Pure combinational logic (checks MSB sign bit)

**Latency:** 0 cycles (combinational)

**Resource Usage:** Minimal (multiplexer logic)

---

### 4. Max Pool (`max_pool.v`)

**Purpose:** 2×2 max pooling with stride 2

**Parameters:**

- `DATA_WIDTH`: 20
- `INPUT_WIDTH`: 26 (after conv)
- `INPUT_HEIGHT`: 26

**Operation:**

- Collects 2×2 non-overlapping blocks
- Outputs maximum value in each block
- Reduces 26×26 → 13×13 (stride 2)

**Architecture:**

- State machine (IDLE → COLLECT → OUTPUT)
- Row buffer for one complete row
- Comparator tree for max finding

**Timing:**

- Processes 4 pixels to output 1 max value
- Total outputs: 13×13 = 169 per filter

**Resource Usage:**

- Row buffer: 26 × 20 = 520 bits
- State machine + control logic

---

### 5. Dense Layer (`dense_layer.v`)

**Purpose:** Fully connected classification layer

**Parameters:**

- `INPUT_SIZE`: 676 (13×13×4 flattened features)
- `OUTPUT_SIZE`: 10 (digit classes)
- `DATA_WIDTH`: 20
- `WEIGHT_WIDTH`: 8
- `ACC_WIDTH`: 32

**Operation:**

```
class_score[j] = Σ(feature[i] × weight[j][i]) + bias[j]
for j = 0..9, i = 0..675
```

**Architecture:**

- Serial processing: one feature at a time
- 10 parallel accumulators (one per class)
- Total MAC operations: 676 × 10 = 6,760

**Timing:**

- ~676 cycles to accumulate all inputs
- Outputs 10 class scores when done

**Resource Usage:**

- Accumulators: 10 × 32 = 320 bits
- Weight ROM: 6,760 × 8 bits = ~6.6 KB
- Bias ROM: 10 × 8 bits = 10 bytes

---

### 6. CNN Top (`cnn_top.v`)

**Purpose:** Integrate all modules into complete pipeline

**Data Flow:**

1. **Input Stage**: Stream 784 pixels (28×28)
2. **Conv Stage**: 4 parallel conv units process 676 windows each
3. **Activation**: ReLU applied to all 26×26×4 outputs
4. **Pooling**: Reduce to 13×13×4 = 676 features
5. **Classification**: FC layer produces 10 class scores
6. **Output**: Argmax to find predicted digit

**Control Signals:**

- `start`: Begin processing new image
- `pixel_valid`: Valid pixel on input
- `done`: Classification complete
- `predicted_class`: Final prediction (0-9)

**Total Latency:**

- Input buffering: ~60 cycles
- Conv+Pool: ~700 cycles
- Dense: ~700 cycles
- **Total: ~1500 cycles** (~15 μs @ 100 MHz)

---

## Memory Organization

### Quantization Format

- **Format**: Q4.4 (4 integer bits, 4 fractional bits)
- **Range**: [-8.0, 7.9375]
- **Scale Factor**: 16 (2^4)

### Weight Storage

#### Convolutional Weights

- **Shape**: [4, 1, 3, 3] = 36 weights
- **Storage**: `conv_weights.vh` (36 × 8-bit)
- **Organization**: Flat array, indexed as `filter_id × 9 + weight_idx`

#### Convolutional Bias

- **Shape**: [4]
- **Storage**: `conv_bias.vh` (4 × 8-bit)

#### FC Weights

- **Shape**: [10, 676] = 6,760 weights
- **Storage**: `fc_weights.vh` (6,760 × 8-bit ≈ 6.6 KB)
- **Organization**: Row-major, `class_id × 676 + feature_idx`

#### FC Bias

- **Shape**: [10]
- **Storage**: `fc_bias.vh` (10 × 8-bit)

---

## Resource Estimation (FPGA)

### Logic Resources

- **Multipliers (DSPs)**:
  - Conv: 4 filters × 9 = 36 multipliers
  - Dense: 1-10 (depends on parallelization)
  - **Total: ~40-50 DSP blocks**

- **Block RAM**:
  - Line buffers: ~500 bits
  - Feature buffer: 676 × 20 = 13,520 bits ≈ 2 KB
  - Weight storage: ~7 KB
  - **Total: ~10 KB BRAM**

- **LUTs/FFs**:
  - Control logic, adders, comparators
  - **Estimate: 5,000-10,000 LUTs**

### Target FPGAs

- **Xilinx**: Artix-7 (small), Zynq-7000
- **Intel**: Cyclone V, MAX 10
- **Lattice**: ECP5

---

## Verification Strategy

### Module-Level Testing

1. **Line Buffer**: Feed known pattern, verify 3×3 windows
2. **Conv Unit**: Test with simple kernels (edge detection, identity)
3. **Max Pool**: Verify max selection on known inputs
4. **Dense Layer**: Test with small matrices, verify MAC

### System-Level Testing

1. Load MNIST test images
2. Compare HW output with Python reference
3. Verify bit-exact accuracy (after quantization)

### Test Images

- Convert test images to hex format
- Stream into testbench
- Compare final class scores
- Verify predicted digit matches

---

## Performance Metrics

### Throughput

- **Per Image**: ~1,500 cycles
- **@ 100 MHz**: ~66,000 images/second
- **@ 50 MHz**: ~33,000 images/second

### Power

- Depends on FPGA family
- Dominated by DSP blocks and memory access

### Accuracy

- **Reference (float)**: 97.39%
- **Quantized (int8)**: Expected ~96-97%
- **Quantization error**: ~0.015 (very low)

---

## Implementation Notes

### Current Limitations

1. **Dense layer** needs refinement for weight access
2. **Max pool** state machine can be optimized
3. **No pipelining** between stages yet
4. **Feature buffer** sizing could be reduced with streaming

### Possible Optimizations

1. **Pipeline stages**: Overlap conv/pool/dense
2. **Weight compression**: Prune small weights
3. **Precision**: Mixed precision (conv: 8-bit, dense: 4-bit)
4. **Batch processing**: Process multiple images in parallel

### Next Steps

1. ✓ Create all module files
2. ⏳ Write testbenches for each module
3. ⏳ Simulate with Icarus Verilog
4. ⏳ Verify against Python reference
5. ⏳ Synthesize for target FPGA
6. ⏳ Optimize timing and resources
