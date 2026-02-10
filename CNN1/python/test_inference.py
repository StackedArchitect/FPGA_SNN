"""
Test Inference Script and Testbench Data Generator
- Run inference on single MNIST images
- Export images to hex format for Verilog testbench
- Compare floating-point vs quantized inference
"""

import torch
import torch.nn.functional as F
import numpy as np
from torchvision import datasets, transforms
from train_mnist_cnn import SimpleMNISTCNN
import os


def load_model(model_path='../data/mnist_cnn_model.pth'):
    """Load trained model"""
    model = SimpleMNISTCNN()
    model.load_state_dict(torch.load(model_path, map_location='cpu'))
    model.eval()
    return model


def quantize_value(value, scale=16):
    """Quantize float to int8 with given scale (Q4.4 format)"""
    quantized = int(round(value * scale))
    # Clip to int8 range
    quantized = max(-128, min(127, quantized))
    return quantized


def inference_float(model, image):
    """Run inference with floating-point weights"""
    with torch.no_grad():
        image = image.unsqueeze(0)  # Add batch dimension
        output = model(image)
        probabilities = F.softmax(output, dim=1)
        prediction = output.argmax(dim=1).item()
        confidence = probabilities[0][prediction].item()
    return prediction, confidence, output[0].numpy()


def inference_quantized(model, image, scale=16):
    """Run inference with quantized weights (simulated)"""
    # Quantize weights
    model_q = SimpleMNISTCNN()
    model_q.load_state_dict(model.state_dict())
    
    with torch.no_grad():
        # Quantize conv weights
        conv_w = model_q.conv1.weight.data
        conv_w_q = torch.round(conv_w * scale) / scale
        model_q.conv1.weight.data = conv_w_q
        
        conv_b = model_q.conv1.bias.data
        conv_b_q = torch.round(conv_b * scale) / scale
        model_q.conv1.bias.data = conv_b_q
        
        # Quantize FC weights
        fc_w = model_q.fc.weight.data
        fc_w_q = torch.round(fc_w * scale) / scale
        model_q.fc.weight.data = fc_w_q
        
        fc_b = model_q.fc.bias.data
        fc_b_q = torch.round(fc_b * scale) / scale
        model_q.fc.bias.data = fc_b_q
        
        # Run inference
        image = image.unsqueeze(0)
        output = model_q(image)
        probabilities = F.softmax(output, dim=1)
        prediction = output.argmax(dim=1).item()
        confidence = probabilities[0][prediction].item()
    
    return prediction, confidence, output[0].numpy()


def save_image_hex(image, filename, label=None):
    """Save image in hex format for Verilog testbench"""
    # Denormalize image back to 0-255 range
    # MNIST normalization: (x - 0.1307) / 0.3081
    image_denorm = image * 0.3081 + 0.1307
    image_denorm = torch.clamp(image_denorm * 255, 0, 255)
    image_uint8 = image_denorm.byte().numpy().flatten()
    
    with open(filename, 'w') as f:
        f.write(f"// MNIST test image\n")
        if label is not None:
            f.write(f"// True label: {label}\n")
        f.write(f"// Size: 28x28 = 784 pixels\n")
        f.write(f"// Format: 8-bit unsigned hex values\n\n")
        
        # Write pixels in rows of 28
        for i in range(28):
            row = image_uint8[i*28:(i+1)*28]
            hex_row = ' '.join([f"{val:02X}" for val in row])
            f.write(f"{hex_row}\n")
    
    print(f"✓ Saved image to {filename}")
    
    # Also save as text (decimal) for easier reading
    txt_filename = filename.replace('.hex', '.txt')
    with open(txt_filename, 'w') as f:
        f.write(f"MNIST test image - Label: {label}\n")
        f.write("="*56 + "\n")
        for i in range(28):
            row = image_uint8[i*28:(i+1)*28]
            dec_row = ' '.join([f"{val:3d}" for val in row])
            f.write(f"{dec_row}\n")
    
    return image_uint8


def visualize_ascii(image):
    """Visualize image as ASCII art"""
    # Denormalize
    image_denorm = image * 0.3081 + 0.1307
    image_denorm = torch.clamp(image_denorm * 255, 0, 255).numpy()
    
    ascii_chars = ' .:-=+*#%@'
    
    print("\nASCII Visualization:")
    print("=" * 28)
    for i in range(28):
        row = ""
        for j in range(28):
            val = int(image_denorm[0, i, j])
            idx = min(int(val / 25.6), 9)
            row += ascii_chars[idx]
        print(row)
    print("=" * 28)


def test_single_image(model, dataset, index=0, save_hex=True):
    """Test inference on a single image"""
    image, label = dataset[index]
    
    print(f"\n{'='*60}")
    print(f"Testing Image #{index}")
    print(f"{'='*60}")
    print(f"True Label: {label}")
    
    # Visualize
    visualize_ascii(image)
    
    # Float inference
    pred_float, conf_float, scores_float = inference_float(model, image)
    print(f"\nFloating-Point Inference:")
    print(f"  Prediction: {pred_float}")
    print(f"  Confidence: {conf_float*100:.2f}%")
    print(f"  Match: {'✓' if pred_float == label else '✗'}")
    
    # Quantized inference
    pred_quant, conf_quant, scores_quant = inference_quantized(model, image)
    print(f"\nQuantized (Q4.4) Inference:")
    print(f"  Prediction: {pred_quant}")
    print(f"  Confidence: {conf_quant*100:.2f}%")
    print(f"  Match: {'✓' if pred_quant == label else '✗'}")
    
    # Compare scores
    print(f"\nClass Scores Comparison:")
    print(f"  Class | Float    | Quantized | Diff")
    print(f"  " + "-"*40)
    for i in range(10):
        diff = abs(scores_float[i] - scores_quant[i])
        indicator = "  <--" if i == label else ""
        print(f"    {i}   | {scores_float[i]:7.3f}  | {scores_quant[i]:7.3f}   | {diff:.3f}{indicator}")
    
    # Save for testbench
    if save_hex:
        os.makedirs('../data/test_images', exist_ok=True)
        hex_file = f'../data/test_images/mnist_{index}_label{label}.hex'
        save_image_hex(image[0], hex_file, label)
        
        # Save expected output
        output_file = f'../data/test_images/mnist_{index}_label{label}_expected.txt'
        with open(output_file, 'w') as f:
            f.write(f"True Label: {label}\n")
            f.write(f"Float Prediction: {pred_float}\n")
            f.write(f"Quantized Prediction: {pred_quant}\n\n")
            f.write("Quantized Class Scores:\n")
            for i in range(10):
                f.write(f"  Class {i}: {scores_quant[i]:.6f}\n")
        
        print(f"\n✓ Test data saved for Verilog testbench")
    
    return pred_float, pred_quant, label


def batch_export_test_images(model, dataset, num_images=10):
    """Export multiple test images for comprehensive testing"""
    print(f"\n{'='*60}")
    print(f"Exporting {num_images} Test Images")
    print(f"{'='*60}\n")
    
    results = {
        'float_correct': 0,
        'quant_correct': 0,
        'both_correct': 0,
        'total': num_images
    }
    
    for i in range(num_images):
        pred_float, pred_quant, label = test_single_image(model, dataset, i, save_hex=True)
        
        if pred_float == label:
            results['float_correct'] += 1
        if pred_quant == label:
            results['quant_correct'] += 1
        if pred_float == label and pred_quant == label:
            results['both_correct'] += 1
    
    print(f"\n{'='*60}")
    print(f"Batch Export Summary")
    print(f"{'='*60}")
    print(f"Total images: {results['total']}")
    print(f"Float correct: {results['float_correct']} ({results['float_correct']/results['total']*100:.1f}%)")
    print(f"Quant correct: {results['quant_correct']} ({results['quant_correct']/results['total']*100:.1f}%)")
    print(f"Both correct: {results['both_correct']} ({results['both_correct']/results['total']*100:.1f}%)")
    
    return results


if __name__ == '__main__':
    print("\n" + "="*60)
    print("MNIST CNN Test Inference & Testbench Data Generator")
    print("="*60)
    
    # Load model
    model = load_model('../data/mnist_cnn_model.pth')
    print("✓ Model loaded")
    
    # Load test dataset
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_dataset = datasets.MNIST(root='../data', train=False, download=False, transform=transform)
    print(f"✓ Test dataset loaded ({len(test_dataset)} images)")
    
    # Test a single image first
    test_single_image(model, test_dataset, index=0, save_hex=True)
    
    # Ask if user wants to export more
    print("\n" + "="*60)
    print("Export more test images? (Enter number, or 0 to skip)")
    try:
        num = int(input("Number of images to export (0-10000): "))
        if num > 0:
            batch_export_test_images(model, test_dataset, min(num, len(test_dataset)))
    except:
        print("Skipping batch export")
    
    print("\n✓ Test inference complete!")
    print("→ Use generated .hex files in Verilog testbenches\n")
