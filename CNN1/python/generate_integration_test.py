"""
System Integration Test - Generate test data for Verilog testbench
Exports a complete MNIST test image for hardware verification
"""

import torch
import numpy as np
from torchvision import datasets, transforms
from train_mnist_cnn import SimpleMNISTCNN
import os


def load_test_image(index=0):
    """Load a single MNIST test image"""
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_dataset = datasets.MNIST(root='../data', train=False, download=False, transform=transform)
    image, label = test_dataset[index]
    return image, label


def denormalize_image(image):
    """Convert normalized image back to 0-255 range"""
    image_denorm = image * 0.3081 + 0.1307
    image_denorm = torch.clamp(image_denorm * 255, 0, 255)
    return image_denorm.byte().numpy()


def generate_verilog_testbench_data(image_index=0):
    """Generate comprehensive test data for Verilog testbench"""
    
    # Load model and image
    model = SimpleMNISTCNN()
    model.load_state_dict(torch.load('../data/mnist_cnn_model.pth', map_location='cpu'))
    model.eval()
    
    image, label = load_test_image(image_index)
    image_uint8 = denormalize_image(image[0])
    
    print(f"\n{'='*60}")
    print(f"Generating Integration Test Data")
    print(f"{'='*60}")
    print(f"Image index: {image_index}")
    print(f"True label: {label}")
    
    # Run inference to get expected outputs
    with torch.no_grad():
        # Get intermediate outputs
        x = image.unsqueeze(0)  # Add batch dimension
        
        # Conv layer output
        conv_out = model.conv1(x)
        print(f"\nConv output shape: {conv_out.shape}")  # Should be [1, 4, 26, 26]
        
        # ReLU
        relu_out = model.relu(conv_out)
        print(f"ReLU output shape: {relu_out.shape}")
        
        # Pool
        pool_out = model.pool(relu_out)
        print(f"Pool output shape: {pool_out.shape}")  # Should be [1, 4, 13, 13]
        
        # Final output
        final_out = model(x)
        prediction = final_out.argmax(dim=1).item()
        print(f"\nPredicted class: {prediction}")
        print(f"Match: {'✓' if prediction == label else '✗'}")
    
    # Export data
    os.makedirs('../data/integration_test', exist_ok=True)
    
    # 1. Input image (hex format)
    image_flat = image_uint8.flatten()
    with open('../data/integration_test/input_image.hex', 'w') as f:
        f.write(f"// MNIST test image #{image_index}\n")
        f.write(f"// True label: {label}\n")
        f.write(f"// Predicted: {prediction}\n\n")
        for i in range(28):
            row_start = i * 28
            row_end = row_start + 28
            hex_row = ' '.join([f"{image_flat[j]:02X}" for j in range(row_start, row_end)])
            f.write(f"{hex_row}\n")
    
    # 2. Expected conv outputs (first filter only, for verification)
    conv_out_np = conv_out[0, 0].numpy()  # Filter 0, shape [26, 26]
    with open('../data/integration_test/expected_conv_filter0.txt', 'w') as f:
        f.write(f"// Expected convolution output for filter 0\n")
        f.write(f"// Shape: 26x26\n\n")
        for i in range(26):
            row_vals = ' '.join([f"{conv_out_np[i,j]:8.3f}" for j in range(26)])
            f.write(f"{row_vals}\n")
    
    # 3. Expected final class scores
    final_scores = final_out[0].numpy()
    with open('../data/integration_test/expected_scores.txt', 'w') as f:
        f.write(f"// Expected class scores\n")
        f.write(f"// True label: {label}\n")
        f.write(f"// Predicted: {prediction}\n\n")
        for i in range(10):
            f.write(f"Class {i}: {final_scores[i]:.6f}\n")
    
    # 4. Create Verilog memory initialization file
    with open('../data/integration_test/input_image.mem', 'w') as f:
        f.write("// Verilog $readmemh compatible format\n")
        for val in image_flat:
            f.write(f"{val:02X}\n")
    
    print(f"\n✓ Integration test data generated:")
    print(f"  - input_image.hex")
    print(f"  - input_image.mem")
    print(f"  - expected_conv_filter0.txt")
    print(f"  - expected_scores.txt")
    print(f"\n{'='*60}\n")
    
    return image_uint8, label, prediction


if __name__ == '__main__':
    # Generate test data for several images
    for idx in [0, 1, 2, 3, 4]:
        generate_verilog_testbench_data(idx)
