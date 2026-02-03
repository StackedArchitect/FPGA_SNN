# SNN2_AER: Self-Learning Character Recognition with AER

## 🎯 Project Overview

**Goal**: Build a spiking neural network that learns to recognize simple 2×2 pixel patterns using STDP (Spike-Timing-Dependent Plasticity) and communicates via AER (Address Event Representation).

**Approach**: Hybrid Python/Hardware
- Train with STDP in Python
- Deploy learned weights to FPGA
- Use AER for efficient neuromorphic communication

---

## 📐 Network Architecture

### Input Layer (4 neurons)
```
Pixel Grid (2×2):        Neuron Mapping:
┌─────┬─────┐            N0(0,0)  N1(0,1)
│ P0  │ P1  │            N2(1,0)  N3(1,1)
├─────┼─────┤
│ P2  │ P3  │
└─────┴─────┘
```

- **4 input neurons** (one per pixel)
- Each neuron encodes pixel intensity as spike rate
- Address: 2-bit (00, 01, 10, 11)

### Hidden Layer (8 neurons)
- **8 feature detector neurons**
- Learn different pattern features via STDP
- Lateral inhibition for competition
- Address: 3-bit (000 to 111)

### Output Layer (3 neurons)
- **3 pattern class neurons** (initially)
- Pattern classes: "L-shape", "T-shape", "Cross"
- Winner-Take-All (WTA) mechanism
- Address: 2-bit (00, 01, 10)

### Total Network
- **Inputs**: 4 pixels
- **Hidden**: 8 neurons  
- **Output**: 3 neurons
- **Total synapses**: 4×8 + 8×3 = 56 connections

---

## 🧠 STDP Learning Rule

### Core Principle
**"Neurons that fire together, wire together"**

### Weight Update Rule
```
If pre-synaptic spike BEFORE post-synaptic spike:
    Δw = A+ × exp(-Δt/τ+)    [Potentiation - strengthen]
    
If pre-synaptic spike AFTER post-synaptic spike:
    Δw = -A- × exp(-Δt/τ-)   [Depression - weaken]
```

### Parameters
- **A+** = 0.01 (potentiation amplitude)
- **A-** = 0.01 (depression amplitude)
- **τ+** = 20 ms (potentiation time constant)
- **τ-** = 20 ms (depression time constant)
- **w_max** = 15 (maximum weight, for hardware)
- **w_min** = 0 (minimum weight)

---

## 📡 AER (Address Event Representation)

### AER Packet Format
```
┌──────────────┬─────────────┬──────────────┐
│ Layer ID (2) │ Neuron ID   │ Timestamp    │
│              │ (variable)  │ (optional)   │
└──────────────┴─────────────┴──────────────┘
```

### Layer Encoding
- `00`: Input layer (4 neurons, 2-bit address)
- `01`: Hidden layer (8 neurons, 3-bit address)
- `10`: Output layer (3 neurons, 2-bit address)

### Event Example
```
Input pixel (0,0) spikes → AER event: [00|00|timestamp]
Hidden neuron 5 fires    → AER event: [01|101|timestamp]
Output neuron 1 fires    → AER event: [10|01|timestamp]
```

---

## 🎨 Pattern Library (Initial)

### Pattern 1: "L-shape"
```
┌───┬───┐
│ 1 │ 0 │  Encoding: [1, 0, 1, 1]
├───┼───┤  Expected output: Neuron 0
│ 1 │ 1 │
└───┴───┘
```

### Pattern 2: "T-shape"
```
┌───┬───┐
│ 1 │ 1 │  Encoding: [1, 1, 0, 1]
├───┼───┤  Expected output: Neuron 1
│ 0 │ 1 │
└───┴───┘
```

### Pattern 3: "Cross"
```
┌───┬───┐
│ 0 │ 1 │  Encoding: [0, 1, 1, 1]
├───┼───┤  Expected output: Neuron 2
│ 1 │ 1 │
└───┴───┘
```

---

## 🔧 Implementation Phases

### Phase 1: Python STDP Training ✓ (Next)
- [ ] Implement LIF neuron model
- [ ] Implement STDP learning rule
- [ ] Create pattern dataset
- [ ] Train network on 3 patterns
- [ ] Visualize weight evolution
- [ ] Extract and quantize weights for hardware

### Phase 2: AER Protocol
- [ ] Design AER packet encoder
- [ ] Implement pixel-to-spike converter
- [ ] Create AER event router
- [ ] Test with pattern sequences

### Phase 3: Verilog Hardware
- [ ] LIF neuron module (with learned weights)
- [ ] AER decoder/encoder
- [ ] SNN core with weight memory
- [ ] Pattern recognition testbench
- [ ] Timing analysis

### Phase 4: Integration & Testing
- [ ] Load Python-trained weights into Verilog
- [ ] Test pattern recognition accuracy
- [ ] Compare Python vs Hardware results
- [ ] Optimize for FPGA resources

---

## 📊 Success Metrics

1. **Learning Convergence**: Weights stabilize after training
2. **Pattern Recognition**: >90% accuracy on trained patterns
3. **Generalization**: Recognize noisy versions of patterns
4. **Hardware Efficiency**: Minimal LUTs/FFs on FPGA
5. **AER Throughput**: Handle real-time spike streams

---

## 🚀 Next Steps

**Immediate**: Start with Python STDP implementation
- Build LIF neuron simulator
- Implement STDP weight update
- Train on 3 patterns
- Visualize learning dynamics

**Questions for you:**

1. **Spike encoding**: Should bright pixel (1) → high spike rate (e.g., 100 Hz)?
2. **Training duration**: How many pattern presentations? (suggest 50-100)
3. **Noise tolerance**: Add noise to training patterns?
4. **Weight precision**: 8-bit signed integers for hardware?

Ready to start building the Python STDP trainer? 🎯
