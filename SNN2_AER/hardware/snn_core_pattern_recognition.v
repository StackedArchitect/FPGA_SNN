// 3-layer SNN: 4→8→3 with STDP weights for pattern recognition
// Patterns: L-shape[1,0,1,1], T-shape[1,1,0,1], Cross[0,1,1,1]

`timescale 1ns/1ps

module snn_core_pattern_recognition #(
    parameter THRESHOLD_HIDDEN = 20,    // Hidden neuron threshold
    parameter THRESHOLD_OUTPUT = 15,    // Output neuron threshold
    parameter LEAK = 1,                 // Leak per cycle
    parameter POTENTIAL_WIDTH = 8       // Bits for membrane potential
) (
    input  wire clk,
    input  wire rst_n,
    
    // Input spikes from AER encoder (4 pixels)
    input  wire spike_in_0,
    input  wire spike_in_1,
    input  wire spike_in_2,
    input  wire spike_in_3,
    
    // Configurable bias signals for outputs (teaching/inference aid)
    input  wire signed [3:0] bias_output_0,  // Bias for L-shape
    input  wire signed [3:0] bias_output_1,  // Bias for T-shape
    input  wire signed [3:0] bias_output_2,  // Bias for Cross
    
    // Output spikes (pattern classification)
    output wire spike_out_0,  // L-shape detected
    output wire spike_out_1,  // T-shape detected
    output wire spike_out_2,  // Cross detected
    
    // Winner neuron (highest spike count)
    output reg [1:0] winner,
    
    // Debug: membrane potentials
    output wire [POTENTIAL_WIDTH-1:0] pot_h0, pot_h1, pot_h2, pot_h3,
    output wire [POTENTIAL_WIDTH-1:0] pot_h4, pot_h5, pot_h6, pot_h7,
    output wire [POTENTIAL_WIDTH-1:0] pot_o0, pot_o1, pot_o2
);

    `include "weight_parameters.vh"
    
    wire spike_h0, spike_h1, spike_h2, spike_h3;
    wire spike_h4, spike_h5, spike_h6, spike_h7;
    
    wire signed [POTENTIAL_WIDTH:0] current_h0, current_h1, current_h2, current_h3;
    wire signed [POTENTIAL_WIDTH:0] current_h4, current_h5, current_h6, current_h7;
    
    assign current_h0 = (spike_in_0 ? WEIGHT_I0_H0 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H0 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H0 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H0 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_0 (.clk(clk), .rst_n(rst_n), .input_current(current_h0), .bias_signal(4'b0),
              .spike_out(spike_h0), .membrane_potential(pot_h0));
    
    assign current_h1 = (spike_in_0 ? WEIGHT_I0_H1 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H1 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H1 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H1 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_1 (.clk(clk), .rst_n(rst_n), .input_current(current_h1), .bias_signal(4'b0),
              .spike_out(spike_h1), .membrane_potential(pot_h1));
    
    
    assign current_h2 = (spike_in_0 ? WEIGHT_I0_H2 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H2 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H2 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H2 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_2 (.clk(clk), .rst_n(rst_n), .input_current(current_h2), .bias_signal(4'b0),
              .spike_out(spike_h2), .membrane_potential(pot_h2));
    
    
    assign current_h3 = (spike_in_0 ? WEIGHT_I0_H3 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H3 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H3 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H3 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_3 (.clk(clk), .rst_n(rst_n), .input_current(current_h3), .bias_signal(4'b0),
              .spike_out(spike_h3), .membrane_potential(pot_h3));
    
    
    assign current_h4 = (spike_in_0 ? WEIGHT_I0_H4 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H4 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H4 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H4 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_4 (.clk(clk), .rst_n(rst_n), .input_current(current_h4), .bias_signal(4'b0),
              .spike_out(spike_h4), .membrane_potential(pot_h4));
    
    
    assign current_h5 = (spike_in_0 ? WEIGHT_I0_H5 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H5 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H5 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H5 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_5 (.clk(clk), .rst_n(rst_n), .input_current(current_h5), .bias_signal(4'b0),
              .spike_out(spike_h5), .membrane_potential(pot_h5));
    
    
    assign current_h6 = (spike_in_0 ? WEIGHT_I0_H6 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H6 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H6 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H6 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_6 (.clk(clk), .rst_n(rst_n), .input_current(current_h6), .bias_signal(4'b0),
              .spike_out(spike_h6), .membrane_potential(pot_h6));
    
    
    assign current_h7 = (spike_in_0 ? WEIGHT_I0_H7 : 0) +
                        (spike_in_1 ? WEIGHT_I1_H7 : 0) +
                        (spike_in_2 ? WEIGHT_I2_H7 : 0) +
                        (spike_in_3 ? WEIGHT_I3_H7 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_HIDDEN), .LEAK(LEAK), .BIAS(0))
    hidden_7 (.clk(clk), .rst_n(rst_n), .input_current(current_h7), .bias_signal(4'b0),
              .spike_out(spike_h7), .membrane_potential(pot_h7));
    
    
    wire signed [POTENTIAL_WIDTH:0] current_o0, current_o1, current_o2;
    
    
    assign current_o0 = (spike_h0 ? WEIGHT_H0_O0 : 0) +
                        (spike_h1 ? WEIGHT_H1_O0 : 0) +
                        (spike_h2 ? WEIGHT_H2_O0 : 0) +
                        (spike_h3 ? WEIGHT_H3_O0 : 0) +
                        (spike_h4 ? WEIGHT_H4_O0 : 0) +
                        (spike_h5 ? WEIGHT_H5_O0 : 0) +
                        (spike_h6 ? WEIGHT_H6_O0 : 0) +
                        (spike_h7 ? WEIGHT_H7_O0 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_OUTPUT), .LEAK(LEAK))
    output_0 (.clk(clk), .rst_n(rst_n), .input_current(current_o0), 
              .bias_signal(bias_output_0),
              .spike_out(spike_out_0), .membrane_potential(pot_o0));
    
    
    assign current_o1 = (spike_h0 ? WEIGHT_H0_O1 : 0) +
                        (spike_h1 ? WEIGHT_H1_O1 : 0) +
                        (spike_h2 ? WEIGHT_H2_O1 : 0) +
                        (spike_h3 ? WEIGHT_H3_O1 : 0) +
                        (spike_h4 ? WEIGHT_H4_O1 : 0) +
                        (spike_h5 ? WEIGHT_H5_O1 : 0) +
                        (spike_h6 ? WEIGHT_H6_O1 : 0) +
                        (spike_h7 ? WEIGHT_H7_O1 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_OUTPUT), .LEAK(LEAK))
    output_1 (.clk(clk), .rst_n(rst_n), .input_current(current_o1), 
              .bias_signal(bias_output_1),
              .spike_out(spike_out_1), .membrane_potential(pot_o1));
    
    
    assign current_o2 = (spike_h0 ? WEIGHT_H0_O2 : 0) +
                        (spike_h1 ? WEIGHT_H1_O2 : 0) +
                        (spike_h2 ? WEIGHT_H2_O2 : 0) +
                        (spike_h3 ? WEIGHT_H3_O2 : 0) +
                        (spike_h4 ? WEIGHT_H4_O2 : 0) +
                        (spike_h5 ? WEIGHT_H5_O2 : 0) +
                        (spike_h6 ? WEIGHT_H6_O2 : 0) +
                        (spike_h7 ? WEIGHT_H7_O2 : 0);
    
    lif_neuron_stdp #(.THRESHOLD(THRESHOLD_OUTPUT), .LEAK(LEAK))
    output_2 (.clk(clk), .rst_n(rst_n), .input_current(current_o2), 
              .bias_signal(bias_output_2),
              .spike_out(spike_out_2), .membrane_potential(pot_o2));
    
    // WINNER-TAKE-ALL: Track spike counts and determine winner
    
    reg [15:0] spike_count_0, spike_count_1, spike_count_2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_count_0 <= 0;
            spike_count_1 <= 0;
            spike_count_2 <= 0;
            winner <= 0;
        end else begin
            // Count spikes
            if (spike_out_0) spike_count_0 <= spike_count_0 + 1;
            if (spike_out_1) spike_count_1 <= spike_count_1 + 1;
            if (spike_out_2) spike_count_2 <= spike_count_2 + 1;
            
            // Determine winner (neuron with most spikes)
            if (spike_count_0 >= spike_count_1 && spike_count_0 >= spike_count_2) begin
                winner <= 2'b00;  // L-shape
            end else if (spike_count_1 >= spike_count_2) begin
                winner <= 2'b01;  // T-shape
            end else begin
                winner <= 2'b10;  // Cross
            end
        end
    end
    
    // INITIALIZATION
    
    initial begin
        $display("========================================================================");
        $display("[SNN_CORE] Pattern Recognition Network with STDP-Trained Weights");
        $display("========================================================================");
        $display("Architecture: 4 inputs → 8 hidden → 3 outputs");
        $display("Patterns:");
        $display("  Output 0 (00): L-shape [1,0,1,1]");
        $display("  Output 1 (01): T-shape [1,1,0,1]");
        $display("  Output 2 (10): Cross   [0,1,1,1]");
        $display("Parameters:");
        $display("  Hidden Threshold: %0d", THRESHOLD_HIDDEN);
        $display("  Output Threshold: %0d", THRESHOLD_OUTPUT);
        $display("  Leak: %0d", LEAK);
        $display("  Configurable bias signals enabled for supervised inference");
        $display("========================================================================");
    end

endmodule
