// Simple test to debug why neurons don't spike

`timescale 1ns/1ps

module tb_simple_spike_test;

reg clk, rst_n;
reg spike_in;
wire spike_out;
wire [7:0] pot;

// Test neuron with simple current
lif_neuron_stdp #(.THRESHOLD(20), .LEAK(1), .BIAS(0))
test_neuron (
    .clk(clk),
    .rst_n(rst_n),
    .input_current(spike_in ? 15 : 0),  // Weight of 15 when input spikes
    .bias_signal(4'b0),
    .spike_out(spike_out),
    .membrane_potential(pot)
);

// Clock
initial begin
    clk = 0;
    forever #50 clk = ~clk;
end

// Test
initial begin
    $dumpfile("simple_test.vcd");
    $dumpvars(0, tb_simple_spike_test);
    
    rst_n = 0;
    spike_in = 0;
    #200;
    rst_n = 1;
    #100;
    
    $display("=== Test 1: Single spike (15) ===");
    spike_in = 1;
    #100;
    spike_in = 0;
    $display("After single spike: pot=%0d, spike=%b", pot, spike_out);
    #1000;
    
    $display("\n=== Test 2: Continuous input (15 per cycle) ===");
    spike_in = 1;
    repeat(50) begin
        @(posedge clk);
        if (pot > 0 || spike_out)
            $display("t=%0t: pot=%0d, spike=%b", $time, pot, spike_out);
    end
    spike_in = 0;
    
    #500;
    $finish;
end

endmodule
