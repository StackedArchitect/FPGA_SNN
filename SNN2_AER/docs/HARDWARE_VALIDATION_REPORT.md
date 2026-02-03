# SNN2_AER Hardware Validation Report

## Summary

Successfully deployed STDP-trained SNN to hardware and validated all components. Hardware functions correctly, but learned weights lack discriminative power for pattern recognition.

## Hardware Validation Results

### ✅ Confirmed Working Components

1. **AER Pixel Encoder**
   - Generates spike trains at 5-cycle period for active pixels
   - 10-cycle period for inactive pixels (background activity)
   - All 4 channels synchronized properly
   - AER address encoding functional

2. **LIF Neurons**
   - Membrane potential integration: V[t+1] = V[t] + I - leak
   - Threshold-based spiking at threshold=20
   - Reset to 0 after spike
   - Bias signal support for supervised inference

3. **3-Layer Network Architecture**
   - 4 inputs → 8 hidden → 3 outputs
   - 56 synaptic connections (32 input→hidden, 24 hidden→output)
   - Spike propagation through all layers functional
   - Weight parameters correctly included from training

4. **Spike Statistics**
   - Hidden neurons: Spiking reliably every 5 cycles
   - Output neurons: 399 spikes per 2000-cycle test (consistent across all 3)
   - No timing or accumulation errors detected

### ❌ Classification Performance

```
Test Results: 4/12 PASSED (33.3%)
```

**Root Cause**: All three output neurons spike identically for every pattern

- L-shape: O0=399, O1=399, O2=399 → Winner: O0 (default tie-breaker)
- T-shape: O0=399, O1=399, O2=399 → Winner: O0
- Cross: O0=399, O1=399, O2=399 → Winner: O0

### Weight Analysis

**Input → Hidden weights (trained):**

- Range: 14-15 (quantized 4-bit)
- Mean: 14.50
- Std: 0.50
- **Issue**: Nearly uniform, no feature selectivity

**Hidden → Output weights (trained):**

- O0: All weights ≈10
- O1: All weights ≈12
- O2: All weights ≈15
- **Issue**: Different baseline but identical within each neuron

**Diagnostic Calculation**:

- For ANY pattern with 3 active pixels:
  - Hidden layer gets ~43-44 current (3 pixels × 14-15 weights)
  - All 8 hidden neurons spike identically
  - Each output gets 8 × weight = 80/96/120 for O0/O1/O2
  - After threshold normalization, all spike at same rate

## STDP Learning Challenge

This hardware validation confirms the findings from Python training:

### Training Phase (with teaching signal)

- ✅ 100% accuracy with supervised bias (+0.5/-0.4 modulation)
- ✅ Weights converge to stable values
- ✅ Loss decreases over 150 epochs

### Inference Phase (without teaching signal)

- ❌ 33% accuracy (random chance for 3 classes)
- ❌ Weights too uniform to discriminate patterns
- ❌ Output neurons have no selectivity

### Biological Insight

This behavior matches known research findings:

1. **Teacher Signal Dependency**: STDP alone struggles with multi-class tasks
2. **Weight Homogeneity**: Small datasets (3 patterns) don't provide enough diversity
3. **Lateral Competition**: Our inhibition was too weak to enforce winner-take-all

## Recommendations

### Option A: Manual Weight Design (RECOMMENDED for demonstration)

Create hand-crafted weights that encode:

- Hidden neurons as feature detectors (corner, edge, center pixel patterns)
- Output neurons tuned to specific pattern combinations
- Guarantees working classification for project showcase

### Option B: Retrain with Stronger Constraints

- Implement hard winner-take-all (disable all losers during STDP)
- Use heterosynaptic plasticity (punish inactive synapses more)
- Increase weight diversity via regularization
- Would require significant Python code changes

### Option C: Hybrid Approach

- Use STDP-trained weights for input→hidden (feature extraction)
- Design output→hidden weights manually (classification logic)
- Demonstrates both learning and practical deployment

## Key Learnings for SNN2 vs SNN1

| Aspect      | SNN1 (XOR)                    | SNN2_AER (Pattern Recognition)   |
| ----------- | ----------------------------- | -------------------------------- |
| Learning    | Supervised (manual weights)   | STDP (unsupervised attempt)      |
| Challenge   | 2-input binary function       | 4-input 3-class patterns         |
| Success     | 100% (4/4 patterns)           | 33% (hardware), 100% (with bias) |
| Insight     | Direct encoding works         | STDP needs more data/constraints |
| Hardware    | Ternary weights, single layer | AER encoding, 3 layers           |
| Scalability | Limited to Boolean logic      | Extensible to larger patterns    |

## Conclusion

**Hardware Implementation: SUCCESS** ✅  
All neuromorphic components function as designed. The SNN correctly:

- Encodes spatial patterns as temporal spike trains (AER)
- Propagates spikes through multi-layer architecture
- Integrates synaptic currents and generates output spikes
- Supports configurable bias for supervised inference

**STDP Learning: PARTIAL** ⚠️  
Training converges but lacks discriminative power:

- Achieves 100% accuracy WITH teaching signal
- Degrades to 33% (random) WITHOUT teaching signal
- Valuable research finding on STDP limitations

**Next Steps**:

1. Document current results as successful hardware validation
2. Create manual weight set for working demo (1-2 hours)
3. Generate comparison table: STDP vs Manual vs Supervised
4. Write final project summary with research insights

## Files Generated

- `snn_core_pattern_recognition.v` - 3-layer SNN with 56 synapses
- `tb_snn_pattern_recognition.v` - Comprehensive testbench (12 test cases)
- `weight_parameters.vh` - STDP-trained quantized weights
- `aer_pixel_encoder.v` - Address-Event Representation encoder
- `lif_neuron_stdp.v` - LIF neuron with bias support
- `snn_pattern_recognition.vcd` - Waveform data for analysis
- `diagnose_hardware.py` - Weight analysis diagnostic tool

## Waveform Evidence

Simulation shows perfect synchronization:

```
Cycle 6: Spikes=[1101] Current=44 Pot=0
Cycle 7: pot=43 (accumulation)
Cycle 8: pot=0, Spike=1 (threshold crossed)
Cycle 11-13: Repeat...
```

All neurons behave identically → Equal spike counts → No classification.
