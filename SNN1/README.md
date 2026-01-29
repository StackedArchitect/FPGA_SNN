# XOR Spiking Neural Network (SNN) on FPGA

## Project Overview

This project implements an **XOR logic gate using a Spiking Neural Network (SNN)** designed for FPGA implementation. It demonstrates neuromorphic computing principles using Leaky Integrate-and-Fire (LIF) neurons.

### Author

Senior FPGA Engineer  
Date: January 28, 2026

---

## Project Structure

```
SNN1/
├── software/                   # Python simulation and weight calculation
│   ├── model_xor.py           # SNN model for XOR with weight derivation
│   └── quantize_weights.py    # Float-to-integer weight quantization
│
└── hardware/                   # Verilog RTL design
    ├── lif_neuron.v           # Basic LIF neuron module
    ├── spike_encoder.v        # Static input to spike train converter
    ├── snn_core.v             # XOR network topology (2-2-1)
    ├── top_snn.v              # Top-level FPGA wrapper
    ├── tb_lif_neuron.v        # LIF neuron testbench
    └── tb_snn.v               # Complete XOR SNN testbench
```

---

## Network Architecture

### Topology

- **2 Input Encoders**: Convert static switch inputs to spike trains
- **2 Hidden Neurons**: Process input patterns with lateral inhibition
- **1 Output Neuron**: Generates XOR result

### XOR Truth Table

```
I0 | I1 | Output
---|----|-----------
 0 |  0 |   0 (No spikes)
 0 |  1 |   1 (Spikes present)
 1 |  0 |   1 (Spikes present)
 1 |  1 |   0 (Inhibited, no spikes)
```

### Key Mechanism

**Lateral Inhibition**: When both inputs are active, hidden neurons mutually inhibit each other, preventing sustained output firing. This is the critical feature that enables XOR functionality.

---

## Design Parameters

### LIF Neuron Dynamics

```verilog
V_new = V_old + Input_Current - LEAK

if (V_new >= THRESHOLD):
    generate_spike()
    V_new = 0
```

### Tuned Parameters

```
THRESHOLD    = 20  // Membrane potential threshold for firing
LEAK         = 1   // Leak per clock cycle
WEIGHT_INPUT = 12  // Synaptic weight from inputs to hidden layer
WEIGHT_OUTPUT= 25  // Synaptic weight from hidden to output layer
WEIGHT_INHIB = -15 // Inhibitory weight for lateral connections
```

---

## Execution Flow

### Step 1: Python Modeling

```bash
cd software
python3 model_xor.py
```

**Purpose**: Verify network architecture and derive optimal weights

### Step 2: Weight Quantization

```bash
python3 quantize_weights.py
```

**Purpose**: Convert floating-point weights to fixed-point integers for hardware

### Step 3: Verilog Simulation

```bash
cd hardware
iverilog -o snn_sim tb_snn.v top_snn.v snn_core.v spike_encoder.v
vvp snn_sim
```

**Purpose**: Verify RTL behavior for all XOR combinations

### Step 4: Waveform Analysis

```bash
gtkwave snn_xor_waveform.vcd
```

**Purpose**: Visual verification of neuron potentials and spike timing

### Step 5: Synthesis (Future)

- **Tool**: Vivado or Quartus
- **Target**: FPGA board (e.g., Artix-7, Cyclone V)
- **Inputs**: Physical switches
- **Output**: LED indicator

---

## Module Descriptions

### 1. lif_neuron.v - LIF Neuron Cell

**Inputs**: clk, rst_n, input_spike  
**Outputs**: spike_out  
**Function**:

- Implements leaky integrate-and-fire dynamics
- Signed arithmetic for inhibitory weights
- Auto-reset after firing

### 2. spike_encoder.v - Rate Encoder

**Inputs**: clk, rst_n, enable  
**Outputs**: spike_out  
**Function**:

- Converts static logic level (switch ON/OFF) to periodic spikes
- Spike rate determines input strength
- Period configurable via parameter

### 3. snn_core.v - Neural Network Core

**Inputs**: clk, rst_n, spike_in_0, spike_in_1  
**Outputs**: spike_out  
**Function**:

- Instantiates 3 LIF neurons (2 hidden, 1 output)
- Implements synaptic connectivity with weights
- Lateral inhibition for XOR functionality

### 4. top_snn.v - FPGA Top Wrapper

**Inputs**: clk, rst_n, switch_0, switch_1  
**Outputs**: led_out  
**Function**:

- Connects spike encoders to SNN core
- Maps physical I/O to internal logic
- Board-specific instantiation point

---

## Simulation Output

The testbench provides comprehensive debug information:

```
[305000] [SNN_CORE] Input Spikes: I0=0 I1=1
[305000] [NEURON_0] V: 0 -> 19 (current=20)
[315000] [NEURON_0] FIRED! Potential was 19, reset to 0
[325000] [SNN_CORE] *** HIDDEN_0 FIRED! ***
[335000] [NEURON_2] V: 0 -> 29 (current=30)
[345000] [SNN_CORE] ======> OUTPUT SPIKE! <======
```

**Legend**:

- Timestamps in ps (picoseconds)
- NEURON_0/1 = Hidden neurons
- NEURON_2 = Output neuron
- V = Membrane potential

---

## Key Features

✅ **Fully Synthesizable**: No floating-point arithmetic  
✅ **Configurable Parameters**: Easy tuning via Verilog parameters  
✅ **Comprehensive Testbench**: Self-checking with all 4 XOR cases  
✅ **Detailed Monitoring**: Display statements track every state change  
✅ **Waveform Dumping**: VCD output for GTKWave analysis  
✅ **Modular Design**: Reusable neuron and encoder modules

---

## Performance Metrics

- **Clock Frequency**: 100 MHz (10ns period)
- **Spike Encoding Period**: 10 clock cycles
- **Response Latency**: ~30-50 cycles per XOR computation
- **Resource Usage**: ~200 LUTs, 50 FFs (Artix-7 estimate)

---

## Next Steps for FPGA Implementation

1. **Synthesis**:

   ```tcl
   read_verilog hardware/top_snn.v
   read_verilog hardware/snn_core.v
   read_verilog hardware/spike_encoder.v
   synth_design -top top_snn
   ```

2. **Constraints**:
   - Define clock period (10ns for 100MHz)
   - Pin assignments for switches and LED
   - Timing constraints for spike propagation

3. **Bitstream Generation**:

   ```tcl
   place_design
   route_design
   write_bitstream
   ```

4. **Programming**:
   - Flash .bit file to FPGA
   - Test with physical switches
   - Observe LED output

---

## Troubleshooting

### Simulation Issues

- **No output spikes**: Check threshold and weight values
- **Always firing**: Reduce weights or increase threshold
- **Timing violations**: Adjust clock period or pipeline design

### Python Import Errors

- Remove `import numpy` if not installed
- Use pure Python implementations

---

## References

- Leaky Integrate-and-Fire neuron model
- Spiking Neural Networks for neuromorphic computing
- FPGA-based neural network implementations

---

## License

Educational project for FPGA and neuromorphic computing learning.

---

## Contact

For questions or improvements, please raise an issue or submit a pull request.
