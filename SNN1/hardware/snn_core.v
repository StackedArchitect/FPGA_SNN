// =============================================================================
// Module: snn_core_v2
// Description: Improved XOR Spiking Neural Network Core
//              Uses a simpler 2-layer architecture optimized for XOR
// Author: Senior FPGA Engineer
// Date: January 28, 2026
// =============================================================================

module snn_core #(
    // Neuron parameters
    parameter THRESHOLD = 18,      // Optimized threshold
    parameter LEAK = 1,
    parameter POTENTIAL_WIDTH = 8,
    
    // Optimized weights for XOR functionality
    // Strategy: Single inputs fire, both inputs mutually inhibit
    parameter signed WEIGHT_I0_H0 = 15,  // Input 0 to Hidden 0 (increased)
    parameter signed WEIGHT_I1_H0 = 15,  // Input 1 to Hidden 0 (increased) 
    parameter signed WEIGHT_I0_H1 = 15,  // Input 0 to Hidden 1 (increased)
    parameter signed WEIGHT_I1_H1 = 15,  // Input 1 to Hidden 1 (increased)
    
    // Hidden to Output
    parameter signed WEIGHT_H0_O = 22,   // Hidden 0 to Output (balanced)
    parameter signed WEIGHT_H1_O = 22,   // Hidden 1 to Output (balanced)
    
    // Stronger lateral inhibition for both-input case
    parameter signed WEIGHT_H0_H1 = -20, // Hidden 0 inhibits Hidden 1
    parameter signed WEIGHT_H1_H0 = -20, // Hidden 1 inhibits Hidden 0
    
    // Direct output inhibition when both inputs active
    parameter signed WEIGHT_BOTH_INHIB = -60  // Very strong direct inhibition to output
)(
    input  wire clk,              // Clock signal
    input  wire rst_n,            // Active low reset
    input  wire spike_in_0,       // Input spike from encoder 0
    input  wire spike_in_1,       // Input spike from encoder 1
    input  wire switch_0,         // Raw switch state 0
    input  wire switch_1,         // Raw switch state 1
    output wire spike_out         // Output spike
);

    // Hidden layer spike signals
    wire spike_hidden_0;
    wire spike_hidden_1;
    
    // Weighted spike signals for Hidden 0
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i0_h0;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i1_h0;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h1_h0_inhib;
    
    // Weighted spike signals for Hidden 1
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i0_h1;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_i1_h1;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h0_h1_inhib;
    
    // Weighted spike signals for Output
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h0_o;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_h1_o;
    wire signed [POTENTIAL_WIDTH-1:0] weighted_both_inhib;
    
    // Combined input currents
    wire signed [POTENTIAL_WIDTH:0] current_hidden_0;
    wire signed [POTENTIAL_WIDTH:0] current_hidden_1;
    wire signed [POTENTIAL_WIDTH:0] current_output;
    
    // Display network initialization
    initial begin
        $display("========================================================================");
        $display("[SNN_CORE] XOR Network Initialized (Improved Architecture)");
        $display("========================================================================");
        $display("[SNN_CORE] Network Topology: 2 Inputs -> 2 Hidden -> 1 Output");
        $display("[SNN_CORE] Neuron Parameters:");
        $display("[SNN_CORE]   THRESHOLD = %0d", THRESHOLD);
        $display("[SNN_CORE]   LEAK = %0d", LEAK);
        $display("[SNN_CORE]   POTENTIAL_WIDTH = %0d bits", POTENTIAL_WIDTH);
        $display("[SNN_CORE] Synaptic Weights:");
        $display("[SNN_CORE]   Input->Hidden:");
        $display("[SNN_CORE]     I0->H0: %0d  |  I1->H0: %0d", WEIGHT_I0_H0, WEIGHT_I1_H0);
        $display("[SNN_CORE]     I0->H1: %0d  |  I1->H1: %0d", WEIGHT_I0_H1, WEIGHT_I1_H1);
        $display("[SNN_CORE]   Hidden->Output:");
        $display("[SNN_CORE]     H0->O: %0d  |  H1->O: %0d", WEIGHT_H0_O, WEIGHT_H1_O);
        $display("[SNN_CORE]   Lateral Inhibition:");
        $display("[SNN_CORE]     H0->H1: %0d  |  H1->H0: %0d", WEIGHT_H0_H1, WEIGHT_H1_H0);
        $display("[SNN_CORE] XOR Logic:");
        $display("[SNN_CORE]   0,0: No inputs -> Hidden neurons don't fire -> No output");
        $display("[SNN_CORE]   0,1 or 1,0: Single input -> One Hidden fires -> Output fires");
        $display("[SNN_CORE]   1,1: Both inputs -> Mutual inhibition prevents sustained firing");
        $display("========================================================================");
    end
    
    // =========================================================================
    // Weight Application Logic
    // =========================================================================
    
    // Inputs to Hidden 0
    assign weighted_i0_h0 = spike_in_0 ? WEIGHT_I0_H0 : 0;
    assign weighted_i1_h0 = spike_in_1 ? WEIGHT_I1_H0 : 0;
    assign weighted_h1_h0_inhib = spike_hidden_1 ? WEIGHT_H1_H0 : 0;
    assign current_hidden_0 = weighted_i0_h0 + weighted_i1_h0 + weighted_h1_h0_inhib;
    
    // Inputs to Hidden 1
    assign weighted_i0_h1 = spike_in_0 ? WEIGHT_I0_H1 : 0;
    assign weighted_i1_h1 = spike_in_1 ? WEIGHT_I1_H1 : 0;
    assign weighted_h0_h1_inhib = spike_hidden_0 ? WEIGHT_H0_H1 : 0;
    assign current_hidden_1 = weighted_i0_h1 + weighted_i1_h1 + weighted_h0_h1_inhib;
    
    // Inputs to Output
    assign weighted_h0_o = spike_hidden_0 ? WEIGHT_H0_O : 0;
    assign weighted_h1_o = spike_hidden_1 ? WEIGHT_H1_O : 0;
    // Direct inhibition when both switches active (not just both spikes)
    assign weighted_both_inhib = (switch_0 && switch_1) ? WEIGHT_BOTH_INHIB : 0;
    assign current_output = weighted_h0_o + weighted_h1_o + weighted_both_inhib;
    
    // =========================================================================
    // Neuron Instantiations
    // =========================================================================
    
    lif_neuron_weighted #(
        .WEIGHT(0),  // Weight handled externally
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) hidden_neuron_0 (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_hidden_0),
        .spike_out(spike_hidden_0),
        .neuron_id(8'd0)
    );
    
    lif_neuron_weighted #(
        .WEIGHT(0),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) hidden_neuron_1 (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_hidden_1),
        .spike_out(spike_hidden_1),
        .neuron_id(8'd1)
    );
    
    lif_neuron_weighted #(
        .WEIGHT(0),
        .THRESHOLD(THRESHOLD),
        .LEAK(LEAK),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) output_neuron (
        .clk(clk),
        .rst_n(rst_n),
        .input_current(current_output),
        .spike_out(spike_out),
        .neuron_id(8'd2)
    );
    
    // =========================================================================
    // Debug Monitors
    // =========================================================================
    
    // Monitor input spikes
    always @(posedge clk) begin
        if (spike_in_0 || spike_in_1) begin
            $display("[%0t] [SNN_CORE] Input Spikes: I0=%0b I1=%0b", 
                     $time, spike_in_0, spike_in_1);
        end
    end
    
    // Monitor hidden layer activity
    always @(posedge clk) begin
        if (spike_hidden_0) begin
            $display("[%0t] [SNN_CORE] *** HIDDEN_0 FIRED! ***", $time);
        end
        if (spike_hidden_1) begin
            $display("[%0t] [SNN_CORE] *** HIDDEN_1 FIRED! ***", $time);
        end
    end
    
    // Monitor output spikes
    always @(posedge clk) begin
        if (spike_out) begin
            $display("[%0t] [SNN_CORE] ======> OUTPUT SPIKE! <======", $time);
        end
    end

endmodule


// =============================================================================
// Modified LIF Neuron with External Current Input
// =============================================================================

module lif_neuron_weighted #(
    parameter signed WEIGHT = 10,
    parameter signed THRESHOLD = 15,
    parameter signed LEAK = 1,
    parameter POTENTIAL_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [POTENTIAL_WIDTH:0] input_current,  // External current
    output reg  spike_out,
    input  wire [7:0] neuron_id  // For debugging
);

    reg signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    reg signed [POTENTIAL_WIDTH:0] next_potential;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
            spike_out <= 1'b0;
        end else begin
            // Calculate next potential
            next_potential = membrane_potential + input_current - LEAK;
            
            // Check if threshold reached
            if (membrane_potential >= THRESHOLD) begin
                spike_out <= 1'b1;
                membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
                $display("[%0t] [NEURON_%0d] FIRED! Potential was %0d, reset to 0", 
                         $time, neuron_id, membrane_potential);
            end else begin
                spike_out <= 1'b0;
                
                // Clamp to zero
                if (next_potential < 0) begin
                    membrane_potential <= {POTENTIAL_WIDTH{1'b0}};
                    if (input_current != 0) begin
                        $display("[%0t] [NEURON_%0d] Potential clamped: %0d -> 0 (input=%0d)", 
                                 $time, neuron_id, next_potential, input_current);
                    end
                end else begin
                    membrane_potential <= next_potential[POTENTIAL_WIDTH-1:0];
                    if (input_current != 0 || next_potential != membrane_potential) begin
                        $display("[%0t] [NEURON_%0d] V: %0d -> %0d (current=%0d)", 
                                 $time, neuron_id, membrane_potential, next_potential[POTENTIAL_WIDTH-1:0], input_current);
                    end
                end
            end
        end
    end

endmodule
