// LIF neuron with leak, threshold, and bias support

`timescale 1ns/1ps

module lif_neuron_stdp #(
    parameter THRESHOLD = 10,
    parameter LEAK = 1,
    parameter POTENTIAL_WIDTH = 8,
    parameter BIAS = 0
) (
    input  wire clk,
    input  wire rst_n,
    input  wire signed [POTENTIAL_WIDTH:0] input_current,
    input  wire signed [3:0] bias_signal,
    output reg spike_out,
    output reg [POTENTIAL_WIDTH-1:0] membrane_potential
);

    reg signed [POTENTIAL_WIDTH:0] potential_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_potential <= 0;
            spike_out <= 0;
        end else begin
            // Calculate next potential
            potential_next = membrane_potential + input_current + bias_signal - LEAK;
            
            // Clamp to zero (no negative potentials)
            if (potential_next < 0) begin
                potential_next = 0;
            end
            
            // Check for spike
            if (membrane_potential >= THRESHOLD) begin
                spike_out <= 1;
                membrane_potential <= 0;  // Reset after spike
            end else begin
                spike_out <= 0;
                membrane_potential <= potential_next[POTENTIAL_WIDTH-1:0];
            end
        end
    end

endmodule
