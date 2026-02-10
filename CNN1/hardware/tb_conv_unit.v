/*
 * Testbench for Convolution Unit
 * 
 * Tests basic convolution operation with known weights and inputs
 */

`timescale 1ns/1ps

module tb_conv_unit();

    parameter DATA_WIDTH = 8;
    parameter WEIGHT_WIDTH = 8;
    parameter ACC_WIDTH = 20;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n, enable;
    reg signed [DATA_WIDTH-1:0] window [0:8];
    reg signed [WEIGHT_WIDTH-1:0] weights [0:8];
    reg signed [WEIGHT_WIDTH-1:0] bias;
    reg valid_in;
    
    wire signed [ACC_WIDTH-1:0] conv_out;
    wire valid_out;
    
    integer i;
    
    // DUT
    conv_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .window(window),
        .weights(weights),
        .bias(bias),
        .valid_in(valid_in),
        .conv_out(conv_out),
        .valid_out(valid_out)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test
    initial begin
        $dumpfile("conv_unit_test.vcd");
        $dumpvars(0, tb_conv_unit);
        
        // Initialize
        rst_n = 0;
        enable = 0;
        valid_in = 0;
        bias = 0;
        
        for (i = 0; i < 9; i = i + 1) begin
            window[i] = 0;
            weights[i] = 0;
        end
        
        #(CLK_PERIOD*3);
        rst_n = 1;
        enable = 1;
        
        $display("\n========================================");
        $display("Convolution Unit Testbench");
        $display("========================================\n");
        
        // Test 1: Identity kernel
        $display("Test 1: Identity kernel (center weight = 1)");
        for (i = 0; i < 9; i = i + 1) begin
            window[i] = (i == 4) ? 100 : 0;  // Center pixel = 100
            weights[i] = (i == 4) ? 1 : 0;   // Center weight = 1
        end
        bias = 0;
        
        @(posedge clk);
        valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        
        wait(valid_out);
        $display("  Input center: 100, Output: %0d (expected ~100)", conv_out);
        
        #(CLK_PERIOD*5);
        
        // Test 2: Sum all pixels with uniform weights
        $display("\nTest 2: Uniform weights");
        for (i = 0; i < 9; i = i + 1) begin
            window[i] = 10;      // All pixels = 10
            weights[i] = 1;      // All weights = 1
        end
        bias = 5;
        
        @(posedge clk);
        valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        
        wait(valid_out);
        $display("  Sum of (9 pixels × 10) × 1 + bias(5): %0d (expected 95)", conv_out);
        
        #(CLK_PERIOD*10);
        
        $display("\n========================================");
        $display("✓ Convolution Unit Test Complete");
        $display("========================================\n");
        
        $finish;
    end
    
    initial begin
        #(CLK_PERIOD * 500);
        $display("\n✗ Timeout!");
        $finish;
    end

endmodule
