// =============================================================================
// Module: lif_neuron (Leaky Integrate-and-Fire Neuron)
// Description: Synthesizable LIF neuron for Spiking Neural Networks
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

module lif_neuron #(
    parameter signed WEIGHT = 10,              // Synaptic weight added per spike
    parameter signed THRESHOLD = 15,           // Firing threshold
    parameter signed LEAK = 1,                 // Leak value per cycle
    parameter POTENTIAL_WIDTH = 8              // Bit width for membrane potential
)(
    input  wire clk,                           // Clock signal
    input  wire rst_n,                         // Active low reset
    input  wire input_spike,                   // Incoming spike signal
    output reg  spike_out                      // Output spike (1-cycle pulse)
);

    // Internal membrane potential register (signed to handle inhibitory weights)
    reg signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    
    // Temporary variable for next membrane potential calculation
    reg signed [POTENTIAL_WIDTH:0] next_potential;  // Extra bit to detect overflow
    
    // Sequential logic - Main neuron dynamics
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset condition
            membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
            spike_out <= 1'b0;
        end else begin
            // Calculate next potential value
            next_potential = membrane_potential;
            
            // Integration: Add synaptic weight if input spike received
            if (input_spike) begin
                next_potential = next_potential + WEIGHT;
            end
            
            // Leak: Subtract leak value every cycle
            next_potential = next_potential - LEAK;
            
            // Check if threshold reached (fire condition)
            if (membrane_potential >= THRESHOLD) begin
                // Fire: Generate output spike
                spike_out <= 1'b1;
                // Reset: Membrane potential goes to zero after firing
                membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
            end else begin
                spike_out <= 1'b0;
                // Clamp membrane potential to zero (cannot go negative)
                if (next_potential < 0) begin
                    membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
                end else begin
                    // Update membrane potential
                    membrane_potential <= next_potential[POTENTIAL_WIDTH-1:0];
                end
            end
        end
    end

endmodule
