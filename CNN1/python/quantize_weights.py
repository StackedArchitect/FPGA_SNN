"""
Weight Quantization Script for FPGA Implementation
Converts floating-point weights to fixed-point integers
Exports to Verilog-compatible format (.vh files)
"""

import torch
import numpy as np
import json
import os
from train_mnist_cnn import SimpleMNISTCNN


def analyze_weight_distribution(weights, name):
    """Analyze weight statistics to determine optimal quantization"""
    print(f"\n{name} Statistics:")
    print(f"  Shape: {weights.shape}")
    print(f"  Min: {weights.min():.6f}")
    print(f"  Max: {weights.max():.6f}")
    print(f"  Mean: {weights.mean():.6f}")
    print(f"  Std: {weights.std():.6f}")
    return weights.min(), weights.max()


def quantize_to_fixed_point(weights, num_bits=8, num_frac_bits=4):
    """
    Quantize floating-point weights to fixed-point representation
    
    Args:
        weights: numpy array of floating-point weights
        num_bits: total bit width (e.g., 8 for int8, 16 for int16)
        num_frac_bits: number of fractional bits
    
    Returns:
        quantized weights as integers
        scale factor used
    """
    # Calculate scale factor: 2^(num_frac_bits)
    scale = 2 ** num_frac_bits
    
    # Quantize: multiply by scale and round
    quantized = np.round(weights * scale).astype(np.int32)
    
    # Clip to representable range
    max_val = 2 ** (num_bits - 1) - 1  # for signed integers
    min_val = -(2 ** (num_bits - 1))
    
    quantized = np.clip(quantized, min_val, max_val)
    
    # Convert to target bit width
    if num_bits == 8:
        quantized = quantized.astype(np.int8)
    elif num_bits == 16:
        quantized = quantized.astype(np.int16)
    
    return quantized, scale


def save_weights_to_verilog(weights, filename, name, width=8):
    """
    Save quantized weights to Verilog header file (.vh)
    
    Args:
        weights: numpy array of quantized weights
        filename: output .vh filename
        name: parameter name prefix
        width: bit width of each weight
    """
    with open(filename, 'w') as f:
        f.write(f"// Automatically generated weight parameters for {name}\n")
        f.write(f"// Bit width: {width}\n")
        f.write(f"// Generated from quantize_weights.py\n\n")
        
        # Flatten weights for easier access
        flat_weights = weights.flatten()
        
        f.write(f"// Total weights: {len(flat_weights)}\n")
        f.write(f"// Original shape: {weights.shape}\n\n")
        
        # Write as Verilog parameter array
        f.write(f"parameter [{width-1}:0] {name} [0:{len(flat_weights)-1}] = '{{\n")
        
        # Write weights in groups of 8 per line for readability
        for i in range(0, len(flat_weights), 8):
            group = flat_weights[i:i+8]
            # Convert to hex (handle signed integers properly)
            if width == 8:
                hex_values = [f"{int(val) & 0xFF:02X}" for val in group]
            else:  # 16-bit
                hex_values = [f"{int(val) & 0xFFFF:04X}" for val in group]
            
            line = "    " + ", ".join([f"8'h{h}" if width == 8 else f"16'h{h}" for h in hex_values])
            if i + 8 < len(flat_weights):
                line += ","
            f.write(line + "\n")
        
        f.write("};\n\n")


def save_weights_to_text(weights, filename, name):
    """Save weights as readable text file for reference"""
    with open(filename, 'w') as f:
        f.write(f"# {name}\n")
        f.write(f"# Shape: {weights.shape}\n\n")
        
        flat_weights = weights.flatten()
        for i, w in enumerate(flat_weights):
            f.write(f"{w}\n")


def quantize_and_export(model_path='../data/mnist_cnn_model.pth', num_bits=8, num_frac_bits=4):
    """
    Main quantization pipeline
    
    Args:
        model_path: path to trained PyTorch model
        num_bits: bit width for quantization (8 or 16)
        num_frac_bits: number of fractional bits for fixed-point
    """
    print("\n" + "="*60)
    print("Weight Quantization for FPGA Implementation")
    print("="*60)
    
    # Load trained model
    print(f"\nLoading model from {model_path}...")
    model = SimpleMNISTCNN()
    model.load_state_dict(torch.load(model_path, map_location='cpu'))
    model.eval()
    
    print(f"✓ Model loaded successfully")
    print(f"\nQuantization settings:")
    print(f"  Bit width: {num_bits}")
    print(f"  Fractional bits: {num_frac_bits}")
    print(f"  Integer bits: {num_bits - num_frac_bits - 1} (+ 1 sign bit)")
    print(f"  Representable range: [{-(2**(num_bits-num_frac_bits-1)):.2f}, {(2**(num_bits-num_frac_bits-1) - 2**(-num_frac_bits)):.2f}]")
    
    # Create output directory
    os.makedirs('../hardware', exist_ok=True)
    
    quantization_info = {
        'num_bits': num_bits,
        'num_frac_bits': num_frac_bits,
        'scale_factor': 2 ** num_frac_bits,
        'layers': {}
    }
    
    # 1. Quantize Conv Layer weights
    print("\n" + "-"*60)
    print("1. Convolutional Layer Weights")
    print("-"*60)
    
    conv_weights = model.conv1.weight.detach().cpu().numpy()  # Shape: [4, 1, 3, 3]
    conv_bias = model.conv1.bias.detach().cpu().numpy()       # Shape: [4]
    
    analyze_weight_distribution(conv_weights, "Conv Weights")
    analyze_weight_distribution(conv_bias, "Conv Bias")
    
    conv_w_quant, conv_w_scale = quantize_to_fixed_point(conv_weights, num_bits, num_frac_bits)
    conv_b_quant, conv_b_scale = quantize_to_fixed_point(conv_bias, num_bits, num_frac_bits)
    
    print(f"\n✓ Quantized conv weights: {conv_w_quant.shape}, dtype: {conv_w_quant.dtype}")
    print(f"  Quantization error: {np.abs(conv_weights - conv_w_quant/conv_w_scale).mean():.6f}")
    
    # Save Conv weights
    save_weights_to_verilog(conv_w_quant, '../hardware/conv_weights.vh', 'CONV_WEIGHTS', num_bits)
    save_weights_to_verilog(conv_b_quant, '../hardware/conv_bias.vh', 'CONV_BIAS', num_bits)
    save_weights_to_text(conv_w_quant, '../data/conv_weights.txt', 'Conv Weights')
    
    quantization_info['layers']['conv1'] = {
        'weights_shape': list(conv_weights.shape),
        'bias_shape': list(conv_bias.shape),
        'scale': float(conv_w_scale)
    }
    
    # 2. Quantize FC Layer weights
    print("\n" + "-"*60)
    print("2. Fully Connected Layer Weights")
    print("-"*60)
    
    fc_weights = model.fc.weight.detach().cpu().numpy()  # Shape: [10, 676]
    fc_bias = model.fc.bias.detach().cpu().numpy()       # Shape: [10]
    
    analyze_weight_distribution(fc_weights, "FC Weights")
    analyze_weight_distribution(fc_bias, "FC Bias")
    
    fc_w_quant, fc_w_scale = quantize_to_fixed_point(fc_weights, num_bits, num_frac_bits)
    fc_b_quant, fc_b_scale = quantize_to_fixed_point(fc_bias, num_bits, num_frac_bits)
    
    print(f"\n✓ Quantized FC weights: {fc_w_quant.shape}, dtype: {fc_w_quant.dtype}")
    print(f"  Quantization error: {np.abs(fc_weights - fc_w_quant/fc_w_scale).mean():.6f}")
    
    # Save FC weights
    save_weights_to_verilog(fc_w_quant, '../hardware/fc_weights.vh', 'FC_WEIGHTS', num_bits)
    save_weights_to_verilog(fc_b_quant, '../hardware/fc_bias.vh', 'FC_BIAS', num_bits)
    save_weights_to_text(fc_w_quant, '../data/fc_weights.txt', 'FC Weights')
    
    quantization_info['layers']['fc'] = {
        'weights_shape': list(fc_weights.shape),
        'bias_shape': list(fc_bias.shape),
        'scale': float(fc_w_scale)
    }
    
    # Save quantization info
    with open('../data/quantization_info.json', 'w') as f:
        json.dump(quantization_info, f, indent=4)
    
    print("\n" + "="*60)
    print("Quantization Complete!")
    print("="*60)
    print(f"\nGenerated files:")
    print(f"  - ../hardware/conv_weights.vh")
    print(f"  - ../hardware/conv_bias.vh")
    print(f"  - ../hardware/fc_weights.vh")
    print(f"  - ../hardware/fc_bias.vh")
    print(f"  - ../data/quantization_info.json")
    print(f"\n✓ Ready for Verilog implementation!")
    
    return quantization_info


if __name__ == '__main__':
    # Run quantization with 8-bit fixed-point (4 integer bits, 4 fractional bits)
    quantization_info = quantize_and_export(
        model_path='../data/mnist_cnn_model.pth',
        num_bits=8,
        num_frac_bits=4
    )
    
    print("\n→ Next step: Start implementing hardware modules in Verilog\n")
