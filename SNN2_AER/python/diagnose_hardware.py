#!/usr/bin/env python3
"""
Diagnostic script to analyze why hardware neurons don't spike.

Simulates the exact hardware logic to identify issues.
"""

import json
import numpy as np

# Load trained weights
with open('../weights/trained_weights.json', 'r') as f:
    data = json.load(f)

weights_ih = np.array(data['weights_input_hidden_quantized'])
weights_ho = np.array(data['weights_hidden_output_quantized'])

print("=" * 80)
print("Hardware SNN Diagnostic Analysis")
print("=" * 80)

# Hardware parameters from testbench
THRESHOLD_HIDDEN = 20
THRESHOLD_OUTPUT = 15
LEAK = 1

print(f"\nHardware Parameters:")
print(f"  Hidden threshold: {THRESHOLD_HIDDEN}")
print(f"  Output threshold: {THRESHOLD_OUTPUT}")
print(f"  Leak per cycle: {LEAK}")

# Test patterns
patterns = {
    'L-shape': [1, 0, 1, 1],
    'T-shape': [1, 1, 0, 1],
    'Cross': [0, 1, 1, 1]
}

print("\n" + "=" * 80)
print("ANALYSIS: Input → Hidden Layer")
print("=" * 80)

for pattern_name, pattern in patterns.items():
    print(f"\n{pattern_name}: {pattern}")
    
    # Calculate input current to each hidden neuron
    for h in range(8):
        # Sum weights for active inputs
        current = sum(weights_ih[i, h] for i in range(4) if pattern[i] == 1)
        
        # Net current after leak
        net_current = current - LEAK
        
        will_spike = "YES" if current >= THRESHOLD_HIDDEN else "NO"
        
        print(f"  H{h}: Sum={current:2d}, After leak={net_current:2d}, "
              f"Threshold={THRESHOLD_HIDDEN}, Spike={will_spike}")

print("\n" + "=" * 80)
print("PROBLEM DIAGNOSIS")
print("=" * 80)

# Calculate maximum possible current
max_weights_per_row = [weights_ih[i, :].max() for i in range(4)]
max_current_possible = sum(max_weights_per_row)  # All 4 inputs active with max weights

print(f"\nMaximum input current possible: {max_current_possible}")
print(f"Hidden neuron threshold: {THRESHOLD_HIDDEN}")
print(f"Deficit: {THRESHOLD_HIDDEN - max_current_possible}")

if max_current_possible < THRESHOLD_HIDDEN:
    print("\n⚠️  CRITICAL ISSUE: Even with all inputs active at max weights,")
    print("    neurons cannot reach threshold!")
    print("\nPossible solutions:")
    print("  1. Lower hidden threshold (e.g., to 10-15)")
    print("  2. Scale up quantized weights (e.g., multiply by 2)")
    print("  3. Reduce leak rate (e.g., to 0)")
    print("  4. Use weight re-scaling during quantization")

# Analyze weight distribution
print("\n" + "=" * 80)
print("WEIGHT STATISTICS")
print("=" * 80)

print(f"\nInput → Hidden weights:")
print(f"  Min: {weights_ih.min()}")
print(f"  Max: {weights_ih.max()}")
print(f"  Mean: {weights_ih.mean():.2f}")
print(f"  Std: {weights_ih.std():.2f}")
print(f"  Range: {weights_ih.max() - weights_ih.min()}")

print(f"\nHidden → Output weights:")
print(f"  Min: {weights_ho.min()}")
print(f"  Max: {weights_ho.max()}")
print(f"  Mean: {weights_ho.mean():.2f}")
print(f"  Std: {weights_ho.std():.2f}")
print(f"  Range: {weights_ho.max() - weights_ho.min()}")

# Proposed fix: re-scale weights to use full [0,31] range
print("\n" + "=" * 80)
print("PROPOSED FIX: Re-scale to 5-bit weights [0,31]")
print("=" * 80)

# Re-scale to [0,31] instead of [0,15]
weights_ih_rescaled = ((weights_ih / 15.0) * 31).astype(int)
weights_ho_rescaled = ((weights_ho / 15.0) * 31).astype(int)

print(f"\nRe-scaled Input → Hidden weights:")
print(f"  Min: {weights_ih_rescaled.min()}")
print(f"  Max: {weights_ih_rescaled.max()}")
print(f"  Mean: {weights_ih_rescaled.mean():.2f}")

# Test with rescaled weights
print("\n" + "=" * 80)
print("ANALYSIS: Re-scaled Input → Hidden (5-bit)")
print("=" * 80)

for pattern_name, pattern in patterns.items():
    print(f"\n{pattern_name}: {pattern}")
    
    for h in range(8):
        current = sum(weights_ih_rescaled[i, h] for i in range(4) if pattern[i] == 1)
        net_current = current - LEAK
        will_spike = "YES" if current >= THRESHOLD_HIDDEN else "NO"
        
        print(f"  H{h}: Sum={current:2d}, After leak={net_current:2d}, "
              f"Threshold={THRESHOLD_HIDDEN}, Spike={will_spike}")

# Alternative: Lower threshold
print("\n" + "=" * 80)
print("ALTERNATIVE: Lower threshold to 10")
print("=" * 80)

THRESHOLD_HIDDEN_LOW = 10

for pattern_name, pattern in patterns.items():
    print(f"\n{pattern_name}: {pattern}")
    
    for h in range(8):
        current = sum(weights_ih[i, h] for i in range(4) if pattern[i] == 1)
        will_spike = "YES" if current >= THRESHOLD_HIDDEN_LOW else "NO"
        
        print(f"  H{h}: Sum={current:2d}, Threshold={THRESHOLD_HIDDEN_LOW}, Spike={will_spike}")

print("\n" + "=" * 80)
print("RECOMMENDATION")
print("=" * 80)
print("\nBest solution: Use 5-bit weights [0,31] with threshold=20")
print("This maintains resolution while ensuring neurons can spike.")
print("\nGenerate new weight_parameters.vh with 5-bit scaling...")
