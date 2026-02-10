"""
MNIST CNN Training Script for FPGA Hardware Accelerator
Architecture: 1 Conv Layer + ReLU + MaxPool + Fully Connected
Target: >90% accuracy with hardware-friendly design
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
import numpy as np
import json
import os

class SimpleMNISTCNN(nn.Module):
    """
    Simplified CNN for hardware implementation:
    - Conv2D: 3x3 kernel, 4 filters, stride=1, no padding
    - ReLU activation
    - MaxPool: 2x2, stride=2
    - Flatten
    - Fully Connected: -> 10 classes
    
    Input: 28x28 grayscale image
    After Conv (no padding): 26x26x4
    After MaxPool: 13x13x4 = 676 features
    FC: 676 -> 10
    """
    def __init__(self):
        super(SimpleMNISTCNN, self).__init__()
        
        # Convolutional layer: 1 input channel, 4 output channels, 3x3 kernel
        self.conv1 = nn.Conv2d(in_channels=1, out_channels=4, kernel_size=3, stride=1, padding=0)
        
        # ReLU activation
        self.relu = nn.ReLU()
        
        # Max pooling: 2x2 window, stride 2
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # Fully connected layer: (13*13*4) = 676 -> 10 classes
        self.fc = nn.Linear(13 * 13 * 4, 10)
        
    def forward(self, x):
        # Conv + ReLU: [batch, 1, 28, 28] -> [batch, 4, 26, 26]
        x = self.conv1(x)
        x = self.relu(x)
        
        # MaxPool: [batch, 4, 26, 26] -> [batch, 4, 13, 13]
        x = self.pool(x)
        
        # Flatten: [batch, 4, 13, 13] -> [batch, 676]
        x = x.view(x.size(0), -1)
        
        # FC: [batch, 676] -> [batch, 10]
        x = self.fc(x)
        
        return x


def train_model(epochs=10, batch_size=64, learning_rate=0.001):
    """Train the CNN on MNIST dataset"""
    
    # Set device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # Data preprocessing
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))  # MNIST mean and std
    ])
    
    # Load MNIST dataset
    train_dataset = datasets.MNIST(root='../data', train=True, download=True, transform=transform)
    test_dataset = datasets.MNIST(root='../data', train=False, download=True, transform=transform)
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
    
    # Initialize model
    model = SimpleMNISTCNN().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    
    print(f"\n{'='*60}")
    print(f"Model Architecture:")
    print(f"{'='*60}")
    print(model)
    print(f"{'='*60}\n")
    
    # Count parameters
    total_params = sum(p.numel() for p in model.parameters())
    print(f"Total parameters: {total_params:,}\n")
    
    # Training loop
    print("Starting training...")
    for epoch in range(epochs):
        model.train()
        train_loss = 0
        correct = 0
        total = 0
        
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(device), target.to(device)
            
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
            _, predicted = output.max(1)
            total += target.size(0)
            correct += predicted.eq(target).sum().item()
            
            if batch_idx % 100 == 0:
                print(f'Epoch: {epoch+1}/{epochs} | Batch: {batch_idx}/{len(train_loader)} | '
                      f'Loss: {loss.item():.4f} | Acc: {100.*correct/total:.2f}%')
        
        # Evaluate on test set
        model.eval()
        test_loss = 0
        correct = 0
        total = 0
        
        with torch.no_grad():
            for data, target in test_loader:
                data, target = data.to(device), target.to(device)
                output = model(data)
                test_loss += criterion(output, target).item()
                _, predicted = output.max(1)
                total += target.size(0)
                correct += predicted.eq(target).sum().item()
        
        test_acc = 100. * correct / total
        avg_test_loss = test_loss / len(test_loader)
        
        print(f'\n>>> Epoch {epoch+1} Complete:')
        print(f'    Train Loss: {train_loss/len(train_loader):.4f}')
        print(f'    Test Loss: {avg_test_loss:.4f}')
        print(f'    Test Accuracy: {test_acc:.2f}%\n')
    
    # Final evaluation
    print(f"\n{'='*60}")
    print(f"FINAL TEST ACCURACY: {test_acc:.2f}%")
    print(f"{'='*60}\n")
    
    if test_acc < 90.0:
        print("⚠️  WARNING: Accuracy is below 90%. Consider training longer.")
    else:
        print("✓ Target accuracy (>90%) achieved!")
    
    return model, test_acc


def save_model_info(model, accuracy):
    """Save model and architecture information"""
    
    # Save the full model
    torch.save(model.state_dict(), '../data/mnist_cnn_model.pth')
    print("\n✓ Model saved to ../data/mnist_cnn_model.pth")
    
    # Save model info
    info = {
        'architecture': {
            'conv1': {
                'type': 'Conv2D',
                'in_channels': 1,
                'out_channels': 4,
                'kernel_size': 3,
                'stride': 1,
                'padding': 0
            },
            'activation': 'ReLU',
            'pool': {
                'type': 'MaxPool2D',
                'kernel_size': 2,
                'stride': 2
            },
            'fc': {
                'type': 'Linear',
                'in_features': 676,
                'out_features': 10
            }
        },
        'accuracy': accuracy,
        'input_shape': [1, 28, 28],
        'output_classes': 10
    }
    
    with open('../data/model_info.json', 'w') as f:
        json.dump(info, f, indent=4)
    
    print("✓ Model info saved to ../data/model_info.json")


if __name__ == '__main__':
    print("\n" + "="*60)
    print("MNIST CNN Training for FPGA Hardware Accelerator")
    print("="*60 + "\n")
    
    # Train the model
    model, accuracy = train_model(epochs=10, batch_size=64, learning_rate=0.001)
    
    # Save model and info
    save_model_info(model, accuracy)
    
    print("\n✓ Phase 1 Complete: Reference model trained successfully!")
    print("→ Next step: Run quantize_weights.py to prepare for hardware implementation\n")
