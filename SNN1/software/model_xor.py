#!/usr/bin/env python3
"""
XOR Spiking Neural Network Model
==================================
This script simulates an SNN to solve the XOR problem and derives
the necessary weights for hardware implementation.

Network Architecture:
- 2 Input Encoders (I0, I1)
- 2 Hidden Neurons (H0, H1)
- 1 Output Neuron (O0)

XOR Truth Table:
  I0 | I1 | Output
  ---------------
   0 |  0 |   0
   0 |  1 |   1
   1 |  0 |   1
   1 |  1 |   0

Author: Senior FPGA Engineer
Date: January 28, 2026
"""

# import numpy as np

class LIF_Neuron:
    """Simple Leaky Integrate-and-Fire neuron model"""
    
    def __init__(self, threshold=15, leak=1, name="Neuron"):
        self.threshold = threshold
        self.leak = leak
        self.potential = 0
        self.name = name
        self.spike_history = []
        
    def step(self, input_current, time_step):
        """Simulate one time step"""
        # Add input current
        self.potential += input_current
        
        # Apply leak
        self.potential -= self.leak
        
        # Clamp to zero (no negative potentials)
        if self.potential < 0:
            self.potential = 0
        
        # Check for spike
        spike = 0
        if self.potential >= self.threshold:
            spike = 1
            self.spike_history.append(time_step)
            self.potential = 0  # Reset after spike
            
        return spike
    
    def reset(self):
        """Reset neuron state"""
        self.potential = 0
        self.spike_history = []


class SNN_XOR:
    """SNN Network for XOR computation"""
    
    def __init__(self):
        # Network parameters (tuned for XOR)
        self.threshold = 15
        self.leak = 1
        
        # Create neurons
        self.hidden_0 = LIF_Neuron(self.threshold, self.leak, "Hidden_0")
        self.hidden_1 = LIF_Neuron(self.threshold, self.leak, "Hidden_1")
        self.output = LIF_Neuron(self.threshold, self.leak, "Output")
        
        # Synaptic weights (optimized for XOR)
        # Input to Hidden layer
        self.w_i0_h0 = 20  # Input 0 to Hidden 0 (excitatory)
        self.w_i1_h0 = 20  # Input 1 to Hidden 0 (excitatory)
        self.w_i0_h1 = 20  # Input 0 to Hidden 1 (excitatory)
        self.w_i1_h1 = 20  # Input 1 to Hidden 1 (excitatory)
        
        # Hidden to Output layer
        self.w_h0_o = 15   # Hidden 0 to Output (excitatory)
        self.w_h1_o = 15   # Hidden 1 to Output (excitatory)
        
        # Lateral inhibition (key for XOR)
        self.w_h0_h1 = -25  # Hidden 0 inhibits Hidden 1
        self.w_h1_h0 = -25  # Hidden 1 inhibits Hidden 0
        
        print("=" * 70)
        print("SNN XOR Network Initialized")
        print("=" * 70)
        print(f"Neuron Parameters: Threshold={self.threshold}, Leak={self.leak}")
        print("\nSynaptic Weights:")
        print(f"  Input->Hidden Layer:")
        print(f"    I0->H0: {self.w_i0_h0:+4d}  |  I1->H0: {self.w_i1_h0:+4d}")
        print(f"    I0->H1: {self.w_i0_h1:+4d}  |  I1->H1: {self.w_i1_h1:+4d}")
        print(f"  Hidden->Output Layer:")
        print(f"    H0->O: {self.w_h0_o:+4d}  |  H1->O: {self.w_h1_o:+4d}")
        print(f"  Lateral Inhibition:")
        print(f"    H0->H1: {self.w_h0_h1:+4d}  |  H1->H0: {self.w_h1_h0:+4d}")
        print("=" * 70 + "\n")
    
    def simulate(self, input_0, input_1, time_steps=50):
        """
        Simulate the network for given inputs
        
        Args:
            input_0: Input spike train for input 0
            input_1: Input spike train for input 1
            time_steps: Number of time steps to simulate
        """
        # Reset all neurons
        self.hidden_0.reset()
        self.hidden_1.reset()
        self.output.reset()
        
        output_spikes = []
        
        print(f"Simulating: I0={input_0}, I1={input_1}")
        print("-" * 70)
        
        for t in range(time_steps):
            # Calculate currents for hidden layer
            h0_current = 0
            h1_current = 0
            
            if input_0:
                h0_current += self.w_i0_h0
                h1_current += self.w_i0_h1
            
            if input_1:
                h0_current += self.w_i1_h0
                h1_current += self.w_i1_h1
            
            # Process hidden neurons
            h0_spike = self.hidden_0.step(h0_current, t)
            h1_spike = self.hidden_1.step(h1_current, t)
            
            # Apply lateral inhibition
            if h0_spike:
                self.hidden_1.potential += self.w_h0_h1
                if self.hidden_1.potential < 0:
                    self.hidden_1.potential = 0
                    
            if h1_spike:
                self.hidden_0.potential += self.w_h1_h0
                if self.hidden_0.potential < 0:
                    self.hidden_0.potential = 0
            
            # Calculate current for output neuron
            o_current = 0
            if h0_spike:
                o_current += self.w_h0_o
            if h1_spike:
                o_current += self.w_h1_o
            
            # Process output neuron
            o_spike = self.output.step(o_current, t)
            output_spikes.append(o_spike)
            
            # Display state every 10 steps or when spikes occur
            if t % 10 == 0 or h0_spike or h1_spike or o_spike:
                print(f"t={t:3d} | H0: V={self.hidden_0.potential:3d} S={h0_spike} | "
                      f"H1: V={self.hidden_1.potential:3d} S={h1_spike} | "
                      f"Out: V={self.output.potential:3d} S={o_spike}")
        
        total_output_spikes = sum(output_spikes)
        print(f"\nTotal Output Spikes: {total_output_spikes}")
        print("=" * 70 + "\n")
        
        return total_output_spikes > 0


def main():
    """Test all XOR combinations"""
    
    print("\n" + "=" * 70)
    print(" XOR SPIKING NEURAL NETWORK - WEIGHT CALCULATION")
    print("=" * 70 + "\n")
    
    snn = SNN_XOR()
    
    # Test cases
    test_cases = [
        (0, 0, 0),  # 0 XOR 0 = 0
        (0, 1, 1),  # 0 XOR 1 = 1
        (1, 0, 1),  # 1 XOR 0 = 1
        (1, 1, 0),  # 1 XOR 1 = 0
    ]
    
    results = []
    
    for i0, i1, expected in test_cases:
        print(f"\n{'='*70}")
        print(f"TEST CASE: {i0} XOR {i1} = {expected}")
        print(f"{'='*70}")
        
        output = snn.simulate(i0, i1, time_steps=50)
        result = 1 if output else 0
        
        status = "✓ PASS" if result == expected else "✗ FAIL"
        results.append((i0, i1, expected, result, status))
        
        print(f"Expected: {expected}, Got: {result} [{status}]\n")
    
    # Summary
    print("\n" + "=" * 70)
    print(" SIMULATION SUMMARY")
    print("=" * 70)
    print(f"{'I0':^5} | {'I1':^5} | {'Expected':^10} | {'Got':^5} | {'Status':^10}")
    print("-" * 70)
    
    for i0, i1, expected, result, status in results:
        print(f"{i0:^5} | {i1:^5} | {expected:^10} | {result:^5} | {status:^10}")
    
    print("=" * 70)
    
    # Generate hardware parameters
    print("\n" + "=" * 70)
    print(" HARDWARE PARAMETERS (for Verilog)")
    print("=" * 70)
    print("Copy these values to snn_core.v:")
    print(f"  WEIGHT_I0_H0 = {snn.w_i0_h0};")
    print(f"  WEIGHT_I1_H0 = {snn.w_i1_h0};")
    print(f"  WEIGHT_I0_H1 = {snn.w_i0_h1};")
    print(f"  WEIGHT_I1_H1 = {snn.w_i1_h1};")
    print(f"  WEIGHT_H0_O  = {snn.w_h0_o};")
    print(f"  WEIGHT_H1_O  = {snn.w_h1_o};")
    print(f"  WEIGHT_H0_H1 = {snn.w_h0_h1}; // Inhibitory")
    print(f"  WEIGHT_H1_H0 = {snn.w_h1_h0}; // Inhibitory")
    print(f"  THRESHOLD    = {snn.threshold};")
    print(f"  LEAK         = {snn.leak};")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    main()
