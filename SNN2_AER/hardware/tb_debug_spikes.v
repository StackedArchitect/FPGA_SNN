// Debug testbench - simplified to trace spike propagation

`timescale 1ns/1ps

module tb_debug_spikes;

reg clk, rst_n;
reg [3:0] pattern;

wire spike_in_0, spike_in_1, spike_in_2, spike_in_3;
wire spike_h0;
wire [7:0] pot_h0;

// AER encoder
aer_pixel_encoder #(.SPIKE_PERIOD(5), .QUIET_PERIOD(10))
aer (.clk(clk), .rst_n(rst_n), .enable(1'b1),  // Enable encoding
     .pixel_0(pattern[0]), .pixel_1(pattern[1]),
     .pixel_2(pattern[2]), .pixel_3(pattern[3]),
     .spike_out_0(spike_in_0), .spike_out_1(spike_in_1),
     .spike_out_2(spike_in_2), .spike_out_3(spike_in_3));

// Include weights
`include "weight_parameters.vh"

// Calculate current for hidden neuron 0
wire signed [8:0] current_h0;
assign current_h0 = (spike_in_0 ? WEIGHT_I0_H0 : 0) +
                    (spike_in_1 ? WEIGHT_I1_H0 : 0) +
                    (spike_in_2 ? WEIGHT_I2_H0 : 0) +
                    (spike_in_3 ? WEIGHT_I3_H0 : 0);

// Single hidden neuron
lif_neuron_stdp #(.THRESHOLD(20), .LEAK(1))
h0 (.clk(clk), .rst_n(rst_n),
    .input_current(current_h0),
    .bias_signal(4'b0),
    .spike_out(spike_h0),
    .membrane_potential(pot_h0));

// Clock
initial begin
    clk = 0;
    forever #50 clk = ~clk;
end

// Monitor
integer cycle;
always @(posedge clk) begin
    if (!rst_n) begin
        cycle = 0;
    end else begin
        cycle = cycle + 1;
        
        // Print every cycle for first 100 cycles
        if (cycle <= 100 && (|{spike_in_0, spike_in_1, spike_in_2, spike_in_3} || pot_h0 > 0 || spike_h0)) begin
            $display("Cycle %3d: Spikes=[%b%b%b%b] Current=%2d Pot=%2d Spike_out=%b",
                     cycle, spike_in_0, spike_in_1, spike_in_2, spike_in_3,
                     current_h0, pot_h0, spike_h0);
        end
    end
end

// Test
initial begin
    $dumpfile("debug_spikes.vcd");
    $dumpvars(0, tb_debug_spikes);
    
    rst_n = 0;
    pattern = 4'b0000;
    #500;
    rst_n = 1;
    #100;
    
    $display("\n===== Testing L-shape [1,0,1,1] =====");
    pattern = 4'b1011;  // Pixels 0, 2, 3 active
    
    #10000;  // Run for 100 cycles
    
    $display("\nFinal: pot_h0=%d, total spikes=%d", pot_h0, spike_h0);
    
    $finish;
end

endmodule
