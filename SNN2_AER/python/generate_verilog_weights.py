#!/usr/bin/env python3
"""
Generate Verilog-compatible weight parameters from trained STDP network

This script reads the trained weights and generates Verilog parameter
definitions ready for inclusion in the hardware SNN core.

Author: FPGA SNN Project
Date: February 3, 2026
"""

import numpy as np
import json
from pathlib import Path


def load_weights():
    """Load trained weights from file"""
    weights_file = Path(__file__).parent.parent / "weights" / "trained_weights.json"
    
    with open(weights_file, 'r') as f:
        data = json.load(f)
    
    return data


def generate_verilog_params(data):
    """Generate Verilog parameter definitions"""
    
    W_ih_quant = np.array(data['weights_input_hidden_quantized'])
    W_ho_quant = np.array(data['weights_hidden_output_quantized'])
    
    n_input = data['network_architecture']['n_input']
    n_hidden = data['network_architecture']['n_hidden']
    n_output = data['network_architecture']['n_output']
    
    print("=" * 80)
    print("VERILOG WEIGHT PARAMETERS FOR SNN2_AER")
    print("=" * 80)
    print(f"\nNetwork Architecture: {n_input} → {n_hidden} → {n_output}")
    print(f"Final Training Accuracy: {data['final_accuracy']*100:.1f}%")
    print("\n" + "=" * 80)
    
    # Generate Input → Hidden weights
    print("\n// ===== INPUT → HIDDEN LAYER WEIGHTS =====")
    print(f"// {n_input} input neurons × {n_hidden} hidden neurons = {n_input*n_hidden} synapses")
    print("// Format: WEIGHT_I<input>_H<hidden>")
    print()
    
    for i in range(n_input):
        for h in range(n_hidden):
            weight = W_ih_quant[i, h]
            print(f"parameter WEIGHT_I{i}_H{h} = {weight:2d};  // Input {i} → Hidden {h}")
        if i < n_input - 1:
            print()
    
    # Generate Hidden → Output weights
    print("\n// ===== HIDDEN → OUTPUT LAYER WEIGHTS =====")
    print(f"// {n_hidden} hidden neurons × {n_output} output neurons = {n_hidden*n_output} synapses")
    print("// Format: WEIGHT_H<hidden>_O<output>")
    print()
    
    for h in range(n_hidden):
        for o in range(n_output):
            weight = W_ho_quant[h, o]
            print(f"parameter WEIGHT_H{h}_O{o} = {weight:2d};  // Hidden {h} → Output {o}")
        if h < n_hidden - 1:
            print()
    
    # Generate pattern lookup table
    print("\n// ===== PATTERN DEFINITIONS =====")
    for pattern_name, pattern_data in data['patterns'].items():
        pattern = np.array(pattern_data).flatten()
        label = {'L-shape': 0, 'T-shape': 1, 'Cross': 2}[pattern_name]
        print(f"// {pattern_name:10} (Label {label}): [{pattern[0]}, {pattern[1]}, {pattern[2]}, {pattern[3]}]")
    
    # Generate bias values for each output neuron (optional teaching signal)
    print("\n// ===== CONFIGURABLE BIAS SIGNALS =====")
    print("// These can be used as teaching signals during inference")
    for o in range(n_output):
        pattern_name = list(data['patterns'].keys())[o]
        print(f"parameter BIAS_OUTPUT_{o} = 0;  // Bias for {pattern_name} neuron")
    
    print("\n" + "=" * 80)
    print("Copy the parameters above into your Verilog module!")
    print("=" * 80 + "\n")
    
    # Save to file for easy inclusion
    output_file = Path(__file__).parent.parent / "hardware" / "weight_parameters.vh"
    with open(output_file, 'w') as f:
        f.write("// =============================================================================\n")
        f.write("// STDP-Trained Weights for Pattern Recognition SNN\n")
        f.write("// Auto-generated from trained_weights.json\n")
        f.write("// =============================================================================\n\n")
        
        f.write(f"// Network: {n_input}→{n_hidden}→{n_output}\n")
        f.write(f"// Training Accuracy: {data['final_accuracy']*100:.1f}%\n\n")
        
        f.write("// Input → Hidden Weights\n")
        for i in range(n_input):
            for h in range(n_hidden):
                weight = W_ih_quant[i, h]
                f.write(f"parameter WEIGHT_I{i}_H{h} = {weight:2d};\n")
        
        f.write("\n// Hidden → Output Weights\n")
        for h in range(n_hidden):
            for o in range(n_output):
                weight = W_ho_quant[h, o]
                f.write(f"parameter WEIGHT_H{h}_O{o} = {weight:2d};\n")
        
        f.write("\n// Bias Signals (configurable)\n")
        for o in range(n_output):
            f.write(f"parameter BIAS_OUTPUT_{o} = 0;\n")
    
    print(f"✓ Weights saved to: {output_file}\n")
    
    # Statistics
    print("Weight Statistics:")
    print(f"  Input→Hidden:")
    print(f"    Min: {W_ih_quant.min()}, Max: {W_ih_quant.max()}, Mean: {W_ih_quant.mean():.2f}")
    print(f"  Hidden→Output:")
    print(f"    Min: {W_ho_quant.min()}, Max: {W_ho_quant.max()}, Mean: {W_ho_quant.mean():.2f}")
    print()


def main():
    data = load_weights()
    generate_verilog_params(data)


if __name__ == "__main__":
    main()
