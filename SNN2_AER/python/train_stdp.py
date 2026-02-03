#!/usr/bin/env python3
"""Train STDP network on 2x2 pattern recognition (L-shape, T-shape, Cross)"""

import numpy as np
import matplotlib.pyplot as plt
from stdp_network import STDP_Network
import json
from pathlib import Path


# Define 2x2 patterns
PATTERNS = {
    'L-shape': np.array([[1, 0],
                         [1, 1]]),
    
    'T-shape': np.array([[1, 1],
                         [0, 1]]),
    
    'Cross':   np.array([[0, 1],
                         [1, 1]])
}

PATTERN_LABELS = {'L-shape': 0, 'T-shape': 1, 'Cross': 2}


def add_noise(pattern: np.ndarray, noise_prob: float = 0.05) -> np.ndarray:
    """
    Add noise to pattern by randomly flipping pixels
    
    Args:
        pattern: 2x2 pattern
        noise_prob: Probability of flipping each pixel
        
    Returns:
        Noisy pattern
    """
    noisy = pattern.copy()
    noise_mask = np.random.random(pattern.shape) < noise_prob
    noisy[noise_mask] = 1 - noisy[noise_mask]
    return noisy


def train_network(n_epochs: int = 150, noise_prob: float = 0.05,
                 pattern_duration: float = 250.0, visualize: bool = True):
    """
    Train STDP network on pattern recognition task
    
    Args:
        n_epochs: Number of training epochs (presentations of all patterns)
        noise_prob: Probability of pixel flip noise
        pattern_duration: Duration to present each pattern (ms)
        visualize: Generate training visualizations
    """
    print("\n" + "=" * 80)
    print("TRAINING STDP NETWORK FOR 2×2 PATTERN RECOGNITION")
    print("=" * 80)
    
    # Create network
    net = STDP_Network(n_input=4, n_hidden=8, n_output=3, 
                      dt=1.0, stdp_enabled=True)
    
    # Training setup
    pattern_names = list(PATTERNS.keys())
    n_patterns = len(pattern_names)
    
    print(f"\nTraining Parameters:")
    print(f"  Epochs: {n_epochs}")
    print(f"  Patterns: {n_patterns} ({', '.join(pattern_names)})")
    print(f"  Pattern duration: {pattern_duration} ms")
    print(f"  Noise probability: {noise_prob * 100}%")
    print(f"  Total presentations: {n_epochs * n_patterns}")
    print("=" * 80 + "\n")
    
    # Track training metrics
    accuracy_history = []
    weight_history_ih = []
    weight_history_ho = []
    confusion_matrix = np.zeros((n_patterns, n_patterns))
    
    # Training loop
    for epoch in range(n_epochs):
        # Shuffle patterns
        pattern_order = np.random.permutation(n_patterns)
        
        epoch_correct = 0
        
        for idx in pattern_order:
            pattern_name = pattern_names[idx]
            pattern = PATTERNS[pattern_name].flatten()
            true_label = PATTERN_LABELS[pattern_name]
            
            # Add noise
            if noise_prob > 0:
                pattern_2d = add_noise(pattern.reshape(2, 2), noise_prob)
                pattern = pattern_2d.flatten()
            
            # Reset neurons for new pattern
            net.reset()
            
            # Simulate pattern presentation
            hidden_spikes, output_spikes = net.simulate_pattern(
                pattern, duration=pattern_duration, label=true_label
            )
            
            # Determine network's prediction
            predicted_label = net.get_winner(output_spikes)
            
            # Update confusion matrix
            confusion_matrix[true_label, predicted_label] += 1
            
            # Check if correct
            if predicted_label == true_label:
                epoch_correct += 1
                
        # Record weights
        net.record_weights()
        weight_history_ih.append(net.get_weights_matrix('input_hidden').copy())
        weight_history_ho.append(net.get_weights_matrix('hidden_output').copy())
        
        # Calculate accuracy
        accuracy = epoch_correct / n_patterns
        accuracy_history.append(accuracy)
        
        # Progress report every 10 epochs
        if (epoch + 1) % 10 == 0 or epoch == 0:
            print(f"Epoch {epoch+1:3d}/{n_epochs}: Accuracy = {accuracy*100:5.1f}% "
                  f"({epoch_correct}/{n_patterns} correct)")
                  
    print("\n" + "=" * 80)
    print("TRAINING COMPLETE!")
    print("=" * 80)
    
    # Final evaluation
    print(f"\nFinal Accuracy: {accuracy_history[-1]*100:.1f}%")
    print(f"Average Accuracy (last 20 epochs): {np.mean(accuracy_history[-20:])*100:.1f}%")
    
    # Normalize confusion matrix
    confusion_matrix_norm = confusion_matrix / confusion_matrix.sum(axis=1, keepdims=True)
    
    print("\nConfusion Matrix:")
    print("         " + "  ".join([f"{name[:5]:>5}" for name in pattern_names]))
    for i, name in enumerate(pattern_names):
        row_str = f"{name[:8]:8} "
        row_str += "  ".join([f"{confusion_matrix_norm[i,j]:5.2f}" for j in range(n_patterns)])
        print(row_str)
        
    # Save trained weights
    save_weights(net, accuracy_history, weight_history_ih, weight_history_ho)
    
    # Visualizations
    if visualize:
        visualize_training(accuracy_history, weight_history_ih, weight_history_ho,
                          confusion_matrix_norm, pattern_names)
        
    return net, accuracy_history


def save_weights(net: STDP_Network, accuracy_history: list,
                weight_history_ih: list, weight_history_ho: list):
    """Save trained weights to file"""
    
    weights_dir = Path(__file__).parent.parent / "weights"
    weights_dir.mkdir(exist_ok=True)
    
    # Get final weights
    W_ih = net.get_weights_matrix('input_hidden')
    W_ho = net.get_weights_matrix('hidden_output')
    
    # Quantize for hardware (0-15 scale)
    W_ih_quantized = np.round(W_ih * 15).astype(int)
    W_ho_quantized = np.round(W_ho * 15).astype(int)
    
    # Save as JSON
    weights_data = {
        'network_architecture': {
            'n_input': net.n_input,
            'n_hidden': net.n_hidden,
            'n_output': net.n_output
        },
        'weights_input_hidden': W_ih.tolist(),
        'weights_hidden_output': W_ho.tolist(),
        'weights_input_hidden_quantized': W_ih_quantized.tolist(),
        'weights_hidden_output_quantized': W_ho_quantized.tolist(),
        'final_accuracy': accuracy_history[-1],
        'patterns': {name: pattern.tolist() for name, pattern in PATTERNS.items()}
    }
    
    weights_file = weights_dir / "trained_weights.json"
    with open(weights_file, 'w') as f:
        json.dump(weights_data, f, indent=2)
        
    print(f"\n✓ Weights saved to: {weights_file}")
    
    # Also save as NumPy arrays
    np.savez(weights_dir / "trained_weights.npz",
             W_ih=W_ih, W_ho=W_ho,
             W_ih_quantized=W_ih_quantized,
             W_ho_quantized=W_ho_quantized,
             accuracy_history=accuracy_history)
    
    print(f"✓ NumPy weights saved to: {weights_dir / 'trained_weights.npz'}")


def visualize_training(accuracy_history, weight_history_ih, weight_history_ho,
                      confusion_matrix, pattern_names):
    """Create training visualizations"""
    
    fig = plt.figure(figsize=(16, 10))
    
    # 1. Accuracy over time
    ax1 = plt.subplot(2, 3, 1)
    ax1.plot(accuracy_history, linewidth=2)
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.set_title('Training Accuracy Over Time')
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim([0, 1.05])
    
    # 2. Final weight matrix (Input → Hidden)
    ax2 = plt.subplot(2, 3, 2)
    W_ih_final = weight_history_ih[-1]
    im2 = ax2.imshow(W_ih_final.T, cmap='viridis', aspect='auto')
    ax2.set_xlabel('Input Neuron')
    ax2.set_ylabel('Hidden Neuron')
    ax2.set_title('Final Weights: Input → Hidden')
    plt.colorbar(im2, ax=ax2)
    
    # 3. Final weight matrix (Hidden → Output)
    ax3 = plt.subplot(2, 3, 3)
    W_ho_final = weight_history_ho[-1]
    im3 = ax3.imshow(W_ho_final.T, cmap='viridis', aspect='auto')
    ax3.set_xlabel('Hidden Neuron')
    ax3.set_ylabel('Output Neuron')
    ax3.set_title('Final Weights: Hidden → Output')
    ax3.set_yticks(range(len(pattern_names)))
    ax3.set_yticklabels(pattern_names)
    plt.colorbar(im3, ax=ax3)
    
    # 4. Weight evolution (sample synapse)
    ax4 = plt.subplot(2, 3, 4)
    # Track a few representative synapses
    for i in range(min(4, len(weight_history_ih[0].flatten()))):
        weights = [w.flatten()[i] for w in weight_history_ih]
        ax4.plot(weights, label=f'Synapse {i}', alpha=0.7)
    ax4.set_xlabel('Epoch')
    ax4.set_ylabel('Weight')
    ax4.set_title('Weight Evolution (Input→Hidden, sample)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # 5. Confusion Matrix
    ax5 = plt.subplot(2, 3, 5)
    im5 = ax5.imshow(confusion_matrix, cmap='Blues', aspect='auto', vmin=0, vmax=1)
    ax5.set_xlabel('Predicted')
    ax5.set_ylabel('True')
    ax5.set_title('Confusion Matrix (Normalized)')
    ax5.set_xticks(range(len(pattern_names)))
    ax5.set_yticks(range(len(pattern_names)))
    ax5.set_xticklabels(pattern_names, rotation=45)
    ax5.set_yticklabels(pattern_names)
    
    # Add text annotations
    for i in range(len(pattern_names)):
        for j in range(len(pattern_names)):
            text = ax5.text(j, i, f'{confusion_matrix[i, j]:.2f}',
                          ha="center", va="center", color="black" if confusion_matrix[i,j] < 0.5 else "white")
    plt.colorbar(im5, ax=ax5)
    
    # 6. Pattern examples
    ax6 = plt.subplot(2, 3, 6)
    pattern_viz = np.zeros((2, 3*2 + 2))  # 3 patterns with spacing
    for idx, (name, pattern) in enumerate(PATTERNS.items()):
        col_start = idx * 3
        pattern_viz[:, col_start:col_start+2] = pattern
    ax6.imshow(pattern_viz, cmap='binary', aspect='auto')
    ax6.set_title('Training Patterns')
    ax6.set_yticks([])
    ax6.set_xticks([0.5, 3.5, 6.5])
    ax6.set_xticklabels(pattern_names)
    ax6.grid(False)
    
    plt.tight_layout()
    
    # Save figure
    fig_path = Path(__file__).parent.parent / "weights" / "training_results.png"
    plt.savefig(fig_path, dpi=150, bbox_inches='tight')
    print(f"✓ Training visualization saved to: {fig_path}")
    
    plt.show()


def test_trained_network(net: STDP_Network, n_tests: int = 20):
    """Test trained network with clean and noisy patterns"""
    
    print("\n" + "=" * 80)
    print("TESTING TRAINED NETWORK")
    print("=" * 80)
    
    pattern_names = list(PATTERNS.keys())
    
    # Test clean patterns (NO TEACHER SIGNAL)
    print("\nTest 1: Clean patterns (inference mode)")
    print("-" * 40)
    for name, pattern in PATTERNS.items():
        net.reset()
        # Turn off STDP for testing
        net.stdp_enabled = False
        hidden_spikes, output_spikes = net.simulate_pattern(pattern.flatten(), duration=200.0, label=None)
        net.stdp_enabled = True
        
        predicted = net.get_winner(output_spikes)
        true_label = PATTERN_LABELS[name]
        
        spike_counts = [len(spikes) for spikes in output_spikes]
        correct = "✓" if predicted == true_label else "✗"
        print(f"{name:10} → Predicted: {pattern_names[predicted]:10} (spikes: {spike_counts}) [{correct}]")
        
    # Test noisy patterns
    print("\nTest 2: Noisy patterns (5% noise, inference mode)")
    print("-" * 40)
    noise_results = {name: {'correct': 0, 'total': 0} for name in pattern_names}
    
    for _ in range(n_tests):
        for name, pattern in PATTERNS.items():
            noisy_pattern = add_noise(pattern, noise_prob=0.05)
            net.reset()
            net.stdp_enabled = False
            hidden_spikes, output_spikes = net.simulate_pattern(noisy_pattern.flatten(), duration=200.0, label=None)
            net.stdp_enabled = True
            
            predicted = net.get_winner(output_spikes)
            true_label = PATTERN_LABELS[name]
            
            noise_results[name]['total'] += 1
            if predicted == true_label:
                noise_results[name]['correct'] += 1
                
    for name in pattern_names:
        accuracy = noise_results[name]['correct'] / noise_results[name]['total'] * 100
        print(f"{name:10} → Accuracy: {accuracy:5.1f}% ({noise_results[name]['correct']}/{noise_results[name]['total']})")
        
    print("=" * 80 + "\n")


def main():
    """Main training pipeline"""
    
    # Train network
    net, accuracy_history = train_network(
        n_epochs=150,
        noise_prob=0.05,
        pattern_duration=250.0,
        visualize=True
    )
    
    # Test trained network
    test_trained_network(net, n_tests=20)
    
    print("\n✓ Training complete! Check the weights/ directory for results.")
    print("Next step: Implement AER encoding and Verilog deployment.\n")


if __name__ == "__main__":
    main()
