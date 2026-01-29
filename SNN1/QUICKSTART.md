# XOR SNN - Quick Start Guide

## Overview

This project implements XOR logic using a Spiking Neural Network (SNN) in Verilog for FPGA deployment.

---

## Project Structure

```
SNN1/
├── README.md                      # Comprehensive documentation
├── SIMULATION_RESULTS.md          # Detailed simulation analysis
├── software/                      # Python modeling
│   ├── model_xor.py              # SNN mathematical model
│   └── quantize_weights.py       # Weight quantization
└── hardware/                      # Verilog RTL design
    ├── lif_neuron.v              # LIF neuron cell
    ├── spike_encoder.v           # Input encoder
    ├── snn_core.v                # XOR network core
    ├── top_snn.v                 # Top-level wrapper
    ├── tb_lif_neuron.v           # Neuron testbench
    └── tb_snn.v                  # XOR testbench
```

---

## Quick Start (3 Steps)

### Step 1: Run Python Model (Optional)

```bash
cd software
python3 model_xor.py
```

**Output**: Calculated weights for XOR network

### Step 2: Run Verilog Simulation

```bash
cd hardware
iverilog -o snn_sim tb_snn.v top_snn.v snn_core.v spike_encoder.v
vvp snn_sim
```

**Output**: Detailed simulation with debug messages

### Step 3: View Waveforms

```bash
gtkwave snn_xor_waveform.vcd &
```

**Signals to observe**:

- `switch_0`, `switch_1` - Inputs
- `hidden_neuron_0.membrane_potential` - Hidden layer 0
- `hidden_neuron_1.membrane_potential` - Hidden layer 1
- `output_neuron.membrane_potential` - Output layer
- `led_out` - Final output

---

## Understanding the Output

### Console Output Explained

```
[355000] [SNN_CORE] Input Spikes: I0=0 I1=1
  └─ Time: 355ns, Input pattern: 0 XOR 1

[355000] [NEURON_0] V: 0 -> 11 (current=12)
  └─ Neuron 0 potential increased from 0 to 11 (received 12, leaked 1)

[765000] [NEURON_0] FIRED! Potential was 31, reset to 0
  └─ Neuron crossed threshold (20), generated spike, reset

[795000] [SNN_CORE] ======> OUTPUT SPIKE! <======
  └─ Final XOR result: Output spike generated
```

### Test Results

- **0 XOR 0 = 0**: ✓ Passing (no output spikes)
- **0 XOR 1 = 1**: Needs tuning (parameter adjustment required)
- **1 XOR 0 = 1**: Needs tuning
- **1 XOR 1 = 0**: Needs tuning (see SIMULATION_RESULTS.md)

---

## Key Parameters (in snn_core.v)

```verilog
THRESHOLD = 20           // Neuron firing threshold
LEAK = 1                 // Potential decay per cycle
WEIGHT_INPUT = 12        // Input → Hidden weight
WEIGHT_OUTPUT = 25       // Hidden → Output weight
WEIGHT_INHIB = -15       // Lateral inhibition weight
SPIKE_PERIOD = 10        // Encoder spike period (cycles)
```

**To tune**: Edit these values in [snn_core.v](hardware/snn_core.v) and re-run simulation.

---

## Simulation Options

### Run with Custom Time

Edit `tb_snn.v` line 25:

```verilog
parameter SIM_TIME = 1000;  // Change to 2000 for longer sim
```

### Adjust Display Verbosity

Comment out debug statements in:

- `snn_core.v` (lines 160-180)
- `lif_neuron_weighted` module (lines 200-210)

---

## Next Steps

### For Working XOR

1. **Option A**: Adjust parameters (see SIMULATION_RESULTS.md, Option A)
2. **Option B**: Reduce spike period to 5 cycles in `top_snn.v`
3. **Option C**: Increase input weights to 16-18

### For FPGA Synthesis

```bash
# In Vivado TCL console:
read_verilog hardware/top_snn.v
read_verilog hardware/snn_core.v
read_verilog hardware/spike_encoder.v
synth_design -top top_snn -part xc7a35ticsg324-1L
```

### For Advanced Features

- Implement refractory period in `lif_neuron_weighted`
- Add STDP learning rules
- Expand to 3+ layer networks
- Try other logic gates (AND, OR, NAND)

---

## Troubleshooting

### Error: "Module not found"

```bash
iverilog -o snn_sim tb_snn.v top_snn.v snn_core.v spike_encoder.v lif_neuron.v
# Add lif_neuron.v if using standalone version
```

### No waveform file generated

Check for `$dumpfile` in testbench (line 73 of tb_snn.v)

### Simulation hangs

Timeout is set to 1000ns. Check `SIM_TIME` parameter.

---

## Resources

- **Full Documentation**: [README.md](README.md)
- **Simulation Analysis**: [SIMULATION_RESULTS.md](SIMULATION_RESULTS.md)
- **LIF Neuron Theory**: https://en.wikipedia.org/wiki/Biological_neuron_model#Leaky_integrate-and-fire
- **SNNs**: https://en.wikipedia.org/wiki/Spiking_neural_network

---

## Contact & Contributing

This is an educational project demonstrating neuromorphic computing on FPGAs.

**Suggestions for improvement:**

1. Fork the project
2. Make changes
3. Test thoroughly
4. Submit pull request

---

**Happy Spiking!** 🧠⚡

---

_Created: January 28, 2026_  
_Last Updated: January 28, 2026_
