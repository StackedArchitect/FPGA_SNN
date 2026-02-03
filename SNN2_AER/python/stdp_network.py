#!/usr/bin/env python3
"""STDP-based SNN for 2x2 pattern recognition (4→8→3 architecture)"""

import numpy as np
import matplotlib.pyplot as plt
from typing import List, Tuple, Dict
import json


class LIF_Neuron:
    """Leaky Integrate-and-Fire neuron"""
    
    def __init__(self, neuron_id: int, threshold: float = 1.0, 
                 tau_m: float = 20.0, tau_s: float = 5.0, 
                 v_rest: float = 0.0, v_reset: float = 0.0):
        self.id = neuron_id
        self.threshold = threshold
        self.tau_m = tau_m
        self.tau_s = tau_s
        self.v_rest = v_rest
        self.v_reset = v_reset
        
        self.v = v_rest
        self.i_syn = 0.0
        self.spike_times = []
        self.last_spike_time = -np.inf
        self.v_history = []
        self.spike_history = []
        
    def reset(self):
        """Reset neuron state"""
        self.v = self.v_rest
        self.i_syn = 0.0
        self.spike_times = []
        self.last_spike_time = -np.inf
        self.v_history = []
        self.spike_history = []
        
    def step(self, dt: float, input_current: float) -> bool:
        self.i_syn += input_current
        self.i_syn *= np.exp(-dt / self.tau_s)
        
        dv = (-(self.v - self.v_rest) + self.i_syn) / self.tau_m
        self.v += dv * dt
        
        spiked = False
        if self.v >= self.threshold:
            spiked = True
            self.v = self.v_reset
            self.spike_times.append(len(self.v_history) * dt)
            self.last_spike_time = len(self.v_history) * dt
            
        self.v_history.append(self.v)
        self.spike_history.append(1 if spiked else 0)
        
        return spiked


class STDP_Synapse:
    """Synapse with STDP learning"""
    
    def __init__(self, pre_id: int, post_id: int, 
                 w_init: float = 0.5, w_min: float = 0.0, w_max: float = 1.0,
                 A_plus: float = 0.01, A_minus: float = 0.01,
                 tau_plus: float = 20.0, tau_minus: float = 20.0):
        """
        Initialize STDP synapse
        
        Args:
            pre_id: Pre-synaptic neuron ID
            post_id: Post-synaptic neuron ID
            w_init: Initial weight
            w_min: Minimum weight (hard bound)
            w_max: Maximum weight (hard bound)
            A_plus: Potentiation amplitude
            A_minus: Depression amplitude
            tau_plus: Potentiation time constant (ms)
            tau_minus: Depression time constant (ms)
        """
        self.pre_id = pre_id
        self.post_id = post_id
        self.w = w_init
        self.w_min = w_min
        self.w_max = w_max
        
        # STDP parameters
        self.A_plus = A_plus
        self.A_minus = A_minus
        self.tau_plus = tau_plus
        self.tau_minus = tau_minus
        
        # Weight history
        self.w_history = [w_init]
        
        # Eligibility traces for STDP
        self.pre_trace = 0.0
        self.post_trace = 0.0
        
    def update_traces(self, dt: float, pre_spike: bool, post_spike: bool):
        """
        Update pre and post-synaptic traces
        
        Args:
            dt: Time step (ms)
            pre_spike: Did pre-synaptic neuron spike?
            post_spike: Did post-synaptic neuron spike?
        """
        # Decay traces
        self.pre_trace *= np.exp(-dt / self.tau_plus)
        self.post_trace *= np.exp(-dt / self.tau_minus)
        
        # Add spike contributions
        if pre_spike:
            self.pre_trace += self.A_plus
            # Depression: pre AFTER post
            if self.post_trace > 0:
                self.w -= self.post_trace
                
        if post_spike:
            self.post_trace += self.A_minus
            # Potentiation: pre BEFORE post
            if self.pre_trace > 0:
                self.w += self.pre_trace
                
        # Hard bounds
        self.w = np.clip(self.w, self.w_min, self.w_max)
        
    def apply_stdp(self, pre_spike_time: float, post_spike_time: float):
        """
        Apply STDP weight update based on spike timing
        
        Args:
            pre_spike_time: Time of pre-synaptic spike
            post_spike_time: Time of post-synaptic spike
        """
        delta_t = post_spike_time - pre_spike_time
        
        if delta_t > 0:  # Pre before post -> Potentiation
            dw = self.A_plus * np.exp(-delta_t / self.tau_plus)
            self.w += dw
        elif delta_t < 0:  # Post before pre -> Depression
            dw = -self.A_minus * np.exp(delta_t / self.tau_minus)
            self.w += dw
            
        # Hard bounds
        self.w = np.clip(self.w, self.w_min, self.w_max)
        
    def record_weight(self):
        """Record current weight"""
        self.w_history.append(self.w)


class STDP_Network:
    """
    3-layer SNN with STDP learning for pattern recognition
    """
    
    def __init__(self, n_input: int = 4, n_hidden: int = 8, n_output: int = 3,
                 dt: float = 1.0, stdp_enabled: bool = True):
        """
        Initialize STDP network
        
        Args:
            n_input: Number of input neurons
            n_hidden: Number of hidden neurons
            n_output: Number of output neurons
            dt: Simulation time step (ms)
            stdp_enabled: Enable STDP learning
        """
        self.n_input = n_input
        self.n_hidden = n_hidden
        self.n_output = n_output
        self.dt = dt
        self.stdp_enabled = stdp_enabled
        
        print("=" * 80)
        print(f"Initializing STDP Network: {n_input}→{n_hidden}→{n_output}")
        print("=" * 80)
        
        # Create neurons
        self.input_neurons = [LIF_Neuron(i, threshold=0.8) for i in range(n_input)]
        self.hidden_neurons = [LIF_Neuron(i, threshold=0.9) for i in range(n_hidden)]
        self.output_neurons = [LIF_Neuron(i, threshold=0.8) for i in range(n_output)]
        
        # Create synapses with STDP
        self.synapses_ih = []  # Input -> Hidden
        self.synapses_ho = []  # Hidden -> Output
        
        # Input to Hidden connections
        print(f"Creating {n_input}×{n_hidden} = {n_input*n_hidden} input→hidden synapses...")
        for i in range(n_input):
            for h in range(n_hidden):
                w_init = np.random.uniform(0.2, 0.5)  # Lower initial weights
                synapse = STDP_Synapse(i, h, w_init=w_init, w_max=1.0, 
                                      A_plus=0.015, A_minus=0.015)  # Stronger STDP
                self.synapses_ih.append(synapse)
                
        # Hidden to Output connections
        print(f"Creating {n_hidden}×{n_output} = {n_hidden*n_output} hidden→output synapses...")
        for h in range(n_hidden):
            for o in range(n_output):
                w_init = np.random.uniform(0.1, 0.3)  # Even lower for output layer
                synapse = STDP_Synapse(h, o, w_init=w_init, w_max=1.0,
                                      A_plus=0.02, A_minus=0.02)  # Strong learning
                self.synapses_ho.append(synapse)
                
        print(f"Total synapses: {len(self.synapses_ih) + len(self.synapses_ho)}")
        print("STDP enabled:", "YES ✓" if stdp_enabled else "NO")
        print("=" * 80 + "\n")
        
    def reset(self):
        """Reset all neurons"""
        for neuron in self.input_neurons + self.hidden_neurons + self.output_neurons:
            neuron.reset()
            
    def encode_spike_train(self, pattern: np.ndarray, duration: float, 
                          spike_rate_on: float = 100.0, spike_rate_off: float = 5.0) -> Dict:
        """
        Encode 2x2 pattern as Poisson spike trains
        
        Args:
            pattern: 2x2 array (flattened to 4 values, 0 or 1)
            duration: Encoding duration (ms)
            spike_rate_on: Spike rate for active pixel (Hz)
            spike_rate_off: Spike rate for inactive pixel (Hz)
            
        Returns:
            Dictionary with spike trains for each input neuron
        """
        spike_trains = {}
        n_steps = int(duration / self.dt)
        
        for i, pixel_val in enumerate(pattern):
            rate = spike_rate_on if pixel_val > 0.5 else spike_rate_off
            # Poisson process: probability of spike = rate * dt / 1000
            p_spike = rate * self.dt / 1000.0
            spikes = np.random.random(n_steps) < p_spike
            spike_trains[i] = spikes
            
        return spike_trains
        
    def simulate_pattern(self, pattern: np.ndarray, duration: float = 200.0,
                        label: int = None) -> Tuple[List, List]:
        """
        Simulate network response to a pattern
        
        Args:
            pattern: 2x2 pattern (flattened to 4 values)
            duration: Simulation duration (ms)
            label: Pattern label (for supervised STDP)
            
        Returns:
            (hidden_spikes, output_spikes) - spike times for each layer
        """
        n_steps = int(duration / self.dt)
        
        # Encode pattern as spike trains
        input_spikes = self.encode_spike_train(pattern, duration)
        
        # Storage for spikes
        hidden_spikes = [[] for _ in range(self.n_hidden)]
        output_spikes = [[] for _ in range(self.n_output)]
        
        # Simulate
        for step in range(n_steps):
            t = step * self.dt
            
            # Input layer (driven by pattern)
            input_spike_flags = [input_spikes[i][step] for i in range(self.n_input)]
            
            # Hidden layer
            hidden_spike_flags = []
            for h_idx, h_neuron in enumerate(self.hidden_neurons):
                # Calculate input current from input layer
                i_input = 0.0
                for i_idx in range(self.n_input):
                    if input_spike_flags[i_idx]:
                        synapse = self.synapses_ih[i_idx * self.n_hidden + h_idx]
                        i_input += synapse.w
                        
                # Update neuron
                h_spiked = h_neuron.step(self.dt, i_input)
                hidden_spike_flags.append(h_spiked)
                
                if h_spiked:
                    hidden_spikes[h_idx].append(t)
                    
            # Output layer with lateral inhibition
            output_spike_flags = []
            output_currents = []
            
            # First pass: calculate currents
            for o_idx in range(self.n_output):
                # Calculate input current from hidden layer
                i_input = 0.0
                for h_idx in range(self.n_hidden):
                    if hidden_spike_flags[h_idx]:
                        synapse = self.synapses_ho[h_idx * self.n_output + o_idx]
                        i_input += synapse.w
                output_currents.append(i_input)
            
            # Second pass: update neurons with competition
            for o_idx, o_neuron in enumerate(self.output_neurons):
                i_input = output_currents[o_idx]
                
                # Add lateral inhibition from other output neurons
                for other_idx in range(self.n_output):
                    if other_idx != o_idx and output_currents[other_idx] > 0:
                        i_input -= 0.1 * output_currents[other_idx]
                
                # Add supervised teaching signal if label provided
                if label is not None and self.stdp_enabled:
                    if o_idx == label:
                        # Strong boost for correct neuron
                        i_input += 0.5
                    else:
                        # Strong suppression for incorrect neurons
                        i_input -= 0.4
                        
                # Update neuron
                o_spiked = o_neuron.step(self.dt, i_input)
                output_spike_flags.append(o_spiked)
                
                if o_spiked:
                    output_spikes[o_idx].append(t)
                    
            # Apply STDP weight updates
            if self.stdp_enabled:
                # Update input->hidden synapses (unsupervised)
                for i_idx in range(self.n_input):
                    for h_idx in range(self.n_hidden):
                        synapse = self.synapses_ih[i_idx * self.n_hidden + h_idx]
                        synapse.update_traces(self.dt, input_spike_flags[i_idx], 
                                            hidden_spike_flags[h_idx])
                        
                # Update hidden->output synapses with supervision
                for h_idx in range(self.n_hidden):
                    for o_idx in range(self.n_output):
                        synapse = self.synapses_ho[h_idx * self.n_output + o_idx]
                        
                        if label is not None:
                            # Supervised STDP: modulate learning based on correctness
                            if o_idx == label:
                                # Strengthen connections to correct output
                                synapse.update_traces(self.dt, hidden_spike_flags[h_idx], 
                                                    output_spike_flags[o_idx])
                                # Strong potentiation for correct neuron when hidden fires
                                if hidden_spike_flags[h_idx]:
                                    synapse.w += 0.01  # Reward correct associations strongly
                                if output_spike_flags[o_idx]:
                                    synapse.w += 0.005  # Extra reward for firing
                            else:
                                # Weaken connections to incorrect outputs
                                if hidden_spike_flags[h_idx]:
                                    synapse.w -= 0.015  # Punish wrong associations strongly
                                if output_spike_flags[o_idx]:
                                    synapse.w -= 0.02  # Extra punishment for incorrect firing
                        else:
                            # Regular unsupervised STDP
                            synapse.update_traces(self.dt, hidden_spike_flags[h_idx], 
                                                output_spike_flags[o_idx])
                        
                        # Hard bounds
                        synapse.w = np.clip(synapse.w, synapse.w_min, synapse.w_max)
                        
        return hidden_spikes, output_spikes
        
    def get_winner(self, output_spikes: List) -> int:
        """
        Determine winner neuron (most spikes)
        
        Args:
            output_spikes: List of spike times for each output neuron
            
        Returns:
            Index of winner neuron
        """
        spike_counts = [len(spikes) for spikes in output_spikes]
        return np.argmax(spike_counts)
        
    def get_weights_matrix(self, layer: str = 'input_hidden') -> np.ndarray:
        """
        Get weight matrix for visualization
        
        Args:
            layer: 'input_hidden' or 'hidden_output'
            
        Returns:
            Weight matrix
        """
        if layer == 'input_hidden':
            W = np.zeros((self.n_input, self.n_hidden))
            for i in range(self.n_input):
                for h in range(self.n_hidden):
                    W[i, h] = self.synapses_ih[i * self.n_hidden + h].w
            return W
        elif layer == 'hidden_output':
            W = np.zeros((self.n_hidden, self.n_output))
            for h in range(self.n_hidden):
                for o in range(self.n_output):
                    W[h, o] = self.synapses_ho[h * self.n_output + o].w
            return W
        else:
            raise ValueError(f"Unknown layer: {layer}")
            
    def record_weights(self):
        """Record current weights for all synapses"""
        for synapse in self.synapses_ih + self.synapses_ho:
            synapse.record_weight()


def main():
    """Test STDP network"""
    print("\n" + "=" * 80)
    print("STDP NETWORK TEST")
    print("=" * 80 + "\n")
    
    # Create network
    net = STDP_Network(n_input=4, n_hidden=8, n_output=3, dt=1.0)
    
    # Test pattern
    pattern = np.array([1, 0, 1, 1])  # L-shape
    print(f"Testing with pattern: {pattern.reshape(2, 2)}")
    print()
    
    # Simulate
    hidden_spikes, output_spikes = net.simulate_pattern(pattern, duration=200.0)
    
    # Results
    print("\nResults:")
    print(f"Hidden layer spikes: {[len(s) for s in hidden_spikes]}")
    print(f"Output layer spikes: {[len(s) for s in output_spikes]}")
    print(f"Winner neuron: {net.get_winner(output_spikes)}")
    
    # Show weights
    print("\nInput→Hidden weights:")
    print(net.get_weights_matrix('input_hidden'))
    
    print("\n" + "=" * 80 + "\n")


if __name__ == "__main__":
    main()
