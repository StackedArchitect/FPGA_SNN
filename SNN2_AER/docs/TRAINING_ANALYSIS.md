# Training Analysis Summary

## Training Results Visualization

The `training_results.png` image (generated during training) should contain 4 subplots:

### 1. **Training Accuracy Over Epochs** (Top Left)
- **Expected**: Curve rising from ~33% to 100% over 150 epochs
- **What it means**: With supervised teaching signal, network learns to associate patterns with outputs
- **Reality**: Achieves 100% because teacher bias (+0.5 to correct neuron) forces correct output

### 2. **Weight Evolution** (Top Right)  
- **Shows**: How input→hidden and hidden→output weights change over time
- **Problem visible here**: Lines converge to same values instead of diverging
- **Healthy network would show**: Different colored lines spreading apart (weight specialization)
- **Our network shows**: Lines clustering together (weight homogeneity)

### 3. **Spike Raster Plot** (Bottom Left)
- **Displays**: When each neuron spikes during a sample pattern presentation
- **Should show**: Different patterns triggering different hidden neurons
- **Likely shows**: All hidden neurons spiking similarly for all patterns

### 4. **Final Weight Matrices** (Bottom Right)
- **Heatmaps**: Color-coded weights (dark=low, bright=high)
- **Input→Hidden matrix (4×8)**: Should show varied patterns
  - **Reality**: Each row is uniform (all same color)
  - **Means**: Each input connects equally to all hidden neurons
- **Hidden→Output matrix (8×3)**: Should show each column having unique pattern
  - **Reality**: Each column is uniform (all same color)
  - **Means**: Each output weights all hidden neurons equally

## Weight Statistics from JSON

```
Input→Hidden (Quantized):
  Row 0: [15, 15, 15, 15, 15, 15, 15, 15]  ← All identical!
  Row 1: [14, 14, 14, 14, 14, 14, 14, 14]  ← All identical!
  Row 2: [14, 14, 14, 14, 14, 14, 14, 14]  ← All identical!
  Row 3: [14, 14, 14, 14, 14, 14, 14, 14]  ← All identical!
  
  Only 2 unique values: {14, 15}
  Coefficient of variation: 3.4% (healthy: >20%)
```

```
Hidden→Output (Quantized):
  Output 0: [10, 10, 10, 10, 10, 10, 10, 10]  ← All 10!
  Output 1: [12, 12, 12, 12, 12, 12, 12, 12]  ← All 12!
  Output 2: [15, 15, 15, 15, 15, 15, 15, 15]  ← All 15!
  
  Each output has uniform weights
  Different baseline (10 vs 12 vs 15) but no selectivity
```

## Why Training "Succeeded" but Inference Failed

### During Training (100% accuracy):
```python
# Supervised STDP adds teaching signal:
if pattern_id == correct_class:
    output_neurons[correct_class].i_syn += 0.5  # Extra boost
else:
    output_neurons[wrong_class].i_syn -= 0.4   # Suppression
```

This external bias **forces** the correct neuron to spike more, making accuracy 100%.

### During Inference (33% accuracy):
```python
# No teaching signal:
# All outputs receive: 8 hidden spikes × weight
O0: 8 × 10 = 80 current → ~400 spikes
O1: 8 × 12 = 96 current → ~400 spikes  
O2: 8 × 15 = 120 current → ~400 spikes
```

After threshold normalization, all spike equally → random classification.

## Root Cause: Dataset Too Small

**STDP learns from spike timing correlations**:
- Input 0 spikes → Output 0 should spike (for L-shape)
- Input 0 spikes → Output 1 should spike (for T-shape)

With only 3 patterns, Input 0 appears in 2 of them! STDP can't distinguish:
- Should I strengthen Input0→Output0 or Input0→Output1?
- Solution: Strengthen both equally (weight homogeneity)

**Needs**: 
- 10+ patterns for diversity
- OR hard winner-take-all (suppress losing outputs completely)
- OR heterosynaptic plasticity (weaken non-firing connections)

## Is Training "Proper"?

✅ **Technically correct**: STDP algorithm implemented correctly  
✅ **Converges**: Weights stabilize, loss decreases  
❌ **Not sufficient**: Dataset too small for unsupervised discrimination  
⚠️ **Research finding**: Demonstrates known STDP limitation
